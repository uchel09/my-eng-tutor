import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/local/daos/flashcard_dao.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/services/tts_service.dart';
import 'package:my_english_tutor/app/modules/flashcards/models/daily_vocab_curriculum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlashcardDao & Migration v3 Tests', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      // Trigger database open and initial seeding.
      await db.roadmapDao.watchAllLevelsWithLessons().first;
    });

    tearDown(() async {
      await db.close();
    });

    test('creates 3-level Deck -> SubDeck -> Flashcard and reports stats', () async {
      final deckId = await db.flashcardDao.createDeck(
        name: 'Daily Verbs',
        description: 'Essential action verbs',
      );
      final subDeckId = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Office Actions',
      );

      await db.flashcardDao.createFlashcard(
        subDeckId: subDeckId,
        word: 'negotiate',
        phonetic: '/nɪˈɡoʊʃieɪt/',
        meaningId: 'bernegosiasi',
        wordType: 'verb',
        examples: const [
          FlashcardExampleItem(
            tense: 'Simple Present',
            en: 'We negotiate contracts every Monday.',
            id: 'Kami menegosiasikan kontrak setiap Senin.',
          ),
        ],
        aiConversation: 'A: Ready to negotiate?\nB: Yes, let us start.',
      );
      await db.flashcardDao.createFlashcard(
        subDeckId: subDeckId,
        word: 'clarify',
        meaningId: 'mengklarifikasi',
        wordType: 'verb',
      );

      final decksStats = await db.flashcardDao.watchDecksWithStats().first;
      expect(decksStats.length, 1);
      expect(decksStats.first.deck.name, 'Daily Verbs');
      expect(decksStats.first.subDeckCount, 1);
      expect(decksStats.first.totalCardCount, 2);

      await db.flashcardDao.renameDeck(deckId, 'Business Verbs');
      await db.flashcardDao.renameSubDeck(subDeckId, 'Meetings');

      final subDeckStats =
          await db.flashcardDao.watchSubDecksWithStats(deckId).first;
      expect(subDeckStats.length, 1);
      expect(subDeckStats.first.subDeck.name, 'Meetings');
      expect(subDeckStats.first.cardCount, 2);

      final refreshedDecks = await db.flashcardDao.getDecksWithStats();
      expect(refreshedDecks.first.deck.name, 'Business Verbs');
    });

    test('deduplicates word per subDeck case-insensitively without blocking other subDecks', () async {
      final deckId = await db.flashcardDao.createDeck(name: 'Core Vocab');
      final subA = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Sub A',
      );
      final subB = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Sub B',
      );

      final firstId = await db.flashcardDao.createFlashcard(
        subDeckId: subA,
        word: 'run',
        meaningId: 'berlari',
      );

      final dupId = await db.flashcardDao.createFlashcard(
        subDeckId: subA,
        word: '  RUN ',
        phonetic: '/rʌn/',
        meaningId: 'menjalankan / berlari',
        wordType: 'verb',
        examples: const [
          FlashcardExampleItem(
            tense: 'Simple Past',
            en: 'She ran to catch the train.',
            id: 'Dia berlari mengejar kereta.',
          ),
        ],
      );

      expect(dupId, firstId);

      final cardsSubA = await db.flashcardDao.getCardsBySubDeck(subA);
      expect(cardsSubA.length, 1);
      expect(cardsSubA.first.phonetic, '/rʌn/');
      expect(cardsSubA.first.meaningId, 'menjalankan / berlari');
      expect(cardsSubA.first.wordType, 'verb');

      final otherSubCardId = await db.flashcardDao.createFlashcard(
        subDeckId: subB,
        word: 'run',
        meaningId: 'berjalan (sistem)',
      );
      expect(otherSubCardId, isNot(firstId));

      final cardsSubB = await db.flashcardDao.getCardsBySubDeck(subB);
      expect(cardsSubB.length, 1);
    });

    test('getCardsByDeck merges across sub-decks while getCardsBySubDeck filters strictly', () async {
      final deck1 = await db.flashcardDao.createDeck(name: 'Deck 1');
      final deck2 = await db.flashcardDao.createDeck(name: 'Deck 2');
      final sub1 = await db.flashcardDao.createSubDeck(deckId: deck1, name: 'S1');
      final sub2 = await db.flashcardDao.createSubDeck(deckId: deck1, name: 'S2');
      final subOther = await db.flashcardDao.createSubDeck(deckId: deck2, name: 'S3');

      await db.flashcardDao.createFlashcard(
        subDeckId: sub1,
        word: 'resilient',
        meaningId: 'tangguh',
      );
      await db.flashcardDao.createFlashcard(
        subDeckId: sub2,
        word: 'coherent',
        meaningId: 'runtut',
      );
      await db.flashcardDao.createFlashcard(
        subDeckId: subOther,
        word: 'ambient',
        meaningId: 'suasana sekitar',
      );

      final mergedDeck1 = await db.flashcardDao.getCardsByDeck(deck1);
      expect(mergedDeck1.map((c) => c.word), containsAll(<String>['resilient', 'coherent']));
      expect(mergedDeck1.length, 2);

      final onlySub1 = await db.flashcardDao.getCardsBySubDeck(sub1);
      expect(onlySub1.map((c) => c.word), <String>['resilient']);
    });

    test('deleteDeck cascades delete to child sub-decks and flashcards', () async {
      final deckId = await db.flashcardDao.createDeck(name: 'Temp Deck');
      final subId = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Temp Sub',
      );
      await db.flashcardDao.createFlashcard(
        subDeckId: subId,
        word: 'ephemeral',
        meaningId: 'sementara',
      );

      expect((await db.flashcardDao.getSubDecksByDeck(deckId)).length, 1);
      expect((await db.flashcardDao.getCardsByDeck(deckId)).length, 1);

      await db.flashcardDao.deleteDeck(deckId);

      expect(await db.flashcardDao.getDecksWithStats(), isEmpty);
      expect(await db.flashcardDao.getSubDecksByDeck(deckId), isEmpty);
      expect(await db.flashcardDao.getCardsByDeck(deckId), isEmpty);
    });

    test('recordCardReview updates reviewCount, lastReviewedAt, and clamps masteryLevel 0..5', () async {
      final deckId = await db.flashcardDao.createDeck(name: 'Review Deck');
      final subId = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Review Sub',
      );
      final cardId = await db.flashcardDao.createFlashcard(
        subDeckId: subId,
        word: 'articulate',
        meaningId: 'fasih',
      );

      // Incorrect at level 0 should stay clamped at 0 while incrementing reviewCount.
      await db.flashcardDao.recordCardReview(cardId: cardId, isCorrect: false);
      var card = (await db.flashcardDao.getCardsBySubDeck(subId)).single;
      expect(card.masteryLevel, 0);
      expect(card.reviewCount, 1);
      expect(card.lastReviewedAt, isNotNull);

      // 7 consecutive correct reviews should cap masteryLevel at 5.
      for (var i = 0; i < 7; i++) {
        await db.flashcardDao.recordCardReview(cardId: cardId, isCorrect: true);
      }
      card = (await db.flashcardDao.getCardsBySubDeck(subId)).single;
      expect(card.masteryLevel, 5);
      expect(card.reviewCount, 8);

      // 1 incorrect review drops masteryLevel from 5 -> 4.
      await db.flashcardDao.recordCardReview(cardId: cardId, isCorrect: false);
      card = (await db.flashcardDao.getCardsBySubDeck(subId)).single;
      expect(card.masteryLevel, 4);
      expect(card.reviewCount, 9);
    });

    test('SettingsDao exports and imports 3-level flashcards and stays backward-compatible', () async {
      final deckId = await db.flashcardDao.createDeck(name: 'Backup Deck');
      final subId = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Backup Sub',
      );
      await db.flashcardDao.createFlashcard(
        subDeckId: subId,
        word: 'delegate',
        phonetic: '/ˈdelɪɡeɪt/',
        meaningId: 'mendelegasikan',
        wordType: 'verb',
        examples: const [
          FlashcardExampleItem(
            tense: 'Simple Present',
            en: 'Good managers delegate tasks wisely.',
            id: 'Manajer yang baik mendelegasikan tugas dengan bijak.',
          ),
        ],
      );

      final exported = await db.settingsDao.exportAllDataAsMap();
      expect(exported['version'], 2);
      expect((exported['flashcardDecks'] as List).length, 1);
      expect((exported['flashcardSubDecks'] as List).length, 1);
      expect((exported['flashcards'] as List).length, 1);

      // Clear and re-import full backup.
      await db.flashcardDao.deleteDeck(deckId);
      expect(await db.flashcardDao.getDecksWithStats(), isEmpty);

      await db.settingsDao.importAllDataFromMap(exported);
      final restoredDecks = await db.flashcardDao.getDecksWithStats();
      expect(restoredDecks.length, 1);
      expect(restoredDecks.first.deck.name, 'Backup Deck');
      expect(restoredDecks.first.subDeckCount, 1);
      expect(restoredDecks.first.totalCardCount, 1);

      // Simulate older v1 backup payload without flashcard keys.
      final legacyPayload = Map<String, dynamic>.from(exported)
        ..['version'] = 1
        ..remove('flashcardDecks')
        ..remove('flashcardSubDecks')
        ..remove('flashcards');

      await db.settingsDao.importAllDataFromMap(legacyPayload);
      expect(await db.flashcardDao.getDecksWithStats(), isEmpty);
      expect((await db.roadmapDao.watchAllLevelsWithLessons().first).length, 6);
    });

    test('FlashcardPosHelper & FlashcardExampleItem handle unlimited multi-POS normalization and backward compatibility', () {
      final normalized = FlashcardPosHelper.normalizePartsOfSpeech(const [
        'noun',
        'VERB',
        '  phrasal   verb ',
        'adjective',
        'Noun',
        'adverb',
        'preposition',
      ]);
      expect(normalized, <String>[
        'Noun',
        'Verb',
        'Phrasal Verb',
        'Adjective',
        'Adverb',
        'Preposition',
      ]);
      expect(FlashcardPosHelper.hasVerbPos(normalized), isTrue);
      expect(FlashcardPosHelper.nonVerbPosList(normalized), <String>[
        'Noun',
        'Adjective',
        'Adverb',
        'Preposition',
      ]);
      expect(FlashcardPosHelper.isHybridWithVerb(normalized), isTrue);
      expect(FlashcardPosHelper.isHybridWithVerb(const ['Adjective', 'Noun']), isFalse);
      expect(FlashcardPosHelper.isHybridWithVerb(const ['Phrasal Verb']), isFalse);
      expect(FlashcardPosHelper.hasVerbPos(const ['Phrasal Verb']), isTrue);

      final encodedPos = FlashcardPosHelper.encodePartsOfSpeech(normalized);
      expect(FlashcardPosHelper.decodePartsOfSpeech(encodedPos), normalized);
      expect(FlashcardPosHelper.decodePartsOfSpeech('invalid-json'), isEmpty);

      // Backward compatibility for FlashcardExampleItem without/with pos
      final legacyItem = FlashcardExampleItem.fromJson(const <String, dynamic>{
        'tense': 'Daily Use',
        'en': 'Stay calm.',
        'id': 'Tetap tenang.',
      });
      expect(legacyItem.pos, '');
      expect(legacyItem.toJson().containsKey('pos'), isFalse);

      final posItem = FlashcardExampleItem.fromJson(const <String, dynamic>{
        'pos': 'Adjective',
        'tense': 'Workplace',
        'en': 'We need a set schedule.',
        'id': 'Kami butuh jadwal yang pasti.',
      });
      expect(posItem.pos, 'Adjective');
      expect(posItem.toJson()['pos'], 'Adjective');
    });

    test('FlashcardDao & SettingsDao persist, export, and fallback partsOfSpeechJson & verbTensesExamplesJson', () async {
      final deckId = await db.flashcardDao.createDeck(name: 'Multi POS Deck');
      final subId = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Hybrid Words',
      );

      final cardId = await db.flashcardDao.createFlashcard(
        subDeckId: subId,
        word: 'set',
        meaningId: 'mengatur / perangkat / tetap',
      );

      final nonVerbExamples = List<FlashcardExampleItem>.generate(
        5,
        (i) => FlashcardExampleItem(
          pos: i.isEven ? 'Noun' : 'Adjective',
          tense: 'Daily Use',
          en: 'Non-verb sentence ${i + 1} for set.',
          id: 'Kalimat non-verb ${i + 1}.',
        ),
      );
      final verb16Examples = List<FlashcardExampleItem>.generate(
        16,
        (i) => FlashcardExampleItem(
          pos: 'Verb',
          tense: 'Tense ${i + 1}',
          en: 'Verb tense sentence ${i + 1} for set.',
          id: 'Kalimat verb ${i + 1}.',
        ),
      );

      await db.flashcardDao.updateFlashcardPracticeContent(
        cardId: cardId,
        phonetic: '/set/',
        meaningId: 'mengatur / seperangkat / pasti',
        partsOfSpeech: const ['noun', 'Verb', 'ADJECTIVE'],
        examples: nonVerbExamples,
        verbTensesExamples: verb16Examples,
        aiConversation: 'A: Is the date set?\nB: Yes, let us set up the set.',
      );

      final savedCard = (await db.flashcardDao.getCardsBySubDeck(subId)).single;
      expect(savedCard.wordType, 'verb');
      expect(
        FlashcardPosHelper.decodePartsOfSpeech(savedCard.partsOfSpeechJson),
        const ['Noun', 'Verb', 'Adjective'],
      );
      expect(
        FlashcardExampleItem.decodeExamples(savedCard.examplesJson),
        hasLength(5),
      );
      expect(
        FlashcardExampleItem.decodeExamples(savedCard.verbTensesExamplesJson),
        hasLength(16),
      );

      // Export & Re-import roundtrip preserves new JSON columns
      final exported = await db.settingsDao.exportAllDataAsMap();
      await db.flashcardDao.deleteDeck(deckId);
      await db.settingsDao.importAllDataFromMap(exported);

      final restoredCard = (await db.flashcardDao.getCardsByDeck(deckId)).single;
      expect(
        FlashcardPosHelper.decodePartsOfSpeech(restoredCard.partsOfSpeechJson),
        const ['Noun', 'Verb', 'Adjective'],
      );
      expect(
        FlashcardExampleItem.decodeExamples(restoredCard.verbTensesExamplesJson),
        hasLength(16),
      );

      // Legacy backup map without new columns falls back to '[]' safely
      final legacyExport = Map<String, dynamic>.from(exported);
      final cardsList = (legacyExport['flashcards'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      cardsList.first.remove('partsOfSpeechJson');
      cardsList.first.remove('verbTensesExamplesJson');
      legacyExport['flashcards'] = cardsList;

      await db.settingsDao.importAllDataFromMap(legacyExport);
      final legacyRestored =
          (await db.flashcardDao.getCardsByDeck(deckId)).single;
      expect(legacyRestored.partsOfSpeechJson, '[]');
      expect(legacyRestored.verbTensesExamplesJson, '[]');
    });

    test('updateFlashcardPracticeContent updates word and rejects empty or duplicate words within the same sub-deck', () async {
      final deckId = await db.flashcardDao.createDeck(name: 'Edit DAO Deck');
      final subA = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Sub A',
      );
      final subB = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Sub B',
      );

      final card1Id = await db.flashcardDao.createFlashcard(
        subDeckId: subA,
        word: 'schedule',
        phonetic: '/ˈskedʒuːl/',
        meaningId: 'jadwal',
        partsOfSpeech: const ['Noun'],
      );
      final card2Id = await db.flashcardDao.createFlashcard(
        subDeckId: subA,
        word: 'delegate',
        meaningId: 'mendelegasikan',
        partsOfSpeech: const ['Verb'],
      );
      await db.flashcardDao.createFlashcard(
        subDeckId: subB,
        word: 'agenda',
        meaningId: 'agenda',
      );

      // Empty/whitespace word throws ArgumentError.
      await expectLater(
        () => db.flashcardDao.updateFlashcardPracticeContent(
          cardId: card1Id,
          word: '   ',
        ),
        throwsArgumentError,
      );

      // Duplicate word inside the same sub-deck (case-insensitive) throws StateError.
      await expectLater(
        () => db.flashcardDao.updateFlashcardPracticeContent(
          cardId: card1Id,
          word: '  DELEGATE ',
        ),
        throwsStateError,
      );

      // Updating the same card's casing/fields succeeds without self-conflict.
      await db.flashcardDao.updateFlashcardPracticeContent(
        cardId: card1Id,
        word: '  Schedule  ',
        phonetic: '/ˈʃedʒ.uːl/',
        meaningId: 'jadwal / menjadwalkan',
        partsOfSpeech: const ['noun', 'verb'],
      );

      final subACards = await db.flashcardDao.getCardsBySubDeck(subA);
      final updatedCard1 = subACards.firstWhere((c) => c.id == card1Id);
      expect(updatedCard1.word, 'Schedule');
      expect(updatedCard1.phonetic, '/ˈʃedʒ.uːl/');
      expect(updatedCard1.meaningId, 'jadwal / menjadwalkan');
      expect(updatedCard1.wordType, 'verb');
      expect(
        FlashcardPosHelper.decodePartsOfSpeech(updatedCard1.partsOfSpeechJson),
        const ['Noun', 'Verb'],
      );

      // Same word allowed in a different sub-deck (subA vs subB).
      await db.flashcardDao.updateFlashcardPracticeContent(
        cardId: card2Id,
        word: 'agenda',
        partsOfSpeech: const <String>[],
      );
      final updatedCard2 =
          (await db.flashcardDao.getCardsBySubDeck(subA))
              .firstWhere((c) => c.id == card2Id);
      expect(updatedCard2.word, 'agenda');
      expect(updatedCard2.wordType, 'non_verb');
      expect(updatedCard2.partsOfSpeechJson, '[]');
    });

    test('getOrCreateDeckByName, getOrCreateSubDeckByName, getExistingWordsInDeck, bulkUpsertFlashcards & DailyVocabCurriculum', () async {
      // Static curriculum verification: 4 CEFR levels x 12 sub-decks = 48 topics (2,400 words).
      expect(DailyVocabCurriculum.levels, hasLength(4));
      expect(DailyVocabCurriculum.allTopics, hasLength(48));
      expect(
        DailyVocabCurriculum.allTopics.fold<int>(
          0,
          (sum, topic) => sum + topic.targetCount,
        ),
        2400,
      );
      expect(DailyVocabCurriculum.topicsForLevel('A1'), hasLength(12));
      expect(DailyVocabCurriculum.topicsForLevel('b2'), hasLength(12));

      final deckId1 = await db.flashcardDao.getOrCreateDeckByName(
        name: '  A1 - Pemula (Daily Basics) ',
        description: 'Deck pemula',
      );
      final deckId2 = await db.flashcardDao.getOrCreateDeckByName(
        name: 'a1 - pemula (daily basics)',
      );
      expect(deckId2, deckId1);

      final subId1 = await db.flashcardDao.getOrCreateSubDeckByName(
        deckId: deckId1,
        name: ' Daily Routines & Actions ',
        description: 'Aktivitas rutin',
      );
      final subId2 = await db.flashcardDao.getOrCreateSubDeckByName(
        deckId: deckId1,
        name: 'daily routines & actions',
      );
      expect(subId2, subId1);

      final otherSubId = await db.flashcardDao.getOrCreateSubDeckByName(
        deckId: deckId1,
        name: 'Food, Cooking & Dining',
      );

      // Pre-seed one card with existing examples & blank phonetic/meaning/POS.
      await db.flashcardDao.createFlashcard(
        subDeckId: subId1,
        word: 'wake up',
        meaningId: '',
        examples: const <FlashcardExampleItem>[
          FlashcardExampleItem(
            pos: 'Phrasal Verb',
            tense: 'Simple Present',
            en: 'I wake up at 6 a.m.',
            id: 'Saya bangun pukul 6 pagi.',
          ),
        ],
        aiConversation: 'A: When do you wake up?\nB: Early!',
      );
      await db.flashcardDao.createFlashcard(
        subDeckId: otherSubId,
        word: 'Breakfast',
        meaningId: 'sarapan',
      );

      final inserted = await db.flashcardDao.bulkUpsertFlashcards(
        subDeckId: subId1,
        items: const <FlashcardSeedInput>[
          // Matches existing 'wake up' -> fills blank fields without touching examplesJson/aiConversation.
          FlashcardSeedInput(
            word: 'Wake Up',
            phonetic: '/weɪk ʌp/',
            meaningId: 'bangun tidur',
            partsOfSpeech: ['phrasal verb'],
          ),
          // Brand new card.
          FlashcardSeedInput(
            word: 'schedule',
            phonetic: '/ˈskedʒ.uːl/',
            meaningId: 'jadwal / menjadwalkan',
            partsOfSpeech: ['noun', 'VERB'],
          ),
          // Internal duplicate within batch -> ignored.
          FlashcardSeedInput(
            word: '  SCHEDULE ',
            phonetic: '/other/',
            meaningId: 'duplicate',
            partsOfSpeech: ['Noun'],
          ),
          // Blank word -> ignored.
          FlashcardSeedInput(
            word: '   ',
            meaningId: 'empty',
          ),
        ],
      );

      expect(inserted, 1);

      final subCards = await db.flashcardDao.getCardsBySubDeck(subId1);
      expect(subCards, hasLength(2));

      final wakeCard = subCards.firstWhere((c) => c.word == 'wake up');
      expect(wakeCard.phonetic, '/weɪk ʌp/');
      expect(wakeCard.meaningId, 'bangun tidur');
      expect(wakeCard.wordType, 'verb');
      expect(
        FlashcardPosHelper.decodePartsOfSpeech(wakeCard.partsOfSpeechJson),
        const ['Phrasal Verb'],
      );
      expect(FlashcardExampleItem.decodeExamples(wakeCard.examplesJson), hasLength(1));
      expect(wakeCard.aiConversation, contains('When do you wake up?'));

      final scheduleCard = subCards.firstWhere((c) => c.word == 'schedule');
      expect(scheduleCard.examplesJson, '[]');
      expect(scheduleCard.verbTensesExamplesJson, '[]');
      expect(scheduleCard.aiConversation, '');
      expect(scheduleCard.wordType, 'verb');
      expect(
        FlashcardPosHelper.decodePartsOfSpeech(scheduleCard.partsOfSpeechJson),
        const ['Noun', 'Verb'],
      );

      final existingDeckWords =
          await db.flashcardDao.getExistingWordsInDeck(deckId1);
      expect(existingDeckWords, equals(<String>{'wake up', 'schedule', 'breakfast'}));
    });

    test('updateCardStudyStatus updates status, clamps 0..2, and aggregates completedCardCount/reviewCardCount/progressPercent on SubDeck & Deck stats', () async {
      final deckId = await db.flashcardDao.createDeck(name: 'Progress Deck');
      final emptyDeckId = await db.flashcardDao.createDeck(name: 'Empty Deck');
      final sub1Id = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Topic 1',
      );
      final sub2Id = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Topic 2',
      );

      final c1 = await db.flashcardDao.createFlashcard(
        subDeckId: sub1Id,
        word: 'alpha',
        meaningId: 'alfa',
      );
      final c2 = await db.flashcardDao.createFlashcard(
        subDeckId: sub1Id,
        word: 'beta',
        meaningId: 'beta',
      );
      final c3 = await db.flashcardDao.createFlashcard(
        subDeckId: sub1Id,
        word: 'gamma',
        meaningId: 'gama',
      );
      final c4 = await db.flashcardDao.createFlashcard(
        subDeckId: sub2Id,
        word: 'delta',
        meaningId: 'delta',
      );

      // Default studyStatus is 0 (unstudied) for all cards.
      final initialCards = await db.flashcardDao.getCardsByDeck(deckId);
      expect(
        initialCards.every((c) => c.studyStatus == FlashcardStudyStatus.unstudied),
        isTrue,
      );

      // Update cards: c1 -> Hafal (2), c2 -> Perlu Ulang (1), c3 -> Hafal (via clamped 99 -> 2), c4 -> stays 0.
      await db.flashcardDao.updateCardStudyStatus(
        cardId: c1,
        studyStatus: FlashcardStudyStatus.mastered,
      );
      await db.flashcardDao.updateCardStudyStatus(
        cardId: c2,
        studyStatus: FlashcardStudyStatus.needsReview,
      );
      await db.flashcardDao.updateCardStudyStatus(
        cardId: c3,
        studyStatus: 99,
      );
      // Verify negative values clamp safely to 0.
      await db.flashcardDao.updateCardStudyStatus(
        cardId: c4,
        studyStatus: -5,
      );

      final subStats = await db.flashcardDao.watchSubDecksWithStats(deckId).first;
      final s1 = subStats.firstWhere((s) => s.subDeck.id == sub1Id);
      final s2 = subStats.firstWhere((s) => s.subDeck.id == sub2Id);

      expect(s1.cardCount, 3);
      expect(s1.completedCardCount, 2);
      expect(s1.reviewCardCount, 1);
      expect(s1.progressRatio, closeTo(2 / 3, 0.0001));
      expect(s1.progressPercent, 67);

      expect(s2.cardCount, 1);
      expect(s2.completedCardCount, 0);
      expect(s2.reviewCardCount, 0);
      expect(s2.progressPercent, 0);

      final deckStats = await db.flashcardDao.watchDecksWithStats().first;
      final dMain = deckStats.firstWhere((d) => d.deck.id == deckId);
      final dEmpty = deckStats.firstWhere((d) => d.deck.id == emptyDeckId);

      expect(dMain.totalCardCount, 4);
      expect(dMain.completedCardCount, 2);
      expect(dMain.reviewCardCount, 1);
      expect(dMain.progressRatio, 0.5);
      expect(dMain.progressPercent, 50);

      expect(dEmpty.totalCardCount, 0);
      expect(dEmpty.completedCardCount, 0);
      expect(dEmpty.reviewCardCount, 0);
      expect(dEmpty.progressRatio, 0.0);
      expect(dEmpty.progressPercent, 0);

      // Export & import preserves studyStatus.
      final exported = await db.settingsDao.exportAllDataAsMap();
      final dbRestored = AppDatabase(NativeDatabase.memory());
      addTearDown(dbRestored.close);
      await dbRestored.settingsDao.importAllDataFromMap(exported);
      final restoredCards = await dbRestored.flashcardDao.getCardsBySubDeck(sub1Id);
      expect(
        restoredCards.firstWhere((c) => c.id == c1).studyStatus,
        FlashcardStudyStatus.mastered,
      );
      expect(
        restoredCards.firstWhere((c) => c.id == c2).studyStatus,
        FlashcardStudyStatus.needsReview,
      );
    });
  });

  group('TtsService & GeminiRestProvider Flashcard AI Tests', () {
    test('TtsService lifecycle does not crash when platform channel is unavailable', () async {
      final service = TtsService();
      service.onInit();
      await service.speak('pronounce');
      await service.stop();
      service.onClose();

      expect(service.isSpeaking.value, isFalse);
      expect(service.activeText.value, isEmpty);
    });

    test('GeminiRestProvider parses Flashcard practice content and quiz JSON cleanly', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.roadmapDao.watchAllLevelsWithLessons().first;

      final deckId = await db.flashcardDao.createDeck(name: 'AI Deck');
      final subId = await db.flashcardDao.createSubDeck(deckId: deckId, name: 'AI Sub');
      await db.flashcardDao.createFlashcard(
        subDeckId: subId,
        word: 'collaborate',
        meaningId: 'berkolaborasi',
        wordType: 'verb',
      );
      final cards = await db.flashcardDao.getCardsBySubDeck(subId);
      final targetCard = cards.single;

      final mockClient = MockClient((http.Request request) async {
        final bodyStr = request.body;
        if (bodyStr.contains('covering all 16 English tenses')) {
          final payload = jsonEncode(<String, dynamic>{
            'candidates': <Map<String, dynamic>>[
              <String, dynamic>{
                'content': <String, dynamic>{
                  'parts': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'text': jsonEncode(<String, dynamic>{
                        'wordType': 'verb',
                        'phonetic': '/kəˈlæbəreɪt/',
                        'meaningId': 'bekerja sama / berkolaborasi',
                        'examples': List<Map<String, String>>.generate(
                          16,
                          (i) => <String, String>{
                            'tense': 'Tense ${i + 1}',
                            'en': 'Sentence ${i + 1} with collaborate.',
                            'id': 'Kalimat ${i + 1} dengan berkolaborasi.',
                          },
                        ),
                        'conversation':
                            'A: Can we collaborate on this?\nB: Sure, let us collaborate today.',
                      }),
                    },
                  ],
                },
              },
            ],
          });
          return http.Response.bytes(
            utf8.encode(payload),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }

        final quizPayload = jsonEncode(<String, dynamic>{
          'candidates': <Map<String, dynamic>>[
            <String, dynamic>{
              'content': <String, dynamic>{
                'parts': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'text': jsonEncode(<String, dynamic>{
                      'questions': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'cardId': targetCard.id,
                          'word': targetCard.word,
                          'questionPrompt':
                              'Choose the best word: Two teams will ____ on the launch.',
                          'options': <String>[
                            'collaborate',
                            'hesitate',
                            'isolate',
                            'evaporate',
                          ],
                          'correctIndex': 0,
                          'explanationId':
                              "'collaborate' berarti bekerja sama.",
                        },
                      ],
                    }),
                  },
                ],
              },
            },
          ],
        });
        return http.Response.bytes(
          utf8.encode(quizPayload),
          200,
          headers: const <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      });

      final provider = GeminiRestProvider(httpClient: mockClient);

      final practice = await provider.generateFlashcardPracticeContent(
        apiKey: 'dummy-key',
        model: 'gemini-2.5-flash',
        word: 'collaborate',
        wordTypeHint: 'verb',
        includeAll16Tenses: true,
      );
      expect(practice.wordType, 'verb');
      expect(practice.phonetic, '/kəˈlæbəreɪt/');
      expect(practice.examples.length, 16);
      expect(practice.conversation, contains('collaborate'));

      final quiz = await provider.generateFlashcardQuiz(
        apiKey: 'dummy-key',
        model: 'gemini-2.5-flash',
        cards: cards,
        scopeTitle: 'AI Sub',
      );
      expect(quiz.length, 1);
      expect(quiz.single.cardId, targetCard.id);
      expect(quiz.single.options.length, 4);
      expect(quiz.single.correctIndex, 0);
      expect(quiz.single.explanationId, contains('bekerja sama'));
    });

    test('GeminiRestProvider parses unlimited partsOfSpeech, handles mode prompts, and includes POS in quiz prompt', () async {
      final capturedPrompts = <String>[];
      var callIndex = 0;

      final mockClient = MockClient((http.Request request) async {
        final decodedReq = jsonDecode(request.body) as Map<String, dynamic>;
        final promptText =
            decodedReq['contents'][0]['parts'][0]['text'] as String;
        capturedPrompts.add(promptText);
        callIndex += 1;

        if (callIndex == 1) {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': jsonEncode({
                            'partsOfSpeech': ['noun', 'verb', 'adjective', 'adverb'],
                            'wordType': 'non_verb', // overridden cleanly since 'verb' exists in POS list
                            'phonetic': '/faɪn/',
                            'meaningId': 'baik / denda / mendenda',
                            'examples': List<Map<String, String>>.generate(
                              5,
                              (i) => {
                                'pos': i == 0 ? 'noun' : (i == 1 ? 'adjective' : 'adverb'),
                                'tense': 'Daily Use',
                                'en': 'Multi POS sentence ${i + 1}.',
                                'id': 'Kalimat ${i + 1}.',
                              },
                            ),
                            'conversation': 'A: Everything is fine.\nB: Let us fine-tune the rest.',
                          }),
                        },
                      ],
                    },
                  },
                ],
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }

        if (callIndex == 2) {
          // Legacy response without partsOfSpeech falls back from wordType
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': jsonEncode({
                            'wordType': 'verb',
                            'phonetic': '/rʌn/',
                            'meaningId': 'berlari',
                            'examples': List<Map<String, String>>.generate(
                              5,
                              (i) => {
                                'tense': 'Simple Present',
                                'en': 'I run ${i + 1} km daily.',
                                'id': 'Saya berlari.',
                              },
                            ),
                            'conversation': 'A: Ready?\nB: Let us run!',
                          }),
                        },
                      ],
                    },
                  },
                ],
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }

        // Quiz response (3rd call)
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'questions': [
                            {
                              'cardId': 42,
                              'word': 'fine',
                              'questionPrompt': 'Choose the best usage of fine.',
                              'options': ['fine', 'poor', 'broken', 'late'],
                              'correctIndex': 0,
                              'explanationId': 'fine berarti baik atau denda.',
                            },
                          ],
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final provider = GeminiRestProvider(httpClient: mockClient);

      final multiRes = await provider.generateFlashcardPracticeContent(
        apiKey: 'dummy-key',
        model: 'gemini-3.8-flash',
        word: 'fine',
        knownPartsOfSpeech: const ['Noun', 'Verb', 'Adjective', 'Adverb'],
        mode: FlashcardExampleGenerationMode.nonVerbOnly,
        avoidSentences: const ['Avoid old fine sentence.'],
      );
      expect(multiRes.partsOfSpeech, ['Noun', 'Verb', 'Adjective', 'Adverb']);
      expect(multiRes.wordType, 'verb');
      expect(multiRes.examples[0].pos, 'Noun');
      expect(multiRes.examples[1].pos, 'Adjective');
      expect(multiRes.examples[2].pos, 'Adverb');
      expect(capturedPrompts[0], contains('Non-Verb POS examples ONLY'));
      expect(capturedPrompts[0], contains('Noun, Adjective, Adverb'));
      expect(capturedPrompts[0], contains('Avoid old fine sentence.'));

      final legacyRes = await provider.generateFlashcardPracticeContent(
        apiKey: 'dummy-key',
        model: 'gemini-3.8-flash',
        word: 'run',
        mode: FlashcardExampleGenerationMode.verb16TensesOnly,
      );
      expect(legacyRes.partsOfSpeech, ['Verb']);
      expect(legacyRes.wordType, 'verb');
      expect(capturedPrompts[1], contains('covering all 16 English tenses'));

      final multiPosCard = Flashcard(
        id: 42,
        subDeckId: 1,
        word: 'fine',
        phonetic: '/faɪn/',
        meaningId: 'baik / denda',
        wordType: 'verb',
        partsOfSpeechJson: '["Noun","Verb","Adjective","Adverb"]',
        examplesJson: '[]',
        verbTensesExamplesJson: '[]',
        aiConversation: '',
        masteryLevel: 0,
        studyStatus: 0,
        reviewCount: 0,
        lastReviewedAt: null,
        createdAt: DateTime(2026, 11, 14),
      );
      final quiz = await provider.generateFlashcardQuiz(
        apiKey: 'dummy-key',
        model: 'gemini-3.8-flash',
        cards: [multiPosCard],
        scopeTitle: 'Multi POS Quiz',
      );
      expect(quiz, hasLength(1));
      expect(
        capturedPrompts[2],
        contains('partsOfSpeech: Noun, Verb, Adjective, Adverb'),
      );
    });

    test('GeminiRestProvider.generateDailyVocabBatch parses multi-POS batch, normalizes POS & filters avoidWords', () async {
      late String capturedPrompt;
      final provider = GeminiRestProvider(
        httpClient: MockClient((http.Request request) async {
          final bodyMap = jsonDecode(request.body) as Map<String, dynamic>;
          capturedPrompt =
              bodyMap['contents'][0]['parts'][0]['text'] as String;
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'items': [
                            {
                              'word': 'alreadyInDeck',
                              'phonetic': '/.../ ',
                              'meaningId': 'sudah ada',
                              'partsOfSpeech': ['Noun'],
                            },
                            {
                              'word': 'commute',
                              'phonetic': '/kəˈmjuːt/',
                              'meaningId': 'pulang-pergi kerja',
                              'partsOfSpeech': ['verb', ' NOUN '],
                            },
                            {
                              'word': 'COMMUTE',
                              'phonetic': '/dup/',
                              'meaningId': 'duplikat internal',
                              'partsOfSpeech': ['Noun'],
                            },
                            {
                              'word': 'put off',
                              'phonetic': '/pʊt ɔːf/',
                              'meaningId': 'menunda',
                              'partsOfSpeech': ['phrasal verb'],
                            },
                          ],
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      final items = await provider.generateDailyVocabBatch(
        apiKey: 'dummy-key',
        model: 'gemini-3.8-flash',
        cefrLevel: 'A2',
        topicName: 'Daily Routines & Actions',
        count: 50,
        avoidWords: const <String>['AlreadyInDeck'],
      );

      expect(capturedPrompt, contains('CEFR Level: A2'));
      expect(capturedPrompt, contains('Daily Routines & Actions'));
      expect(capturedPrompt, contains('Do NOT generate example sentences, tense tables, or dialogs'));
      expect(capturedPrompt, contains('AlreadyInDeck'));

      expect(items, hasLength(2));
      expect(items[0].word, 'commute');
      expect(items[0].phonetic, '/kəˈmjuːt/');
      expect(items[0].meaningId, 'pulang-pergi kerja');
      expect(items[0].partsOfSpeech, const ['Verb', 'Noun']);
      expect(items[1].word, 'put off');
      expect(items[1].partsOfSpeech, const ['Phrasal Verb']);
    });

    test('GeminiRestProvider.generateDailyVocabBatch salvages truncated JSON, caps avoidWords at 300 with maxOutputTokens=4096, and returns [] when all valid items are avoided', () async {
      var callIndex = 0;
      late Map<String, dynamic> capturedConfig;
      late String capturedPrompt;

      final provider = GeminiRestProvider(
        httpClient: MockClient((http.Request request) async {
          callIndex += 1;
          final bodyMap = jsonDecode(request.body) as Map<String, dynamic>;
          capturedConfig =
              Map<String, dynamic>.from(bodyMap['generationConfig'] as Map);
          capturedPrompt =
              bodyMap['contents'][0]['parts'][0]['text'] as String;

          late String modelText;
          if (callIndex == 1) {
            // Truncated mid-3rd item with prose prefix and braces inside string value.
            modelText =
                'Here is the JSON:\n{"items":[{"word":"commute","phonetic":"/kəˈmjuːt/","meaningId":"perjalanan kerja","partsOfSpeech":["Verb","Noun"]},{"word":"errand","phonetic":"/ˈer.ənd/","meaningId":"urusan {singkat}","partsOfSpeech":["Noun"]},{"word":"groceries","phonetic":"/ˈɡrəʊ';
          } else if (callIndex == 2) {
            // Valid items, but every word is already present in avoidWords.
            modelText = jsonEncode(<String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'word': 'alreadyOne',
                  'phonetic': '/1/',
                  'meaningId': 'satu',
                  'partsOfSpeech': <String>['Noun'],
                },
                <String, dynamic>{
                  'word': 'alreadyTwo',
                  'phonetic': '/2/',
                  'meaningId': 'dua',
                  'partsOfSpeech': <String>['Verb'],
                },
              ],
            });
          } else {
            // Completely unusable non-item text -> should throw Format -> GeminiApiException.
            modelText = 'Sorry, I cannot comply with that request right now.';
          }

          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': modelText},
                    ],
                  },
                },
              ],
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      final avoid350 = List<String>.generate(350, (i) => 'old_word_$i');
      final salvaged = await provider.generateDailyVocabBatch(
        apiKey: 'dummy-key',
        model: 'gemini-2.5-flash',
        cefrLevel: 'A1',
        topicName: 'Daily Routines & Actions',
        count: 25,
        avoidWords: avoid350,
      );

      expect(capturedConfig['maxOutputTokens'], 4096);
      expect(capturedConfig['temperature'], 0.35);
      expect(capturedConfig['responseMimeType'], 'application/json');
      // Keeps the latest 300 avoidWords (indices 50..349), omitting index 0..49.
      expect(capturedPrompt, contains('"old_word_50"'));
      expect(capturedPrompt, contains('"old_word_349"'));
      expect(capturedPrompt, isNot(contains('"old_word_0"')));

      expect(salvaged, hasLength(2));
      expect(salvaged[0].word, 'commute');
      expect(salvaged[1].word, 'errand');
      expect(salvaged[1].meaningId, 'urusan {singkat}');

      final allAvoided = await provider.generateDailyVocabBatch(
        apiKey: 'dummy-key',
        model: 'gemini-2.5-flash',
        cefrLevel: 'A1',
        topicName: 'Daily Routines & Actions',
        count: 25,
        avoidWords: const <String>['alreadyone', 'ALREADYTWO'],
      );
      expect(allAvoided, isEmpty);

      await expectLater(
        () => provider.generateDailyVocabBatch(
          apiKey: 'dummy-key',
          model: 'gemini-2.5-flash',
          cefrLevel: 'A1',
          topicName: 'Daily Routines & Actions',
          count: 25,
        ),
        throwsA(isA<GeminiApiException>()),
      );
    });
  });
}
