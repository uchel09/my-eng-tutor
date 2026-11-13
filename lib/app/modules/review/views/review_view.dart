import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_state_widgets.dart';
import '../../../data/local/app_database.dart';
import '../controllers/review_controller.dart';

class ReviewView extends GetView<ReviewController> {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review & Kosakata'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: controller.showAddManualVocabDialog,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Kosakata'),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Vocab Bank'),
              Tab(text: 'Mistake Log'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const AppLoadingView(message: 'Memuat data review offline...');
          }

          final error = controller.errorMessage.value;
          if (error != null) {
            return AppErrorView(
              message: error,
              onRetry: controller.retryLoad,
            );
          }

          return Column(
            children: [
              _GlobalSearchBar(controller: controller),
              Expanded(
                child: TabBarView(
                  children: [
                    _VocabBankTab(controller: controller),
                    _MistakeLogTab(controller: controller),
                    _HistoryTab(controller: controller),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _GlobalSearchBar extends StatelessWidget {
  const _GlobalSearchBar({required this.controller});

  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Obx(
        () => TextField(
          controller: controller.searchController,
          onChanged: controller.onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Cari kata, arti, kalimat, atau koreksi...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    tooltip: 'Hapus pencarian',
                    onPressed: controller.clearSearch,
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _VocabBankTab extends StatelessWidget {
  const _VocabBankTab({required this.controller});

  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CefrFilterStrip(controller: controller),
        Expanded(
          child: Obx(() {
            final allEmpty = controller.vocabItems.isEmpty;
            final items = controller.filteredVocab;

            if (allEmpty) {
              return AppEmptyView(
                icon: Icons.menu_book_rounded,
                title: 'Vocab Bank Masih Kosong',
                subtitle:
                    'Kosakata baru dari sesi AI atau input manualmu akan muncul di sini.',
                actionLabel: 'Tambah Kosakata',
                onAction: controller.showAddManualVocabDialog,
              );
            }

            if (items.isEmpty) {
              return const AppEmptyView(
                icon: Icons.search_off_rounded,
                title: 'Kosakata Tidak Ditemukan',
                subtitle:
                    'Coba ubah kata kunci pencarian atau pilih filter CEFR lain.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _VocabCard(
                  item: items[index],
                  onMarkMastered: () =>
                      controller.markVocabMastered(items[index].id),
                  onDelete: () => controller.deleteVocab(items[index].id),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _CefrFilterStrip extends StatelessWidget {
  const _CefrFilterStrip({required this.controller});

  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Obx(() {
        final selected = controller.selectedCefrFilter.value;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          scrollDirection: Axis.horizontal,
          itemCount: ReviewController.cefrFilterOptions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final option = ReviewController.cefrFilterOptions[index];
            return ChoiceChip(
              label: Text(option == 'ALL' ? 'Semua' : option),
              selected: selected == option,
              onSelected: (_) => controller.selectCefrFilter(option),
            );
          },
        );
      }),
    );
  }
}

class _VocabCard extends StatelessWidget {
  const _VocabCard({
    required this.item,
    required this.onMarkMastered,
    required this.onDelete,
  });

  final VocabItem item;
  final VoidCallback onMarkMastered;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    item.word,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.cefrLevel.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Hapus kosakata',
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.meaningId,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (item.exampleSentence.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '"${item.exampleSentence}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Mastered ${item.masteryCount}x',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: onMarkMastered,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Hafal +1'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MistakeLogTab extends StatelessWidget {
  const _MistakeLogTab({required this.controller});

  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allEmpty = controller.mistakes.isEmpty;
      final groups = controller.groupedMistakesByDay;

      if (allEmpty) {
        return const AppEmptyView(
          icon: Icons.spellcheck_rounded,
          title: 'Belum Ada Catatan Kesalahan',
          subtitle:
              'Koreksi grammar, diksi, dan pelafalan dari sesi latihanmu akan terkumpul di sini.',
        );
      }

      if (groups.isEmpty) {
        return const AppEmptyView(
          icon: Icons.search_off_rounded,
          title: 'Catatan Tidak Ditemukan',
          subtitle: 'Coba gunakan kata kunci pencarian lain.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final group = groups[index];
          final isExpanded = controller.isMistakeDayExpanded(group.dayKey);
          return _MistakeDaySection(
            group: group,
            isExpanded: isExpanded,
            controller: controller,
          );
        },
      );
    });
  }
}

class _MistakeDaySection extends StatelessWidget {
  const _MistakeDaySection({
    required this.group,
    required this.isExpanded,
    required this.controller,
  });

  final MistakeDayGroup group;
  final bool isExpanded;
  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => controller.toggleMistakeDay(group.dayKey),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.dayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${group.items.length} catatan',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, itemIndex) {
              final mistake = group.items[itemIndex];
              return _MistakeCard(
                mistake: mistake,
                dateLabel: controller.formatTimeOnly(mistake.createdAt),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({
    required this.mistake,
    required this.dateLabel,
  });

  final Mistake mistake;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mistake.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalimatmu',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mistake.originalSentence,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perbaikan Lebih Natural',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mistake.correctedSentence,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            if (mistake.explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                mistake.explanation,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.controller});

  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.sessions;
      if (items.isEmpty) {
        return const AppEmptyView(
          icon: Icons.history_rounded,
          title: 'Belum Ada Riwayat Sesi',
          subtitle:
              'Selesaikan latihan bicara pertamamu untuk melihat rapor skor dan transkrip di sini.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final session = items[index];
          return _HistorySessionCard(
            title: controller.resolveSessionTitle(session),
            typeLabel: controller.sessionTypeLabel(session.sessionType),
            dateLabel: controller.formatSessionDate(session.startedAt),
            durationLabel: controller.formatDuration(session.durationSec),
            score: session.overallScore,
            passed: session.passed,
            onTap: () => controller.openSessionDetail(session),
          );
        },
      );
    });
  }
}

class _HistorySessionCard extends StatelessWidget {
  const _HistorySessionCard({
    required this.title,
    required this.typeLabel,
    required this.dateLabel,
    required this.durationLabel,
    required this.score,
    required this.passed,
    required this.onTap,
  });

  final String title;
  final String typeLabel;
  final String dateLabel;
  final String durationLabel;
  final int score;
  final bool passed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final badgeBg = passed
        ? colorScheme.secondaryContainer
        : colorScheme.tertiaryContainer;
    final badgeFg = passed
        ? colorScheme.onSecondaryContainer
        : colorScheme.onTertiaryContainer;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          durationLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$score/100',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: badgeFg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
