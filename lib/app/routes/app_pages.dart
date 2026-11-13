import 'package:get/get.dart';

import '../modules/flashcards/bindings/flashcard_quiz_binding.dart';
import '../modules/flashcards/bindings/flashcard_study_binding.dart';
import '../modules/flashcards/bindings/flashcard_subdecks_binding.dart';
import '../modules/flashcards/views/flashcard_quiz_view.dart';
import '../modules/flashcards/views/flashcard_study_view.dart';
import '../modules/flashcards/views/flashcard_subdecks_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/practice/bindings/practice_binding.dart';
import '../modules/practice/views/practice_view.dart';
import '../modules/review/bindings/review_binding.dart';
import '../modules/review/views/review_view.dart';
import '../modules/roadmap/bindings/roadmap_binding.dart';
import '../modules/roadmap/views/roadmap_view.dart';
import '../modules/session_result/bindings/session_result_binding.dart';
import '../modules/session_result/views/session_result_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.ROADMAP,
      page: () => const RoadmapView(),
      binding: RoadmapBinding(),
    ),
    GetPage(
      name: _Paths.PRACTICE,
      page: () => const PracticeView(),
      binding: PracticeBinding(),
    ),
    GetPage(
      name: _Paths.SESSION_RESULT,
      page: () => const SessionResultView(),
      binding: SessionResultBinding(),
    ),
    GetPage(
      name: _Paths.REVIEW,
      page: () => const ReviewView(),
      binding: ReviewBinding(),
    ),
    GetPage(
      name: _Paths.FLASHCARD_SUBDECKS,
      page: () => const FlashcardSubDecksView(),
      binding: FlashcardSubDecksBinding(),
    ),
    GetPage(
      name: _Paths.FLASHCARD_CARDS,
      page: () => const FlashcardStudyView(),
      binding: FlashcardStudyBinding(),
    ),
    GetPage(
      name: _Paths.FLASHCARD_QUIZ,
      page: () => const FlashcardQuizView(),
      binding: FlashcardQuizBinding(),
    ),
  ];
}
