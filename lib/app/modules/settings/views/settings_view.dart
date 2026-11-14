import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/gemini_constants.dart';
import '../../../core/widgets/app_state_widgets.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Obx(() {
        final currentSettings = controller.settings.value;
        if (currentSettings == null) {
          return const AppLoadingView(message: 'Memuat pengaturan...');
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildApiKeySection(theme, colorScheme),
            const SizedBox(height: 16),
            _buildModelAndTutorSection(
              theme,
              colorScheme,
              bilingualSupport: currentSettings.bilingualBeginnerSupport,
            ),
            const SizedBox(height: 16),
            _buildAudioSection(theme, colorScheme),
            const SizedBox(height: 16),
            _buildAppearanceAndModeSection(
              theme,
              colorScheme,
              darkMode: currentSettings.darkMode,
              unlockAllOverride: currentSettings.unlockAllOverride,
            ),
            const SizedBox(height: 16),
            _buildBackupSection(theme, colorScheme),
          ],
        );
      }),
    );
  }

  Widget _buildApiKeySection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.key_rounded,
              title: '1. Gemini API Key (Free Tier)',
              subtitle:
                  'Buat API key gratis di Google AI Studio (aistudio.google.com), lalu tempel di bawah ini. Disimpan hanya di perangkat Anda.',
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 14),
            Obx(
              () => TextField(
                controller: controller.apiKeyController,
                focusNode: controller.apiKeyFocusNode,
                obscureText: controller.isObscureApiKey.value,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIzaSy...',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(
                    tooltip: controller.isObscureApiKey.value
                        ? 'Tampilkan API key'
                        : 'Sembunyikan API key',
                    onPressed: controller.toggleApiKeyVisibility,
                    icon: Icon(
                      controller.isObscureApiKey.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.isSavingApi.value
                          ? null
                          : controller.saveApiAndModelSettings,
                      icon: controller.isSavingApi.value
                          ? const _SmallButtonSpinner()
                          : const Icon(Icons.save_outlined),
                      label: const Text('Simpan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.isTestingApi.value
                          ? null
                          : controller.testGeminiConnection,
                      icon: controller.isTestingApi.value
                          ? const _SmallButtonSpinner()
                          : const Icon(Icons.wifi_tethering_rounded),
                      label: const Text('Tes Koneksi'),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              final message = controller.apiTestResultMessage.value;
              final isSuccess = controller.apiTestSuccess.value;
              if (message == null || isSuccess == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _StatusBanner(
                  message: message,
                  isSuccess: isSuccess,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModelAndTutorSection(
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool bilingualSupport,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.tune_rounded,
              title: '2. Konfigurasi Model & Tutor',
              subtitle:
                  'Pilih preset model Gemini atau muat daftar model aktif langsung dari API key Anda.',
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 14),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: controller.isFetchingModels.value
                      ? null
                      : () => controller.loadModelsFromApiKey(),
                  icon: controller.isFetchingModels.value
                      ? const _SmallButtonSpinner()
                      : const Icon(Icons.cloud_download_outlined),
                  label: Text(
                    controller.isFetchingModels.value
                        ? 'Memuat Model...'
                        : 'Muat Model dari API Key',
                  ),
                ),
              ),
            ),
            Obx(() {
              final message = controller.modelFetchMessage.value;
              final isSuccess = controller.modelFetchSuccess.value;
              if (message == null || isSuccess == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _StatusBanner(
                  message: message,
                  isSuccess: isSuccess,
                ),
              );
            }),
            const SizedBox(height: 14),
            Text(
              'Live Audio Model (WebSocket)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final selected = controller.activeLiveModelText.value;
              final options = controller.dynamicLiveModels.isNotEmpty
                  ? controller.dynamicLiveModels
                  : GeminiConstants.liveModelOptions;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((model) {
                  return ChoiceChip(
                    label: Text(model),
                    selected: selected == model,
                    onSelected: (_) => controller.selectLiveModelPreset(model),
                  );
                }).toList(growable: false),
              );
            }),
            const SizedBox(height: 10),
            TextField(
              controller: controller.liveModelController,
              focusNode: controller.liveModelFocusNode,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Custom Live Model ID',
                hintText: GeminiConstants.defaultLiveModel,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scoring Model (REST Evaluasi)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final selected = controller.activeScoringModelText.value;
              final options = controller.dynamicScoringModels.isNotEmpty
                  ? controller.dynamicScoringModels
                  : GeminiConstants.scoringModelOptions;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((model) {
                  return ChoiceChip(
                    label: Text(model),
                    selected: selected == model,
                    onSelected: (_) =>
                        controller.selectScoringModelPreset(model),
                  );
                }).toList(growable: false),
              );
            }),
            const SizedBox(height: 10),
            TextField(
              controller: controller.scoringModelController,
              focusNode: controller.scoringModelFocusNode,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Custom Scoring Model ID',
                hintText: GeminiConstants.defaultScoringModel,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Flashcard AI Model (Kalimat, Kuis & Pelafalan)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final selected = controller.activeFlashcardModelText.value;
              final options = controller.dynamicScoringModels.isNotEmpty
                  ? controller.dynamicScoringModels
                  : GeminiConstants.scoringModelOptions;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((model) {
                  return ChoiceChip(
                    label: Text(model),
                    selected: selected == model,
                    onSelected: (_) =>
                        controller.selectFlashcardModelPreset(model),
                  );
                }).toList(growable: false),
              );
            }),
            const SizedBox(height: 10),
            TextField(
              controller: controller.flashcardModelController,
              focusNode: controller.flashcardModelFocusNode,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Custom Flashcard AI Model ID',
                hintText: GeminiConstants.defaultFlashcardModel,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Flashcard TTS Model (Live API)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Suara AI yang sudah pernah diputar (kata, mode lambat, contoh kalimat, dialog & kuis) otomatis disimpan sebagai file audio .wav di folder aplikasi agar tetap aman saat aplikasi ditutup, hemat kuota, bisa diputar offline, dan ikut terhapus bersih saat aplikasi di-uninstall. Otomatis beralih ke suara perangkat (flutter_tts) jika offline atau kuota habis.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final selected = controller.activeFlashcardTtsModelText.value;
              final options = controller.dynamicTtsModels.isNotEmpty
                  ? controller.dynamicTtsModels
                  : GeminiConstants.ttsModelOptions;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((model) {
                  return ChoiceChip(
                    label: Text(model),
                    selected: selected == model,
                    onSelected: (_) =>
                        controller.selectFlashcardTtsModelPreset(model),
                  );
                }).toList(growable: false),
              );
            }),
            const SizedBox(height: 10),
            TextField(
              controller: controller.flashcardTtsModelController,
              focusNode: controller.flashcardTtsModelFocusNode,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Custom Flashcard TTS Model ID',
                hintText: GeminiConstants.defaultTtsModel,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: controller.isSavingApi.value
                    ? null
                    : controller.saveApiAndModelSettings,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Simpan Model Kustom'),
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.isTestingFlashcardTts.value
                      ? null
                      : controller.testFlashcardTts,
                  icon: controller.isTestingFlashcardTts.value
                      ? const _SmallButtonSpinner()
                      : const Icon(Icons.volume_up_rounded),
                  label: const Text('Tes Suara Flashcard AI'),
                ),
              ),
            ),
            Obx(() {
              final message = controller.flashcardTtsTestMessage.value;
              final isSuccess = controller.flashcardTtsTestSuccess.value;
              if (message == null || isSuccess == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _StatusBanner(
                  message: message,
                  isSuccess: isSuccess,
                ),
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              final count = controller.savedAudioFileCount.value;
              final isBusy = controller.isClearingSavedAudio.value;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.audio_file_outlined,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.savedAudioSummaryText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tersimpan di folder aplikasi (my_english_tutor_audio) untuk pemutaran offline.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isBusy || count == 0
                            ? null
                            : controller.clearSavedAudioFiles,
                        icon: isBusy
                            ? const _SmallButtonSpinner()
                            : const Icon(Icons.delete_outline_rounded),
                        label: const Text('Hapus Audio Tersimpan'),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bantuan Bahasa Indonesia (Level A1–A2)'),
              subtitle: const Text(
                'Tampilkan penjelasan koreksi dan ringkasan AI dalam Bahasa Indonesia untuk pemula.',
              ),
              value: bilingualSupport,
              onChanged: controller.toggleBilingualBeginner,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.mic_none_rounded,
              title: '3. Perangkat Audio Android',
              subtitle:
                  'Pastikan izin mikrofon aktif dan speaker dapat memutar suara PCM 24kHz.',
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 14),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.isTestingAudio.value
                      ? null
                      : controller.testAudioHardware,
                  icon: controller.isTestingAudio.value
                      ? const _SmallButtonSpinner()
                      : const Icon(Icons.volume_up_outlined),
                  label: const Text('Tes Mic & Speaker'),
                ),
              ),
            ),
            Obx(() {
              final message = controller.audioTestMessage.value;
              final isSuccess = controller.audioTestSuccess.value;
              if (message == null || isSuccess == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _StatusBanner(
                  message: message,
                  isSuccess: isSuccess,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceAndModeSection(
    ThemeData theme,
    ColorScheme colorScheme, {
    required bool darkMode,
    required bool unlockAllOverride,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.palette_outlined,
              title: '4. Tampilan & Mode Belajar',
              subtitle:
                  'Atur tema tampilan, akses bebas semua level, atau reset progress.',
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dark Mode'),
              subtitle: const Text('Gunakan tampilan gelap yang nyaman di mata.'),
              value: darkMode,
              onChanged: controller.toggleDarkMode,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Unlock All Misi (Mode Bebas)'),
              subtitle: const Text(
                'Buka seluruh level A1–C2 tanpa harus lulus berurutan.',
              ),
              value: unlockAllOverride,
              onChanged: controller.toggleUnlockAllOverride,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                ),
                onPressed: controller.resetAllProgress,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Reset Progress Belajar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              icon: Icons.backup_outlined,
              title: '5. Backup & Restore Progress',
              subtitle:
                  'Ekspor progress, skor, kosakata, & streak ke file JSON atau pulihkan dari cadangan.',
              colorScheme: colorScheme,
              theme: theme,
            ),
            const SizedBox(height: 14),
            Obx(
              () => Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: controller.isExportingBackup.value
                          ? null
                          : controller.exportBackup,
                      icon: controller.isExportingBackup.value
                          ? const _SmallButtonSpinner()
                          : const Icon(Icons.ios_share_rounded),
                      label: const Text('Export Backup JSON'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: controller.isImportingBackup.value
                          ? null
                          : controller.importBackup,
                      icon: controller.isImportingBackup.value
                          ? const _SmallButtonSpinner()
                          : const Icon(Icons.upload_file_rounded),
                      label: const Text('Import Backup JSON'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.theme,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isSuccess
        ? Colors.green.withValues(alpha: 0.12)
        : colorScheme.errorContainer;
    final fgColor = isSuccess
        ? (Theme.of(context).brightness == Brightness.dark
            ? Colors.green.shade300
            : Colors.green.shade800)
        : colorScheme.onErrorContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fgColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            size: 18,
            color: fgColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButtonSpinner extends StatelessWidget {
  const _SmallButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
