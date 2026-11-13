@Timeout(Duration(seconds: 25))
library;

import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Value;

import 'package:my_english_tutor/app/core/theme/app_theme.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/local/daos/flashcard_dao.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/repositories/tutor_repository.dart';
import 'package:my_english_tutor/app/data/services/audio_service.dart';
import 'package:my_english_tutor/app/data/services/tts_service.dart';
import 'package:my_english_tutor/app/modules/flashcards/controllers/flashcard_quiz_controller.dart';
import 'package:my_english_tutor/app/modules/flashcards/controllers/flashcard_subdecks_controller.dart';
import 'package:my_english_tutor/app/modules/flashcards/controllers/flashcards_controller.dart';
import 'package:my_english_tutor/app/modules/flashcards/models/flashcard_nav_args.dart';
import 'package:my_english_tutor/app/modules/home/bindings/home_binding.dart';
import 'package:my_english_tutor/app/routes/app_pages.dart';

class _FakeQuizGeminiProvider extends GeminiRestProvider {
  bool shouldThrowQuotaError = false;
  int callCount = 0;
  List<int> lastReceivedCardIds = const <int>[];
  String? lastReceivedScopeTitle;

  @override
  Future<List<FlashcardQuizQuestion>> generateFlashcardQuiz({
    required String apiKey,
    required String model,
    required List<Flashcard> cards,
    required String scopeTitle,
    int maxQuestions = 15,
  }) async {
    callCount += 1;
    lastReceivedScopeTitle = scopeTitle;
    lastReceivedCardIds = cards.map((c) => c.id).toList(growable: false);

    if (shouldThrowQuotaError) {
      throw const GeminiApiException('Quota exceeded', statusCode: 429);
    }

    return cards.take(maxQuestions).map((card) {
      final word = card.word;
      return FlashcardQuizQuestion(
        cardId: card.id,
        word: word,
        questionPrompt: 'AI Quiz: Choose the meaning of "$word".',
        options: <String>[
          'Arti dari $word',
          'Pilihan salah 1 ($word)',
          'Pilihan salah 2 ($word)',
          'Pilihan salah 3 ($word)',
        ],
        correctIndex: 0,
        explanationId: 'Arti kata "$word" adalah "${card.meaningId}".',
      );
    }).toList(growable: false);
  }
}

class _FakeTtsService extends TtsService {
  final List<String> spokenTexts = <String>[];
  int stopCount = 0;

  @override
  Future<void> speak(
    String text, {
    String language = 'en-US',
    double rate = 0.48,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    spokenTexts.add(trimmed);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }
}

void main() {
  late AppDatabase db;
  late TutorRepository repository;
  late _FakeQuizGeminiProvider fakeGemini;
  late _FakeTtsService fakeTts;

  setUp(() async {
    Get.testMode = true;
    db = AppDatabase(NativeDatabase.memory());
    await db.roadmapDao.watchAllLevelsWithLessons().first;
    await db.settingsDao.updateSettings(
      const AppSettingsCompanion(apiKey: Value('test-api-key')),
    );

    fakeGemini = _FakeQuizGeminiProvider();
    fakeTts = _FakeTtsService();

    Get.put<AppDatabase>(db, permanent: true);
    Get.put<AudioService>(AudioService(), permanent: true);
    Get.put<TtsService>(fakeTts, permanent: true);
    Get.put<GeminiRestProvider>(fakeGemini, permanent: true);
    repository = Get.put<TutorRepository>(
      TutorRepository(database: db, restProvider: fakeGemini),
      permanent: true,
    );

    HomeBinding().dependencies();
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<void> waitUntilLoaded(FlashcardQuizController controller) async {
    var guard = 0;
    while (controller.isLoading.value && guard < 100) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      guard += 1;
    }
  }

  Future<void> pumpRoutedApp(
    WidgetTester tester, {
    required String initialRoute,
  }) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        title: 'My English Tutor',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: initialRoute,
        getPages: AppPages.routes,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Flashcard Quiz Scope & Controller', () {
    test(
      'FlashcardQuizController AI flow tracks score, history, and updates Drift masteryLevel',
      () async {
        final deckId = await db.flashcardDao.createDeck(name: 'Negotiation');
        final subDeckId = await db.flashcardDao.createSubDeck(
          deckId: deckId,
          name: 'Key Terms',
        );

        final card1Id = await db.flashcardDao.createFlashcard(
          subDeckId: subDeckId,
          word: 'negotiate',
          meaningId: 'bernegosiasi',
        );
        final card2Id = await db.flashcardDao.createFlashcard(
          subDeckId: subDeckId,
          word: 'deadline',
          meaningId: 'tenggat waktu',
        );

        final cards = await db.flashcardDao.getCardsBySubDeck(subDeckId);
        final controller = FlashcardQuizController(
          repository: repository,
          ttsService: fakeTts,
          initialArgs: FlashcardQuizArgs(
            scopeTitle: 'Key Terms',
            scopeSubtitle: 'Sub-Deck • Negotiation',
            cards: cards,
            deckId: deckId,
            subDeckId: subDeckId,
          ),
          random: Random(42),
        );

        controller.onInit();
        await waitUntilLoaded(controller);

        expect(controller.isLoading.value, isFalse);
        expect(controller.isFallbackOfflineMode.value, isFalse);
        expect(controller.errorMessage.value, isEmpty);
        expect(controller.questions.length, 2);
        expect(fakeGemini.callCount, 1);

        // Answer Q1 correctly (index 0 in fake provider).
        await controller.selectOption(0);
        expect(controller.isCurrentAnswered.value, isTrue);
        expect(controller.correctCount.value, 1);
        expect(controller.answerHistory.length, 1);
        expect(controller.isCompleted.value, isFalse);

        controller.nextQuestion();
        expect(controller.currentIndex.value, 1);
        expect(controller.isCurrentAnswered.value, isFalse);

        // Answer Q2 incorrectly (index 1).
        await controller.selectOption(1);
        expect(controller.correctCount.value, 1);
        expect(controller.answerHistory.length, 2);
        expect(controller.isLastQuestion, isTrue);

        controller.nextQuestion();
        expect(controller.isCompleted.value, isTrue);
        expect(controller.accuracyPercent, 50.0);

        final updatedCards = await db.flashcardDao.getCardsBySubDeck(subDeckId);
        final updatedCard1 = updatedCards.firstWhere((c) => c.id == card1Id);
        final updatedCard2 = updatedCards.firstWhere((c) => c.id == card2Id);

        expect(updatedCard1.reviewCount, 1);
        expect(updatedCard1.masteryLevel, 1);
        expect(updatedCard2.reviewCount, 1);
        expect(updatedCard2.masteryLevel, 0);

        controller.onClose();
      },
    );

    test(
      'FlashcardQuizController falls back to local quiz on API quota/offline error',
      () async {
        fakeGemini.shouldThrowQuotaError = true;

        final deckId = await db.flashcardDao.createDeck(name: 'Offline Deck');
        final subDeckId = await db.flashcardDao.createSubDeck(
          deckId: deckId,
          name: 'Daily Work',
        );

        await db.flashcardDao.createFlashcard(
          subDeckId: subDeckId,
          word: 'collaborate',
          meaningId: 'berkolaborasi',
          examples: const <FlashcardExampleItem>[
            FlashcardExampleItem(
              tense: 'Present Simple',
              en: 'Our teams collaborate every Friday.',
              id: 'Tim kami berkolaborasi setiap hari Jumat.',
            ),
          ],
        );
        await db.flashcardDao.createFlashcard(
          subDeckId: subDeckId,
          word: 'budget',
          meaningId: 'anggaran',
        );
        await db.flashcardDao.createFlashcard(
          subDeckId: subDeckId,
          word: 'contract',
          meaningId: 'kontrak',
        );

        final cards = await db.flashcardDao.getCardsBySubDeck(subDeckId);
        final controller = FlashcardQuizController(
          repository: repository,
          ttsService: fakeTts,
          initialArgs: FlashcardQuizArgs(
            scopeTitle: 'Daily Work',
            scopeSubtitle: 'Sub-Deck • Offline Deck',
            cards: cards,
            deckId: deckId,
            subDeckId: subDeckId,
          ),
          random: Random(7),
        );

        controller.onInit();
        await waitUntilLoaded(controller);

        expect(controller.isLoading.value, isFalse);
        expect(controller.isFallbackOfflineMode.value, isTrue);
        expect(controller.infoBanner.value, contains('Mode Kuis Lokal:'));
        expect(controller.questions.length, 3);

        for (final q in controller.questions) {
          expect(q.options.length, 4);
          expect(q.options.toSet().length, 4);
          expect(q.correctIndex, inInclusiveRange(0, 3));
        }

        final clozeQuestion = controller.questions.firstWhere(
          (q) => q.word == 'collaborate',
        );
        expect(clozeQuestion.questionPrompt, contains('____'));

        for (var i = 0; i < controller.questions.length; i++) {
          final currentQ = controller.currentQuestion!;
          await controller.selectOption(currentQ.correctIndex);
          controller.nextQuestion();
        }

        expect(controller.isCompleted.value, isTrue);
        expect(controller.correctCount.value, 3);

        final updatedCards = await db.flashcardDao.getCardsBySubDeck(subDeckId);
        for (final card in updatedCards) {
          expect(card.reviewCount, 1);
          expect(card.masteryLevel, 1);
        }

        controller.onClose();
      },
    );
  });

  group('Flashcard Quiz Navigation & 360dp UI', () {
    testWidgets(
      'FlashcardsController.startDeckQuiz merges all Sub-Deck cards inside the Deck',
      (tester) async {
        late FlashcardDeck businessDeck;

        await tester.runAsync(() async {
          final businessDeckId = await db.flashcardDao.createDeck(
            name: 'Business',
          );
          final subAId = await db.flashcardDao.createSubDeck(
            deckId: businessDeckId,
            name: 'Meetings',
          );
          final subBId = await db.flashcardDao.createSubDeck(
            deckId: businessDeckId,
            name: 'Contracts',
          );
          await db.flashcardDao.createFlashcard(
            subDeckId: subAId,
            word: 'agenda',
            meaningId: 'agenda rapat',
          );
          await db.flashcardDao.createFlashcard(
            subDeckId: subAId,
            word: 'minutes',
            meaningId: 'notulensi',
          );
          await db.flashcardDao.createFlashcard(
            subDeckId: subBId,
            word: 'clause',
            meaningId: 'klausul',
          );

          final otherDeckId = await db.flashcardDao.createDeck(name: 'Travel');
          final otherSubId = await db.flashcardDao.createSubDeck(
            deckId: otherDeckId,
            name: 'Airport',
          );
          await db.flashcardDao.createFlashcard(
            subDeckId: otherSubId,
            word: 'itinerary',
            meaningId: 'rencana perjalanan',
          );

          final decks = await db.flashcardDao.getDecksWithStats();
          businessDeck = decks
              .firstWhere((item) => item.deck.id == businessDeckId)
              .deck;
        });

        await pumpRoutedApp(tester, initialRoute: Routes.HOME);

        final flashcardsController = Get.find<FlashcardsController>();
        await tester.runAsync(
          () => flashcardsController.startDeckQuiz(businessDeck),
        );
        await tester.pumpAndSettle();

        expect(Get.currentRoute, Routes.FLASHCARD_QUIZ);
        final quizController = Get.find<FlashcardQuizController>();
        expect(quizController.args?.scopeTitle, 'Business');
        expect(
          quizController.args?.cards.map((c) => c.word).toSet(),
          equals(<String>{'agenda', 'minutes', 'clause'}),
        );

        expect(find.text('Tes: Business'), findsOneWidget);
        expect(find.text('Semua Sub-Deck di Deck ini'), findsOneWidget);
        expect(find.text('Soal 1 / 3'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'FlashcardSubDecksController.startSubDeckQuiz tests only cards in the selected Sub-Deck',
      (tester) async {
        late FlashcardDeck businessDeck;
        late FlashcardSubDeck meetingsSubDeck;

        await tester.runAsync(() async {
          final businessDeckId = await db.flashcardDao.createDeck(
            name: 'Business',
          );
          final meetingsId = await db.flashcardDao.createSubDeck(
            deckId: businessDeckId,
            name: 'Meetings',
          );
          final contractsId = await db.flashcardDao.createSubDeck(
            deckId: businessDeckId,
            name: 'Contracts',
          );

          await db.flashcardDao.createFlashcard(
            subDeckId: meetingsId,
            word: 'agenda',
            meaningId: 'agenda rapat',
          );
          await db.flashcardDao.createFlashcard(
            subDeckId: meetingsId,
            word: 'minutes',
            meaningId: 'notulensi',
          );
          await db.flashcardDao.createFlashcard(
            subDeckId: contractsId,
            word: 'clause',
            meaningId: 'klausul',
          );

          final decks = await db.flashcardDao.getDecksWithStats();
          businessDeck = decks
              .firstWhere((item) => item.deck.id == businessDeckId)
              .deck;
          final subDecks = await db.flashcardDao.getSubDecksByDeck(
            businessDeckId,
          );
          meetingsSubDeck = subDecks.firstWhere((s) => s.id == meetingsId);
        });

        await pumpRoutedApp(tester, initialRoute: Routes.HOME);

        unawaited(
          Get.toNamed<void>(
            Routes.FLASHCARD_SUBDECKS,
            arguments: FlashcardSubDecksArgs(deck: businessDeck),
          ),
        );
        await tester.pumpAndSettle();

        final subDecksController = Get.find<FlashcardSubDecksController>();
        await tester.runAsync(
          () => subDecksController.startSubDeckQuiz(meetingsSubDeck),
        );
        await tester.pumpAndSettle();

        expect(Get.currentRoute, Routes.FLASHCARD_QUIZ);
        final quizController = Get.find<FlashcardQuizController>();
        expect(quizController.args?.scopeTitle, 'Meetings');
        expect(quizController.args?.subDeckId, meetingsSubDeck.id);
        expect(
          quizController.args?.cards.map((c) => c.word).toSet(),
          equals(<String>{'agenda', 'minutes'}),
        );

        expect(find.text('Tes: Meetings'), findsOneWidget);
        expect(find.text('Sub-Deck • Business'), findsOneWidget);
        expect(find.text('Soal 1 / 2'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'FlashcardQuizView renders quiz, TTS button, feedback, and summary without 360dp overflow',
      (tester) async {
        final capturedErrors = <FlutterErrorDetails>[];
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          capturedErrors.add(details);
          originalOnError?.call(details);
        };
        addTearDown(() {
          FlutterError.onError = originalOnError;
        });

        late FlashcardQuizArgs quizArgs;
        await tester.runAsync(() async {
          final deckId = await db.flashcardDao.createDeck(name: 'Negotiation');
          final subDeckId = await db.flashcardDao.createSubDeck(
            deckId: deckId,
            name: 'Phrases',
          );
          await db.flashcardDao.createFlashcard(
            subDeckId: subDeckId,
            word: 'negotiate',
            meaningId: 'bernegosiasi',
          );
          await db.flashcardDao.createFlashcard(
            subDeckId: subDeckId,
            word: 'compromise',
            meaningId: 'berkompromi',
          );
          final cards = await db.flashcardDao.getCardsBySubDeck(subDeckId);
          quizArgs = FlashcardQuizArgs(
            scopeTitle: 'Negotiation',
            scopeSubtitle: 'Semua Sub-Deck di Deck ini',
            cards: cards,
            deckId: deckId,
            subDeckId: subDeckId,
          );
        });

        await pumpRoutedApp(tester, initialRoute: Routes.HOME);

        unawaited(
          Get.toNamed<void>(
            Routes.FLASHCARD_QUIZ,
            arguments: quizArgs,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tes: Negotiation'), findsOneWidget);
        expect(find.text('Soal 1 / 2'), findsOneWidget);
        expect(find.text('Benar: 0'), findsOneWidget);
        expect(find.text('Dengar Kata'), findsOneWidget);
        expect(
          find.text('AI Quiz: Choose the meaning of "negotiate".'),
          findsOneWidget,
        );

        // Tap TTS button for active question word.
        await tester.tap(find.text('Dengar Kata'));
        await tester.pump();
        expect(fakeTts.spokenTexts, contains('negotiate'));

        // Answer Q1 correctly (option A).
        await tester.tap(find.text('Arti dari negotiate'));
        await tester.pumpAndSettle();

        expect(find.text('Benar: 1'), findsOneWidget);
        expect(find.text('Benar! Penjelasan:'), findsOneWidget);
        expect(find.text('Soal Berikutnya'), findsOneWidget);

        // Proceed to Q2.
        await tester.ensureVisible(find.text('Soal Berikutnya'));
        await tester.tap(find.text('Soal Berikutnya'));
        await tester.pumpAndSettle();

        expect(find.text('Soal 2 / 2'), findsOneWidget);

        // Answer Q2 incorrectly (wrong option).
        await tester.tap(find.text('Pilihan salah 1 (compromise)'));
        await tester.pumpAndSettle();

        expect(find.text('Kurang Tepat • Penjelasan:'), findsOneWidget);
        expect(find.text('Lihat Hasil Tes'), findsOneWidget);

        // Open result summary screen.
        await tester.ensureVisible(find.text('Lihat Hasil Tes'));
        await tester.tap(find.text('Lihat Hasil Tes'));
        await tester.pumpAndSettle();

        expect(find.text('50%'), findsOneWidget);
        expect(find.text('Benar 1 dari 2 soal'), findsOneWidget);
        expect(
          find.text('Mastery level setiap kartu telah diperbarui.'),
          findsOneWidget,
        );
        expect(find.text('Review Jawaban'), findsOneWidget);
        expect(find.text('Tes Ulang (Soal Baru)'), findsOneWidget);
        expect(find.text('Selesai'), findsOneWidget);

        // Retake quiz resets back to Q1.
        await tester.ensureVisible(find.text('Tes Ulang (Soal Baru)'));
        await tester.tap(find.text('Tes Ulang (Soal Baru)'));
        await tester.pumpAndSettle();
        expect(find.text('Soal 1 / 2'), findsOneWidget);

        final overflowErrors = capturedErrors
            .where((e) => e.exceptionAsString().contains('RenderFlex overflowed'))
            .toList();
        expect(overflowErrors, isEmpty);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );
  });
}
