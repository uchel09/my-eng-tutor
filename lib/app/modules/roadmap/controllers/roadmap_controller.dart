import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/daos/roadmap_dao.dart';
import '../../../data/models/practice_args.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../routes/app_pages.dart';

/// Manages reactive CEFR roadmap data, lock/unlock rules, and mission launch.
class RoadmapController extends GetxController {
  RoadmapController({required this.repository});

  final TutorRepository repository;

  final RxList<LevelWithLessons> levels = <LevelWithLessons>[].obs;
  final RxSet<int> expandedLevelIds = <int>{}.obs;
  final Rxn<AppSetting> settings = Rxn<AppSetting>();
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  final Set<int> _initializedLevelIds = <int>{};
  StreamSubscription<List<LevelWithLessons>>? _roadmapSub;
  StreamSubscription<AppSetting>? _settingsSub;

  @override
  void onInit() {
    super.onInit();
    retryLoad();
  }

  /// Subscribes (or re-subscribes) to the Drift roadmap and settings streams.
  void retryLoad() {
    _roadmapSub?.cancel();
    _settingsSub?.cancel();

    isLoading.value = true;
    errorMessage.value = null;

    _roadmapSub = repository.watchRoadmap().listen(
      (data) {
        levels.assignAll(data);
        _syncDefaultExpandedLevels(data);
        isLoading.value = false;
        errorMessage.value = null;
      },
      onError: (Object error) {
        errorMessage.value = 'Gagal memuat peta belajar: $error';
        isLoading.value = false;
      },
    );

    _settingsSub = repository.watchSettings().listen(
      (data) {
        settings.value = data;
      },
    );
  }

  void _syncDefaultExpandedLevels(List<LevelWithLessons> data) {
    for (final group in data) {
      if (_initializedLevelIds.contains(group.level.id)) continue;
      _initializedLevelIds.add(group.level.id);

      final isLevelOpen = group.level.isUnlocked || isUnlockAllActive;
      final allCompleted =
          group.lessons.isNotEmpty && group.lessons.every((l) => l.isCompleted);
      if (isLevelOpen && !allCompleted) {
        expandedLevelIds.add(group.level.id);
      }
    }
  }

  bool isLevelExpanded(int levelId) => expandedLevelIds.contains(levelId);

  void toggleLevelExpanded(int levelId) {
    if (expandedLevelIds.contains(levelId)) {
      expandedLevelIds.remove(levelId);
    } else {
      expandedLevelIds.add(levelId);
    }
  }

  bool get isUnlockAllActive => settings.value?.unlockAllOverride ?? false;

  bool canAccessLesson(LevelWithLessons group, Lesson lesson) {
    return isUnlockAllActive || (group.level.isUnlocked && lesson.isUnlocked);
  }

  double levelProgress(LevelWithLessons group) {
    if (group.lessons.isEmpty) return 0;
    final completed = group.lessons.where((l) => l.isCompleted).length;
    return completed / group.lessons.length;
  }

  String modeLabel(String mode) {
    return mode == 'guided_speech' ? 'Guided 60 Detik' : 'Live Roleplay';
  }

  /// Handles tapping a lesson card: informs if locked, or shows mission details.
  void onTapLesson(LevelWithLessons group, Lesson lesson) {
    if (!canAccessLesson(group, lesson)) {
      final colorScheme = Get.theme.colorScheme;
      Get.snackbar(
        'Misi Terkunci',
        'Terkunci! Selesaikan misi sebelumnya dengan skor minimal ${group.level.minPassScore} (atau aktifkan Unlock All di Pengaturan).',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: colorScheme.surfaceContainerHighest,
        colorText: colorScheme.onSurface,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    Get.bottomSheet<void>(
      _MissionDetailSheet(
        group: group,
        lesson: lesson,
        modeLabel: modeLabel(lesson.mode),
        onStart: () => startLesson(group, lesson),
      ),
      isScrollControlled: true,
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  /// Closes the mission detail sheet and launches the speaking practice screen.
  void startLesson(LevelWithLessons group, Lesson lesson) {
    if (Get.isBottomSheetOpen ?? false) {
      Get.back<void>();
    }

    Get.toNamed<void>(
      Routes.PRACTICE,
      arguments: PracticeArgs(
        sessionType: 'lesson',
        level: group.level,
        lesson: lesson,
        targetCefrLevel: group.level.code,
        title: lesson.title,
        scenarioPrompt: lesson.scenarioPrompt,
        mode: lesson.mode,
        targetDurationSec: lesson.targetDurationSec,
      ),
    );
  }

  @override
  void onClose() {
    _roadmapSub?.cancel();
    _settingsSub?.cancel();
    super.onClose();
  }
}

class _MissionDetailSheet extends StatelessWidget {
  const _MissionDetailSheet({
    required this.group,
    required this.lesson,
    required this.modeLabel,
    required this.onStart,
  });

  final LevelWithLessons group;
  final Lesson lesson;
  final String modeLabel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${group.level.code} • ${group.level.title}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(modeLabel),
                  avatar: Icon(
                    lesson.mode == 'guided_speech'
                        ? Icons.record_voice_over_rounded
                        : Icons.forum_rounded,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lesson.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                lesson.scenarioPrompt,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _MetaInfo(
                  icon: Icons.timer_outlined,
                  label: 'Target: ${lesson.targetDurationSec} detik',
                ),
                _MetaInfo(
                  icon: Icons.emoji_events_outlined,
                  label: lesson.bestScore > 0
                      ? 'Skor terbaik: ${lesson.bestScore}'
                      : 'Min lulus: ${group.level.minPassScore}',
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Mulai Misi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  const _MetaInfo({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
