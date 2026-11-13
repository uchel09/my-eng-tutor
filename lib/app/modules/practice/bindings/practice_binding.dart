import 'package:get/get.dart';

import '../../../data/providers/gemini_live_provider.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/audio_service.dart';
import '../controllers/practice_controller.dart';

class PracticeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PracticeController>(
      () => PracticeController(
        liveProvider: Get.find<GeminiLiveProvider>(),
        audioService: Get.find<AudioService>(),
        repository: Get.find<TutorRepository>(),
      ),
    );
  }
}
