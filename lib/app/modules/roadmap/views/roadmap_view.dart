import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_state_widgets.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/roadmap_dao.dart';
import '../controllers/roadmap_controller.dart';

class RoadmapView extends GetView<RoadmapController> {
  const RoadmapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Belajar A1–C2'),
        actions: [
          Obx(() {
            if (!controller.isUnlockAllActive) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  Icons.lock_open_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                label: const Text('Unlock All'),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingView(message: 'Memuat peta belajar A1–C2...');
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return AppErrorView(
            message: error,
            onRetry: controller.retryLoad,
          );
        }

        if (controller.levels.isEmpty) {
          return const AppEmptyView(
            icon: Icons.route_rounded,
            title: 'Kurikulum Belum Tersedia',
            subtitle: 'Data level A1–C2 belum ditemukan di database lokal.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          itemCount: controller.levels.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final group = controller.levels[index];
            return _LevelSectionCard(
              group: group,
              controller: controller,
            );
          },
        );
      }),
    );
  }
}

class _LevelSectionCard extends StatelessWidget {
  const _LevelSectionCard({
    required this.group,
    required this.controller,
  });

  final LevelWithLessons group;
  final RoadmapController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final level = group.level;
    final isLevelOpen = level.isUnlocked || controller.isUnlockAllActive;
    final completedCount = group.lessons.where((l) => l.isCompleted).length;
    final progress = controller.levelProgress(group);

    return Card(
      child: Obx(() {
        final isExpanded = controller.isLevelExpanded(level.id);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => controller.toggleLevelExpanded(level.id),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isLevelOpen
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            level.code,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isLevelOpen
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      level.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (!isLevelOpen)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.lock_rounded,
                                        size: 18,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                level.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$completedCount/${group.lessons.length}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 14),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.lessons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final lesson = group.lessons[index];
                    final canAccess = controller.canAccessLesson(group, lesson);
                    return _LessonTile(
                      lesson: lesson,
                      minPassScore: level.minPassScore,
                      modeLabel: controller.modeLabel(lesson.mode),
                      canAccess: canAccess,
                      onTap: () => controller.onTapLesson(group, lesson),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.minPassScore,
    required this.modeLabel,
    required this.canAccess,
    required this.onTap,
  });

  final Lesson lesson;
  final int minPassScore;
  final String modeLabel;
  final bool canAccess;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isCompleted = lesson.isCompleted;
    final bool isActive = canAccess && !isCompleted;

    final Color containerColor;
    final Color borderColor;
    if (isCompleted) {
      containerColor = Colors.green.withValues(alpha: 0.08);
      borderColor = Colors.green.withValues(alpha: 0.4);
    } else if (isActive) {
      containerColor = colorScheme.primaryContainer.withValues(alpha: 0.35);
      borderColor = colorScheme.primary;
    } else {
      containerColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
      borderColor = colorScheme.outlineVariant.withValues(alpha: 0.5);
    }

    return Material(
      color: containerColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _LeadingStatusIcon(
                isCompleted: isCompleted,
                isActive: isActive,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lesson.orderIndex}. ${lesson.title}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: canAccess
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MiniBadge(
                          text: modeLabel,
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        if (isCompleted)
                          _MiniBadge(
                            text: 'Skor: ${lesson.bestScore}',
                            color: theme.brightness == Brightness.dark
                                ? Colors.green.shade300
                                : Colors.green.shade800,
                          )
                        else if (isActive)
                          _MiniBadge(
                            text: 'Siap Dipraktikkan',
                            color: colorScheme.primary,
                          )
                        else
                          _MiniBadge(
                            text: 'Min skor $minPassScore',
                            color: colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                canAccess
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                size: 20,
                color: canAccess
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingStatusIcon extends StatelessWidget {
  const _LeadingStatusIcon({
    required this.isCompleted,
    required this.isActive,
    required this.colorScheme,
  });

  final bool isCompleted;
  final bool isActive;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Icon(
        Icons.check_circle_rounded,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.green.shade300
            : Colors.green.shade700,
        size: 28,
      );
    }
    if (isActive) {
      return Icon(
        Icons.play_circle_fill_rounded,
        color: colorScheme.primary,
        size: 28,
      );
    }
    return Icon(
      Icons.lock_rounded,
      color: colorScheme.outline,
      size: 24,
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
