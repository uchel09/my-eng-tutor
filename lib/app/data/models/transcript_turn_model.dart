import 'dart:convert';

/// Represents a single spoken or text turn in a live tutoring conversation.
class TranscriptTurnModel {
  const TranscriptTurnModel({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  /// Role of the speaker: `'user'` or `'tutor'`.
  final String role;
  final String text;
  final DateTime timestamp;

  factory TranscriptTurnModel.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] as String?)?.trim().toLowerCase();
    final role = rawRole == 'tutor' ? 'tutor' : 'user';
    final text = (json['text'] as String?) ?? '';

    DateTime timestamp;
    final rawTs = json['timestamp'];
    if (rawTs is String && rawTs.isNotEmpty) {
      timestamp = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else if (rawTs is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else {
      timestamp = DateTime.now();
    }

    return TranscriptTurnModel(
      role: role,
      text: text,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'role': role,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  static String encodeList(List<TranscriptTurnModel> turns) {
    return jsonEncode(turns.map((t) => t.toJson()).toList(growable: false));
  }

  static List<TranscriptTurnModel> decodeList(String rawJson) {
    if (rawJson.trim().isEmpty) return const [];
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TranscriptTurnModel.fromJson)
        .toList(growable: false);
  }
}
