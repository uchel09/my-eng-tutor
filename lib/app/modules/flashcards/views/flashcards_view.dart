import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_state_widgets.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../controllers/flashcards_controller.dart';
import '../widgets/flashcard_dialogs.dart';

class FlashcardsView extends GetView<FlashcardsController> {
  const FlashcardsView({super.key});

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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _openCreateDeckDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Buat Deck'),
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
          return AppErrorView(
            message: error,
            onRetry: controller.retryLoad,
          );
        }

        if (controller.decks.isEmpty) {
          return AppEmptyView(
            icon: Icons.style_outlined,
            title: 'Belum Ada Deck Flashcard',
            subtitle:
                'Kelompokkan kosakatamu secara rapi ke dalam Deck dan Sub-Deck, misalnya "Business Word".',
            actionLabel: 'Buat Deck Pertama',
            onAction: () => _openCreateDeckDialog(context),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: controller.decks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final stats = controller.decks[index];
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
  const _DeckCard({
    required this.stats,
    required this.onTap,
  });

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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.folder_copy_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
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
                      spacing: 8,
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
                      ],
                    ),
                  ],
                ),
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
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
