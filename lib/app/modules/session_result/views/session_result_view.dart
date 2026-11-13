import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_state_widgets.dart';
import '../../../data/models/speech_insight_model.dart';
import '../../flashcards/widgets/flashcard_deck_picker_sheet.dart';
import '../controllers/session_result_controller.dart';

class SessionResultView extends GetView<SessionResultController> {
  const SessionResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Insight'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingView(
            message: 'Menganalisis kelancaran, grammar & kosakatamu...',
          );
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppErrorView(
                    title: 'Evaluasi Gagal',
                    message: error,
                    onRetry: controller.isViewingHistory.value
                        ? null
                        : controller.retryEvaluation,
                    retryLabel: 'Coba Nilai Lagi',
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.finishToHome,
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = controller.insight.value;
        if (data == null) {
          return AppEmptyView(
            icon: Icons.analytics_outlined,
            title: 'Hasil Belum Tersedia',
            subtitle: 'Tidak ada data evaluasi yang dapat ditampilkan.',
            actionLabel: 'Kembali',
            onAction: controller.finishToHome,
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _SessionHeaderRow(
                    title: controller.sessionTitle.value,
                    duration: controller.formattedDuration,
                  ),
                  const SizedBox(height: 14),
                  _StatusBannerCard(
                    sessionType: controller.sessionType.value,
                    insight: data,
                    passed: controller.passed.value,
                    minPassScore: controller.minPassScore.value,
                    didUnlockProgress: controller.didUnlockProgress.value,
                    unlockedLabel: controller.unlockedLabel.value,
                  ),
                  const SizedBox(height: 16),
                  _ScoreBreakdownCard(insight: data),
                  const SizedBox(height: 16),
                  _FillerWordsCard(insight: data),
                  const SizedBox(height: 16),
                  _AiSummaryCard(summary: data.aiSummary),
                  const SizedBox(height: 16),
                  _MistakesSectionCard(mistakes: data.mistakes),
                  const SizedBox(height: 16),
                  _VocabSuggestionsCard(
                    suggestions: data.vocabSuggestions,
                    controller: controller,
                  ),
                  if (controller.transcriptTurns.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _TranscriptExpansionCard(controller: controller),
                  ],
                ],
              ),
            ),
            _BottomActionBar(controller: controller),
          ],
        );
      }),
    );
  }
}

class _SessionHeaderRow extends StatelessWidget {
  const _SessionHeaderRow({
    required this.title,
    required this.duration,
  });

  final String title;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Chip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(Icons.timer_outlined, size: 16),
          label: Text(
            duration,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBannerCard extends StatelessWidget {
  const _StatusBannerCard({
    required this.sessionType,
    required this.insight,
    required this.passed,
    required this.minPassScore,
    required this.didUnlockProgress,
    required this.unlockedLabel,
  });

  final String sessionType;
  final SpeechInsightModel insight;
  final bool passed;
  final int minPassScore;
  final bool didUnlockProgress;
  final String? unlockedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (sessionType == 'placement') {
      final level = insight.recommendedCefrLevel ?? 'A1';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 36,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekomendasi Level: $level',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level $level dan level sebelumnya kini terbuka di peta belajar Roadmap!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (sessionType == 'free_talk') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.forum_rounded,
              size: 32,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sesi Free Talk selesai! Skor keseluruhanmu: ${insight.overallScore}/100.',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Lesson status banner
    final Color bg = passed
        ? Colors.green.withValues(alpha: 0.14)
        : Colors.amber.withValues(alpha: 0.16);
    final Color fg = passed
        ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
        : (isDark ? Colors.amber.shade300 : Colors.amber.shade900);

    final String title = passed
        ? 'Lulus! Skor ${insight.overallScore}/100'
        : 'Skor ${insight.overallScore}/100 — Terus Berlatih!';
    final String subtitle = passed
        ? (unlockedLabel != null
            ? 'Misi baru terbuka: $unlockedLabel'
            : (didUnlockProgress
                ? 'Progres misi tercatat & misi berikutnya terbuka!'
                : 'Misi selesai dengan baik!'))
        : 'Butuh skor minimal $minPassScore untuk membuka misi berikutnya.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passed ? Icons.celebration_rounded : Icons.trending_up_rounded,
            size: 30,
            color: fg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdownCard extends StatelessWidget {
  const _ScoreBreakdownCard({required this.insight});

  final SpeechInsightModel insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${insight.overallScore}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Speaking Score',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Evaluasi 4 pilar kelancaran bahasa Inggris',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _MetricBar(
              label: 'Fluency',
              score: insight.fluencyScore,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 10),
            _MetricBar(
              label: 'Grammar',
              score: insight.grammarScore,
              color: colorScheme.secondary,
            ),
            const SizedBox(height: 10),
            _MetricBar(
              label: 'Vocabulary',
              score: insight.vocabScore,
              color: colorScheme.tertiary,
            ),
            const SizedBox(height: 10),
            _MetricBar(
              label: 'Pronunciation Clarity',
              score: insight.pronunciationScore,
              color: Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$score/100',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (score / 100).clamp(0.0, 1.0),
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.14),
          ),
        ),
      ],
    );
  }
}

class _FillerWordsCard extends StatelessWidget {
  const _FillerWordsCard({required this.insight});

  final SpeechInsightModel insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = insight.fillerCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.record_voice_over_outlined, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filler Words',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('$count terdeteksi'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (count == 0)
              Text(
                'Hebat! Tidak ada filler word yang mengganggu kelancaranmu.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else if (insight.detectedFillers.isEmpty)
              Text(
                'Terdeteksi $count jeda filler word saat berbicara. Coba ganti jeda "um/uh" dengan diam sejenak.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: insight.detectedFillers
                    .map((word) => Chip(label: Text('"$word"')))
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Feedback Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              summary.isNotEmpty
                  ? summary
                  : 'Sesi selesai dengan baik. Terus tingkatkan konsistensi latihan harianmu!',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _MistakesSectionCard extends StatelessWidget {
  const _MistakesSectionCard({required this.mistakes});

  final List<MistakeItemModel> mistakes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spellcheck_rounded, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Better Phrasing',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (mistakes.isEmpty)
              Text(
                'Kalimatmu sudah sangat rapi! Tidak ada kesalahan grammar mencolok pada sesi ini.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mistakes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = mistakes[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(item.category),
                        ),
                        const SizedBox(height: 6),
                        if (item.originalSentence.isNotEmpty) ...[
                          Text(
                            item.originalSentence,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (item.correctedSentence.isNotEmpty) ...[
                          Text(
                            item.correctedSentence,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? Colors.green.shade300
                                  : Colors.green.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (item.explanation.isNotEmpty)
                          Text(
                            item.explanation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _VocabSuggestionsCard extends StatelessWidget {
  const _VocabSuggestionsCard({
    required this.suggestions,
    required this.controller,
  });

  final List<VocabSuggestionModel> suggestions;
  final SessionResultController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rekomendasi Kosakata Baru',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (suggestions.isNotEmpty)
                  Obx(() {
                    final hasUnsaved = suggestions.any(
                      (vocab) =>
                          !controller.isVocabSavedToFlashcard(vocab.word),
                    );
                    if (!hasUnsaved) {
                      return const SizedBox.shrink();
                    }
                    return TextButton(
                      onPressed: () async {
                        final selected = await showFlashcardDeckPickerSheet(
                          context: context,
                          repository: controller.repository,
                          title: 'Simpan Semua ke Flashcard',
                        );
                        if (selected == null) return;
                        await controller.saveAllVocabToFlashcardSubDeck(
                          subDeckId: selected.subDeckId,
                          targetLabel: selected.targetLabel,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Simpan Semua'),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 10),
            if (suggestions.isEmpty)
              Text(
                'Belum ada saran kosakata tambahan untuk sesi ini.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final vocab = suggestions[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    vocab.word,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      vocab.cefrLevel,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Obx(() {
                              final targetLabel =
                                  controller.savedFlashcardTargetLabel(
                                vocab.word,
                              );
                              Future<void> pickAndSave() async {
                                final selected =
                                    await showFlashcardDeckPickerSheet(
                                  context: context,
                                  repository: controller.repository,
                                  title: 'Simpan "${vocab.word}" ke Flashcard',
                                );
                                if (selected == null) return;
                                await controller.saveVocabToFlashcardSubDeck(
                                  vocab: vocab,
                                  subDeckId: selected.subDeckId,
                                  targetLabel: selected.targetLabel,
                                );
                              }

                              if (targetLabel != null) {
                                return ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 185,
                                  ),
                                  child: FilledButton.tonalIcon(
                                    onPressed: pickAndSave,
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(
                                      Icons.bookmark_added_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'Tersimpan ($targetLabel)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }
                              return OutlinedButton.icon(
                                onPressed: pickAndSave,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(
                                  Icons.bookmark_add_outlined,
                                  size: 16,
                                ),
                                label: const Text('Simpan'),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vocab.meaningId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (vocab.exampleSentence.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"${vocab.exampleSentence}"',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TranscriptExpansionCard extends StatelessWidget {
  const _TranscriptExpansionCard({required this.controller});

  final SessionResultController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        title: Text(
          'Lihat Transkrip Percakapan (${controller.transcriptTurns.length})',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: controller.transcriptTurns.map((turn) {
          final isUser = turn.role == 'user';
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 58,
                  child: Text(
                    isUser ? 'Anda:' : 'Tutor:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isUser
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    turn.text,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.controller});

  final SessionResultController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            if (!controller.isViewingHistory.value) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.retryPractice,
                  child: const Text('Ulangi Latihan'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                onPressed: controller.finishToHome,
                child: const Text('Selesai'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
