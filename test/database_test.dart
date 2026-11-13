import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/local/seed/curriculum_seeder.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('seeder creates 6 levels, 100 lessons, and default settings', () async {
    final roadmap = await db.roadmapDao.watchAllLevelsWithLessons().first;
    expect(roadmap, hasLength(6));

    final codes = roadmap.map((e) => e.level.code).toList();
    expect(codes, equals(['A1', 'A2', 'B1', 'B2', 'C1', 'C2']));

    final totalLessons =
        roadmap.fold<int>(0, (sum, item) => sum + item.lessons.length);
    expect(totalLessons, equals(100));

    final expectedCounts = <String, int>{
      'A1': 15,
      'A2': 17,
      'B1': 18,
      'B2': 18,
      'C1': 16,
      'C2': 16,
    };
    for (final item in roadmap) {
      expect(item.lessons, hasLength(expectedCounts[item.level.code]));
    }

    // Only A1 and its first lesson should be unlocked initially.
    for (final item in roadmap) {
      if (item.level.code == 'A1') {
        expect(item.level.isUnlocked, isTrue);
        expect(item.lessons.first.isUnlocked, isTrue);
        for (final lesson in item.lessons.skip(1)) {
          expect(lesson.isUnlocked, isFalse);
        }
      } else {
        expect(item.level.isUnlocked, isFalse);
        for (final lesson in item.lessons) {
          expect(lesson.isUnlocked, isFalse);
        }
      }
    }

    final settings = await db.settingsDao.getSettings();
    expect(settings.id, equals(1));
    expect(settings.bilingualBeginnerSupport, isTrue);
    expect(settings.currentStreak, equals(0));
  });

  test(
    'unlockNextLessonOrLevel unlocks next lesson only when score >= minPassScore',
    () async {
      final roadmapBefore =
          await db.roadmapDao.watchAllLevelsWithLessons().first;
      final a1Lessons = roadmapBefore.first.lessons;
      final lesson1 = a1Lessons[0];
      final lesson2 = a1Lessons[1];

      // Below passing threshold (70): should record bestScore but stay locked.
      final failResult =
          await db.roadmapDao.unlockNextLessonOrLevel(lesson1.id, 65);
      expect(failResult, isFalse);

      final lesson1AfterFail =
          await db.roadmapDao.watchLessonById(lesson1.id).first;
      final lesson2AfterFail =
          await db.roadmapDao.watchLessonById(lesson2.id).first;
      expect(lesson1AfterFail?.bestScore, equals(65));
      expect(lesson1AfterFail?.isCompleted, isFalse);
      expect(lesson2AfterFail?.isUnlocked, isFalse);

      // Passing score (>= 70): completes lesson 1 and unlocks lesson 2.
      final passResult =
          await db.roadmapDao.unlockNextLessonOrLevel(lesson1.id, 78);
      expect(passResult, isTrue);

      final lesson1AfterPass =
          await db.roadmapDao.watchLessonById(lesson1.id).first;
      final lesson2AfterPass =
          await db.roadmapDao.watchLessonById(lesson2.id).first;
      expect(lesson1AfterPass?.bestScore, equals(78));
      expect(lesson1AfterPass?.isCompleted, isTrue);
      expect(lesson2AfterPass?.isUnlocked, isTrue);
    },
  );

  test(
    'completing final lesson of A1 unlocks A2 and A2 lesson 1',
    () async {
      final roadmapBefore =
          await db.roadmapDao.watchAllLevelsWithLessons().first;
      final a1LastLesson = roadmapBefore[0].lessons.last;

      final result =
          await db.roadmapDao.unlockNextLessonOrLevel(a1LastLesson.id, 85);
      expect(result, isTrue);

      final roadmapAfter =
          await db.roadmapDao.watchAllLevelsWithLessons().first;
      expect(roadmapAfter[1].level.code, equals('A2'));
      expect(roadmapAfter[1].level.isUnlocked, isTrue);
      expect(roadmapAfter[1].lessons.first.isUnlocked, isTrue);
      expect(roadmapAfter[1].lessons[1].isUnlocked, isFalse);
    },
  );

  test(
    'CurriculumSeeder.seedMissingLessons is idempotent and preserves existing progress',
    () async {
      await db.settingsDao.updateSettings(
        const AppSettingsCompanion(apiKey: Value('AIzaPersistedKey')),
      );

      final initialRoadmap =
          await db.roadmapDao.watchAllLevelsWithLessons().first;
      final a1LevelId = initialRoadmap[0].level.id;

      // Simulate an older v1 database: complete A1 lessons 1..4 and delete newer lessons.
      for (final lesson in initialRoadmap[0].lessons.take(4)) {
        await db.roadmapDao.unlockNextLessonOrLevel(lesson.id, 88);
      }
      await (db.delete(db.lessons)
            ..where(
              (t) =>
                  t.levelId.equals(a1LevelId) &
                  t.orderIndex.isBiggerThanValue(4),
            ))
          .go();

      // Upgrade twice to verify idempotency.
      await CurriculumSeeder.seedMissingLessons(db);
      await CurriculumSeeder.seedMissingLessons(db);

      final upgradedRoadmap =
          await db.roadmapDao.watchAllLevelsWithLessons().first;
      final totalLessons = upgradedRoadmap.fold<int>(
        0,
        (sum, item) => sum + item.lessons.length,
      );
      expect(totalLessons, equals(100));

      final a1After = upgradedRoadmap[0].lessons;
      expect(a1After, hasLength(15));
      for (var i = 0; i < 4; i++) {
        expect(a1After[i].isCompleted, isTrue);
        expect(a1After[i].bestScore, equals(88));
      }
      // Next newly seeded lesson (orderIndex 5) should unlock automatically so user is not stuck.
      expect(a1After[4].orderIndex, equals(5));
      expect(a1After[4].isUnlocked, isTrue);
      expect(a1After[5].isUnlocked, isFalse);

      final settingsAfter = await db.settingsDao.getSettings();
      expect(settingsAfter.apiKey, equals('AIzaPersistedKey'));
    },
  );

  test('setLevelUnlocked unlocks target level and prior levels', () async {
    await db.roadmapDao.setLevelUnlocked('B1');

    final roadmap = await db.roadmapDao.watchAllLevelsWithLessons().first;
    expect(roadmap[0].level.isUnlocked, isTrue); // A1
    expect(roadmap[1].level.isUnlocked, isTrue); // A2
    expect(roadmap[2].level.isUnlocked, isTrue); // B1
    expect(roadmap[2].lessons.first.isUnlocked, isTrue);
    expect(roadmap[3].level.isUnlocked, isFalse); // B2
    expect(roadmap[4].level.isUnlocked, isFalse); // C1
    expect(roadmap[5].level.isUnlocked, isFalse); // C2
  });

  test(
    'saveSessionWithInsights saves session, mistakes, vocab, streak, and lesson stats',
    () async {
      final roadmap = await db.roadmapDao.watchAllLevelsWithLessons().first;
      final lesson1 = roadmap.first.lessons.first;
      final now = DateTime(2026, 11, 13, 15, 0);

      final sessionId = await db.practiceDao.saveSessionWithInsights(
        session: PracticeSessionsCompanion.insert(
          lessonId: Value(lesson1.id),
          sessionType: 'lesson',
          startedAt: now,
          endedAt: Value(now.add(const Duration(seconds: 65))),
          durationSec: const Value(65),
          overallScore: const Value(82),
          fluencyScore: const Value(80),
          grammarScore: const Value(84),
          vocabScore: const Value(81),
          pronunciationScore: const Value(83),
          fillerCount: const Value(2),
          aiSummary: const Value('Clear introduction with natural pacing.'),
          passed: const Value(true),
        ),
        mistakesList: [
          MistakesCompanion.insert(
            sessionId: 0,
            originalSentence: 'I am work as engineer.',
            correctedSentence: 'I work as an engineer.',
            explanation: 'Use simple present without "am" and add "an".',
            category: 'grammar',
            createdAt: now,
          ),
        ],
        vocabList: [
          VocabItemsCompanion.insert(
            word: 'passionate',
            meaningId: 'penuh semangat / antusias',
            exampleSentence: 'I am passionate about mobile development.',
            cefrLevel: 'B1',
            createdAt: now,
          ),
        ],
      );

      expect(sessionId, greaterThan(0));

      final sessions = await db.practiceDao.watchRecentSessions().first;
      expect(sessions, hasLength(1));
      expect(sessions.first.overallScore, equals(82));

      final mistakes = await db.practiceDao.watchAllMistakes().first;
      expect(mistakes, hasLength(1));
      expect(mistakes.first.sessionId, equals(sessionId));

      final vocab = await db.practiceDao.watchAllVocab().first;
      expect(vocab, hasLength(1));
      expect(vocab.first.sessionId, equals(sessionId));

      await db.practiceDao.incrementVocabMastery(vocab.first.id);
      final updatedVocab = await db.practiceDao.watchAllVocab().first;
      expect(updatedVocab.first.masteryCount, equals(1));

      final settings = await db.settingsDao.getSettings();
      expect(settings.currentStreak, equals(1));
      expect(settings.lastPracticeDate, isNotNull);

      final updatedLesson =
          await db.roadmapDao.watchLessonById(lesson1.id).first;
      expect(updatedLesson?.bestScore, equals(82));
      expect(updatedLesson?.isCompleted, isTrue);
    },
  );

  test('exportAllDataAsMap and importAllDataFromMap round-trip', () async {
    await db.settingsDao.updateSettings(
      const AppSettingsCompanion(
        apiKey: Value('secret-local-key'),
        darkMode: Value(true),
      ),
    );
    await db.roadmapDao.setLevelUnlocked('A2');

    final exported = await db.settingsDao.exportAllDataAsMap();
    expect(
      (exported['settings'] as Map<String, dynamic>).containsKey('apiKey'),
      isFalse,
    );

    await db.roadmapDao.resetProgress();
    final resetRoadmap = await db.roadmapDao.watchAllLevelsWithLessons().first;
    expect(resetRoadmap[1].level.isUnlocked, isFalse);

    await db.settingsDao.importAllDataFromMap(exported);

    final restoredRoadmap =
        await db.roadmapDao.watchAllLevelsWithLessons().first;
    expect(restoredRoadmap[1].level.isUnlocked, isTrue);

    final restoredSettings = await db.settingsDao.getSettings();
    expect(restoredSettings.darkMode, isTrue);
    expect(restoredSettings.apiKey, equals('secret-local-key'));
  });
}
