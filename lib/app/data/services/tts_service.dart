import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

/// Manages real-time Android/device Text-to-Speech playback for flashcards.
class TtsService extends GetxService {
  TtsService({FlutterTts? tts}) : _tts = tts;

  FlutterTts? _tts;

  final RxBool isSpeaking = false.obs;
  final RxString activeText = ''.obs;

  bool _isInitialized = false;
  bool _isClosed = false;

  FlutterTts get _flutterTts => _tts ??= FlutterTts();

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
        if (_isClosed) return;
        isSpeaking.value = true;
      });
      tts.setCompletionHandler(() {
        if (_isClosed) return;
        isSpeaking.value = false;
        activeText.value = '';
      });
      tts.setCancelHandler(() {
        if (_isClosed) return;
        isSpeaking.value = false;
        activeText.value = '';
      });
      tts.setErrorHandler((dynamic message) {
        debugPrint('TtsService error handler: $message');
        if (_isClosed) return;
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

  /// Speaks [text] aloud in real time, stopping any active utterance first.
  Future<void> speak(
    String text, {
    String language = 'en-US',
    double rate = 0.48,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isClosed) return;

    await _initEngine();
    if (isSpeaking.value) {
      await stop();
    }

    try {
      activeText.value = trimmed;
      isSpeaking.value = true;
      await _flutterTts.setLanguage(language);
      await _flutterTts.setSpeechRate(rate);
      final result = await _flutterTts.speak(trimmed);
      if (result == 0 && !_isClosed) {
        isSpeaking.value = false;
        activeText.value = '';
      }
    } catch (error) {
      debugPrint('TtsService speak failed: $error');
      if (!_isClosed) {
        isSpeaking.value = false;
        activeText.value = '';
      }
    }
  }

  /// Stops active Text-to-Speech output and resets reactive speaking state.
  Future<void> stop() async {
    if (!_isClosed) {
      isSpeaking.value = false;
      activeText.value = '';
    }
    try {
      await _tts?.stop();
    } catch (error) {
      debugPrint('TtsService stop failed: $error');
    }
  }

  @override
  void onClose() {
    _isClosed = true;
    unawaited(stop());
    super.onClose();
  }
}
