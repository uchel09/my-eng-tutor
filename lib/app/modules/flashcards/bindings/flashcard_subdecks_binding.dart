import 'package:get/get.dart';

import '../../../data/repositories/tutor_repository.dart';
import '../controllers/flashcard_subdecks_controller.dart';

class FlashcardSubDecksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FlashcardSubDecksController>(
      () => FlashcardSubDecksController(
        repository: Get.find<TutorRepository>(),
      ),
    );
  }
}
