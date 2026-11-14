import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/flashcards_controller.dart';
import '../models/daily_vocab_curriculum.dart';

/// Opens a scrollable ModalBottomSheet for downloading curated CEFR Daily Vocab packs.
Future<void> showFlashcardPackDownloadSheet({
  required BuildContext context,
  required FlashcardsController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return _FlashcardPackDownloadSheet(controller: controller);
    },
  );
}

class _FlashcardPackDownloadSheet extends StatelessWidget {
  const _FlashcardPackDownloadSheet({required this.controller});

  final FlashcardsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Obx(() {
          final isDownloading = controller.isDownloadingPack.value;
          final isPaused = controller.isDownloadPaused.value;
          final current = controller.packProgressCurrent.value;
          final total = controller.packProgressTotal.value;
          final inserted = controller.packInsertedCards.value;
          final statusText = controller.packStatusText.value;
          final errorText = controller.packErrorMessage.value;
          final showProgressPanel =
              isDownloading ||
              isPaused ||
              total > 0 ||
              statusText.isNotEmpty ||
              errorText != null;

          final double? progressValue = total > 0
              ? (current / total).clamp(0.0, 1.0)
              : (isDownloading ? null : 0.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cloud_download_outlined,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unduh Paket Kosakata Harian (AI)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '4 Level CEFR (A1–B2) • 48 Sub-Deck Topik',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Setiap kartu hanya mengunduh Kata, Fonetik IPA, Arti Indonesia, '
                  'dan Multi-POS agar hemat kuota & cepat tersimpan. '
                  'Contoh kalimat & dialog tetap ringan dan bisa dibuat kapan saja lewat "Lengkapi dengan AI".',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              if (showProgressPanel) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              total > 0
                                  ? 'Topik $current / $total'
                                  : 'Memproses...',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '+$inserted kata tersimpan',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: progressValue,
                        ),
                      ),
                      if (statusText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          statusText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (errorText != null && errorText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            errorText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                      if (isDownloading || isPaused) ...[
                        const SizedBox(height: 10),
                        if (isDownloading)
                          FilledButton.tonalIcon(
                            onPressed: controller.pauseCurriculumDownload,
                            icon: const Icon(Icons.pause_rounded, size: 18),
                            label: const Text('Jeda / Hentikan'),
                          )
                        else
                          FilledButton.icon(
                            onPressed: controller.resumeCurriculumDownload,
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: const Text('Lanjutkan Unduhan'),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Pilih Paket yang Akan Diunduh',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: isDownloading
                    ? null
                    : () => controller.downloadCurriculumPack(),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Semua Level (~2.400 Kata)'),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final tileWidth = (constraints.maxWidth - spacing) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: DailyVocabCurriculum.levels
                        .map((level) {
                          return SizedBox(
                            width: tileWidth,
                            child: OutlinedButton(
                              onPressed: isDownloading
                                  ? null
                                  : () => controller.downloadCurriculumPack(
                                      cefrLevelFilter: level.cefrLevel,
                                    ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 12,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    level.shortLabel,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '12 Topik • ~600 Kata',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  );
                },
              ),
            ],
          );
        }),
      ),
    );
  }
}
