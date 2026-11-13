// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_dao.dart';

// ignore_for_file: type=lint
mixin _$FlashcardDaoMixin on DatabaseAccessor<AppDatabase> {
  $FlashcardDecksTable get flashcardDecks => attachedDatabase.flashcardDecks;
  $FlashcardSubDecksTable get flashcardSubDecks =>
      attachedDatabase.flashcardSubDecks;
  $FlashcardsTable get flashcards => attachedDatabase.flashcards;
  FlashcardDaoManager get managers => FlashcardDaoManager(this);
}

class FlashcardDaoManager {
  final _$FlashcardDaoMixin _db;
  FlashcardDaoManager(this._db);
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
