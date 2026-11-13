import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/daos/roadmap_dao.dart';
import '../../../data/models/session_result_args.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../routes/app_pages.dart';

/// Represents a calendar-day group of logged speaking mistakes.
class MistakeDayGroup {
  const MistakeDayGroup({
    required this.dayKey,
    required this.dayLabel,
    required this.items,
  });

  final String dayKey;
  final String dayLabel;
  final List<Mistake> items;
}

/// Offline review controller managing Vocab Bank, Mistake Log, and History.
class ReviewController extends GetxController {
  ReviewController({required this.repository});

  final TutorRepository repository;

  static const List<String> cefrFilterOptions = <String>[
    'ALL',
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
  ];

  static const List<String> cefrLevels = <String>[
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
  ];

  static const List<String> _monthAbbr = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  final RxList<VocabItem> vocabItems = <VocabItem>[].obs;
  final RxList<Mistake> mistakes = <Mistake>[].obs;
  final RxList<PracticeSession> sessions = <PracticeSession>[].obs;

  final RxString searchQuery = ''.obs;
  final RxString selectedCefrFilter = 'ALL'.obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxSet<String> collapsedMistakeDayKeys = <String>{}.obs;
  final RxSet<String> expandedMistakeDayKeys = <String>{}.obs;

  final RxMap<int, ({String title, String cefrCode})> _lessonMetaMap =
      <int, ({String title, String cefrCode})>{}.obs;

  final TextEditingController searchController = TextEditingController();

  StreamSubscription<List<VocabItem>>? _vocabSub;
  StreamSubscription<List<Mistake>>? _mistakesSub;
  StreamSubscription<List<PracticeSession>>? _sessionsSub;
  StreamSubscription<List<LevelWithLessons>>? _roadmapSub;

  @override
  void onInit() {
    super.onInit();
    retryLoad();
  }

  /// Subscribes (or re-subscribes) to offline Drift streams for Review tabs.
  void retryLoad() {
    _vocabSub?.cancel();
    _mistakesSub?.cancel();
    _sessionsSub?.cancel();
    _roadmapSub?.cancel();

    isLoading.value = true;
    errorMessage.value = null;

    _vocabSub = repository.watchAllVocab().listen(
      (data) {
        vocabItems.assignAll(data);
        isLoading.value = false;
        errorMessage.value = null;
      },
      onError: (Object error) {
        errorMessage.value = 'Gagal memuat kosakata: $error';
        isLoading.value = false;
      },
    );

    _mistakesSub = repository.watchAllMistakes().listen(
      (data) {
        mistakes.assignAll(data);
      },
      onError: (Object error) {
        errorMessage.value ??= 'Gagal memuat catatan kesalahan: $error';
      },
    );

    _sessionsSub = repository.watchRecentSessions(limit: 50).listen(
      (data) {
        sessions.assignAll(data);
      },
      onError: (Object error) {
        errorMessage.value ??= 'Gagal memuat riwayat sesi: $error';
      },
    );

    _roadmapSub = repository.watchRoadmap().listen((groups) {
      final mapped = <int, ({String title, String cefrCode})>{};
      for (final group in groups) {
        for (final lesson in group.lessons) {
          mapped[lesson.id] = (
            title: lesson.title,
            cefrCode: group.level.code,
          );
        }
      }
      _lessonMetaMap.assignAll(mapped);
    });
  }

  /// Updates [searchQuery] as the user types in the global search bar.
  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  /// Clears the search bar text and active query.
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  /// Selects a CEFR chip filter (`ALL` or `A1`..`C2`).
  void selectCefrFilter(String cefr) {
    selectedCefrFilter.value = cefr;
  }

  /// Filtered vocabulary list matching [selectedCefrFilter] and [searchQuery].
  List<VocabItem> get filteredVocab {
    final filter = selectedCefrFilter.value.toUpperCase();
    final query = searchQuery.value.trim().toLowerCase();

    return vocabItems.where((item) {
      if (filter != 'ALL' && item.cefrLevel.toUpperCase() != filter) {
        return false;
      }
      if (query.isEmpty) return true;
      return item.word.toLowerCase().contains(query) ||
          item.meaningId.toLowerCase().contains(query) ||
          item.exampleSentence.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  /// Filtered mistake log matching [searchQuery].
  List<Mistake> get filteredMistakes {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return mistakes.toList(growable: false);
    }

    return mistakes.where((item) {
      return item.originalSentence.toLowerCase().contains(query) ||
          item.correctedSentence.toLowerCase().contains(query) ||
          item.explanation.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  /// Groups [filteredMistakes] by local calendar day ordered newest-first.
  List<MistakeDayGroup> get groupedMistakesByDay {
    final items = filteredMistakes;
    if (items.isEmpty) return const <MistakeDayGroup>[];

    final grouped = <DateTime, List<Mistake>>{};
    for (final mistake in items) {
      final local = mistake.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      grouped.putIfAbsent(day, () => <Mistake>[]).add(mistake);
    }

    final sortedDays = grouped.keys.toList(growable: false)
      ..sort((a, b) => b.compareTo(a));

    final nowLocal = DateTime.now();
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    return sortedDays.map((day) {
      final dayItems = List<Mistake>.from(grouped[day]!)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final month = day.month.toString().padLeft(2, '0');
      final dateNum = day.day.toString().padLeft(2, '0');
      final dayKey = '${day.year}-$month-$dateNum';
      final shortDate = formatShortDate(day);
      final diffDays = today.difference(day).inDays;

      final String dayLabel;
      if (diffDays == 0) {
        dayLabel = 'Hari Ini • $shortDate';
      } else if (diffDays == 1) {
        dayLabel = 'Kemarin • $shortDate';
      } else {
        dayLabel = shortDate;
      }

      return MistakeDayGroup(
        dayKey: dayKey,
        dayLabel: dayLabel,
        items: List<Mistake>.unmodifiable(dayItems),
      );
    }).toList(growable: false);
  }

  /// Whether mistake group [dayKey] is currently expanded.
  bool isMistakeDayExpanded(String dayKey) {
    if (searchQuery.value.trim().isNotEmpty) {
      return true;
    }
    if (expandedMistakeDayKeys.contains(dayKey)) {
      return true;
    }
    if (collapsedMistakeDayKeys.contains(dayKey)) {
      return false;
    }
    final groups = groupedMistakesByDay;
    return groups.isNotEmpty && groups.first.dayKey == dayKey;
  }

  /// Toggles expanded/collapsed state for mistake group [dayKey].
  void toggleMistakeDay(String dayKey) {
    if (isMistakeDayExpanded(dayKey)) {
      expandedMistakeDayKeys.remove(dayKey);
      collapsedMistakeDayKeys.add(dayKey);
    } else {
      collapsedMistakeDayKeys.remove(dayKey);
      expandedMistakeDayKeys.add(dayKey);
    }
  }

  /// Resolves a readable title for a saved [session].
  String resolveSessionTitle(PracticeSession session) {
    final lessonId = session.lessonId;
    if (lessonId != null) {
      final meta = _lessonMetaMap[lessonId];
      if (meta != null) {
        return '${meta.cefrCode} • ${meta.title}';
      }
    }

    switch (session.sessionType) {
      case 'placement':
        return 'Quick Placement Test';
      case 'free_talk':
        return 'Free Talk Bebas';
      case 'guided_speech':
        return 'Latihan Guided 60s';
      case 'live_roleplay':
        return 'Latihan Live Roleplay';
      default:
        return 'Sesi Latihan';
    }
  }

  /// Returns a short display label for a session's `sessionType`.
  String sessionTypeLabel(String sessionType) {
    switch (sessionType) {
      case 'placement':
        return 'Placement Test';
      case 'free_talk':
        return 'Free Talk';
      case 'guided_speech':
        return 'Guided 60s';
      case 'live_roleplay':
        return 'Live Roleplay';
      default:
        return 'Latihan';
    }
  }

  /// Formats [date] as `13 Nov 2026 • 16:14`.
  String formatSessionDate(DateTime date) {
    final local = date.toLocal();
    final month = _monthAbbr[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} $month ${local.year} • $hour:$minute';
  }

  /// Formats [date] as `13 Nov 2026`.
  String formatShortDate(DateTime date) {
    final local = date.toLocal();
    final month = _monthAbbr[local.month - 1];
    return '${local.day} $month ${local.year}';
  }

  /// Formats [dt] in local `HH:mm` clock notation.
  String formatTimeOnly(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formats duration in seconds as `m:ss` or `Xm Xs`.
  String formatDuration(int seconds) {
    final clamped = seconds < 0 ? 0 : seconds;
    final mins = clamped ~/ 60;
    final secs = clamped % 60;
    if (mins == 0) {
      return '${secs}d';
    }
    return '${mins}m ${secs.toString().padLeft(2, '0')}d';
  }

  /// Increments the mastery counter for the given vocabulary item [id].
  Future<void> markVocabMastered(int id) async {
    await repository.incrementVocabMastery(id);
  }

  /// Confirms with the user and deletes the vocabulary item [id].
  Future<void> deleteVocab(int id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Kosakata?'),
        content: const Text(
          'Kosakata ini akan dihapus permanen dari Vocab Bank.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
            ),
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await repository.deleteVocab(id);
    }
  }

  /// Opens a modal dialog to manually insert a new vocabulary card.
  Future<void> showAddManualVocabDialog() async {
    final result = await Get.dialog<_ManualVocabInput>(
      const _AddManualVocabDialog(),
    );
    if (result == null) return;

    await repository.addManualVocab(
      word: result.word,
      meaningId: result.meaningId,
      exampleSentence: result.exampleSentence,
      cefrLevel: result.cefrLevel,
    );

    final colorScheme = Get.theme.colorScheme;
    Get.snackbar(
      'Kosakata Ditambahkan',
      '"${result.word}" (${result.cefrLevel}) tersimpan ke Vocab Bank.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: colorScheme.secondaryContainer,
      colorText: colorScheme.onSecondaryContainer,
      duration: const Duration(seconds: 2),
    );
  }

  /// Opens the offline speech insight view for a historical [session].
  void openSessionDetail(PracticeSession session) {
    Get.toNamed<void>(
      Routes.SESSION_RESULT,
      arguments: SessionResultArgs(
        existingSession: session,
        sessionTitle: resolveSessionTitle(session),
      ),
    );
  }

  @override
  void onClose() {
    _vocabSub?.cancel();
    _mistakesSub?.cancel();
    _sessionsSub?.cancel();
    _roadmapSub?.cancel();
    searchController.dispose();
    super.onClose();
  }
}

class _ManualVocabInput {
  const _ManualVocabInput({
    required this.word,
    required this.meaningId,
    required this.exampleSentence,
    required this.cefrLevel,
  });

  final String word;
  final String meaningId;
  final String exampleSentence;
  final String cefrLevel;
}

class _AddManualVocabDialog extends StatefulWidget {
  const _AddManualVocabDialog();

  @override
  State<_AddManualVocabDialog> createState() => _AddManualVocabDialogState();
}

class _AddManualVocabDialogState extends State<_AddManualVocabDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();
  String _selectedCefr = 'A1';

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      _ManualVocabInput(
        word: _wordController.text.trim(),
        meaningId: _meaningController.text.trim(),
        exampleSentence: _exampleController.text.trim(),
        cefrLevel: _selectedCefr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Kosakata'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _wordController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Kata / Frasa Inggris',
                  hintText: 'contoh: break the ice',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kata atau frasa wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _meaningController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Arti (Bahasa Indonesia)',
                  hintText: 'contoh: mencairkan suasana',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Arti Bahasa Indonesia wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _exampleController,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Contoh Kalimat',
                  hintText: 'contoh: A joke helped break the ice.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Contoh kalimat wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCefr,
                decoration: const InputDecoration(
                  labelText: 'Level CEFR',
                ),
                items: ReviewController.cefrLevels
                    .map(
                      (level) => DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCefr = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
