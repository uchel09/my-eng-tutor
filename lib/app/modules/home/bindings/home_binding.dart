import 'package:get/get.dart';

import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/audio_service.dart';
import '../../flashcards/controllers/flashcards_controller.dart';
import '../../review/controllers/review_controller.dart';
import '../../roadmap/controllers/roadmap_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(repository: Get.find<TutorRepository>()),
      fenix: true,
    );
    Get.lazyPut<RoadmapController>(
      () => RoadmapController(repository: Get.find<TutorRepository>()),
      fenix: true,
    );
    Get.lazyPut<FlashcardsController>(
      () => FlashcardsController(repository: Get.find<TutorRepository>()),
      fenix: true,
    );
    Get.lazyPut<ReviewController>(
      () => ReviewController(repository: Get.find<TutorRepository>()),
      fenix: true,
    );
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        repository: Get.find<TutorRepository>(),
        audioService: Get.find<AudioService>(),
      ),
      fenix: true,
    );
  }
}
