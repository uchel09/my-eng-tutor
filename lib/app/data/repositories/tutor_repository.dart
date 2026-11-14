import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Value;

import '../../core/constants/gemini_constants.dart';
import '../local/app_database.dart';
import '../local/daos/flashcard_dao.dart';
import '../local/daos/roadmap_dao.dart';
import '../models/speech_insight_model.dart';
import '../models/transcript_turn_model.dart';
import '../providers/gemini_live_provider.dart';
import '../providers/gemini_rest_provider.dart';

/// Result returned after evaluating and persisting a speaking session.
class SessionEvaluationOutput {
  const SessionEvaluationOutput({
    required this.sessionId,
    required this.insight,
    required this.passed,
    required this.didUnlockProgress,
  });

  final int sessionId;
  final SpeechInsightModel insight;
  final bool passed;
  final bool didUnlockProgress;
}

/// Coordinates local Drift persistence with Gemini Live and REST services.
class TutorRepository {
  TutorRepository({
    required AppDatabase database,
    required GeminiRestProvider restProvider,
    GeminiLiveProvider? liveProvider,
  })  : _database = database,
        _restProvider = restProvider,
        _liveProvider = liveProvider;

  final AppDatabase _database;
  final GeminiRestProvider _restProvider;
  final GeminiLiveProvider? _liveProvider;

  GeminiLiveProvider? get _resolvedLiveProvider {
    if (_liveProvider != null) return _liveProvider;
    if (Get.isRegistered<GeminiLiveProvider>()) {
      return Get.find<GeminiLiveProvider>();
    }
    return null;
  }

  // --- Roadmap ---

  Stream<List<LevelWithLessons>> watchRoadmap() {
    return _database.roadmapDao.watchAllLevelsWithLessons();
  }

  Stream<Lesson?> watchLessonById(int id) {
    return _database.roadmapDao.watchLessonById(id);
  }

  Future<void> resetProgress() {
    return _database.roadmapDao.resetProgress();
  }

  // --- Settings & Backup ---

  Stream<AppSetting> watchSettings() {
    return _database.settingsDao.watchSettings();
  }

  Future<AppSetting> getSettings() {
    return _database.settingsDao.getSettings();
  }

  Future<void> updateSettings(AppSettingsCompanion entry) {
    return _database.settingsDao.updateSettings(entry);
  }

  Future<Map<String, dynamic>> exportBackupJson() {
    return _database.settingsDao.exportAllDataAsMap();
  }

  Future<void> importBackupJson(Map<String, dynamic> json) {
    return _database.settingsDao.importAllDataFromMap(json);
  }

  // --- Practice History, Mistakes & Vocab ---

  Stream<List<PracticeSession>> watchRecentSessions({int limit = 25}) {
    return _database.practiceDao.watchRecentSessions(limit: limit);
  }

  Stream<List<Mistake>> watchAllMistakes() {
    return _database.practiceDao.watchAllMistakes();
  }

  Stream<List<VocabItem>> watchAllVocab() {
    return _database.practiceDao.watchAllVocab();
  }

  Future<int> addManualVocab({
    required String word,
    required String meaningId,
    required String exampleSentence,
    required String cefrLevel,
  }) {
    return _database.practiceDao.addManualVocab(
      word: word,
      meaningId: meaningId,
      exampleSentence: exampleSentence,
      cefrLevel: cefrLevel,
    );
  }

  Future<int> saveSuggestedVocab({
    int? sessionId,
    required String word,
    required String meaningId,
    required String exampleSentence,
    required String cefrLevel,
  }) {
    return _database.practiceDao.saveVocabItem(
      sessionId: sessionId,
      word: word,
      meaningId: meaningId,
      exampleSentence: exampleSentence,
      cefrLevel: cefrLevel,
    );
  }

  Future<void> incrementVocabMastery(int id) {
    return _database.practiceDao.incrementVocabMastery(id);
  }

  Future<int> deleteVocab(int id) {
    return _database.practiceDao.deleteVocab(id);
  }

  /// Returns all recorded mistakes associated with [sessionId].
  Future<List<Mistake>> getMistakesForSession(int sessionId) async {
    final all = await watchAllMistakes().first;
    return all.where((m) => m.sessionId == sessionId).toList(growable: false);
  }

  /// Returns all saved vocabulary items associated with [sessionId].
  Future<List<VocabItem>> getVocabForSession(int sessionId) async {
    final all = await watchAllVocab().first;
    return all.where((v) => v.sessionId == sessionId).toList(growable: false);
  }

  /// Resolves a human-readable label for the next unlocked lesson or level
  /// after [completedLessonId] is completed, or `null` if none was unlocked.
  Future<String?> findNextUnlockedLabelAfter(int completedLessonId) async {
    final roadmap = await watchRoadmap().first;
    for (var levelIdx = 0; levelIdx < roadmap.length; levelIdx++) {
      final group = roadmap[levelIdx];
      for (var lessonIdx = 0; lessonIdx < group.lessons.length; lessonIdx++) {
        final lesson = group.lessons[lessonIdx];
        if (lesson.id != completedLessonId) continue;
        if (!lesson.isCompleted) return null;

        if (lessonIdx + 1 < group.lessons.length) {
          final nextLesson = group.lessons[lessonIdx + 1];
          return nextLesson.isUnlocked
              ? '${group.level.code}: ${nextLesson.title}'
              : null;
        }

        if (levelIdx + 1 < roadmap.length) {
          final nextGroup = roadmap[levelIdx + 1];
          if (!nextGroup.level.isUnlocked) return null;
          if (nextGroup.lessons.isNotEmpty) {
            return '${nextGroup.level.code} ${nextGroup.level.title}: ${nextGroup.lessons.first.title}';
          }
          return '${nextGroup.level.code} ${nextGroup.level.title}';
        }

        return null;
      }
    }
    return null;
  }

  // --- Gemini REST & Session Evaluation ---

  Future<AvailableGeminiModels> fetchAvailableModels({
    required String apiKey,
  }) {
    return _restProvider.fetchAvailableModels(apiKey: apiKey);
  }

  Future<String> testApiKey({
    required String apiKey,
    required String model,
  }) {
    return _restProvider.testConnection(apiKey: apiKey, model: model);
  }

  /// Evaluates a finished speaking session via Gemini REST, persists the
  /// session + mistakes + vocabulary into Drift, and unlocks progression.
  Future<SessionEvaluationOutput> evaluateAndSaveSession({
    int? lessonId,
    required String sessionType,
    required String targetCefrLevel,
    required String lessonTitle,
    required String scenarioPrompt,
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSec,
    required List<TranscriptTurnModel> transcript,
    Uint8List? recordedAudioWavBytes,
  }) async {
    final settings = await getSettings();

    final insight = await _restProvider.evaluateSpeakingSession(
      apiKey: settings.apiKey,
      model: settings.scoringModel,
      targetCefrLevel: targetCefrLevel,
      sessionType: sessionType,
      lessonTitle: lessonTitle,
      scenarioPrompt: scenarioPrompt,
      bilingualBeginnerSupport: settings.bilingualBeginnerSupport,
      transcript: transcript,
      recordedAudioWavBytes: recordedAudioWavBytes,
    );

    final minPassScore = await _resolveMinPassScore(lessonId);
    final passed = insight.overallScore >= minPassScore;
    final now = endedAt;

    final mistakeCompanions = insight.mistakes
        .map(
          (m) => MistakesCompanion.insert(
            sessionId: 0,
            originalSentence: m.originalSentence,
            correctedSentence: m.correctedSentence,
            explanation: m.explanation,
            category: m.category,
            createdAt: now,
          ),
        )
        .toList(growable: false);

    final sessionId = await _database.practiceDao.saveSessionWithInsights(
      session: PracticeSessionsCompanion.insert(
        lessonId: Value(lessonId),
        sessionType: sessionType,
        startedAt: startedAt,
        endedAt: Value(endedAt),
        durationSec: Value(durationSec),
        transcriptJson: Value(TranscriptTurnModel.encodeList(transcript)),
        overallScore: Value(insight.overallScore),
        fluencyScore: Value(insight.fluencyScore),
        grammarScore: Value(insight.grammarScore),
        vocabScore: Value(insight.vocabScore),
        pronunciationScore: Value(insight.pronunciationScore),
        fillerCount: Value(insight.fillerCount),
        aiSummary: Value(insight.aiSummary),
        passed: Value(passed),
      ),
      mistakesList: mistakeCompanions,
      vocabList: const <VocabItemsCompanion>[],
    );

    var didUnlockProgress = false;
    if (lessonId != null) {
      didUnlockProgress = await _database.roadmapDao
          .unlockNextLessonOrLevel(lessonId, insight.overallScore);
    }

    if (sessionType == 'placement' && insight.recommendedCefrLevel != null) {
      await _database.roadmapDao
          .setLevelUnlocked(insight.recommendedCefrLevel!);
      didUnlockProgress = true;
    }

    return SessionEvaluationOutput(
      sessionId: sessionId,
      insight: insight,
      passed: passed,
      didUnlockProgress: didUnlockProgress,
    );
  }

  Future<int> _resolveMinPassScore(int? lessonId) async {
    if (lessonId == null) return GeminiConstants.minPassScore;
    final roadmap = await watchRoadmap().first;
    for (final entry in roadmap) {
      for (final lesson in entry.lessons) {
        if (lesson.id == lessonId) {
          return entry.level.minPassScore;
        }
      }
    }
    return GeminiConstants.minPassScore;
  }

  // --- Flashcard 3-Level CRUD & Review ---

  Stream<List<DeckWithStats>> watchDecksWithStats() {
    return _database.flashcardDao.watchDecksWithStats();
  }

  Future<List<DeckWithStats>> getDecksWithStats() {
    return _database.flashcardDao.getDecksWithStats();
  }

  Stream<List<SubDeckWithStats>> watchSubDecksWithStats(int deckId) {
    return _database.flashcardDao.watchSubDecksWithStats(deckId);
  }

  Future<List<FlashcardSubDeck>> getSubDecksByDeck(int deckId) {
    return _database.flashcardDao.getSubDecksByDeck(deckId);
  }

  Stream<List<Flashcard>> watchFlashcardsBySubDeck(int subDeckId) {
    return _database.flashcardDao.watchFlashcardsBySubDeck(subDeckId);
  }

  Future<List<Flashcard>> getCardsBySubDeck(int subDeckId) {
    return _database.flashcardDao.getCardsBySubDeck(subDeckId);
  }

  Future<List<Flashcard>> getCardsByDeck(int deckId) {
    return _database.flashcardDao.getCardsByDeck(deckId);
  }

  Future<int> createDeck({required String name, String? description}) {
    return _database.flashcardDao.createDeck(
      name: name,
      description: description,
    );
  }

  Future<int> getOrCreateDeckByName({
    required String name,
    String? description,
  }) {
    return _database.flashcardDao.getOrCreateDeckByName(
      name: name,
      description: description,
    );
  }

  Future<void> renameDeck(int deckId, String newName) {
    return _database.flashcardDao.renameDeck(deckId, newName);
  }

  Future<void> deleteDeck(int deckId) {
    return _database.flashcardDao.deleteDeck(deckId);
  }

  Future<int> createSubDeck({
    required int deckId,
    required String name,
    String? description,
  }) {
    return _database.flashcardDao.createSubDeck(
      deckId: deckId,
      name: name,
      description: description,
    );
  }

  Future<int> getOrCreateSubDeckByName({
    required int deckId,
    required String name,
    String? description,
  }) {
    return _database.flashcardDao.getOrCreateSubDeckByName(
      deckId: deckId,
      name: name,
      description: description,
    );
  }

  Future<Set<String>> getExistingWordsInDeck(int deckId) {
    return _database.flashcardDao.getExistingWordsInDeck(deckId);
  }

  Future<int> bulkUpsertFlashcards({
    required int subDeckId,
    required List<FlashcardSeedInput> items,
  }) {
    return _database.flashcardDao.bulkUpsertFlashcards(
      subDeckId: subDeckId,
      items: items,
    );
  }

  Future<void> renameSubDeck(int subDeckId, String newName) {
    return _database.flashcardDao.renameSubDeck(subDeckId, newName);
  }

  Future<void> deleteSubDeck(int subDeckId) {
    return _database.flashcardDao.deleteSubDeck(subDeckId);
  }

  Future<int> createFlashcard({
    required int subDeckId,
    required String word,
    String? phonetic,
    required String meaningId,
    String wordType = 'non_verb',
    List<String>? partsOfSpeech,
    List<FlashcardExampleItem> examples = const [],
    List<FlashcardExampleItem>? verbTensesExamples,
    String aiConversation = '',
  }) {
    return _database.flashcardDao.createFlashcard(
      subDeckId: subDeckId,
      word: word,
      phonetic: phonetic,
      meaningId: meaningId,
      wordType: wordType,
      partsOfSpeech: partsOfSpeech,
      examples: examples,
      verbTensesExamples: verbTensesExamples,
      aiConversation: aiConversation,
    );
  }

  Future<void> updateFlashcardPracticeContent({
    required int cardId,
    String? word,
    String? phonetic,
    String? meaningId,
    String? wordType,
    List<String>? partsOfSpeech,
    List<FlashcardExampleItem>? examples,
    List<FlashcardExampleItem>? verbTensesExamples,
    String? aiConversation,
  }) {
    return _database.flashcardDao.updateFlashcardPracticeContent(
      cardId: cardId,
      word: word,
      phonetic: phonetic,
      meaningId: meaningId,
      wordType: wordType,
      partsOfSpeech: partsOfSpeech,
      examples: examples,
      verbTensesExamples: verbTensesExamples,
      aiConversation: aiConversation,
    );
  }

  Future<void> recordCardReview({
    required int cardId,
    required bool isCorrect,
  }) {
    return _database.flashcardDao.recordCardReview(
      cardId: cardId,
      isCorrect: isCorrect,
    );
  }

  Future<void> updateCardStudyStatus({
    required int cardId,
    required int studyStatus,
  }) {
    return _database.flashcardDao.updateCardStudyStatus(
      cardId: cardId,
      studyStatus: studyStatus,
    );
  }

  Future<void> deleteFlashcard(int cardId) {
    return _database.flashcardDao.deleteFlashcard(cardId);
  }

  // --- Flashcard AI Content & Quiz Generation ---

  Future<FlashcardPracticeAiResult> generateFlashcardPracticeContent({
    required String word,
    String? currentMeaningId,
    String? wordTypeHint,
    List<String> knownPartsOfSpeech = const <String>[],
    FlashcardExampleGenerationMode mode =
        FlashcardExampleGenerationMode.standard,
    bool includeAll16Tenses = false,
    List<String> avoidSentences = const [],
  }) async {
    final settings = await getSettings();
    final effectiveFlashcardModel = settings.flashcardModel.trim().isNotEmpty
        ? settings.flashcardModel
        : settings.scoringModel;
    return _restProvider.generateFlashcardPracticeContent(
      apiKey: settings.apiKey,
      model: effectiveFlashcardModel,
      word: word,
      currentMeaningId: currentMeaningId,
      wordTypeHint: wordTypeHint,
      knownPartsOfSpeech: knownPartsOfSpeech,
      mode: mode,
      includeAll16Tenses: includeAll16Tenses,
      avoidSentences: avoidSentences,
    );
  }

  Future<List<FlashcardQuizQuestion>> generateFlashcardQuiz({
    required List<Flashcard> cards,
    required String scopeTitle,
    int maxQuestions = 15,
  }) async {
    final settings = await getSettings();
    final effectiveFlashcardModel = settings.flashcardModel.trim().isNotEmpty
        ? settings.flashcardModel
        : settings.scoringModel;
    return _restProvider.generateFlashcardQuiz(
      apiKey: settings.apiKey,
      model: effectiveFlashcardModel,
      cards: cards,
      scopeTitle: scopeTitle,
      maxQuestions: maxQuestions,
    );
  }

  Future<SentencePronunciationFeedback> evaluateSentencePronunciation({
    required String targetSentence,
    String? targetWord,
    required Uint8List audioWavBytes,
  }) async {
    final settings = await getSettings();
    final effectiveFlashcardModel = settings.flashcardModel.trim().isNotEmpty
        ? settings.flashcardModel
        : settings.scoringModel;
    return _restProvider.evaluateSentencePronunciation(
      apiKey: settings.apiKey,
      model: effectiveFlashcardModel,
      targetSentence: targetSentence,
      targetWord: targetWord,
      audioWavBytes: audioWavBytes,
    );
  }

  Future<List<GeneratedVocabPackItem>> generateDailyVocabBatch({
    required String cefrLevel,
    required String topicName,
    int count = 50,
    List<String> avoidWords = const <String>[],
  }) async {
    final settings = await getSettings();
    final effectiveFlashcardModel = settings.flashcardModel.trim().isNotEmpty
        ? settings.flashcardModel
        : settings.scoringModel;
    return _restProvider.generateDailyVocabBatch(
      apiKey: settings.apiKey,
      model: effectiveFlashcardModel,
      cefrLevel: cefrLevel,
      topicName: topicName,
      count: count,
      avoidWords: avoidWords,
    );
  }

  /// Synthesizes English speech PCM16 24kHz audio via Live WebSocket (default)
  /// or REST `-tts` endpoint when a `-tts` model ID is explicitly configured.
  Future<Uint8List> synthesizeSpeechPcm24k({
    required String text,
    bool slow = false,
  }) async {
    final settings = await getSettings();
    final apiKey = settings.apiKey.trim();
    if (apiKey.isEmpty) {
      throw const GeminiApiException(
        'API key Gemini belum diisi. Masukkan API key di Pengaturan terlebih dahulu.',
        statusCode: 400,
      );
    }

    final ttsModel = settings.flashcardTtsModel.trim().isNotEmpty
        ? settings.flashcardTtsModel.trim()
        : (settings.liveModel.trim().isNotEmpty
              ? settings.liveModel.trim()
              : GeminiConstants.defaultLiveModel);

    final liveFallbackModel = settings.liveModel.trim();

    Future<Uint8List> synthesizeWithModel(String targetModel) {
      if (targetModel.toLowerCase().contains('-tts')) {
        return _restProvider.synthesizeSpeechPcm24k(
          apiKey: apiKey,
          model: targetModel,
          text: text,
          slow: slow,
        );
      }

      final liveProvider = _resolvedLiveProvider;
      if (liveProvider == null) {
        throw const GeminiLiveException(
          'Layanan Gemini Live tidak tersedia untuk memutar suara Flashcard.',
        );
      }

      return liveProvider.synthesizeSpeechOncePcm24k(
        apiKey: apiKey,
        model: targetModel,
        text: text,
        slow: slow,
      );
    }

    try {
      return await synthesizeWithModel(ttsModel);
    } catch (error) {
      final canRetryWithLiveModel =
          liveFallbackModel.isNotEmpty &&
          liveFallbackModel != ttsModel &&
          !liveFallbackModel.toLowerCase().contains('-tts') &&
          !_isOfflineOrApiKeyFailure(error);
      if (!canRetryWithLiveModel) {
        rethrow;
      }
      return synthesizeWithModel(liveFallbackModel);
    }
  }

  static bool _isOfflineOrApiKeyFailure(Object error) {
    if (error is SocketException || error is TimeoutException) return true;
    if (error is GeminiApiException &&
        (error.statusCode == null ||
            error.statusCode == 400 ||
            error.statusCode == 401 ||
            error.statusCode == 403)) {
      return true;
    }

    final lower = error.toString().toLowerCase();
    return lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('internet') ||
        lower.contains('offline') ||
        lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('api key') ||
        lower.contains('401') ||
        lower.contains('403') ||
        lower.contains('unauthenticated') ||
        lower.contains('permission_denied');
  }
}
