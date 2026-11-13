import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tutor_tables.dart';

part 'settings_dao.g.dart';

/// Persistence, reactive watching, and JSON backup/restore for [AppSettings].
@DriftAccessor(
  tables: [
    Levels,
    Lessons,
    PracticeSessions,
    Mistakes,
    VocabItems,
    AppSettings,
    FlashcardDecks,
    FlashcardSubDecks,
    Flashcards,
  ],
)
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  static const String defaultLiveModel = 'gemini-3.8-live';
  static const String defaultScoringModel = 'gemini-3.8-flash';
  static const String defaultFlashcardModel = defaultScoringModel;
  static const String defaultTtsModel = 'gemini-2.5-flash-preview-tts';

  /// Watches the singleton [AppSetting] row (`id = 1`).
  Stream<AppSetting> watchSettings() {
    return (select(appSettings)..where((t) => t.id.equals(1)))
        .watchSingleOrNull()
        .map(
          (row) =>
              row ??
              AppSetting(
                id: 1,
                apiKey: '',
                liveModel: defaultLiveModel,
                scoringModel: defaultScoringModel,
                flashcardModel: defaultFlashcardModel,
                flashcardTtsModel: defaultTtsModel,
                bilingualBeginnerSupport: true,
                darkMode: false,
                unlockAllOverride: false,
                currentStreak: 0,
                lastPracticeDate: null,
              ),
        );
  }

  /// Reads the singleton [AppSetting] row, creating it if absent.
  Future<AppSetting> getSettings() async {
    final existing = await (select(appSettings)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (existing != null) return existing;

    await into(appSettings).insert(
      AppSettingsCompanion.insert(id: const Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
    return (select(appSettings)..where((t) => t.id.equals(1))).getSingle();
  }

  /// Applies partial updates to the singleton [AppSettings] row (`id = 1`).
  Future<void> updateSettings(AppSettingsCompanion entry) async {
    await getSettings();
    await (update(appSettings)..where((t) => t.id.equals(1)))
        .write(entry.copyWith(id: const Value(1)));
  }

  /// Exports curriculum progress, sessions, mistakes, vocab, and non-secret
  /// preferences as a JSON-serializable map.
  Future<Map<String, dynamic>> exportAllDataAsMap() async {
    final settings = await getSettings();
    final allLevels = await (select(levels)
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
    final allLessons = await (select(lessons)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final allSessions = await (select(practiceSessions)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final allMistakes = await (select(mistakes)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final allVocab = await (select(vocabItems)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final allFlashcardDecks = await (select(flashcardDecks)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final allFlashcardSubDecks = await (select(flashcardSubDecks)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final allFlashcards = await (select(flashcards)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();

    return <String, dynamic>{
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': <String, dynamic>{
        'liveModel': settings.liveModel,
        'scoringModel': settings.scoringModel,
        'flashcardModel': settings.flashcardModel,
        'flashcardTtsModel': settings.flashcardTtsModel,
        'bilingualBeginnerSupport': settings.bilingualBeginnerSupport,
        'darkMode': settings.darkMode,
        'unlockAllOverride': settings.unlockAllOverride,
        'currentStreak': settings.currentStreak,
        'lastPracticeDate': settings.lastPracticeDate?.toIso8601String(),
      },
      'levels': allLevels
          .map(
            (e) => <String, dynamic>{
              'id': e.id,
              'code': e.code,
              'title': e.title,
              'description': e.description,
              'orderIndex': e.orderIndex,
              'minPassScore': e.minPassScore,
              'isUnlocked': e.isUnlocked,
            },
          )
          .toList(growable: false),
      'lessons': allLessons
          .map(
            (e) => <String, dynamic>{
              'id': e.id,
              'levelId': e.levelId,
              'title': e.title,
              'scenarioPrompt': e.scenarioPrompt,
              'systemInstruction': e.systemInstruction,
              'mode': e.mode,
              'targetDurationSec': e.targetDurationSec,
              'orderIndex': e.orderIndex,
              'isUnlocked': e.isUnlocked,
              'bestScore': e.bestScore,
              'isCompleted': e.isCompleted,
            },
          )
          .toList(growable: false),
      'practiceSessions': allSessions
          .map(
            (e) => <String, dynamic>{
              'id': e.id,
              'lessonId': e.lessonId,
              'sessionType': e.sessionType,
              'startedAt': e.startedAt.toIso8601String(),
              'endedAt': e.endedAt?.toIso8601String(),
              'durationSec': e.durationSec,
              'transcriptJson': e.transcriptJson,
              'overallScore': e.overallScore,
              'fluencyScore': e.fluencyScore,
              'grammarScore': e.grammarScore,
              'vocabScore': e.vocabScore,
              'pronunciationScore': e.pronunciationScore,
              'fillerCount': e.fillerCount,
              'aiSummary': e.aiSummary,
              'passed': e.passed,
            },
          )
          .toList(growable: false),
      'mistakes': allMistakes
          .map(
            (e) => <String, dynamic>{
              'id': e.id,
              'sessionId': e.sessionId,
              'originalSentence': e.originalSentence,
              'correctedSentence': e.correctedSentence,
              'explanation': e.explanation,
              'category': e.category,
              'createdAt': e.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      'vocabItems': allVocab
          .map(
            (e) => <String, dynamic>{
              'id': e.id,
              'sessionId': e.sessionId,
              'word': e.word,
              'meaningId': e.meaningId,
              'exampleSentence': e.exampleSentence,
              'cefrLevel': e.cefrLevel,
              'masteryCount': e.masteryCount,
              'createdAt': e.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      'flashcardDecks': allFlashcardDecks
          .map(
            (e) => <String, dynamic>{
              'id': e.id,
              'name': e.name,
              'description': e.description,
              'createdAt': e.createdAt.toIso8601String(),
              'updatedAt': e.updatedAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      'flashcardSubDecks': allFlashcardSubDecks
          .map(
            (e) => <String, dynamic>{
              'id': e.id,
              'deckId': e.deckId,
              'name': e.name,
              'description': e.description,
              'createdAt': e.createdAt.toIso8601String(),
              'updatedAt': e.updatedAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      'flashcards': allFlashcards
          .map(
            (e) => <String, dynamic>{
              'id': e.id,
              'subDeckId': e.subDeckId,
              'word': e.word,
              'phonetic': e.phonetic,
              'meaningId': e.meaningId,
              'wordType': e.wordType,
              'examplesJson': e.examplesJson,
              'aiConversation': e.aiConversation,
              'masteryLevel': e.masteryLevel,
              'reviewCount': e.reviewCount,
              'lastReviewedAt': e.lastReviewedAt?.toIso8601String(),
              'createdAt': e.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
    };
  }

  /// Restores database state from a backup map created by [exportAllDataAsMap]
  /// in a single transaction, preserving the local `apiKey` unless supplied.
  Future<void> importAllDataFromMap(Map<String, dynamic> json) async {
    final rawLevels = json['levels'];
    final rawLessons = json['lessons'];
    if (rawLevels is! List || rawLessons is! List || rawLevels.isEmpty) {
      throw const FormatException(
        'Invalid backup payload: levels and lessons are required.',
      );
    }

    final rawSessions = (json['practiceSessions'] as List?) ?? const [];
    final rawMistakes = (json['mistakes'] as List?) ?? const [];
    final rawVocab = (json['vocabItems'] as List?) ?? const [];
    final rawFlashcardDecks = (json['flashcardDecks'] as List?) ?? const [];
    final rawFlashcardSubDecks =
        (json['flashcardSubDecks'] as List?) ?? const [];
    final rawFlashcards = (json['flashcards'] as List?) ?? const [];
    final rawSettings = json['settings'] as Map<String, dynamic>?;

    await transaction(() async {
      await delete(flashcards).go();
      await delete(flashcardSubDecks).go();
      await delete(flashcardDecks).go();
      await delete(mistakes).go();
      await delete(vocabItems).go();
      await delete(practiceSessions).go();
      await delete(lessons).go();
      await delete(levels).go();

      for (final item in rawLevels.cast<Map<String, dynamic>>()) {
        await into(levels).insert(
          LevelsCompanion.insert(
            id: Value(item['id'] as int),
            code: item['code'] as String,
            title: item['title'] as String,
            description: item['description'] as String,
            orderIndex: item['orderIndex'] as int,
            minPassScore: Value((item['minPassScore'] as int?) ?? 70),
            isUnlocked: Value((item['isUnlocked'] as bool?) ?? false),
          ),
        );
      }

      for (final item in rawLessons.cast<Map<String, dynamic>>()) {
        await into(lessons).insert(
          LessonsCompanion.insert(
            id: Value(item['id'] as int),
            levelId: item['levelId'] as int,
            title: item['title'] as String,
            scenarioPrompt: item['scenarioPrompt'] as String,
            systemInstruction: item['systemInstruction'] as String,
            mode: item['mode'] as String,
            targetDurationSec: Value((item['targetDurationSec'] as int?) ?? 60),
            orderIndex: item['orderIndex'] as int,
            isUnlocked: Value((item['isUnlocked'] as bool?) ?? false),
            bestScore: Value((item['bestScore'] as int?) ?? 0),
            isCompleted: Value((item['isCompleted'] as bool?) ?? false),
          ),
        );
      }

      for (final item in rawSessions.cast<Map<String, dynamic>>()) {
        await into(practiceSessions).insert(
          PracticeSessionsCompanion.insert(
            id: Value(item['id'] as int),
            lessonId: Value(item['lessonId'] as int?),
            sessionType: item['sessionType'] as String,
            startedAt: DateTime.parse(item['startedAt'] as String),
            endedAt: Value(
              item['endedAt'] != null
                  ? DateTime.parse(item['endedAt'] as String)
                  : null,
            ),
            durationSec: Value((item['durationSec'] as int?) ?? 0),
            transcriptJson: Value((item['transcriptJson'] as String?) ?? '[]'),
            overallScore: Value((item['overallScore'] as int?) ?? 0),
            fluencyScore: Value((item['fluencyScore'] as int?) ?? 0),
            grammarScore: Value((item['grammarScore'] as int?) ?? 0),
            vocabScore: Value((item['vocabScore'] as int?) ?? 0),
            pronunciationScore: Value((item['pronunciationScore'] as int?) ?? 0),
            fillerCount: Value((item['fillerCount'] as int?) ?? 0),
            aiSummary: Value((item['aiSummary'] as String?) ?? ''),
            passed: Value((item['passed'] as bool?) ?? false),
          ),
        );
      }

      for (final item in rawMistakes.cast<Map<String, dynamic>>()) {
        await into(mistakes).insert(
          MistakesCompanion.insert(
            id: Value(item['id'] as int),
            sessionId: item['sessionId'] as int,
            originalSentence: item['originalSentence'] as String,
            correctedSentence: item['correctedSentence'] as String,
            explanation: item['explanation'] as String,
            category: item['category'] as String,
            createdAt: DateTime.parse(item['createdAt'] as String),
          ),
        );
      }

      for (final item in rawVocab.cast<Map<String, dynamic>>()) {
        await into(vocabItems).insert(
          VocabItemsCompanion.insert(
            id: Value(item['id'] as int),
            sessionId: Value(item['sessionId'] as int?),
            word: item['word'] as String,
            meaningId: item['meaningId'] as String,
            exampleSentence: item['exampleSentence'] as String,
            cefrLevel: item['cefrLevel'] as String,
            masteryCount: Value((item['masteryCount'] as int?) ?? 0),
            createdAt: DateTime.parse(item['createdAt'] as String),
          ),
        );
      }

      for (final item in rawFlashcardDecks.cast<Map<String, dynamic>>()) {
        await into(flashcardDecks).insert(
          FlashcardDecksCompanion.insert(
            id: Value(item['id'] as int),
            name: item['name'] as String,
            description: Value(item['description'] as String?),
            createdAt: Value(DateTime.parse(item['createdAt'] as String)),
            updatedAt: Value(DateTime.parse(item['updatedAt'] as String)),
          ),
        );
      }

      for (final item in rawFlashcardSubDecks.cast<Map<String, dynamic>>()) {
        await into(flashcardSubDecks).insert(
          FlashcardSubDecksCompanion.insert(
            id: Value(item['id'] as int),
            deckId: item['deckId'] as int,
            name: item['name'] as String,
            description: Value(item['description'] as String?),
            createdAt: Value(DateTime.parse(item['createdAt'] as String)),
            updatedAt: Value(DateTime.parse(item['updatedAt'] as String)),
          ),
        );
      }

      for (final item in rawFlashcards.cast<Map<String, dynamic>>()) {
        await into(flashcards).insert(
          FlashcardsCompanion.insert(
            id: Value(item['id'] as int),
            subDeckId: item['subDeckId'] as int,
            word: item['word'] as String,
            phonetic: Value(item['phonetic'] as String?),
            meaningId: Value((item['meaningId'] as String?) ?? ''),
            wordType: Value((item['wordType'] as String?) ?? 'non_verb'),
            examplesJson: Value((item['examplesJson'] as String?) ?? '[]'),
            aiConversation: Value((item['aiConversation'] as String?) ?? ''),
            masteryLevel: Value((item['masteryLevel'] as int?) ?? 0),
            reviewCount: Value((item['reviewCount'] as int?) ?? 0),
            lastReviewedAt: Value(
              item['lastReviewedAt'] != null
                  ? DateTime.parse(item['lastReviewedAt'] as String)
                  : null,
            ),
            createdAt: Value(DateTime.parse(item['createdAt'] as String)),
          ),
        );
      }

      if (rawSettings != null) {
        final current = await getSettings();
        final importedApiKey = rawSettings['apiKey'] as String?;
        await (update(appSettings)..where((t) => t.id.equals(1))).write(
          AppSettingsCompanion(
            apiKey: Value(
              (importedApiKey != null && importedApiKey.isNotEmpty)
                  ? importedApiKey
                  : current.apiKey,
            ),
            liveModel: Value(
              (rawSettings['liveModel'] as String?) ?? defaultLiveModel,
            ),
            scoringModel: Value(
              (rawSettings['scoringModel'] as String?) ?? defaultScoringModel,
            ),
            flashcardModel: Value(
              (rawSettings['flashcardModel'] as String?) ??
                  defaultFlashcardModel,
            ),
            flashcardTtsModel: Value(
              (rawSettings['flashcardTtsModel'] as String?) ?? defaultTtsModel,
            ),
            bilingualBeginnerSupport: Value(
              (rawSettings['bilingualBeginnerSupport'] as bool?) ?? true,
            ),
            darkMode: Value((rawSettings['darkMode'] as bool?) ?? false),
            unlockAllOverride: Value(
              (rawSettings['unlockAllOverride'] as bool?) ?? false,
            ),
            currentStreak: Value((rawSettings['currentStreak'] as int?) ?? 0),
            lastPracticeDate: Value(
              rawSettings['lastPracticeDate'] != null
                  ? DateTime.parse(rawSettings['lastPracticeDate'] as String)
                  : null,
            ),
          ),
        );
      }
    });
  }
}
