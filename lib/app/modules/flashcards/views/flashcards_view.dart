import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_state_widgets.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../controllers/flashcards_controller.dart';
import '../widgets/flashcard_dialogs.dart';
import '../widgets/flashcard_pack_download_sheet.dart';
import '../widgets/flashcard_progress_circle.dart';

class FlashcardsView extends GetView<FlashcardsController> {
  const FlashcardsView({super.key});

  Future<void> _openDownloadPackSheet(BuildContext context) {
    return showFlashcardPackDownloadSheet(
      context: context,
      controller: controller,
    );
  }

  Future<void> _openCreateDeckDialog(BuildContext context) async {
    final input = await showFlashcardNamedInputDialog(
      context: context,
      title: 'Buat Deck Baru',
      nameLabel: 'Nama Deck',
      nameHint: 'Contoh: Business Word',
      showDescription: true,
      confirmLabel: 'Buat Deck',
    );
    if (input == null) return;
    await controller.createDeck(input.name, description: input.description);
  }

  Future<void> _openDeckActionsSheet(
    BuildContext context,
    DeckWithStats stats,
  ) async {
    final deck = stats.deck;
    final action = await showFlashcardEntityActionsSheet(
      context: context,
      title: deck.name,
      subtitle: '${stats.subDeckCount} Sub-Deck • ${stats.totalCardCount} Kata',
      openLabel: 'Buka Deck',
      openIcon: Icons.folder_open_rounded,
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case FlashcardEntityAction.open:
        controller.openDeck(deck);
      case FlashcardEntityAction.quiz:
        await controller.startDeckQuiz(deck);
      case FlashcardEntityAction.freeTalk:
        break;
      case FlashcardEntityAction.rename:
        final input = await showFlashcardNamedInputDialog(
          context: context,
          title: 'Ganti Nama Deck',
          nameLabel: 'Nama Deck Baru',
          nameHint: 'Contoh: Business Word',
          initialName: deck.name,
          confirmLabel: 'Simpan',
        );
        if (input != null) {
          await controller.renameDeck(deck, input.name);
        }
      case FlashcardEntityAction.delete:
        final confirmed = await showFlashcardConfirmDeleteDialog(
          context: context,
          title: 'Hapus Deck "${deck.name}"?',
          message:
              'Seluruh sub-deck (${stats.subDeckCount}) dan semua flashcard (${stats.totalCardCount}) di dalamnya akan ikut terhapus permanen.',
        );
        if (confirmed) {
          await controller.deleteDeck(deck);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          TextButton.icon(
            onPressed: () => _openDownloadPackSheet(context),
            icon: const Icon(Icons.cloud_download_outlined, size: 18),
            label: const Text('Unduh Paket'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              tooltip: 'Buat Deck',
              onPressed: () => _openCreateDeckDialog(context),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        if (controller.isLoading.value || controller.decks.isEmpty) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          onPressed: () => _openCreateDeckDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Buat Deck'),
        );
      }),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingView(message: 'Memuat deck flashcard...');
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return AppErrorView(message: error, onRetry: controller.retryLoad);
        }

        if (controller.decks.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.style_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Deck Flashcard',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelompokkan kosakatamu secara rapi ke dalam Deck dan Sub-Deck, atau unduh paket 2.400 kata harian AI sekaligus.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openCreateDeckDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Buat Deck Pertama'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openDownloadPackSheet(context),
                        icon: const Icon(
                          Icons.cloud_download_outlined,
                          size: 18,
                        ),
                        label: const Text('Unduh Paket Kosakata'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: controller.decks.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _PackDownloadBannerCard(
                controller: controller,
                onOpenSheet: () => _openDownloadPackSheet(context),
              );
            }
            final stats = controller.decks[index - 1];
            return _DeckCard(
              stats: stats,
              onTap: () => _openDeckActionsSheet(context, stats),
            );
          },
        );
      }),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.stats, required this.onTap});

  final DeckWithStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final deck = stats.deck;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_copy_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (deck.description != null &&
                        deck.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        deck.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _CountBadge(
                          icon: Icons.folder_outlined,
                          label: '${stats.subDeckCount} Sub-Deck',
                          backgroundColor: colorScheme.secondaryContainer,
                          foregroundColor: colorScheme.onSecondaryContainer,
                        ),
                        _CountBadge(
                          icon: Icons.style_outlined,
                          label: '${stats.totalCardCount} Kata',
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurface,
                        ),
                        _CountBadge(
                          icon: Icons.check_circle_outline_rounded,
                          label: stats.reviewCardCount > 0
                              ? '${stats.completedCardCount}/${stats.totalCardCount} Hafal • ${stats.reviewCardCount} Ulang'
                              : '${stats.completedCardCount}/${stats.totalCardCount} Hafal',
                          backgroundColor: stats.completedCardCount > 0
                              ? Colors.green.shade600.withValues(alpha: 0.14)
                              : (stats.reviewCardCount > 0
                                    ? Colors.amber.shade700.withValues(
                                        alpha: 0.14,
                                      )
                                    : colorScheme.surfaceContainerHighest),
                          foregroundColor: stats.completedCardCount > 0
                              ? (theme.brightness == Brightness.dark
                                    ? Colors.green.shade300
                                    : Colors.green.shade700)
                              : (stats.reviewCardCount > 0
                                    ? (theme.brightness == Brightness.dark
                                          ? Colors.amber.shade300
                                          : Colors.amber.shade800)
                                    : colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FlashcardProgressCircle(
                percent: stats.progressPercent,
                hasCards: stats.totalCardCount > 0,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.more_vert_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackDownloadBannerCard extends StatelessWidget {
  const _PackDownloadBannerCard({
    required this.controller,
    required this.onOpenSheet,
  });

  final FlashcardsController controller;
  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final isDownloading = controller.isDownloadingPack.value;
      final isPaused = controller.isDownloadPaused.value;
      final current = controller.packProgressCurrent.value;
      final total = controller.packProgressTotal.value;
      final inserted = controller.packInsertedCards.value;
      final double? progress = total > 0
          ? (current / total).clamp(0.0, 1.0)
          : null;

      return Card(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpenSheet,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_download_outlined,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paket Kosakata Harian (AI)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isDownloading || isPaused
                                ? 'Topik $current/$total • +$inserted kata tersimpan'
                                : 'Kurikulum tetap 4 Level (A1–B2) • 2.400 kata',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isDownloading)
                      IconButton.filledTonal(
                        tooltip: 'Jeda unduhan',
                        onPressed: controller.pauseCurriculumDownload,
                        icon: const Icon(Icons.pause_rounded, size: 18),
                      )
                    else if (isPaused)
                      FilledButton.tonal(
                        onPressed: controller.resumeCurriculumDownload,
                        child: const Text('Lanjutkan'),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
                if (isDownloading || isPaused) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: progress,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
