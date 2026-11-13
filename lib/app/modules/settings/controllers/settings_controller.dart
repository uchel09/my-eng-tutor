import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/gemini_constants.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/gemini_rest_provider.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/tts_service.dart';

/// Controller for managing API keys, Gemini models, theme, audio tests, and backups.
class SettingsController extends GetxController {
  SettingsController({required this.repository, required this.audioService});

  final TutorRepository repository;
  final AudioService audioService;

  final TextEditingController apiKeyController = TextEditingController();
  final TextEditingController liveModelController = TextEditingController();
  final TextEditingController scoringModelController = TextEditingController();
  final TextEditingController flashcardModelController =
      TextEditingController();
  final TextEditingController flashcardTtsModelController =
      TextEditingController();

  final FocusNode apiKeyFocusNode = FocusNode();
  final FocusNode liveModelFocusNode = FocusNode();
  final FocusNode scoringModelFocusNode = FocusNode();
  final FocusNode flashcardModelFocusNode = FocusNode();
  final FocusNode flashcardTtsModelFocusNode = FocusNode();

  final Rxn<AppSetting> settings = Rxn<AppSetting>();
  final RxBool isObscureApiKey = true.obs;
  final RxBool isSavingApi = false.obs;
  final RxBool isTestingApi = false.obs;
  final RxBool isFetchingModels = false.obs;
  final RxBool isTestingAudio = false.obs;
  final RxBool isExportingBackup = false.obs;
  final RxBool isImportingBackup = false.obs;

  final RxnString apiTestResultMessage = RxnString();
  final RxnBool apiTestSuccess = RxnBool();
  final RxnString modelFetchMessage = RxnString();
  final RxnBool modelFetchSuccess = RxnBool();
  final RxnString audioTestMessage = RxnString();
  final RxnBool audioTestSuccess = RxnBool();

  final RxList<String> dynamicLiveModels = <String>[].obs;
  final RxList<String> dynamicScoringModels = <String>[].obs;
  final RxList<String> dynamicTtsModels = <String>[].obs;

  final RxString activeLiveModelText = GeminiConstants.defaultLiveModel.obs;
  final RxString activeScoringModelText =
      GeminiConstants.defaultScoringModel.obs;
  final RxString activeFlashcardModelText =
      GeminiConstants.defaultFlashcardModel.obs;
  final RxString activeFlashcardTtsModelText =
      GeminiConstants.defaultTtsModel.obs;

  StreamSubscription<AppSetting>? _settingsSub;
  bool _hasInitializedFields = false;
  bool? _lastAppliedDarkMode;

  @override
  void onInit() {
    super.onInit();
    liveModelController.addListener(() {
      activeLiveModelText.value = liveModelController.text.trim();
    });
    scoringModelController.addListener(() {
      activeScoringModelText.value = scoringModelController.text.trim();
    });
    flashcardModelController.addListener(() {
      activeFlashcardModelText.value = flashcardModelController.text.trim();
    });
    flashcardTtsModelController.addListener(() {
      activeFlashcardTtsModelText.value = flashcardTtsModelController.text
          .trim();
    });

    _settingsSub = repository.watchSettings().listen(_onSettingsChanged);
  }

  void _onSettingsChanged(AppSetting data) {
    settings.value = data;

    if (!_hasInitializedFields || !apiKeyFocusNode.hasFocus) {
      if (apiKeyController.text != data.apiKey) {
        apiKeyController.text = data.apiKey;
      }
    }
    if (!_hasInitializedFields || !liveModelFocusNode.hasFocus) {
      if (liveModelController.text != data.liveModel) {
        liveModelController.text = data.liveModel;
      }
    }
    if (!_hasInitializedFields || !scoringModelFocusNode.hasFocus) {
      if (scoringModelController.text != data.scoringModel) {
        scoringModelController.text = data.scoringModel;
      }
    }
    if (!_hasInitializedFields || !flashcardModelFocusNode.hasFocus) {
      if (flashcardModelController.text != data.flashcardModel) {
        flashcardModelController.text = data.flashcardModel;
      }
    }
    if (!_hasInitializedFields || !flashcardTtsModelFocusNode.hasFocus) {
      if (flashcardTtsModelController.text != data.flashcardTtsModel) {
        flashcardTtsModelController.text = data.flashcardTtsModel;
      }
    }
    _hasInitializedFields = true;

    if (_lastAppliedDarkMode != data.darkMode) {
      _lastAppliedDarkMode = data.darkMode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.changeThemeMode(data.darkMode ? ThemeMode.dark : ThemeMode.light);
      });
    }
  }

  void toggleApiKeyVisibility() {
    isObscureApiKey.toggle();
  }

  void _resetTtsCooldownIfRegistered() {
    if (Get.isRegistered<TtsService>()) {
      Get.find<TtsService>().resetAiVoiceCooldown();
    }
  }

  /// Validates and persists the Gemini API key and Live/Scoring/Flashcard model IDs.
  Future<void> saveApiAndModelSettings() async {
    isSavingApi.value = true;
    try {
      final apiKey = apiKeyController.text.trim();
      var liveModel = liveModelController.text.trim();
      var scoringModel = scoringModelController.text.trim();
      var flashcardModel = flashcardModelController.text.trim();
      var flashcardTtsModel = flashcardTtsModelController.text.trim();

      if (liveModel.isEmpty) {
        liveModel = GeminiConstants.defaultLiveModel;
        liveModelController.text = liveModel;
      }
      if (scoringModel.isEmpty) {
        scoringModel = GeminiConstants.defaultScoringModel;
        scoringModelController.text = scoringModel;
      }
      if (flashcardModel.isEmpty) {
        flashcardModel = GeminiConstants.defaultFlashcardModel;
        flashcardModelController.text = flashcardModel;
      }
      if (flashcardTtsModel.isEmpty) {
        flashcardTtsModel = GeminiConstants.defaultTtsModel;
        flashcardTtsModelController.text = flashcardTtsModel;
      }

      await repository.updateSettings(
        AppSettingsCompanion(
          apiKey: drift.Value(apiKey),
          liveModel: drift.Value(liveModel),
          scoringModel: drift.Value(scoringModel),
          flashcardModel: drift.Value(flashcardModel),
          flashcardTtsModel: drift.Value(flashcardTtsModel),
        ),
      );
      _resetTtsCooldownIfRegistered();

      _showSnack(
        title: 'Pengaturan Disimpan',
        message:
            'API key dan konfigurasi model berhasil disimpan secara lokal.',
      );
    } catch (error) {
      _showSnack(
        title: 'Gagal Menyimpan',
        message: 'Terjadi kesalahan saat menyimpan pengaturan: $error',
        isError: true,
      );
    } finally {
      isSavingApi.value = false;
    }
  }

  /// Applies a Live model preset and persists it immediately.
  Future<void> selectLiveModelPreset(String model) async {
    liveModelFocusNode.unfocus();
    liveModelController.text = model;
    await repository.updateSettings(
      AppSettingsCompanion(liveModel: drift.Value(model)),
    );
  }

  /// Applies a Scoring model preset and persists it immediately.
  Future<void> selectScoringModelPreset(String model) async {
    scoringModelFocusNode.unfocus();
    scoringModelController.text = model;
    await repository.updateSettings(
      AppSettingsCompanion(scoringModel: drift.Value(model)),
    );
  }

  /// Applies a Flashcard AI model preset and persists it immediately.
  Future<void> selectFlashcardModelPreset(String model) async {
    flashcardModelFocusNode.unfocus();
    flashcardModelController.text = model;
    await repository.updateSettings(
      AppSettingsCompanion(flashcardModel: drift.Value(model)),
    );
  }

  /// Applies a Flashcard TTS model preset and persists it immediately.
  Future<void> selectFlashcardTtsModelPreset(String model) async {
    flashcardTtsModelFocusNode.unfocus();
    flashcardTtsModelController.text = model;
    await repository.updateSettings(
      AppSettingsCompanion(flashcardTtsModel: drift.Value(model)),
    );
    _resetTtsCooldownIfRegistered();
  }

  /// Fetches active models for the entered API key and auto-heals deprecated IDs.
  Future<void> loadModelsFromApiKey({bool showSnackFeedback = true}) async {
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      modelFetchSuccess.value = false;
      modelFetchMessage.value =
          'API key Gemini masih kosong. Isi API key di atas terlebih dahulu.';
      if (showSnackFeedback) {
        _showSnack(
          title: 'API Key Kosong',
          message:
              'Silakan masukkan Gemini API Key sebelum memuat daftar model.',
          isError: true,
        );
      }
      return;
    }

    isFetchingModels.value = true;
    modelFetchMessage.value = null;
    modelFetchSuccess.value = null;

    try {
      final available = await repository.fetchAvailableModels(apiKey: apiKey);
      dynamicLiveModels.assignAll(available.liveModels);
      dynamicScoringModels.assignAll(available.scoringModels);
      dynamicTtsModels.assignAll(available.ttsModels);

      final currentLive = liveModelController.text.trim();
      final currentScoring = scoringModelController.text.trim();
      final currentFlashcard = flashcardModelController.text.trim();
      final currentTts = flashcardTtsModelController.text.trim();

      String? updatedLive;
      if (available.liveModels.isNotEmpty &&
          (currentLive.isEmpty ||
              !available.liveModels.contains(currentLive))) {
        updatedLive = available.liveModels.first;
        liveModelController.text = updatedLive;
      }

      String? updatedScoring;
      if (available.scoringModels.isNotEmpty &&
          (currentScoring.isEmpty ||
              !available.scoringModels.contains(currentScoring))) {
        updatedScoring = available.scoringModels.first;
        scoringModelController.text = updatedScoring;
      }

      String? updatedFlashcard;
      if (available.scoringModels.isNotEmpty &&
          (currentFlashcard.isEmpty ||
              !available.scoringModels.contains(currentFlashcard))) {
        updatedFlashcard = available.scoringModels.first;
        flashcardModelController.text = updatedFlashcard;
      }

      String? updatedTts;
      if (available.ttsModels.isNotEmpty &&
          (currentTts.isEmpty || !available.ttsModels.contains(currentTts))) {
        updatedTts = available.ttsModels.first;
        flashcardTtsModelController.text = updatedTts;
      }

      if (updatedLive != null ||
          updatedScoring != null ||
          updatedFlashcard != null ||
          updatedTts != null) {
        await repository.updateSettings(
          AppSettingsCompanion(
            liveModel: updatedLive != null
                ? drift.Value(updatedLive)
                : const drift.Value.absent(),
            scoringModel: updatedScoring != null
                ? drift.Value(updatedScoring)
                : const drift.Value.absent(),
            flashcardModel: updatedFlashcard != null
                ? drift.Value(updatedFlashcard)
                : const drift.Value.absent(),
            flashcardTtsModel: updatedTts != null
                ? drift.Value(updatedTts)
                : const drift.Value.absent(),
          ),
        );
        if (updatedTts != null) {
          _resetTtsCooldownIfRegistered();
        }
      }

      final liveCount = available.liveModels.length;
      final scoringCount = available.scoringModels.length;
      final ttsCount = available.ttsModels.length;
      if (liveCount == 0 && scoringCount == 0 && ttsCount == 0) {
        modelFetchSuccess.value = false;
        modelFetchMessage.value =
            'Tidak ditemukan model Gemini yang aktif pada API key ini.';
      } else {
        modelFetchSuccess.value = true;
        final replacedNote =
            (updatedLive != null ||
                updatedScoring != null ||
                updatedFlashcard != null ||
                updatedTts != null)
            ? ' Model lama otomatis disesuaikan ke versi aktif.'
            : '';
        modelFetchMessage.value =
            'Ditemukan $scoringCount model Scoring/Flashcard, $liveCount model Live & $ttsCount model TTS.$replacedNote';
      }

      if (showSnackFeedback && modelFetchMessage.value != null) {
        _showSnack(
          title: 'Daftar Model Dimuat',
          message: modelFetchMessage.value!,
          isError: modelFetchSuccess.value == false,
        );
      }
    } on GeminiApiException catch (error) {
      modelFetchSuccess.value = false;
      modelFetchMessage.value = error.message;
      if (showSnackFeedback) {
        _showSnack(
          title: 'Gagal Memuat Model',
          message: error.message,
          isError: true,
        );
      }
    } catch (error) {
      modelFetchSuccess.value = false;
      modelFetchMessage.value = 'Gagal memuat daftar model: $error';
      if (showSnackFeedback) {
        _showSnack(
          title: 'Gagal Memuat Model',
          message: 'Gagal memuat daftar model: $error',
          isError: true,
        );
      }
    } finally {
      isFetchingModels.value = false;
    }
  }

  /// Tests the entered Gemini API key against the configured scoring model.
  Future<void> testGeminiConnection() async {
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      apiTestSuccess.value = false;
      apiTestResultMessage.value =
          'API key Gemini masih kosong. Silakan isi API key terlebih dahulu.';
      return;
    }

    final model = scoringModelController.text.trim().isNotEmpty
        ? scoringModelController.text.trim()
        : GeminiConstants.defaultScoringModel;

    isTestingApi.value = true;
    apiTestResultMessage.value = null;
    apiTestSuccess.value = null;

    try {
      final reply = await repository.testApiKey(apiKey: apiKey, model: model);
      apiTestSuccess.value = true;
      apiTestResultMessage.value =
          'Koneksi berhasil! Model "$model" merespons: "$reply"';
    } on GeminiApiException catch (error) {
      if (error.statusCode == 404 && dynamicScoringModels.isEmpty) {
        await loadModelsFromApiKey(showSnackFeedback: false);
        final recoveredModel = scoringModelController.text.trim();
        if (dynamicScoringModels.isNotEmpty &&
            recoveredModel.isNotEmpty &&
            recoveredModel != model) {
          try {
            final reply = await repository.testApiKey(
              apiKey: apiKey,
              model: recoveredModel,
            );
            apiTestSuccess.value = true;
            apiTestResultMessage.value =
                'Model "$model" tidak tersedia (404), otomatis beralih ke "$recoveredModel". Koneksi berhasil: "$reply"';
            return;
          } on GeminiApiException catch (retryError) {
            apiTestSuccess.value = false;
            apiTestResultMessage.value = retryError.message;
            return;
          }
        }
      }

      apiTestSuccess.value = false;
      if (error.statusCode == 404) {
        apiTestResultMessage.value =
            '${error.message} Tekan tombol "Muat Model dari API Key" di bagian Konfigurasi Model untuk memilih model yang tersedia.';
      } else {
        apiTestResultMessage.value = error.message;
      }
    } catch (error) {
      apiTestSuccess.value = false;
      apiTestResultMessage.value = 'Gagal menguji koneksi Gemini: $error';
    } finally {
      isTestingApi.value = false;
    }
  }

  /// Verifies microphone permission and plays a 440Hz test tone via Android speaker.
  Future<void> testAudioHardware() async {
    isTestingAudio.value = true;
    audioTestMessage.value = null;
    audioTestSuccess.value = null;

    try {
      final permission = await audioService
          .checkAndRequestMicrophonePermission();
      if (permission == MicrophonePermissionStatus.permanentlyDenied) {
        audioTestSuccess.value = false;
        audioTestResultMessageForPermissionDenied();
        await _showPermissionSettingsDialog();
        return;
      }

      if (permission == MicrophonePermissionStatus.denied) {
        audioTestSuccess.value = false;
        audioTestMessage.value =
            'Izin mikrofon ditolak. Aktifkan izin mikrofon untuk latihan berbicara.';
        return;
      }

      await audioService.initPlayer();
      await audioService.playTestBeep();

      audioTestSuccess.value = true;
      audioTestMessage.value =
          'Mikrofon aktif dan nada uji 440 Hz berhasil diputar melalui speaker.';
    } catch (error) {
      audioTestSuccess.value = false;
      audioTestMessage.value = 'Gagal menguji perangkat audio: $error';
    } finally {
      isTestingAudio.value = false;
    }
  }

  void audioTestResultMessageForPermissionDenied() {
    audioTestMessage.value =
        'Izin mikrofon diblokir permanen. Buka Pengaturan Perangkat untuk mengizinkannya.';
  }

  Future<void> toggleBilingualBeginner(bool value) async {
    await repository.updateSettings(
      AppSettingsCompanion(bilingualBeginnerSupport: drift.Value(value)),
    );
  }

  Future<void> toggleDarkMode(bool value) async {
    await repository.updateSettings(
      AppSettingsCompanion(darkMode: drift.Value(value)),
    );
    _lastAppliedDarkMode = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleUnlockAllOverride(bool value) async {
    if (!value) {
      await repository.updateSettings(
        const AppSettingsCompanion(unlockAllOverride: drift.Value(false)),
      );
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Aktifkan Unlock All Misi?'),
        content: const Text(
          'Semua level dan pelajaran (A1–C2) akan langsung bisa diakses tanpa menyelesaikan misi sebelumnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await repository.updateSettings(
        const AppSettingsCompanion(unlockAllOverride: drift.Value(true)),
      );
    }
  }

  /// Exports local curriculum progress, history, mistakes, and vocab to a JSON file
  /// and opens the Android share sheet.
  Future<void> exportBackup() async {
    isExportingBackup.value = true;
    try {
      final payload = await repository.exportBackupJson();
      final encoded = const JsonEncoder.withIndent('  ').convert(payload);

      final now = DateTime.now();
      final timestamp =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}${Platform.pathSeparator}my_english_tutor_backup_$timestamp.json',
      );
      await file.writeAsString(encoded, encoding: utf8);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'application/json')],
          text: 'Backup progress My English Tutor ($timestamp)',
          subject: 'My English Tutor Backup',
        ),
      );
    } catch (error) {
      _showSnack(
        title: 'Gagal Export Backup',
        message: 'Tidak dapat mengekspor data backup: $error',
        isError: true,
      );
    } finally {
      isExportingBackup.value = false;
    }
  }

  /// Picks a `.json` backup file, validates its schema, confirms overwrite,
  /// and restores data into Drift while keeping the local API key intact.
  Future<void> importBackup() async {
    isImportingBackup.value = true;
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Pilih File Backup JSON',
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final rawJson = utf8.decode(bytes);

      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic> ||
          decoded['levels'] is! List ||
          (decoded['levels'] as List).isEmpty ||
          decoded['lessons'] is! List) {
        throw const FormatException(
          'Format file backup tidak valid. Pastikan file berasal dari Export Backup aplikasi ini.',
        );
      }

      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Restore Backup JSON?'),
          content: const Text(
            'Progress belajar, riwayat sesi, catatan kesalahan, dan kosakata saat ini akan digantikan oleh file backup. API Key Gemini Anda tetap aman dipertahankan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      await repository.importBackupJson(decoded);
      _hasInitializedFields = false;

      _showSnack(
        title: 'Restore Berhasil',
        message: 'Data progress belajar berhasil dipulihkan dari backup.',
      );
    } on FormatException catch (error) {
      _showSnack(
        title: 'File Backup Tidak Valid',
        message: error.message,
        isError: true,
      );
    } catch (error) {
      _showSnack(
        title: 'Gagal Import Backup',
        message: 'Tidak dapat memulihkan backup: $error',
        isError: true,
      );
    } finally {
      isImportingBackup.value = false;
    }
  }

  /// Resets all learning progress, sessions, mistakes, vocab, and streak after confirmation.
  Future<void> resetAllProgress() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reset Progress Belajar?'),
        content: const Text(
          'Hapus semua progress, skor, kosakata, catatan kesalahan, & streak? API Key tidak akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Reset Progress'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await repository.resetProgress();
      _showSnack(
        title: 'Progress Direset',
        message:
            'Semua progress belajar kembali ke awal (A1 Lesson 1). API Key Anda tetap tersimpan.',
      );
    } catch (error) {
      _showSnack(
        title: 'Gagal Reset',
        message: 'Tidak dapat mereset progress: $error',
        isError: true,
      );
    }
  }

  Future<void> _showPermissionSettingsDialog() async {
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('Izin Mikrofon Diperlukan'),
        content: const Text(
          'Akses mikrofon diblokir permanen di Android. Silakan buka Pengaturan Aplikasi dan aktifkan izin Mikrofon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () async {
              Get.back<void>();
              await audioService.openDeviceAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _showSnack({
    required String title,
    required String message,
    bool isError = false,
  }) {
    final colorScheme = Get.theme.colorScheme;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: isError
          ? colorScheme.errorContainer
          : colorScheme.primaryContainer,
      colorText: isError
          ? colorScheme.onErrorContainer
          : colorScheme.onPrimaryContainer,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    _settingsSub?.cancel();
    apiKeyController.dispose();
    liveModelController.dispose();
    scoringModelController.dispose();
    flashcardModelController.dispose();
    flashcardTtsModelController.dispose();
    apiKeyFocusNode.dispose();
    liveModelFocusNode.dispose();
    scoringModelFocusNode.dispose();
    flashcardModelFocusNode.dispose();
    flashcardTtsModelFocusNode.dispose();
    super.onClose();
  }
}
