import 'dart:typed_data';

import '../local/app_database.dart';
import 'practice_args.dart';
import 'transcript_turn_model.dart';

/// Arguments passed to [SessionResultView] for either a freshly completed
/// session (to be evaluated via Gemini REST) or a saved historical session.
class SessionResultArgs {
  const SessionResultArgs({
    this.practiceArgs,
    this.transcript = const <TranscriptTurnModel>[],
    this.startedAt,
    this.endedAt,
    this.durationSec = 0,
    this.recordedWavBytes,
    this.existingSession,
    this.sessionTitle,
  });

  final PracticeArgs? practiceArgs;
  final List<TranscriptTurnModel> transcript;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSec;
  final Uint8List? recordedWavBytes;

  /// Non-null when opening a saved session from Review/History.
  final PracticeSession? existingSession;
  final String? sessionTitle;
}
