import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/models/practice_args.dart';
import '../../../data/models/session_result_args.dart';
import '../../../data/models/transcript_turn_model.dart';
import '../../../data/providers/gemini_live_provider.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/audio_service.dart';
import '../../../routes/app_pages.dart';

/// Orchestrates real-time bidirectional speaking sessions over Gemini Live & AudioService.
class PracticeController extends GetxController {
  PracticeController({
    required this.liveProvider,
    required this.audioService,
    required this.repository,
    PracticeArgs? initialArgs,
  }) : _initialArgs = initialArgs;

  final GeminiLiveProvider liveProvider;
  final AudioService audioService;
  final TutorRepository repository;
  final PracticeArgs? _initialArgs;

  late final PracticeArgs? args;

  static const int maxTutorAudioBytesPerTurn = 3 * 1024 * 1024;

  final Rx<LiveConnectionState> connectionState =
      LiveConnectionState.disconnected.obs;
  final RxBool isMicActive = false.obs;
  final RxBool isAiSpeaking = false.obs;
  final RxInt elapsedSeconds = 0.obs;
  final RxBool showTextInput = false.obs;
  final RxBool isPromptExpanded = true.obs;
  final RxList<TranscriptTurnModel> transcriptTurns =
      <TranscriptTurnModel>[].obs;
  final RxMap<int, Uint8List> tutorAudioByTurnIndex = <int, Uint8List>{}.obs;
  final RxnInt replayingTurnIndex = RxnInt();
  final RxnString errorMessage = RxnString();
  final RxBool isPermissionPermanentlyDenied = false.obs;
  final RxBool isApiKeyMissingError = false.obs;
  final RxBool hasEverConnected = false.obs;

  final TextEditingController textFallbackController = TextEditingController();
  final ScrollController transcriptScrollController = ScrollController();

  DateTime startedAt = DateTime.now();
  Timer? _sessionTimer;

  BytesBuilder _currentTutorAudioBuffer = BytesBuilder(copy: false);
  int _currentTutorAudioBytes = 0;
  int? _activeTutorTurnIndex;
  bool _turnCompletePendingForBuffer = false;

  StreamSubscription<LiveConnectionState>? _connStateSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<Uint8List>? _audioOutSub;
  StreamSubscription<void>? _interruptedSub;
  StreamSubscription<void>? _turnCompleteSub;
  StreamSubscription<TranscriptTurnModel>? _transcriptSub;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<bool>? _audioSpeakingSub;

  bool _isDisposed = false;
  bool _isTogglingRecord = false;

  @override
  void onInit() {
    super.onInit();
    final rawArgs = Get.arguments;
    args = _initialArgs ?? (rawArgs is PracticeArgs ? rawArgs : null);
    unawaited(startSession());
  }

  /// Initializes [args] without starting a network Live session (for widget/unit tests).
  @visibleForTesting
  void setArgsForTest(PracticeArgs testArgs) {
    args = testArgs;
  }

  /// Connects to Gemini Live, initializes Android audio streams, and begins the session.
  Future<void> startSession() async {
    final currentArgs = args;
    if (currentArgs == null) {
      errorMessage.value = 'Parameter sesi latihan tidak ditemukan.';
      connectionState.value = LiveConnectionState.error;
      return;
    }

    await _cleanupActiveSession();
    _clearTutorAudioCache();
    if (_isDisposed) return;

    startedAt = DateTime.now();
    elapsedSeconds.value = 0;
    errorMessage.value = null;
    isPermissionPermanentlyDenied.value = false;
    isApiKeyMissingError.value = false;
    connectionState.value = LiveConnectionState.connecting;

    try {
      final settings = await repository.getSettings();
      if (_isDisposed) return;

      if (settings.apiKey.trim().isEmpty) {
        isApiKeyMissingError.value = true;
        errorMessage.value =
            'API Key Gemini belum diisi. Silakan isi di Pengaturan terlebih dahulu.';
        connectionState.value = LiveConnectionState.error;
        return;
      }

      final permission = await audioService
          .checkAndRequestMicrophonePermission();
      if (_isDisposed) return;

      if (permission != MicrophonePermissionStatus.granted) {
        isPermissionPermanentlyDenied.value =
            permission == MicrophonePermissionStatus.permanentlyDenied;
        errorMessage.value = isPermissionPermanentlyDenied.value
            ? 'Izin mikrofon diblokir permanen. Buka Pengaturan Aplikasi Android untuk mengizinkan mikrofon.'
            : 'Izin mikrofon ditolak. Aktifkan izin mikrofon untuk memulai latihan berbicara.';
        connectionState.value = LiveConnectionState.error;
        return;
      }

      audioService.clearRecordedBuffer();
      await audioService.initPlayer();
      if (_isDisposed) return;

      _bindProviderStreams();

      final systemInstruction = _buildSystemInstruction(currentArgs, settings);
      await liveProvider.connect(
        apiKey: settings.apiKey,
        model: settings.liveModel,
        systemInstruction: systemInstruction,
      );
      if (_isDisposed) return;

      hasEverConnected.value = true;
      connectionState.value = LiveConnectionState.connected;

      _micSub = audioService.micStream.listen((Uint8List chunk) {
        if (isMicActive.value &&
            !isAiSpeaking.value &&
            replayingTurnIndex.value == null &&
            liveProvider.currentState == LiveConnectionState.connected) {
          liveProvider.sendAudioChunk(chunk);
        }
      });

      // Manual Push/Tap-to-Record mode: keep microphone standby on session start
      // so the AI tutor greeting plays clearly through the speaker.
      isMicActive.value = false;
      _startTimer();

      liveProvider.sendTextMessage("Hello! I'm ready to practice.");
    } on GeminiLiveException catch (error) {
      errorMessage.value = error.message;
      connectionState.value = LiveConnectionState.error;
    } catch (error) {
      errorMessage.value = 'Gagal memulai sesi latihan: $error';
      connectionState.value = LiveConnectionState.error;
    }
  }

  void _bindProviderStreams() {
    _connStateSub = liveProvider.connectionStateStream.listen((state) {
      connectionState.value = state;
      if (state == LiveConnectionState.connected) {
        hasEverConnected.value = true;
        errorMessage.value = null;
      }
    });

    _errorSub = liveProvider.errorStream.listen((msg) {
      errorMessage.value = msg;
    });

    _audioOutSub = liveProvider.audioOutputStream.listen((Uint8List pcmBytes) {
      appendTutorAudioChunk(pcmBytes);
      isAiSpeaking.value = true;
      unawaited(
        audioService.feedPcm24k(pcmBytes).catchError((
          Object error,
          StackTrace stack,
        ) {
          debugPrint('PracticeController audio feed error: $error\n$stack');
        }),
      );
    });

    _audioSpeakingSub = audioService.isAiSpeaking.listen((bool speaking) {
      isAiSpeaking.value = speaking;
    });

    _interruptedSub = liveProvider.interruptedStream.listen((_) {
      isAiSpeaking.value = false;
      onTutorTurnComplete();
      unawaited(
        audioService.clearAndStopPlayer().catchError((
          Object error,
          StackTrace stack,
        ) {
          debugPrint('PracticeController interrupt stop error: $error\n$stack');
        }),
      );
    });

    _turnCompleteSub = liveProvider.turnCompleteStream.listen((_) {
      onTutorTurnComplete();
      if (!audioService.isAiSpeaking.value) {
        isAiSpeaking.value = false;
      }
    });

    _transcriptSub = liveProvider.transcriptStream.listen(
      _appendTranscriptTurn,
    );
  }

  /// Buffers incoming 24kHz PCM bytes for the active tutor turn (up to 3 MB).
  void appendTutorAudioChunk(Uint8List pcmBytes) {
    if (pcmBytes.isEmpty) return;
    _turnCompletePendingForBuffer = false;

    final remaining = maxTutorAudioBytesPerTurn - _currentTutorAudioBytes;
    if (remaining <= 0) return;

    if (pcmBytes.length <= remaining) {
      _currentTutorAudioBuffer.add(Uint8List.fromList(pcmBytes));
      _currentTutorAudioBytes += pcmBytes.length;
    } else {
      _currentTutorAudioBuffer.add(
        Uint8List.fromList(pcmBytes.sublist(0, remaining)),
      );
      _currentTutorAudioBytes += remaining;
    }
  }

  /// Finalizes the active tutor turn's audio buffer and attaches it to its bubble index.
  void onTutorTurnComplete() {
    if (_activeTutorTurnIndex != null) {
      _commitCurrentTutorAudio();
      _activeTutorTurnIndex = null;
      _turnCompletePendingForBuffer = false;
    } else if (_currentTutorAudioBuffer.isNotEmpty) {
      _turnCompletePendingForBuffer = true;
    }
  }

  void _commitCurrentTutorAudio() {
    final targetIndex = _activeTutorTurnIndex;
    if (targetIndex == null || _currentTutorAudioBuffer.isEmpty) return;

    final newBytes = _currentTutorAudioBuffer.takeBytes();
    _currentTutorAudioBytes = 0;
    if (newBytes.isEmpty) return;

    final existing = tutorAudioByTurnIndex[targetIndex];
    if (existing == null || existing.isEmpty) {
      tutorAudioByTurnIndex[targetIndex] = newBytes;
    } else {
      final combined = BytesBuilder(copy: false)
        ..add(existing)
        ..add(newBytes);
      tutorAudioByTurnIndex[targetIndex] = combined.takeBytes();
    }
  }

  void _clearTutorAudioCache() {
    _currentTutorAudioBuffer.clear();
    _currentTutorAudioBuffer = BytesBuilder(copy: false);
    _currentTutorAudioBytes = 0;
    _activeTutorTurnIndex = null;
    _turnCompletePendingForBuffer = false;
    tutorAudioByTurnIndex.clear();
    replayingTurnIndex.value = null;
  }

  void _startTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value++;
    });
  }

  void _appendTranscriptTurn(TranscriptTurnModel incoming) {
    final rawText = incoming.text;
    if (rawText.trim().isEmpty) return;

    if (incoming.role == 'user') {
      if (_activeTutorTurnIndex != null) {
        _commitCurrentTutorAudio();
        _activeTutorTurnIndex = null;
      } else if (_currentTutorAudioBuffer.isNotEmpty) {
        _currentTutorAudioBuffer.clear();
        _currentTutorAudioBytes = 0;
      }
      _turnCompletePendingForBuffer = false;
    }

    if (transcriptTurns.isNotEmpty &&
        transcriptTurns.last.role == incoming.role) {
      final targetIndex = transcriptTurns.length - 1;
      final last = transcriptTurns.last;
      final merged = _mergeTranscriptText(last.text, rawText);
      transcriptTurns[targetIndex] = TranscriptTurnModel(
        role: last.role,
        text: merged,
        timestamp: incoming.timestamp,
      );
      if (incoming.role == 'tutor') {
        _activeTutorTurnIndex = targetIndex;
      }
    } else {
      transcriptTurns.add(
        TranscriptTurnModel(
          role: incoming.role,
          text: rawText.trimLeft(),
          timestamp: incoming.timestamp,
        ),
      );
      if (incoming.role == 'tutor') {
        _activeTutorTurnIndex = transcriptTurns.length - 1;
      }
    }

    if (incoming.role == 'tutor' &&
        _turnCompletePendingForBuffer &&
        _currentTutorAudioBuffer.isNotEmpty) {
      _commitCurrentTutorAudio();
      _activeTutorTurnIndex = null;
      _turnCompletePendingForBuffer = false;
    }

    _scrollToBottom();
  }

  String _mergeTranscriptText(String previous, String incoming) {
    if (previous.isEmpty) return incoming.trimLeft();
    final prevEndsWithSpace = RegExp(r'\s$').hasMatch(previous);
    final nextStartsWithSpace = RegExp(r'^\s').hasMatch(incoming);
    final nextStartsWithPunctuation = RegExp(
      r'^[.,!?;:\x27"\)\]…]',
    ).hasMatch(incoming);

    if (prevEndsWithSpace || nextStartsWithSpace || nextStartsWithPunctuation) {
      return '$previous$incoming';
    }
    return '$previous $incoming';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed ||
          !transcriptScrollController.hasClients ||
          transcriptScrollController.positions.length != 1) {
        return;
      }
      final position = transcriptScrollController.position;
      if (!position.hasContentDimensions) return;
      transcriptScrollController.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  String _buildSystemInstruction(
    PracticeArgs currentArgs,
    AppSetting settings,
  ) {
    final cefr = currentArgs.targetCefrLevel.toUpperCase();
    final isBeginnerBilingual =
        settings.bilingualBeginnerSupport && (cefr == 'A1' || cefr == 'A2');

    final languageGuide = isBeginnerBilingual
        ? 'The learner is at beginner CEFR $cefr. Speak slowly using clear, simple English sentences. If the learner seems stuck or asks in Indonesian, you may give a brief supportive explanation in Bahasa Indonesia, then gently guide them back to English.'
        : 'The learner is practicing at CEFR $cefr. Conduct the conversation in natural, encouraging Full English and model gentle corrections naturally.';

    final modeGuide = currentArgs.isTimedSpeechMode
        ? 'This is a ${currentArgs.targetDurationSec}-second guided speaking prompt. Open with 1 short warm sentence inviting the learner to speak about the prompt, then mostly listen attentively without interrupting too often. Ask at most one brief follow-up only if the learner finishes early.'
        : 'This is a natural two-way live roleplay conversation. Keep your turns concise (1–3 sentences) so the learner does most of the speaking.';

    final lessonInstruction =
        currentArgs.lesson?.systemInstruction.trim() ?? '';
    final topicLine =
        currentArgs.customTopic != null &&
            currentArgs.customTopic!.trim().isNotEmpty
        ? 'Topic: ${currentArgs.customTopic}'
        : '';

    final targetWords = currentArgs.targetVocabulary
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .take(10)
        .toList(growable: false);
    final subDeckHeader =
        currentArgs.vocabSubDeckTitle != null &&
            currentArgs.vocabSubDeckTitle!.trim().isNotEmpty
        ? ' (Sub-Deck: ${currentArgs.vocabSubDeckTitle!.trim()})'
        : '';
    final targetVocabBlock = targetWords.isEmpty
        ? ''
        : '''
Target Vocabulary Practice$subDeckHeader:
Target Words (max 10): ${targetWords.join(', ')}
Vocabulary Practice Instructions:
- Lead a natural two-way conversation matching the context/topic above.
- Gradually encourage and prompt the learner to use these target words naturally (1–2 target words per turn; do NOT push all words at once).
- If the learner seems to forget or hesitate on a target word, give a brief explanation of its meaning and 1 short example sentence, then invite them to try using it.''';

    return '''
You are a warm, encouraging personal English speaking tutor (similar to Stimuler).
Target CEFR Level: $cefr
Session Type: ${currentArgs.sessionType}
Title: ${currentArgs.title}
Scenario Prompt: ${currentArgs.scenarioPrompt}
$topicLine
$lessonInstruction
$targetVocabBlock

$languageGuide
$modeGuide
''';
  }

  /// Builds the Gemini Live system instruction for deterministic unit testing.
  @visibleForTesting
  String buildSystemInstructionForTest(
    PracticeArgs currentArgs,
    AppSetting settings,
  ) => _buildSystemInstruction(currentArgs, settings);

  /// Returns `true` when any user turn in [transcriptTurns] uses [targetWord]
  /// as a complete word or phrase (case-insensitive, safe word boundaries).
  bool isTargetWordPracticed(String targetWord) {
    final normalized = targetWord.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map(RegExp.escape)
        .toList(growable: false);
    if (tokens.isEmpty) return false;

    final phrasePattern = tokens.join(r'\s+');
    final pattern = RegExp(
      r'(?<![a-z0-9])' + phrasePattern + r'(?![a-z0-9])',
      caseSensitive: false,
    );

    for (final turn in transcriptTurns) {
      if (turn.role != 'user') continue;
      if (pattern.hasMatch(turn.text)) {
        return true;
      }
    }
    return false;
  }

  /// Number of target vocabulary words already used by the user in [transcriptTurns].
  int get practicedTargetWordsCount {
    final targets = args?.targetVocabulary ?? const <String>[];
    var count = 0;
    for (final word in targets) {
      if (isTargetWordPracticed(word)) {
        count++;
      }
    }
    return count;
  }

  /// Toggles manual recording: standby -> record -> stop & send audioStreamEnd.
  Future<void> toggleMic() => toggleRecordAndSend();

  /// Starts or stops manual voice recording and triggers Gemini Live turn processing.
  Future<void> toggleRecordAndSend() async {
    if (_isDisposed || _isTogglingRecord) return;
    _isTogglingRecord = true;

    try {
      if (!isMicActive.value) {
        if (connectionState.value != LiveConnectionState.connected) {
          final colorScheme = Get.theme.colorScheme;
          Get.snackbar(
            'Koneksi Belum Siap',
            'Tunggu hingga koneksi Gemini Live terhubung sebelum merekam.',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            backgroundColor: colorScheme.surfaceContainerHighest,
            colorText: colorScheme.onSurface,
          );
          return;
        }

        await stopAiSpeaking();
        final currentArgs = args;
        await audioService.startMicStream(
          captureBufferForEval: currentArgs?.isTimedSpeechMode ?? false,
          appendBuffer: true,
          maxCaptureSeconds: 90,
        );
        if (_isDisposed) {
          await audioService.stopMicStream();
          return;
        }
        isMicActive.value = true;
      } else {
        isMicActive.value = false;
        await audioService.stopMicStream();
        liveProvider.sendAudioStreamEnd();
      }
    } catch (error) {
      isMicActive.value = false;
      errorMessage.value = 'Gagal mengaktifkan mikrofon: $error';
    } finally {
      _isTogglingRecord = false;
    }
  }

  /// Interrupts active tutor audio or replay so the learner can speak immediately.
  Future<void> stopAiSpeaking() async {
    replayingTurnIndex.value = null;
    isAiSpeaking.value = false;
    await audioService.clearAndStopPlayer();
  }

  /// Replays the cached 24kHz audio for tutor bubble at [turnIndex], or stops if playing.
  Future<void> replayTutorTurn(int turnIndex) async {
    if (replayingTurnIndex.value == turnIndex) {
      await stopReplay();
      return;
    }

    final audioBytes = tutorAudioByTurnIndex[turnIndex];
    if (audioBytes == null || audioBytes.isEmpty) return;

    replayingTurnIndex.value = turnIndex;
    await audioService.playPcm24kBuffer(
      audioBytes,
      onCompleted: () {
        if (replayingTurnIndex.value == turnIndex) {
          replayingTurnIndex.value = null;
        }
      },
    );
  }

  /// Stops an active bubble replay cleanly.
  Future<void> stopReplay() async {
    replayingTurnIndex.value = null;
    await audioService.clearAndStopPlayer();
  }

  void toggleTextInput() {
    showTextInput.toggle();
  }

  void togglePromptExpanded() {
    isPromptExpanded.toggle();
  }

  /// Sends a text fallback message into the live session and records it in transcript.
  void sendTextFallback() {
    final text = textFallbackController.text.trim();
    if (text.isEmpty ||
        liveProvider.currentState != LiveConnectionState.connected) {
      return;
    }

    liveProvider.sendTextMessage(text);
    _appendTranscriptTurn(
      TranscriptTurnModel(role: 'user', text: text, timestamp: DateTime.now()),
    );
    textFallbackController.clear();
  }

  Future<void> openDeviceSettings() async {
    await audioService.openDeviceAppSettings();
  }

  /// Confirms before discarding an active speaking session.
  Future<bool> confirmExitSession() async {
    final isActive =
        connectionState.value == LiveConnectionState.connected ||
        connectionState.value == LiveConnectionState.connecting ||
        transcriptTurns.isNotEmpty ||
        elapsedSeconds.value > 0;

    if (!isActive) {
      await _cleanupActiveSession();
      _clearTutorAudioCache();
      return true;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Akhiri Sesi?'),
        content: const Text(
          'Akhiri sesi tanpa menilai? Percakapan ini tidak akan disimpan ke riwayat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Lanjut Latihan'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cleanupActiveSession();
      _clearTutorAudioCache();
      return true;
    }
    return false;
  }

  /// Stops capture/WebSocket and prepares captured transcript + WAV for evaluation.
  Future<void> finishAndEvaluate() async {
    final currentArgs = args;
    if (currentArgs == null) return;

    final hasUserTurn = transcriptTurns.any((t) => t.role == 'user');
    if (!hasUserTurn && elapsedSeconds.value < 5) {
      final colorScheme = Get.theme.colorScheme;
      Get.snackbar(
        'Belum Cukup Data',
        'Berbicaralah minimal 5 detik atau kirim 1 pesan sebelum menilai sesi.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: colorScheme.surfaceContainerHighest,
        colorText: colorScheme.onSurface,
      );
      return;
    }

    await audioService.stopMicStream();
    isMicActive.value = false;

    final Uint8List? wavBytes = currentArgs.isTimedSpeechMode
        ? audioService.buildRecordedWavBytes()
        : null;
    final endedAt = DateTime.now();
    final duration = elapsedSeconds.value;
    final transcriptSnapshot = transcriptTurns.toList(growable: false);

    await _cleanupActiveSession();
    _clearTutorAudioCache();
    audioService.clearRecordedBuffer();

    Get.offNamed<void>(
      Routes.SESSION_RESULT,
      arguments: SessionResultArgs(
        practiceArgs: currentArgs,
        transcript: transcriptSnapshot,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSec: duration,
        recordedWavBytes: wavBytes,
      ),
    );
  }

  String get formattedElapsed {
    final total = elapsedSeconds.value;
    final mins = (total ~/ 60).toString().padLeft(2, '0');
    final secs = (total % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String formatSeconds(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _cleanupActiveSession() async {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    await _micSub?.cancel();
    _micSub = null;
    await _connStateSub?.cancel();
    _connStateSub = null;
    await _errorSub?.cancel();
    _errorSub = null;
    await _audioOutSub?.cancel();
    _audioOutSub = null;
    await _interruptedSub?.cancel();
    _interruptedSub = null;
    await _turnCompleteSub?.cancel();
    _turnCompleteSub = null;
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    await _audioSpeakingSub?.cancel();
    _audioSpeakingSub = null;

    isMicActive.value = false;
    isAiSpeaking.value = false;

    await audioService.stopMicStream();
    await audioService.clearAndStopPlayer();
    await liveProvider.disconnect();
    _clearTutorAudioCache();
  }

  /// Exposes transcript append for deterministic unit testing of audio cache pairing.
  void appendTranscriptTurnForTest(TranscriptTurnModel turn) {
    _appendTranscriptTurn(turn);
  }

  /// Exposes audio cache clearing for deterministic unit testing.
  void clearTutorAudioCacheForTest() => _clearTutorAudioCache();

  @override
  void onClose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _clearTutorAudioCache();
    unawaited(
      _cleanupActiveSession().then((_) {
        audioService.clearRecordedBuffer();
      }),
    );
    textFallbackController.dispose();
    transcriptScrollController.dispose();
    super.onClose();
  }
}
