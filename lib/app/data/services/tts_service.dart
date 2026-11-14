import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/gemini_constants.dart';
import '../providers/gemini_live_provider.dart';
import '../providers/gemini_rest_provider.dart';
import '../repositories/tutor_repository.dart';
import 'audio_service.dart';

/// Hybrid Text-to-Speech service backed by Gemini Live/REST TTS with an
/// in-memory RAM cache, persistent per-utterance `.wav` storage in the app's
/// `my_english_tutor_audio` directory, and automatic fallback to device
/// `flutter_tts` when offline/unconfigured/rate-limited.
class TtsService extends GetxService {
  TtsService({
    TutorRepository? repository,
    AudioService? audioService,
    FlutterTts? flutterTts,
    Future<bool> Function()? internetChecker,
    Future<Directory> Function()? cacheDirectoryProvider,
  })  : _repository = repository,
        _audioService = audioService,
        _tts = flutterTts,
        _internetChecker = internetChecker,
        _cacheDirectoryProvider = cacheDirectoryProvider;

  static const int _maxRamCacheEntries = 60;
  static const Duration _cooldownDuration = Duration(seconds: 60);
  static const String audioFolderName = 'my_english_tutor_audio';

  static final BigInt _fnvMask64 = BigInt.parse('ffffffffffffffff', radix: 16);
  static final BigInt _fnvOffset1 = BigInt.parse('cbf29ce484222325', radix: 16);
  static final BigInt _fnvOffset2 = BigInt.parse('9e3779b97f4a7c15', radix: 16);
  static final BigInt _fnvPrime64 = BigInt.parse('100000001b3', radix: 16);

  final TutorRepository? _repository;
  final AudioService? _audioService;
  FlutterTts? _tts;
  final Future<bool> Function()? _internetChecker;
  final Future<Directory> Function()? _cacheDirectoryProvider;

  final RxBool isSpeaking = false.obs;
  final RxString activeText = ''.obs;
  final RxBool isLoadingAudio = false.obs;

  /// Source of the active/most recent utterance: `'ai'`, `'cache'`, `'offline_tts'`, or `''`.
  final RxString activeVoiceSource = ''.obs;

  /// Reason for falling back to device TTS: `'no_api_key'`, `'offline'`, `'quota_exceeded'`, `'api_error'`, or `null`.
  final RxnString lastFallbackReason = RxnString();

  /// Underlying error detail when AI synthesis fell back to device TTS.
  final RxnString lastFallbackDetail = RxnString();

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
    lastFallbackDetail.value = null;
  }

  /// Empties all cached PCM audio buffers stored in RAM.
  /// Persistent `.wav` files in [audioFolderName] are intentionally preserved.
  void clearRamCache() {
    _pcmCache.clear();
  }

  /// Resolves the persistent app-private `my_english_tutor_audio` directory,
  /// returning `null` safely if platform storage is unavailable (e.g. unit tests).
  Future<Directory?> _resolveAudioCacheDirectory({
    bool createIfMissing = true,
  }) async {
    try {
      Directory? rootDir;
      final provider = _cacheDirectoryProvider;
      if (provider != null) {
        rootDir = await provider();
      } else {
        try {
          rootDir = await getExternalStorageDirectory();
        } catch (_) {
          rootDir = null;
        }
        if (rootDir == null) {
          try {
            rootDir = await getApplicationDocumentsDirectory();
          } catch (_) {
            rootDir = null;
          }
        }
      }

      if (rootDir == null) return null;

      final audioDir = Directory(
        '${rootDir.path}${Platform.pathSeparator}$audioFolderName',
      );
      if (!await audioDir.exists()) {
        if (!createIfMissing) return null;
        await audioDir.create(recursive: true);
      }
      return audioDir;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    } on FileSystemException {
      return null;
    } catch (error) {
      debugPrint('TtsService audio dir resolution skipped: $error');
      return null;
    }
  }

  static String _dualFnv1a64Hex(String input) {
    final bytes = utf8.encode(input);
    var hash1 = _fnvOffset1;
    var hash2 = _fnvOffset2;
    for (final byte in bytes) {
      hash1 = ((hash1 ^ BigInt.from(byte)) * _fnvPrime64) & _fnvMask64;
    }
    for (var i = bytes.length - 1; i >= 0; i--) {
      final mixedByte = bytes[i] ^ ((i * 31) & 0xff);
      hash2 = ((hash2 ^ BigInt.from(mixedByte)) * _fnvPrime64) & _fnvMask64;
    }
    return '${hash1.toRadixString(16).padLeft(16, '0')}'
        '${hash2.toRadixString(16).padLeft(16, '0')}';
  }

  /// Builds a deterministic, filesystem-safe `.wav` filename from [cacheKey].
  @visibleForTesting
  static String buildAudioCacheFileName({
    required String cacheKey,
    required String text,
    required String speedTag,
  }) {
    var slug = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (slug.isEmpty) {
      slug = 'audio';
    }
    if (slug.length > 28) {
      slug = slug.substring(0, 28).replaceAll(RegExp(r'_+$'), '');
      if (slug.isEmpty) {
        slug = 'audio';
      }
    }
    final safeSpeed = speedTag == 'slow' ? 'slow' : 'normal';
    final hash32 = _dualFnv1a64Hex(cacheKey);
    return '${slug}_${safeSpeed}_$hash32.wav';
  }

  static bool _isValidRiffWaveBytes(Uint8List bytes) {
    if (bytes.length <= 44) return false;
    return bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46 && // F
        bytes[8] == 0x57 && // W
        bytes[9] == 0x41 && // A
        bytes[10] == 0x56 && // V
        bytes[11] == 0x45; // E
  }

  Future<Uint8List?> _readFromDiskCache({
    required String cacheKey,
    required String text,
    required String speedTag,
  }) async {
    final audioDir = await _resolveAudioCacheDirectory(createIfMissing: false);
    if (audioDir == null) return null;

    final fileName = buildAudioCacheFileName(
      cacheKey: cacheKey,
      text: text,
      speedTag: speedTag,
    );
    final file = File('${audioDir.path}${Platform.pathSeparator}$fileName');
    try {
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (!_isValidRiffWaveBytes(bytes)) {
        try {
          await file.delete();
        } catch (_) {}
        return null;
      }
      return bytes.sublist(44);
    } catch (error) {
      debugPrint('TtsService disk cache read failed: $error');
      return null;
    }
  }

  Future<void> _writeToDiskCache({
    required String cacheKey,
    required String text,
    required String speedTag,
    required Uint8List pcmBytes,
  }) async {
    final audioDir = await _resolveAudioCacheDirectory(createIfMissing: true);
    if (audioDir == null || pcmBytes.isEmpty) return;

    final fileName = buildAudioCacheFileName(
      cacheKey: cacheKey,
      text: text,
      speedTag: speedTag,
    );
    final targetPath = '${audioDir.path}${Platform.pathSeparator}$fileName';
    final targetFile = File(targetPath);
    final tempFile = File('$targetPath.tmp');

    try {
      final wavBytes = buildWavFromPcm16(
        pcmBytes: pcmBytes,
        sampleRate: GeminiConstants.outputSampleRate,
        channels: GeminiConstants.audioChannels,
      );
      await tempFile.writeAsBytes(wavBytes, flush: true);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetPath);
    } catch (error) {
      debugPrint('TtsService disk cache write failed: $error');
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  /// Returns count and total size in bytes of `.wav` files stored in [audioFolderName].
  Future<({int fileCount, int totalBytes})> getSavedAudioStats() async {
    final audioDir = await _resolveAudioCacheDirectory(createIfMissing: false);
    if (audioDir == null) {
      return (fileCount: 0, totalBytes: 0);
    }

    var fileCount = 0;
    var totalBytes = 0;
    try {
      await for (final entity in audioDir.list(followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.wav')) {
          try {
            totalBytes += await entity.length();
            fileCount += 1;
          } catch (_) {}
        }
      }
    } catch (error) {
      debugPrint('TtsService getSavedAudioStats failed: $error');
    }
    return (fileCount: fileCount, totalBytes: totalBytes);
  }

  /// Deletes all saved `.wav` (and leftover `.tmp`) files in [audioFolderName]
  /// and empties the in-memory RAM cache.
  Future<void> clearSavedAudioFiles() async {
    clearRamCache();
    final audioDir = await _resolveAudioCacheDirectory(createIfMissing: false);
    if (audioDir == null) return;

    try {
      await for (final entity in audioDir.list(followLinks: false)) {
        if (entity is File) {
          final lower = entity.path.toLowerCase();
          if (lower.endsWith('.wav') || lower.endsWith('.tmp')) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (error) {
      debugPrint('TtsService clearSavedAudioFiles failed: $error');
    }
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

  Future<bool> _hasInternetConnection() async {
    final checker = _internetChecker;
    if (checker != null) {
      return await checker();
    }
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
    try {
      final results = await Connectivity().checkConnectivity().timeout(
            const Duration(milliseconds: 500),
          );
      if (results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none)) {
        return false;
      }
    } on MissingPluginException {
      // Fall through to real DNS/TCP reachability check when native plugin is missing.
    } on PlatformException {
      // Fall through to real DNS/TCP reachability check.
    } on UnimplementedError {
      // Fall through to real DNS/TCP reachability check.
    } catch (_) {
      // Fall through to real DNS/TCP reachability check.
    }

    Socket? socket;
    try {
      final sw = Stopwatch()..start();
      final addresses = await InternetAddress.lookup(
        'generativelanguage.googleapis.com',
      ).timeout(const Duration(milliseconds: 900));
      if (addresses.isEmpty) {
        return false;
      }
      final remainingMs = 1200 - sw.elapsedMilliseconds;
      if (remainingMs <= 0) {
        return false;
      }
      socket = await Socket.connect(
        addresses.first,
        443,
        timeout: Duration(milliseconds: remainingMs.clamp(1, 1000)),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
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
    final previousVoiceSource = activeVoiceSource.value;
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
        previousVoiceSource: previousVoiceSource,
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
    required String previousVoiceSource,
  }) async {
    String apiKey;
    String effectiveTtsModel;
    try {
      final settings = await repo.getSettings();
      if (_isClosed || requestId != _speakRequestId) return false;
      apiKey = settings.apiKey.trim();
      final configuredTts = settings.flashcardTtsModel.trim();
      final configuredLive = settings.liveModel.trim();
      effectiveTtsModel = configuredTts.isNotEmpty
          ? configuredTts
          : (configuredLive.isNotEmpty
                ? configuredLive
                : GeminiConstants.defaultTtsModel);
    } catch (error) {
      if (!_isClosed && requestId == _speakRequestId) {
        lastFallbackReason.value = 'api_error';
        lastFallbackDetail.value = _formatFallbackDetail(error);
        debugPrint('TtsService AI fallback (${lastFallbackReason.value}): $error');
      }
      return false;
    }

    final speedTag = rate < 0.42 ? 'slow' : 'normal';
    final cacheKey = '$effectiveTtsModel|$speedTag|$trimmed';

    // Step 1: Play from RAM cache or persistent `.wav` disk cache immediately even if offline or API key is empty.
    var cachedPcm = _readFromCache(cacheKey);
    if (cachedPcm == null) {
      cachedPcm = await _readFromDiskCache(
        cacheKey: cacheKey,
        text: trimmed,
        speedTag: speedTag,
      );
      if (_isClosed || requestId != _speakRequestId) return false;
      if (cachedPcm != null) {
        _writeToCache(cacheKey, cachedPcm);
      }
    }
    if (cachedPcm != null) {
      if (_cooldownReason == 'offline' ||
          lastFallbackReason.value == 'offline') {
        _cooldownReason = null;
        _aiCooldownUntil = null;
      }
      lastFallbackReason.value = null;
      lastFallbackDetail.value = null;
      isLoadingAudio.value = false;
      activeVoiceSource.value = 'cache';
      isSpeaking.value = true;
      return _playPcmViaAudioService(audio, cachedPcm, requestId);
    }

    if (apiKey.isEmpty) {
      lastFallbackReason.value = 'no_api_key';
      lastFallbackDetail.value = 'API key Gemini belum diisi di Pengaturan.';
      return false;
    }

    // Step 2: Check connectivity BEFORE turning on AI loading indicator.
    final isOnline = await _hasInternetConnection();
    if (_isClosed || requestId != _speakRequestId) return false;
    if (!isOnline) {
      lastFallbackReason.value = 'offline';
      lastFallbackDetail.value =
          'Tidak ada koneksi internet. Menggunakan suara perangkat (TTS).';
      if (!_isInAiCooldown) {
        _cooldownReason = 'offline';
        _aiCooldownUntil = null;
      }
      return false;
    }

    // Step 3: Online — clear previous offline fallback state WITHOUT clearing _pcmCache.
    final wasOfflineFallback = _cooldownReason == 'offline' ||
        lastFallbackReason.value == 'offline' ||
        previousVoiceSource == 'offline_tts';
    if (wasOfflineFallback &&
        (_cooldownReason == 'offline' || !_isInAiCooldown)) {
      _cooldownReason = null;
      _aiCooldownUntil = null;
      lastFallbackReason.value = null;
      lastFallbackDetail.value = null;
    }

    if (_isInAiCooldown) {
      lastFallbackReason.value = _cooldownReason ?? 'quota_exceeded';
      lastFallbackDetail.value ??=
          'Cooldown sementara aktif (${lastFallbackReason.value}).';
      return false;
    }

    isLoadingAudio.value = true;
    lastFallbackReason.value = null;
    lastFallbackDetail.value = null;
    try {
      final pcmBytes = await repo
          .synthesizeSpeechPcm24k(
            text: trimmed,
            slow: rate < 0.42,
          )
          .timeout(const Duration(seconds: 15));
      if (_isClosed || requestId != _speakRequestId) {
        return false;
      }
      if (pcmBytes.isEmpty) {
        throw const GeminiApiException('Data audio TTS dari Gemini kosong.');
      }

      _writeToCache(cacheKey, pcmBytes);
      await _writeToDiskCache(
        cacheKey: cacheKey,
        text: trimmed,
        speedTag: speedTag,
        pcmBytes: pcmBytes,
      );
      if (_isClosed || requestId != _speakRequestId) {
        return false;
      }
      isLoadingAudio.value = false;
      lastFallbackDetail.value = null;
      activeVoiceSource.value = 'ai';
      isSpeaking.value = true;
      return await _playPcmViaAudioService(audio, pcmBytes, requestId);
    } on GeminiApiException catch (error) {
      if (_isClosed || requestId != _speakRequestId) return false;
      _classifyAndRecordAiFailure(error, statusCode: error.statusCode);
      debugPrint('TtsService AI fallback (${lastFallbackReason.value}): $error');
      return false;
    } on GeminiLiveException catch (error) {
      if (_isClosed || requestId != _speakRequestId) return false;
      _classifyAndRecordAiFailure(error);
      debugPrint('TtsService AI fallback (${lastFallbackReason.value}): $error');
      return false;
    } catch (error) {
      if (_isClosed || requestId != _speakRequestId) return false;
      _classifyAndRecordAiFailure(error);
      debugPrint('TtsService AI fallback (${lastFallbackReason.value}): $error');
      return false;
    } finally {
      if (!_isClosed && requestId == _speakRequestId) {
        isLoadingAudio.value = false;
      }
    }
  }

  static String _formatFallbackDetail(Object error) {
    var msg = error.toString().trim();
    if (msg.startsWith('GeminiLiveException: ')) {
      msg = msg.substring('GeminiLiveException: '.length).trim();
    } else if (msg.startsWith('GeminiApiException: ')) {
      msg = msg.substring('GeminiApiException: '.length).trim();
    }
    return msg;
  }

  void _classifyAndRecordAiFailure(Object error, {int? statusCode}) {
    final detail = _formatFallbackDetail(error);
    lastFallbackDetail.value = detail;
    final lower = detail.toLowerCase();

    // Never lock user out with 60s cooldown for model-specific or empty-response errors
    if (lower.contains('not found') ||
        lower.contains('ditolak') ||
        lower.contains('kosong') ||
        lower.contains('unsupported')) {
      lastFallbackReason.value = 'api_error';
      return;
    }

    if (statusCode == 429) {
      lastFallbackReason.value = 'quota_exceeded';
      _cooldownReason = 'quota_exceeded';
      _aiCooldownUntil = DateTime.now().add(_cooldownDuration);
      return;
    }
    if (statusCode == 401 || statusCode == 403) {
      lastFallbackReason.value = 'api_error';
      _cooldownReason = 'api_error';
      _aiCooldownUntil = DateTime.now().add(_cooldownDuration);
      return;
    }

    if (lower.contains('429') ||
        lower.contains('quota') ||
        lower.contains('kuota') ||
        lower.contains('resource exhausted') ||
        lower.contains('resource_exhausted') ||
        lower.contains('rate limit')) {
      lastFallbackReason.value = 'quota_exceeded';
      _cooldownReason = 'quota_exceeded';
      _aiCooldownUntil = DateTime.now().add(_cooldownDuration);
      return;
    }

    if (lower.contains('api key') ||
        lower.contains('401') ||
        lower.contains('403') ||
        lower.contains('permission_denied') ||
        lower.contains('unauthenticated')) {
      lastFallbackReason.value = 'api_error';
      _cooldownReason = 'api_error';
      _aiCooldownUntil = DateTime.now().add(_cooldownDuration);
      return;
    }

    final isNetworkError = error is SocketException ||
        error is TimeoutException ||
        lower.contains('offline') ||
        lower.contains('timeout') ||
        lower.contains('internet') ||
        lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('failed host lookup');
    if (isNetworkError || (error is GeminiApiException && statusCode == null && !lower.contains('json'))) {
      lastFallbackReason.value = 'offline';
      if (!_isInAiCooldown) {
        _cooldownReason = 'offline';
        _aiCooldownUntil = null;
      }
      return;
    }

    lastFallbackReason.value = 'api_error';
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
        lastFallbackDetail.value = _formatFallbackDetail(error);
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
