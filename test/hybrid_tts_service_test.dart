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
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:my_english_tutor/app/core/constants/gemini_constants.dart';
import 'package:my_english_tutor/app/core/theme/app_theme.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/local/daos/settings_dao.dart';
import 'package:my_english_tutor/app/data/providers/gemini_live_provider.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/repositories/tutor_repository.dart';
import 'package:my_english_tutor/app/data/services/audio_service.dart';
import 'package:my_english_tutor/app/data/services/tts_service.dart';
import 'package:my_english_tutor/app/modules/flashcards/widgets/flashcard_dialogs.dart';
import 'package:my_english_tutor/app/modules/settings/controllers/settings_controller.dart';
import 'package:my_english_tutor/app/modules/settings/views/settings_view.dart';

class _FakeWebSocketSink implements WebSocketSink {
  _FakeWebSocketSink(this.onAdd, this.onClose);

  final void Function(dynamic data) onAdd;
  final Future<void> Function(int? closeCode, String? closeReason) onClose;
  final Completer<void> _doneCompleter = Completer<void>();
  bool isClosed = false;

  @override
  void add(dynamic data) {
    onAdd(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) => stream.forEach(add);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (isClosed) return;
    isClosed = true;
    await onClose(closeCode, closeReason);
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }

  @override
  Future<void> get done => _doneCompleter.future;
}

class _FakeWebSocketChannel implements WebSocketChannel {
  _FakeWebSocketChannel({
    required this.uri,
    required void Function(_FakeWebSocketChannel channel, dynamic frame)
        onOutgoingFrame,
  }) {
    _sink = _FakeWebSocketSink(
      (dynamic data) => onOutgoingFrame(this, data),
      (int? code, String? reason) async {
        _closeCode ??= code ?? 1000;
        _closeReason ??= reason;
        await _incoming.close();
      },
    );
  }

  final Uri uri;
  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final List<Map<String, dynamic>> sentJsonFrames = <Map<String, dynamic>>[];
  late final _FakeWebSocketSink _sink;
  int? _closeCode;
  String? _closeReason;

  bool get isSinkClosed => _sink.isClosed;

  void pushServerJson(Map<String, dynamic> payload) {
    if (!_incoming.isClosed) {
      _incoming.add(jsonEncode(payload));
    }
  }

  Future<void> closeFromServer([int code = 1000, String reason = '']) async {
    _closeCode = code;
    _closeReason = reason;
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }

  @override
  Future<void> get ready => Future<void>.value();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => _closeReason;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HangingWebSocketSink implements WebSocketSink {
  int closeCallCount = 0;
  final Completer<void> _neverDone = Completer<void>();

  @override
  void add(dynamic data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) => Future<void>.value();

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    closeCallCount += 1;
    // Never completes — simulates IOWebSocketChannel.sink.close() hanging when socket never opened.
    return _neverDone.future;
  }

  @override
  Future<void> get done => _neverDone.future;
}

class _HangingWebSocketChannel implements WebSocketChannel {
  final _HangingWebSocketSink _sink = _HangingWebSocketSink();
  final Completer<void> _neverReady = Completer<void>();
  final StreamController<dynamic> _streamController = StreamController<dynamic>();

  bool get sinkCloseCalled => _sink.closeCallCount > 0;

  @override
  Future<void> get ready => _neverReady.future;

  @override
  Stream<dynamic> get stream => _streamController.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingSynthTutorRepository extends TutorRepository {
  _ThrowingSynthTutorRepository({
    required super.database,
    required super.restProvider,
    super.liveProvider,
    required this.onSynthesize,
  });

  final Future<Uint8List> Function() onSynthesize;

  @override
  Future<Uint8List> synthesizeSpeechPcm24k({
    required String text,
    bool slow = false,
  }) =>
      onSynthesize();
}

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

    test('synthesizeSpeechPcm24k smart-routes Live API models to GeminiLiveProvider and -tts models to GeminiRestProvider', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      var restTtsCalls = 0;
      var liveTtsCalls = 0;
      String? lastLiveModel;
      final createdChannels = <_FakeWebSocketChannel>[];

      final client = MockClient((http.Request request) async {
        if (request.url.toString().contains(':generateContent')) {
          restTtsCalls += 1;
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {
                        'inlineData': {
                          'mimeType': 'audio/L16;codec=pcm;rate=24000',
                          'data': base64Encode(<int>[9, 8, 7, 6]),
                        },
                      },
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final liveProvider = GeminiLiveProvider(
        channelFactory: (Uri uri) {
          late _FakeWebSocketChannel ch;
          ch = _FakeWebSocketChannel(
            uri: uri,
            onOutgoingFrame: (_FakeWebSocketChannel channel, dynamic raw) {
              final frame = jsonDecode(raw as String) as Map<String, dynamic>;
              channel.sentJsonFrames.add(frame);
              if (frame.containsKey('setup')) {
                liveTtsCalls += 1;
                lastLiveModel = frame['setup']['model'] as String?;
                channel.pushServerJson({'setupComplete': <String, dynamic>{}});
              } else if (frame.containsKey('clientContent')) {
                channel.pushServerJson({
                  'serverContent': {
                    'modelTurn': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'audio/pcm;rate=24000',
                            'data': base64Encode(<int>[1, 2, 3, 4]),
                          },
                        },
                      ],
                    },
                    'turnComplete': true,
                  },
                });
              }
            },
          );
          createdChannels.add(ch);
          return ch;
        },
      );
      addTearDown(liveProvider.dispose);

      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(httpClient: client),
        liveProvider: liveProvider,
      );

      // Default Live model routes via WebSocket
      await repo.updateSettings(
        const AppSettingsCompanion(
          apiKey: Value('AIzaRoutingKey'),
          flashcardTtsModel: Value('gemini-3.8-live'),
        ),
      );
      final liveBytes = await repo.synthesizeSpeechPcm24k(text: 'Persevere');
      expect(liveBytes, Uint8List.fromList(<int>[1, 2, 3, 4]));
      expect(liveTtsCalls, 1);
      expect(restTtsCalls, 0);
      expect(lastLiveModel, 'models/gemini-3.8-live');
      expect(createdChannels.single.isSinkClosed, isTrue);

      // Explicit -tts model still routes via REST
      await repo.updateSettings(
        const AppSettingsCompanion(
          flashcardTtsModel: Value('gemini-2.5-flash-preview-tts'),
        ),
      );
      final restBytes = await repo.synthesizeSpeechPcm24k(text: 'Persevere');
      expect(restBytes, Uint8List.fromList(<int>[9, 8, 7, 6]));
      expect(liveTtsCalls, 1);
      expect(restTtsCalls, 1);
    });

    test('TutorRepository.synthesizeSpeechPcm24k auto-retries 1x with settings.liveModel when flashcardTtsModel fails with non-offline/non-API-key error', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final attemptedModels = <String>[];
      final liveProvider = GeminiLiveProvider(
        channelFactory: (Uri uri) {
          return _FakeWebSocketChannel(
            uri: uri,
            onOutgoingFrame: (_FakeWebSocketChannel channel, dynamic raw) {
              final frame = jsonDecode(raw as String) as Map<String, dynamic>;
              if (frame.containsKey('setup')) {
                final model = frame['setup']['model'] as String;
                attemptedModels.add(model);
                if (model == 'models/gemini-bad-live') {
                  unawaited(
                    channel.closeFromServer(
                      1008,
                      'models/gemini-bad-live is not found for API version v1beta',
                    ),
                  );
                } else {
                  channel.pushServerJson({'setupComplete': <String, dynamic>{}});
                }
              } else if (frame.containsKey('clientContent')) {
                channel.pushServerJson({
                  'serverContent': {
                    'modelTurn': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'audio/pcm;rate=24000',
                            'data': base64Encode(<int>[4, 3, 2, 1]),
                          },
                        },
                      ],
                    },
                    'turnComplete': true,
                  },
                });
              }
            },
          );
        },
      );
      addTearDown(liveProvider.dispose);

      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(
          httpClient: MockClient((_) async => http.Response('{}', 500)),
        ),
        liveProvider: liveProvider,
      );

      await repo.updateSettings(
        const AppSettingsCompanion(
          apiKey: Value('AIzaRetryKey'),
          flashcardTtsModel: Value('gemini-bad-live'),
          liveModel: Value('gemini-live-fallback'),
        ),
      );

      final pcm = await repo.synthesizeSpeechPcm24k(text: 'Persevere');
      expect(pcm, Uint8List.fromList(<int>[4, 3, 2, 1]));
      expect(
        attemptedModels,
        ['models/gemini-bad-live', 'models/gemini-live-fallback'],
      );
    });

    test('TutorRepository.synthesizeSpeechPcm24k does not retry liveModel on TimeoutException or timeout error', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final attemptedModels = <String>[];
      var throwDirectTimeoutException = false;
      final liveProvider = GeminiLiveProvider(
        channelFactory: (Uri uri) {
          return _FakeWebSocketChannel(
            uri: uri,
            onOutgoingFrame: (_FakeWebSocketChannel channel, dynamic raw) {
              final frame = jsonDecode(raw as String) as Map<String, dynamic>;
              if (frame.containsKey('setup')) {
                attemptedModels.add(frame['setup']['model'] as String);
                if (throwDirectTimeoutException) {
                  throw TimeoutException('WebSocket handshake timeout');
                }
                channel.pushServerJson({
                  'error': {'message': 'Connection timeout while reaching host'},
                });
              }
            },
          );
        },
      );
      addTearDown(liveProvider.dispose);

      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(
          httpClient: MockClient((_) async => http.Response('{}', 500)),
        ),
        liveProvider: liveProvider,
      );

      await repo.updateSettings(
        const AppSettingsCompanion(
          apiKey: Value('AIzaTimeoutKey'),
          flashcardTtsModel: Value('gemini-primary-live'),
          liveModel: Value('gemini-fallback-live'),
        ),
      );

      // Case A: error text containing 'timeout' skips secondary liveModel retry.
      await expectLater(
        () => repo.synthesizeSpeechPcm24k(text: 'Persevere'),
        throwsA(isA<GeminiLiveException>()),
      );
      expect(attemptedModels, ['models/gemini-primary-live']);

      // Case B: direct TimeoutException (e.g. REST -tts timeout) skips retry too.
      attemptedModels.clear();
      throwDirectTimeoutException = true;
      await repo.updateSettings(
        const AppSettingsCompanion(
          flashcardTtsModel: Value('gemini-2.5-flash-preview-tts'),
          liveModel: Value('gemini-fallback-live'),
        ),
      );
      final restRepo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(
          httpClient: MockClient((_) async {
            attemptedModels.add('rest-tts');
            throw TimeoutException('REST TTS timeout');
          }),
        ),
        liveProvider: liveProvider,
      );
      await expectLater(
        () => restRepo.synthesizeSpeechPcm24k(text: 'Persevere'),
        throwsA(isA<GeminiApiException>()),
      );
      expect(attemptedModels, ['rest-tts']);
    });
  });

  group('GeminiLiveProvider One-Shot WebSocket TTS (synthesizeSpeechOncePcm24k)', () {
    test('Sends read-aloud setup & clientContent, merges PCM chunks until turnComplete & keeps active session isolated', () async {
      final openedChannels = <_FakeWebSocketChannel>[];

      final liveProvider = GeminiLiveProvider(
        channelFactory: (Uri uri) {
          late _FakeWebSocketChannel ch;
          ch = _FakeWebSocketChannel(
            uri: uri,
            onOutgoingFrame: (_FakeWebSocketChannel channel, dynamic raw) {
              final frame = jsonDecode(raw as String) as Map<String, dynamic>;
              channel.sentJsonFrames.add(frame);

              if (frame.containsKey('setup')) {
                channel.pushServerJson({'setupComplete': <String, dynamic>{}});
              } else if (frame.containsKey('clientContent')) {
                final text = frame['clientContent']['turns'][0]['parts'][0]['text'];
                if (text == 'QuotaFail') {
                  channel.pushServerJson({
                    'error': {'message': '429 RESOURCE_EXHAUSTED quota exceeded'},
                  });
                } else {
                  channel.pushServerJson({
                    'serverContent': {
                      'modelTurn': {
                        'parts': [
                          {
                            'inlineData': {
                              'mimeType': 'audio/pcm;rate=24000',
                              'data': base64Encode(<int>[10, 11, 12]),
                            },
                          },
                        ],
                      },
                    },
                  });
                  channel.pushServerJson({
                    'serverContent': {
                      'modelTurn': {
                        'parts': [
                          {
                            'inlineData': {
                              'mimeType': 'audio/pcm;rate=24000',
                              'data': base64Encode(<int>[13, 14]),
                            },
                          },
                        ],
                      },
                      'turnComplete': true,
                    },
                  });
                }
              }
            },
          );
          openedChannels.add(ch);
          return ch;
        },
      );
      addTearDown(liveProvider.dispose);

      // Connect a main interactive Live session first (like PracticeView)
      await liveProvider.connect(
        apiKey: 'AIzaLiveMainKey',
        model: 'gemini-2.5-flash-native-audio-preview-12-2025',
        systemInstruction: 'You are an English tutor.',
      );
      expect(liveProvider.currentState, LiveConnectionState.connected);

      final mainTranscripts = <Object>[];
      final mainSub = liveProvider.transcriptStream.listen(mainTranscripts.add);
      addTearDown(mainSub.cancel);

      // Run one-shot slow TTS while main session stays open
      final pcmSlow = await liveProvider.synthesizeSpeechOncePcm24k(
        apiKey: 'AIzaLiveMainKey',
        model: 'gemini-3.8-live',
        text: 'Resilience builds confidence.',
        slow: true,
        voiceName: 'Kore',
      );

      expect(pcmSlow, Uint8List.fromList(<int>[10, 11, 12, 13, 14]));
      expect(openedChannels, hasLength(2));
      // Main session remains open and untouched
      expect(liveProvider.currentState, LiveConnectionState.connected);
      expect(openedChannels[0].isSinkClosed, isFalse);
      expect(mainTranscripts, isEmpty);

      // One-shot socket is properly closed
      final oneShotChannel = openedChannels[1];
      expect(oneShotChannel.isSinkClosed, isTrue);
      expect(oneShotChannel.uri.queryParameters['key'], 'AIzaLiveMainKey');

      final setupFrame = oneShotChannel.sentJsonFrames[0]['setup'] as Map<String, dynamic>;
      expect(setupFrame['model'], 'models/gemini-3.8-live');
      expect(setupFrame['generationConfig']['responseModalities'], ['AUDIO']);
      expect(setupFrame['inputAudioTranscription'], <String, dynamic>{});
      expect(setupFrame['outputAudioTranscription'], <String, dynamic>{});
      expect(
        setupFrame['generationConfig']['speechConfig']['voiceConfig']['prebuiltVoiceConfig']['voiceName'],
        'Kore',
      );
      final instructionText = setupFrame['systemInstruction']['parts'][0]['text'] as String;
      expect(
        instructionText,
        contains('Speak ONLY the exact English text sent by the user verbatim, slowly and clearly'),
      );

      final clientFrame = oneShotChannel.sentJsonFrames[1]['clientContent'] as Map<String, dynamic>;
      expect(clientFrame['turnComplete'], isTrue);
      expect(clientFrame['turns'][0]['parts'][0]['text'], 'Resilience builds confidence.');

      // Normal pace checks normal systemInstruction
      await liveProvider.synthesizeSpeechOncePcm24k(
        apiKey: 'AIzaLiveMainKey',
        model: 'gemini-3.8-live',
        text: 'Articulate',
        slow: false,
      );
      final normalSetup = openedChannels[2].sentJsonFrames[0]['setup'] as Map<String, dynamic>;
      expect(
        normalSetup['systemInstruction']['parts'][0]['text'],
        contains('natural American English'),
      );

      // Error handling does not disturb main session
      await expectLater(
        () => liveProvider.synthesizeSpeechOncePcm24k(
          apiKey: 'AIzaLiveMainKey',
          model: 'gemini-3.8-live',
          text: 'QuotaFail',
        ),
        throwsA(isA<GeminiLiveException>()),
      );
      expect(liveProvider.currentState, LiveConnectionState.connected);
    });

    test('Close code 1008 with not-found/unsupported reason maps cleanly without blaming quota or API key', () async {
      final liveProvider = GeminiLiveProvider(
        channelFactory: (Uri uri) {
          return _FakeWebSocketChannel(
            uri: uri,
            onOutgoingFrame: (_FakeWebSocketChannel channel, dynamic raw) {
              final frame = jsonDecode(raw as String) as Map<String, dynamic>;
              if (frame.containsKey('setup')) {
                unawaited(
                  channel.closeFromServer(
                    1008,
                    'models/missing-live-model is not found for API version v1beta, or is not supported for bidiGenerateContent.',
                  ),
                );
              }
            },
          );
        },
      );
      addTearDown(liveProvider.dispose);

      await expectLater(
        () => liveProvider.synthesizeSpeechOncePcm24k(
          apiKey: 'AIzaLiveMainKey',
          model: 'missing-live-model',
          text: 'Hello',
        ),
        throwsA(
          isA<GeminiLiveException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Sesi Gemini Live ditolak (kode 1008):'),
              contains('not found'),
              isNot(contains('Kuota')),
            ),
          ),
        ),
      );
    });

    test('Ready timeout with never-completing sink.close() exits promptly with GeminiLiveException without hanging in finally', () async {
      late _HangingWebSocketChannel hangingChannel;
      final liveProvider = GeminiLiveProvider(
        channelFactory: (Uri uri) {
          hangingChannel = _HangingWebSocketChannel();
          return hangingChannel;
        },
      );
      addTearDown(liveProvider.dispose);

      final stopwatch = Stopwatch()..start();
      await expectLater(
        () => liveProvider.synthesizeSpeechOncePcm24k(
          apiKey: 'AIzaLiveMainKey',
          model: 'gemini-3.8-live',
          text: 'OfflineHangTest',
        ),
        throwsA(
          isA<GeminiLiveException>().having(
            (e) => e.message,
            'message',
            contains('timeout'),
          ),
        ),
      );
      stopwatch.stop();

      expect(hangingChannel.sinkCloseCalled, isTrue);
      // 5s ready timeout + non-blocking !isReady sink.close() must return well under 8s.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 8)));
    });
  });

  group('Hybrid TtsService Online AI, RAM Cache & Fallback', () {
    late AppDatabase db;
    late _FakeAudioService fakeAudio;
    late _FakeFlutterTts fakeFlutterTts;
    late int ttsApiCalls;
    late int nextStatusCode;
    late bool throwSocketException;
    late bool throwLiveQuotaError;
    late int? liveCloseCode;
    late String? liveCloseReason;
    late TtsService ttsService;
    late TutorRepository repo;
    late GeminiLiveProvider liveProvider;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      fakeAudio = _FakeAudioService();
      fakeFlutterTts = _FakeFlutterTts();
      ttsApiCalls = 0;
      nextStatusCode = 200;
      throwSocketException = false;
      throwLiveQuotaError = false;
      liveCloseCode = null;
      liveCloseReason = null;

      liveProvider = GeminiLiveProvider(
        channelFactory: (Uri uri) {
          return _FakeWebSocketChannel(
            uri: uri,
            onOutgoingFrame: (_FakeWebSocketChannel channel, dynamic raw) {
              final frame = jsonDecode(raw as String) as Map<String, dynamic>;
              if (frame.containsKey('setup')) {
                ttsApiCalls += 1;
                if (throwSocketException) {
                  throw const SocketException('No internet connection');
                }
                if (liveCloseCode != null) {
                  unawaited(
                    channel.closeFromServer(
                      liveCloseCode!,
                      liveCloseReason ?? '',
                    ),
                  );
                  return;
                }
                if (throwLiveQuotaError) {
                  channel.pushServerJson({
                    'error': {'message': '429 RESOURCE_EXHAUSTED quota exceeded'},
                  });
                  return;
                }
                channel.pushServerJson({'setupComplete': <String, dynamic>{}});
              } else if (frame.containsKey('clientContent')) {
                final pcmPayload = Uint8List.fromList(<int>[ttsApiCalls, 2, 3, 4]);
                channel.pushServerJson({
                  'serverContent': {
                    'modelTurn': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'audio/pcm;rate=24000',
                            'data': base64Encode(pcmPayload),
                          },
                        },
                      ],
                    },
                    'turnComplete': true,
                  },
                });
              }
            },
          );
        },
      );

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

      repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(httpClient: client),
        liveProvider: liveProvider,
      );
      await repo.updateSettings(
        const AppSettingsCompanion(
          apiKey: Value('AIzaHybridKey'),
          flashcardTtsModel: Value('gemini-3.8-live'),
        ),
      );

      ttsService = TtsService(
        repository: repo,
        audioService: fakeAudio,
        flutterTts: fakeFlutterTts,
      );
    });

    tearDown(() async {
      await liveProvider.dispose();
      await db.close();
    });

    test('Online Live API synthesis plays PCM24k buffer, hits RAM cache, busts on slow rate/model change & clears cache', () async {
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

      // Second identical call hits RAM cache without hitting WebSocket
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
          flashcardTtsModel: Value('gemini-2.5-flash-native-audio-preview-12-2025'),
        ),
      );
      await ttsService.speak('Perseverance');
      expect(ttsApiCalls, 3);
      expect(ttsService.activeVoiceSource.value, 'ai');

      // Clearing RAM cache forces fresh synthesis call
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
      expect(ttsService.lastFallbackDetail.value, isNotNull);
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
      expect(ttsService.lastFallbackDetail.value, isNotNull);
    });

    test('Falls back to flutter_tts on 429 / Live quota exceeded and honors cooldown until resetAiVoiceCooldown', () async {
      throwLiveQuotaError = true;

      await ttsService.speak('Alpha');
      // 1 attempt on flashcardTtsModel + 1 auto-retry on settings.liveModel
      expect(ttsApiCalls, 2);
      expect(fakeFlutterTts.spokenTexts, ['Alpha']);
      expect(ttsService.activeVoiceSource.value, 'offline_tts');
      expect(ttsService.lastFallbackReason.value, 'quota_exceeded');
      expect(ttsService.lastFallbackDetail.value, contains('Kuota'));

      // During 60s cooldown, Live/REST AI call is skipped directly
      throwLiveQuotaError = false;
      await ttsService.speak('Beta');
      expect(ttsApiCalls, 2);
      expect(fakeFlutterTts.spokenTexts, ['Alpha', 'Beta']);
      expect(ttsService.activeVoiceSource.value, 'offline_tts');
      expect(ttsService.lastFallbackReason.value, 'quota_exceeded');

      // Resetting cooldown re-enables AI voice and clears fallback detail
      ttsService.resetAiVoiceCooldown();
      expect(ttsService.lastFallbackReason.value, isNull);
      expect(ttsService.lastFallbackDetail.value, isNull);
      await ttsService.speak('Gamma');
      expect(ttsApiCalls, 3);
      expect(fakeAudio.playPcm24kCalls, hasLength(1));
      expect(ttsService.activeVoiceSource.value, 'ai');
      expect(ttsService.lastFallbackReason.value, isNull);
      expect(ttsService.lastFallbackDetail.value, isNull);
    });

    test('Model/session 1008 not-found populates lastFallbackDetail, skips 60s cooldown, and clears on AI/cache playback', () async {
      await db.settingsDao.updateSettings(
        const AppSettingsCompanion(
          flashcardTtsModel: Value('gemini-bad-live'),
          liveModel: Value('gemini-bad-live'),
        ),
      );
      liveCloseCode = 1008;
      liveCloseReason = 'models/gemini-bad-live is not found for API version v1beta';

      await ttsService.speak('FirstAttempt');
      expect(ttsApiCalls, 1);
      expect(ttsService.activeVoiceSource.value, 'offline_tts');
      expect(ttsService.lastFallbackReason.value, 'api_error');
      expect(ttsService.lastFallbackDetail.value, contains('1008'));
      expect(ttsService.lastFallbackDetail.value, contains('not found'));

      // Should NOT trigger 60s cooldown for not-found/ditolak errors -> 2nd call still hits AI
      liveCloseCode = null;
      liveCloseReason = null;
      await ttsService.speak('SecondAttempt');
      expect(ttsApiCalls, 2);
      expect(ttsService.activeVoiceSource.value, 'ai');
      expect(ttsService.lastFallbackReason.value, isNull);
      expect(ttsService.lastFallbackDetail.value, isNull);

      // Re-record a failure then verify RAM cache playback also clears fallback details
      liveCloseCode = 1008;
      liveCloseReason = 'models/gemini-bad-live is not found';
      await ttsService.speak('TriggerError');
      expect(ttsService.lastFallbackDetail.value, isNotNull);
      await ttsService.speak('SecondAttempt');
      expect(ttsService.activeVoiceSource.value, 'cache');
      expect(ttsService.lastFallbackReason.value, isNull);
      expect(ttsService.lastFallbackDetail.value, isNull);
    });

    test('Also falls back and applies cooldown on REST -tts 429 when a -tts model is configured', () async {
      await db.settingsDao.updateSettings(
        const AppSettingsCompanion(
          flashcardTtsModel: Value('gemini-2.5-flash-preview-tts'),
          liveModel: Value('gemini-2.5-flash-preview-tts'),
        ),
      );
      nextStatusCode = 429;

      await ttsService.speak('Delta');
      expect(ttsApiCalls, 1);
      expect(fakeFlutterTts.spokenTexts, ['Delta']);
      expect(ttsService.activeVoiceSource.value, 'offline_tts');
      expect(ttsService.lastFallbackReason.value, 'quota_exceeded');
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

    test('internetChecker skips AI loading when offline, keeps _pcmCache playable, and clears offline state on reconnect without wiping cache', () async {
      var isOnline = true;
      final networkTts = TtsService(
        repository: repo,
        audioService: fakeAudio,
        flutterTts: fakeFlutterTts,
        internetChecker: () async => isOnline,
      );
      addTearDown(networkTts.onClose);

      final loadingHistory = <bool>[];
      final loadingSub = networkTts.isLoadingAudio.listen(loadingHistory.add);
      addTearDown(loadingSub.cancel);

      // Step 1: Online synthesis populates _pcmCache for 'WarmCached'.
      await networkTts.speak('WarmCached');
      expect(ttsApiCalls, 1);
      expect(networkTts.activeVoiceSource.value, 'ai');
      expect(fakeAudio.playPcm24kCalls, hasLength(1));

      // Step 2: Go offline — uncached word skips AI loading & goes straight to offline_tts.
      isOnline = false;
      loadingHistory.clear();
      await networkTts.speak('OfflineWord');
      expect(ttsApiCalls, 1);
      expect(loadingHistory, isNot(contains(true)));
      expect(networkTts.isLoadingAudio.value, isFalse);
      expect(networkTts.activeVoiceSource.value, 'offline_tts');
      expect(networkTts.lastFallbackReason.value, 'offline');
      expect(networkTts.lastFallbackDetail.value, isNotNull);
      expect(fakeFlutterTts.spokenTexts, ['OfflineWord']);

      // Step 3: Still offline — previously cached word still plays from RAM cache.
      await networkTts.speak('WarmCached');
      expect(ttsApiCalls, 1);
      expect(networkTts.activeVoiceSource.value, 'cache');
      expect(fakeAudio.playPcm24kCalls, hasLength(2));

      // Step 4: Back to OfflineWord, then transition Offline -> Online clears offline state & keeps cache intact.
      await networkTts.speak('OfflineWord');
      expect(networkTts.activeVoiceSource.value, 'offline_tts');
      expect(networkTts.lastFallbackReason.value, 'offline');

      final stopCallsBeforeReconnect = fakeFlutterTts.stopCalls;
      isOnline = true;
      await networkTts.speak('RecoveredWord');
      expect(fakeFlutterTts.stopCalls, greaterThan(stopCallsBeforeReconnect));
      expect(ttsApiCalls, 2);
      expect(networkTts.activeVoiceSource.value, 'ai');
      expect(networkTts.lastFallbackReason.value, isNull);
      expect(networkTts.lastFallbackDetail.value, isNull);

      // Step 5: Verify _pcmCache entry from before offline episode is still intact (0 new API calls).
      await networkTts.speak('WarmCached');
      expect(ttsApiCalls, 2);
      expect(networkTts.activeVoiceSource.value, 'cache');
      expect(fakeAudio.playPcm24kCalls, hasLength(4));
    });

    test('Resets isLoadingAudio to false and falls back to flutter_tts on synthesize timeout or unexpected exception', () async {
      late Future<Uint8List> Function() nextAction;
      final throwingRepo = _ThrowingSynthTutorRepository(
        database: db,
        restProvider: GeminiRestProvider(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        liveProvider: liveProvider,
        onSynthesize: () => nextAction(),
      );
      final faultTts = TtsService(
        repository: throwingRepo,
        audioService: fakeAudio,
        flutterTts: fakeFlutterTts,
        internetChecker: () async => true,
      );
      addTearDown(faultTts.onClose);

      // 1. TimeoutException during synthesizeSpeechPcm24k -> isLoadingAudio resets & falls back to offline_tts.
      nextAction = () => Future<Uint8List>.error(
            TimeoutException('Simulated synthesize timeout'),
          );
      await faultTts.speak('TimeoutWord');
      expect(faultTts.isLoadingAudio.value, isFalse);
      expect(faultTts.activeVoiceSource.value, 'offline_tts');
      expect(faultTts.lastFallbackReason.value, 'offline');
      expect(fakeFlutterTts.spokenTexts, ['TimeoutWord']);

      // 2. Unexpected StateError/Exception during synthesizeSpeechPcm24k -> isLoadingAudio resets & falls back.
      nextAction = () => Future<Uint8List>.error(
            StateError('Unexpected internal synthesizer crash'),
          );
      await faultTts.speak('CrashWord');
      expect(faultTts.isLoadingAudio.value, isFalse);
      expect(faultTts.activeVoiceSource.value, 'offline_tts');
      expect(faultTts.lastFallbackReason.value, 'api_error');
      expect(
        faultTts.lastFallbackDetail.value,
        contains('Unexpected internal synthesizer crash'),
      );
      expect(fakeFlutterTts.spokenTexts, ['TimeoutWord', 'CrashWord']);
    });

    test('Persists valid RIFF/WAVE .wav files in my_english_tutor_audio, survives clearRamCache/restart offline with 0 API calls, recovers corrupt files, and clears via clearSavedAudioFiles', () async {
      final tempRoot = await Directory.systemTemp.createTemp('met_tts_disk_');
      addTearDown(() async {
        if (await tempRoot.exists()) {
          await tempRoot.delete(recursive: true);
        }
      });

      var isOnline = true;
      final firstInstance = TtsService(
        repository: repo,
        audioService: fakeAudio,
        flutterTts: fakeFlutterTts,
        internetChecker: () async => isOnline,
        cacheDirectoryProvider: () async => tempRoot,
      );

      // 1. First playback fetches Gemini TTS once and writes a valid RIFF/WAVE `.wav` file.
      await firstInstance.speak('Articulate');
      expect(ttsApiCalls, 1);
      expect(firstInstance.activeVoiceSource.value, 'ai');
      expect(fakeAudio.playPcm24kCalls, hasLength(1));
      final firstPcm = fakeAudio.playPcm24kCalls.first;

      await firstInstance.speak('Articulate', rate: 0.35);
      expect(ttsApiCalls, 2);

      final audioDir = Directory(
        '${tempRoot.path}${Platform.pathSeparator}${TtsService.audioFolderName}',
      );
      expect(await audioDir.exists(), isTrue);

      final wavFiles = (await audioDir.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('.wav'))
          .toList();
      expect(wavFiles, hasLength(2));

      final normalFile = wavFiles.firstWhere(
        (f) => f.path.split(Platform.pathSeparator).last.startsWith('articulate_normal_'),
      );
      expect(
        RegExp(r'^articulate_normal_[0-9a-f]{32}\.wav$').hasMatch(
          normalFile.path.split(Platform.pathSeparator).last,
        ),
        isTrue,
      );
      final wavBytes = await normalFile.readAsBytes();
      expect(String.fromCharCodes(wavBytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wavBytes.sublist(8, 12)), 'WAVE');
      expect(wavBytes.sublist(44), orderedEquals(firstPcm));

      final statsBeforeClose = await firstInstance.getSavedAudioStats();
      expect(statsBeforeClose.fileCount, 2);
      expect(
        statsBeforeClose.totalBytes,
        wavFiles.fold<int>(0, (sum, f) => sum + f.lengthSync()),
      );

      // 2. Simulate app close (clearRamCache + onClose) — disk `.wav` files remain intact!
      firstInstance.clearRamCache();
      firstInstance.onClose();
      expect(await normalFile.exists(), isTrue);

      // 3. Reopen offline with a brand-new TtsService instance -> plays from disk cache with 0 API calls!
      isOnline = false;
      final reopenedInstance = TtsService(
        repository: repo,
        audioService: fakeAudio,
        flutterTts: fakeFlutterTts,
        internetChecker: () async => isOnline,
        cacheDirectoryProvider: () async => tempRoot,
      );
      addTearDown(reopenedInstance.onClose);

      await reopenedInstance.speak('Articulate');
      expect(ttsApiCalls, 2);
      expect(reopenedInstance.activeVoiceSource.value, 'cache');
      expect(reopenedInstance.lastFallbackReason.value, isNull);
      expect(fakeAudio.playPcm24kCalls, hasLength(3));
      expect(fakeAudio.playPcm24kCalls.last, orderedEquals(firstPcm));

      // Corrupting a disk `.wav` (<= 44 bytes) causes deletion and re-fetch when online.
      await normalFile.writeAsBytes(Uint8List(10));
      reopenedInstance.clearRamCache();
      isOnline = true;
      await reopenedInstance.speak('Articulate');
      expect(ttsApiCalls, 3);
      expect(reopenedInstance.activeVoiceSource.value, 'ai');
      expect((await normalFile.readAsBytes()).length, greaterThan(44));

      // 4. clearSavedAudioFiles deletes all disk `.wav` files and resets stats + RAM cache.
      await reopenedInstance.clearSavedAudioFiles();
      final statsAfterClear = await reopenedInstance.getSavedAudioStats();
      expect(statsAfterClear.fileCount, 0);
      expect(statsAfterClear.totalBytes, 0);
      expect(await normalFile.exists(), isFalse);
    });
  });

  group('Drift v3 -> v6 & v4 -> v6 Migration, SettingsDao Export/Import & SettingsView (Live Models)', () {
    test('Drift v3 -> v6 on-disk migration preserves API key, 100 missions, flashcards & sets Live TTS default', () async {
      final tempDir = await Directory.systemTemp.createTemp('met_v3_v6_test_');
      final dbFile = File('${tempDir.path}/tutor_v3.sqlite');
      try {
        final dbV3Prep = AppDatabase(NativeDatabase(dbFile));
        expect(dbV3Prep.schemaVersion, 7);
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

        // Simulate existing v3 schema on disk prior to v6 upgrade
        await dbV3Prep.customStatement(
          'ALTER TABLE app_settings DROP COLUMN flashcard_model;',
        );
        await dbV3Prep.customStatement(
          'ALTER TABLE app_settings DROP COLUMN flashcard_tts_model;',
        );
        await dbV3Prep.customStatement(
          'ALTER TABLE flashcards DROP COLUMN parts_of_speech_json;',
        );
        await dbV3Prep.customStatement(
          'ALTER TABLE flashcards DROP COLUMN verb_tenses_examples_json;',
        );
        await dbV3Prep.customStatement(
          'ALTER TABLE flashcards DROP COLUMN study_status;',
        );
        await dbV3Prep.customStatement('PRAGMA user_version = 3;');
        await dbV3Prep.close();

        final dbUpgraded = AppDatabase(NativeDatabase(dbFile));
        final upgradedSettings = await dbUpgraded.settingsDao.getSettings();
        final allLessons = await dbUpgraded.select(dbUpgraded.lessons).get();
        final allDecks = await dbUpgraded.flashcardDao.getDecksWithStats();
        final upgradedCard =
            (await dbUpgraded.flashcardDao.getCardsByDeck(deckId)).single;

        expect(upgradedSettings.apiKey, 'legacy-v3-api-key');
        expect(upgradedSettings.flashcardModel, SettingsDao.defaultFlashcardModel);
        expect(upgradedSettings.flashcardTtsModel, 'gemini-3.8-live');
        expect(allLessons.length, 100);
        expect(allDecks.any((d) => d.deck.name == 'Migrated Deck'), isTrue);
        expect(upgradedCard.partsOfSpeechJson, '[]');
        expect(upgradedCard.verbTensesExamplesJson, '[]');
        expect(upgradedCard.studyStatus, 0);

        await dbUpgraded.close();
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('Drift v4 -> v6 on-disk migration switches legacy -tts model to active live_model & adds flashcard POS columns safely', () async {
      final tempDir = await Directory.systemTemp.createTemp('met_v4_v6_test_');
      final dbFile = File('${tempDir.path}/tutor_v4.sqlite');
      try {
        final dbV4Prep = AppDatabase(NativeDatabase(dbFile));
        await dbV4Prep.settingsDao.updateSettings(
          const AppSettingsCompanion(
            apiKey: Value('v4-api-key'),
            liveModel: Value('gemini-2.5-flash-native-audio-preview-12-2025'),
            flashcardTtsModel: Value('gemini-2.5-flash-preview-tts'),
          ),
        );
        final deckId = await dbV4Prep.flashcardDao.createDeck(
          name: 'V4 Preserved Deck',
        );
        final subDeckId = await dbV4Prep.flashcardDao.createSubDeck(
          deckId: deckId,
          name: 'Idioms',
        );
        await dbV4Prep.flashcardDao.createFlashcard(
          subDeckId: subDeckId,
          word: 'break a leg',
          meaningId: 'semoga berhasil',
        );

        await dbV4Prep.customStatement(
          'ALTER TABLE flashcards DROP COLUMN parts_of_speech_json;',
        );
        await dbV4Prep.customStatement(
          'ALTER TABLE flashcards DROP COLUMN verb_tenses_examples_json;',
        );
        await dbV4Prep.customStatement(
          'ALTER TABLE flashcards DROP COLUMN study_status;',
        );
        await dbV4Prep.customStatement('PRAGMA user_version = 4;');
        await dbV4Prep.close();

        final dbUpgraded = AppDatabase(NativeDatabase(dbFile));
        final upgradedSettings = await dbUpgraded.settingsDao.getSettings();
        final allLessons = await dbUpgraded.select(dbUpgraded.lessons).get();
        final allDecks = await dbUpgraded.flashcardDao.getDecksWithStats();
        final upgradedCard =
            (await dbUpgraded.flashcardDao.getCardsByDeck(deckId)).single;

        expect(upgradedSettings.apiKey, 'v4-api-key');
        expect(
          upgradedSettings.flashcardTtsModel,
          'gemini-2.5-flash-native-audio-preview-12-2025',
        );
        expect(allLessons.length, 100);
        expect(allDecks.any((d) => d.deck.name == 'V4 Preserved Deck'), isTrue);
        expect(upgradedCard.partsOfSpeechJson, '[]');
        expect(upgradedCard.verbTensesExamplesJson, '[]');
        expect(upgradedCard.studyStatus, 0);

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

    testWidgets('SettingsView at 360dp width displays Flashcard TTS Model (Live API), excludes transcribe/translate/-tts and saves selection with zero overflow', (WidgetTester tester) async {
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
                  'name': 'models/gemini-9.9-live',
                  'supportedGenerationMethods': ['bidiGenerateContent'],
                },
                {
                  'name': 'models/gemini-live-2.5-flash-transcribe',
                  'supportedGenerationMethods': ['bidiGenerateContent'],
                },
                {
                  'name': 'models/gemini-live-translate-preview',
                  'supportedGenerationMethods': ['bidiGenerateContent'],
                },
                {
                  'name': 'models/gemini-2.5-flash-preview-tts',
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
      final settingsController = Get.put<SettingsController>(
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

      // Verify dynamicTtsModels contains only Live API voice models (excluding transcribe/translate/-tts)
      expect(
        settingsController.dynamicTtsModels,
        unorderedEquals([
          'gemini-9.9-live',
          'gemini-2.5-flash-native-audio-preview-12-2025',
        ]),
      );
      expect(
        settingsController.dynamicTtsModels.any(
          (m) =>
              m.contains('transcribe') ||
              m.contains('translate') ||
              m.contains('-tts'),
        ),
        isFalse,
      );

      final flashcardAiLabel = find.text('Flashcard AI Model (Kalimat, Kuis & Pelafalan)');
      await tester.scrollUntilVisible(
        flashcardAiLabel,
        250,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      expect(flashcardAiLabel, findsOneWidget);

      final flashcardTtsLabel = find.text('Flashcard TTS Model (Live API)');
      await tester.scrollUntilVisible(
        flashcardTtsLabel,
        250,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      expect(flashcardTtsLabel, findsOneWidget);

      final saveCustomModelBtn = find.text('Simpan Model Kustom');
      await tester.scrollUntilVisible(
        saveCustomModelBtn,
        250,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      expect(flashcardTtsLabel, findsOneWidget);

      final dynamicLive99Chip = find.widgetWithText(ChoiceChip, 'gemini-9.9-live').last;
      expect(dynamicLive99Chip, findsOneWidget);

      final liveNativeTtsChip = find
          .widgetWithText(
            ChoiceChip,
            'gemini-2.5-flash-native-audio-preview-12-2025',
          )
          .last;
      await tester.ensureVisible(liveNativeTtsChip);
      await tester.pump();
      await tester.tap(liveNativeTtsChip);

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      final savedSettings = await tester.runAsync(() => repo.getSettings());
      expect(
        savedSettings?.flashcardTtsModel,
        'gemini-2.5-flash-native-audio-preview-12-2025',
      );

      // REST -tts chips must not be shown anywhere
      expect(
        find.widgetWithText(ChoiceChip, 'gemini-2.5-flash-preview-tts'),
        findsNothing,
      );

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

    testWidgets('FlashcardVoiceSourceChip opens diagnostic dialog showing lastFallbackDetail when tapped in offline_tts state', (WidgetTester tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final fakeAudio = _FakeAudioService();
      final fakeFlutterTts = _FakeFlutterTts();
      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
      );
      final ttsService = TtsService(
        repository: repo,
        audioService: fakeAudio,
        flutterTts: fakeFlutterTts,
      );
      ttsService.activeVoiceSource.value = 'offline_tts';
      ttsService.lastFallbackReason.value = 'error';
      ttsService.lastFallbackDetail.value =
          'Sesi Gemini Live ditolak (kode 1008): models/bad not found';

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: FlashcardVoiceSourceChip(ttsService: ttsService),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      await tester.tap(find.byType(FlashcardVoiceSourceChip));
      await tester.pumpAndSettle();

      expect(find.text('Info Suara Offline (TTS)'), findsOneWidget);
      expect(
        find.text('Sesi Gemini Live ditolak (kode 1008): models/bad not found'),
        findsOneWidget,
      );

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() async {
        await db.close();
      });
    });

    test('SettingsController.testFlashcardTts handles empty API key, error response, and plays Live PCM buffer directly on success', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final fakeAudio = _FakeAudioService();
      final fakeFlutterTts = _FakeFlutterTts();
      var failWith1008 = false;

      final liveProvider = GeminiLiveProvider(
        channelFactory: (Uri uri) {
          return _FakeWebSocketChannel(
            uri: uri,
            onOutgoingFrame: (_FakeWebSocketChannel channel, dynamic raw) {
              final frame = jsonDecode(raw as String) as Map<String, dynamic>;
              if (frame.containsKey('setup')) {
                if (failWith1008) {
                  unawaited(
                    channel.closeFromServer(
                      1008,
                      'models/invalid-live not found',
                    ),
                  );
                  return;
                }
                channel.pushServerJson({'setupComplete': <String, dynamic>{}});
              } else if (frame.containsKey('clientContent')) {
                channel.pushServerJson({
                  'serverContent': {
                    'modelTurn': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'audio/pcm;rate=24000',
                            'data': base64Encode(<int>[7, 8, 9, 10, 11]),
                          },
                        },
                      ],
                    },
                    'turnComplete': true,
                  },
                });
              }
            },
          );
        },
      );
      addTearDown(liveProvider.dispose);

      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        liveProvider: liveProvider,
      );
      final ttsService = TtsService(
        repository: repo,
        audioService: fakeAudio,
        flutterTts: fakeFlutterTts,
      );
      Get.reset();
      Get.put<TtsService>(ttsService);
      addTearDown(Get.reset);

      final controller = SettingsController(
        repository: repo,
        audioService: fakeAudio,
      );
      controller.onInit();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // 1. Empty API key
      controller.apiKeyController.text = '';
      await controller.testFlashcardTts();
      expect(controller.flashcardTtsTestSuccess.value, isFalse);
      expect(
        controller.flashcardTtsTestMessage.value,
        contains('API key Gemini masih kosong'),
      );
      expect(fakeFlutterTts.spokenTexts, isEmpty);

      // 2. Live WebSocket rejection does NOT silently fallback to flutter_tts
      failWith1008 = true;
      controller.apiKeyController.text = 'AIzaTestKey';
      controller.flashcardTtsModelController.text = 'invalid-live';
      await db.settingsDao.updateSettings(
        const AppSettingsCompanion(liveModel: Value('invalid-live')),
      );
      await controller.testFlashcardTts();
      expect(controller.flashcardTtsTestSuccess.value, isFalse);
      expect(controller.flashcardTtsTestMessage.value, contains('1008'));
      expect(fakeFlutterTts.spokenTexts, isEmpty);

      // 3. Valid Live WebSocket plays 5 PCM bytes directly
      failWith1008 = false;
      controller.flashcardTtsModelController.text = 'gemini-3.8-live';
      await controller.testFlashcardTts();
      expect(controller.flashcardTtsTestSuccess.value, isTrue);
      expect(
        controller.flashcardTtsTestMessage.value,
        'Berhasil! Suara AI berbunyi via model "gemini-3.8-live" (5 bytes).',
      );
      expect(fakeAudio.playPcm24kCalls, hasLength(1));
      expect(fakeFlutterTts.spokenTexts, isEmpty);
    });

    testWidgets('SettingsView Tes Suara Flashcard AI button runs direct Live test at 360dp with inline status banner and zero overflow', (WidgetTester tester) async {
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
      final liveProvider = GeminiLiveProvider(
        channelFactory: (Uri uri) {
          return _FakeWebSocketChannel(
            uri: uri,
            onOutgoingFrame: (_FakeWebSocketChannel channel, dynamic raw) {
              final frame = jsonDecode(raw as String) as Map<String, dynamic>;
              if (frame.containsKey('setup')) {
                channel.pushServerJson({'setupComplete': <String, dynamic>{}});
              } else if (frame.containsKey('clientContent')) {
                channel.pushServerJson({
                  'serverContent': {
                    'modelTurn': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'audio/pcm;rate=24000',
                            'data': base64Encode(<int>[21, 22, 23, 24]),
                          },
                        },
                      ],
                    },
                    'turnComplete': true,
                  },
                });
              }
            },
          );
        },
      );

      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        liveProvider: liveProvider,
      );
      await tester.runAsync(() async {
        await repo.updateSettings(
          const AppSettingsCompanion(
            apiKey: Value('AIzaWidgetTestKey'),
            flashcardTtsModel: Value('gemini-3.8-live'),
          ),
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
      final testVoiceBtn = find.text('Tes Suara Flashcard AI');
      await tester.scrollUntilVisible(
        testVoiceBtn,
        250,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      await tester.ensureVisible(testVoiceBtn);
      await tester.pump();
      await tester.tap(testVoiceBtn);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text(
          'Berhasil! Suara AI berbunyi via model "gemini-3.8-live" (4 bytes).',
        ),
        findsOneWidget,
      );
      expect(fakeAudio.playPcm24kCalls, hasLength(1));

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('RenderFlex overflowed'))
          .toList();
      expect(overflowErrors, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      Get.reset();
      await tester.runAsync(() async {
        await liveProvider.dispose();
        await db.close();
      });
    });

    testWidgets('SettingsView displays saved .wav audio stats and clears files on Hapus Audio Tersimpan tap at 360dp', (WidgetTester tester) async {
      final errors = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final tempRoot = await tester.runAsync(
        () => Directory.systemTemp.createTemp('met_settings_audio_'),
      );
      addTearDown(() async {
        await tester.runAsync(() async {
          if (tempRoot != null && await tempRoot.exists()) {
            await tempRoot.delete(recursive: true);
          }
        });
      });

      final db = AppDatabase(NativeDatabase.memory());
      final fakeAudio = _FakeAudioService();
      final fakeFlutterTts = _FakeFlutterTts();
      final liveProvider = GeminiLiveProvider(
        channelFactory: (Uri uri) {
          return _FakeWebSocketChannel(
            uri: uri,
            onOutgoingFrame: (_FakeWebSocketChannel channel, dynamic raw) {
              final frame = jsonDecode(raw as String) as Map<String, dynamic>;
              if (frame.containsKey('setup')) {
                channel.pushServerJson({'setupComplete': <String, dynamic>{}});
              } else if (frame.containsKey('clientContent')) {
                channel.pushServerJson({
                  'serverContent': {
                    'modelTurn': {
                      'parts': [
                        {
                          'inlineData': {
                            'mimeType': 'audio/pcm;rate=24000',
                            'data': base64Encode(
                              List<int>.filled(2048, 7),
                            ),
                          },
                        },
                      ],
                    },
                    'turnComplete': true,
                  },
                });
              }
            },
          );
        },
      );

      final repo = TutorRepository(
        database: db,
        restProvider: GeminiRestProvider(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        liveProvider: liveProvider,
      );
      await tester.runAsync(() async {
        await repo.updateSettings(
          const AppSettingsCompanion(
            apiKey: Value('AIzaSettingsAudioKey'),
            flashcardTtsModel: Value('gemini-3.8-live'),
          ),
        );
      });

      final ttsService = TtsService(
        repository: repo,
        audioService: fakeAudio,
        flutterTts: fakeFlutterTts,
        cacheDirectoryProvider: () async => tempRoot!,
      );

      // Populate 1 saved `.wav` file before opening SettingsView
      await tester.runAsync(() => ttsService.speak('Persistence'));
      final seededStats = await tester.runAsync(
        () => ttsService.getSavedAudioStats(),
      );
      expect(seededStats?.fileCount, 1);

      Get.reset();
      Get.put<AudioService>(fakeAudio, permanent: true);
      Get.put<TtsService>(ttsService, permanent: true);
      final settingsController = Get.put<SettingsController>(
        SettingsController(repository: repo, audioService: fakeAudio),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const SettingsView(),
        ),
      );
      await tester.runAsync(() async {
        await settingsController.refreshSavedAudioStats();
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final scrollable = find.byType(Scrollable).first;
      final clearBtn = find.text('Hapus Audio Tersimpan');
      await tester.scrollUntilVisible(
        clearBtn,
        250,
        maxScrolls: 60,
        scrollable: scrollable,
      );
      await tester.ensureVisible(clearBtn);
      await tester.pump();

      expect(settingsController.savedAudioFileCount.value, 1);
      expect(find.text('Audio tersimpan: 1 file (2,0 KB)'), findsOneWidget);

      final clearOutlinedBtn = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: clearBtn,
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      );
      expect(clearOutlinedBtn.enabled, isTrue);

      await tester.runAsync(() => settingsController.clearSavedAudioFiles());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(settingsController.savedAudioFileCount.value, 0);
      expect(find.text('Audio tersimpan: 0 file (0 B)'), findsOneWidget);

      final overflowErrors = errors
          .where((e) => e.exceptionAsString().contains('RenderFlex overflowed'))
          .toList();
      expect(overflowErrors, isEmpty);

      Get.closeAllSnackbars();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      Get.reset();
      await tester.runAsync(() async {
        await liveProvider.dispose();
        await db.close();
      });
    });
  });
}
