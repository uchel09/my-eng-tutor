import 'dart:async';

import 'package:get/get.dart';

import '../../../core/constants/gemini_constants.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../../../data/models/session_result_args.dart';
import '../../../data/models/speech_insight_model.dart';
import '../../../data/models/transcript_turn_model.dart';
import '../../../data/providers/gemini_rest_provider.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../routes/app_pages.dart';
import '../../flashcards/widgets/flashcard_dialogs.dart';

/// Evaluates finished speaking sessions or replays saved session insights.
class SessionResultController extends GetxController {
  SessionResultController({required this.repository});

  final TutorRepository repository;

  late final SessionResultArgs? args;

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<SpeechInsightModel> insight = Rxn<SpeechInsightModel>();
  final RxBool passed = false.obs;
  final RxBool didUnlockProgress = false.obs;
  final RxnString unlockedLabel = RxnString();
  final RxString sessionTitle = ''.obs;
  final RxInt durationSec = 0.obs;
  final RxString sessionType = 'lesson'.obs;
  final RxInt minPassScore = GeminiConstants.minPassScore.obs;
  final RxList<TranscriptTurnModel> transcriptTurns =
      <TranscriptTurnModel>[].obs;
  final RxBool isViewingHistory = false.obs;
  final RxMap<String, int> savedVocabIdsByWord = <String, int>{}.obs;
  final RxMap<String, String> savedFlashcardTargetsByWord =
      <String, String>{}.obs;

  int? _savedSessionId;

  @override
  void onInit() {
    super.onInit();
    final rawArgs = Get.arguments;
    args = rawArgs is SessionResultArgs ? rawArgs : null;

    if (args == null) {
      errorMessage.value = 'Data hasil sesi tidak ditemukan.';
      isLoading.value = false;
      return;
    }

    final existing = args!.existingSession;
    if (existing != null) {
      isViewingHistory.value = true;
      unawaited(_loadExistingSession(existing, args!.sessionTitle));
      return;
    }

    final practiceArgs = args!.practiceArgs;
    if (practiceArgs == null) {
      errorMessage.value = 'Parameter sesi latihan tidak valid.';
      isLoading.value = false;
      return;
    }

    sessionTitle.value = practiceArgs.title;
    durationSec.value = args!.durationSec;
    sessionType.value = practiceArgs.sessionType;
    minPassScore.value =
        practiceArgs.level?.minPassScore ?? GeminiConstants.minPassScore;
    transcriptTurns.assignAll(args!.transcript);

    unawaited(evaluateSession());
  }

  Future<void> _loadExistingSession(
    PracticeSession existing,
    String? customTitle,
  ) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      _savedSessionId = existing.id;
      sessionType.value = existing.sessionType;
      durationSec.value = existing.durationSec;
      passed.value = existing.passed;
      sessionTitle.value = customTitle ?? _defaultTitleFor(existing.sessionType);
      transcriptTurns.assignAll(
        TranscriptTurnModel.decodeList(existing.transcriptJson),
      );

      final mistakesRows = await repository.getMistakesForSession(existing.id);
      final vocabRows = await repository.getVocabForSession(existing.id);

      savedVocabIdsByWord.clear();
      savedFlashcardTargetsByWord.clear();
      for (final vocab in vocabRows) {
        savedVocabIdsByWord[_vocabKey(vocab.word)] = vocab.id;
      }

      insight.value = SpeechInsightModel(
        overallScore: existing.overallScore,
        fluencyScore: existing.fluencyScore,
        grammarScore: existing.grammarScore,
        vocabScore: existing.vocabScore,
        pronunciationScore: existing.pronunciationScore,
        fillerCount: existing.fillerCount,
        detectedFillers: const <String>[],
        aiSummary: existing.aiSummary,
        mistakes: mistakesRows
            .map(
              (m) => MistakeItemModel(
                originalSentence: m.originalSentence,
                correctedSentence: m.correctedSentence,
                explanation: m.explanation,
                category: m.category,
              ),
            )
            .toList(growable: false),
        vocabSuggestions: vocabRows
            .map(
              (v) => VocabSuggestionModel(
                word: v.word,
                meaningId: v.meaningId,
                exampleSentence: v.exampleSentence,
                cefrLevel: v.cefrLevel,
              ),
            )
            .toList(growable: false),
      );
    } catch (error) {
      errorMessage.value = 'Gagal memuat detail sesi tersimpan: $error';
    } finally {
      isLoading.value = false;
    }
  }

  /// Calls Gemini REST evaluation, persists insights into Drift, and updates unlock state.
  Future<void> evaluateSession() async {
    final currentArgs = args;
    final practiceArgs = currentArgs?.practiceArgs;
    if (currentArgs == null || practiceArgs == null) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final startedAt = currentArgs.startedAt ??
          DateTime.now().subtract(Duration(seconds: currentArgs.durationSec));
      final endedAt = currentArgs.endedAt ?? DateTime.now();

      final output = await repository.evaluateAndSaveSession(
        lessonId: practiceArgs.lesson?.id,
        sessionType: practiceArgs.sessionType,
        targetCefrLevel: practiceArgs.targetCefrLevel,
        lessonTitle: practiceArgs.title,
        scenarioPrompt: practiceArgs.scenarioPrompt,
        startedAt: startedAt,
        endedAt: endedAt,
        durationSec: currentArgs.durationSec,
        transcript: currentArgs.transcript,
        recordedAudioWavBytes: currentArgs.recordedWavBytes,
      );

      _savedSessionId = output.sessionId;
      savedVocabIdsByWord.clear();
      savedFlashcardTargetsByWord.clear();
      insight.value = output.insight;
      passed.value = output.passed;
      didUnlockProgress.value = output.didUnlockProgress;

      if (output.didUnlockProgress && practiceArgs.lesson != null) {
        unlockedLabel.value = await repository.findNextUnlockedLabelAfter(
          practiceArgs.lesson!.id,
        );
      }
    } on GeminiApiException catch (error) {
      errorMessage.value = error.message;
    } catch (error) {
      errorMessage.value = 'Gagal mengevaluasi sesi berbicara: $error';
    } finally {
      isLoading.value = false;
    }
  }

  String _vocabKey(String word) => word.trim().toLowerCase();

  /// Whether [word] from this session is currently saved in the user's Vocab Bank.
  bool isVocabSaved(String word) {
    return savedVocabIdsByWord.containsKey(_vocabKey(word));
  }

  /// Toggles saving or removing a suggested vocabulary item in Drift Vocab Bank.
  Future<void> toggleSaveVocab(VocabSuggestionModel vocab) async {
    final key = _vocabKey(vocab.word);
    if (key.isEmpty) return;

    final existingId = savedVocabIdsByWord[key];
    if (existingId != null) {
      await repository.deleteVocab(existingId);
      savedVocabIdsByWord.remove(key);
      return;
    }

    final insertedId = await repository.saveSuggestedVocab(
      sessionId: _savedSessionId,
      word: vocab.word,
      meaningId: vocab.meaningId,
      exampleSentence: vocab.exampleSentence,
      cefrLevel: vocab.cefrLevel,
    );
    savedVocabIdsByWord[key] = insertedId;
  }

  /// Saves all unsaved vocabulary suggestions from the current insight into Vocab Bank.
  Future<void> saveAllSuggestedVocab() async {
    final suggestions =
        insight.value?.vocabSuggestions ?? const <VocabSuggestionModel>[];
    for (final vocab in suggestions) {
      if (isVocabSaved(vocab.word)) continue;
      final key = _vocabKey(vocab.word);
      if (key.isEmpty) continue;
      final insertedId = await repository.saveSuggestedVocab(
        sessionId: _savedSessionId,
        word: vocab.word,
        meaningId: vocab.meaningId,
        exampleSentence: vocab.exampleSentence,
        cefrLevel: vocab.cefrLevel,
      );
      savedVocabIdsByWord[key] = insertedId;
    }
  }

  /// Whether [word] has already been saved to a Flashcard Sub-Deck in this session view.
  bool isVocabSavedToFlashcard(String word) {
    return savedFlashcardTargetsByWord.containsKey(_vocabKey(word));
  }

  /// Returns `"Deck / Sub-Deck"` label if [word] was saved to Flashcards.
  String? savedFlashcardTargetLabel(String word) {
    return savedFlashcardTargetsByWord[_vocabKey(word)];
  }

  Future<bool> _persistFlashcardForVocab({
    required VocabSuggestionModel vocab,
    required int subDeckId,
    required String targetLabel,
  }) async {
    final key = _vocabKey(vocab.word);
    if (key.isEmpty) return false;

    final example = vocab.exampleSentence.trim();
    final examples = example.isNotEmpty
        ? <FlashcardExampleItem>[
            FlashcardExampleItem(
              tense: 'Context',
              en: example,
              id: '',
            ),
          ]
        : const <FlashcardExampleItem>[];

    await repository.createFlashcard(
      subDeckId: subDeckId,
      word: vocab.word.trim(),
      meaningId: vocab.meaningId.trim(),
      examples: examples,
    );
    savedFlashcardTargetsByWord[key] = targetLabel;
    return true;
  }

  /// Saves a suggested [vocab] item into the selected Flashcard [subDeckId].
  Future<void> saveVocabToFlashcardSubDeck({
    required VocabSuggestionModel vocab,
    required int subDeckId,
    required String targetLabel,
  }) async {
    final saved = await _persistFlashcardForVocab(
      vocab: vocab,
      subDeckId: subDeckId,
      targetLabel: targetLabel,
    );
    if (!saved) return;

    savedFlashcardTargetsByWord.refresh();
    showFlashcardSnackbar(
      title: 'Tersimpan ke Flashcard',
      message: '"${vocab.word}" disimpan ke $targetLabel.',
    );
  }

  /// Saves all unsaved suggested vocabulary items to the selected [subDeckId].
  Future<void> saveAllVocabToFlashcardSubDeck({
    required int subDeckId,
    required String targetLabel,
  }) async {
    final suggestions =
        insight.value?.vocabSuggestions ?? const <VocabSuggestionModel>[];
    var savedCount = 0;

    for (final vocab in suggestions) {
      if (isVocabSavedToFlashcard(vocab.word)) continue;
      final saved = await _persistFlashcardForVocab(
        vocab: vocab,
        subDeckId: subDeckId,
        targetLabel: targetLabel,
      );
      if (saved) savedCount++;
    }

    if (savedCount > 0) {
      savedFlashcardTargetsByWord.refresh();
      showFlashcardSnackbar(
        title: 'Flashcard Disimpan',
        message: '$savedCount kosakata disimpan ke $targetLabel.',
      );
    }
  }

  /// Retries Gemini evaluation without losing the captured transcript or WAV audio.
  Future<void> retryEvaluation() async {
    await evaluateSession();
  }

  /// Restarts the exact same practice mission or mode.
  void retryPractice() {
    final practiceArgs = args?.practiceArgs;
    if (practiceArgs == null) return;
    Get.offNamed<void>(Routes.PRACTICE, arguments: practiceArgs);
  }

  /// Returns to the previous root tab (Home / Roadmap / Review).
  void finishToHome() {
    Get.back<void>();
  }

  String get formattedDuration {
    final total = durationSec.value;
    final mins = (total ~/ 60).toString().padLeft(2, '0');
    final secs = (total % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String _defaultTitleFor(String type) {
    switch (type) {
      case 'placement':
        return 'Quick Placement Test';
      case 'free_talk':
        return 'Free Talk Session';
      default:
        return 'Speaking Mission';
    }
  }
}
