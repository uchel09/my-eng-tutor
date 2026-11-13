import 'package:get/get.dart';

import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/audio_service.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        repository: Get.find<TutorRepository>(),
        audioService: Get.find<AudioService>(),
      ),
    );
  }
}
