import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tutor_tables.dart';

part 'practice_dao.g.dart';

/// Persistence and reactive queries for practice sessions, mistakes, and vocabulary.
@DriftAccessor(
  tables: [Levels, Lessons, PracticeSessions, Mistakes, VocabItems, AppSettings],
)
class PracticeDao extends DatabaseAccessor<AppDatabase> with _$PracticeDaoMixin {
  PracticeDao(super.db);

  /// Saves a completed session together with its extracted [mistakes] and
  /// [vocabItems], updates the daily streak in [AppSettings], and updates
  /// `bestScore` / `isCompleted` on the linked [Lesson] in a single transaction.
  ///
  /// Returns the newly inserted session ID.
  Future<int> saveSessionWithInsights({
    required PracticeSessionsCompanion session,
    List<MistakesCompanion> mistakesList = const [],
    List<VocabItemsCompanion> vocabList = const [],
  }) {
    return transaction(() async {
      final sessionId = await into(practiceSessions).insert(session);

      for (final mistake in mistakesList) {
        await into(mistakes).insert(
          mistake.copyWith(sessionId: Value(sessionId)),
        );
      }

      for (final vocab in vocabList) {
        await into(vocabItems).insert(
          vocab.copyWith(sessionId: Value(sessionId)),
        );
      }

      final practiceTimestamp = session.endedAt.present &&
              session.endedAt.value != null
          ? session.endedAt.value!
          : (session.startedAt.present ? session.startedAt.value : DateTime.now());
      await _updateStreak(practiceTimestamp);

      final linkedLessonId =
          session.lessonId.present ? session.lessonId.value : null;
      if (linkedLessonId != null) {
        final lesson = await (select(lessons)
              ..where((t) => t.id.equals(linkedLessonId)))
            .getSingleOrNull();
        if (lesson != null) {
          final score =
              session.overallScore.present ? session.overallScore.value : 0;
          final passed = session.passed.present ? session.passed.value : false;
          await (update(lessons)..where((t) => t.id.equals(linkedLessonId)))
              .write(
            LessonsCompanion(
              bestScore: Value(math.max(lesson.bestScore, score)),
              isCompleted: Value(lesson.isCompleted || passed),
            ),
          );
        }
      }

      return sessionId;
    });
  }

  Future<void> _updateStreak(DateTime practiceTime) async {
    var settings = await (select(appSettings)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (settings == null) {
      await into(appSettings).insert(
        AppSettingsCompanion.insert(id: const Value(1)),
      );
      settings = await (select(appSettings)..where((t) => t.id.equals(1)))
          .getSingle();
    }

    final practiceDay =
        DateTime(practiceTime.year, practiceTime.month, practiceTime.day);
    final lastDate = settings.lastPracticeDate;

    int nextStreak;
    if (lastDate == null) {
      nextStreak = 1;
    } else {
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final dayDiff = practiceDay.difference(lastDay).inDays;
      if (dayDiff <= 0) {
        nextStreak = settings.currentStreak > 0 ? settings.currentStreak : 1;
      } else if (dayDiff == 1) {
        nextStreak = settings.currentStreak + 1;
      } else {
        nextStreak = 1;
      }
    }

    await (update(appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(
        currentStreak: Value(nextStreak),
        lastPracticeDate: Value(practiceTime),
      ),
    );
  }

  /// Watches recent practice sessions ordered newest-first.
  Stream<List<PracticeSession>> watchRecentSessions({int limit = 25}) {
    return (select(practiceSessions)
          ..orderBy([
            (t) => OrderingTerm.desc(t.startedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .watch();
  }

  /// Watches all recorded mistakes ordered newest-first.
  Stream<List<Mistake>> watchAllMistakes() {
    return (select(mistakes)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  /// Watches all saved vocabulary items ordered newest-first.
  Stream<List<VocabItem>> watchAllVocab() {
    return (select(vocabItems)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  /// Inserts a vocabulary item with an optional linked [sessionId].
  Future<int> saveVocabItem({
    int? sessionId,
    required String word,
    required String meaningId,
    required String exampleSentence,
    required String cefrLevel,
  }) {
    return into(vocabItems).insert(
      VocabItemsCompanion.insert(
        sessionId: Value(sessionId),
        word: word.trim(),
        meaningId: meaningId.trim(),
        exampleSentence: exampleSentence.trim(),
        cefrLevel: cefrLevel.trim().toUpperCase(),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Inserts a user-created vocabulary item outside of a practice session.
  Future<int> addManualVocab({
    required String word,
    required String meaningId,
    required String exampleSentence,
    required String cefrLevel,
  }) {
    return saveVocabItem(
      sessionId: null,
      word: word,
      meaningId: meaningId,
      exampleSentence: exampleSentence,
      cefrLevel: cefrLevel,
    );
  }

  /// Increments `masteryCount` for the vocabulary item with [id].
  Future<void> incrementVocabMastery(int id) {
    return transaction(() async {
      final item = await (select(vocabItems)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (item == null) return;
      await (update(vocabItems)..where((t) => t.id.equals(id))).write(
        VocabItemsCompanion(masteryCount: Value(item.masteryCount + 1)),
      );
    });
  }

  /// Deletes the vocabulary item with [id].
  Future<int> deleteVocab(int id) {
    return (delete(vocabItems)..where((t) => t.id.equals(id))).go();
  }
}
