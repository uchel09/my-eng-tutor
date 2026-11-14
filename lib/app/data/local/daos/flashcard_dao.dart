import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tutor_tables.dart';

part 'flashcard_dao.g.dart';

/// Lightweight flashcard input used for bulk curriculum seeding/upsert.
class FlashcardSeedInput {
  const FlashcardSeedInput({
    required this.word,
    this.phonetic = '',
    this.meaningId = '',
    this.partsOfSpeech = const <String>[],
  });

  final String word;
  final String phonetic;
  final String meaningId;
  final List<String> partsOfSpeech;
}

/// Study status constants and labels for flashcard progress tracking.
class FlashcardStudyStatus {
  const FlashcardStudyStatus._();

  static const int unstudied = 0;
  static const int needsReview = 1;
  static const int mastered = 2;

  static int clamp(int value) => value.clamp(unstudied, mastered);

  static String labelId(int status) {
    switch (clamp(status)) {
      case needsReview:
        return 'Perlu Ulang';
      case mastered:
        return 'Hafal';
      case unstudied:
      default:
        return 'Belum';
    }
  }
}

/// Aggregated statistics for a Level-1 [FlashcardDeck].
class DeckWithStats {
  const DeckWithStats({
    required this.deck,
    required this.subDeckCount,
    required this.totalCardCount,
    this.completedCardCount = 0,
    this.reviewCardCount = 0,
  });

  final FlashcardDeck deck;
  final int subDeckCount;
  final int totalCardCount;
  final int completedCardCount;
  final int reviewCardCount;

  double get progressRatio =>
      totalCardCount <= 0 ? 0.0 : completedCardCount / totalCardCount;

  int get progressPercent => (progressRatio * 100).round().clamp(0, 100);
}

/// Aggregated card count and progress stats for a Level-2 [FlashcardSubDeck].
class SubDeckWithStats {
  const SubDeckWithStats({
    required this.subDeck,
    required this.cardCount,
    this.completedCardCount = 0,
    this.reviewCardCount = 0,
  });

  final FlashcardSubDeck subDeck;
  final int cardCount;
  final int completedCardCount;
  final int reviewCardCount;

  double get progressRatio =>
      cardCount <= 0 ? 0.0 : completedCardCount / cardCount;

  int get progressPercent => (progressRatio * 100).round().clamp(0, 100);
}

/// Represents a single AI-generated or saved example sentence on a flashcard.
class FlashcardExampleItem {
  const FlashcardExampleItem({
    required this.tense,
    required this.en,
    required this.id,
    this.pos = '',
  });

  final String tense;
  final String en;
  final String id;
  final String pos;

  factory FlashcardExampleItem.fromJson(Map<String, dynamic> json) {
    return FlashcardExampleItem(
      tense: (json['tense']?.toString() ?? '').trim(),
      en: (json['en']?.toString() ?? '').trim(),
      id: (json['id']?.toString() ?? '').trim(),
      pos: (json['pos']?.toString() ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() {
    final trimmedPos = pos.trim();
    return <String, dynamic>{
      'tense': tense,
      'en': en,
      'id': id,
      if (trimmedPos.isNotEmpty) 'pos': trimmedPos,
    };
  }

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

/// Utilities for normalizing, encoding, and classifying flashcard Parts of Speech.
class FlashcardPosHelper {
  const FlashcardPosHelper._();

  /// Normalizes a single POS label into Title Case (e.g. `'phrasal verb'` -> `'Phrasal Verb'`).
  static String normalizePosLabel(String raw) {
    final words = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '';

    return words
        .map(
          (w) => w.length == 1
              ? w.toUpperCase()
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  /// Normalizes and deduplicates an arbitrary list of POS labels without count limits.
  static List<String> normalizePartsOfSpeech(Iterable<String> rawList) {
    final result = <String>[];
    final seenLower = <String>{};
    for (final raw in rawList) {
      final normalized = normalizePosLabel(raw);
      if (normalized.isEmpty) continue;
      final key = normalized.toLowerCase();
      if (seenLower.add(key)) {
        result.add(normalized);
      }
    }
    return List<String>.unmodifiable(result);
  }

  /// Encodes normalized Parts of Speech into a JSON array string for Drift storage.
  static String encodePartsOfSpeech(List<String> posList) {
    return jsonEncode(normalizePartsOfSpeech(posList));
  }

  /// Safely decodes a Drift JSON array string into normalized Title Case POS labels.
  static List<String> decodePartsOfSpeech(String jsonStr) {
    final trimmed = jsonStr.trim();
    if (trimmed.isEmpty) return const <String>[];

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! List) return const <String>[];
      return normalizePartsOfSpeech(decoded.map((e) => e.toString()));
    } catch (_) {
      return const <String>[];
    }
  }

  /// Returns `true` if a single POS label represents Verb or Phrasal Verb.
  static bool isVerbPos(String pos) {
    final lower = normalizePosLabel(pos).toLowerCase();
    return lower == 'verb' || lower == 'phrasal verb';
  }

  /// Returns `true` if [posList] includes `'Verb'` or `'Phrasal Verb'`.
  static bool hasVerbPos(List<String> posList) {
    return posList.any(isVerbPos);
  }

  /// Returns all POS labels in [posList] excluding `'Verb'` and `'Phrasal Verb'`.
  static List<String> nonVerbPosList(List<String> posList) {
    return normalizePartsOfSpeech(posList)
        .where((pos) => !isVerbPos(pos))
        .toList(growable: false);
  }

  /// Returns `true` when [posList] combines Verb/Phrasal Verb with at least one other POS.
  static bool isHybridWithVerb(List<String> posList) {
    final normalized = normalizePartsOfSpeech(posList);
    return hasVerbPos(normalized) && nonVerbPosList(normalized).isNotEmpty;
  }

  /// Derives backward-compatible `'verb'` / `'non_verb'` category from [posList].
  static String deriveWordType(
    List<String> posList, {
    String fallback = 'non_verb',
  }) {
    final normalized = normalizePartsOfSpeech(posList);
    if (normalized.isNotEmpty) {
      return hasVerbPos(normalized) ? 'verb' : 'non_verb';
    }
    return fallback == 'verb' ? 'verb' : 'non_verb';
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
          if (card.studyStatus == FlashcardStudyStatus.mastered) {
            acc.completedCardIds.add(card.id);
          } else if (card.studyStatus == FlashcardStudyStatus.needsReview) {
            acc.reviewCardIds.add(card.id);
          }
        }
      }
      return grouped.values
          .map(
            (acc) => DeckWithStats(
              deck: acc.deck,
              subDeckCount: acc.subDeckIds.length,
              totalCardCount: acc.cardIds.length,
              completedCardCount: acc.completedCardIds.length,
              reviewCardCount: acc.reviewCardIds.length,
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

  /// Looks up a deck by [name] (trim + case-insensitive) or creates it if missing.
  Future<int> getOrCreateDeckByName({
    required String name,
    String? description,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama deck wajib diisi.');
    }

    return transaction(() async {
      final targetKey = trimmed.toLowerCase();
      final existingDecks = await select(flashcardDecks).get();
      for (final deck in existingDecks) {
        if (deck.name.trim().toLowerCase() == targetKey) {
          return deck.id;
        }
      }
      return createDeck(name: trimmed, description: description);
    });
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
          if (card.studyStatus == FlashcardStudyStatus.mastered) {
            acc.completedCardIds.add(card.id);
          } else if (card.studyStatus == FlashcardStudyStatus.needsReview) {
            acc.reviewCardIds.add(card.id);
          }
        }
      }
      return grouped.values
          .map(
            (acc) => SubDeckWithStats(
              subDeck: acc.subDeck,
              cardCount: acc.cardIds.length,
              completedCardCount: acc.completedCardIds.length,
              reviewCardCount: acc.reviewCardIds.length,
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

  /// Looks up a sub-deck in [deckId] by [name] (trim + case-insensitive) or creates it.
  Future<int> getOrCreateSubDeckByName({
    required int deckId,
    required String name,
    String? description,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama sub-deck wajib diisi.');
    }

    return transaction(() async {
      final targetKey = trimmed.toLowerCase();
      final existingSubDecks = await getSubDecksByDeck(deckId);
      for (final subDeck in existingSubDecks) {
        if (subDeck.name.trim().toLowerCase() == targetKey) {
          return subDeck.id;
        }
      }
      return createSubDeck(
        deckId: deckId,
        name: trimmed,
        description: description,
      );
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
    List<String>? partsOfSpeech,
    List<FlashcardExampleItem> examples = const [],
    List<FlashcardExampleItem>? verbTensesExamples,
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

      final normalizedPos = partsOfSpeech != null
          ? FlashcardPosHelper.normalizePartsOfSpeech(partsOfSpeech)
          : const <String>[];
      final normalizedWordType = FlashcardPosHelper.deriveWordType(
        normalizedPos,
        fallback: wordType,
      );
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
        final nextPartsOfSpeechJson = normalizedPos.isNotEmpty
            ? FlashcardPosHelper.encodePartsOfSpeech(normalizedPos)
            : existing.partsOfSpeechJson;
        final nextWordType = normalizedPos.isNotEmpty
            ? normalizedWordType
            : (normalizedWordType == 'verb' ? 'verb' : existing.wordType);
        final nextExamplesJson = examples.isNotEmpty
            ? FlashcardExampleItem.encodeExamples(examples)
            : existing.examplesJson;
        final nextVerbTensesJson =
            (verbTensesExamples != null && verbTensesExamples.isNotEmpty)
                ? FlashcardExampleItem.encodeExamples(verbTensesExamples)
                : existing.verbTensesExamplesJson;
        final nextConversation = trimmedConversation.isNotEmpty
            ? trimmedConversation
            : existing.aiConversation;

        await (update(flashcards)..where((t) => t.id.equals(existing!.id)))
            .write(
          FlashcardsCompanion(
            phonetic: Value(nextPhonetic),
            meaningId: Value(nextMeaning),
            wordType: Value(nextWordType),
            partsOfSpeechJson: Value(nextPartsOfSpeechJson),
            examplesJson: Value(nextExamplesJson),
            verbTensesExamplesJson: Value(nextVerbTensesJson),
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
          partsOfSpeechJson: Value(
            FlashcardPosHelper.encodePartsOfSpeech(normalizedPos),
          ),
          examplesJson: Value(FlashcardExampleItem.encodeExamples(examples)),
          verbTensesExamplesJson: Value(
            FlashcardExampleItem.encodeExamples(
              verbTensesExamples ?? const <FlashcardExampleItem>[],
            ),
          ),
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

  /// Updates flashcard core fields and/or generated practice details.
  Future<void> updateFlashcardPracticeContent({
    required int cardId,
    String? word,
    String? phonetic,
    String? meaningId,
    String? wordType,
    List<String>? partsOfSpeech,
    List<FlashcardExampleItem>? examples,
    List<FlashcardExampleItem>? verbTensesExamples,
    String? aiConversation,
  }) {
    return transaction(() async {
      String? trimmedWord;
      if (word != null) {
        trimmedWord = word.trim();
        if (trimmedWord.isEmpty) {
          throw ArgumentError.value(
            word,
            'word',
            'Kata bahasa Inggris wajib diisi.',
          );
        }

        final currentCard = await (select(flashcards)
              ..where((t) => t.id.equals(cardId)))
            .getSingleOrNull();
        if (currentCard != null) {
          final normalizedTarget = trimmedWord.toLowerCase();
          final siblings = await (select(flashcards)
                ..where((t) => t.subDeckId.equals(currentCard.subDeckId)))
              .get();
          for (final other in siblings) {
            if (other.id != cardId &&
                other.word.trim().toLowerCase() == normalizedTarget) {
              throw StateError(
                'Kata "$trimmedWord" sudah ada di sub-deck ini.',
              );
            }
          }
        }
      }

      final normalizedPos = partsOfSpeech != null
          ? FlashcardPosHelper.normalizePartsOfSpeech(partsOfSpeech)
          : null;
      final resolvedWordType = normalizedPos != null
          ? FlashcardPosHelper.deriveWordType(
              normalizedPos,
              fallback: wordType ?? 'non_verb',
            )
          : (wordType != null
                ? (wordType == 'verb' ? 'verb' : 'non_verb')
                : null);

      await (update(flashcards)..where((t) => t.id.equals(cardId))).write(
        FlashcardsCompanion(
          word: trimmedWord != null
              ? Value(trimmedWord)
              : const Value.absent(),
          phonetic: phonetic != null
              ? Value(phonetic.trim().isEmpty ? null : phonetic.trim())
              : const Value.absent(),
          meaningId: meaningId != null
              ? Value(meaningId.trim())
              : const Value.absent(),
          wordType: resolvedWordType != null
              ? Value(resolvedWordType)
              : const Value.absent(),
          partsOfSpeechJson: normalizedPos != null
              ? Value(FlashcardPosHelper.encodePartsOfSpeech(normalizedPos))
              : const Value.absent(),
          examplesJson: examples != null
              ? Value(FlashcardExampleItem.encodeExamples(examples))
              : const Value.absent(),
          verbTensesExamplesJson: verbTensesExamples != null
              ? Value(FlashcardExampleItem.encodeExamples(verbTensesExamples))
              : const Value.absent(),
          aiConversation: aiConversation != null
              ? Value(aiConversation.trim())
              : const Value.absent(),
        ),
      );
    });
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

  /// Updates the 3-state [studyStatus] (`0` Belum, `1` Perlu Ulang, `2` Hafal) for [cardId].
  Future<void> updateCardStudyStatus({
    required int cardId,
    required int studyStatus,
  }) async {
    final normalized = FlashcardStudyStatus.clamp(studyStatus);
    await (update(flashcards)..where((t) => t.id.equals(cardId))).write(
      FlashcardsCompanion(studyStatus: Value(normalized)),
    );
  }

  /// Permanently deletes flashcard [cardId].
  Future<void> deleteFlashcard(int cardId) async {
    await (delete(flashcards)..where((t) => t.id.equals(cardId))).go();
  }

  /// Returns lowercase trimmed words across all sub-decks belonging to [deckId].
  Future<Set<String>> getExistingWordsInDeck(int deckId) async {
    final query = selectOnly(flashcards).join([
      innerJoin(
        flashcardSubDecks,
        flashcardSubDecks.id.equalsExp(flashcards.subDeckId),
      ),
    ])
      ..addColumns([flashcards.word])
      ..where(flashcardSubDecks.deckId.equals(deckId));

    final rows = await query.get();
    final existingWords = <String>{};
    for (final row in rows) {
      final word = (row.read(flashcards.word) ?? '').trim().toLowerCase();
      if (word.isNotEmpty) {
        existingWords.add(word);
      }
    }
    return existingWords;
  }

  /// Bulk inserts new cards into [subDeckId] or fills blank core fields on existing
  /// cards without overwriting user-generated example sentences or conversations.
  ///
  /// Returns the count of newly inserted flashcards.
  Future<int> bulkUpsertFlashcards({
    required int subDeckId,
    required List<FlashcardSeedInput> items,
  }) {
    if (items.isEmpty) return Future<int>.value(0);

    return transaction(() async {
      final existingCards = await (select(flashcards)
            ..where((t) => t.subDeckId.equals(subDeckId)))
          .get();

      final existingByWord = <String, Flashcard>{
        for (final card in existingCards)
          card.word.trim().toLowerCase(): card,
      };
      final seenInputKeys = <String>{};
      final toInsert = <FlashcardsCompanion>[];
      final now = DateTime.now();
      var touchedAny = false;

      for (final item in items) {
        final trimmedWord = item.word.trim();
        if (trimmedWord.isEmpty) continue;

        final key = trimmedWord.toLowerCase();
        if (!seenInputKeys.add(key)) continue;

        final normalizedPos = FlashcardPosHelper.normalizePartsOfSpeech(
          item.partsOfSpeech,
        );
        final trimmedPhonetic = item.phonetic.trim();
        final trimmedMeaning = item.meaningId.trim();

        final existing = existingByWord[key];
        if (existing != null) {
          final existingPhoneticBlank =
              existing.phonetic == null || existing.phonetic!.trim().isEmpty;
          final existingMeaningBlank = existing.meaningId.trim().isEmpty;
          final existingPosBlank = FlashcardPosHelper.decodePartsOfSpeech(
            existing.partsOfSpeechJson,
          ).isEmpty;

          final shouldUpdatePhonetic =
              existingPhoneticBlank && trimmedPhonetic.isNotEmpty;
          final shouldUpdateMeaning =
              existingMeaningBlank && trimmedMeaning.isNotEmpty;
          final shouldUpdatePos =
              existingPosBlank && normalizedPos.isNotEmpty;

          if (shouldUpdatePhonetic || shouldUpdateMeaning || shouldUpdatePos) {
            touchedAny = true;
            await (update(flashcards)..where((t) => t.id.equals(existing.id)))
                .write(
              FlashcardsCompanion(
                phonetic: shouldUpdatePhonetic
                    ? Value(trimmedPhonetic)
                    : const Value.absent(),
                meaningId: shouldUpdateMeaning
                    ? Value(trimmedMeaning)
                    : const Value.absent(),
                partsOfSpeechJson: shouldUpdatePos
                    ? Value(
                        FlashcardPosHelper.encodePartsOfSpeech(normalizedPos),
                      )
                    : const Value.absent(),
                wordType: shouldUpdatePos
                    ? Value(FlashcardPosHelper.deriveWordType(normalizedPos))
                    : const Value.absent(),
              ),
            );
          }
          continue;
        }

        final wordType = FlashcardPosHelper.deriveWordType(normalizedPos);
        toInsert.add(
          FlashcardsCompanion.insert(
            subDeckId: subDeckId,
            word: trimmedWord,
            phonetic: Value(trimmedPhonetic.isEmpty ? null : trimmedPhonetic),
            meaningId: Value(trimmedMeaning),
            wordType: Value(wordType),
            partsOfSpeechJson: Value(
              FlashcardPosHelper.encodePartsOfSpeech(normalizedPos),
            ),
            examplesJson: const Value('[]'),
            verbTensesExamplesJson: const Value('[]'),
            aiConversation: const Value(''),
            createdAt: Value(now),
          ),
        );
      }

      if (toInsert.isNotEmpty) {
        touchedAny = true;
        await batch((b) {
          b.insertAll(flashcards, toInsert);
        });
      }

      if (touchedAny) {
        await (update(flashcardSubDecks)..where((t) => t.id.equals(subDeckId)))
            .write(FlashcardSubDecksCompanion(updatedAt: Value(now)));

        final subDeckRow = await (select(flashcardSubDecks)
              ..where((t) => t.id.equals(subDeckId)))
            .getSingleOrNull();
        if (subDeckRow != null) {
          await (update(flashcardDecks)
                ..where((t) => t.id.equals(subDeckRow.deckId)))
              .write(FlashcardDecksCompanion(updatedAt: Value(now)));
        }
      }

      return toInsert.length;
    });
  }
}

class _MutableDeckAccumulator {
  _MutableDeckAccumulator(this.deck);

  final FlashcardDeck deck;
  final Set<int> subDeckIds = <int>{};
  final Set<int> cardIds = <int>{};
  final Set<int> completedCardIds = <int>{};
  final Set<int> reviewCardIds = <int>{};
}

class _MutableSubDeckAccumulator {
  _MutableSubDeckAccumulator(this.subDeck);

  final FlashcardSubDeck subDeck;
  final Set<int> cardIds = <int>{};
  final Set<int> completedCardIds = <int>{};
  final Set<int> reviewCardIds = <int>{};
}
