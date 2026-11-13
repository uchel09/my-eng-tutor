@Timeout(Duration(seconds: 25))
library;

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Value;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:my_english_tutor/app/core/theme/app_theme.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/local/daos/flashcard_dao.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/repositories/tutor_repository.dart';
import 'package:my_english_tutor/app/data/services/audio_service.dart';
import 'package:my_english_tutor/app/data/services/tts_service.dart';
import 'package:my_english_tutor/app/modules/flashcards/models/flashcard_nav_args.dart';
import 'package:my_english_tutor/app/modules/home/bindings/home_binding.dart';
import 'package:my_english_tutor/app/routes/app_pages.dart';

class _FakeTtsCall {
  const _FakeTtsCall(this.text, this.rate);

  final String text;
  final double rate;
}

class _FakeTtsService extends TtsService {
  final List<_FakeTtsCall> speakCalls = <_FakeTtsCall>[];
  int stopCalls = 0;

  @override
  Future<void> speak(
    String text, {
    String language = 'en-US',
    double rate = 0.48,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    isSpeaking.value = true;
    activeText.value = trimmed;
    speakCalls.add(_FakeTtsCall(trimmed, rate));
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    isSpeaking.value = false;
    activeText.value = '';
  }
}

class _FakeAudioService extends AudioService {
  bool permissionGranted = true;
  int permissionCheckCount = 0;
  int openSettingsCount = 0;
  int startMicCalls = 0;
  int stopMicCalls = 0;
  int clearBufferCalls = 0;
  int? lastMaxCaptureSeconds;
  bool? lastCaptureBufferForEval;

  @override
  Future<bool> ensureMicrophonePermission() async {
    permissionCheckCount += 1;
    return permissionGranted;
  }

  @override
  Future<bool> openDeviceAppSettings() async {
    openSettingsCount += 1;
    return true;
  }

  @override
  Future<void> startMicStream({
    bool captureBufferForEval = false,
    bool appendBuffer = false,
    int maxCaptureSeconds = 90,
  }) async {
    startMicCalls += 1;
    lastCaptureBufferForEval = captureBufferForEval;
    lastMaxCaptureSeconds = maxCaptureSeconds;

    if (!permissionGranted) {
      throw StateError('Izin mikrofon belum diberikan.');
    }

    prepareCaptureBufferForTest(
      captureBufferForEval: captureBufferForEval,
      appendBuffer: appendBuffer,
      maxCaptureSeconds: maxCaptureSeconds,
    );
    // Seed non-empty 16kHz PCM chunk so buildRecordedWavBytes produces valid WAV bytes.
    appendCaptureChunkForTest(Uint8List.fromList(<int>[12, 0, 24, 0, 36, 0, 48, 0]));
    isRecording.value = true;
  }

  @override
  Future<void> stopMicStream() async {
    stopMicCalls += 1;
    isRecording.value = false;
  }

  @override
  void clearRecordedBuffer() {
    clearBufferCalls += 1;
    super.clearRecordedBuffer();
  }
}

class _FakePronunciationGeminiProvider extends GeminiRestProvider {
  String? lastSentence;
  String? lastTargetWord;
  Uint8List? lastAudioBytes;

  @override
  Future<SentencePronunciationFeedback> evaluateSentencePronunciation({
    required String apiKey,
    required String model,
    required String targetSentence,
    String? targetWord,
    required Uint8List audioWavBytes,
  }) async {
    lastSentence = targetSentence;
    lastTargetWord = targetWord;
    lastAudioBytes = audioWavBytes;

    return const SentencePronunciationFeedback(
      score: 88,
      clarityScore: 90,
      intonationScore: 84,
      heardText: 'We must negotiate the deal today.',
      overallFeedbackId: 'Pelafalan kalimat sudah jelas dan ritmenya natural.',
      wordFeedback: <SentenceWordFeedback>[
        SentenceWordFeedback(word: 'We', status: 'good', tipId: ''),
        SentenceWordFeedback(word: 'must', status: 'good', tipId: ''),
        SentenceWordFeedback(
          word: 'negotiate',
          status: 'needs_work',
          tipId: 'Tekankan suku kata kedua: ne-GO-ti-ate.',
        ),
        SentenceWordFeedback(
          word: 'today',
          status: 'missing',
          tipId: 'Kata akhir belum terdengar jelas.',
        ),
      ],
      practiceTipsId: <String>[
        'Perjelas penekanan suku kata pada kata "negotiate".',
      ],
    );
  }
}

void main() {
  group('GeminiRestProvider.evaluateSentencePronunciation', () {
    test(
      'sends audio/wav inlineData payload and parses structured feedback robustly',
      () async {
        Map<String, dynamic>? capturedBody;
        final fakeWav = buildWavFromPcm16(
          pcmBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        );

        final mockClient = MockClient((http.Request request) async {
          expect(request.url.path, contains(':generateContent'));
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

          final responseJson = <String, dynamic>{
            'candidates': <Map<String, dynamic>>[
              <String, dynamic>{
                'content': <String, dynamic>{
                  'parts': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'text': '''```json
{
  "score": 115,
  "clarityScore": "86",
  "intonationScore": -5,
  "heardText": "She can negotiate effectively.",
  "overallFeedbackId": "Bagus sekali, artikulasi sudah cukup jelas.",
  "wordFeedback": [
    {"word": "She", "status": "good", "tipId": ""},
    {"word": "negotiate", "status": "needs improvement", "tipId": "Tekankan -go-."},
    {"word": "effectively", "status": "omitted", "tipId": "Akhiran -ly belum terdengar."}
  ],
  "practiceTipsId": [
    "Latih penekanan kata kerja berakhiran -ate."
  ]
}
```''',
                    },
                  ],
                },
              },
            ],
          };
          return http.Response(jsonEncode(responseJson), 200);
        });

        final provider = GeminiRestProvider(httpClient: mockClient);
        final feedback = await provider.evaluateSentencePronunciation(
          apiKey: 'demo-key',
          model: 'gemini-2.5-flash',
          targetSentence: 'She can negotiate effectively.',
          targetWord: 'negotiate',
          audioWavBytes: fakeWav,
        );

        expect(capturedBody, isNotNull);
        final contents = capturedBody!['contents'] as List<dynamic>;
        final parts =
            (contents.first as Map<String, dynamic>)['parts'] as List<dynamic>;
        expect(parts, hasLength(2));
        expect(
          (parts[0] as Map<String, dynamic>)['text'],
          allOf(
            contains('She can negotiate effectively.'),
            contains('negotiate'),
          ),
        );
        final inlineData = (parts[1] as Map<String, dynamic>)['inlineData']
            as Map<String, dynamic>;
        expect(inlineData['mimeType'], 'audio/wav');
        expect(inlineData['data'], base64Encode(fakeWav));

        expect(feedback.score, 100);
        expect(feedback.clarityScore, 86);
        expect(feedback.intonationScore, 0);
        expect(feedback.heardText, 'She can negotiate effectively.');
        expect(feedback.wordFeedback, hasLength(3));
        expect(feedback.wordFeedback[0].status, 'good');
        expect(feedback.wordFeedback[1].status, 'needs_work');
        expect(feedback.wordFeedback[2].status, 'missing');
        expect(
          feedback.practiceTipsId,
          equals(<String>['Latih penekanan kata kerja berakhiran -ate.']),
        );
      },
    );

    test(
      'throws GeminiApiException when apiKey or audioWavBytes is empty',
      () async {
        final provider = GeminiRestProvider(
          httpClient: MockClient(
            (_) async => http.Response('{}', 200),
          ),
        );

        await expectLater(
          () => provider.evaluateSentencePronunciation(
            apiKey: '   ',
            model: 'gemini-2.5-flash',
            targetSentence: 'Hello world.',
            audioWavBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          ),
          throwsA(
            isA<GeminiApiException>().having((e) => e.statusCode, 'code', 400),
          ),
        );

        await expectLater(
          () => provider.evaluateSentencePronunciation(
            apiKey: 'valid-key',
            model: 'gemini-2.5-flash',
            targetSentence: 'Hello world.',
            audioWavBytes: Uint8List(0),
          ),
          throwsA(
            isA<GeminiApiException>().having((e) => e.statusCode, 'code', 400),
          ),
        );
      },
    );
  });

  group('FlashcardStudyView & SentencePronunciationSheet 360dp UI', () {
    late AppDatabase db;
    late _FakeTtsService fakeTts;
    late _FakeAudioService fakeAudio;
    late _FakePronunciationGeminiProvider fakeGemini;
    late FlashcardSubDeck subDeck;

    setUp(() async {
      Get.testMode = true;
      db = AppDatabase(NativeDatabase.memory());
      await db.roadmapDao.watchAllLevelsWithLessons().first;
      await db.settingsDao.updateSettings(
        const AppSettingsCompanion(apiKey: Value('test-api-key')),
      );

      final deckId = await db.flashcardDao.createDeck(name: 'Business');
      final subDeckId = await db.flashcardDao.createSubDeck(
        deckId: deckId,
        name: 'Meetings',
      );
      await db.flashcardDao.createFlashcard(
        subDeckId: subDeckId,
        word: 'negotiate',
        meaningId: 'bernegosiasi',
        wordType: 'verb',
        examples: const <FlashcardExampleItem>[
          FlashcardExampleItem(
            tense: 'Present Perfect Continuous',
            en: 'We must negotiate the deal today.',
            id: 'Kita harus menegosiasikan kesepakatan hari ini.',
          ),
        ],
      );
      final list = await db.flashcardDao.getSubDecksByDeck(deckId);
      subDeck = list.single;

      fakeTts = _FakeTtsService();
      fakeAudio = _FakeAudioService();
      fakeGemini = _FakePronunciationGeminiProvider();

      Get.put<AppDatabase>(db, permanent: true);
      Get.put<AudioService>(fakeAudio, permanent: true);
      Get.put<TtsService>(fakeTts, permanent: true);
      Get.put<GeminiRestProvider>(fakeGemini, permanent: true);
      Get.put<TutorRepository>(
        TutorRepository(database: db, restProvider: fakeGemini),
        permanent: true,
      );
      HomeBinding().dependencies();
    });

    tearDown(() async {
      Get.reset();
      await db.close();
    });

    Future<void> openStudyScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        GetMaterialApp(
          title: 'My English Tutor',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          initialRoute: Routes.HOME,
          getPages: AppPages.routes,
        ),
      );
      await tester.pumpAndSettle();

      unawaited(
        Get.toNamed<void>(
          Routes.FLASHCARD_CARDS,
          arguments: FlashcardStudyArgs(
            subDeck: subDeck,
            deckName: 'Business',
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder activeMainScrollable() {
      return find
          .descendant(
            of: find.byType(Scaffold).last,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Scrollable && w.physics is! NeverScrollableScrollPhysics,
            ),
          )
          .first;
    }

    Future<void> scrollToAndTapPractice(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.text('Practice'),
        200,
        scrollable: activeMainScrollable(),
      );
      await tester.ensureVisible(find.text('Practice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Practice button opens sheet, Dengar Pelan uses rate 0.35, recording shows word feedback and updates card score at 360dp',
      (tester) async {
        final capturedErrors = <FlutterErrorDetails>[];
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          capturedErrors.add(details);
          originalOnError?.call(details);
        };
        addTearDown(() {
          FlutterError.onError = originalOnError;
        });

        await openStudyScreen(tester);
        await scrollToAndTapPractice(tester);

        expect(find.text('Latihan Pronunciation'), findsOneWidget);
        expect(
          find.text('We must negotiate the deal today.'),
          findsWidgets,
        );
        expect(find.text('Dengar Normal'), findsOneWidget);
        expect(find.text('Dengar Pelan'), findsOneWidget);

        await tester.tap(find.text('Dengar Pelan'));
        await tester.pump();
        expect(
          fakeTts.speakCalls.any(
            (c) => c.text == 'We must negotiate the deal today.' && c.rate == 0.35,
          ),
          isTrue,
        );

        await tester.tap(find.text('Mulai Rekam'));
        await tester.pumpAndSettle();

        expect(fakeTts.stopCalls, greaterThanOrEqualTo(1));
        expect(fakeAudio.startMicCalls, 1);
        expect(fakeAudio.lastCaptureBufferForEval, isTrue);
        expect(fakeAudio.lastMaxCaptureSeconds, 20);
        expect(find.text('Stop & Nilai'), findsOneWidget);

        await tester.tap(find.text('Stop & Nilai'));
        await tester.pumpAndSettle();

        expect(fakeAudio.stopMicCalls, 1);
        expect(fakeGemini.lastSentence, 'We must negotiate the deal today.');
        expect(fakeGemini.lastTargetWord, 'negotiate');
        expect(fakeGemini.lastAudioBytes, isNotEmpty);

        expect(find.text('88 / 100'), findsOneWidget);
        expect(find.text('Kejelasan: 90'), findsOneWidget);
        expect(find.text('Intonasi: 84'), findsOneWidget);
        expect(find.text('Evaluasi Per Kata'), findsOneWidget);
        expect(find.text('negotiate'), findsWidgets);
        expect(
          find.text('Terdengar seperti: "We must negotiate the deal today."'),
          findsOneWidget,
        );
        expect(find.text('Tips Latihan'), findsOneWidget);
        expect(find.text('Coba Lagi'), findsOneWidget);

        // Close bottom sheet and verify score chip appears on the example card.
        await tester.tap(find.byTooltip('Tutup'));
        await tester.pumpAndSettle();
        expect(find.text('88%'), findsOneWidget);

        final overflowErrors = capturedErrors
            .where((e) => e.exceptionAsString().contains('RenderFlex overflowed'))
            .toList();
        expect(overflowErrors, isEmpty);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );

    testWidgets(
      'Permission denied shows Buka Pengaturan button and closing mid-recording stops mic cleanly',
      (tester) async {
        await openStudyScreen(tester);
        await scrollToAndTapPractice(tester);

        // Denied permission state shows Buka Pengaturan button.
        fakeAudio.permissionGranted = false;
        await tester.tap(find.text('Mulai Rekam'));
        await tester.pumpAndSettle();

        expect(find.text('Buka Pengaturan'), findsOneWidget);
        await tester.tap(find.text('Buka Pengaturan'));
        await tester.pump();
        expect(fakeAudio.openSettingsCount, 1);

        // Grant permission, start recording, then dismiss sheet mid-recording.
        fakeAudio.permissionGranted = true;
        await tester.tap(find.text('Coba Lagi'));
        await tester.pumpAndSettle();
        expect(find.text('Stop & Nilai'), findsOneWidget);

        await tester.tap(find.byTooltip('Tutup'));
        await tester.pumpAndSettle();

        expect(fakeAudio.stopMicCalls, greaterThanOrEqualTo(1));
        expect(fakeAudio.clearBufferCalls, greaterThanOrEqualTo(1));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      },
    );
  });
}
