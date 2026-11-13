import 'package:get/get.dart';

import '../data/local/app_database.dart';
import '../data/providers/gemini_live_provider.dart';
import '../data/providers/gemini_rest_provider.dart';
import '../data/repositories/tutor_repository.dart';
import '../data/services/audio_service.dart';
import '../data/services/tts_service.dart';

/// Registers global singletons available throughout the application lifecycle.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AppDatabase>(AppDatabase.defaults(), permanent: true);
    Get.put<AudioService>(AudioService(), permanent: true);
    Get.put<TtsService>(TtsService(), permanent: true);
    Get.lazyPut<GeminiLiveProvider>(() => GeminiLiveProvider(), fenix: true);
    Get.lazyPut<GeminiRestProvider>(() => GeminiRestProvider(), fenix: true);
    Get.lazyPut<TutorRepository>(
      () => TutorRepository(
        database: Get.find<AppDatabase>(),
        restProvider: Get.find<GeminiRestProvider>(),
      ),
      fenix: true,
    );
  }
}
