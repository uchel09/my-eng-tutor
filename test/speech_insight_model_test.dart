import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:my_english_tutor/app/data/models/speech_insight_model.dart';
import 'package:my_english_tutor/app/data/models/transcript_turn_model.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';

void main() {
  group('TranscriptTurnModel', () {
    test('round-trips single turn and turn list via JSON', () {
      final ts = DateTime.utc(2026, 11, 13, 8, 30, 15);
      final original = [
        TranscriptTurnModel(
          role: 'user',
          text: 'Hello, my name is Budi.',
          timestamp: ts,
        ),
        TranscriptTurnModel(
          role: 'tutor',
          text: 'Nice to meet you, Budi!',
          timestamp: ts.add(const Duration(seconds: 4)),
        ),
      ];

      final encoded = TranscriptTurnModel.encodeList(original);
      final decoded = TranscriptTurnModel.decodeList(encoded);

      expect(decoded, hasLength(2));
      expect(decoded[0].role, equals('user'));
      expect(decoded[0].text, equals('Hello, my name is Budi.'));
      expect(decoded[0].timestamp.toUtc(), equals(ts));
      expect(decoded[1].role, equals('tutor'));
      expect(decoded[1].text, equals('Nice to meet you, Budi!'));
    });

    test('handles missing/invalid fields defensively', () {
      final turn = TranscriptTurnModel.fromJson(<String, dynamic>{
        'role': 'UNKNOWN',
        'text': null,
        'timestamp': 'not-a-date',
      });
      expect(turn.role, equals('user'));
      expect(turn.text, equals(''));
      expect(turn.timestamp, isA<DateTime>());
    });
  });

  group('SpeechInsightModel', () {
    test('fromRawJson strips markdown ```json code fences cleanly', () {
      const rawResponse = '''
Here is the evaluation:
```json
{
  "overallScore": 84.6,
  "fluencyScore": 82.2,
  "grammarScore": "79.5",
  "vocabScore": 88,
  "pronunciationScore": 89,
  "fillerCount": 2.0,
  "detectedFillers": ["um", "like"],
  "aiSummary": "Bagus sekali! Alur bicaramu cukup lancar.",
  "recommendedCefrLevel": "b1",
  "mistakes": [
    {
      "originalSentence": "I am go to office yesterday.",
      "correctedSentence": "I went to the office yesterday.",
      "explanation": "Gunakan bentuk lampau 'went' untuk kejadian kemarin.",
      "category": "grammar"
    }
  ],
  "vocabSuggestions": [
    {
      "word": "commute",
      "meaningId": "perjalanan rutin ke kantor",
      "exampleSentence": "My morning commute takes 30 minutes.",
      "cefrLevel": "b1"
    }
  ]
}
```
''';

      final insight = SpeechInsightModel.fromRawJson(rawResponse);

      expect(insight.overallScore, equals(85));
      expect(insight.fluencyScore, equals(82));
      expect(insight.grammarScore, equals(80));
      expect(insight.vocabScore, equals(88));
      expect(insight.pronunciationScore, equals(89));
      expect(insight.fillerCount, equals(2));
      expect(insight.detectedFillers, equals(['um', 'like']));
      expect(insight.recommendedCefrLevel, equals('B1'));
      expect(insight.mistakes, hasLength(1));
      expect(
        insight.mistakes.first.correctedSentence,
        equals('I went to the office yesterday.'),
      );
      expect(insight.vocabSuggestions, hasLength(1));
      expect(insight.vocabSuggestions.first.cefrLevel, equals('B1'));
    });

    test('fromJson handles double scores, out-of-range values, and nulls', () {
      final insight = SpeechInsightModel.fromJson(<String, dynamic>{
        'fluencyScore': 72.4,
        'grammarScore': 120.0,
        'vocabScore': -5,
        'pronunciationScore': 80.5,
        'fillerCount': null,
        'detectedFillers': ['uh', null, ''],
        'aiSummary': null,
        'recommendedCefrLevel': null,
        'mistakes': null,
        'vocabSuggestions': [
          <String, dynamic>{'word': ''},
          <String, dynamic>{
            'word': 'articulate',
            'meaningId': 'fasih dan jelas',
            'exampleSentence': 'She is very articulate.',
            'cefrLevel': null,
          },
        ],
      });

      expect(insight.fluencyScore, equals(72));
      expect(insight.grammarScore, equals(100));
      expect(insight.vocabScore, equals(0));
      expect(insight.pronunciationScore, equals(81));
      // Computed average of (72 + 100 + 0 + 81) / 4 = 63.25 -> 63
      expect(insight.overallScore, equals(63));
      expect(insight.fillerCount, equals(1));
      expect(insight.detectedFillers, equals(['uh']));
      expect(insight.aiSummary, equals(''));
      expect(insight.recommendedCefrLevel, isNull);
      expect(insight.mistakes, isEmpty);
      expect(insight.vocabSuggestions, hasLength(1));
      expect(insight.vocabSuggestions.first.word, equals('articulate'));
      expect(insight.vocabSuggestions.first.cefrLevel, equals('B1'));
    });
  });

  group('GeminiRestProvider fetchAvailableModels & 404 details', () {
    test('fetchAvailableModels strips prefix, filters specialized models, and prioritizes newest gemini-*', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1beta/models');
        expect(request.url.queryParameters['key'], 'AIzaTestKey');

        return http.Response(
          jsonEncode(<String, dynamic>{
            'models': [
              {
                'name': 'models/text-embedding-004',
                'supportedGenerationMethods': ['embedContent'],
              },
              {
                'name': 'models/gemini-2.5-flash-preview-tts',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/gemini-2.5-flash',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/gemini-3.8-flash',
                'supportedGenerationMethods': ['generateContent'],
              },
              {
                'name': 'models/gemini-3.8-live',
                'supportedGenerationMethods': ['bidiGenerateContent'],
              },
              {
                'name': 'models/gemini-2.0-flash-live-001',
                'supportedGenerationMethods': ['bidiGenerateContent', 'generateContent'],
              },
            ],
          }),
          200,
        );
      });

      final provider = GeminiRestProvider(httpClient: mockClient);
      final result = await provider.fetchAvailableModels(apiKey: 'AIzaTestKey');

      expect(result.liveModels, equals(['gemini-3.8-live', 'gemini-2.0-flash-live-001']));
      expect(result.scoringModels.first, equals('gemini-3.8-flash'));
      expect(result.scoringModels, contains('gemini-2.5-flash'));
      expect(result.scoringModels, isNot(contains('text-embedding-004')));
      expect(result.scoringModels, isNot(contains('gemini-2.5-flash-preview-tts')));
    });

    test('testConnection surfaces model name and Google 404 error detail', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'error': {
              'code': 404,
              'message': 'models/gemini-2.5-flash is not found for API version v1beta.',
            },
          }),
          404,
        );
      });

      final provider = GeminiRestProvider(httpClient: mockClient);
      await expectLater(
        () => provider.testConnection(apiKey: 'AIzaTestKey', model: 'gemini-2.5-flash'),
        throwsA(
          isA<GeminiApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', contains('gemini-2.5-flash'))
              .having((e) => e.message, 'message', contains('is not found')),
        ),
      );
    });
  });
}
