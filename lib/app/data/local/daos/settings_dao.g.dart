// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_dao.dart';

// ignore_for_file: type=lint
mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LevelsTable get levels => attachedDatabase.levels;
  $LessonsTable get lessons => attachedDatabase.lessons;
  $PracticeSessionsTable get practiceSessions =>
      attachedDatabase.practiceSessions;
  $MistakesTable get mistakes => attachedDatabase.mistakes;
  $VocabItemsTable get vocabItems => attachedDatabase.vocabItems;
  $AppSettingsTable get appSettings => attachedDatabase.appSettings;
  $FlashcardDecksTable get flashcardDecks => attachedDatabase.flashcardDecks;
  $FlashcardSubDecksTable get flashcardSubDecks =>
      attachedDatabase.flashcardSubDecks;
  $FlashcardsTable get flashcards => attachedDatabase.flashcards;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$LevelsTableTableManager get levels =>
      $$LevelsTableTableManager(_db.attachedDatabase, _db.levels);
  $$LessonsTableTableManager get lessons =>
      $$LessonsTableTableManager(_db.attachedDatabase, _db.lessons);
  $$PracticeSessionsTableTableManager get practiceSessions =>
      $$PracticeSessionsTableTableManager(
        _db.attachedDatabase,
        _db.practiceSessions,
      );
  $$MistakesTableTableManager get mistakes =>
      $$MistakesTableTableManager(_db.attachedDatabase, _db.mistakes);
  $$VocabItemsTableTableManager get vocabItems =>
      $$VocabItemsTableTableManager(_db.attachedDatabase, _db.vocabItems);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db.attachedDatabase, _db.appSettings);
  $$FlashcardDecksTableTableManager get flashcardDecks =>
      $$FlashcardDecksTableTableManager(
        _db.attachedDatabase,
        _db.flashcardDecks,
      );
  $$FlashcardSubDecksTableTableManager get flashcardSubDecks =>
      $$FlashcardSubDecksTableTableManager(
        _db.attachedDatabase,
        _db.flashcardSubDecks,
      );
  $$FlashcardsTableTableManager get flashcards =>
      $$FlashcardsTableTableManager(_db.attachedDatabase, _db.flashcards);
}
