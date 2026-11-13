import 'package:get/get.dart';

import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/tts_service.dart';
import '../controllers/flashcard_quiz_controller.dart';

class FlashcardQuizBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FlashcardQuizController>(
      () => FlashcardQuizController(
        repository: Get.find<TutorRepository>(),
        ttsService: Get.find<TtsService>(),
      ),
    );
  }
}
