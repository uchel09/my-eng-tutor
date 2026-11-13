import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_english_tutor/app/data/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.roadmapDao.watchAllLevelsWithLessons().first;
  });

  tearDown(() async {
    await db.close();
  });

  test('initial seed unlocks only A1 and lesson 1 while A2-C2 remain locked', () async {
    final roadmap = await db.roadmapDao.watchAllLevelsWithLessons().first;
    expect(roadmap.map((g) => g.level.code).toList(), ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);

    final a1 = roadmap.first;
    expect(a1.level.isUnlocked, isTrue);
    expect(a1.lessons, hasLength(15));
    expect(a1.lessons[0].isUnlocked, isTrue);
    for (final lesson in a1.lessons.skip(1)) {
      expect(lesson.isUnlocked, isFalse);
    }

    for (final levelGroup in roadmap.skip(1)) {
      expect(levelGroup.level.isUnlocked, isFalse);
      for (final lesson in levelGroup.lessons) {
        expect(lesson.isUnlocked, isFalse);
      }
    }
  });

  test('score below 70 updates bestScore without completing or unlocking next lesson', () async {
    final roadmapBefore = await db.roadmapDao.watchAllLevelsWithLessons().first;
    final a1Lesson1 = roadmapBefore.first.lessons[0];
    final a1Lesson2 = roadmapBefore.first.lessons[1];

    final didPass = await db.roadmapDao.unlockNextLessonOrLevel(a1Lesson1.id, 65);
    expect(didPass, isFalse);

    final updatedL1 = await db.roadmapDao.watchLessonById(a1Lesson1.id).first;
    final updatedL2 = await db.roadmapDao.watchLessonById(a1Lesson2.id).first;
    expect(updatedL1?.bestScore, 65);
    expect(updatedL1?.isCompleted, isFalse);
    expect(updatedL2?.isUnlocked, isFalse);

    // Lower subsequent score does not overwrite higher bestScore.
    await db.roadmapDao.unlockNextLessonOrLevel(a1Lesson1.id, 52);
    final updatedL1Again = await db.roadmapDao.watchLessonById(a1Lesson1.id).first;
    expect(updatedL1Again?.bestScore, 65);
    expect(updatedL1Again?.isCompleted, isFalse);
  });

  test('completing all 15 A1 lessons sequentially with score >= 70 unlocks A2 lesson 1', () async {
    final roadmapStart = await db.roadmapDao.watchAllLevelsWithLessons().first;
    final a1Lessons = roadmapStart.first.lessons;
    expect(a1Lessons, hasLength(15));

    for (var i = 0; i < a1Lessons.length; i++) {
      final score = 70 + (i % 6) * 5;
      final passed = await db.roadmapDao.unlockNextLessonOrLevel(
        a1Lessons[i].id,
        score,
      );
      expect(passed, isTrue);

      final current = await db.roadmapDao.watchLessonById(a1Lessons[i].id).first;
      expect(current?.isCompleted, isTrue);
      expect(current?.bestScore, score);
    }

    final roadmapAfter = await db.roadmapDao.watchAllLevelsWithLessons().first;
    final a2 = roadmapAfter[1];
    expect(a2.level.code, 'A2');
    expect(a2.level.isUnlocked, isTrue);
    expect(a2.lessons[0].isUnlocked, isTrue);
    expect(a2.lessons[1].isUnlocked, isFalse);
  });

  test('setLevelUnlocked B1 unlocks A1, A2, B1 and each first lesson', () async {
    await db.roadmapDao.setLevelUnlocked('B1');

    final roadmap = await db.roadmapDao.watchAllLevelsWithLessons().first;
    for (final index in [0, 1, 2]) {
      expect(roadmap[index].level.isUnlocked, isTrue);
      expect(roadmap[index].lessons.first.isUnlocked, isTrue);
    }
    for (final index in [3, 4, 5]) {
      expect(roadmap[index].level.isUnlocked, isFalse);
      expect(roadmap[index].lessons.first.isUnlocked, isFalse);
    }
  });

  test('resetProgress clears history, streak, and unlocks while preserving saved apiKey', () async {
    const savedKey = 'AIzaSyTestPersonalKey123';
    await db.settingsDao.updateSettings(
      const AppSettingsCompanion(
        apiKey: Value(savedKey),
        unlockAllOverride: Value(true),
      ),
    );
    await db.roadmapDao.setLevelUnlocked('B1');

    final roadmapBefore = await db.roadmapDao.watchAllLevelsWithLessons().first;
    final firstLesson = roadmapBefore.first.lessons.first;
    final now = DateTime(2026, 11, 13, 16, 30);

    await db.practiceDao.saveSessionWithInsights(
      session: PracticeSessionsCompanion.insert(
        lessonId: Value(firstLesson.id),
        sessionType: 'guided_speech',
        startedAt: now,
        durationSec: const Value(60),
        overallScore: const Value(88),
        passed: const Value(true),
      ),
      mistakesList: [
        MistakesCompanion.insert(
          sessionId: 0,
          originalSentence: 'I very like coffee.',
          correctedSentence: 'I really like coffee.',
          explanation: 'Gunakan really alih-alih very sebelum kata kerja.',
          category: 'grammar',
          createdAt: now,
        ),
      ],
      vocabList: [
        VocabItemsCompanion.insert(
          word: 'fluent',
          meaningId: 'fasih',
          exampleSentence: 'Daily practice makes you fluent.',
          cefrLevel: 'B1',
          createdAt: now,
        ),
      ],
    );

    await db.roadmapDao.resetProgress();

    final roadmapAfter = await db.roadmapDao.watchAllLevelsWithLessons().first;
    expect(roadmapAfter[0].level.isUnlocked, isTrue);
    expect(roadmapAfter[0].lessons[0].isUnlocked, isTrue);
    expect(roadmapAfter[0].lessons[0].bestScore, 0);
    expect(roadmapAfter[0].lessons[0].isCompleted, isFalse);
    expect(roadmapAfter[1].level.isUnlocked, isFalse);
    expect(roadmapAfter[2].level.isUnlocked, isFalse);

    expect(await db.practiceDao.watchRecentSessions().first, isEmpty);
    expect(await db.practiceDao.watchAllMistakes().first, isEmpty);
    expect(await db.practiceDao.watchAllVocab().first, isEmpty);

    final settingsAfter = await db.settingsDao.getSettings();
    expect(settingsAfter.apiKey, savedKey);
    expect(settingsAfter.currentStreak, 0);
    expect(settingsAfter.lastPracticeDate, isNull);
    expect(settingsAfter.unlockAllOverride, isFalse);
  });
}
