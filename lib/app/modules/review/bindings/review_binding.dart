import 'package:get/get.dart';

import '../../../data/repositories/tutor_repository.dart';
import '../controllers/review_controller.dart';

class ReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReviewController>(
      () => ReviewController(repository: Get.find<TutorRepository>()),
    );
  }
}
