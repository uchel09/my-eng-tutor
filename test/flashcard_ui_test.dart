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
import 'package:my_english_tutor/app/modules/flashcards/controllers/flashcard_study_controller.dart';
import 'package:my_english_tutor/app/modules/flashcards/controllers/flashcards_controller.dart';
import 'package:my_english_tutor/app/modules/flashcards/models/flashcard_nav_args.dart';
import 'package:my_english_tutor/app/modules/flashcards/views/flashcards_view.dart';
import 'package:my_english_tutor/app/modules/flashcards/widgets/flashcard_progress_circle.dart';
import 'package:my_english_tutor/app/modules/home/bindings/home_binding.dart';
import 'package:my_english_tutor/app/modules/home/controllers/home_controller.dart';
import 'package:my_english_tutor/app/modules/session_result/controllers/session_result_controller.dart';
import 'package:my_english_tutor/app/routes/app_pages.dart';

class _FakeFlashcardGeminiProvider extends GeminiRestProvider {
  List<String> lastAvoidSentences = const <String>[];
  bool? lastIncludeAll16Tenses;
  FlashcardExampleGenerationMode? lastMode;
  List<String> lastKnownPartsOfSpeech = const <String>[];
  int generateCallCount = 0;
  int vocabBatchCallCount = 0;
  final List<String> requestedVocabTopics = <String>[];
  final List<int> requestedVocabCounts = <int>[];
  void Function(int callNumber, String topicName)? onVocabBatchCall;
  Future<List<GeneratedVocabPackItem>> Function(
    int callNumber,
    String topicName,
    int count,
  )? customVocabBatchHandler;

  final Map<String, List<String>> partsOfSpeechByWord = <String, List<String>>{
    'negotiate': <String>['Verb'],
    'resilient': <String>['Adjective'],
    'set': <String>['Noun', 'Verb', 'Adjective'],
  };

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
    List<String> knownPartsOfSpeech = const <String>[],
    FlashcardExampleGenerationMode mode =
        FlashcardExampleGenerationMode.standard,
    bool includeAll16Tenses = false,
    List<String> avoidSentences = const <String>[],
  }) async {
    generateCallCount += 1;
    lastIncludeAll16Tenses = includeAll16Tenses;
    lastMode = mode;
    lastKnownPartsOfSpeech = List<String>.from(knownPartsOfSpeech);
    lastAvoidSentences = List<String>.from(avoidSentences);

    final posList =
        partsOfSpeechByWord[word.trim().toLowerCase()] ??
        (knownPartsOfSpeech.isNotEmpty
            ? knownPartsOfSpeech
            : const <String>['Verb']);
    final is16 =
        mode == FlashcardExampleGenerationMode.verb16TensesOnly ||
        includeAll16Tenses;
    final count = is16 ? 16 : 5;
    final prefix = avoidSentences.isEmpty ? 'Initial' : 'Fresh';
    final nonVerbs = FlashcardPosHelper.nonVerbPosList(posList);

    final examples = List<FlashcardExampleItem>.generate(count, (i) {
      final posTag = is16
          ? 'Verb'
          : (nonVerbs.isNotEmpty
                ? nonVerbs[i % nonVerbs.length]
                : (posList.isNotEmpty ? posList.first : 'Verb'));
      final scopePrefix = is16
          ? (avoidSentences.isEmpty ? 'Verb16' : 'FreshVerb16')
          : prefix;
      return FlashcardExampleItem(
        pos: posTag,
        tense: is16 ? 'Tense ${i + 1}' : 'Daily ${i + 1}',
        en: '$scopePrefix sentence ${i + 1} with $word.',
        id: 'Terjemahan $scopePrefix ${i + 1}.',
      );
    });

    return FlashcardPracticeAiResult(
      wordType: FlashcardPosHelper.deriveWordType(posList),
      partsOfSpeech: posList,
      phonetic: word.trim().toLowerCase() == 'negotiate'
          ? '/nɪˈɡoʊʃieɪt/'
          : '/set/',
      meaningId: word.trim().toLowerCase() == 'negotiate'
          ? 'bernegosiasi'
          : 'arti $word',
      examples: examples,
      conversation:
          'A: Should we $word today?\nB: Yes, let us $word right away.\n\nTerjemahan:\nA: Haruskah kita menggunakan $word hari ini?\nB: Ya, mari segera.',
    );
  }

  @override
  Future<List<GeneratedVocabPackItem>> generateDailyVocabBatch({
    required String apiKey,
    required String model,
    required String cefrLevel,
    required String topicName,
    int count = 50,
    List<String> avoidWords = const <String>[],
  }) async {
    vocabBatchCallCount += 1;
    final batchIndex = vocabBatchCallCount;
    requestedVocabTopics.add('$cefrLevel:$topicName');
    requestedVocabCounts.add(count);
    onVocabBatchCall?.call(batchIndex, topicName);

    final handler = customVocabBatchHandler;
    if (handler != null) {
      return handler(batchIndex, topicName, count);
    }

    final avoidSet = avoidWords.map((w) => w.trim().toLowerCase()).toSet();
    final safeTopicSlug = topicName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    const posPool = <List<String>>[
      <String>['Verb'],
      <String>['Noun'],
      <String>['Adjective'],
      <String>['Noun', 'Verb'],
      <String>['Adverb'],
    ];

    final items = <GeneratedVocabPackItem>[];
    var seq = 1;
    while (items.length < count) {
      final candidate = '${cefrLevel.toLowerCase()}_${safeTopicSlug}_w$seq';
      seq += 1;
      if (avoidSet.contains(candidate)) continue;
      items.add(
        GeneratedVocabPackItem(
          word: candidate,
          phonetic: '/$candidate/',
          meaningId: 'arti $candidate',
          partsOfSpeech: posPool[(items.length) % posPool.length],
        ),
      );
    }
    return items;
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

  Future<void> scrollAndTap(
    WidgetTester tester,
    Finder finder, {
    double delta = 200,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: activeMainScrollable(),
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pumpAppWith360Viewport(
    WidgetTester tester,
    Widget home, {
    String? initialRoute,
    Size size = const Size(360, 780),
  }) async {
    tester.view.physicalSize = size;
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
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
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
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
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
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
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
      await scrollAndTap(
        tester,
        find.text('Gunakan Semua 16 Tenses'),
        delta: -200,
      );
      await scrollAndTap(
        tester,
        find.text('Ganti Latihan Kalimat'),
        delta: -200,
      );

      expect(fakeRestProvider.lastIncludeAll16Tenses, isTrue);
      expect(
        fakeRestProvider.lastAvoidSentences,
        contains('Verb16 sentence 1 with negotiate.'),
      );
      expect(find.text('Contoh Kalimat (16)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('FreshVerb16 sentence 1 with negotiate.'),
        200,
        scrollable: activeMainScrollable(),
      );
      expect(
        find.text('FreshVerb16 sentence 1 with negotiate.'),
        findsOneWidget,
      );

      // Persist draft to Drift via "Simpan".
      await scrollAndTap(tester, find.text('Simpan'), delta: -200);
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
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        'Travel',
      );
      await tester.tap(find.text('Buat & Pilih'));
      await tester.pumpAndSettle();

      // Auto-advanced to Step 2 -> Create a new Sub-Deck inline.
      expect(find.text('+ Buat Sub-Deck Baru'), findsOneWidget);
      await tester.tap(find.text('+ Buat Sub-Deck Baru'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
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

  testWidgets(
    'Multi-POS modes at 360dp portrait: Pure Non-Verb hides 16 Tenses, Hybrid 3 POS keeps 2 isolated tabs without overflow',
    (WidgetTester tester) async {
      final overflowErrors = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          overflowErrors.add(details);
        }
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      final repo = Get.find<TutorRepository>();
      final deckId = await tester.runAsync(
        () => repo.createDeck(name: 'POS Deck'),
      );
      final subDeckId = await tester.runAsync(
        () => repo.createSubDeck(deckId: deckId!, name: 'POS Sub'),
      );
      await tester.runAsync(
        () => repo.createFlashcard(
          subDeckId: subDeckId!,
          word: 'set',
          meaningId: '',
        ),
      );
      await tester.runAsync(
        () => repo.createFlashcard(
          subDeckId: subDeckId!,
          word: 'resilient',
          meaningId: '',
        ),
      );
      final subDeck = (await tester.runAsync(
        () => db.flashcardDao.getSubDecksByDeck(deckId!),
      ))!.single;

      await pumpAppWith360Viewport(
        tester,
        const SizedBox.shrink(),
        initialRoute: AppPages.INITIAL,
      );
      await tester.pumpAndSettle();

      Get.toNamed<void>(
        Routes.FLASHCARD_CARDS,
        arguments: FlashcardStudyArgs(subDeck: subDeck, deckName: 'POS Deck'),
      );
      await tester.pumpAndSettle();

      // Active card #1 is newest ("resilient" -> Pure Adjective)
      expect(find.text('resilient'), findsOneWidget);
      expect(
        find.text('Jenis kata dideteksi saat Lengkapi dengan AI'),
        findsOneWidget,
      );

      await scrollAndTap(tester, find.text('Lengkapi dengan AI'));

      // Pure Non-Verb: shows Adjective chip + 5 sentences, NO 16 Tenses toggle/tabs
      expect(find.text('Adjective'), findsWidgets);
      expect(find.text('Contoh Kalimat (5)'), findsOneWidget);
      expect(find.text('Gunakan Semua 16 Tenses'), findsNothing);
      expect(find.text('16 Tenses (Verb)'), findsNothing);

      // Move to card #2 ("set" -> 3-POS Hybrid: Noun + Verb + Adjective)
      await scrollAndTap(
        tester,
        find.byTooltip('Kartu berikutnya'),
        delta: -250,
      );
      expect(find.text('set'), findsOneWidget);

      await scrollAndTap(tester, find.text('Lengkapi dengan AI'));

      // All 3 POS chips + 2 segmented tabs appear cleanly at 360dp
      expect(find.text('Noun'), findsWidgets);
      expect(find.text('Verb'), findsWidgets);
      expect(find.text('Adjective'), findsWidgets);
      expect(find.text('Noun • Adjective (5)'), findsOneWidget);
      expect(find.text('16 Tenses (Verb)'), findsOneWidget);
      expect(find.byType(TabBarView), findsNothing);
      expect(find.text('Initial sentence 1 with set.'), findsOneWidget);

      // Switch to Tab 2 -> activate & generate 16 Verb sentences without losing Tab 1
      await scrollAndTap(tester, find.text('16 Tenses (Verb)'));

      expect(find.text('Aktifkan & Generate 16 Tenses (Verb)'), findsOneWidget);
      await scrollAndTap(
        tester,
        find.text('Aktifkan & Generate 16 Tenses (Verb)'),
      );

      expect(
        fakeRestProvider.lastMode,
        FlashcardExampleGenerationMode.verb16TensesOnly,
      );
      expect(find.text('16 Tenses (Verb) (16)'), findsOneWidget);
      expect(find.text('Verb16 sentence 1 with set.'), findsOneWidget);

      // Toggle Tab 2 switch OFF then ON -> preserves generated 16 sentences in memory
      final countBeforeToggle = fakeRestProvider.generateCallCount;
      await scrollAndTap(
        tester,
        find.text('16 Tenses (Verb) Aktif'),
        delta: -150,
      );
      expect(find.text('Tampilkan 16 Tenses (Verb)'), findsOneWidget);
      await scrollAndTap(tester, find.text('Tampilkan 16 Tenses (Verb)'));
      expect(fakeRestProvider.generateCallCount, countBeforeToggle);
      expect(find.text('Verb16 sentence 1 with set.'), findsOneWidget);

      // Switch back to Tab 1 -> confirm Tab 1 sentences untouched, then Ganti Latihan Kalimat replaces ONLY Tab 1
      await scrollAndTap(
        tester,
        find.text('Noun • Adjective (5)'),
        delta: -150,
      );
      expect(find.text('Initial sentence 1 with set.'), findsOneWidget);

      await scrollAndTap(
        tester,
        find.text('Ganti Latihan Kalimat'),
        delta: -200,
      );

      expect(
        fakeRestProvider.lastMode,
        FlashcardExampleGenerationMode.nonVerbOnly,
      );
      expect(find.text('Fresh sentence 1 with set.'), findsOneWidget);
      // Tab 2 still has 16 Verb sentences intact
      expect(find.text('16 Tenses (Verb) (16)'), findsOneWidget);

      // Switch to Tab 2 and click Ganti Latihan Kalimat -> replaces ONLY Tab 2 (Tab 1 stays intact)
      await scrollAndTap(
        tester,
        find.text('16 Tenses (Verb) (16)'),
        delta: -150,
      );
      await scrollAndTap(
        tester,
        find.text('Ganti Latihan Kalimat'),
        delta: -200,
      );
      expect(
        fakeRestProvider.lastMode,
        FlashcardExampleGenerationMode.verb16TensesOnly,
      );
      expect(
        fakeRestProvider.lastAvoidSentences,
        contains('Verb16 sentence 1 with set.'),
      );
      expect(find.text('FreshVerb16 sentence 1 with set.'), findsOneWidget);
      // Tab 1 non-verb sentences remain intact
      await scrollAndTap(
        tester,
        find.text('Noun • Adjective (5)'),
        delta: -150,
      );
      expect(find.text('Fresh sentence 1 with set.'), findsOneWidget);

      // Save persists BOTH lists & all 3 POS to Drift
      await scrollAndTap(tester, find.text('Simpan'), delta: -200);
      await flushSnackbars(tester);

      final persistedCards = await tester.runAsync(
        () => db.flashcardDao.getCardsBySubDeck(subDeck.id),
      );
      final savedSet = persistedCards!.firstWhere((c) => c.word == 'set');
      expect(savedSet.wordType, 'verb');
      expect(
        FlashcardPosHelper.decodePartsOfSpeech(savedSet.partsOfSpeechJson),
        const ['Noun', 'Verb', 'Adjective'],
      );
      expect(
        FlashcardExampleItem.decodeExamples(savedSet.examplesJson).first.en,
        'Fresh sentence 1 with set.',
      );
      final savedVerb16 = FlashcardExampleItem.decodeExamples(
        savedSet.verbTensesExamplesJson,
      );
      expect(savedVerb16, hasLength(16));
      expect(savedVerb16.first.en, 'FreshVerb16 sentence 1 with set.');

      // Daftar mode shows compact POS summary without overflow (in pinned header above ListView)
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
      expect(find.text('Noun • Verb • Adjective'), findsOneWidget);

      expect(overflowErrors, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'Edit Flashcard works in Belajar and Daftar modes at 360x760 portrait without overflow or duplicates',
    (WidgetTester tester) async {
      final overflowErrors = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          overflowErrors.add(details);
        }
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      Finder fieldByLabel(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );

      final repo = Get.find<TutorRepository>();
      final deckId = await tester.runAsync(
        () => repo.createDeck(name: 'Edit Deck'),
      );
      final subDeckId = await tester.runAsync(
        () => repo.createSubDeck(deckId: deckId!, name: 'Edit Sub'),
      );
      await tester.runAsync(
        () => repo.createFlashcard(
          subDeckId: subDeckId!,
          word: 'schedule',
          phonetic: '/ˈskedʒuːl/',
          meaningId: 'jadwal',
          partsOfSpeech: const ['Noun'],
        ),
      );
      await tester.runAsync(
        () => repo.createFlashcard(
          subDeckId: subDeckId!,
          word: 'negotiate',
          meaningId: '',
        ),
      );
      final subDeck = (await tester.runAsync(
        () => db.flashcardDao.getSubDecksByDeck(deckId!),
      ))!.single;

      await pumpAppWith360Viewport(
        tester,
        const SizedBox.shrink(),
        initialRoute: AppPages.INITIAL,
        size: const Size(360, 760),
      );
      await tester.pumpAndSettle();

      Get.toNamed<void>(
        Routes.FLASHCARD_CARDS,
        arguments: FlashcardStudyArgs(subDeck: subDeck, deckName: 'Edit Deck'),
      );
      await tester.pumpAndSettle();

      // Card #1 (newest) is 'negotiate'. Generate AI draft first so unsaved draft sync is also verified.
      expect(find.text('negotiate'), findsOneWidget);
      await scrollAndTap(tester, find.text('Lengkapi dengan AI'));

      // Verify Belajar edit button is visible (scroll back up after tapping Lengkapi dengan AI) and open dialog.
      final studyEditBtn = find.byTooltip('Edit kartu ini');
      await tester.scrollUntilVisible(
        studyEditBtn,
        -200,
        scrollable: activeMainScrollable(),
      );
      await tester.ensureVisible(studyEditBtn);
      await tester.pumpAndSettle();
      expect(studyEditBtn, findsOneWidget);
      await tester.tap(studyEditBtn);
      await tester.pumpAndSettle();

      expect(find.text('Edit Flashcard'), findsOneWidget);

      final dialogSaveBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Simpan'),
      );

      // Empty word validation inside dialog.
      await tester.enterText(fieldByLabel('Kata / Frasa Inggris *'), '   ');
      await tester.tap(dialogSaveBtn);
      await tester.pumpAndSettle();
      expect(find.text('Kata / Frasa Inggris wajib diisi.'), findsOneWidget);

      // Fill valid edited fields including multi-POS.
      await tester.enterText(
        fieldByLabel('Kata / Frasa Inggris *'),
        '  allocate  ',
      );
      await tester.enterText(
        fieldByLabel('Fonetik IPA (opsional)'),
        '/ˈæl.ə.keɪt/',
      );
      await tester.enterText(
        fieldByLabel('Arti Bahasa Indonesia (opsional)'),
        'mengalokasikan',
      );
      await tester.enterText(
        fieldByLabel('Jenis Kata (opsional, pisah koma)'),
        'noun, verb, Noun',
      );
      await tester.tap(dialogSaveBtn);
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      // Belajar UI reflects updated card & synced draft (Hybrid Noun + Verb tabs).
      expect(find.text('allocate'), findsOneWidget);
      expect(find.text('/ˈæl.ə.keɪt/'), findsOneWidget);
      expect(find.text('Noun'), findsWidgets);
      expect(find.text('Verb'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Noun (5)'),
        150,
        scrollable: activeMainScrollable(),
      );
      expect(find.text('Noun (5)'), findsOneWidget);
      expect(find.text('16 Tenses (Verb)'), findsOneWidget);

      var savedCards = await tester.runAsync(
        () => db.flashcardDao.getCardsBySubDeck(subDeck.id),
      );
      final allocatedRow = savedCards!.firstWhere((c) => c.word == 'allocate');
      expect(allocatedRow.phonetic, '/ˈæl.ə.keɪt/');
      expect(allocatedRow.meaningId, 'mengalokasikan');
      expect(
        FlashcardPosHelper.decodePartsOfSpeech(allocatedRow.partsOfSpeechJson),
        const ['Noun', 'Verb'],
      );

      // Switch to Daftar mode and verify Edit button appears on each list item without overflow.
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Edit kata'), findsNWidgets(2));
      expect(find.text('allocate'), findsOneWidget);
      expect(find.text('schedule'), findsOneWidget);

      // Open Edit on 'schedule' card from Daftar mode and test duplicate guard first.
      Finder scheduleEditBtn() => find.descendant(
        of: find.ancestor(
          of: find.text('schedule'),
          matching: find.byType(Card),
        ),
        matching: find.byTooltip('Edit kata'),
      );

      await tester.ensureVisible(scheduleEditBtn());
      await tester.pumpAndSettle();
      await tester.tap(scheduleEditBtn());
      await tester.pumpAndSettle();

      await tester.enterText(
        fieldByLabel('Kata / Frasa Inggris *'),
        'ALLOCATE',
      );
      await tester.tap(find.text('Simpan').last);
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      // 'schedule' must still exist untouched because duplicate was rejected.
      savedCards = await tester.runAsync(
        () => db.flashcardDao.getCardsBySubDeck(subDeck.id),
      );
      expect(savedCards!.where((c) => c.word == 'schedule'), hasLength(1));

      // Now edit 'schedule' to a valid non-duplicate word & details from Daftar mode.
      await tester.ensureVisible(scheduleEditBtn());
      await tester.pumpAndSettle();
      await tester.tap(scheduleEditBtn());
      await tester.pumpAndSettle();

      await tester.enterText(
        fieldByLabel('Kata / Frasa Inggris *'),
        'timetable',
      );
      await tester.enterText(
        fieldByLabel('Fonetik IPA (opsional)'),
        '/ˈtaɪm.teɪ.bəl/',
      );
      await tester.enterText(
        fieldByLabel('Arti Bahasa Indonesia (opsional)'),
        'jadwal kegiatan',
      );
      await tester.enterText(
        fieldByLabel('Jenis Kata (opsional, pisah koma)'),
        'noun, adjective',
      );
      await tester.tap(find.text('Simpan').last);
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      // Daftar UI and Drift row reflect all edited details cleanly without overflow.
      expect(find.text('timetable'), findsOneWidget);
      expect(find.text('/ˈtaɪm.teɪ.bəl/'), findsOneWidget);
      expect(find.text('jadwal kegiatan'), findsOneWidget);
      expect(find.text('Noun • Adjective'), findsOneWidget);

      savedCards = await tester.runAsync(
        () => db.flashcardDao.getCardsBySubDeck(subDeck.id),
      );
      final timetableRow = savedCards!.firstWhere((c) => c.word == 'timetable');
      expect(timetableRow.phonetic, '/ˈtaɪm.teɪ.bəl/');
      expect(timetableRow.meaningId, 'jadwal kegiatan');
      expect(timetableRow.wordType, 'non_verb');
      expect(
        FlashcardPosHelper.decodePartsOfSpeech(timetableRow.partsOfSpeechJson),
        const ['Noun', 'Adjective'],
      );

      expect(overflowErrors, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'Daily Vocab AI pack download supports A1 pack, pause mid-download, skip completed sub-decks on resume & keeps examples empty at 360dp',
    (WidgetTester tester) async {
      final overflowErrors = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          overflowErrors.add(details);
        }
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      final fastController = FlashcardsController(
        repository: Get.find<TutorRepository>(),
        packInterRequestDelay: Duration.zero,
        packFormatRetryDelay: Duration.zero,
      );
      if (Get.isPrepared<FlashcardsController>()) {
        Get.find<FlashcardsController>().onClose();
      }
      Get.delete<FlashcardsController>(force: true);
      GetInstance().markAsDirty<FlashcardsController>();
      Get.put<FlashcardsController>(fastController, permanent: true);
      expect(identical(Get.find<FlashcardsController>(), fastController), isTrue);

      await pumpAppWith360Viewport(
        tester,
        const FlashcardsView(),
        size: const Size(360, 760),
      );
      await tester.pumpAndSettle();

      // Open download pack bottom sheet from AppBar action button.
      await tester.tap(find.text('Unduh Paket'));
      await tester.pumpAndSettle();

      expect(find.text('Unduh Paket Kosakata Harian (AI)'), findsOneWidget);
      expect(find.text('Semua Level (~2.400 Kata)'), findsOneWidget);
      expect(find.text('A1 Pemula'), findsOneWidget);
      expect(find.text('B2 Lanjutan'), findsOneWidget);

      // Pause cleanly after 2 topics complete (2 sub-batches of 25 words each = 4 calls).
      fakeRestProvider.onVocabBatchCall = (int callNum, String _) {
        if (callNum == 4) {
          fastController.pauseCurriculumDownload();
        }
      };

      await tester.ensureVisible(find.text('A1 Pemula'));
      await tester.tap(find.text('A1 Pemula'));
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      expect(fakeRestProvider.vocabBatchCallCount, 4);
      expect(
        fakeRestProvider.requestedVocabCounts.every((c) => c > 0 && c <= 25),
        isTrue,
      );
      expect(fastController.isDownloadPaused.value, isTrue);
      expect(fastController.packProgressCurrent.value, 2);
      expect(fastController.packProgressTotal.value, 12);
      expect(fastController.packInsertedCards.value, 100);
      expect(find.text('Lanjutkan Unduhan'), findsOneWidget);

      // Resume -> Topics 1 & 2 already have >= 45 cards so they are skipped (10 topics * 2 sub-batches = 20 new calls, 24 total).
      fakeRestProvider.onVocabBatchCall = null;
      await tester.ensureVisible(find.text('Lanjutkan Unduhan'));
      await tester.tap(find.text('Lanjutkan Unduhan'));
      await tester.pumpAndSettle();
      await flushSnackbars(tester);

      expect(fakeRestProvider.vocabBatchCallCount, 24);
      expect(
        fakeRestProvider.requestedVocabCounts.every((c) => c > 0 && c <= 25),
        isTrue,
      );
      expect(fastController.isDownloadPaused.value, isFalse);
      expect(fastController.packProgressCurrent.value, 12);

      // Verify Drift contents: 1 A1 Deck, 12 Sub-Decks, 600 Cards, and NO examples generated.
      final decks = await tester.runAsync(
        () => db.flashcardDao.getDecksWithStats(),
      );
      final a1Deck = decks!.firstWhere(
        (d) => d.deck.name == 'A1 - Pemula (Daily Basics)',
      );
      expect(a1Deck.subDeckCount, 12);
      expect(a1Deck.totalCardCount, 600);

      final a1Cards = await tester.runAsync(
        () => db.flashcardDao.getCardsByDeck(a1Deck.deck.id),
      );
      expect(a1Cards, hasLength(600));
      expect(a1Cards!.every((c) => c.examplesJson == '[]'), isTrue);
      expect(a1Cards.every((c) => c.verbTensesExamplesJson == '[]'), isTrue);

      expect(overflowErrors, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    '_CardsListPanel POS filter chips filter Verb/Noun/Adjective/Adverb/Multi-POS/Lainnya cleanly at 360dp',
    (WidgetTester tester) async {
      final overflowErrors = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          overflowErrors.add(details);
        }
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      final deckId = await tester.runAsync(
        () => db.flashcardDao.createDeck(name: 'Filter Deck'),
      );
      final subDeckId = await tester.runAsync(
        () => db.flashcardDao.createSubDeck(
          deckId: deckId!,
          name: 'Mixed Daily Topic',
        ),
      );

      await tester.runAsync(
        () => db.flashcardDao.bulkUpsertFlashcards(
          subDeckId: subDeckId!,
          items: const <FlashcardSeedInput>[
            FlashcardSeedInput(
              word: 'accept',
              meaningId: 'menerima',
              partsOfSpeech: ['Verb'],
            ),
            FlashcardSeedInput(
              word: 'schedule',
              meaningId: 'jadwal / menjadwalkan',
              partsOfSpeech: ['Noun', 'Verb'],
            ),
            FlashcardSeedInput(
              word: 'budget',
              meaningId: 'anggaran',
              partsOfSpeech: ['Noun'],
            ),
            FlashcardSeedInput(
              word: 'resilient',
              meaningId: 'tangguh',
              partsOfSpeech: ['Adjective'],
            ),
            FlashcardSeedInput(
              word: 'smoothly',
              meaningId: 'dengan lancar',
              partsOfSpeech: ['Adverb'],
            ),
            FlashcardSeedInput(
              word: 'regarding',
              meaningId: 'mengenai',
              partsOfSpeech: ['Preposition'],
            ),
          ],
        ),
      );

      final subDeck = (await tester.runAsync(
        () => db.flashcardDao.getSubDecksByDeck(deckId!),
      ))!
          .single;

      await pumpAppWith360Viewport(
        tester,
        const SizedBox.shrink(),
        initialRoute: AppPages.INITIAL,
        size: const Size(360, 760),
      );
      await tester.pumpAndSettle();

      Get.toNamed<void>(
        Routes.FLASHCARD_CARDS,
        arguments: FlashcardStudyArgs(
          subDeck: subDeck,
          deckName: 'Filter Deck',
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Daftar mode.
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      // All 6 cards initially reachable under 'Semua' (scroll down to reveal bottom cards at 360x760).
      expect(find.text('regarding'), findsOneWidget);
      expect(find.text('smoothly'), findsOneWidget);
      expect(find.text('resilient'), findsOneWidget);
      expect(find.text('budget'), findsOneWidget);
      final verticalListScrollable = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      await tester.scrollUntilVisible(
        find.text('schedule'),
        150,
        scrollable: verticalListScrollable,
      );
      expect(find.text('schedule'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('accept'),
        150,
        scrollable: verticalListScrollable,
      );
      expect(find.text('accept'), findsOneWidget);

      // Helper for scrolling horizontal POS chip bar cleanly.
      final chipScrollable = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
      );
      Future<void> tapPosChip(String label, {double delta = 120}) async {
        final chipFinder = find.widgetWithText(FilterChip, label);
        await tester.scrollUntilVisible(
          chipFinder,
          delta,
          scrollable: chipScrollable,
        );
        await tester.ensureVisible(chipFinder);
        await tester.pumpAndSettle();
        await tester.tap(chipFinder);
        await tester.pumpAndSettle();
      }

      // Filter by 'Verb' -> 'accept' & 'schedule'.
      await tapPosChip('Verb');
      expect(find.text('accept'), findsOneWidget);
      expect(find.text('schedule'), findsOneWidget);
      expect(find.text('budget'), findsNothing);
      expect(find.text('resilient'), findsNothing);

      // Filter by 'Multi-POS' -> only 'schedule'.
      await tapPosChip('Multi-POS', delta: 120);
      expect(find.text('schedule'), findsOneWidget);
      expect(find.text('accept'), findsNothing);
      expect(find.text('budget'), findsNothing);

      // Scroll chips horizontally to reveal and tap 'Lainnya' -> only 'regarding'.
      await tapPosChip('Lainnya', delta: 120);
      expect(find.text('regarding'), findsOneWidget);
      expect(find.text('schedule'), findsNothing);

      // Filter by 'Adjective' -> only 'resilient', then tap it to open Study Mode on that exact card.
      await tapPosChip('Adjective', delta: -120);
      expect(find.text('resilient'), findsOneWidget);
      expect(find.text('regarding'), findsNothing);

      await tester.tap(find.text('resilient'));
      await tester.pumpAndSettle();
      expect(find.text('resilient'), findsOneWidget);
      expect(find.text('Ketuk kartu untuk balik & lihat arti'), findsOneWidget);

      expect(overflowErrors, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets(
    'downloadCurriculumPack caps requests at <= 25 words, auto-retries format glitch 1x & advances cleanly on empty/duplicate sub-batches',
    (WidgetTester tester) async {
      final controller = FlashcardsController(
        repository: Get.find<TutorRepository>(),
        packInterRequestDelay: Duration.zero,
        packFormatRetryDelay: Duration.zero,
      );
      addTearDown(controller.onClose);

      var retriedTopic1FormatGlitch = false;
      var emptyCountTopic2 = 0;

      fakeRestProvider.customVocabBatchHandler = (
        int callNumber,
        String topicName,
        int count,
      ) async {
        expect(count, inInclusiveRange(1, 25));

        // Call #1 throws a retryable format error once -> should auto-retry 1x cleanly.
        if (callNumber == 1) {
          retriedTopic1FormatGlitch = true;
          throw const GeminiApiException(
            'Format daftar kosakata dari Gemini tidak valid. Silakan coba lagi.',
          );
        }

        // Topic 2 ("Food, Cooking & Dining") returns empty list [] twice -> moves on cleanly without stopping download.
        if (topicName == 'Food, Cooking & Dining') {
          emptyCountTopic2 += 1;
          return const <GeneratedVocabPackItem>[];
        }

        final safeTopic = topicName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
        return List<GeneratedVocabPackItem>.generate(
          count,
          (idx) => GeneratedVocabPackItem(
            word: '${safeTopic}_c${callNumber}_w$idx',
            phonetic: '/w$idx/',
            meaningId: 'arti $idx',
            partsOfSpeech: const <String>['Noun'],
          ),
        );
      };

      await tester.runAsync(() => controller.downloadCurriculumPack(cefrLevelFilter: 'A1'));

      expect(retriedTopic1FormatGlitch, isTrue);
      // Topic 2 received an initial request + 1 extra attempt (total 2 empty responses) then moved on.
      expect(emptyCountTopic2, 2);
      expect(controller.isDownloadPaused.value, isFalse);
      expect(controller.packErrorMessage.value, isNull);
      expect(controller.packProgressCurrent.value, 12);
      // 11 remaining topics x 50 words = 550 cards saved seamlessly despite glitch & empty topic.
      expect(controller.packInsertedCards.value, 550);
      expect(
        fakeRestProvider.requestedVocabCounts.every((c) => c <= 25),
        isTrue,
      );
    },
  );

  testWidgets(
    'FlashcardProgressCircle maps exact colors for 0%, 25%, 60%, 90%, 100% and empty decks',
    (WidgetTester tester) async {
      final colorScheme = AppTheme.lightTheme.colorScheme;

      expect(
        FlashcardProgressCircle.colorForProgress(0, false, colorScheme),
        colorScheme.outlineVariant,
      );
      expect(
        FlashcardProgressCircle.colorForProgress(0, true, colorScheme),
        colorScheme.outlineVariant,
      );
      expect(
        FlashcardProgressCircle.textColorForProgress(0, true, colorScheme),
        colorScheme.onSurfaceVariant,
      );
      expect(
        FlashcardProgressCircle.colorForProgress(25, true, colorScheme),
        Colors.red.shade600,
      );
      expect(
        FlashcardProgressCircle.colorForProgress(60, true, colorScheme),
        Colors.amber.shade700,
      );
      expect(
        FlashcardProgressCircle.colorForProgress(90, true, colorScheme),
        Colors.blue.shade600,
      );
      expect(
        FlashcardProgressCircle.colorForProgress(100, true, colorScheme),
        Colors.green.shade600,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Wrap(
              spacing: 8,
              children: [
                FlashcardProgressCircle(percent: 0, hasCards: false),
                FlashcardProgressCircle(percent: 25),
                FlashcardProgressCircle(percent: 60),
                FlashcardProgressCircle(percent: 90),
                FlashcardProgressCircle(percent: 100),
              ],
            ),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      final indicators = tester
          .widgetList<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .toList();
      expect(indicators, hasLength(5));
      expect(
        (indicators[0].valueColor as AlwaysStoppedAnimation<Color>).value,
        colorScheme.outlineVariant,
      );
      expect(
        (indicators[1].valueColor as AlwaysStoppedAnimation<Color>).value,
        Colors.red.shade600,
      );
      expect(
        (indicators[2].valueColor as AlwaysStoppedAnimation<Color>).value,
        Colors.amber.shade700,
      );
      expect(
        (indicators[3].valueColor as AlwaysStoppedAnimation<Color>).value,
        Colors.blue.shade600,
      );
      expect(
        (indicators[4].valueColor as AlwaysStoppedAnimation<Color>).value,
        Colors.green.shade600,
      );
    },
  );

  testWidgets(
    '3 study status markers update StudyView, ListView filters, SubDeck & Deck progress circles cleanly at 360dp',
    (WidgetTester tester) async {
      final overflowErrors = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) {
          overflowErrors.add(details);
        }
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      final deckId = await tester.runAsync(
        () => db.flashcardDao.createDeck(name: 'Progress Deck'),
      );
      final subDeckId = await tester.runAsync(
        () => db.flashcardDao.createSubDeck(
          deckId: deckId!,
          name: 'Progress Topic',
        ),
      );

      await tester.runAsync(
        () => db.flashcardDao.bulkUpsertFlashcards(
          subDeckId: subDeckId!,
          items: const <FlashcardSeedInput>[
            FlashcardSeedInput(
              word: 'alpha',
              meaningId: 'pertama',
              partsOfSpeech: ['Noun'],
            ),
            FlashcardSeedInput(
              word: 'beta',
              meaningId: 'kedua',
              partsOfSpeech: ['Verb'],
            ),
            FlashcardSeedInput(
              word: 'gamma',
              meaningId: 'ketiga',
              partsOfSpeech: ['Adjective'],
            ),
            FlashcardSeedInput(
              word: 'delta',
              meaningId: 'keempat',
              partsOfSpeech: ['Noun'],
            ),
          ],
        ),
      );

      final subDeck = (await tester.runAsync(
        () => db.flashcardDao.getSubDecksByDeck(deckId!),
      ))!
          .single;

      await pumpAppWith360Viewport(
        tester,
        const SizedBox.shrink(),
        initialRoute: AppPages.INITIAL,
        size: const Size(360, 760),
      );
      await tester.pumpAndSettle();

      // Navigate into StudyView for Progress Topic.
      Get.toNamed<void>(
        Routes.FLASHCARD_CARDS,
        arguments: FlashcardStudyArgs(
          subDeck: subDeck,
          deckName: 'Progress Deck',
        ),
      );
      await tester.pumpAndSettle();

      // Header starts at 0% Hafal.
      expect(find.text('0% Hafal'), findsOneWidget);
      expect(find.text('0/4 Hafal • 0 Ulang • 4 Belum'), findsOneWidget);

      final studyCtrl = Get.find<FlashcardStudyController>();
      final firstCardWord = studyCtrl.activeCard!.word;

      // Mark 1st visible card as 'Hafal' -> 25% Hafal.
      await tester.tap(find.text('Hafal').last);
      await tester.pumpAndSettle();
      expect(find.text('25% Hafal'), findsOneWidget);
      expect(find.text('1/4 Hafal • 0 Ulang • 3 Belum'), findsOneWidget);

      // Move to 2nd card and mark 'Perlu Ulang'.
      await tester.tap(find.byTooltip('Kartu berikutnya'));
      await tester.pumpAndSettle();
      final secondCardWord = studyCtrl.activeCard!.word;
      await tester.tap(find.text('Perlu Ulang').last);
      await tester.pumpAndSettle();
      expect(find.text('25% Hafal'), findsOneWidget);
      expect(find.text('1/4 Hafal • 1 Ulang • 2 Belum'), findsOneWidget);

      // Switch to Daftar mode, toggle a card's status via quick menu, then filter by 'Hafal'.
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(Card),
          matching: find.text('Belum'),
        ).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hafal').last);
      await tester.pumpAndSettle();
      expect(find.text('50% Hafal'), findsOneWidget);
      expect(find.text('2/4 Hafal • 1 Ulang • 1 Belum'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Hafal'));
      await tester.pumpAndSettle();
      expect(find.text(firstCardWord), findsOneWidget);
      expect(find.text(secondCardWord), findsNothing);

      // Switching back to Belajar stays consistent with the active 'Hafal' filter (2 cards, clamped to index 1).
      await tester.tap(find.text('Belajar'));
      await tester.pumpAndSettle();
      expect(find.text('Kartu 2 dari 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Kartu sebelumnya'));
      await tester.pumpAndSettle();
      expect(find.text('Kartu 1 dari 2'), findsOneWidget);
      expect(find.text(firstCardWord), findsOneWidget);

      // Mark both filtered cards as 'Belum' while filtered to 'Hafal' -> empty filter view + "Tampilkan Semua".
      await tester.tap(find.text('Belum').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Belum').last);
      await tester.pumpAndSettle();
      expect(find.text('Tampilkan Semua'), findsOneWidget);

      await tester.tap(find.text('Tampilkan Semua'));
      await tester.pumpAndSettle();
      expect(find.text('Kartu 1 dari 4'), findsOneWidget);

      // Mark two distinct cards as 'Hafal' (with secondCardWord still 'Perlu Ulang') -> 2/4 = 50% (1 Ulang).
      final hafalCandidates = studyCtrl.cards
          .where((c) => c.word != secondCardWord)
          .take(2)
          .toList();
      for (final card in hafalCandidates) {
        await tester.runAsync(
          () => studyCtrl.setCardStudyStatus(card, FlashcardStudyStatus.mastered),
        );
      }
      await tester.pumpAndSettle();

      // Pop back to Home -> Flashcard tab -> DeckCard & SubDeckCard show 50% circle + summary badge.
      Get.back<void>();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flashcard'));
      await tester.pumpAndSettle();

      expect(find.text('Progress Deck'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('2/4 Hafal • 1 Ulang'), findsOneWidget);

      // Open Sub-Decks screen to verify _SubDeckCard progress circle too.
      await tester.tap(find.text('Progress Deck'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka Deck'));
      await tester.pumpAndSettle();

      expect(find.text('Progress Topic'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('2/4 Hafal • 1 Ulang'), findsOneWidget);

      expect(overflowErrors, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );
}
