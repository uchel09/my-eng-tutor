import 'dart:convert';

/// A grammar, phrasing, or pronunciation mistake detected during practice.
class MistakeItemModel {
  const MistakeItemModel({
    required this.originalSentence,
    required this.correctedSentence,
    required this.explanation,
    required this.category,
  });

  final String originalSentence;
  final String correctedSentence;
  final String explanation;
  final String category;

  factory MistakeItemModel.fromJson(Map<String, dynamic> json) {
    return MistakeItemModel(
      originalSentence: _asString(json['originalSentence']),
      correctedSentence: _asString(json['correctedSentence']),
      explanation: _asString(json['explanation']),
      category: _asString(json['category'], fallback: 'grammar'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'originalSentence': originalSentence,
        'correctedSentence': correctedSentence,
        'explanation': explanation,
        'category': category,
      };
}

/// A contextual vocabulary recommendation generated from the practice session.
class VocabSuggestionModel {
  const VocabSuggestionModel({
    required this.word,
    required this.meaningId,
    required this.exampleSentence,
    required this.cefrLevel,
  });

  final String word;
  final String meaningId;
  final String exampleSentence;
  final String cefrLevel;

  factory VocabSuggestionModel.fromJson(Map<String, dynamic> json) {
    return VocabSuggestionModel(
      word: _asString(json['word']),
      meaningId: _asString(json['meaningId']),
      exampleSentence: _asString(json['exampleSentence']),
      cefrLevel: _normalizeCefr(_asString(json['cefrLevel'])) ?? 'B1',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'word': word,
        'meaningId': meaningId,
        'exampleSentence': exampleSentence,
        'cefrLevel': cefrLevel,
      };
}

/// Structured evaluation returned by Gemini after a speaking practice session.
class SpeechInsightModel {
  const SpeechInsightModel({
    required this.overallScore,
    required this.fluencyScore,
    required this.grammarScore,
    required this.vocabScore,
    required this.pronunciationScore,
    required this.fillerCount,
    required this.detectedFillers,
    required this.aiSummary,
    this.recommendedCefrLevel,
    required this.mistakes,
    required this.vocabSuggestions,
  });

  final int overallScore;
  final int fluencyScore;
  final int grammarScore;
  final int vocabScore;
  final int pronunciationScore;
  final int fillerCount;
  final List<String> detectedFillers;
  final String aiSummary;
  final String? recommendedCefrLevel;
  final List<MistakeItemModel> mistakes;
  final List<VocabSuggestionModel> vocabSuggestions;

  /// Parses raw Gemini text output, safely stripping optional markdown fences
  /// such as ````json ... ```` before decoding JSON.
  factory SpeechInsightModel.fromRawJson(String rawText) {
    final cleaned = stripMarkdownCodeFence(rawText);
    dynamic decoded = jsonDecode(cleaned);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      decoded = decoded.first;
    }
    if (decoded is! Map) {
      throw const FormatException(
        'Respons evaluasi Gemini tidak berbentuk objek JSON yang valid.',
      );
    }
    return SpeechInsightModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  /// Defensively builds [SpeechInsightModel] from a decoded JSON map.
  factory SpeechInsightModel.fromJson(Map<String, dynamic> json) {
    final rawFillers = json['detectedFillers'];
    final fillers = <String>[];
    if (rawFillers is List) {
      for (final item in rawFillers) {
        final value = item?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          fillers.add(value);
        }
      }
    }

    final rawMistakes = json['mistakes'];
    final mistakes = <MistakeItemModel>[];
    if (rawMistakes is List) {
      for (final item in rawMistakes) {
        if (item is Map) {
          final parsed =
              MistakeItemModel.fromJson(Map<String, dynamic>.from(item));
          if (parsed.originalSentence.isNotEmpty ||
              parsed.correctedSentence.isNotEmpty) {
            mistakes.add(parsed);
          }
        }
      }
    }

    final rawVocab = json['vocabSuggestions'];
    final vocabSuggestions = <VocabSuggestionModel>[];
    if (rawVocab is List) {
      for (final item in rawVocab) {
        if (item is Map) {
          final parsed =
              VocabSuggestionModel.fromJson(Map<String, dynamic>.from(item));
          if (parsed.word.isNotEmpty) {
            vocabSuggestions.add(parsed);
          }
        }
      }
    }

    final fluency = _asInt(json['fluencyScore'], min: 0, max: 100);
    final grammar = _asInt(json['grammarScore'], min: 0, max: 100);
    final vocab = _asInt(json['vocabScore'], min: 0, max: 100);
    final pronunciation = _asInt(json['pronunciationScore'], min: 0, max: 100);

    final rawOverall = json['overallScore'];
    final overall = rawOverall != null
        ? _asInt(rawOverall, min: 0, max: 100)
        : ((fluency + grammar + vocab + pronunciation) / 4).round();

    final parsedFillerCount =
        _asInt(json['fillerCount'], min: 0, max: 9999, fallback: fillers.length);

    return SpeechInsightModel(
      overallScore: overall,
      fluencyScore: fluency,
      grammarScore: grammar,
      vocabScore: vocab,
      pronunciationScore: pronunciation,
      fillerCount: parsedFillerCount,
      detectedFillers: List<String>.unmodifiable(fillers),
      aiSummary: _asString(json['aiSummary']),
      recommendedCefrLevel: _normalizeCefr(json['recommendedCefrLevel']),
      mistakes: List<MistakeItemModel>.unmodifiable(mistakes),
      vocabSuggestions: List<VocabSuggestionModel>.unmodifiable(vocabSuggestions),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'overallScore': overallScore,
        'fluencyScore': fluencyScore,
        'grammarScore': grammarScore,
        'vocabScore': vocabScore,
        'pronunciationScore': pronunciationScore,
        'fillerCount': fillerCount,
        'detectedFillers': detectedFillers,
        'aiSummary': aiSummary,
        'recommendedCefrLevel': recommendedCefrLevel,
        'mistakes': mistakes.map((m) => m.toJson()).toList(growable: false),
        'vocabSuggestions':
            vocabSuggestions.map((v) => v.toJson()).toList(growable: false),
      };

  /// Removes leading/trailing markdown code fences (e.g. ````json ... ````)
  /// and extracts the outermost JSON object if extra prose surrounds it.
  static String stripMarkdownCodeFence(String raw) {
    var trimmed = raw.trim();
    if (trimmed.startsWith('```')) {
      final firstNewline = trimmed.indexOf('\n');
      if (firstNewline != -1) {
        trimmed = trimmed.substring(firstNewline + 1);
      } else {
        trimmed = trimmed.replaceFirst(RegExp(r'^```[a-zA-Z]*'), '');
      }
      final closingFence = trimmed.lastIndexOf('```');
      if (closingFence != -1) {
        trimmed = trimmed.substring(0, closingFence);
      }
      trimmed = trimmed.trim();
    }

    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start != -1 && end > start) {
        trimmed = trimmed.substring(start, end + 1);
      }
    }
    return trimmed;
  }
}

int _asInt(
  dynamic value, {
  int min = 0,
  int max = 100,
  int fallback = 0,
}) {
  int parsed;
  if (value is int) {
    parsed = value;
  } else if (value is num) {
    parsed = value.round();
  } else if (value is String) {
    final numValue = num.tryParse(value.trim());
    parsed = numValue != null ? numValue.round() : fallback;
  } else {
    parsed = fallback;
  }
  if (parsed < min) return min;
  if (parsed > max) return max;
  return parsed;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _normalizeCefr(dynamic value) {
  if (value == null) return null;
  final code = value.toString().trim().toUpperCase();
  const validCodes = <String>{'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
  return validCodes.contains(code) ? code : null;
}
