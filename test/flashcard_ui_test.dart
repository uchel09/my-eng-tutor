@Timeout(Duration(seconds: 25))
library;

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Value;

import 'package:my_english_tutor/app/core/theme/app_theme.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/local/daos/flashcard_dao.dart';
import 'package:my_english_tutor/app/data/models/practice_args.dart';
import 'package:my_english_tutor/app/data/models/session_result_args.dart';
import 'package:my_english_tutor/app/data/models/speech_insight_model.dart';
import 'package:my_english_tutor/app/data/models/transcript_turn_model.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/repositories/tutor_repository.dart';
import 'package:my_english_tutor/app/data/services/audio_service.dart';
import 'package:my_english_tutor/app/data/services/tts_service.dart';
import 'package:my_english_tutor/app/modules/home/bindings/home_binding.dart';
import 'package:my_english_tutor/app/modules/home/controllers/home_controller.dart';
import 'package:my_english_tutor/app/modules/session_result/controllers/session_result_controller.dart';
import 'package:my_english_tutor/app/routes/app_pages.dart';

class _FakeFlashcardGeminiProvider extends GeminiRestProvider {
  List<String> lastAvoidSentences = const <String>[];
  bool? lastIncludeAll16Tenses;

  @override
  Future<SpeechInsightModel> evaluateSpeakingSession({
    required String apiKey,
    required String model,
    required String targetCefrLevel,
    required String sessionType,
    required String lessonTitle,
    required String scenarioPrompt,
    required bool bilingualBeginnerSupport,
    required List<TranscriptTurnModel> transcript,
    dynamic recordedAudioWavBytes,
  }) async {
    return const SpeechInsightModel(
      overallScore: 88,
      fluencyScore: 87,
      grammarScore: 88,
      vocabScore: 89,
      pronunciationScore: 86,
      fillerCount: 0,
      detectedFillers: <String>[],
      aiSummary: 'Clear speaking performance.',
      mistakes: <MistakeItemModel>[],
      vocabSuggestions: <VocabSuggestionModel>[
        VocabSuggestionModel(
          word: 'articulate',
          meaningId: 'fasih dan jelas',
          exampleSentence: 'She is very articulate during meetings.',
          cefrLevel: 'B2',
        ),
        VocabSuggestionModel(
          word: 'resilient',
          meaningId: 'tangguh',
          exampleSentence: 'Teams stay resilient under pressure.',
          cefrLevel: 'B2',
        ),
      ],
    );
  }

  @override
  Future<FlashcardPracticeAiResult> generateFlashcardPracticeContent({
    required String apiKey,
    required String model,
    required String word,
    String? currentMeaningId,
    String? wordTypeHint,
    bool includeAll16Tenses = false,
    List<String> avoidSentences = const <String>[],
  }) async {
    lastIncludeAll16Tenses = includeAll16Tenses;
    lastAvoidSentences = List<String>.from(avoidSentences);

    final count = includeAll16Tenses ? 16 : 5;
    final prefix = avoidSentences.isEmpty ? 'Initial' : 'Fresh';
    return FlashcardPracticeAiResult(
      wordType: 'verb',
      phonetic: '/nɪˈɡoʊʃieɪt/',
      meaningId: 'bernegosiasi',
      examples: List<FlashcardExampleItem>.generate(
        count,
        (i) => FlashcardExampleItem(
          tense: 'Tense ${i + 1}',
          en: '$prefix sentence ${i + 1} with $word.',
          id: 'Terjemahan $prefix ${i + 1}.',
        ),
      ),
      conversation:
          'A: Should we $word today?\nB: Yes, let us $word right away.\n\nTerjemahan:\nA: Haruskah kita bernegosiasi hari ini?\nB: Ya, mari segera bernegosiasi.',
    );
  }
}

void main() {
  late AppDatabase db;
  late _FakeFlashcardGeminiProvider fakeRestProvider;

  Future<void> flushSnackbars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  Finder activeMainScrollable() {
    return find
        .descendant(
          of: find.byType(Scaffold).last,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Scrollable && w.physics is! NeverScrollableScrollPhysics,
          ),
        )
        .first;
  }

  Future<void> pumpAppWith360Viewport(
    WidgetTester tester,
    Widget home, {
    String? initialRoute,
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
        home: initialRoute == null ? home : null,
      ),
    );
  }

  setUp(() async {
    Get.testMode = true;
    db = AppDatabase(NativeDatabase.memory());
    await db.roadmapDao.watchAllLevelsWithLessons().first;
    await db.settingsDao.updateSettings(
      const AppSettingsCompanion(apiKey: Value('test-key')),
    );

    fakeRestProvider = _FakeFlashcardGeminiProvider();

    Get.put<AppDatabase>(db, permanent: true);
    Get.put<AudioService>(AudioService(), permanent: true);
    Get.put<TtsService>(TtsService(), permanent: true);
    Get.put<GeminiRestProvider>(fakeRestProvider, permanent: true);
    Get.lazyPut<TutorRepository>(
      () => TutorRepository(
        database: Get.find<AppDatabase>(),
        restProvider: Get.find<GeminiRestProvider>(),
      ),
      fenix: true,
    );
    HomeBinding().dependencies();
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  test('HomeController.openSettingsTab targets Settings tab index 4', () {
    final homeController = Get.find<HomeController>();
    homeController.changeTab(2);
    expect(homeController.currentTabIndex.value, 2);

    homeController.openSettingsTab();
    expect(homeController.currentTabIndex.value, 4);

    // Tab indices outside 0..4 are ignored.
    homeController.changeTab(5);
    expect(homeController.currentTabIndex.value, 4);
  });

  testWidgets(
    '3-level Deck -> Sub-Deck -> 4-action sheet -> Study & AI Practice at 360dp',
    (WidgetTester tester) async {
      await pumpAppWith360Viewport(
        tester,
        const SizedBox.shrink(),
        initialRoute: AppPages.INITIAL,
      );
      await tester.pumpAndSettle();

      // Switch to 5th-added Flashcard tab (index 2).
      await tester.tap(find.text('Flashcard'));
      await tester.pumpAndSettle();
      expect(find.text('Flashcards'), findsOneWidget);

      // Level 1: Create a Deck.
      await tester.tap(find.text('Buat Deck Pertama'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ).first,
        'Business Word',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Buat Deck'),
        ),
      );
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      expect(find.text('Business Word'), findsOneWidget);
      expect(find.text('0 Sub-Deck'), findsOneWidget);
      expect(find.text('0 Kata'), findsOneWidget);

      // Tap Deck -> Bottom Sheet Menu 4 Aksi.
      await tester.tap(find.text('Business Word'));
      await tester.pumpAndSettle();
      expect(find.text('Buka Deck'), findsOneWidget);
      expect(find.text('Mulai Tes'), findsOneWidget);
      expect(find.text('Ganti Nama'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);

      // Validate empty quiz guard ("Mulai Tes").
      await tester.tap(find.text('Mulai Tes'));
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      // Re-open 4-action menu -> Buka Deck (Level 2).
      await tester.tap(find.text('Business Word'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka Deck'));
      await tester.pumpAndSettle();

      expect(find.text('Business Word'), findsOneWidget);
      expect(find.text('Buat Sub-Deck Pertama'), findsOneWidget);

      // Level 2: Create a Sub-Deck.
      await tester.tap(find.text('Buat Sub-Deck Pertama'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ).first,
        'Business 1',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Buat Sub-Deck'),
        ),
      );
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      expect(find.text('Business 1'), findsOneWidget);

      // Tap Sub-Deck -> Bottom Sheet Menu 4 Aksi -> Buka Sub-Deck (Level 3).
      await tester.tap(find.text('Business 1'));
      await tester.pumpAndSettle();
      expect(find.text('Buka Sub-Deck'), findsOneWidget);
      expect(find.text('Mulai Tes'), findsOneWidget);
      expect(find.text('Ganti Nama'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);

      await tester.tap(find.text('Buka Sub-Deck'));
      await tester.pumpAndSettle();

      // Level 3: Add Word "negotiate".
      await tester.tap(find.text('+ Tambah Kata'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ).first,
        'negotiate',
      );
      await tester.tap(find.text('Tambahkan'));
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      expect(find.text('negotiate'), findsOneWidget);
      expect(find.text('Lengkapi dengan AI'), findsOneWidget);

      // Generate AI -> creates unsaved draft with 5 sentences + Verb switch.
      await tester.scrollUntilVisible(
        find.text('Lengkapi dengan AI'),
        200,
        scrollable: activeMainScrollable(),
      );
      await tester.tap(find.text('Lengkapi dengan AI'));
      await tester.pumpAndSettle();

      expect(find.text('Belum disimpan'), findsOneWidget);
      expect(find.text('Gunakan Semua 16 Tenses'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Initial sentence 1 with negotiate.'),
        200,
        scrollable: activeMainScrollable(),
      );
      expect(find.text('Initial sentence 1 with negotiate.'), findsOneWidget);

      // Enable 16 tenses and regenerate via "Ganti Latihan Kalimat".
      await tester.scrollUntilVisible(
        find.text('Gunakan Semua 16 Tenses'),
        -200,
        scrollable: activeMainScrollable(),
      );
      await tester.tap(find.text('Gunakan Semua 16 Tenses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ganti Latihan Kalimat'));
      await tester.pumpAndSettle();

      expect(fakeRestProvider.lastIncludeAll16Tenses, isTrue);
      expect(
        fakeRestProvider.lastAvoidSentences,
        contains('Initial sentence 1 with negotiate.'),
      );
      expect(find.text('Contoh Kalimat (16)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Fresh sentence 1 with negotiate.'),
        200,
        scrollable: activeMainScrollable(),
      );
      expect(find.text('Fresh sentence 1 with negotiate.'), findsOneWidget);

      // Persist draft to Drift via "Simpan".
      await tester.scrollUntilVisible(
        find.text('Simpan'),
        -200,
        scrollable: activeMainScrollable(),
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      expect(find.text('Tersimpan'), findsWidgets);
      final savedCards = await tester.runAsync(() async {
        final decks = await db.flashcardDao.getDecksWithStats();
        return db.flashcardDao.getCardsByDeck(decks.single.deck.id);
      });
      expect(savedCards, hasLength(1));
      expect(savedCards!.single.wordType, 'verb');
      expect(
        FlashcardExampleItem.decodeExamples(savedCards.single.examplesJson),
        hasLength(16),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  test(
    'SessionResultController saves vocab directly to chosen Flashcard sub-deck',
    () async {
      final repo = Get.find<TutorRepository>();
      final deckId = await repo.createDeck(name: 'Career');
      final subDeckId = await repo.createSubDeck(
        deckId: deckId,
        name: 'Meetings',
      );

      final controller = SessionResultController(repository: repo);
      controller.args = SessionResultArgs(
        practiceArgs: PracticeArgs(
          sessionType: 'free_talk',
          targetCefrLevel: 'B2',
          title: 'Work Chat',
          scenarioPrompt: 'Discuss meeting outcomes.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
        ),
        transcript: <TranscriptTurnModel>[
          TranscriptTurnModel(
            role: 'user',
            text: 'We stayed resilient and articulate.',
            timestamp: DateTime(2026, 11, 13, 19, 0),
          ),
        ],
        durationSec: 75,
      );

      await controller.evaluateSession();
      expect(controller.insight.value?.vocabSuggestions, hasLength(2));

      await controller.saveVocabToFlashcardSubDeck(
        vocab: controller.insight.value!.vocabSuggestions.first,
        subDeckId: subDeckId,
        targetLabel: 'Career / Meetings',
      );

      expect(controller.isVocabSavedToFlashcard('articulate'), isTrue);
      expect(
        controller.savedFlashcardTargetLabel('articulate'),
        'Career / Meetings',
      );
      expect(controller.isVocabSavedToFlashcard('resilient'), isFalse);

      await controller.saveAllVocabToFlashcardSubDeck(
        subDeckId: subDeckId,
        targetLabel: 'Career / Meetings',
      );

      expect(controller.isVocabSavedToFlashcard('resilient'), isTrue);
      final cards = await db.flashcardDao.getCardsBySubDeck(subDeckId);
      expect(cards.map((c) => c.word), <String>['articulate', 'resilient']);
      expect(
        FlashcardExampleItem.decodeExamples(cards.first.examplesJson).first.en,
        'She is very articulate during meetings.',
      );

      controller.onClose();
    },
  );

  testWidgets(
    'SessionResultView Simpan opens deck/sub-deck picker and saves to Flashcards at 360dp',
    (WidgetTester tester) async {
      final sessionArgs = SessionResultArgs(
        practiceArgs: PracticeArgs(
          sessionType: 'free_talk',
          targetCefrLevel: 'B2',
          title: 'Airport Check-In',
          scenarioPrompt: 'Talk at the airport counter.',
          mode: 'live_roleplay',
          targetDurationSec: 90,
        ),
        transcript: <TranscriptTurnModel>[
          TranscriptTurnModel(
            role: 'user',
            text: 'I need an articulate explanation.',
            timestamp: DateTime(2026, 11, 13, 19, 5),
          ),
        ],
        durationSec: 80,
      );

      await pumpAppWith360Viewport(
        tester,
        const SizedBox.shrink(),
        initialRoute: AppPages.INITIAL,
      );
      await tester.pumpAndSettle();

      Get.toNamed<void>(Routes.SESSION_RESULT, arguments: sessionArgs);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Rekomendasi Kosakata Baru'),
        220,
        scrollable: activeMainScrollable(),
      );
      await tester.pumpAndSettle();

      // Tap first "Simpan" button on recommended word.
      await tester.tap(find.text('Simpan').first);
      await tester.pumpAndSettle();

      // Step 1 inside picker sheet: Create a new Deck inline.
      expect(find.text('+ Buat Deck Baru'), findsOneWidget);
      await tester.tap(find.text('+ Buat Deck Baru'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ).first,
        'Travel',
      );
      await tester.tap(find.text('Buat & Pilih'));
      await tester.pumpAndSettle();

      // Auto-advanced to Step 2 -> Create a new Sub-Deck inline.
      expect(find.text('+ Buat Sub-Deck Baru'), findsOneWidget);
      await tester.tap(find.text('+ Buat Sub-Deck Baru'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ).first,
        'Airport',
      );
      await tester.tap(find.text('Buat & Pilih'));
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      // Verify button updated and database row saved.
      expect(find.text('Tersimpan (Travel / Airport)'), findsOneWidget);
      final allDecks = await tester.runAsync(db.flashcardDao.getDecksWithStats);
      expect(allDecks!.single.deck.name, 'Travel');
      expect(allDecks.single.totalCardCount, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}
