import 'package:get/get.dart';

import '../../../data/repositories/tutor_repository.dart';
import '../controllers/session_result_controller.dart';

class SessionResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SessionResultController>(
      () => SessionResultController(repository: Get.find<TutorRepository>()),
    );
  }
}
