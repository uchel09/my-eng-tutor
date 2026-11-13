import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../core/constants/gemini_constants.dart';

/// Result of checking or requesting Android microphone runtime permission.
enum MicrophonePermissionStatus {
  granted,
  denied,
  permanentlyDenied,
}

/// Wraps raw PCM 16-bit little-endian audio bytes in a standard 44-byte RIFF/WAVE header.
Uint8List buildWavFromPcm16({
  required Uint8List pcmBytes,
  int sampleRate = GeminiConstants.inputSampleRate,
  int channels = GeminiConstants.audioChannels,
}) {
  const bitsPerSample = 16;
  final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
  final blockAlign = channels * (bitsPerSample ~/ 8);
  final dataSize = pcmBytes.length;
  final totalSize = 44 + dataSize;

  final buffer = Uint8List(totalSize);
  final header = ByteData.view(buffer.buffer);

  // RIFF chunk descriptor
  buffer[0] = 0x52; // 'R'
  buffer[1] = 0x49; // 'I'
  buffer[2] = 0x46; // 'F'
  buffer[3] = 0x46; // 'F'
  header.setUint32(4, 36 + dataSize, Endian.little);
  buffer[8] = 0x57; // 'W'
  buffer[9] = 0x41; // 'A'
  buffer[10] = 0x56; // 'V'
  buffer[11] = 0x45; // 'E'

  // fmt sub-chunk
  buffer[12] = 0x66; // 'f'
  buffer[13] = 0x6D; // 'm'
  buffer[14] = 0x74; // 't'
  buffer[15] = 0x20; // ' '
  header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  header.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);

  // data sub-chunk
  buffer[36] = 0x64; // 'd'
  buffer[37] = 0x61; // 'a'
  buffer[38] = 0x74; // 't'
  buffer[39] = 0x61; // 'a'
  header.setUint32(40, dataSize, Endian.little);

  buffer.setRange(44, totalSize, pcmBytes);
  return buffer;
}

/// Manages Android microphone capture (16kHz PCM16), speaker playback (24kHz PCM16),
/// optional WAV buffering for evaluation, and microphone permission checks.
class AudioService extends GetxService {
  final StreamController<Uint8List> _micStreamController =
      StreamController<Uint8List>.broadcast();

  final RxBool isRecording = false.obs;
  final RxBool isAiSpeaking = false.obs;

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _micSubscription;
  BytesBuilder? _captureBuffer;
  int _maxCaptureBytes = 0;
  int _capturedBytesCount = 0;

  bool _isPlayerInitialized = false;
  int? _pendingOddByte;
  Future<void> _playerQueue = Future<void>.value();
  Timer? _speakingEndDebounce;
  Completer<void>? _activeReplayCompleter;
  int _playbackSessionToken = 0;

  AudioRecorder get _audioRecorder => _recorder ??= AudioRecorder();

  Future<T> _enqueuePlayerTask<T>(Future<T> Function() action) {
    final next = _playerQueue.then((_) => action());
    _playerQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        debugPrint('AudioService player queue error: $error\n$stack');
      },
    );
    return next;
  }

  /// Broadcast stream of raw PCM 16-bit 16kHz mono chunks from the microphone.
  Stream<Uint8List> get micStream => _micStreamController.stream;

  // --- Permission Handling ---

  /// Checks current microphone permission and requests it if not yet granted.
  Future<MicrophonePermissionStatus> checkAndRequestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted || status.isLimited) {
      return MicrophonePermissionStatus.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return MicrophonePermissionStatus.permanentlyDenied;
    }

    status = await Permission.microphone.request();
    if (status.isGranted || status.isLimited) {
      return MicrophonePermissionStatus.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return MicrophonePermissionStatus.permanentlyDenied;
    }
    return MicrophonePermissionStatus.denied;
  }

  /// Convenience wrapper returning `true` when microphone permission is granted.
  Future<bool> ensureMicrophonePermission() async {
    final result = await checkAndRequestMicrophonePermission();
    return result == MicrophonePermissionStatus.granted;
  }

  /// Opens the Android system App Settings page so the user can grant permissions.
  Future<bool> openDeviceAppSettings() {
    return openAppSettings();
  }

  // --- Microphone Capture (16kHz PCM16 Mono) ---

  /// Starts capturing 16kHz mono PCM16 audio into [micStream].
  ///
  /// When [captureBufferForEval] is `true`, copies up to [maxCaptureSeconds] of
  /// audio into an internal buffer retrievable via [buildRecordedWavBytes].
  /// When [appendBuffer] is `true`, preserves previously captured bytes from
  /// earlier turns in the same session.
  Future<void> startMicStream({
    bool captureBufferForEval = false,
    bool appendBuffer = false,
    int maxCaptureSeconds = 90,
  }) async {
    if (isRecording.value) {
      await stopMicStream();
    }

    final permitted = await ensureMicrophonePermission();
    if (!permitted) {
      throw StateError(
        'Izin mikrofon belum diberikan. Aktifkan izin mikrofon untuk mulai berbicara.',
      );
    }

    prepareCaptureBufferForTest(
      captureBufferForEval: captureBufferForEval,
      appendBuffer: appendBuffer,
      maxCaptureSeconds: maxCaptureSeconds,
    );

    const config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: GeminiConstants.inputSampleRate,
      numChannels: GeminiConstants.audioChannels,
      echoCancel: true,
      noiseSuppress: true,
      autoGain: true,
      audioInterruption: AudioInterruptionMode.none,
      androidConfig: AndroidRecordConfig(
        speakerphone: true,
      ),
    );

    final rawStream = await _audioRecorder.startStream(config);
    isRecording.value = true;

    _micSubscription = rawStream.listen(
      (Uint8List chunk) {
        if (chunk.isEmpty) return;

        if (!_micStreamController.isClosed) {
          _micStreamController.add(chunk);
        }

        appendCaptureChunkForTest(chunk);
      },
      onError: (Object error) {
        isRecording.value = false;
      },
      onDone: () {
        isRecording.value = false;
      },
      cancelOnError: false,
    );
  }

  /// Prepares or appends the internal WAV evaluation buffer cleanly.
  @visibleForTesting
  void prepareCaptureBufferForTest({
    required bool captureBufferForEval,
    required bool appendBuffer,
    required int maxCaptureSeconds,
  }) {
    if (captureBufferForEval && maxCaptureSeconds > 0) {
      _maxCaptureBytes = maxCaptureSeconds *
          GeminiConstants.inputSampleRate *
          GeminiConstants.audioChannels *
          2;
      if (!appendBuffer || _captureBuffer == null) {
        _captureBuffer = BytesBuilder(copy: false);
        _capturedBytesCount = 0;
      }
      return;
    }

    if (!appendBuffer) {
      _captureBuffer = null;
      _maxCaptureBytes = 0;
      _capturedBytesCount = 0;
    }
  }

  /// Appends a raw PCM16 chunk into the evaluation capture buffer up to the max limit.
  @visibleForTesting
  void appendCaptureChunkForTest(Uint8List chunk) {
    final buffer = _captureBuffer;
    if (buffer == null ||
        chunk.isEmpty ||
        _capturedBytesCount >= _maxCaptureBytes) {
      return;
    }

    final remaining = _maxCaptureBytes - _capturedBytesCount;
    if (chunk.length <= remaining) {
      buffer.add(Uint8List.fromList(chunk));
      _capturedBytesCount += chunk.length;
    } else {
      buffer.add(Uint8List.fromList(chunk.sublist(0, remaining)));
      _capturedBytesCount += remaining;
    }
  }

  /// Returns the captured 16kHz audio wrapped as a RIFF/WAVE payload, or `null`.
  Uint8List? buildRecordedWavBytes() {
    final buffer = _captureBuffer;
    if (buffer == null || buffer.isEmpty) return null;
    final pcmBytes = buffer.toBytes();
    if (pcmBytes.isEmpty) return null;
    return buildWavFromPcm16(
      pcmBytes: pcmBytes,
      sampleRate: GeminiConstants.inputSampleRate,
      channels: GeminiConstants.audioChannels,
    );
  }

  /// Stops active microphone streaming and cancels the internal stream subscription.
  Future<void> stopMicStream() async {
    await _micSubscription?.cancel();
    _micSubscription = null;

    if (_recorder != null) {
      try {
        if (await _recorder!.isRecording()) {
          await _recorder!.stop();
        }
      } catch (_) {
        // Ignore stop errors if the platform recorder already stopped.
      }
    }
    isRecording.value = false;
  }

  /// Clears any captured PCM buffer held for post-session evaluation.
  void clearRecordedBuffer() {
    _captureBuffer?.clear();
    _captureBuffer = null;
    _maxCaptureBytes = 0;
    _capturedBytesCount = 0;
  }

  // --- Speaker Output (24kHz PCM16 Mono) ---

  /// Initializes the 24kHz mono PCM playback engine on Android.
  Future<void> initPlayer() {
    return _enqueuePlayerTask(_initPlayerInternal);
  }

  Future<void> _initPlayerInternal() async {
    if (_isPlayerInitialized) return;

    await FlutterPcmSound.setLogLevel(LogLevel.error);
    await FlutterPcmSound.setup(
      sampleRate: GeminiConstants.outputSampleRate,
      channelCount: GeminiConstants.audioChannels,
    );
    await FlutterPcmSound.setFeedThreshold(2400);
    FlutterPcmSound.setFeedCallback((int remainingFrames) {
      if (remainingFrames == 0) {
        final replayCompleter = _activeReplayCompleter;
        if (replayCompleter != null && !replayCompleter.isCompleted) {
          replayCompleter.complete();
        }
        _scheduleSpeakingEnd();
      }
    });
    _isPlayerInitialized = true;
  }

  void _scheduleSpeakingEnd() {
    _speakingEndDebounce?.cancel();
    _speakingEndDebounce = Timer(const Duration(milliseconds: 450), () {
      isAiSpeaking.value = false;
    });
  }

  /// Feeds raw 24kHz PCM16 little-endian bytes to the Android speaker queue.
  ///
  /// Safely carries over a trailing odd byte between chunks to prevent
  /// 16-bit alignment `RangeError`s.
  Future<void> feedPcm24k(Uint8List rawBytes) {
    if (rawBytes.isEmpty) return Future<void>.value();
    return _enqueuePlayerTask(() => _feedPcm24kInternal(rawBytes));
  }

  Future<void> _feedPcm24kInternal(Uint8List rawBytes) async {
    if (rawBytes.isEmpty) return;

    try {
      if (!_isPlayerInitialized) {
        await _initPlayerInternal();
      }

      Uint8List combined;
      if (_pendingOddByte != null) {
        combined = Uint8List(rawBytes.length + 1);
        combined[0] = _pendingOddByte!;
        combined.setRange(1, combined.length, rawBytes);
        _pendingOddByte = null;
      } else {
        combined = rawBytes;
      }

      final usableLength = combined.length & ~1;
      if (usableLength < combined.length) {
        _pendingOddByte = combined[combined.length - 1];
      }
      if (usableLength == 0) return;

      // Copy into a zero-offset Uint8List because FlutterPcmSound.feed reads
      // `buffer.bytes.buffer.asUint8List()`.
      final alignedBytes = Uint8List.fromList(
        combined.sublist(0, usableLength),
      );

      _speakingEndDebounce?.cancel();
      isAiSpeaking.value = true;
      await FlutterPcmSound.feed(
        PcmArrayInt16(bytes: alignedBytes.buffer.asByteData()),
      );
      FlutterPcmSound.start();
    } catch (error, stack) {
      debugPrint('AudioService.feedPcm24k error: $error\n$stack');
      rethrow;
    }
  }

  /// Plays a complete cached 24kHz PCM16 buffer in chunks for turn replay.
  Future<void> playPcm24kBuffer(
    Uint8List fullPcmBytes, {
    VoidCallback? onCompleted,
  }) async {
    if (fullPcmBytes.isEmpty) {
      onCompleted?.call();
      return;
    }

    const chunkSize = 9600;
    final alignedTotalLength = fullPcmBytes.length & ~1;
    if (alignedTotalLength == 0) {
      onCompleted?.call();
      return;
    }

    late int sessionToken;
    late Completer<void> drainCompleter;

    await _enqueuePlayerTask(() async {
      await _clearAndStopPlayerInternal();
      await _initPlayerInternal();

      sessionToken = _playbackSessionToken;
      drainCompleter = Completer<void>();
      _speakingEndDebounce?.cancel();
      isAiSpeaking.value = true;

      for (var offset = 0; offset < alignedTotalLength; offset += chunkSize) {
        if (_playbackSessionToken != sessionToken) {
          if (!drainCompleter.isCompleted) {
            drainCompleter.complete();
          }
          return;
        }
        final end = math.min(offset + chunkSize, alignedTotalLength);
        final isLastChunk = end >= alignedTotalLength;
        if (isLastChunk) {
          _activeReplayCompleter = drainCompleter;
        }
        final chunk = Uint8List.fromList(fullPcmBytes.sublist(offset, end));
        await FlutterPcmSound.feed(
          PcmArrayInt16(bytes: chunk.buffer.asByteData()),
        );
        FlutterPcmSound.start();
      }
    });

    try {
      final estimatedMs =
          ((alignedTotalLength / 2) / GeminiConstants.outputSampleRate * 1000)
              .ceil();
      await drainCompleter.future.timeout(
        Duration(milliseconds: estimatedMs + 1500),
        onTimeout: () {},
      );
    } catch (error, stack) {
      debugPrint('AudioService.playPcm24kBuffer error: $error\n$stack');
    } finally {
      if (identical(_activeReplayCompleter, drainCompleter)) {
        _activeReplayCompleter = null;
      }
      if (_playbackSessionToken == sessionToken) {
        _speakingEndDebounce?.cancel();
        isAiSpeaking.value = false;
      }
      onCompleted?.call();
    }
  }

  /// Immediately halts audio playback, clears queued samples, and resets state.
  Future<void> clearAndStopPlayer() {
    return _enqueuePlayerTask(_clearAndStopPlayerInternal);
  }

  Future<void> _clearAndStopPlayerInternal() async {
    _playbackSessionToken++;
    _speakingEndDebounce?.cancel();
    _speakingEndDebounce = null;
    _pendingOddByte = null;
    isAiSpeaking.value = false;

    final replayCompleter = _activeReplayCompleter;
    _activeReplayCompleter = null;
    if (replayCompleter != null && !replayCompleter.isCompleted) {
      replayCompleter.complete();
    }

    if (_isPlayerInitialized) {
      _isPlayerInitialized = false;
      try {
        await FlutterPcmSound.release();
      } catch (error, stack) {
        debugPrint('AudioService.clearAndStopPlayer error: $error\n$stack');
      }
    }
  }

  // --- Hardware Self-Test ---

  /// Generates and plays a 0.3s 440Hz sine tone at 24kHz PCM16 to test speaker output.
  Future<void> playTestBeep() async {
    const durationSec = 0.3;
    const frequencyHz = 440.0;
    const sampleRate = GeminiConstants.outputSampleRate;
    final sampleCount = (sampleRate * durationSec).round();

    final byteData = ByteData(sampleCount * 2);
    const maxAmplitude = 32767 * 0.25;

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final sample = (math.sin(2 * math.pi * frequencyHz * t) * maxAmplitude)
          .round()
          .clamp(-32768, 32767);
      byteData.setInt16(i * 2, sample, Endian.little);
    }

    await feedPcm24k(byteData.buffer.asUint8List());
  }

  @override
  void onClose() {
    unawaited(_disposeResources());
    super.onClose();
  }

  Future<void> _disposeResources() async {
    await stopMicStream();
    clearRecordedBuffer();
    await clearAndStopPlayer();

    final recorder = _recorder;
    _recorder = null;
    if (recorder != null) {
      try {
        await recorder.dispose();
      } catch (_) {
        // Ignore recorder disposal errors on shutdown.
      }
    }

    if (!_micStreamController.isClosed) {
      await _micStreamController.close();
    }
  }
}
