import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tutor_tables.dart';

part 'roadmap_dao.g.dart';

/// Combined view of a CEFR [Level] and its ordered [Lesson] list.
class LevelWithLessons {
  const LevelWithLessons({
    required this.level,
    required this.lessons,
  });

  final Level level;
  final List<Lesson> lessons;
}

/// Reactive queries and progression mutations for the CEFR roadmap.
@DriftAccessor(
  tables: [Levels, Lessons, PracticeSessions, Mistakes, VocabItems, AppSettings],
)
class RoadmapDao extends DatabaseAccessor<AppDatabase> with _$RoadmapDaoMixin {
  RoadmapDao(super.db);

  /// Watches all levels ordered by [Levels.orderIndex] alongside their ordered lessons.
  Stream<List<LevelWithLessons>> watchAllLevelsWithLessons() {
    final query = select(levels).join([
      leftOuterJoin(lessons, lessons.levelId.equalsExp(levels.id)),
    ])
      ..orderBy([
        OrderingTerm.asc(levels.orderIndex),
        OrderingTerm.asc(lessons.orderIndex),
      ]);

    return query.watch().map((rows) {
      final grouped = <int, LevelWithLessons>{};
      for (final row in rows) {
        final level = row.readTable(levels);
        final lesson = row.readTableOrNull(lessons);
        final entry = grouped.putIfAbsent(
          level.id,
          () => LevelWithLessons(level: level, lessons: <Lesson>[]),
        );
        if (lesson != null) {
          entry.lessons.add(lesson);
        }
      }
      return grouped.values.toList(growable: false);
    });
  }

  /// Watches a single lesson by [id].
  Stream<Lesson?> watchLessonById(int id) {
    return (select(lessons)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Records [score] for [completedLessonId] and unlocks the next lesson or level
  /// atomically when [score] meets the parent level's [Levels.minPassScore].
  ///
  /// Returns `true` if the lesson was passed and progression was applied.
  Future<bool> unlockNextLessonOrLevel(int completedLessonId, int score) {
    return transaction(() async {
      final currentLesson = await (select(lessons)
            ..where((t) => t.id.equals(completedLessonId)))
          .getSingleOrNull();
      if (currentLesson == null) return false;

      final currentLevel = await (select(levels)
            ..where((t) => t.id.equals(currentLesson.levelId)))
          .getSingleOrNull();
      if (currentLevel == null) return false;

      final passed = score >= currentLevel.minPassScore;
      final updatedBestScore =
          score > currentLesson.bestScore ? score : currentLesson.bestScore;

      await (update(lessons)..where((t) => t.id.equals(completedLessonId)))
          .write(
        LessonsCompanion(
          bestScore: Value(updatedBestScore),
          isCompleted: Value(currentLesson.isCompleted || passed),
        ),
      );

      if (!passed) return false;

      final nextLessonInLevel = await (select(lessons)
            ..where(
              (t) =>
                  t.levelId.equals(currentLevel.id) &
                  t.orderIndex.isBiggerThanValue(currentLesson.orderIndex),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])
            ..limit(1))
          .getSingleOrNull();

      if (nextLessonInLevel != null) {
        await (update(lessons)..where((t) => t.id.equals(nextLessonInLevel.id)))
            .write(const LessonsCompanion(isUnlocked: Value(true)));
        return true;
      }

      final nextLevel = await (select(levels)
            ..where(
              (t) => t.orderIndex.isBiggerThanValue(currentLevel.orderIndex),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])
            ..limit(1))
          .getSingleOrNull();

      if (nextLevel != null) {
        await (update(levels)..where((t) => t.id.equals(nextLevel.id)))
            .write(const LevelsCompanion(isUnlocked: Value(true)));

        final firstLessonOfNextLevel = await (select(lessons)
              ..where((t) => t.levelId.equals(nextLevel.id))
              ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])
              ..limit(1))
            .getSingleOrNull();

        if (firstLessonOfNextLevel != null) {
          await (update(lessons)
                ..where((t) => t.id.equals(firstLessonOfNextLevel.id)))
              .write(const LessonsCompanion(isUnlocked: Value(true)));
        }
      }

      return true;
    });
  }

  /// Unlocks the target CEFR [levelCode] and all prior levels (used by placement test).
  Future<void> setLevelUnlocked(String levelCode) {
    return transaction(() async {
      final targetLevel = await (select(levels)
            ..where((t) => t.code.equals(levelCode.toUpperCase())))
          .getSingleOrNull();
      if (targetLevel == null) return;

      final levelsToUnlock = await (select(levels)
            ..where(
              (t) => t.orderIndex.isSmallerOrEqualValue(targetLevel.orderIndex),
            ))
          .get();

      for (final level in levelsToUnlock) {
        await (update(levels)..where((t) => t.id.equals(level.id)))
            .write(const LevelsCompanion(isUnlocked: Value(true)));

        final firstLesson = await (select(lessons)
              ..where((t) => t.levelId.equals(level.id))
              ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])
              ..limit(1))
            .getSingleOrNull();

        if (firstLesson != null) {
          await (update(lessons)..where((t) => t.id.equals(firstLesson.id)))
              .write(const LessonsCompanion(isUnlocked: Value(true)));
        }
      }
    });
  }

  /// Resets all curriculum unlock states, lesson scores, practice history, and streak.
  Future<void> resetProgress() {
    return transaction(() async {
      await delete(mistakes).go();
      await delete(vocabItems).go();
      await delete(practiceSessions).go();

      await update(levels).write(const LevelsCompanion(isUnlocked: Value(false)));
      await update(lessons).write(
        const LessonsCompanion(
          isUnlocked: Value(false),
          bestScore: Value(0),
          isCompleted: Value(false),
        ),
      );

      final firstLevel = await (select(levels)
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])
            ..limit(1))
          .getSingleOrNull();

      if (firstLevel != null) {
        await (update(levels)..where((t) => t.id.equals(firstLevel.id)))
            .write(const LevelsCompanion(isUnlocked: Value(true)));

        final firstLesson = await (select(lessons)
              ..where((t) => t.levelId.equals(firstLevel.id))
              ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])
              ..limit(1))
            .getSingleOrNull();

        if (firstLesson != null) {
          await (update(lessons)..where((t) => t.id.equals(firstLesson.id)))
              .write(const LessonsCompanion(isUnlocked: Value(true)));
        }
      }

      await (update(appSettings)..where((t) => t.id.equals(1))).write(
        const AppSettingsCompanion(
          currentStreak: Value(0),
          lastPracticeDate: Value(null),
          unlockAllOverride: Value(false),
        ),
      );
    });
  }
}
