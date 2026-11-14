import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_english_tutor/app/core/theme/app_theme.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/local/daos/flashcard_dao.dart';
import 'package:my_english_tutor/app/data/models/transcript_turn_model.dart';
import 'package:my_english_tutor/app/data/providers/gemini_live_provider.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/repositories/tutor_repository.dart';
import 'package:my_english_tutor/app/data/services/audio_service.dart';
import 'package:my_english_tutor/app/data/services/tts_service.dart';
import 'package:my_english_tutor/app/modules/flashcards/controllers/flashcard_study_controller.dart';
import 'package:my_english_tutor/app/modules/flashcards/controllers/flashcard_subdecks_controller.dart';
import 'package:my_english_tutor/app/modules/flashcards/models/flashcard_nav_args.dart';
import 'package:my_english_tutor/app/modules/flashcards/views/flashcard_study_view.dart';
import 'package:my_english_tutor/app/modules/flashcards/views/flashcard_subdecks_view.dart';
import 'package:my_english_tutor/app/modules/flashcards/widgets/flashcard_freetalk_sheet.dart';
import 'package:my_english_tutor/app/modules/home/bindings/home_binding.dart';
import 'package:my_english_tutor/app/modules/home/views/home_view.dart';
import 'package:my_english_tutor/app/modules/practice/controllers/practice_controller.dart';
import 'package:my_english_tutor/app/modules/practice/views/practice_view.dart';
import 'package:my_english_tutor/app/routes/app_pages.dart';

Flashcard _makeCard({
  required int id,
  required String word,
  int studyStatus = FlashcardStudyStatus.unstudied,
  String meaningId = 'arti',
}) {
  return Flashcard(
    id: id,
    subDeckId: 1,
    word: word,
    phonetic: '',
    meaningId: meaningId,
    wordType: 'non_verb',
    examplesJson: '[]',
    partsOfSpeechJson: '["Noun"]',
    verbTensesExamplesJson: '[]',
    aiConversation: '',
    studyStatus: studyStatus,
    masteryLevel: 0,
    reviewCount: 0,
    lastReviewedAt: null,
    createdAt: DateTime(2026, 11, 14),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Free Talk Vocabulary Helper & PracticeController Unit Tests', () {
    test('selectAutoFreeTalkVocabulary prioritizes needsReview & unstudied over mastered and enforces hard cap of 10 unique words', () {
      final cards = <Flashcard>[
        for (var i = 1; i <= 5; i++)
          _makeCard(
            id: i,
            word: 'mastered_$i',
            studyStatus: FlashcardStudyStatus.mastered,
          ),
        for (var i = 1; i <= 6; i++)
          _makeCard(
            id: 10 + i,
            word: 'unstudied_$i',
            studyStatus: FlashcardStudyStatus.unstudied,
          ),
        for (var i = 1; i <= 4; i++)
          _makeCard(
            id: 20 + i,
            word: 'review_$i',
            studyStatus: FlashcardStudyStatus.needsReview,
          ),
        // Case-insensitive duplicate & blank word
        _makeCard(
          id: 99,
          word: 'REVIEW_1',
          studyStatus: FlashcardStudyStatus.needsReview,
        ),
        _makeCard(id: 100, word: '   ', studyStatus: FlashcardStudyStatus.unstudied),
      ];

      final picked = selectAutoFreeTalkVocabulary(
        cards,
        maxWords: 20, // Exceeds 10 -> hard-capped to 10
        random: math.Random(42),
      );

      expect(picked, hasLength(10));
      expect(
        picked.where((c) => c.studyStatus == FlashcardStudyStatus.needsReview),
        hasLength(4),
      );
      expect(
        picked.where((c) => c.studyStatus == FlashcardStudyStatus.unstudied),
        hasLength(6),
      );
      expect(
        picked.where((c) => c.studyStatus == FlashcardStudyStatus.mastered),
        isEmpty,
      );
      expect(
        picked.map((c) => c.word.toLowerCase()).toSet(),
        hasLength(10),
      );
    });

    test('selectAutoFreeTalkVocabulary fills remaining quota with mastered cards when unmastered < 10', () {
      final cards = <Flashcard>[
        _makeCard(id: 1, word: 'review_only', studyStatus: FlashcardStudyStatus.needsReview),
        _makeCard(id: 2, word: 'new_only', studyStatus: FlashcardStudyStatus.unstudied),
        _makeCard(id: 3, word: 'done_1', studyStatus: FlashcardStudyStatus.mastered),
        _makeCard(id: 4, word: 'done_2', studyStatus: FlashcardStudyStatus.mastered),
      ];

      final picked = selectAutoFreeTalkVocabulary(cards, random: math.Random(7));
      expect(picked, hasLength(4));
      expect(picked.first.word, 'review_only');
      expect(picked[1].word, 'new_only');
    });

    test('buildSubDeckFreeTalkPracticeArgs extracts CEFR hint and preserves optional topic & targetVocabulary', () {
      final args = buildSubDeckFreeTalkPracticeArgs(
        const FlashcardSubDeckFreeTalkSelection(
          targetVocabulary: <String>['negotiate', 'budget', 'NEGOTIATE'],
          subDeckTitle: 'Office & Meetings',
          deckTitle: 'Kosakata Harian - B1',
          optionalTopic: 'Client meeting',
        ),
      );

      expect(args.sessionType, 'free_talk');
      expect(args.mode, 'live_roleplay');
      expect(args.targetCefrLevel, 'B1');
      expect(args.hasTargetVocabulary, isTrue);
      expect(args.targetVocabulary, const <String>['negotiate', 'budget']);
      expect(args.vocabSubDeckTitle, 'Office & Meetings');
      expect(args.customTopic, 'Client meeting');
      expect(args.title, 'Free Talk: Client meeting (Office & Meetings)');
    });

    test('PracticeController includes targetVocabulary in systemInstruction and detects whole-word user turns accurately', () async {
      Get.testMode = true;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        Get.reset();
        await db.close();
      });

      final controller = PracticeController(
        liveProvider: GeminiLiveProvider(),
        audioService: AudioService(),
        repository: TutorRepository(
          database: db,
          restProvider: GeminiRestProvider(),
        ),
      );
      addTearDown(controller.onClose);

      final practiceArgs = buildSubDeckFreeTalkPracticeArgs(
        const FlashcardSubDeckFreeTalkSelection(
          targetVocabulary: <String>['run', 'budget', 'coffee shop'],
          subDeckTitle: 'Daily Routine',
          cefrHint: 'B1',
          optionalTopic: 'Morning chat',
        ),
      );
      controller.setArgsForTest(practiceArgs);

      final settings = await db.settingsDao.getSettings();
      final instruction = controller.buildSystemInstructionForTest(
        practiceArgs,
        settings,
      );

      expect(instruction, contains('Sub-Deck: Daily Routine'));
      expect(instruction, contains('run, budget, coffee shop'));
      expect(instruction, contains('1–2 target words per turn'));
      expect(instruction, contains('Morning chat'));

      // Tutor mention must NOT count as user practice; 'running' must NOT match 'run'.
      controller.appendTranscriptTurnForTest(
        TranscriptTurnModel(
          role: 'tutor',
          text: 'Try using run, budget, and coffee shop!',
          timestamp: DateTime(2026, 11, 14, 10, 0),
        ),
      );
      controller.appendTranscriptTurnForTest(
        TranscriptTurnModel(
          role: 'user',
          text: 'I was running late and checked my BUDGET at the coffee shop.',
          timestamp: DateTime(2026, 11, 14, 10, 0, 5),
        ),
      );

      expect(controller.isTargetWordPracticed('budget'), isTrue);
      expect(controller.isTargetWordPracticed('coffee shop'), isTrue);
      expect(controller.isTargetWordPracticed('run'), isFalse);
      expect(controller.practicedTargetWordsCount, 2);

      controller.appendTranscriptTurnForTest(
        TranscriptTurnModel(
          role: 'user',
          text: 'Usually I run in the park.',
          timestamp: DateTime(2026, 11, 14, 10, 0, 12),
        ),
      );
      expect(controller.isTargetWordPracticed('run'), isTrue);
      expect(controller.practicedTargetWordsCount, 3);
    });
  });

  group('Free Talk Vocabulary UI Widget Tests (360x760)', () {
    testWidgets('Home Free Talk dialog switches between Talk Bebas & Kosakata Sub-Deck and enforces max 10 manual selection at 360dp', (WidgetTester tester) async {
      final errors = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      await tester.binding.setSurfaceSize(const Size(360, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Get.testMode = true;
      final db = AppDatabase(NativeDatabase.memory());
      await tester.runAsync(() async {
        await db.roadmapDao.watchAllLevelsWithLessons().first;
        final deckId = await db.flashcardDao.createDeck(name: 'Kosakata A2');
        final subDeckId = await db.flashcardDao.createSubDeck(
          deckId: deckId,
          name: 'Cafe & Dining',
        );
        for (var i = 1; i <= 12; i++) {
          final cardId = await db.flashcardDao.createFlashcard(
            subDeckId: subDeckId,
            word: 'cafe_word_$i',
            meaningId: 'arti_$i',
          );
          if (i <= 2) {
            await db.flashcardDao.updateCardStudyStatus(
              cardId: cardId,
              studyStatus: FlashcardStudyStatus.needsReview,
            );
          }
        }
      });

      Get.reset();
      Get.put<AppDatabase>(db, permanent: true);
      Get.put<AudioService>(AudioService(), permanent: true);
      Get.put<TtsService>(TtsService(), permanent: true);
      Get.lazyPut<GeminiRestProvider>(() => GeminiRestProvider(), fenix: true);
      Get.lazyPut<TutorRepository>(
        () => TutorRepository(
          database: Get.find<AppDatabase>(),
          restProvider: Get.find<GeminiRestProvider>(),
        ),
        fenix: true,
      );
      HomeBinding().dependencies();

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Free Talk Bebas'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Free Talk Bebas'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Topik Free Talk'), findsOneWidget);
      expect(find.text('Talk Bebas'), findsOneWidget);
      expect(find.text('Kosakata Sub-Deck'), findsOneWidget);

      // Switch to Kosakata Sub-Deck mode
      await tester.tap(find.text('Kosakata Sub-Deck'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();

      expect(find.text('Otomatis (Maks. 10)'), findsOneWidget);
      expect(find.text('Pilih Manual (1–10)'), findsOneWidget);
      expect(find.text('Acak Ulang'), findsOneWidget);

      // Switch to Pilih Manual (1–10)
      await tester.tap(find.text('Pilih Manual (1–10)'));
      await tester.pumpAndSettle();

      // Starts at 0 / 10 with all checkboxes enabled, "Isi 10 Acak" quick action, and submit disabled.
      expect(find.text('Terpilih: 0 / 10 kata'), findsOneWidget);
      expect(find.text('Isi 10 Acak'), findsOneWidget);
      expect(
        tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .every((cb) => cb.value == false && cb.onChanged != null),
        isTrue,
      );
      final submitBtnBefore = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Mulai Free Talk'),
      );
      expect(submitBtnBefore.onPressed, isNull);

      // Manually check words one by one from 0 -> 2 and verify submit becomes enabled.
      for (var step = 1; step <= 2; step++) {
        final nextUnchecked = find
            .byWidgetPredicate((w) => w is Checkbox && w.value == false)
            .first;
        await tester.ensureVisible(nextUnchecked);
        await tester.pumpAndSettle();
        await tester.tap(nextUnchecked);
        await tester.pumpAndSettle();
        expect(find.text('Terpilih: $step / 10 kata'), findsOneWidget);
      }
      expect(find.text('Kosongkan'), findsOneWidget);
      final submitBtnAfterTwo = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Mulai Free Talk'),
      );
      expect(submitBtnAfterTwo.onPressed, isNotNull);

      // Tap "Kosongkan" to return to 0 / 10, then fill up to 10 words cleanly.
      await tester.tap(find.text('Kosongkan'));
      await tester.pumpAndSettle();
      expect(find.text('Terpilih: 0 / 10 kata'), findsOneWidget);

      await tester.tap(find.text('Isi 10 Acak'));
      await tester.pumpAndSettle();
      expect(find.text('Terpilih: 10 / 10 kata'), findsOneWidget);
      expect(
        find.text(
          'Maksimal 10 kata per sesi agar obrolan fokus (hapus centang lain atau ketuk Kosongkan)',
        ),
        findsOneWidget,
      );

      // Verify remaining unchecked checkboxes are disabled at 10 / 10.
      final disabledCheckboxes = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .where((cb) => cb.value == false && cb.onChanged == null)
          .toList();
      expect(disabledCheckboxes, hasLength(2));

      // Tapping "Kosongkan" resets back to 0 / 10 and re-enables all 12 checkboxes.
      await tester.tap(find.text('Kosongkan'));
      await tester.pumpAndSettle();
      expect(find.text('Terpilih: 0 / 10 kata'), findsOneWidget);
      expect(
        tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .every((cb) => cb.value == false && cb.onChanged != null),
        isTrue,
      );

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('RenderFlex overflowed'))
          .toList();
      expect(overflowErrors, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      Get.reset();
      await tester.runAsync(() async {
        await db.close();
      });
    });

    testWidgets('PracticeView _ScenarioPromptCard renders Target Kosakata chips & updates practiced checkmarks without overflow at 360dp', (WidgetTester tester) async {
      final errors = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      await tester.binding.setSurfaceSize(const Size(360, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Get.testMode = true;
      final db = AppDatabase(NativeDatabase.memory());
      final liveProvider = GeminiLiveProvider();
      final controller = PracticeController(
        liveProvider: liveProvider,
        audioService: AudioService(),
        repository: TutorRepository(
          database: db,
          restProvider: GeminiRestProvider(),
        ),
        initialArgs: buildSubDeckFreeTalkPracticeArgs(
          const FlashcardSubDeckFreeTalkSelection(
            targetVocabulary: <String>['budget', 'negotiate', 'run'],
            subDeckTitle: 'Business Basics',
            cefrHint: 'B1',
            optionalTopic: 'Project planning',
          ),
        ),
      );

      Get.put<PracticeController>(controller);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      controller.hasEverConnected.value = true;
      controller.errorMessage.value = null;
      controller.connectionState.value = LiveConnectionState.connected;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const PracticeView(),
        ),
      );
      await tester.pump();

      expect(find.text('0/3 kata'), findsOneWidget);
      expect(find.text('Target Kosakata (0/3 terpakai):'), findsOneWidget);
      expect(find.text('budget'), findsOneWidget);
      expect(find.text('negotiate'), findsOneWidget);
      expect(find.text('run'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      // User says 'budget' and 'negotiate' (and 'running' which must NOT mark 'run')
      controller.appendTranscriptTurnForTest(
        TranscriptTurnModel(
          role: 'user',
          text: 'We are running late, so let us negotiate the budget first.',
          timestamp: DateTime(2026, 11, 14, 18, 0),
        ),
      );
      await tester.pump();

      expect(find.text('2/3 kata'), findsOneWidget);
      expect(find.text('Target Kosakata (2/3 terpakai):'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('RenderFlex overflowed'))
          .toList();
      expect(overflowErrors, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      controller.onClose();
      Get.reset();
      await tester.runAsync(() async {
        await db.close();
      });
    });

    testWidgets('FlashcardSubDecksView sheet & FlashcardStudyView header expose Sub-Deck Free Talk flow at 360dp', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Get.testMode = true;
      final db = AppDatabase(NativeDatabase.memory());
      late FlashcardDeck deck;
      late FlashcardSubDeck subDeck;
      await tester.runAsync(() async {
        final deckId = await db.flashcardDao.createDeck(name: 'Business B1');
        final subDeckId = await db.flashcardDao.createSubDeck(
          deckId: deckId,
          name: 'Negotiation',
        );
        await db.flashcardDao.createFlashcard(
          subDeckId: subDeckId,
          word: 'proposal',
          meaningId: 'proposal / usulan',
        );
        deck = (await db.flashcardDao.getDecksWithStats()).first.deck;
        subDeck = (await db.flashcardDao.getSubDecksByDeck(deckId)).first;
      });

      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(),
      );

      Get.reset();
      Get.put<FlashcardSubDecksController>(
        FlashcardSubDecksController(repository: repo, initialDeck: deck),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          home: const FlashcardSubDecksView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Negotiation'));
      await tester.pumpAndSettle();
      expect(find.text('Free Talk dengan AI'), findsOneWidget);

      await tester.tap(find.text('Free Talk dengan AI'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await tester.pumpAndSettle();
      expect(find.text('Free Talk: Negotiation'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Switch to FlashcardStudyView and verify header Free Talk button
      Get.reset();
      Get.put<FlashcardStudyController>(
        FlashcardStudyController(
          repository: repo,
          ttsService: TtsService(repository: repo, audioService: AudioService()),
          initialArgs: FlashcardStudyArgs(
            subDeck: subDeck,
            deckName: deck.name,
          ),
        ),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          getPages: AppPages.routes,
          home: const FlashcardStudyView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Free Talk'), findsOneWidget);
      await tester.tap(find.text('Free Talk'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await tester.pumpAndSettle();

      expect(find.text('Free Talk: Negotiation'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      Get.reset();
      await tester.runAsync(() async {
        await db.close();
      });
    });
  });
}
