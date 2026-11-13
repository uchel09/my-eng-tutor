@Timeout(Duration(seconds: 25))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart' hide Value;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:my_english_tutor/app/core/constants/gemini_constants.dart';
import 'package:my_english_tutor/app/core/theme/app_theme.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/local/daos/settings_dao.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/repositories/tutor_repository.dart';
import 'package:my_english_tutor/app/data/services/audio_service.dart';
import 'package:my_english_tutor/app/data/services/tts_service.dart';
import 'package:my_english_tutor/app/modules/settings/controllers/settings_controller.dart';
import 'package:my_english_tutor/app/modules/settings/views/settings_view.dart';

class _FakeAudioService extends AudioService {
  final List<Uint8List> playPcm24kCalls = <Uint8List>[];
  int clearAndStopCalls = 0;
  VoidCallback? lastOnCompleted;
  Completer<void>? _playbackCompleter;
  bool holdPlaybackUntilTriggered = false;

  @override
  Future<void> playPcm24kBuffer(
    Uint8List fullPcmBytes, {
    VoidCallback? onCompleted,
  }) async {
    playPcm24kCalls.add(fullPcmBytes);
    lastOnCompleted = onCompleted;
    if (holdPlaybackUntilTriggered) {
      _playbackCompleter = Completer<void>();
      await _playbackCompleter!.future;
    }
    onCompleted?.call();
  }

  @override
  Future<void> clearAndStopPlayer() async {
    clearAndStopCalls += 1;
    if (_playbackCompleter != null && !_playbackCompleter!.isCompleted) {
      _playbackCompleter!.complete();
    }
  }

  void triggerCompleted() {
    if (_playbackCompleter != null && !_playbackCompleter!.isCompleted) {
      _playbackCompleter!.complete();
    }
    final cb = lastOnCompleted;
    lastOnCompleted = null;
    cb?.call();
  }
}

class _FakeFlutterTts extends FlutterTts {
  VoidCallback? _start;
  VoidCallback? _completion;
  VoidCallback? _cancel;
  ErrorHandler? _error;

  final List<String> spokenTexts = <String>[];
  final List<double> speechRates = <double>[];
  final List<String> languages = <String>[];
  int stopCalls = 0;
  bool autoComplete = false;

  @override
  void setStartHandler(VoidCallback callback) {
    _start = callback;
  }

  @override
  void setCompletionHandler(VoidCallback callback) {
    _completion = callback;
  }

  @override
  void setCancelHandler(VoidCallback callback) {
    _cancel = callback;
  }

  @override
  void setErrorHandler(ErrorHandler handler) {
    _error = handler;
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    languages.add(language);
    return 1;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    speechRates.add(rate);
    return 1;
  }

  @override
  Future<dynamic> setPitch(double pitch) async => 1;

  @override
  Future<dynamic> setVolume(double volume) async => 1;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spokenTexts.add(text);
    _start?.call();
    if (autoComplete) {
      _completion?.call();
    }
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    stopCalls += 1;
    _cancel?.call();
    return 1;
  }

  void triggerCompletion() {
    _completion?.call();
  }

  void triggerError(String message) {
    _error?.call(message);
  }
}

Uint8List _buildTestWav(
  List<int> pcmBytes, {
  bool withExtraListChunk = false,
}) {
  final extraChunkBytes = withExtraListChunk ? <int>[0x49, 0x4E, 0x46, 0x4F] : <int>[];
  final extraSectionLength = withExtraListChunk ? (8 + extraChunkBytes.length) : 0;
  final totalSize = 12 + 24 + extraSectionLength + 8 + pcmBytes.length;
  final data = Uint8List(totalSize);
  final view = ByteData.sublistView(data);
  var offset = 0;

  void writeAscii(String s) {
    for (var i = 0; i < s.length; i++) {
      data[offset++] = s.codeUnitAt(i);
    }
  }

  writeAscii('RIFF');
  view.setUint32(offset, totalSize - 8, Endian.little);
  offset += 4;
  writeAscii('WAVE');

  // fmt chunk (16 bytes payload)
  writeAscii('fmt ');
  view.setUint32(offset, 16, Endian.little);
  offset += 4;
  view.setUint16(offset, 1, Endian.little); // PCM
  view.setUint16(offset + 2, 1, Endian.little); // Mono
  view.setUint32(offset + 4, 24000, Endian.little);
  view.setUint32(offset + 8, 48000, Endian.little);
  view.setUint16(offset + 12, 2, Endian.little);
  view.setUint16(offset + 14, 16, Endian.little);
  offset += 16;

  if (withExtraListChunk) {
    writeAscii('LIST');
    view.setUint32(offset, extraChunkBytes.length, Endian.little);
    offset += 4;
    data.setRange(offset, offset + extraChunkBytes.length, extraChunkBytes);
    offset += extraChunkBytes.length;
  }

  writeAscii('data');
  view.setUint32(offset, pcmBytes.length, Endian.little);
  offset += 4;
  data.setRange(offset, offset + pcmBytes.length, pcmBytes);

  return data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiRestProvider Audio Payload, Models & REST TTS', () {
    test('extractPcm24kFromAudioPayload strips standard 44-byte WAV header', () {
      final expectedPcm = <int>[10, 20, 30, 40, 50, 60];
      final wavBytes = _buildTestWav(expectedPcm);

      final result = GeminiRestProvider.extractPcm24kFromAudioPayload(
        wavBytes,
        mimeType: 'audio/wav',
      );

      expect(result, Uint8List.fromList(expectedPcm));
    });

    test('extractPcm24kFromAudioPayload strips RIFF/WAVE header with extra chunk before data', () {
      final expectedPcm = <int>[1, 2, 3, 4, 5, 6, 7, 8];
      final wavBytes = _buildTestWav(expectedPcm, withExtraListChunk: true);

      final result = GeminiRestProvider.extractPcm24kFromAudioPayload(
        wavBytes,
        mimeType: 'audio/x-wav',
      );

      expect(result, Uint8List.fromList(expectedPcm));
    });

    test('extractPcm24kFromAudioPayload preserves raw PCM bytes untouched', () {
      final rawPcm = Uint8List.fromList(<int>[0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC]);

      final result = GeminiRestProvider.extractPcm24kFromAudioPayload(
        rawPcm,
        mimeType: 'audio/L16;codec=pcm;rate=24000',
      );

      expect(result, rawPcm);
    });

    test('parseAvailableModels puts -tts generateContent models into ttsModels and excludes them from scoringModels', () {
      final parsed = GeminiRestProvider.parseAvailableModels({
        'models': [
          {
            'name': 'models/gemini-2.5-flash-preview-tts',
            'supportedGenerationMethods': ['generateContent'],
          },
          {
            'name': 'models/gemini-3.8-flash-tts',
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
            'name': 'models/gemini-2.5-flash-native-audio-preview-12-2025',
            'supportedGenerationMethods': ['bidiGenerateContent'],
          },
        ],
      });

      expect(
        parsed.ttsModels,
        containsAll(['gemini-3.8-flash-tts', 'gemini-2.5-flash-preview-tts']),
      );
      expect(parsed.scoringModels, containsAll(['gemini-3.8-flash', 'gemini-2.5-flash']));
      expect(parsed.scoringModels.any((m) => m.contains('tts')), isFalse);
      expect(
        parsed.liveModels,
        contains('gemini-2.5-flash-native-audio-preview-12-2025'),
      );
    });

    test('synthesizeSpeechPcm24k sends AUDIO modality, voice config, slow directive and strips WAV header', () async {
      final expectedPcm = <int>[0x01, 0x02, 0x03, 0x04, 0x05, 0x06];
      final wavResponse = _buildTestWav(expectedPcm);
      final requests = <http.Request>[];

      final client = MockClient((http.Request request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'inlineData': {
                        'mimeType': 'audio/wav',
                        'data': base64Encode(wavResponse),
                      },
                    },
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final provider = GeminiRestProvider(httpClient: client);

      final pcmNormal = await provider.synthesizeSpeechPcm24k(
        apiKey: 'AIzaTestKey',
        model: 'gemini-2.5-flash-preview-tts',
        text: 'Resilient',
        slow: false,
      );
      expect(pcmNormal, Uint8List.fromList(expectedPcm));

      final pcmSlow = await provider.synthesizeSpeechPcm24k(
        apiKey: 'AIzaTestKey',
        model: 'gemini-3.8-flash-tts',
        text: 'Perseverance',
        slow: true,
        voiceName: 'Aoede',
      );
      expect(pcmSlow, Uint8List.fromList(expectedPcm));

      expect(requests, hasLength(2));
      expect(
        requests[0].url.toString(),
        contains('gemini-2.5-flash-preview-tts:generateContent'),
      );
      expect(requests[0].url.queryParameters['key'], 'AIzaTestKey');
      expect(requests[1].url.queryParameters['key'], 'AIzaTestKey');

      final body0 = jsonDecode(requests[0].body) as Map<String, dynamic>;
      final gen0 = body0['generationConfig'] as Map<String, dynamic>;
      expect(gen0['responseModalities'], ['AUDIO']);
      expect(
        gen0['speechConfig']['voiceConfig']['prebuiltVoiceConfig']['voiceName'],
        GeminiConstants.defaultTtsVoice,
      );
      expect(
        body0['contents'][0]['parts'][0]['text'],
        'Say naturally: Resilient',
      );

      final body1 = jsonDecode(requests[1].body) as Map<String, dynamic>;
      expect(
        body1['generationConfig']['speechConfig']['voiceConfig']['prebuiltVoiceConfig']['voiceName'],
        'Aoede',
      );
      expect(
        body1['contents'][0]['parts'][0]['text'],
        'Say slowly and clearly for an English learner: Perseverance',
      );

      await expectLater(
        () => provider.synthesizeSpeechPcm24k(
          apiKey: '',
          model: 'gemini-2.5-flash-preview-tts',
          text: 'Hello',
        ),
        throwsA(isA<GeminiApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });
  });

  group('TutorRepository Flashcard AI Model Routing', () {
    test('generateFlashcardPracticeContent and evaluateSentencePronunciation use flashcardModel instead of scoringModel', () async {
      final calledUrls = <String>[];
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final client = MockClient((http.Request request) async {
        calledUrls.add(request.url.toString());
        if (request.url.path.contains('generateContent')) {
          if (request.body.contains('clarityScore')) {
            return http.Response(
              jsonEncode({
                'candidates': [
                  {
                    'content': {
                      'parts': [
                        {
                          'text': jsonEncode({
                            'score': 90,
                            'clarityScore': 88,
                            'intonationScore': 92,
                            'heardText': 'She stayed resilient.',
                            'overallFeedbackId': 'Bagus.',
                            'wordFeedback': [
                              {'word': 'She', 'status': 'good', 'tipId': ''},
                            ],
                          }),
                        },
                      ],
                    },
                  },
                ],
              }),
              200,
              headers: const {'content-type': 'application/json; charset=utf-8'},
            );
          }

          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'text': jsonEncode({
                          'wordType': 'non_verb',
                          'phonetic': '/rɪˈzɪliənt/',
                          'meaningId': 'tangguh',
                          'examples': [
                            {'tense': 'Daily Use', 'en': 'She is resilient.', 'id': 'Dia tangguh.'},
                            {'tense': 'Daily Use', 'en': 'Stay resilient.', 'id': 'Tetap tangguh.'},
                            {'tense': 'Daily Use', 'en': 'Kids are resilient.', 'id': 'Anak-anak tangguh.'},
                            {'tense': 'Business', 'en': 'Resilient teams win.', 'id': 'Tim tangguh menang.'},
                            {'tense': 'Daily Use', 'en': 'Be resilient today.', 'id': 'Jadilah tangguh hari ini.'},
                          ],
                          'conversation': 'A: You seem calm.\nB: Trying to be resilient.',
                        }),
                      },
                    ],
                  },
                },
              ],
            }),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{}', 404);
      });

      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(httpClient: client),
      );
      await repo.updateSettings(
        const AppSettingsCompanion(
          apiKey: Value('AIzaTestKey'),
          scoringModel: Value('gemini-2.5-pro'),
          flashcardModel: Value('gemini-2.5-flash'),
          flashcardTtsModel: Value('gemini-3.8-flash-tts'),
        ),
      );

      final deckId = await db.flashcardDao.createDeck(name: 'Core Vocab');
      final subDeckId = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Adjectives',
      );
      final cardId = await db.flashcardDao.createFlashcard(
        subDeckId: subDeckId,
        word: 'resilient',
        meaningId: 'tangguh',
      );
      final cards = await db.flashcardDao.getCardsBySubDeck(subDeckId);
      final card = cards.firstWhere((c) => c.id == cardId);

      await repo.generateFlashcardPracticeContent(
        word: card.word,
        currentMeaningId: card.meaningId,
      );
      await repo.evaluateSentencePronunciation(
        targetSentence: 'She stayed resilient.',
        audioWavBytes: _buildTestWav(<int>[1, 2, 3, 4]),
      );

      expect(calledUrls, hasLength(2));
      expect(calledUrls[0], contains('gemini-2.5-flash:generateContent'));
      expect(calledUrls[1], contains('gemini-2.5-flash:generateContent'));
      expect(calledUrls.any((u) => u.contains('gemini-2.5-pro')), isFalse);
    });
  });

  group('Hybrid TtsService Online AI, RAM Cache & Fallback', () {
    late AppDatabase db;
    late _FakeAudioService fakeAudio;
    late _FakeFlutterTts fakeFlutterTts;
    late int ttsApiCalls;
    late int nextStatusCode;
    late bool throwSocketException;
    late TtsService ttsService;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      fakeAudio = _FakeAudioService();
      fakeFlutterTts = _FakeFlutterTts();
      ttsApiCalls = 0;
      nextStatusCode = 200;
      throwSocketException = false;

      final client = MockClient((http.Request request) async {
        ttsApiCalls += 1;
        if (throwSocketException) {
          throw const SocketException('No internet connection');
        }
        if (nextStatusCode != 200) {
          return http.Response(
            jsonEncode({
              'error': {'message': 'Mock HTTP $nextStatusCode'},
            }),
            nextStatusCode,
          );
        }
        final pcmPayload = Uint8List.fromList(<int>[ttsApiCalls, 2, 3, 4]);
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'inlineData': {
                        'mimeType': 'audio/L16;codec=pcm;rate=24000',
                        'data': base64Encode(pcmPayload),
                      },
                    },
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(httpClient: client),
      );
      await repo.updateSettings(
        const AppSettingsCompanion(
          apiKey: Value('AIzaHybridKey'),
          flashcardTtsModel: Value('gemini-2.5-flash-preview-tts'),
        ),
      );

      ttsService = TtsService(
        repository: repo,
        audioService: fakeAudio,
        flutterTts: fakeFlutterTts,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Online AI synthesis plays PCM24k buffer, hits RAM cache, busts on slow rate/model change & clears cache', () async {
      fakeAudio.holdPlaybackUntilTriggered = true;
      final speakFuture = ttsService.speak('Perseverance');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(ttsApiCalls, 1);
      expect(fakeAudio.playPcm24kCalls, hasLength(1));
      expect(fakeFlutterTts.spokenTexts, isEmpty);
      expect(ttsService.activeVoiceSource.value, 'ai');
      expect(ttsService.lastFallbackReason.value, isNull);
      expect(ttsService.isSpeaking.value, isTrue);

      fakeAudio.triggerCompleted();
      await speakFuture;
      fakeAudio.holdPlaybackUntilTriggered = false;
      expect(ttsService.isSpeaking.value, isFalse);
      expect(ttsService.activeText.value, '');

      // Second identical call hits RAM cache without hitting REST API
      await ttsService.speak('Perseverance');
      expect(ttsApiCalls, 1);
      expect(fakeAudio.playPcm24kCalls, hasLength(2));
      expect(ttsService.activeVoiceSource.value, 'cache');

      // Slow rate (< 0.42) uses distinct cache key
      await ttsService.speak('Perseverance', rate: 0.35);
      expect(ttsApiCalls, 2);
      expect(fakeAudio.playPcm24kCalls, hasLength(3));
      expect(ttsService.activeVoiceSource.value, 'ai');

      // Changing flashcardTtsModel in Settings invalidates previous model cache key match
      await db.settingsDao.updateSettings(
        const AppSettingsCompanion(
          flashcardTtsModel: Value('gemini-3.8-flash-tts'),
        ),
      );
      await ttsService.speak('Perseverance');
      expect(ttsApiCalls, 3);
      expect(ttsService.activeVoiceSource.value, 'ai');

      // Clearing RAM cache forces fresh REST call
      ttsService.clearRamCache();
      await ttsService.speak('Perseverance');
      expect(ttsApiCalls, 4);
      expect(ttsService.activeVoiceSource.value, 'ai');
    });

    test('Falls back to flutter_tts when API key is empty', () async {
      await db.settingsDao.updateSettings(
        const AppSettingsCompanion(apiKey: Value('')),
      );

      await ttsService.speak('Resilient');
      expect(ttsApiCalls, 0);
      expect(fakeAudio.playPcm24kCalls, isEmpty);
      expect(fakeFlutterTts.spokenTexts, ['Resilient']);
      expect(ttsService.activeVoiceSource.value, 'offline_tts');
      expect(ttsService.lastFallbackReason.value, 'no_api_key');
      expect(ttsService.isSpeaking.value, isTrue);

      fakeFlutterTts.triggerCompletion();
      expect(ttsService.isSpeaking.value, isFalse);
    });

    test('Falls back to flutter_tts on SocketException (offline)', () async {
      throwSocketException = true;

      await ttsService.speak('Resilient');
      expect(ttsApiCalls, 1);
      expect(fakeFlutterTts.spokenTexts, ['Resilient']);
      expect(ttsService.activeVoiceSource.value, 'offline_tts');
      expect(ttsService.lastFallbackReason.value, 'offline');
    });

    test('Falls back to flutter_tts on 429 quota exceeded and honors cooldown until resetAiVoiceCooldown', () async {
      nextStatusCode = 429;

      await ttsService.speak('Alpha');
      expect(ttsApiCalls, 1);
      expect(fakeFlutterTts.spokenTexts, ['Alpha']);
      expect(ttsService.activeVoiceSource.value, 'offline_tts');
      expect(ttsService.lastFallbackReason.value, 'quota_exceeded');

      // During 60s cooldown, REST API is skipped directly
      nextStatusCode = 200;
      await ttsService.speak('Beta');
      expect(ttsApiCalls, 1);
      expect(fakeFlutterTts.spokenTexts, ['Alpha', 'Beta']);
      expect(ttsService.activeVoiceSource.value, 'offline_tts');
      expect(ttsService.lastFallbackReason.value, 'quota_exceeded');

      // Resetting cooldown re-enables REST AI voice
      ttsService.resetAiVoiceCooldown();
      await ttsService.speak('Gamma');
      expect(ttsApiCalls, 2);
      expect(fakeAudio.playPcm24kCalls, hasLength(1));
      expect(ttsService.activeVoiceSource.value, 'ai');
      expect(ttsService.lastFallbackReason.value, isNull);
    });

    test('stop() clears AI audio player and stops fallback TTS cleanly', () async {
      await ttsService.speak('Stop test');
      await ttsService.stop();

      expect(fakeAudio.clearAndStopCalls, greaterThanOrEqualTo(1));
      expect(fakeFlutterTts.stopCalls, greaterThanOrEqualTo(1));
      expect(ttsService.isSpeaking.value, isFalse);
      expect(ttsService.isLoadingAudio.value, isFalse);
      expect(ttsService.activeText.value, '');
    });
  });

  group('Drift v3 -> v4 Migration, SettingsDao Export/Import & SettingsView (360dp)', () {
    test('Drift v3 -> v4 on-disk migration preserves API key, 100 missions, flashcards & sets model defaults', () async {
      final tempDir = await Directory.systemTemp.createTemp('met_v3_v4_test_');
      final dbFile = File('${tempDir.path}/tutor_v3.sqlite');
      try {
        final dbV3Prep = AppDatabase(NativeDatabase(dbFile));
        expect(dbV3Prep.schemaVersion, 4);
        await dbV3Prep.settingsDao.updateSettings(
          const AppSettingsCompanion(apiKey: Value('legacy-v3-api-key')),
        );
        final deckId = await dbV3Prep.flashcardDao.createDeck(
          name: 'Migrated Deck',
        );
        final subDeckId = await dbV3Prep.flashcardDao.createSubDeck(
          deckId: deckId,
          name: 'Phrases',
        );
        await dbV3Prep.flashcardDao.createFlashcard(
          subDeckId: subDeckId,
          word: 'persevere',
          meaningId: 'bertahan',
        );

        // Simulate existing v3 schema on disk prior to v4 upgrade
        await dbV3Prep.customStatement(
          'ALTER TABLE app_settings DROP COLUMN flashcard_model;',
        );
        await dbV3Prep.customStatement(
          'ALTER TABLE app_settings DROP COLUMN flashcard_tts_model;',
        );
        await dbV3Prep.customStatement('PRAGMA user_version = 3;');
        await dbV3Prep.close();

        final dbUpgraded = AppDatabase(NativeDatabase(dbFile));
        final upgradedSettings = await dbUpgraded.settingsDao.getSettings();
        final allLessons = await dbUpgraded.select(dbUpgraded.lessons).get();
        final allDecks = await dbUpgraded.flashcardDao.getDecksWithStats();

        expect(upgradedSettings.apiKey, 'legacy-v3-api-key');
        expect(upgradedSettings.flashcardModel, SettingsDao.defaultFlashcardModel);
        expect(upgradedSettings.flashcardTtsModel, SettingsDao.defaultTtsModel);
        expect(allLessons.length, 100);
        expect(allDecks.any((d) => d.deck.name == 'Migrated Deck'), isTrue);

        await dbUpgraded.close();
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('SettingsDao export/import preserves flashcardModel & flashcardTtsModel and handles legacy backup fallback', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.settingsDao.updateSettings(
        const AppSettingsCompanion(
          apiKey: Value('export-key'),
          flashcardModel: Value('gemini-2.5-flash'),
          flashcardTtsModel: Value('gemini-3.8-flash-tts'),
        ),
      );

      final exported = await db.settingsDao.exportAllDataAsMap();
      final exportedSettings = exported['settings'] as Map<String, dynamic>;
      expect(exportedSettings['flashcardModel'], 'gemini-2.5-flash');
      expect(exportedSettings['flashcardTtsModel'], 'gemini-3.8-flash-tts');

      // Mutate current settings then restore from export
      await db.settingsDao.updateSettings(
        const AppSettingsCompanion(
          flashcardModel: Value('gemini-3.8-flash'),
          flashcardTtsModel: Value('gemini-2.5-flash-preview-tts'),
        ),
      );
      await db.settingsDao.importAllDataFromMap(exported);
      final restored = await db.settingsDao.getSettings();
      expect(restored.flashcardModel, 'gemini-2.5-flash');
      expect(restored.flashcardTtsModel, 'gemini-3.8-flash-tts');

      // Legacy backup without flashcardModel / flashcardTtsModel falls back cleanly
      final legacyExport = Map<String, dynamic>.from(exported);
      final legacySettings = Map<String, dynamic>.from(exportedSettings)
        ..remove('flashcardModel')
        ..remove('flashcardTtsModel');
      legacyExport['settings'] = legacySettings;

      await db.settingsDao.importAllDataFromMap(legacyExport);
      final fallbackSettings = await db.settingsDao.getSettings();
      expect(fallbackSettings.flashcardModel, SettingsDao.defaultFlashcardModel);
      expect(fallbackSettings.flashcardTtsModel, SettingsDao.defaultTtsModel);
    });

    testWidgets('SettingsView at 360dp width displays Flashcard AI & TTS models, loads dynamic models and saves selection with zero overflow', (WidgetTester tester) async {
      final errors = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final db = AppDatabase(NativeDatabase.memory());
      final fakeAudio = _FakeAudioService();
      final fakeFlutterTts = _FakeFlutterTts();

      final client = MockClient((http.Request request) async {
        if (request.url.path.endsWith('/models')) {
          return http.Response(
            jsonEncode({
              'models': [
                {
                  'name': 'models/gemini-3.8-flash',
                  'supportedGenerationMethods': ['generateContent'],
                },
                {
                  'name': 'models/gemini-2.5-flash-native-audio-preview-12-2025',
                  'supportedGenerationMethods': ['bidiGenerateContent'],
                },
                {
                  'name': 'models/gemini-2.5-flash-preview-tts',
                  'supportedGenerationMethods': ['generateContent'],
                },
                {
                  'name': 'models/gemini-9.9-flash-tts',
                  'supportedGenerationMethods': ['generateContent'],
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(httpClient: client),
      );
      await tester.runAsync(() async {
        await repo.updateSettings(
          const AppSettingsCompanion(apiKey: Value('AIzaSettingsTestKey')),
        );
      });

      final ttsService = TtsService(
        repository: repo,
        audioService: fakeAudio,
        flutterTts: fakeFlutterTts,
      );

      Get.reset();
      Get.put<AudioService>(fakeAudio, permanent: true);
      Get.put<TtsService>(ttsService, permanent: true);
      Get.put<SettingsController>(
        SettingsController(repository: repo, audioService: fakeAudio),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const SettingsView(),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final scrollable = find.byType(Scrollable).first;

      final loadBtn = find.text('Muat Model dari API Key');
      await tester.scrollUntilVisible(
        loadBtn,
        250,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      await tester.ensureVisible(loadBtn);
      await tester.pump();
      await tester.tap(loadBtn);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final flashcardAiLabel = find.text('Flashcard AI Model (Kalimat, Kuis & Pelafalan)');
      await tester.scrollUntilVisible(
        flashcardAiLabel,
        250,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      expect(flashcardAiLabel, findsOneWidget);

      final flashcardTtsLabel = find.text('Flashcard TTS Model (Suara AI REST)');
      await tester.scrollUntilVisible(
        flashcardTtsLabel,
        250,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      expect(flashcardTtsLabel, findsOneWidget);

      final dynamicTtsChip = find.widgetWithText(ChoiceChip, 'gemini-9.9-flash-tts');
      await tester.scrollUntilVisible(
        dynamicTtsChip,
        200,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      await tester.ensureVisible(dynamicTtsChip);
      await tester.pump();
      await tester.tap(dynamicTtsChip);

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      final savedSettings = await tester.runAsync(() => repo.getSettings());
      expect(savedSettings?.flashcardTtsModel, 'gemini-9.9-flash-tts');

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('RenderFlex overflowed'))
          .toList();
      expect(overflowErrors, isEmpty);

      // Let any active GetX snackbar animations finish and dispose cleanly.
      Get.closeAllSnackbars();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      Get.reset();
      await tester.runAsync(() async {
        await db.close();
      });
    });
  });
}
