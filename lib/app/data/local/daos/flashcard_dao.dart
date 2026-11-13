import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tutor_tables.dart';

part 'flashcard_dao.g.dart';

/// Aggregated statistics for a Level-1 [FlashcardDeck].
class DeckWithStats {
  const DeckWithStats({
    required this.deck,
    required this.subDeckCount,
    required this.totalCardCount,
  });

  final FlashcardDeck deck;
  final int subDeckCount;
  final int totalCardCount;
}

/// Aggregated card count for a Level-2 [FlashcardSubDeck].
class SubDeckWithStats {
  const SubDeckWithStats({
    required this.subDeck,
    required this.cardCount,
  });

  final FlashcardSubDeck subDeck;
  final int cardCount;
}

/// Represents a single AI-generated or saved example sentence on a flashcard.
class FlashcardExampleItem {
  const FlashcardExampleItem({
    required this.tense,
    required this.en,
    required this.id,
  });

  final String tense;
  final String en;
  final String id;

  factory FlashcardExampleItem.fromJson(Map<String, dynamic> json) {
    return FlashcardExampleItem(
      tense: (json['tense']?.toString() ?? '').trim(),
      en: (json['en']?.toString() ?? '').trim(),
      id: (json['id']?.toString() ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tense': tense,
        'en': en,
        'id': id,
      };

  /// Safely decodes a JSON array string into typed [FlashcardExampleItem]s.
  static List<FlashcardExampleItem> decodeExamples(String jsonStr) {
    final trimmed = jsonStr.trim();
    if (trimmed.isEmpty) return const <FlashcardExampleItem>[];

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! List) return const <FlashcardExampleItem>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) => FlashcardExampleItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.en.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <FlashcardExampleItem>[];
    }
  }

  /// Serializes [items] into a JSON array string suitable for Drift storage.
  static String encodeExamples(List<FlashcardExampleItem> items) {
    return jsonEncode(items.map((item) => item.toJson()).toList(growable: false));
  }
}

/// Reactive queries and CRUD operations for the 3-level Flashcard hierarchy.
@DriftAccessor(tables: [FlashcardDecks, FlashcardSubDecks, Flashcards])
class FlashcardDao extends DatabaseAccessor<AppDatabase>
    with _$FlashcardDaoMixin {
  FlashcardDao(super.db);

  // --- Level 1: Decks ---

  /// Watches all decks ordered newest-first alongside sub-deck and card counts.
  Stream<List<DeckWithStats>> watchDecksWithStats() {
    final query = select(flashcardDecks).join([
      leftOuterJoin(
        flashcardSubDecks,
        flashcardSubDecks.deckId.equalsExp(flashcardDecks.id),
      ),
      leftOuterJoin(
        flashcards,
        flashcards.subDeckId.equalsExp(flashcardSubDecks.id),
      ),
    ])
      ..orderBy([
        OrderingTerm.desc(flashcardDecks.updatedAt),
        OrderingTerm.desc(flashcardDecks.id),
      ]);

    return query.watch().map((rows) {
      final grouped = <int, _MutableDeckAccumulator>{};
      for (final row in rows) {
        final deck = row.readTable(flashcardDecks);
        final subDeck = row.readTableOrNull(flashcardSubDecks);
        final card = row.readTableOrNull(flashcards);

        final acc = grouped.putIfAbsent(
          deck.id,
          () => _MutableDeckAccumulator(deck),
        );
        if (subDeck != null) {
          acc.subDeckIds.add(subDeck.id);
        }
        if (card != null) {
          acc.cardIds.add(card.id);
        }
      }
      return grouped.values
          .map(
            (acc) => DeckWithStats(
              deck: acc.deck,
              subDeckCount: acc.subDeckIds.length,
              totalCardCount: acc.cardIds.length,
            ),
          )
          .toList(growable: false);
    });
  }

  /// Fetches all decks with their sub-deck and card counts once.
  Future<List<DeckWithStats>> getDecksWithStats() {
    return watchDecksWithStats().first;
  }

  /// Inserts a new top-level [FlashcardDeck] and returns its ID.
  Future<int> createDeck({required String name, String? description}) {
    final now = DateTime.now();
    final trimmedDesc = description?.trim();
    return into(flashcardDecks).insert(
      FlashcardDecksCompanion.insert(
        name: name.trim(),
        description: Value(
          (trimmedDesc != null && trimmedDesc.isNotEmpty) ? trimmedDesc : null,
        ),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Renames deck [deckId] and refreshes its `updatedAt` timestamp.
  Future<void> renameDeck(int deckId, String newName) async {
    await (update(flashcardDecks)..where((t) => t.id.equals(deckId))).write(
      FlashcardDecksCompanion(
        name: Value(newName.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes deck [deckId] (cascades to all child sub-decks and flashcards).
  Future<void> deleteDeck(int deckId) async {
    await (delete(flashcardDecks)..where((t) => t.id.equals(deckId))).go();
  }

  // --- Level 2: Sub-Decks ---

  /// Watches sub-decks inside [deckId] alongside each sub-deck's card count.
  Stream<List<SubDeckWithStats>> watchSubDecksWithStats(int deckId) {
    final query = (select(flashcardSubDecks)
          ..where((t) => t.deckId.equals(deckId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .join([
      leftOuterJoin(
        flashcards,
        flashcards.subDeckId.equalsExp(flashcardSubDecks.id),
      ),
    ]);

    return query.watch().map((rows) {
      final grouped = <int, _MutableSubDeckAccumulator>{};
      for (final row in rows) {
        final subDeck = row.readTable(flashcardSubDecks);
        final card = row.readTableOrNull(flashcards);

        final acc = grouped.putIfAbsent(
          subDeck.id,
          () => _MutableSubDeckAccumulator(subDeck),
        );
        if (card != null) {
          acc.cardIds.add(card.id);
        }
      }
      return grouped.values
          .map(
            (acc) => SubDeckWithStats(
              subDeck: acc.subDeck,
              cardCount: acc.cardIds.length,
            ),
          )
          .toList(growable: false);
    });
  }

  /// Fetches sub-decks belonging to [deckId].
  Future<List<FlashcardSubDeck>> getSubDecksByDeck(int deckId) {
    return (select(flashcardSubDecks)
          ..where((t) => t.deckId.equals(deckId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  /// Inserts a new [FlashcardSubDeck] under [deckId] and returns its ID.
  Future<int> createSubDeck({
    required int deckId,
    required String name,
    String? description,
  }) {
    return transaction(() async {
      final now = DateTime.now();
      final trimmedDesc = description?.trim();
      final subDeckId = await into(flashcardSubDecks).insert(
        FlashcardSubDecksCompanion.insert(
          deckId: deckId,
          name: name.trim(),
          description: Value(
            (trimmedDesc != null && trimmedDesc.isNotEmpty)
                ? trimmedDesc
                : null,
          ),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await (update(flashcardDecks)..where((t) => t.id.equals(deckId))).write(
        FlashcardDecksCompanion(updatedAt: Value(now)),
      );
      return subDeckId;
    });
  }

  /// Renames sub-deck [subDeckId] and refreshes its `updatedAt` timestamp.
  Future<void> renameSubDeck(int subDeckId, String newName) async {
    await (update(flashcardSubDecks)..where((t) => t.id.equals(subDeckId)))
        .write(
      FlashcardSubDecksCompanion(
        name: Value(newName.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes sub-deck [subDeckId] (cascades to all flashcards inside it).
  Future<void> deleteSubDeck(int subDeckId) async {
    await (delete(flashcardSubDecks)..where((t) => t.id.equals(subDeckId)))
        .go();
  }

  // --- Level 3: Flashcards ---

  /// Watches all flashcards in [subDeckId] ordered newest-first.
  Stream<List<Flashcard>> watchFlashcardsBySubDeck(int subDeckId) {
    return (select(flashcards)
          ..where((t) => t.subDeckId.equals(subDeckId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  /// Returns all flashcards inside a single [subDeckId] (for Sub-Deck quiz scope).
  Future<List<Flashcard>> getCardsBySubDeck(int subDeckId) {
    return (select(flashcards)
          ..where((t) => t.subDeckId.equals(subDeckId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.masteryLevel),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  /// Returns all flashcards across every sub-deck inside [deckId] (for Deck quiz scope).
  Future<List<Flashcard>> getCardsByDeck(int deckId) async {
    final query = (select(flashcards).join([
      innerJoin(
        flashcardSubDecks,
        flashcardSubDecks.id.equalsExp(flashcards.subDeckId),
      ),
    ])
          ..where(flashcardSubDecks.deckId.equals(deckId))
          ..orderBy([
            OrderingTerm.asc(flashcards.masteryLevel),
            OrderingTerm.asc(flashcards.id),
          ]));

    final rows = await query.get();
    return rows.map((row) => row.readTable(flashcards)).toList(growable: false);
  }

  /// Inserts a flashcard into [subDeckId] or merges new details if the same
  /// word (case-insensitive) already exists inside that sub-deck.
  Future<int> createFlashcard({
    required int subDeckId,
    required String word,
    String? phonetic,
    required String meaningId,
    String wordType = 'non_verb',
    List<FlashcardExampleItem> examples = const [],
    String aiConversation = '',
  }) {
    return transaction(() async {
      final trimmedWord = word.trim();
      final normalizedTarget = trimmedWord.toLowerCase();
      final existingCards = await (select(flashcards)
            ..where((t) => t.subDeckId.equals(subDeckId)))
          .get();

      Flashcard? existing;
      for (final card in existingCards) {
        if (card.word.trim().toLowerCase() == normalizedTarget) {
          existing = card;
          break;
        }
      }

      final normalizedWordType = wordType == 'verb' ? 'verb' : 'non_verb';
      final trimmedPhonetic = phonetic?.trim();
      final trimmedMeaning = meaningId.trim();
      final trimmedConversation = aiConversation.trim();

      if (existing != null) {
        final nextPhonetic =
            (trimmedPhonetic != null && trimmedPhonetic.isNotEmpty)
                ? trimmedPhonetic
                : existing.phonetic;
        final nextMeaning =
            trimmedMeaning.isNotEmpty ? trimmedMeaning : existing.meaningId;
        final nextWordType =
            normalizedWordType == 'verb' ? 'verb' : existing.wordType;
        final nextExamplesJson = examples.isNotEmpty
            ? FlashcardExampleItem.encodeExamples(examples)
            : existing.examplesJson;
        final nextConversation = trimmedConversation.isNotEmpty
            ? trimmedConversation
            : existing.aiConversation;

        await (update(flashcards)..where((t) => t.id.equals(existing!.id)))
            .write(
          FlashcardsCompanion(
            phonetic: Value(nextPhonetic),
            meaningId: Value(nextMeaning),
            wordType: Value(nextWordType),
            examplesJson: Value(nextExamplesJson),
            aiConversation: Value(nextConversation),
          ),
        );
        return existing.id;
      }

      final insertedId = await into(flashcards).insert(
        FlashcardsCompanion.insert(
          subDeckId: subDeckId,
          word: trimmedWord,
          phonetic: Value(
            (trimmedPhonetic != null && trimmedPhonetic.isNotEmpty)
                ? trimmedPhonetic
                : null,
          ),
          meaningId: Value(trimmedMeaning),
          wordType: Value(normalizedWordType),
          examplesJson: Value(FlashcardExampleItem.encodeExamples(examples)),
          aiConversation: Value(trimmedConversation),
          createdAt: Value(DateTime.now()),
        ),
      );
      await (update(flashcardSubDecks)..where((t) => t.id.equals(subDeckId)))
          .write(
        FlashcardSubDecksCompanion(updatedAt: Value(DateTime.now())),
      );
      return insertedId;
    });
  }

  /// Updates generated practice details (examples, conversation, phonetic, etc.).
  Future<void> updateFlashcardPracticeContent({
    required int cardId,
    String? phonetic,
    String? meaningId,
    String? wordType,
    List<FlashcardExampleItem>? examples,
    String? aiConversation,
  }) async {
    await (update(flashcards)..where((t) => t.id.equals(cardId))).write(
      FlashcardsCompanion(
        phonetic: phonetic != null
            ? Value(phonetic.trim().isEmpty ? null : phonetic.trim())
            : const Value.absent(),
        meaningId: meaningId != null
            ? Value(meaningId.trim())
            : const Value.absent(),
        wordType: wordType != null
            ? Value(wordType == 'verb' ? 'verb' : 'non_verb')
            : const Value.absent(),
        examplesJson: examples != null
            ? Value(FlashcardExampleItem.encodeExamples(examples))
            : const Value.absent(),
        aiConversation: aiConversation != null
            ? Value(aiConversation.trim())
            : const Value.absent(),
      ),
    );
  }

  /// Records a quiz/review outcome for [cardId], clamping `masteryLevel` to `0..5`.
  Future<void> recordCardReview({
    required int cardId,
    required bool isCorrect,
  }) {
    return transaction(() async {
      final card = await (select(flashcards)..where((t) => t.id.equals(cardId)))
          .getSingleOrNull();
      if (card == null) return;

      final nextMastery = isCorrect
          ? math.min(5, card.masteryLevel + 1)
          : math.max(0, card.masteryLevel - 1);

      await (update(flashcards)..where((t) => t.id.equals(cardId))).write(
        FlashcardsCompanion(
          masteryLevel: Value(nextMastery),
          reviewCount: Value(card.reviewCount + 1),
          lastReviewedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// Permanently deletes flashcard [cardId].
  Future<void> deleteFlashcard(int cardId) async {
    await (delete(flashcards)..where((t) => t.id.equals(cardId))).go();
  }
}

class _MutableDeckAccumulator {
  _MutableDeckAccumulator(this.deck);

  final FlashcardDeck deck;
  final Set<int> subDeckIds = <int>{};
  final Set<int> cardIds = <int>{};
}

class _MutableSubDeckAccumulator {
  _MutableSubDeckAccumulator(this.subDeck);

  final FlashcardSubDeck subDeck;
  final Set<int> cardIds = <int>{};
}
