import '../../data/local/daos/settings_dao.dart';

/// Shared configuration constants for Gemini Live WebSocket and REST APIs.
class GeminiConstants {
  const GeminiConstants._();

  /// Gemini Multimodal Live API WebSocket endpoint (v1beta).
  static const String liveWsEndpoint =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';

  /// Gemini REST API base URL (v1beta).
  static const String restBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Default Gemini Live native-audio model synced with [SettingsDao].
  static const String defaultLiveModel = SettingsDao.defaultLiveModel;

  /// Default Gemini model for post-session scoring and text analysis.
  static const String defaultScoringModel = SettingsDao.defaultScoringModel;

  /// Recommended Live API model choices displayed in Settings.
  static const List<String> liveModelOptions = <String>[
    'gemini-3.8-live',
    'gemini-2.5-flash-native-audio-preview-12-2025',
    'gemini-2.0-flash-live-001',
  ];

  /// Recommended REST scoring/evaluation model choices displayed in Settings.
  static const List<String> scoringModelOptions = <String>[
    'gemini-3.8-flash',
    'gemini-3.5-flash-lite',
    'gemini-2.5-flash',
  ];

  /// Required microphone PCM16 input sample rate (16 kHz) for Gemini Live.
  static const int inputSampleRate = 16000;

  /// Output PCM16 playback sample rate (24 kHz) streamed by Gemini Live.
  static const int outputSampleRate = 24000;

  /// Mono channel configuration for both capture and playback.
  static const int audioChannels = 1;

  /// Minimum overall score required to pass a lesson by default.
  static const int minPassScore = 70;

  /// Default speaking prompt duration in seconds.
  static const int defaultTargetDurationSec = 60;
}
