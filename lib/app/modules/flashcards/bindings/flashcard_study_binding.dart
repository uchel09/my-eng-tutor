import 'package:get/get.dart';

import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/tts_service.dart';
import '../controllers/flashcard_study_controller.dart';

class FlashcardStudyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FlashcardStudyController>(
      () => FlashcardStudyController(
        repository: Get.find<TutorRepository>(),
        ttsService: Get.find<TtsService>(),
        audioService: Get.find<AudioService>(),
      ),
    );
  }
}
