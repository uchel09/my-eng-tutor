import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../../core/constants/gemini_constants.dart';
import '../local/app_database.dart';
import '../local/daos/flashcard_dao.dart';
import '../models/speech_insight_model.dart';
import '../models/transcript_turn_model.dart';

/// AI-generated practice details, example sentences, and mini dialog for a flashcard.
class FlashcardPracticeAiResult {
  const FlashcardPracticeAiResult({
    required this.wordType,
    required this.phonetic,
    required this.meaningId,
    required this.examples,
    required this.conversation,
  });

  /// Classified part of speech category: `'verb'` or `'non_verb'`.
  final String wordType;
  final String phonetic;
  final String meaningId;
  final List<FlashcardExampleItem> examples;
  final String conversation;

  factory FlashcardPracticeAiResult.fromRawJson(
    String rawText, {
    String? fallbackMeaningId,
  }) {
    final cleaned = SpeechInsightModel.stripMarkdownCodeFence(rawText);
    dynamic decoded = jsonDecode(cleaned);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      decoded = decoded.first;
    }
    if (decoded is! Map) {
      throw const FormatException(
        'Respons latihan flashcard tidak berbentuk objek JSON yang valid.',
      );
    }
    return FlashcardPracticeAiResult.fromJson(
      Map<String, dynamic>.from(decoded),
      fallbackMeaningId: fallbackMeaningId,
    );
  }

  factory FlashcardPracticeAiResult.fromJson(
    Map<String, dynamic> json, {
    String? fallbackMeaningId,
  }) {
    final rawType = (json['wordType']?.toString() ?? '').trim().toLowerCase();
    final normalizedType = rawType == 'verb' ? 'verb' : 'non_verb';

    final rawExamples = json['examples'];
    final examples = <FlashcardExampleItem>[];
    if (rawExamples is List) {
      for (final item in rawExamples) {
        if (item is Map) {
          final parsed = FlashcardExampleItem.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (parsed.en.isNotEmpty) {
            examples.add(parsed);
          }
        }
      }
    }

    final parsedMeaning = (json['meaningId']?.toString() ?? '').trim();
    return FlashcardPracticeAiResult(
      wordType: normalizedType,
      phonetic: (json['phonetic']?.toString() ?? '').trim(),
      meaningId: parsedMeaning.isNotEmpty
          ? parsedMeaning
          : (fallbackMeaningId?.trim() ?? ''),
      examples: List<FlashcardExampleItem>.unmodifiable(examples),
      conversation: (json['conversation']?.toString() ?? '').trim(),
    );
  }
}

/// Multiple-choice quiz question generated for a specific [Flashcard] row.
class FlashcardQuizQuestion {
  const FlashcardQuizQuestion({
    required this.cardId,
    required this.word,
    required this.questionPrompt,
    required this.options,
    required this.correctIndex,
    required this.explanationId,
  });

  final int cardId;
  final String word;
  final String questionPrompt;
  final List<String> options;
  final int correctIndex;
  final String explanationId;
}

/// Word-level pronunciation feedback inside [SentencePronunciationFeedback].
class SentenceWordFeedback {
  const SentenceWordFeedback({
    required this.word,
    required this.status,
    required this.tipId,
  });

  final String word;

  /// One of `'good'`, `'needs_work'`, or `'missing'`.
  final String status;
  final String tipId;

  factory SentenceWordFeedback.fromJson(Map<String, dynamic> json) {
    final normalizedStatus = _normalizeWordStatus(json['status']);
    return SentenceWordFeedback(
      word: (json['word']?.toString() ?? '').trim(),
      status: normalizedStatus,
      tipId: (json['tipId']?.toString() ?? '').trim(),
    );
  }

  static String _normalizeWordStatus(dynamic rawStatus) {
    final raw = (rawStatus?.toString() ?? '').trim().toLowerCase();
    final compact = raw.replaceAll(RegExp(r'[\s\-]+'), '_');
    if (compact == 'good' || compact == 'correct' || compact == 'clear') {
      return 'good';
    }
    if (compact == 'missing' ||
        compact == 'omitted' ||
        compact == 'skipped' ||
        compact == 'absent') {
      return 'missing';
    }
    return 'needs_work';
  }
}

/// Pronunciation evaluation returned for a shadowed flashcard example sentence.
class SentencePronunciationFeedback {
  const SentencePronunciationFeedback({
    required this.score,
    required this.clarityScore,
    required this.intonationScore,
    required this.heardText,
    required this.overallFeedbackId,
    required this.wordFeedback,
    required this.practiceTipsId,
  });

  final int score;
  final int clarityScore;
  final int intonationScore;
  final String heardText;
  final String overallFeedbackId;
  final List<SentenceWordFeedback> wordFeedback;
  final List<String> practiceTipsId;

  factory SentencePronunciationFeedback.fromRawJson(String rawText) {
    final cleaned = SpeechInsightModel.stripMarkdownCodeFence(rawText);
    dynamic decoded = jsonDecode(cleaned);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      decoded = decoded.first;
    }
    if (decoded is! Map) {
      throw const FormatException(
        'Respons evaluasi pelafalan kalimat tidak berbentuk objek JSON yang valid.',
      );
    }
    return SentencePronunciationFeedback.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  factory SentencePronunciationFeedback.fromJson(Map<String, dynamic> json) {
    final overallScore = _clampScore(json['score'], fallback: 0);
    final clarity = _clampScore(json['clarityScore'], fallback: overallScore);
    final intonation = _clampScore(
      json['intonationScore'],
      fallback: overallScore,
    );

    final rawWords = json['wordFeedback'];
    final words = <SentenceWordFeedback>[];
    if (rawWords is List) {
      for (final item in rawWords) {
        if (item is Map) {
          final parsed = SentenceWordFeedback.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (parsed.word.isNotEmpty) {
            words.add(parsed);
          }
        }
      }
    }

    final rawTips = json['practiceTipsId'];
    final tips = <String>[];
    if (rawTips is List) {
      for (final tip in rawTips) {
        final text = (tip?.toString() ?? '').trim();
        if (text.isNotEmpty) {
          tips.add(text);
        }
      }
    }

    final heardText = (json['heardText']?.toString() ?? '').trim();
    final overallFeedback = (json['overallFeedbackId']?.toString() ?? '')
        .trim();

    return SentencePronunciationFeedback(
      score: overallScore,
      clarityScore: clarity,
      intonationScore: intonation,
      heardText: heardText,
      overallFeedbackId: overallFeedback.isNotEmpty
          ? overallFeedback
          : 'Latihan yang baik! Terus ucapkan kalimat ini perlahan lalu ke kecepatan normal.',
      wordFeedback: List<SentenceWordFeedback>.unmodifiable(words),
      practiceTipsId: List<String>.unmodifiable(tips),
    );
  }

  static int _clampScore(dynamic raw, {required int fallback}) {
    int parsed;
    if (raw is int) {
      parsed = raw;
    } else if (raw is num) {
      parsed = raw.round();
    } else if (raw is String) {
      final parsedNum = num.tryParse(raw.trim());
      parsed = parsedNum != null ? parsedNum.round() : fallback;
    } else {
      parsed = fallback;
    }
    if (parsed < 0) return 0;
    if (parsed > 100) return 100;
    return parsed;
  }
}

/// Active Gemini model IDs partitioned by Live WebSocket, REST scoring, and REST TTS capabilities.
class AvailableGeminiModels {
  const AvailableGeminiModels({
    required this.liveModels,
    required this.scoringModels,
    this.ttsModels = const <String>[],
  });

  final List<String> liveModels;
  final List<String> scoringModels;
  final List<String> ttsModels;
}

/// Exception representing REST API errors from Gemini with friendly Indonesian messages.
class GeminiApiException implements Exception {
  const GeminiApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'GeminiApiException($statusCode): $message';
}

/// Handles Gemini REST API calls for API key validation and post-session evaluation.
class GeminiRestProvider {
  GeminiRestProvider({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final http.Client _client;

  /// Fetches active models accessible by [apiKey] from `GET /v1beta/models`
  /// and separates Live WebSocket (`bidiGenerateContent`) vs REST Scoring
  /// (`generateContent`) models.
  Future<AvailableGeminiModels> fetchAvailableModels({
    required String apiKey,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const GeminiApiException(
        'API key Gemini belum diisi. Masukkan API key terlebih dahulu.',
        statusCode: 400,
      );
    }

    final uri = Uri.parse(
      '${GeminiConstants.restBaseUrl}/models?key=$trimmedKey',
    );

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 20));
    } on SocketException {
      throw const GeminiApiException(
        'Tidak ada koneksi internet. Periksa Wi-Fi atau data seluler Anda.',
      );
    } on TimeoutException {
      throw const GeminiApiException(
        'Permintaan daftar model ke Gemini timeout. Coba lagi sebentar.',
      );
    } on http.ClientException {
      throw const GeminiApiException(
        'Gagal menghubungi server Gemini. Periksa koneksi internet Anda.',
      );
    }

    if (response.statusCode != 200) {
      throw _mapHttpError(response.statusCode, response.body);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const GeminiApiException(
        'Respons daftar model Gemini tidak sesuai format JSON.',
        statusCode: 200,
      );
    }

    return parseAvailableModels(Map<String, dynamic>.from(decoded));
  }

  /// Parses a `/v1beta/models` JSON payload into categorized Live, Scoring, and TTS model IDs.
  static AvailableGeminiModels parseAvailableModels(
    Map<String, dynamic> responseJson,
  ) {
    final rawModels = responseJson['models'];
    if (rawModels is! List) {
      return const AvailableGeminiModels(
        liveModels: <String>[],
        scoringModels: <String>[],
        ttsModels: <String>[],
      );
    }

    final liveModels = <String>[];
    final scoringModels = <String>[];
    final ttsModels = <String>[];

    for (final entry in rawModels) {
      if (entry is! Map) continue;
      final rawName = entry['name']?.toString().trim() ?? '';
      if (rawName.isEmpty) continue;

      final modelId = rawName.startsWith('models/')
          ? rawName.substring('models/'.length)
          : rawName;
      final lowerId = modelId.toLowerCase();

      final methodsRaw = entry['supportedGenerationMethods'];
      final methods = methodsRaw is List
          ? methodsRaw.map((m) => m.toString()).toSet()
          : const <String>{};

      if (methods.contains('bidiGenerateContent')) {
        liveModels.add(modelId);
      }

      if (methods.contains('generateContent')) {
        if (lowerId.contains('tts')) {
          ttsModels.add(modelId);
        }
        if (!_isSpecializedNonScoringModel(lowerId)) {
          scoringModels.add(modelId);
        }
      }
    }

    liveModels.sort(_compareModelIds);
    scoringModels.sort(_compareModelIds);
    ttsModels.sort(_compareModelIds);

    return AvailableGeminiModels(
      liveModels: liveModels.toList(growable: false),
      scoringModels: scoringModels.toList(growable: false),
      ttsModels: ttsModels.toList(growable: false),
    );
  }

  static bool _isSpecializedNonScoringModel(String lowerId) {
    return lowerId.contains('embedding') ||
        lowerId.contains('imagen') ||
        lowerId.contains('veo') ||
        lowerId.contains('-tts') ||
        lowerId.contains('aqa');
  }

  static int _compareModelIds(String a, String b) {
    final aLower = a.toLowerCase();
    final bLower = b.toLowerCase();

    final aIsGemini = aLower.startsWith('gemini-');
    final bIsGemini = bLower.startsWith('gemini-');
    if (aIsGemini != bIsGemini) {
      return aIsGemini ? -1 : 1;
    }

    final aVersion = _extractVersionScore(aLower);
    final bVersion = _extractVersionScore(bLower);
    if (aVersion != bVersion) {
      return bVersion.compareTo(aVersion);
    }

    final aRank = _tierRank(aLower);
    final bRank = _tierRank(bLower);
    if (aRank != bRank) {
      return aRank.compareTo(bRank);
    }

    return aLower.compareTo(bLower);
  }

  static double _extractVersionScore(String lowerId) {
    final match = RegExp(r'gemini-(\d+(?:\.\d+)?)').firstMatch(lowerId);
    if (match == null) return 0;
    return double.tryParse(match.group(1) ?? '') ?? 0;
  }

  static int _tierRank(String lowerId) {
    if (lowerId.contains('flash') && !lowerId.contains('lite')) return 0;
    if (lowerId.contains('pro')) return 1;
    if (lowerId.contains('flash-lite') || lowerId.contains('lite')) return 2;
    return 3;
  }

  /// Verifies the user's [apiKey] and [model] with a lightweight `generateContent` call.
  Future<String> testConnection({
    required String apiKey,
    required String model,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const GeminiApiException(
        'API key Gemini belum diisi. Masukkan API key terlebih dahulu.',
        statusCode: 400,
      );
    }

    final payload = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': 'Reply with OK'},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'maxOutputTokens': 16,
        'temperature': 0,
      },
    };

    final responseJson = await _postGenerateContent(
      apiKey: trimmedKey,
      model: model,
      body: payload,
      timeout: const Duration(seconds: 20),
    );

    final text = _extractFirstCandidateText(responseJson);
    return text.isNotEmpty ? text : 'OK';
  }

  /// Evaluates a completed speaking session (transcript + optional WAV audio)
  /// and returns structured Stimuler-style feedback.
  Future<SpeechInsightModel> evaluateSpeakingSession({
    required String apiKey,
    required String model,
    required String targetCefrLevel,
    required String sessionType,
    required String lessonTitle,
    required String scenarioPrompt,
    required bool bilingualBeginnerSupport,
    required List<TranscriptTurnModel> transcript,
    Uint8List? recordedAudioWavBytes,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const GeminiApiException(
        'API key Gemini belum diatur. Silakan isi API key di Settings.',
        statusCode: 400,
      );
    }

    final normalizedCefr = targetCefrLevel.trim().toUpperCase();
    final isBeginnerIndonesian =
        bilingualBeginnerSupport &&
        (normalizedCefr == 'A1' || normalizedCefr == 'A2');
    final isPlacement = sessionType == 'placement';

    final prompt = _buildEvaluationPrompt(
      targetCefrLevel: normalizedCefr,
      sessionType: sessionType,
      lessonTitle: lessonTitle,
      scenarioPrompt: scenarioPrompt,
      isBeginnerIndonesian: isBeginnerIndonesian,
      isPlacement: isPlacement,
      transcript: transcript,
      hasAudioAttachment:
          recordedAudioWavBytes != null && recordedAudioWavBytes.isNotEmpty,
    );

    final parts = <Map<String, dynamic>>[
      <String, dynamic>{'text': prompt},
    ];
    if (recordedAudioWavBytes != null && recordedAudioWavBytes.isNotEmpty) {
      parts.add(<String, dynamic>{
        'inlineData': <String, dynamic>{
          'mimeType': 'audio/wav',
          'data': base64Encode(recordedAudioWavBytes),
        },
      });
    }

    final payload = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{'role': 'user', 'parts': parts},
      ],
      'generationConfig': <String, dynamic>{
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      },
    };

    final responseJson = await _postGenerateContent(
      apiKey: trimmedKey,
      model: model,
      body: payload,
      timeout: const Duration(seconds: 60),
    );

    final rawText = _extractFirstCandidateText(responseJson);
    if (rawText.trim().isEmpty) {
      throw const GeminiApiException(
        'Gemini tidak mengembalikan hasil evaluasi. Silakan coba lagi.',
      );
    }

    try {
      return SpeechInsightModel.fromRawJson(rawText);
    } on FormatException {
      throw const GeminiApiException(
        'Format respons evaluasi dari Gemini tidak valid. Silakan coba ulangi penilaian.',
      );
    }
  }

  /// Generates phonetic transcription, Indonesian meaning, contextual/tense
  /// example sentences, and a mini 2-4 line conversation for a flashcard word.
  Future<FlashcardPracticeAiResult> generateFlashcardPracticeContent({
    required String apiKey,
    required String model,
    required String word,
    String? currentMeaningId,
    String? wordTypeHint,
    bool includeAll16Tenses = false,
    List<String> avoidSentences = const [],
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const GeminiApiException(
        'API key Gemini belum diisi. Masukkan API key di Pengaturan terlebih dahulu.',
        statusCode: 400,
      );
    }

    final trimmedWord = word.trim();
    if (trimmedWord.isEmpty) {
      throw const GeminiApiException(
        'Kata atau frasa flashcard tidak boleh kosong.',
        statusCode: 400,
      );
    }

    final prompt = _buildFlashcardPracticePrompt(
      word: trimmedWord,
      currentMeaningId: currentMeaningId,
      wordTypeHint: wordTypeHint,
      includeAll16Tenses: includeAll16Tenses,
      avoidSentences: avoidSentences,
    );

    final payload = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': prompt},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'responseMimeType': 'application/json',
        'temperature': 0.45,
      },
    };

    final responseJson = await _postGenerateContent(
      apiKey: trimmedKey,
      model: model,
      body: payload,
      timeout: const Duration(seconds: 60),
    );

    final rawText = _extractFirstCandidateText(responseJson);
    if (rawText.trim().isEmpty) {
      throw const GeminiApiException(
        'Gemini tidak mengembalikan materi latihan kata. Silakan coba lagi.',
      );
    }

    try {
      return FlashcardPracticeAiResult.fromRawJson(
        rawText,
        fallbackMeaningId: currentMeaningId,
      );
    } on FormatException {
      throw const GeminiApiException(
        'Format materi latihan flashcard dari Gemini tidak valid. Silakan coba lagi.',
      );
    }
  }

  /// Generates up to [maxQuestions] multiple-choice quiz questions prioritized
  /// toward the cards with the lowest `masteryLevel`.
  Future<List<FlashcardQuizQuestion>> generateFlashcardQuiz({
    required String apiKey,
    required String model,
    required List<Flashcard> cards,
    required String scopeTitle,
    int maxQuestions = 15,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const GeminiApiException(
        'API key Gemini belum diisi. Masukkan API key di Pengaturan terlebih dahulu.',
        statusCode: 400,
      );
    }

    if (cards.isEmpty) {
      throw const GeminiApiException(
        'Belum ada kartu flashcard di cakupan ini untuk dibuat kuis.',
        statusCode: 400,
      );
    }

    final prioritized = List<Flashcard>.from(cards)
      ..sort((a, b) {
        final masteryCmp = a.masteryLevel.compareTo(b.masteryLevel);
        if (masteryCmp != 0) return masteryCmp;
        final reviewCmp = a.reviewCount.compareTo(b.reviewCount);
        if (reviewCmp != 0) return reviewCmp;
        return a.id.compareTo(b.id);
      });

    final cappedCount = maxQuestions < 1
        ? 1
        : (maxQuestions > prioritized.length
              ? prioritized.length
              : maxQuestions);
    final selectedCards = prioritized.take(cappedCount).toList(growable: false);

    final cardsById = <int, Flashcard>{
      for (final card in selectedCards) card.id: card,
    };
    final cardsByWord = <String, Flashcard>{
      for (final card in selectedCards) card.word.trim().toLowerCase(): card,
    };

    final prompt = _buildFlashcardQuizPrompt(
      selectedCards: selectedCards,
      scopeTitle: scopeTitle,
    );

    final payload = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': prompt},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'responseMimeType': 'application/json',
        'temperature': 0.35,
      },
    };

    final responseJson = await _postGenerateContent(
      apiKey: trimmedKey,
      model: model,
      body: payload,
      timeout: const Duration(seconds: 60),
    );

    final rawText = _extractFirstCandidateText(responseJson);
    if (rawText.trim().isEmpty) {
      throw const GeminiApiException(
        'Gemini tidak mengembalikan soal kuis. Silakan coba lagi.',
      );
    }

    try {
      return _parseQuizQuestions(
        rawText: rawText,
        cardsById: cardsById,
        cardsByWord: cardsByWord,
      );
    } on FormatException {
      throw const GeminiApiException(
        'Format soal kuis flashcard dari Gemini tidak valid. Silakan coba lagi.',
      );
    }
  }

  /// Evaluates user pronunciation of a shadowed English [targetSentence]
  /// from raw RIFF/WAVE audio bytes via Gemini multimodal `generateContent`.
  Future<SentencePronunciationFeedback> evaluateSentencePronunciation({
    required String apiKey,
    required String model,
    required String targetSentence,
    String? targetWord,
    required Uint8List audioWavBytes,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const GeminiApiException(
        'API key Gemini belum diisi. Masukkan API key di Pengaturan terlebih dahulu.',
        statusCode: 400,
      );
    }

    final trimmedSentence = targetSentence.trim();
    if (trimmedSentence.isEmpty) {
      throw const GeminiApiException(
        'Kalimat target latihan tidak boleh kosong.',
        statusCode: 400,
      );
    }

    if (audioWavBytes.isEmpty) {
      throw const GeminiApiException(
        'Rekaman suara kosong. Coba rekam ulang kalimat tersebut.',
        statusCode: 400,
      );
    }

    final prompt = _buildSentencePronunciationPrompt(
      targetSentence: trimmedSentence,
      targetWord: targetWord,
    );

    final payload = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': prompt},
            <String, dynamic>{
              'inlineData': <String, dynamic>{
                'mimeType': 'audio/wav',
                'data': base64Encode(audioWavBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      },
    };

    final responseJson = await _postGenerateContent(
      apiKey: trimmedKey,
      model: model,
      body: payload,
      timeout: const Duration(seconds: 60),
    );

    final rawText = _extractFirstCandidateText(responseJson);
    if (rawText.trim().isEmpty) {
      throw const GeminiApiException(
        'Gemini tidak mengembalikan hasil penilaian pelafalan. Silakan coba lagi.',
      );
    }

    try {
      return SentencePronunciationFeedback.fromRawJson(rawText);
    } on FormatException {
      throw const GeminiApiException(
        'Format hasil evaluasi pelafalan dari Gemini tidak valid. Silakan coba lagi.',
      );
    }
  }

  /// Extracts raw 24kHz PCM16 bytes from a Gemini TTS audio payload.
  ///
  /// When [rawBytes] contains a RIFF/WAVE container, locates the `'data'` chunk
  /// and returns its sample payload; otherwise returns [rawBytes] unchanged.
  @visibleForTesting
  static Uint8List extractPcm24kFromAudioPayload(
    Uint8List rawBytes, {
    String mimeType = '',
  }) {
    if (rawBytes.length >= 12 &&
        rawBytes[0] == 0x52 && // 'R'
        rawBytes[1] == 0x49 && // 'I'
        rawBytes[2] == 0x46 && // 'F'
        rawBytes[3] == 0x46 && // 'F'
        rawBytes[8] == 0x57 && // 'W'
        rawBytes[9] == 0x41 && // 'A'
        rawBytes[10] == 0x56 && // 'V'
        rawBytes[11] == 0x45) // 'E'
    {
      final view = ByteData.view(
        rawBytes.buffer,
        rawBytes.offsetInBytes,
        rawBytes.length,
      );
      var offset = 12;
      while (offset + 8 <= rawBytes.length) {
        final chunkId = String.fromCharCodes(rawBytes, offset, offset + 4);
        final chunkSize = view.getUint32(offset + 4, Endian.little);
        final dataStart = offset + 8;
        final isUnbounded =
            chunkSize == 0xFFFFFFFF || dataStart + chunkSize > rawBytes.length;
        final dataEnd = isUnbounded ? rawBytes.length : dataStart + chunkSize;

        if (chunkId == 'data') {
          return Uint8List.fromList(rawBytes.sublist(dataStart, dataEnd));
        }

        final paddedSize = chunkSize + (chunkSize.isOdd ? 1 : 0);
        if (paddedSize <= 0) break;
        offset = dataStart + paddedSize;
      }

      if (rawBytes.length > 44) {
        return Uint8List.fromList(rawBytes.sublist(44));
      }
      return Uint8List(0);
    }

    return rawBytes;
  }

  /// Synthesizes speech via Gemini REST `generateContent` (`responseModalities: ['AUDIO']`)
  /// and returns raw 24kHz PCM16 audio bytes.
  Future<Uint8List> synthesizeSpeechPcm24k({
    required String apiKey,
    required String model,
    required String text,
    bool slow = false,
    String voiceName = GeminiConstants.defaultTtsVoice,
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw const GeminiApiException(
        'API key Gemini belum diisi. Masukkan API key di Pengaturan terlebih dahulu.',
        statusCode: 400,
      );
    }

    final trimmedModel = model.trim();
    if (trimmedModel.isEmpty) {
      throw const GeminiApiException(
        'Model TTS Gemini belum dipilih.',
        statusCode: 400,
      );
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw const GeminiApiException(
        'Teks untuk sintesis suara tidak boleh kosong.',
        statusCode: 400,
      );
    }

    final directivePrompt = slow
        ? 'Say slowly and clearly for an English learner: $trimmedText'
        : 'Say naturally: $trimmedText';

    final payload = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'user',
          'parts': <Map<String, dynamic>>[
            <String, dynamic>{'text': directivePrompt},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'responseModalities': <String>['AUDIO'],
        'speechConfig': <String, dynamic>{
          'voiceConfig': <String, dynamic>{
            'prebuiltVoiceConfig': <String, dynamic>{'voiceName': voiceName},
          },
        },
      },
    };

    final responseJson = await _postGenerateContent(
      apiKey: trimmedKey,
      model: trimmedModel,
      body: payload,
      timeout: const Duration(seconds: 15),
    );

    final inlineAudio = _extractFirstAudioInlineData(responseJson);
    if (inlineAudio == null || inlineAudio.base64Data.isEmpty) {
      throw const GeminiApiException(
        'Gemini tidak mengembalikan data audio TTS. Silakan coba lagi.',
      );
    }

    Uint8List decodedBytes;
    try {
      decodedBytes = base64Decode(inlineAudio.base64Data);
    } on FormatException {
      throw const GeminiApiException(
        'Format base64 audio TTS dari Gemini tidak valid.',
      );
    }

    final pcmBytes = extractPcm24kFromAudioPayload(
      decodedBytes,
      mimeType: inlineAudio.mimeType,
    );
    if (pcmBytes.isEmpty) {
      throw const GeminiApiException('Payload audio TTS dari Gemini kosong.');
    }
    return pcmBytes;
  }

  ({String mimeType, String base64Data})? _extractFirstAudioInlineData(
    Map<String, dynamic> responseJson,
  ) {
    final candidates = responseJson['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map) return null;

    final content = firstCandidate['content'];
    if (content is! Map) return null;

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;

    for (final part in parts) {
      if (part is! Map) continue;
      final inlineData = part['inlineData'] ?? part['inline_data'];
      if (inlineData is! Map) continue;
      final data = (inlineData['data']?.toString() ?? '').trim();
      if (data.isEmpty) continue;
      final mimeType = (inlineData['mimeType'] ?? inlineData['mime_type'] ?? '')
          .toString()
          .trim();
      return (mimeType: mimeType, base64Data: data);
    }
    return null;
  }

  Future<Map<String, dynamic>> _postGenerateContent({
    required String apiKey,
    required String model,
    required Map<String, dynamic> body,
    required Duration timeout,
  }) async {
    final cleanModel = model.startsWith('models/')
        ? model.substring('models/'.length)
        : model;
    final uri = Uri.parse(
      '${GeminiConstants.restBaseUrl}/models/$cleanModel:generateContent?key=$apiKey',
    );

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on SocketException {
      throw const GeminiApiException(
        'Tidak ada koneksi internet. Periksa Wi-Fi atau data seluler Anda.',
      );
    } on TimeoutException {
      throw const GeminiApiException(
        'Permintaan ke Gemini timeout. Koneksi lambat atau server sedang sibuk.',
      );
    } on http.ClientException {
      throw const GeminiApiException(
        'Gagal menghubungi server Gemini. Periksa koneksi internet Anda.',
      );
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw const GeminiApiException(
        'Respons server Gemini tidak sesuai format JSON.',
        statusCode: 200,
      );
    }

    throw _mapHttpError(
      response.statusCode,
      response.body,
      attemptedModel: cleanModel,
    );
  }

  GeminiApiException _mapHttpError(
    int statusCode,
    String body, {
    String? attemptedModel,
  }) {
    final rawDetail = _extractApiErrorMessage(body).trim();
    final detail = rawDetail.toLowerCase();

    if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
      if (detail.contains('api key') ||
          detail.contains('permission') ||
          detail.contains('unauthenticated') ||
          statusCode == 401 ||
          statusCode == 403) {
        return GeminiApiException(
          'API key Gemini tidak valid atau tidak memiliki izin akses. Periksa kembali di Settings.',
          statusCode: statusCode,
        );
      }
      return GeminiApiException(
        'Permintaan ditolak Gemini (HTTP $statusCode). Periksa API key dan nama model di Settings.',
        statusCode: statusCode,
      );
    }

    if (statusCode == 404) {
      final modelLabel = (attemptedModel != null && attemptedModel.isNotEmpty)
          ? ' "$attemptedModel"'
          : '';
      final detailNote = rawDetail.isNotEmpty ? ' Detail: $rawDetail.' : '';
      return GeminiApiException(
        'Model Gemini$modelLabel tidak ditemukan (HTTP 404).$detailNote Ketuk "Muat Model dari API Key" atau pilih model lain di Settings.',
        statusCode: statusCode,
      );
    }

    if (statusCode == 429) {
      return const GeminiApiException(
        'Batas pemakaian Free Tier Gemini tercapai (HTTP 429). Tunggu 1 menit lalu coba lagi.',
        statusCode: 429,
      );
    }

    if (statusCode >= 500) {
      return GeminiApiException(
        'Server Gemini sedang mengalami gangguan sementara (HTTP $statusCode). Coba lagi sebentar lagi.',
        statusCode: statusCode,
      );
    }

    return GeminiApiException(
      'Gagal berkomunikasi dengan Gemini (HTTP $statusCode).',
      statusCode: statusCode,
    );
  }

  String _extractApiErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        return (decoded['error'] as Map)['message']?.toString() ?? '';
      }
    } catch (_) {
      // Ignore non-JSON error payloads.
    }
    return body;
  }

  String _extractFirstCandidateText(Map<String, dynamic> responseJson) {
    final candidates = responseJson['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map) return '';

    final content = firstCandidate['content'];
    if (content is! Map) return '';

    final parts = content['parts'];
    if (parts is! List) return '';

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }
    return buffer.toString().trim();
  }

  String _buildEvaluationPrompt({
    required String targetCefrLevel,
    required String sessionType,
    required String lessonTitle,
    required String scenarioPrompt,
    required bool isBeginnerIndonesian,
    required bool isPlacement,
    required List<TranscriptTurnModel> transcript,
    required bool hasAudioAttachment,
  }) {
    final transcriptBuffer = StringBuffer();
    if (transcript.isEmpty) {
      transcriptBuffer.writeln(
        '(No text transcript captured; rely on audio if attached.)',
      );
    } else {
      for (final turn in transcript) {
        final speaker = turn.role == 'tutor' ? 'Tutor' : 'Learner';
        transcriptBuffer.writeln('$speaker: ${turn.text}');
      }
    }

    final feedbackLanguageRule = isBeginnerIndonesian
        ? 'Write "aiSummary" and every "mistakes[].explanation" in warm, beginner-friendly Bahasa Indonesia (keep English example words/phrases in English).'
        : 'Write "aiSummary" and every "mistakes[].explanation" in clear, encouraging English.';

    final placementRule = isPlacement
        ? 'Because sessionType is "placement", you MUST set "recommendedCefrLevel" to exactly one of "A1", "A2", "B1", "B2", "C1", or "C2" reflecting the learner\'s demonstrated speaking level.'
        : 'Set "recommendedCefrLevel" to null unless placement assessment is requested.';

    final audioInstruction = hasAudioAttachment
        ? 'An audio recording of the learner is attached as WAV. Evaluate pronunciation clarity, pacing, hesitation, and filler words directly from the audio as well as the transcript.'
        : 'Evaluate pronunciation clarity conservatively from flow, phrasing, and intelligibility cues in the transcript.';

    return '''
You are an expert English speaking coach (similar to Stimuler). Evaluate the learner's English speaking performance fairly according to CEFR level $targetCefrLevel.

Session Metadata:
- sessionType: $sessionType
- lessonTitle: $lessonTitle
- scenarioPrompt: $scenarioPrompt
- targetCefrLevel: $targetCefrLevel

Instructions:
1. Score each dimension from 0 to 100 (integers):
   - fluencyScore (pacing, continuity, minimal awkward pauses)
   - grammarScore (tense accuracy, sentence structure)
   - vocabScore (lexical variety and appropriateness for $targetCefrLevel)
   - pronunciationScore (clarity and articulation)
   - overallScore (holistic weighted score 0-100)
2. Count filler words used by the learner ("um", "uh", "like", "you know", "anu", etc.) in "fillerCount" and list distinct fillers found in "detectedFillers".
3. Extract specific learner mistakes into "mistakes" (max 5 most impactful items) with:
   - originalSentence
   - correctedSentence
   - explanation
   - category (one of: "grammar", "vocabulary", "pronunciation", "fluency")
4. Suggest 2 to 4 useful next-step words/phrases in "vocabSuggestions" with:
   - word
   - meaningId (concise Indonesian meaning)
   - exampleSentence (natural English example)
   - cefrLevel ("A1", "A2", "B1", "B2", "C1", or "C2")
5. $feedbackLanguageRule
6. $placementRule
7. $audioInstruction

Return ONLY strict JSON matching this schema (no markdown fences):
{
  "overallScore": 78,
  "fluencyScore": 76,
  "grammarScore": 74,
  "vocabScore": 80,
  "pronunciationScore": 82,
  "fillerCount": 2,
  "detectedFillers": ["um", "like"],
  "aiSummary": "string",
  "recommendedCefrLevel": ${isPlacement ? '"B1"' : 'null'},
  "mistakes": [
    {
      "originalSentence": "string",
      "correctedSentence": "string",
      "explanation": "string",
      "category": "grammar"
    }
  ],
  "vocabSuggestions": [
    {
      "word": "string",
      "meaningId": "string",
      "exampleSentence": "string",
      "cefrLevel": "B1"
    }
  ]
}

Conversation Transcript:
$transcriptBuffer
''';
  }

  String _buildFlashcardPracticePrompt({
    required String word,
    String? currentMeaningId,
    String? wordTypeHint,
    required bool includeAll16Tenses,
    required List<String> avoidSentences,
  }) {
    final meaningHintLine =
        (currentMeaningId != null && currentMeaningId.trim().isNotEmpty)
        ? '- Known Indonesian meaning hint: "${currentMeaningId.trim()}"\n'
        : '';
    final typeHintLine =
        (wordTypeHint != null && wordTypeHint.trim().isNotEmpty)
        ? '- Word type hint from user/card: "${wordTypeHint.trim()}"\n'
        : '';

    final examplesRule = includeAll16Tenses
        ? '''
- Since "wordType" may be "verb" and full 16 tenses mode is enabled:
  * If the word is "verb", generate EXACTLY 16 example sentences covering all 16 English tenses in order (Simple Present, Present Continuous, Present Perfect, Present Perfect Continuous, Simple Past, Past Continuous, Past Perfect, Past Perfect Continuous, Simple Future, Future Continuous, Future Perfect, Future Perfect Continuous, Simple Future Past, Future Past Continuous, Future Past Perfect, Future Past Perfect Continuous), setting "tense" to each exact tense name.
  * If the word is strictly "non_verb" (e.g., noun, adjective, adverb, idiom), generate 5 to 6 natural contextual example sentences and label "tense" with a short context tag (such as "Daily Use", "Workplace", "Conversation", "Travel").'''
        : '''
- Sentence examples rule:
  * If "wordType" is "verb", generate at least 5 natural, practical example sentences showcasing useful tense variety (label "tense" with the actual English tense name, e.g., "Simple Present", "Simple Past", "Present Perfect").
  * If "wordType" is "non_verb", generate at least 5 everyday natural example sentences matching how the word or phrase is commonly used (label "tense" with a concise context tag like "Daily Use", "Conversation", "Business", NOT forced into 16 tenses).''';

    final avoidSection = avoidSentences.isNotEmpty
        ? '''
- IMPORTANT: Do NOT repeat or slightly rephrase any of these previously seen English sentences. Generate completely fresh sentences instead:
${avoidSentences.map((s) => '  * $s').join('\n')}'''
        : '';

    return '''
You are an expert bilingual English-Indonesian vocabulary coach.
Generate rich study content for the English target word or phrase: "$word"
$meaningHintLine$typeHintLine
Requirements:
1. Determine "wordType": return "verb" if the target word is commonly used as an English verb (or matches wordTypeHint "verb"), otherwise return "non_verb".
2. Provide accurate IPA "phonetic" notation (e.g., "/ˈɑːr.tɪ.kjə.leɪt/").
3. Provide a clear, concise Indonesian translation in "meaningId".
4. Populate "examples" array where each item has "tense", "en" (natural English sentence using "$word"), and "id" (natural Indonesian translation):
$examplesRule
$avoidSection
5. Provide "conversation": a natural 2 to 4 line mini dialog between "A:" and "B:" in English using the target word/phrase naturally, followed directly below by a concise Indonesian translation section.

Return ONLY strict JSON matching this schema (no markdown fences):
{
  "wordType": "verb",
  "phonetic": "/.../",
  "meaningId": "arti bahasa Indonesia",
  "examples": [
    {
      "tense": "Simple Present",
      "en": "English example sentence.",
      "id": "Terjemahan bahasa Indonesia."
    }
  ],
  "conversation": "A: ...\\nB: ...\\n\\nTerjemahan:\\nA: ...\\nB: ..."
}
''';
  }

  String _buildFlashcardQuizPrompt({
    required List<Flashcard> selectedCards,
    required String scopeTitle,
  }) {
    final cardsBuffer = StringBuffer();
    for (final card in selectedCards) {
      cardsBuffer.writeln(
        '- cardId: ${card.id} | word: "${card.word}" | meaningId: "${card.meaningId}" | wordType: ${card.wordType}',
      );
    }

    return '''
You are an English vocabulary quiz designer for an Indonesian learner.
Scope title: "$scopeTitle"
Create 1 multiple-choice English question for each target card below (${selectedCards.length} total questions):

Target Cards:
$cardsBuffer

Question Design Rules:
1. Vary question styles naturally across the quiz:
   - Fill-in-the-blank sentence ("Complete the sentence: ... ____ ...") testing contextual usage
   - Contextual meaning / best English paraphrase
   - Natural synonym or closest context match
2. Each question MUST include the exact matching integer "cardId" and "word" from Target Cards above.
3. "questionPrompt" must be clear English (no spoilers giving away the Indonesian meaning directly unless testing translation), with EXACTLY 4 distinct choices in "options" and a valid 0-based "correctIndex" (0, 1, 2, or 3).
4. "explanationId" must concisely explain the answer and meaning in warm Bahasa Indonesia.

Return ONLY strict JSON matching this schema (no markdown fences):
{
  "questions": [
    {
      "cardId": 1,
      "word": "example",
      "questionPrompt": "Choose the word that best completes the sentence: She gave a clear ____ during the presentation.",
      "options": ["example", "option2", "option3", "option4"],
      "correctIndex": 0,
      "explanationId": "'example' berarti contoh; paling sesuai melengkapi kalimat."
    }
  ]
}
''';
  }

  List<FlashcardQuizQuestion> _parseQuizQuestions({
    required String rawText,
    required Map<int, Flashcard> cardsById,
    required Map<String, Flashcard> cardsByWord,
  }) {
    final cleaned = SpeechInsightModel.stripMarkdownCodeFence(rawText);
    final decoded = jsonDecode(cleaned);

    final List<dynamic> rawList;
    if (decoded is Map && decoded['questions'] is List) {
      rawList = decoded['questions'] as List<dynamic>;
    } else if (decoded is List) {
      rawList = decoded;
    } else {
      throw const FormatException('Quiz JSON must contain a questions list.');
    }

    final results = <FlashcardQuizQuestion>[];
    for (final entry in rawList) {
      if (entry is! Map) continue;
      final item = Map<String, dynamic>.from(entry);

      final rawCardId = item['cardId'];
      final parsedId = rawCardId is int
          ? rawCardId
          : int.tryParse(rawCardId?.toString() ?? '');
      final rawWord = (item['word']?.toString() ?? '').trim();

      final matchedCard =
          (parsedId != null ? cardsById[parsedId] : null) ??
          cardsByWord[rawWord.toLowerCase()];
      if (matchedCard == null) continue;

      final promptText = (item['questionPrompt']?.toString() ?? '').trim();
      final rawOptions = item['options'];
      if (promptText.isEmpty || rawOptions is! List) continue;

      final options = rawOptions
          .map((opt) => opt?.toString().trim() ?? '')
          .where((opt) => opt.isNotEmpty)
          .take(4)
          .toList(growable: false);
      if (options.length < 4) continue;

      final rawCorrectIdx = item['correctIndex'];
      final correctIdx = rawCorrectIdx is int
          ? rawCorrectIdx
          : int.tryParse(rawCorrectIdx?.toString() ?? '') ?? 0;
      if (correctIdx < 0 || correctIdx >= options.length) continue;

      results.add(
        FlashcardQuizQuestion(
          cardId: matchedCard.id,
          word: matchedCard.word,
          questionPrompt: promptText,
          options: options,
          correctIndex: correctIdx,
          explanationId: (item['explanationId']?.toString() ?? '').trim(),
        ),
      );
    }

    if (results.isEmpty) {
      throw const FormatException('No valid quiz questions parsed.');
    }
    return results;
  }

  String _buildSentencePronunciationPrompt({
    required String targetSentence,
    String? targetWord,
  }) {
    final trimmedTargetWord = targetWord?.trim();
    final focusLine =
        (trimmedTargetWord != null && trimmedTargetWord.isNotEmpty)
        ? '- Target vocabulary word to inspect closely: "$trimmedTargetWord"\n'
        : '';

    return '''
You are an encouraging, accurate English pronunciation coach evaluating an Indonesian learner's speech recording.
Target sentence the learner was practicing:
"$targetSentence"
$focusLine
Instructions:
1. Listen directly to the attached WAV audio and transcribe objectively what was heard in "heardText" (write "(tidak terdengar jelas)" if the audio is silent or unintelligible).
2. Compare the learner's pronunciation carefully against the target sentence (paying special attention to any target vocabulary word if listed). Score honestly but supportively from 0 to 100 for:
   - "score": overall pronunciation accuracy
   - "clarityScore": consonant/vowel articulation & intelligibility
   - "intonationScore": word stress, rhythm, and natural phrasing
3. Break down the sentence word by word in "wordFeedback" following the exact order of words in the target sentence. For each word set:
   - "status": strictly one of "good", "needs_work", or "missing"
   - "tipId": short actionable coaching note in Bahasa Indonesia if status is "needs_work" or "missing" (or "" if "good")
4. Write "overallFeedbackId" in warm, constructive Bahasa Indonesia.
5. Provide 1 to 3 concrete, practical tips in "practiceTipsId" in Bahasa Indonesia (focusing on specific vowel sounds, final consonants, word stress, or connected speech).

Return ONLY strict JSON matching this schema (no markdown fences):
{
  "score": 84,
  "clarityScore": 86,
  "intonationScore": 80,
  "heardText": "transcription of what was heard",
  "overallFeedbackId": "Pelafalan cukup jelas...",
  "wordFeedback": [
    {
      "word": "example",
      "status": "good",
      "tipId": ""
    },
    {
      "word": "word",
      "status": "needs_work",
      "tipId": "Tekankan konsonan akhir /d/ lebih jelas."
    }
  ],
  "practiceTipsId": [
    "Perhatikan panjang vokal dan penekanan suku kata..."
  ]
}
''';
  }
}
