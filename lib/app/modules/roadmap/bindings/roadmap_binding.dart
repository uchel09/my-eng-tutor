import 'package:get/get.dart';

import '../../../data/repositories/tutor_repository.dart';
import '../controllers/roadmap_controller.dart';

class RoadmapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RoadmapController>(
      () => RoadmapController(repository: Get.find<TutorRepository>()),
    );
  }
}
