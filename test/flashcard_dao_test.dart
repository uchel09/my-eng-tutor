import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/local/daos/flashcard_dao.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/services/tts_service.dart';

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
  });
}
