import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/daos/roadmap_dao.dart';
import '../../../data/models/practice_args.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../routes/app_pages.dart';

/// Controller for the 5-tab home shell, daily streak, progress summary, and quick launches.
class HomeController extends GetxController {
  HomeController({required this.repository});

  final TutorRepository repository;

  final RxInt currentTabIndex = 0.obs;
  final RxList<LevelWithLessons> levels = <LevelWithLessons>[].obs;
  final Rxn<AppSetting> settings = Rxn<AppSetting>();
  final RxBool isLoading = true.obs;

  StreamSubscription<List<LevelWithLessons>>? _roadmapSub;
  StreamSubscription<AppSetting>? _settingsSub;
  bool? _lastAppliedDarkMode;

  @override
  void onInit() {
    super.onInit();
    _roadmapSub = repository.watchRoadmap().listen(
      (data) {
        levels.assignAll(data);
        isLoading.value = false;
      },
      onError: (_) {
        isLoading.value = false;
      },
    );

    _settingsSub = repository.watchSettings().listen((data) {
      settings.value = data;
      if (_lastAppliedDarkMode != data.darkMode) {
        _lastAppliedDarkMode = data.darkMode;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.changeThemeMode(
            data.darkMode ? ThemeMode.dark : ThemeMode.light,
          );
        });
      }
    });
  }

  int get currentStreak => settings.value?.currentStreak ?? 0;

  bool get isApiKeyMissing =>
      (settings.value?.apiKey.trim().isEmpty ?? true);

  bool get isUnlockAllActive => settings.value?.unlockAllOverride ?? false;

  /// Highest unlocked CEFR level code (defaults to `'A1'`).
  String get activeCefrCode {
    String code = 'A1';
    for (final group in levels) {
      if (group.level.isUnlocked) {
        code = group.level.code;
      }
    }
    return code;
  }

  int get completedLessonsCount {
    var count = 0;
    for (final group in levels) {
      count += group.lessons.where((l) => l.isCompleted).length;
    }
    return count;
  }

  int get totalLessonsCount {
    var count = 0;
    for (final group in levels) {
      count += group.lessons.length;
    }
    return count;
  }

  double get overallProgress {
    final total = totalLessonsCount;
    if (total == 0) return 0;
    return completedLessonsCount / total;
  }

  /// First unlocked & uncompleted lesson; falls back to the final lesson if all completed.
  ({Level level, Lesson lesson})? get nextRecommendedLesson {
    ({Level level, Lesson lesson})? lastLesson;
    for (final group in levels) {
      for (final lesson in group.lessons) {
        lastLesson = (level: group.level, lesson: lesson);
        final accessible = isUnlockAllActive ||
            (group.level.isUnlocked && lesson.isUnlocked);
        if (accessible && !lesson.isCompleted) {
          return lastLesson;
        }
      }
    }
    return lastLesson;
  }

  String modeLabel(String mode) {
    return mode == 'guided_speech' ? 'Guided 60s' : 'Live Roleplay';
  }

  void changeTab(int index) {
    if (index < 0 || index > 4) return;
    currentTabIndex.value = index;
  }

  void openSettingsTab() => changeTab(4);

  void startRecommendedLesson() {
    final recommended = nextRecommendedLesson;
    if (recommended == null) {
      changeTab(1);
      return;
    }

    Get.toNamed<void>(
      Routes.PRACTICE,
      arguments: PracticeArgs(
        sessionType: 'lesson',
        level: recommended.level,
        lesson: recommended.lesson,
        targetCefrLevel: recommended.level.code,
        title: recommended.lesson.title,
        scenarioPrompt: recommended.lesson.scenarioPrompt,
        mode: recommended.lesson.mode,
        targetDurationSec: recommended.lesson.targetDurationSec,
      ),
    );
  }

  void startPlacementTest() {
    Get.toNamed<void>(
      Routes.PRACTICE,
      arguments: PracticeArgs(
        sessionType: 'placement',
        targetCefrLevel: activeCefrCode,
        title: 'Quick Placement Test (60s)',
        scenarioPrompt:
            'Speak freely for 60 seconds: introduce yourself, describe your daily work or studies, and share one recent experience or future goal so AI can estimate your CEFR level (A1–C2).',
        mode: 'guided_speech',
        targetDurationSec: 60,
      ),
    );
  }

  Future<void> startFreeTalk() async {
    final chosenTopic = await Get.dialog<String>(
      const _FreeTalkTopicDialog(),
    );

    if (chosenTopic == null || chosenTopic.trim().isEmpty) return;

    Get.toNamed<void>(
      Routes.PRACTICE,
      arguments: PracticeArgs(
        sessionType: 'free_talk',
        targetCefrLevel: activeCefrCode,
        title: 'Free Talk: $chosenTopic',
        scenarioPrompt:
            'Have an engaging, natural two-way English conversation about "$chosenTopic".',
        mode: 'live_roleplay',
        targetDurationSec: 120,
        customTopic: chosenTopic,
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

class _FreeTalkTopicDialog extends StatefulWidget {
  const _FreeTalkTopicDialog();

  @override
  State<_FreeTalkTopicDialog> createState() => _FreeTalkTopicDialogState();
}

class _FreeTalkTopicDialogState extends State<_FreeTalkTopicDialog> {
  static const List<String> _quickTopics = <String>[
    'Daily Life',
    'Work & Career',
    'Traveling',
    'Hobbies',
    'Technology',
  ];

  final TextEditingController _customController = TextEditingController();
  String _selectedTopic = _quickTopics.first;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Topik Free Talk'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickTopics.map((topic) {
                final isSelected = _selectedTopic == topic &&
                    _customController.text.trim().isEmpty;
                return ChoiceChip(
                  label: Text(topic),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedTopic = topic;
                      _customController.clear();
                    });
                  },
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _customController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Atau ketik topik bebas',
                hintText: 'Misal: Favorite movies, Startup ideas...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final custom = _customController.text.trim();
            Navigator.of(context).pop(
              custom.isNotEmpty ? custom : _selectedTopic,
            );
          },
          child: const Text('Mulai Ngobrol'),
        ),
      ],
    );
  }
}
