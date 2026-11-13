import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_english_tutor/app/core/theme/app_theme.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/repositories/tutor_repository.dart';
import 'package:my_english_tutor/app/data/services/audio_service.dart';
import 'package:my_english_tutor/app/data/services/tts_service.dart';
import 'package:my_english_tutor/app/modules/home/bindings/home_binding.dart';
import 'package:my_english_tutor/app/routes/app_pages.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    Get.testMode = true;
    db = AppDatabase(NativeDatabase.memory());
    // Ensure Drift onCreate + CurriculumSeeder completes before pumping UI.
    await db.roadmapDao.watchAllLevelsWithLessons().first;

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
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  testWidgets('HomeView renders 5-tab NavigationBar and dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        title: 'My English Tutor',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: AppPages.INITIAL,
        getPages: AppPages.routes,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('My English Tutor'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Roadmap'), findsOneWidget);
    expect(find.text('Flashcard'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Siap berlatih hari ini?'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('0 / 100 Misi Selesai'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('0 / 100 Misi Selesai'), findsOneWidget);

    await tester.tap(find.text('Roadmap'));
    await tester.pumpAndSettle();

    expect(find.text('Peta Belajar A1–C2'), findsOneWidget);
    expect(find.text('1. Self-Introduction'), findsOneWidget);

    await tester.tap(find.text('Flashcard'));
    await tester.pumpAndSettle();

    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Belum Ada Deck Flashcard'), findsOneWidget);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('Review & Kosakata'), findsOneWidget);
    expect(find.text('Vocab Bank'), findsOneWidget);
    expect(find.text('Mistake Log'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Free Talk Bebas'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Free Talk Bebas'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Topik Free Talk'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Coffee culture');
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Topik Free Talk'), findsNothing);

    // Dispose widget tree and flush Drift's StreamQueryStore zero-duration timer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
