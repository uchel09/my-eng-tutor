import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/providers/gemini_rest_provider.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/tts_service.dart';
import 'flashcard_dialogs.dart';

/// Opens an interactive shadowing & pronunciation evaluation bottom sheet for [sentence].
Future<void> showSentencePronunciationSheet({
  required BuildContext context,
  required String sentence,
  String? meaningId,
  String? targetWord,
  required TutorRepository repository,
  required TtsService ttsService,
  AudioService? audioService,
  void Function(int score)? onEvaluated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _SentencePronunciationSheet(
      sentence: sentence,
      meaningId: meaningId,
      targetWord: targetWord,
      repository: repository,
      ttsService: ttsService,
      audioService: audioService,
      onEvaluated: onEvaluated,
    ),
  );
}

enum _SheetStage {
  idle,
  permissionDenied,
  recording,
  evaluating,
  error,
  result,
}

class _SentencePronunciationSheet extends StatefulWidget {
  const _SentencePronunciationSheet({
    required this.sentence,
    this.meaningId,
    this.targetWord,
    required this.repository,
    required this.ttsService,
    this.audioService,
    this.onEvaluated,
  });

  final String sentence;
  final String? meaningId;
  final String? targetWord;
  final TutorRepository repository;
  final TtsService ttsService;
  final AudioService? audioService;
  final void Function(int score)? onEvaluated;

  @override
  State<_SentencePronunciationSheet> createState() =>
      _SentencePronunciationSheetState();
}

class _SentencePronunciationSheetState
    extends State<_SentencePronunciationSheet> {
  static const int _maxCaptureSeconds = 20;
  static const Color _successGreen = Color(0xFF16A34A);
  static const Color _warningAmber = Color(0xFFD97706);

  _SheetStage _stage = _SheetStage.idle;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String _errorMessage = '';
  SentencePronunciationFeedback? _feedback;
  bool _hasActiveCapture = false;
  bool _isDisposed = false;

  AudioService? get _resolvedAudioService {
    if (widget.audioService != null) return widget.audioService;
    if (Get.isRegistered<AudioService>()) {
      return Get.find<AudioService>();
    }
    return null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    unawaited(widget.ttsService.stop());

    final audio = _resolvedAudioService;
    if (audio != null &&
        (_hasActiveCapture ||
            _stage == _SheetStage.recording ||
            audio.isRecording.value)) {
      unawaited(audio.stopMicStream().catchError((_) {}));
      audio.clearRecordedBuffer();
    }
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _speakExample({required double rate}) async {
    final trimmed = widget.sentence.trim();
    if (trimmed.isEmpty) return;
    await widget.ttsService.speak(trimmed, rate: rate);
  }

  Future<void> _startRecording() async {
    if (_stage == _SheetStage.recording || _stage == _SheetStage.evaluating) {
      return;
    }

    await widget.ttsService.stop();

    final audio = _resolvedAudioService;
    if (audio == null) {
      if (_isDisposed) return;
      setState(() {
        _errorMessage =
            'Layanan mikrofon tidak tersedia. Muat ulang halaman lalu coba lagi.';
        _stage = _SheetStage.error;
      });
      return;
    }

    bool permitted;
    try {
      permitted = await audio.ensureMicrophonePermission();
    } catch (error) {
      if (_isDisposed) return;
      setState(() {
        _errorMessage = 'Gagal memeriksa izin mikrofon: $error';
        _stage = _SheetStage.error;
      });
      return;
    }

    if (_isDisposed) return;
    if (!permitted) {
      setState(() {
        _stage = _SheetStage.permissionDenied;
      });
      return;
    }

    try {
      audio.clearRecordedBuffer();
      _hasActiveCapture = true;
      await audio.startMicStream(
        captureBufferForEval: true,
        maxCaptureSeconds: _maxCaptureSeconds,
      );
    } catch (error) {
      _hasActiveCapture = false;
      audio.clearRecordedBuffer();
      if (_isDisposed) return;
      setState(() {
        _errorMessage = 'Gagal memulai rekaman mikrofon: $error';
        _stage = _SheetStage.error;
      });
      return;
    }

    if (_isDisposed) {
      unawaited(audio.stopMicStream().catchError((_) {}));
      audio.clearRecordedBuffer();
      return;
    }

    _timer?.cancel();
    setState(() {
      _elapsedSeconds = 0;
      _errorMessage = '';
      _stage = _SheetStage.recording;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || _stage != _SheetStage.recording) {
        timer.cancel();
        return;
      }
      final nextSeconds = _elapsedSeconds + 1;
      if (nextSeconds >= _maxCaptureSeconds) {
        timer.cancel();
        setState(() {
          _elapsedSeconds = _maxCaptureSeconds;
        });
        unawaited(_stopAndEvaluate());
      } else {
        setState(() {
          _elapsedSeconds = nextSeconds;
        });
      }
    });
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    final audio = _resolvedAudioService;
    if (audio != null) {
      try {
        await audio.stopMicStream();
      } catch (_) {
        // Ignore stop errors when cancelling early.
      }
      audio.clearRecordedBuffer();
    }
    _hasActiveCapture = false;

    if (_isDisposed) return;
    setState(() {
      _elapsedSeconds = 0;
      _errorMessage = '';
      _stage = _feedback != null ? _SheetStage.result : _SheetStage.idle;
    });
  }

  Future<void> _stopAndEvaluate() async {
    if (_stage != _SheetStage.recording) return;
    _timer?.cancel();

    final audio = _resolvedAudioService;
    if (audio == null) {
      if (_isDisposed) return;
      setState(() {
        _errorMessage = 'Layanan mikrofon tidak ditemukan.';
        _stage = _SheetStage.error;
      });
      return;
    }

    setState(() {
      _stage = _SheetStage.evaluating;
      _errorMessage = '';
    });

    try {
      await audio.stopMicStream();
    } catch (_) {
      // Proceed to inspect any captured chunks even if stop throws.
    }

    final wavBytes = audio.buildRecordedWavBytes();
    audio.clearRecordedBuffer();
    _hasActiveCapture = false;

    if (_isDisposed) return;

    if (wavBytes == null || wavBytes.isEmpty) {
      setState(() {
        _errorMessage =
            'Suara belum terekam atau durasi terlalu singkat. Coba tekan Mulai Rekam dan ucapkan kalimat dengan jelas.';
        _stage = _SheetStage.error;
      });
      return;
    }

    try {
      final result = await widget.repository.evaluateSentencePronunciation(
        targetSentence: widget.sentence,
        targetWord: widget.targetWord,
        audioWavBytes: wavBytes,
      );
      if (_isDisposed) return;

      setState(() {
        _feedback = result;
        _stage = _SheetStage.result;
      });
      widget.onEvaluated?.call(result.score);
    } on GeminiApiException catch (error) {
      if (_isDisposed) return;
      setState(() {
        _errorMessage = error.message;
        _stage = _SheetStage.error;
      });
    } catch (error) {
      if (_isDisposed) return;
      setState(() {
        _errorMessage = 'Gagal menilai pelafalan kalimat: $error';
        _stage = _SheetStage.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final trimmedMeaning = widget.meaningId?.trim() ?? '';
    final trimmedTargetWord = widget.targetWord?.trim() ?? '';
    final isAudioBusy =
        _stage == _SheetStage.recording || _stage == _SheetStage.evaluating;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Latihan Pronunciation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (trimmedTargetWord.isNotEmpty) ...[
                      Text(
                        'Fokus kata: $trimmedTargetWord',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      widget.sentence.trim(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    if (trimmedMeaning.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        trimmedMeaning,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final target = widget.sentence.trim();
                final isTarget =
                    target.isNotEmpty &&
                    widget.ttsService.activeText.value == target;
                final isLoadingTts =
                    isTarget && widget.ttsService.isLoadingAudio.value;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isAudioBusy
                          ? null
                          : () => _speakExample(rate: 0.48),
                      icon: isLoadingTts
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.volume_up_rounded, size: 18),
                      label: const Text('Dengar Normal'),
                    ),
                    OutlinedButton.icon(
                      onPressed: isAudioBusy
                          ? null
                          : () => _speakExample(rate: 0.35),
                      icon: isLoadingTts
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : const Icon(
                              Icons.slow_motion_video_rounded,
                              size: 18,
                            ),
                      label: const Text('Dengar Pelan'),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FlashcardVoiceSourceChip(ttsService: widget.ttsService),
              ),
              const SizedBox(height: 12),
              _buildStageContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageContent(BuildContext context) {
    switch (_stage) {
      case _SheetStage.idle:
        return _buildIdleSection(context);
      case _SheetStage.permissionDenied:
        return _buildPermissionDeniedSection(context);
      case _SheetStage.recording:
        return _buildRecordingSection(context);
      case _SheetStage.evaluating:
        return _buildEvaluatingSection(context);
      case _SheetStage.error:
        return _buildErrorSection(context);
      case _SheetStage.result:
        final feedback = _feedback;
        if (feedback == null) return _buildIdleSection(context);
        return _buildResultSection(context, feedback);
    }
  }

  Widget _buildIdleSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dengarkan contoh kalimat, lalu tekan tombol di bawah untuk membaca kalimat dengan lantang dan jelas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Mulai Rekam'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final audio = _resolvedAudioService;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.mic_off_rounded, color: colorScheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Izin mikrofon dibutuhkan untuk merekam pelafalan kalimat Anda. Aktifkan izin mikrofon di Pengaturan aplikasi lalu coba lagi.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: audio == null
                    ? null
                    : () => audio.openDeviceAppSettings(),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Buka Pengaturan'),
              ),
              OutlinedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.fiber_manual_record_rounded,
                color: colorScheme.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sedang merekam... ucapkan kalimat target',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(_elapsedSeconds),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onError,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _cancelRecording,
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                onPressed: _stopAndEvaluate,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop & Nilai'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluatingSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 12),
          Text(
            'AI sedang menilai pelafalanmu...',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: colorScheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _errorMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(
    BuildContext context,
    SentencePronunciationFeedback feedback,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scoreColor = feedback.score >= 85
        ? _successGreen
        : (feedback.score >= 65 ? _warningAmber : colorScheme.error);
    final nonGoodWords = feedback.wordFeedback
        .where((wf) => wf.status != 'good' && wf.tipId.isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scoreColor.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    '${feedback.score} / 100',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetricChip(
                        label: 'Kejelasan: ${feedback.clarityScore}',
                        color: colorScheme.primary,
                      ),
                      _MetricChip(
                        label: 'Intonasi: ${feedback.intonationScore}',
                        color: colorScheme.secondary,
                      ),
                    ],
                  ),
                ],
              ),
              if (feedback.heardText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Terdengar seperti: "${feedback.heardText}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                feedback.overallFeedbackId,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
          ),
        ),
        if (feedback.wordFeedback.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Evaluasi Per Kata',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: feedback.wordFeedback
                .map((wf) => _WordStatusChip(feedback: wf))
                .toList(growable: false),
          ),
          if (nonGoodWords.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final wf in nonGoodWords)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${wf.word}: ${wf.tipId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ],
        if (feedback.practiceTipsId.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Tips Latihan',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final tip in feedback.practiceTipsId)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $tip',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _startRecording,
          icon: const Icon(Icons.mic_rounded),
          label: const Text('Coba Lagi'),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WordStatusChip extends StatelessWidget {
  const _WordStatusChip({required this.feedback});

  final SentenceWordFeedback feedback;

  static const Color _successGreen = Color(0xFF16A34A);
  static const Color _warningAmber = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color chipColor;
    final IconData icon;

    switch (feedback.status) {
      case 'good':
        chipColor = _successGreen;
        icon = Icons.check_circle_rounded;
      case 'missing':
        chipColor = colorScheme.error;
        icon = Icons.remove_circle_outline_rounded;
      default:
        chipColor = _warningAmber;
        icon = Icons.tune_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              feedback.word,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
