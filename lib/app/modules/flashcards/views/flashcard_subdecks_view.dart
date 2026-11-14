import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_state_widgets.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../controllers/flashcard_subdecks_controller.dart';
import '../widgets/flashcard_dialogs.dart';
import '../widgets/flashcard_progress_circle.dart';

class FlashcardSubDecksView extends GetView<FlashcardSubDecksController> {
  const FlashcardSubDecksView({super.key});

  Future<void> _openCreateSubDeckDialog(BuildContext context) async {
    final input = await showFlashcardNamedInputDialog(
      context: context,
      title: 'Buat Sub-Deck Baru',
      nameLabel: 'Nama Sub-Deck',
      nameHint: 'Contoh: Business 1',
      showDescription: true,
      confirmLabel: 'Buat Sub-Deck',
    );
    if (input == null) return;
    await controller.createSubDeck(input.name, description: input.description);
  }

  Future<void> _openSubDeckActionsSheet(
    BuildContext context,
    SubDeckWithStats stats,
  ) async {
    final subDeck = stats.subDeck;
    final action = await showFlashcardEntityActionsSheet(
      context: context,
      title: subDeck.name,
      subtitle: '${stats.cardCount} Kata di ${controller.deckTitle}',
      openLabel: 'Buka Sub-Deck',
      openIcon: Icons.style_outlined,
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case FlashcardEntityAction.open:
        controller.openSubDeck(subDeck);
      case FlashcardEntityAction.quiz:
        await controller.startSubDeckQuiz(subDeck);
      case FlashcardEntityAction.rename:
        final input = await showFlashcardNamedInputDialog(
          context: context,
          title: 'Ganti Nama Sub-Deck',
          nameLabel: 'Nama Sub-Deck Baru',
          nameHint: 'Contoh: Business 1',
          initialName: subDeck.name,
          confirmLabel: 'Simpan',
        );
        if (input != null) {
          await controller.renameSubDeck(subDeck, input.name);
        }
      case FlashcardEntityAction.delete:
        final confirmed = await showFlashcardConfirmDeleteDialog(
          context: context,
          title: 'Hapus Sub-Deck "${subDeck.name}"?',
          message:
              'Semua flashcard (${stats.cardCount}) di dalam sub-deck ini akan ikut terhapus permanen.',
        );
        if (confirmed) {
          await controller.deleteSubDeck(subDeck);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.deckTitle,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: controller.deck == null
                  ? null
                  : () => _openCreateSubDeckDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Sub-Deck'),
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        if (controller.isLoading.value ||
            controller.deck == null ||
            controller.subDecks.isEmpty) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          onPressed: () => _openCreateSubDeckDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Sub-Deck'),
        );
      }),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingView(message: 'Memuat daftar sub-deck...');
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return AppErrorView(
            message: error,
            onRetry: controller.deck == null ? null : controller.retryLoad,
          );
        }

        if (controller.subDecks.isEmpty) {
          return AppEmptyView(
            icon: Icons.library_books_outlined,
            title: 'Belum Ada Sub-Deck',
            subtitle:
                'Buat sub-deck di "${controller.deckTitle}", misalnya "Business 1" atau "Business 2", untuk menyimpan flashcard kata.',
            actionLabel: 'Buat Sub-Deck Pertama',
            onAction: () => _openCreateSubDeckDialog(context),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: controller.subDecks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final stats = controller.subDecks[index];
            return _SubDeckCard(
              stats: stats,
              onTap: () => _openSubDeckActionsSheet(context, stats),
            );
          },
        );
      }),
    );
  }
}

class _SubDeckCard extends StatelessWidget {
  const _SubDeckCard({
    required this.stats,
    required this.onTap,
  });

  final SubDeckWithStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subDeck = stats.subDeck;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.style_rounded,
                  color: colorScheme.onSecondaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subDeck.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subDeck.description != null &&
                        subDeck.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subDeck.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${stats.cardCount} Kata',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stats.completedCardCount > 0
                                ? Colors.green.shade600.withValues(alpha: 0.14)
                                : (stats.reviewCardCount > 0
                                      ? Colors.amber.shade700.withValues(
                                          alpha: 0.14,
                                        )
                                      : colorScheme.surfaceContainerHighest),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stats.reviewCardCount > 0
                                ? '${stats.completedCardCount}/${stats.cardCount} Hafal • ${stats.reviewCardCount} Ulang'
                                : '${stats.completedCardCount}/${stats.cardCount} Hafal',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: stats.completedCardCount > 0
                                  ? (theme.brightness == Brightness.dark
                                        ? Colors.green.shade300
                                        : Colors.green.shade700)
                                  : (stats.reviewCardCount > 0
                                        ? (theme.brightness == Brightness.dark
                                              ? Colors.amber.shade300
                                              : Colors.amber.shade800)
                                        : colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FlashcardProgressCircle(
                percent: stats.progressPercent,
                hasCards: stats.cardCount > 0,
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
