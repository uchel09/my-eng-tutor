import 'package:drift/drift.dart';

/// CEFR proficiency levels (A1 through C2) for the speaking roadmap.
class Levels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  IntColumn get orderIndex => integer()();
  IntColumn get minPassScore => integer().withDefault(const Constant(70))();
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();
}

/// Guided speaking or live roleplay lessons belonging to a [Levels] row.
class Lessons extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get levelId =>
      integer().references(Levels, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get scenarioPrompt => text()();
  TextColumn get systemInstruction => text()();
  TextColumn get mode => text()();
  IntColumn get targetDurationSec =>
      integer().withDefault(const Constant(60))();
  IntColumn get orderIndex => integer()();
  BoolColumn get isUnlocked => boolean().withDefault(const Constant(false))();
  IntColumn get bestScore => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

/// Completed or in-progress speaking practice sessions.
class PracticeSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lessonId => integer().nullable().references(
        Lessons,
        #id,
        onDelete: KeyAction.setNull,
      )();
  TextColumn get sessionType => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSec => integer().withDefault(const Constant(0))();
  TextColumn get transcriptJson =>
      text().withDefault(const Constant('[]'))();
  IntColumn get overallScore => integer().withDefault(const Constant(0))();
  IntColumn get fluencyScore => integer().withDefault(const Constant(0))();
  IntColumn get grammarScore => integer().withDefault(const Constant(0))();
  IntColumn get vocabScore => integer().withDefault(const Constant(0))();
  IntColumn get pronunciationScore =>
      integer().withDefault(const Constant(0))();
  IntColumn get fillerCount => integer().withDefault(const Constant(0))();
  TextColumn get aiSummary => text().withDefault(const Constant(''))();
  BoolColumn get passed => boolean().withDefault(const Constant(false))();
}

/// Grammar, phrasing, or pronunciation mistakes extracted from a session.
class Mistakes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(
        PracticeSessions,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get originalSentence => text()();
  TextColumn get correctedSentence => text()();
  TextColumn get explanation => text()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Vocabulary items recommended or saved for spaced review.
class VocabItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().nullable().references(
        PracticeSessions,
        #id,
        onDelete: KeyAction.setNull,
      )();
  TextColumn get word => text()();
  TextColumn get meaningId => text()();
  TextColumn get exampleSentence => text()();
  TextColumn get cefrLevel => text()();
  IntColumn get masteryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Singleton application settings and streak metadata (always row id = 1).
class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get apiKey => text().withDefault(const Constant(''))();
  TextColumn get liveModel => text().withDefault(
        const Constant('gemini-2.5-flash-native-audio-preview-12-2025'),
      )();
  TextColumn get scoringModel =>
      text().withDefault(const Constant('gemini-2.5-flash'))();
  BoolColumn get bilingualBeginnerSupport =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get darkMode => boolean().withDefault(const Constant(false))();
  BoolColumn get unlockAllOverride =>
      boolean().withDefault(const Constant(false))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPracticeDate => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Top-level flashcard deck grouping thematic sub-decks (Level 1).
class FlashcardDecks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Topic sub-deck belonging to a [FlashcardDecks] row (Level 2).
class FlashcardSubDecks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deckId => integer().references(
        FlashcardDecks,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Individual flashcard with AI examples, conversation, and mastery state (Level 3).
class Flashcards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subDeckId => integer().references(
        FlashcardSubDecks,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get word => text().withLength(min: 1, max: 120)();
  TextColumn get phonetic => text().nullable()();
  TextColumn get meaningId => text().withDefault(const Constant(''))();
  TextColumn get wordType => text().withDefault(const Constant('non_verb'))();
  TextColumn get examplesJson => text().withDefault(const Constant('[]'))();
  TextColumn get aiConversation => text().withDefault(const Constant(''))();
  IntColumn get masteryLevel => integer().withDefault(const Constant(0))();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
