import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_state_widgets.dart';
import '../../../data/models/transcript_turn_model.dart';
import '../../../data/providers/gemini_live_provider.dart';
import '../../../routes/app_pages.dart';
import '../controllers/practice_controller.dart';

class PracticeView extends GetView<PracticeController> {
  const PracticeView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = controller.args;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final canExit = await controller.confirmExitSession();
        if (canExit && context.mounted) {
          Get.back<void>();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  args?.title ?? 'Latihan Berbicara',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (args != null) ...[
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
                    args.targetCefrLevel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Obx(() {
              final elapsed = controller.formattedElapsed;
              final isTimed = args?.isTimedSpeechMode ?? false;
              final target = args != null
                  ? controller.formatSeconds(args.targetDurationSec)
                  : '01:00';
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isTimed ? '$elapsed / $target' : elapsed,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              );
            }),
          ],
          bottom: args != null && args.isTimedSpeechMode
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(4),
                  child: Obx(() {
                    final targetSec = args.targetDurationSec > 0
                        ? args.targetDurationSec
                        : 60;
                    final progress =
                        (controller.elapsedSeconds.value / targetSec)
                            .clamp(0.0, 1.0);
                    return LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                    );
                  }),
                )
              : null,
        ),
        body: Obx(() {
          final state = controller.connectionState.value;
          final error = controller.errorMessage.value;
          final hasConnected = controller.hasEverConnected.value;

          if (state == LiveConnectionState.connecting && !hasConnected) {
            return const AppLoadingView(
              message: 'Menghubungkan ke Gemini Live Tutor...',
            );
          }

          if (state == LiveConnectionState.error && !hasConnected) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppErrorView(
                      title: 'Tidak Dapat Memulai Sesi',
                      message: error ?? 'Terjadi gangguan koneksi.',
                      onRetry: controller.startSession,
                      retryLabel: 'Coba Lagi',
                    ),
                    if (controller.isApiKeyMissingError.value)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Get.back<void>();
                            Get.toNamed<void>(Routes.SETTINGS);
                          },
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Buka Pengaturan'),
                        ),
                      )
                    else if (controller.isPermissionPermanentlyDenied.value)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: OutlinedButton.icon(
                          onPressed: controller.openDeviceSettings,
                          icon: const Icon(Icons.security_rounded),
                          label: const Text('Buka Izin Aplikasi'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              if (args != null) _ScenarioPromptCard(controller: controller),
              if (state == LiveConnectionState.error && error != null)
                _MidSessionErrorBanner(
                  message: error,
                  onReconnect: controller.startSession,
                ),
              Expanded(
                child: controller.transcriptTurns.isEmpty
                    ? const AppEmptyView(
                        icon: Icons.spatial_audio_off_rounded,
                        title: 'Menunggu Sapaan AI Tutor',
                        subtitle:
                            'Sesi sudah terhubung. Dengarkan sapaan tutor atau mulai berbicara dalam bahasa Inggris.',
                      )
                    : ListView.separated(
                        controller: controller.transcriptScrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: controller.transcriptTurns.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _TranscriptBubble(
                            index: index,
                            turn: controller.transcriptTurns[index],
                            controller: controller,
                          );
                        },
                      ),
              ),
              _VoiceStatusBar(
                isAiSpeaking: controller.isAiSpeaking.value ||
                    controller.replayingTurnIndex.value != null,
                isMicActive: controller.isMicActive.value,
                onStopAiSpeaking: controller.stopAiSpeaking,
              ),
              if (controller.showTextInput.value)
                _TextFallbackBar(controller: controller),
              _BottomControlBar(controller: controller),
            ],
          );
        }),
      ),
    );
  }
}

class _ScenarioPromptCard extends StatelessWidget {
  const _ScenarioPromptCard({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args = controller.args!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Obx(() {
        final expanded = controller.isPromptExpanded.value;
        final totalVocab = args.targetVocabulary.length;
        final practicedVocab = args.hasTargetVocabulary
            ? controller.practicedTargetWordsCount
            : 0;
        final isDark = theme.brightness == Brightness.dark;
        return InkWell(
          onTap: controller.togglePromptExpanded,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Skenario Latihan',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (args.hasTargetVocabulary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: practicedVocab == totalVocab
                              ? Colors.green.shade600.withValues(alpha: 0.16)
                              : colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$practicedVocab/$totalVocab kata',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: practicedVocab == totalVocab
                                ? (isDark
                                      ? Colors.green.shade300
                                      : Colors.green.shade700)
                                : colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 96),
                    child: SingleChildScrollView(
                      child: Text(
                        args.scenarioPrompt,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  if (args.hasTargetVocabulary) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Target Kosakata ($practicedVocab/$totalVocab terpakai):',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 112),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: args.targetVocabulary.map((word) {
                            final isPracticed =
                                controller.isTargetWordPracticed(word);
                            final practicedColor = isDark
                                ? Colors.green.shade300
                                : Colors.green.shade700;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPracticed
                                    ? Colors.green.shade600.withValues(
                                        alpha: 0.16,
                                      )
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isPracticed
                                      ? Colors.green.shade600.withValues(
                                          alpha: 0.7,
                                        )
                                      : colorScheme.outlineVariant.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPracticed) ...[
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: practicedColor,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Flexible(
                                    child: Text(
                                      word,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: isPracticed
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isPracticed
                                                ? practicedColor
                                                : colorScheme.onSurface,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(growable: false),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _MidSessionErrorBanner extends StatelessWidget {
  const _MidSessionErrorBanner({
    required this.message,
    required this.onReconnect,
  });

  final String message;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
            ),
          ),
          TextButton(
            onPressed: onReconnect,
            child: const Text('Sambung'),
          ),
        ],
      ),
    );
  }
}

class _TranscriptBubble extends StatelessWidget {
  const _TranscriptBubble({
    required this.index,
    required this.turn,
    required this.controller,
  });

  final int index;
  final TranscriptTurnModel turn;
  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = turn.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUser ? 'Anda' : 'AI Tutor',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isUser
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                turn.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
              if (!isUser) ...[
                const SizedBox(height: 8),
                Obx(() {
                  final audioBytes = controller.tutorAudioByTurnIndex[index];
                  final hasAudio = audioBytes != null && audioBytes.isNotEmpty;
                  final isReplayingThis =
                      controller.replayingTurnIndex.value == index;

                  if (!hasAudio) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volume_off_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hanya teks',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => isReplayingThis
                        ? controller.stopReplay()
                        : controller.replayTutorTurn(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isReplayingThis
                            ? colorScheme.errorContainer
                            : colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isReplayingThis
                                ? Icons.stop_circle_rounded
                                : Icons.volume_up_rounded,
                            size: 16,
                            color: isReplayingThis
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isReplayingThis ? 'Berhenti' : 'Dengar Ulang',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isReplayingThis
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceStatusBar extends StatelessWidget {
  const _VoiceStatusBar({
    required this.isAiSpeaking,
    required this.isMicActive,
    required this.onStopAiSpeaking,
  });

  final bool isAiSpeaking;
  final bool isMicActive;
  final VoidCallback onStopAiSpeaking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final IconData icon;
    final String label;
    final Color color;

    if (isMicActive) {
      icon = Icons.mic_rounded;
      label = 'Sedang merekam suara Anda... Ketuk Kirim jika selesai';
      color = colorScheme.error;
    } else if (isAiSpeaking) {
      icon = Icons.graphic_eq_rounded;
      label = 'AI Tutor sedang berbicara...';
      color = colorScheme.secondary;
    } else {
      icon = Icons.mic_none_rounded;
      label = 'Ketuk tombol Rekam di bawah untuk mulai berbicara';
      color = colorScheme.onSurfaceVariant;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isAiSpeaking && !isMicActive) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onStopAiSpeaking,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.stop_circle_outlined, size: 16),
              label: const Text('Hentikan'),
            ),
          ],
        ],
      ),
    );
  }
}

class _TextFallbackBar extends StatelessWidget {
  const _TextFallbackBar({required this.controller});

  final PracticeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.textFallbackController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => controller.sendTextFallback(),
              decoration: const InputDecoration(
                hintText: 'Ketik jawaban (fallback)...',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: controller.sendTextFallback,
            icon: const Icon(Icons.send_rounded),
            tooltip: 'Kirim teks',
          ),
        ],
      ),
    );
  }
}

class _BottomControlBar extends StatelessWidget {
  const _BottomControlBar({required this.controller});

  final PracticeController controller;

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
        child: Obx(() {
          final micOn = controller.isMicActive.value;
          final keyboardOn = controller.showTextInput.value;

          return Row(
            children: [
              IconButton.filledTonal(
                onPressed: controller.toggleTextInput,
                tooltip: 'Input Teks',
                icon: Icon(
                  keyboardOn
                      ? Icons.keyboard_hide_rounded
                      : Icons.keyboard_alt_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: FilledButton.icon(
                  onPressed: controller.toggleRecordAndSend,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: micOn
                        ? colorScheme.error
                        : colorScheme.primary,
                    foregroundColor: micOn
                        ? colorScheme.onError
                        : colorScheme.onPrimary,
                  ),
                  icon: Icon(
                    micOn ? Icons.send_rounded : Icons.mic_rounded,
                    size: 20,
                  ),
                  label: Text(
                    micOn ? 'Kirim' : 'Rekam',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: FilledButton.tonalIcon(
                  onPressed: controller.finishAndEvaluate,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Selesai & Nilai',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
