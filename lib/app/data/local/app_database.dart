import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/flashcard_dao.dart';
import 'daos/practice_dao.dart';
import 'daos/roadmap_dao.dart';
import 'daos/settings_dao.dart';
import 'seed/curriculum_seeder.dart';
import 'tables/tutor_tables.dart';

part 'app_database.g.dart';

/// Main SQLite database managed by Drift for `my_english_tutor`.
@DriftDatabase(
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
  daos: [
    RoadmapDao,
    PracticeDao,
    SettingsDao,
    FlashcardDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Creates a database backed by the given [QueryExecutor] (useful for tests).
  AppDatabase(super.e);

  /// Creates the production application database via `drift_flutter`.
  AppDatabase.defaults()
      : super(driftDatabase(name: 'my_english_tutor_db'));

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await CurriculumSeeder.seed(this);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await CurriculumSeeder.seedMissingLessons(this);
          }
          if (from < 3) {
            await m.createTable(flashcardDecks);
            await m.createTable(flashcardSubDecks);
            await m.createTable(flashcards);
          }
          if (from < 4) {
            await m.addColumn(appSettings, appSettings.flashcardModel);
            await m.addColumn(appSettings, appSettings.flashcardTtsModel);
          }
          if (from < 5) {
            await customStatement(
              "UPDATE app_settings SET flashcard_tts_model = live_model "
              "WHERE flashcard_tts_model LIKE '%-tts' OR TRIM(flashcard_tts_model) = ''",
            );
          }
          if (from < 6) {
            await m.addColumn(flashcards, flashcards.partsOfSpeechJson);
            await m.addColumn(flashcards, flashcards.verbTensesExamplesJson);
          }
          if (from < 7) {
            await m.addColumn(flashcards, flashcards.studyStatus);
          }
        },
        beforeOpen: (OpeningDetails details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
