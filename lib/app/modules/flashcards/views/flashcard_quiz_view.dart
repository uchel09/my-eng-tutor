import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_state_widgets.dart';
import '../../../data/providers/gemini_rest_provider.dart';
import '../controllers/flashcard_quiz_controller.dart';

class FlashcardQuizView extends GetView<FlashcardQuizController> {
  const FlashcardQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tes: ${controller.scopeTitle}',
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              controller.scopeSubtitle,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return AppLoadingView(
            message:
                'Menyiapkan soal untuk ${controller.totalSourceCards} kata...',
          );
        }

        final error = controller.errorMessage.value;
        if (error.isNotEmpty) {
          return AppErrorView(
            message: error,
            onRetry: controller.totalSourceCards > 0 ? controller.loadQuiz : null,
          );
        }

        if (controller.isCompleted.value) {
          return _QuizResultView(controller: controller);
        }

        final question = controller.currentQuestion;
        if (question == null) {
          return AppEmptyView(
            icon: Icons.quiz_outlined,
            title: 'Soal Tidak Tersedia',
            subtitle: 'Tidak ada soal yang dapat ditampilkan saat ini.',
            actionLabel: 'Kembali',
            onAction: () => Get.back<void>(),
          );
        }

        return _ActiveQuizBody(
          controller: controller,
          question: question,
        );
      }),
    );
  }
}

class _ActiveQuizBody extends StatelessWidget {
  const _ActiveQuizBody({
    required this.controller,
    required this.question,
  });

  final FlashcardQuizController controller;
  final FlashcardQuizQuestion question;

  static const List<String> _optionLetters = <String>['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final total = controller.questions.length;
      final index = controller.currentIndex.value;
      final answered = controller.isCurrentAnswered.value;
      final selectedIdx = controller.selectedOptionIndex.value;
      final correctCount = controller.correctCount.value;
      final progressValue =
          total == 0 ? 0.0 : (index + (answered ? 1 : 0)) / total;

      return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Soal ${index + 1} / $total',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Benar: $correctCount',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
            ),
          ),
          if (controller.isFallbackOfflineMode.value &&
              controller.infoBanner.value.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 18,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.infoBanner.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pertanyaan',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Obx(() {
                        final speaking =
                            controller.ttsService.isSpeaking.value &&
                                controller.ttsService.activeText.value ==
                                    question.word.trim();
                        return OutlinedButton.icon(
                          onPressed: controller.speakWord,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            speaking
                                ? Icons.graphic_eq_rounded
                                : Icons.volume_up_rounded,
                            size: 18,
                            color: speaking ? colorScheme.primary : null,
                          ),
                          label: const Text('Dengar Kata'),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.questionPrompt,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < question.options.length; i++) ...[
            _QuizOptionTile(
              letter: i < _optionLetters.length ? _optionLetters[i] : '${i + 1}',
              text: question.options[i],
              isAnswered: answered,
              isCorrectOption: i == question.correctIndex,
              isSelectedOption: selectedIdx == i,
              onTap: answered ? null : () => controller.selectOption(i),
            ),
            if (i < question.options.length - 1) const SizedBox(height: 10),
          ],
          if (answered) ...[
            const SizedBox(height: 16),
            _ExplanationCard(
              question: question,
              isCorrect: selectedIdx == question.correctIndex,
              onSpeakWord: controller.speakWord,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.nextQuestion,
              icon: Icon(
                controller.isLastQuestion
                    ? Icons.assessment_outlined
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(
                controller.isLastQuestion
                    ? 'Lihat Hasil Tes'
                    : 'Soal Berikutnya',
              ),
            ),
          ],
        ],
      ),
    );
    });
  }
}

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.letter,
    required this.text,
    required this.isAnswered,
    required this.isCorrectOption,
    required this.isSelectedOption,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool isAnswered;
  final bool isCorrectOption;
  final bool isSelectedOption;
  final VoidCallback? onTap;

  static const Color _successGreen = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color borderColor = colorScheme.outlineVariant;
    Color? cardColor;
    Color badgeBg = colorScheme.surfaceContainerHighest;
    Color badgeFg = colorScheme.onSurface;
    IconData? statusIcon;
    Color? statusIconColor;

    if (isAnswered) {
      if (isCorrectOption) {
        borderColor = _successGreen;
        cardColor = _successGreen.withValues(alpha: 0.12);
        badgeBg = _successGreen;
        badgeFg = Colors.white;
        statusIcon = Icons.check_circle_rounded;
        statusIconColor = _successGreen;
      } else if (isSelectedOption) {
        borderColor = colorScheme.error;
        cardColor = colorScheme.errorContainer.withValues(alpha: 0.45);
        badgeBg = colorScheme.error;
        badgeFg = colorScheme.onError;
        statusIcon = Icons.cancel_rounded;
        statusIconColor = colorScheme.error;
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: borderColor,
          width: isAnswered && (isCorrectOption || isSelectedOption) ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: badgeBg,
                foregroundColor: badgeFg,
                child: Text(
                  letter,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isAnswered && isCorrectOption
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (statusIcon != null) ...[
                const SizedBox(width: 8),
                Icon(statusIcon, color: statusIconColor, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.question,
    required this.isCorrect,
    required this.onSpeakWord,
  });

  final FlashcardQuizQuestion question;
  final bool isCorrect;
  final VoidCallback onSpeakWord;

  static const Color _successGreen = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = isCorrect ? _successGreen : colorScheme.error;
    final explanation = question.explanationId.trim().isNotEmpty
        ? question.explanationId.trim()
        : "Kata target untuk soal ini adalah '${question.word}'.";

    return Card(
      color: isCorrect
          ? _successGreen.withValues(alpha: 0.08)
          : colorScheme.errorContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_outline : Icons.info_outline,
                  color: accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCorrect ? 'Benar! Penjelasan:' : 'Kurang Tepat • Penjelasan:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Dengar kata target',
                  visualDensity: VisualDensity.compact,
                  onPressed: onSpeakWord,
                  icon: Icon(
                    Icons.volume_up_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              explanation,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  const _QuizResultView({required this.controller});

  final FlashcardQuizController controller;

  static const Color _successGreen = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final total = controller.questions.length;
      final correct = controller.correctCount.value;
      final percent = controller.accuracyPercent.round();
      final history = controller.answerHistory;

      return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: colorScheme.primaryContainer.withValues(alpha: 0.45),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '$percent%',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Benar $correct dari $total soal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.motivationMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 18,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Mastery level setiap kartu telah diperbarui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Review Jawaban',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = history[index];
              final question = entry.question;
              final correctOption =
                  question.options[question.correctIndex];
              final isCorrect = entry.isCorrect;
              final badgeColor = isCorrect ? _successGreen : colorScheme.error;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  question.word,
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
                                    color: badgeColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isCorrect ? 'Benar' : 'Salah',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: badgeColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Obx(() {
                            final speaking =
                                controller.ttsService.isSpeaking.value &&
                                    controller.ttsService.activeText.value ==
                                        question.word.trim();
                            return IconButton(
                              tooltip: 'Dengarkan kata',
                              onPressed: () =>
                                  controller.speakText(question.word),
                              icon: Icon(
                                speaking
                                    ? Icons.graphic_eq_rounded
                                    : Icons.volume_up_outlined,
                                color: speaking
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jawaban benar: $correctOption',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (question.explanationId.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          question.explanationId.trim(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: controller.retakeQuiz,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tes Ulang (Soal Baru)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              controller.ttsService.stop();
              Get.back<void>();
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Selesai'),
          ),
        ],
      ),
    );
    });
  }
}
