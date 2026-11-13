import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Value;

import 'package:my_english_tutor/app/core/theme/app_theme.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/repositories/tutor_repository.dart';
import 'package:my_english_tutor/app/modules/review/controllers/review_controller.dart';
import 'package:my_english_tutor/app/modules/review/views/review_view.dart';

void main() {
  late AppDatabase db;
  late TutorRepository repository;
  late ReviewController controller;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.roadmapDao.watchAllLevelsWithLessons().first;
    repository = TutorRepository(
      database: db,
      restProvider: GeminiRestProvider(),
    );
    controller = ReviewController(repository: repository);
    controller.onInit();
    // Wait for initial Drift stream emissions.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() async {
    controller.onClose();
    await db.close();
  });

  test('addManualVocab inserts item with null sessionId and filters reactively', () async {
    final vocabId = await repository.addManualVocab(
      word: '  articulate  ',
      meaningId: 'mampu mengungkapkan ide dengan jelas',
      exampleSentence: 'She can articulate complex ideas simply.',
      cefrLevel: 'b2',
    );
    await repository.addManualVocab(
      word: 'greet',
      meaningId: 'menyapa',
      exampleSentence: 'Always greet your guests warmly.',
      cefrLevel: 'A1',
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.vocabItems.length, 2);
    final inserted = controller.vocabItems.firstWhere((v) => v.id == vocabId);
    expect(inserted.word, 'articulate');
    expect(inserted.cefrLevel, 'B2');
    expect(inserted.sessionId, isNull);
    expect(inserted.masteryCount, 0);

    // Filter by CEFR
    controller.selectCefrFilter('B2');
    expect(controller.filteredVocab.length, 1);
    expect(controller.filteredVocab.first.word, 'articulate');

    // Filter by search query across word/meaning/example
    controller.selectCefrFilter('ALL');
    controller.onSearchChanged('menyapa');
    expect(controller.filteredVocab.length, 1);
    expect(controller.filteredVocab.first.word, 'greet');

    // Mastery increment updates stream reactively
    await controller.markVocabMastered(vocabId);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final updated = controller.vocabItems.firstWhere((v) => v.id == vocabId);
    expect(updated.masteryCount, 1);
  });

  test('filteredMistakes and resolveSessionTitle work offline', () async {
    final roadmap = await repository.watchRoadmap().first;
    final firstLesson = roadmap.first.lessons.first;
    final now = DateTime(2026, 11, 13, 16, 0);

    final sessionId = await db.practiceDao.saveSessionWithInsights(
      session: PracticeSessionsCompanion.insert(
        lessonId: Value(firstLesson.id),
        sessionType: 'guided_speech',
        startedAt: now,
        endedAt: Value(now.add(const Duration(minutes: 1))),
        durationSec: const Value(60),
        overallScore: const Value(84),
        passed: const Value(true),
      ),
      mistakesList: [
        MistakesCompanion.insert(
          sessionId: 0,
          originalSentence: 'I am go to office yesterday.',
          correctedSentence: 'I went to the office yesterday.',
          explanation: 'Gunakan verb-2 went untuk kejadian lampau.',
          category: 'grammar',
          createdAt: now,
        ),
        MistakesCompanion.insert(
          sessionId: 0,
          originalSentence: 'Very good weather today.',
          correctedSentence: 'The weather is lovely today.',
          explanation: 'Tambahkan subjek dan kata kerja agar lengkap.',
          category: 'phrasing',
          createdAt: now,
        ),
      ],
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.sessions.length, 1);
    expect(controller.sessions.first.id, sessionId);
    expect(
      controller.resolveSessionTitle(controller.sessions.first),
      '${roadmap.first.level.code} • ${firstLesson.title}',
    );

    expect(
      controller.resolveSessionTitle(
        PracticeSession(
          id: 99,
          lessonId: null,
          sessionType: 'placement',
          startedAt: now,
          endedAt: null,
          durationSec: 60,
          transcriptJson: '[]',
          overallScore: 70,
          fluencyScore: 70,
          grammarScore: 70,
          vocabScore: 70,
          pronunciationScore: 70,
          fillerCount: 0,
          aiSummary: '',
          passed: true,
        ),
      ),
      'Quick Placement Test',
    );
    expect(
      controller.resolveSessionTitle(
        PracticeSession(
          id: 100,
          lessonId: null,
          sessionType: 'free_talk',
          startedAt: now,
          endedAt: null,
          durationSec: 60,
          transcriptJson: '[]',
          overallScore: 70,
          fluencyScore: 70,
          grammarScore: 70,
          vocabScore: 70,
          pronunciationScore: 70,
          fillerCount: 0,
          aiSummary: '',
          passed: true,
        ),
      ),
      'Free Talk Bebas',
    );

    controller.onSearchChanged('yesterday');
    expect(controller.filteredMistakes.length, 1);
    expect(controller.filteredMistakes.first.category, 'grammar');
  });

  test('groupedMistakesByDay groups by calendar day, toggles expand, and reacts to searchQuery', () async {
    final nowLocal = DateTime.now();
    final todayTime = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 14, 25);
    final yesterdayTime = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 9, 10)
        .subtract(const Duration(days: 1));
    final threeDaysAgoTime = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 19, 5)
        .subtract(const Duration(days: 3));

    await db.practiceDao.saveSessionWithInsights(
      session: PracticeSessionsCompanion.insert(
        sessionType: 'free_talk',
        startedAt: todayTime,
        overallScore: const Value(80),
        passed: const Value(true),
      ),
      mistakesList: [
        MistakesCompanion.insert(
          sessionId: 0,
          originalSentence: 'She go to work.',
          correctedSentence: 'She goes to work.',
          explanation: 'Use third-person singular.',
          category: 'grammar',
          createdAt: todayTime,
        ),
        MistakesCompanion.insert(
          sessionId: 0,
          originalSentence: 'I have many works.',
          correctedSentence: 'I have a lot of work.',
          explanation: 'Work is uncountable.',
          category: 'vocab',
          createdAt: todayTime.subtract(const Duration(hours: 2)),
        ),
        MistakesCompanion.insert(
          sessionId: 0,
          originalSentence: 'Yesterday I eat rice.',
          correctedSentence: 'Yesterday I ate rice.',
          explanation: 'Use past tense ate.',
          category: 'grammar',
          createdAt: yesterdayTime,
        ),
        MistakesCompanion.insert(
          sessionId: 0,
          originalSentence: 'Can you explain me?',
          correctedSentence: 'Can you explain it to me?',
          explanation: 'Explain takes a direct object.',
          category: 'phrasing',
          createdAt: threeDaysAgoTime,
        ),
      ],
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    final groups = controller.groupedMistakesByDay;
    expect(groups, hasLength(3));

    expect(
      groups[0].dayLabel,
      equals('Hari Ini • ${controller.formatShortDate(todayTime)}'),
    );
    expect(groups[0].items, hasLength(2));
    expect(controller.formatTimeOnly(todayTime), equals('14:25'));

    expect(
      groups[1].dayLabel,
      equals('Kemarin • ${controller.formatShortDate(yesterdayTime)}'),
    );
    expect(groups[1].items, hasLength(1));

    expect(
      groups[2].dayLabel,
      equals(controller.formatShortDate(threeDaysAgoTime)),
    );
    expect(groups[2].items, hasLength(1));

    // Only newest day is expanded by default.
    expect(controller.isMistakeDayExpanded(groups[0].dayKey), isTrue);
    expect(controller.isMistakeDayExpanded(groups[1].dayKey), isFalse);
    expect(controller.isMistakeDayExpanded(groups[2].dayKey), isFalse);

    // Toggling expands/collapses cleanly.
    controller.toggleMistakeDay(groups[0].dayKey);
    expect(controller.isMistakeDayExpanded(groups[0].dayKey), isFalse);
    controller.toggleMistakeDay(groups[1].dayKey);
    expect(controller.isMistakeDayExpanded(groups[1].dayKey), isTrue);

    // Active search expands all matching day groups.
    controller.onSearchChanged('grammar');
    final filteredGroups = controller.groupedMistakesByDay;
    expect(filteredGroups, hasLength(2));
    expect(filteredGroups[0].items, hasLength(1));
    expect(filteredGroups[1].items, hasLength(1));
    expect(controller.isMistakeDayExpanded(filteredGroups[0].dayKey), isTrue);
    expect(controller.isMistakeDayExpanded(filteredGroups[1].dayKey), isTrue);
  });

  testWidgets('ReviewView renders all 3 tabs without overflow at 360dp width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.testMode = true;
    final uiController = ReviewController(repository: repository);
    Get.put<ReviewController>(uiController);
    addTearDown(Get.reset);

    await tester.runAsync(() async {
      final now = DateTime(2026, 11, 13, 16, 0);
      await repository.addManualVocab(
        word: 'eloquent',
        meaningId: 'fasih dan meyakinkan',
        exampleSentence: 'She gave an eloquent presentation today.',
        cefrLevel: 'C1',
      );
      await db.practiceDao.saveSessionWithInsights(
        session: PracticeSessionsCompanion.insert(
          lessonId: const Value(null),
          sessionType: 'free_talk',
          startedAt: now,
          durationSec: const Value(95),
          overallScore: const Value(78),
          passed: const Value(true),
        ),
        mistakesList: [
          MistakesCompanion.insert(
            sessionId: 0,
            originalSentence: 'He don’t know the answer.',
            correctedSentence: 'He doesn’t know the answer.',
            explanation: 'Subjek tunggal memakai doesn’t.',
            category: 'grammar',
            createdAt: now,
          ),
        ],
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const ReviewView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('eloquent'), findsOneWidget);
    expect(find.text('Mastered 0x'), findsOneWidget);

    await tester.tap(find.text('Mistake Log'));
    await tester.pumpAndSettle();
    expect(find.text('He doesn’t know the answer.'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Free Talk Bebas'), findsOneWidget);
    expect(find.text('78/100'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
