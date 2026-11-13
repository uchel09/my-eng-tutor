import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

import '../../core/constants/gemini_constants.dart';
import '../providers/gemini_rest_provider.dart';
import '../repositories/tutor_repository.dart';
import 'audio_service.dart';

/// Hybrid Text-to-Speech service backed by Gemini REST TTS with in-memory RAM cache
/// and automatic fallback to device `flutter_tts` when offline/unconfigured/rate-limited.
class TtsService extends GetxService {
  TtsService({
    TutorRepository? repository,
    AudioService? audioService,
    FlutterTts? flutterTts,
  })  : _repository = repository,
        _audioService = audioService,
        _tts = flutterTts;

  static const int _maxRamCacheEntries = 60;
  static const Duration _cooldownDuration = Duration(seconds: 60);

  final TutorRepository? _repository;
  final AudioService? _audioService;
  FlutterTts? _tts;

  final RxBool isSpeaking = false.obs;
  final RxString activeText = ''.obs;
  final RxBool isLoadingAudio = false.obs;

  /// Source of the active/most recent utterance: `'ai'`, `'cache'`, `'offline_tts'`, or `''`.
  final RxString activeVoiceSource = ''.obs;

  /// Reason for falling back to device TTS: `'no_api_key'`, `'offline'`, `'quota_exceeded'`, `'api_error'`, or `null`.
  final RxnString lastFallbackReason = RxnString();

  final LinkedHashMap<String, Uint8List> _pcmCache =
      LinkedHashMap<String, Uint8List>();

  bool _isInitialized = false;
  bool _isClosed = false;
  int _speakRequestId = 0;
  DateTime? _aiCooldownUntil;
  String? _cooldownReason;

  FlutterTts get _flutterTts => _tts ??= FlutterTts();

  TutorRepository? get _resolvedRepository {
    if (_repository != null) return _repository;
    if (Get.isRegistered<TutorRepository>()) {
      return Get.find<TutorRepository>();
    }
    return null;
  }

  AudioService? get _resolvedAudioService {
    if (_audioService != null) return _audioService;
    if (Get.isRegistered<AudioService>()) {
      return Get.find<AudioService>();
    }
    return null;
  }

  bool get _isInAiCooldown =>
      _aiCooldownUntil != null && DateTime.now().isBefore(_aiCooldownUntil!);

  @override
  void onInit() {
    super.onInit();
    unawaited(_initEngine());
  }

  Future<void> _initEngine() async {
    if (_isInitialized || _isClosed) return;
    try {
      final tts = _flutterTts;
      tts.setStartHandler(() {
        if (_isClosed || activeVoiceSource.value != 'offline_tts') return;
        isSpeaking.value = true;
      });
      tts.setCompletionHandler(() {
        if (_isClosed || activeVoiceSource.value != 'offline_tts') return;
        isSpeaking.value = false;
        activeText.value = '';
      });
      tts.setCancelHandler(() {
        if (_isClosed || activeVoiceSource.value != 'offline_tts') return;
        isSpeaking.value = false;
        activeText.value = '';
      });
      tts.setErrorHandler((dynamic message) {
        debugPrint('TtsService error handler: $message');
        if (_isClosed || activeVoiceSource.value != 'offline_tts') return;
        isSpeaking.value = false;
        activeText.value = '';
      });

      await tts.setLanguage('en-US');
      await tts.setSpeechRate(0.48);
      await tts.setPitch(1.0);
      await tts.setVolume(1.0);
      _isInitialized = true;
    } catch (error) {
      debugPrint('TtsService init skipped or failed: $error');
    }
  }

  /// Clears any temporary cooldown triggered by REST quota (`429`) or auth errors.
  void resetAiVoiceCooldown() {
    _aiCooldownUntil = null;
    _cooldownReason = null;
    lastFallbackReason.value = null;
  }

  /// Empties all cached PCM audio buffers stored in RAM.
  void clearRamCache() {
    _pcmCache.clear();
  }

  Uint8List? _readFromCache(String cacheKey) {
    final existing = _pcmCache.remove(cacheKey);
    if (existing != null) {
      _pcmCache[cacheKey] = existing;
    }
    return existing;
  }

  void _writeToCache(String cacheKey, Uint8List pcmBytes) {
    _pcmCache.remove(cacheKey);
    if (_pcmCache.length >= _maxRamCacheEntries) {
      _pcmCache.remove(_pcmCache.keys.first);
    }
    _pcmCache[cacheKey] = pcmBytes;
  }

  /// Speaks [text], preferring Gemini REST TTS + RAM cache for English when
  /// online and configured, and seamlessly falling back to `flutter_tts`.
  Future<void> speak(
    String text, {
    String language = 'en-US',
    double rate = 0.48,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isClosed) return;

    final requestId = ++_speakRequestId;
    await _stopPlaybackOnly();
    if (_isClosed || requestId != _speakRequestId) return;

    activeText.value = trimmed;
    activeVoiceSource.value = '';

    final isEnglish = language.trim().toLowerCase().startsWith('en');
    final repo = _resolvedRepository;
    final audio = _resolvedAudioService;

    if (isEnglish && repo != null && audio != null) {
      final handledByAi = await _trySpeakWithAiOrCache(
        trimmed: trimmed,
        rate: rate,
        repo: repo,
        audio: audio,
        requestId: requestId,
      );
      if (handledByAi || _isClosed || requestId != _speakRequestId) {
        return;
      }
    } else if (!isEnglish) {
      lastFallbackReason.value = null;
    }

    await _speakWithFlutterTts(
      trimmed,
      language: language,
      rate: rate,
      requestId: requestId,
    );
  }

  Future<bool> _trySpeakWithAiOrCache({
    required String trimmed,
    required double rate,
    required TutorRepository repo,
    required AudioService audio,
    required int requestId,
  }) async {
    String apiKey;
    String effectiveTtsModel;
    try {
      final settings = await repo.getSettings();
      if (_isClosed || requestId != _speakRequestId) return false;
      apiKey = settings.apiKey.trim();
      effectiveTtsModel = settings.flashcardTtsModel.trim().isNotEmpty
          ? settings.flashcardTtsModel.trim()
          : GeminiConstants.defaultTtsModel;
    } catch (_) {
      if (!_isClosed && requestId == _speakRequestId) {
        lastFallbackReason.value = 'api_error';
      }
      return false;
    }

    if (apiKey.isEmpty) {
      lastFallbackReason.value = 'no_api_key';
      return false;
    }

    if (_isInAiCooldown) {
      lastFallbackReason.value = _cooldownReason ?? 'quota_exceeded';
      return false;
    }

    final speedTag = rate < 0.42 ? 'slow' : 'normal';
    final cacheKey = '$effectiveTtsModel|$speedTag|$trimmed';

    final cachedPcm = _readFromCache(cacheKey);
    if (cachedPcm != null) {
      lastFallbackReason.value = null;
      isLoadingAudio.value = false;
      activeVoiceSource.value = 'cache';
      isSpeaking.value = true;
      return _playPcmViaAudioService(audio, cachedPcm, requestId);
    }

    isLoadingAudio.value = true;
    lastFallbackReason.value = null;
    try {
      final pcmBytes = await repo.synthesizeSpeechPcm24k(
        text: trimmed,
        slow: rate < 0.42,
      );
      if (_isClosed || requestId != _speakRequestId) {
        if (!_isClosed) isLoadingAudio.value = false;
        return false;
      }
      if (pcmBytes.isEmpty) {
        throw const GeminiApiException('Data audio TTS dari Gemini kosong.');
      }

      _writeToCache(cacheKey, pcmBytes);
      isLoadingAudio.value = false;
      activeVoiceSource.value = 'ai';
      isSpeaking.value = true;
      return await _playPcmViaAudioService(audio, pcmBytes, requestId);
    } on GeminiApiException catch (error) {
      if (_isClosed || requestId != _speakRequestId) return false;
      isLoadingAudio.value = false;
      if (error.statusCode == 429) {
        lastFallbackReason.value = 'quota_exceeded';
        _cooldownReason = 'quota_exceeded';
        _aiCooldownUntil = DateTime.now().add(_cooldownDuration);
      } else if (error.statusCode == 401 || error.statusCode == 403) {
        lastFallbackReason.value = 'api_error';
        _cooldownReason = 'api_error';
        _aiCooldownUntil = DateTime.now().add(_cooldownDuration);
      } else if (error.statusCode == null) {
        lastFallbackReason.value = 'offline';
      } else {
        lastFallbackReason.value = 'api_error';
      }
      return false;
    } catch (error) {
      if (_isClosed || requestId != _speakRequestId) return false;
      isLoadingAudio.value = false;
      final isNetworkError = error is SocketException ||
          error is TimeoutException ||
          error.toString().toLowerCase().contains('internet') ||
          error.toString().toLowerCase().contains('socket');
      lastFallbackReason.value = isNetworkError ? 'offline' : 'api_error';
      return false;
    }
  }

  Future<bool> _playPcmViaAudioService(
    AudioService audio,
    Uint8List pcmBytes,
    int requestId,
  ) async {
    try {
      await audio.playPcm24kBuffer(
        pcmBytes,
        onCompleted: () {
          if (!_isClosed && requestId == _speakRequestId) {
            isSpeaking.value = false;
            activeText.value = '';
          }
        },
      );
      if (!_isClosed && requestId == _speakRequestId) {
        isSpeaking.value = false;
        activeText.value = '';
      }
      return true;
    } catch (error) {
      debugPrint('TtsService AI audio playback failed: $error');
      if (!_isClosed && requestId == _speakRequestId) {
        isSpeaking.value = false;
        lastFallbackReason.value = 'api_error';
      }
      return false;
    }
  }

  Future<void> _speakWithFlutterTts(
    String trimmed, {
    required String language,
    required double rate,
    required int requestId,
  }) async {
    await _initEngine();
    if (_isClosed || requestId != _speakRequestId) return;

    try {
      isLoadingAudio.value = false;
      activeVoiceSource.value = 'offline_tts';
      activeText.value = trimmed;
      isSpeaking.value = true;

      await _flutterTts.setLanguage(language);
      await _flutterTts.setSpeechRate(rate);
      final result = await _flutterTts.speak(trimmed);
      if (result == 0 && !_isClosed && requestId == _speakRequestId) {
        isSpeaking.value = false;
        activeText.value = '';
      }
    } catch (error) {
      debugPrint('TtsService speak failed: $error');
      if (!_isClosed && requestId == _speakRequestId) {
        isSpeaking.value = false;
        activeText.value = '';
      }
    }
  }

  Future<void> _stopPlaybackOnly() async {
    if (!_isClosed) {
      isLoadingAudio.value = false;
      isSpeaking.value = false;
    }
    final audio = _resolvedAudioService;
    if (audio != null) {
      try {
        await audio.clearAndStopPlayer();
      } catch (error) {
        debugPrint('TtsService audio stop failed: $error');
      }
    }
    try {
      await _tts?.stop();
    } catch (error) {
      debugPrint('TtsService stop failed: $error');
    }
  }

  /// Stops active speech output (REST AI or offline TTS) and invalidates pending requests.
  Future<void> stop() async {
    _speakRequestId++;
    await _stopPlaybackOnly();
    if (!_isClosed) {
      activeText.value = '';
      activeVoiceSource.value = '';
    }
  }

  @override
  void onClose() {
    _isClosed = true;
    clearRamCache();
    unawaited(stop());
    super.onClose();
  }
}
