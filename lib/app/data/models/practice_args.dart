import '../../core/constants/gemini_constants.dart';
import '../local/app_database.dart';

/// Navigation arguments passed when launching a speaking [PracticeView] session.
class PracticeArgs {
  const PracticeArgs({
    required this.sessionType,
    this.level,
    this.lesson,
    required this.targetCefrLevel,
    required this.title,
    required this.scenarioPrompt,
    required this.mode,
    this.targetDurationSec = GeminiConstants.defaultTargetDurationSec,
    this.customTopic,
  });

  /// `'lesson'`, `'placement'`, or `'free_talk'`.
  final String sessionType;
  final Level? level;
  final Lesson? lesson;
  final String targetCefrLevel;
  final String title;
  final String scenarioPrompt;

  /// `'guided_speech'` or `'live_roleplay'`.
  final String mode;
  final int targetDurationSec;
  final String? customTopic;

  /// Whether this session captures WAV audio and tracks a timed speech goal.
  bool get isTimedSpeechMode =>
      mode == 'guided_speech' || sessionType == 'placement';
}
