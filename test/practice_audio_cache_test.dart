import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:my_english_tutor/app/core/theme/app_theme.dart';
import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/models/transcript_turn_model.dart';
import 'package:my_english_tutor/app/data/providers/gemini_live_provider.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/repositories/tutor_repository.dart';
import 'package:my_english_tutor/app/data/services/audio_service.dart';
import 'package:my_english_tutor/app/modules/practice/controllers/practice_controller.dart';
import 'package:my_english_tutor/app/modules/practice/views/practice_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AudioService audioService;
  late GeminiLiveProvider liveProvider;
  late TutorRepository repository;
  late PracticeController controller;

  setUp(() {
    Get.testMode = true;
    db = AppDatabase(NativeDatabase.memory());
    audioService = AudioService();
    liveProvider = GeminiLiveProvider();
    repository = TutorRepository(
      database: db,
      restProvider: GeminiRestProvider(),
    );
    controller = PracticeController(
      liveProvider: liveProvider,
      audioService: audioService,
      repository: repository,
    );
  });

  tearDown(() async {
    controller.onClose();
    Get.reset();
    await db.close();
  });

  group('PracticeController tutor audio cache', () {
    test('pairs audio->text->turnComplete and text->audio->turnComplete', () {
      final chunkA1 = Uint8List.fromList([1, 2, 3, 4]);
      final chunkA2 = Uint8List.fromList([5, 6]);
      controller.appendTutorAudioChunk(chunkA1);
      controller.appendTutorAudioChunk(chunkA2);
      controller.appendTranscriptTurnForTest(
        TranscriptTurnModel(
          role: 'tutor',
          text: 'Hello there!',
          timestamp: DateTime(2026, 11, 13, 10, 0),
        ),
      );
      controller.onTutorTurnComplete();

      expect(controller.tutorAudioByTurnIndex[0], equals([1, 2, 3, 4, 5, 6]));

      controller.appendTranscriptTurnForTest(
        TranscriptTurnModel(
          role: 'user',
          text: 'Hi tutor',
          timestamp: DateTime(2026, 11, 13, 10, 0, 5),
        ),
      );
      controller.appendTranscriptTurnForTest(
        TranscriptTurnModel(
          role: 'tutor',
          text: 'How is your day?',
          timestamp: DateTime(2026, 11, 13, 10, 0, 10),
        ),
      );
      controller.appendTutorAudioChunk(Uint8List.fromList([10, 20, 30]));
      controller.appendTutorAudioChunk(Uint8List.fromList([40]));
      controller.onTutorTurnComplete();

      expect(controller.tutorAudioByTurnIndex.containsKey(1), isFalse);
      expect(controller.tutorAudioByTurnIndex[2], equals([10, 20, 30, 40]));
    });

    test('caps cached audio buffer at 3 MB per tutor turn', () {
      const twoMb = 2 * 1024 * 1024;
      controller.appendTranscriptTurnForTest(
        TranscriptTurnModel(
          role: 'tutor',
          text: 'Long speech response',
          timestamp: DateTime(2026, 11, 13, 10, 1),
        ),
      );

      controller.appendTutorAudioChunk(Uint8List(twoMb));
      controller.appendTutorAudioChunk(Uint8List(twoMb));
      controller.appendTutorAudioChunk(Uint8List(1024));
      controller.onTutorTurnComplete();

      final cached = controller.tutorAudioByTurnIndex[0];
      expect(cached, isNotNull);
      expect(cached!.length, equals(PracticeController.maxTutorAudioBytesPerTurn));
    });

    test('clears all cached audio on clearTutorAudioCacheForTest and onClose', () {
      controller.appendTranscriptTurnForTest(
        TranscriptTurnModel(
          role: 'tutor',
          text: 'Turn 1',
          timestamp: DateTime(2026, 11, 13, 10, 2),
        ),
      );
      controller.appendTutorAudioChunk(Uint8List.fromList([7, 8, 9]));
      controller.onTutorTurnComplete();
      controller.replayingTurnIndex.value = 0;

      expect(controller.tutorAudioByTurnIndex, isNotEmpty);

      controller.clearTutorAudioCacheForTest();
      expect(controller.tutorAudioByTurnIndex, isEmpty);
      expect(controller.replayingTurnIndex.value, isNull);

      controller.appendTranscriptTurnForTest(
        TranscriptTurnModel(
          role: 'tutor',
          text: 'Turn 2',
          timestamp: DateTime(2026, 11, 13, 10, 3),
        ),
      );
      controller.appendTutorAudioChunk(Uint8List.fromList([11, 12]));
      controller.onTutorTurnComplete();
      controller.replayingTurnIndex.value = 1;

      controller.onClose();
      expect(controller.tutorAudioByTurnIndex, isEmpty);
      expect(controller.replayingTurnIndex.value, isNull);
    });
  });

  group('GeminiLiveProvider audioStreamEnd & AudioService appendBuffer', () {
    test('encodes realtimeInput audioStreamEnd payload and ignores disconnected send', () {
      final decoded = jsonDecode(
        GeminiLiveProvider.encodeAudioStreamEndPayload(),
      ) as Map<String, dynamic>;
      expect(decoded['realtimeInput'], equals({'audioStreamEnd': true}));

      // Should not throw when WebSocket is disconnected.
      expect(() => liveProvider.sendAudioStreamEnd(), returnsNormally);
    });

    test('appendBuffer preserves previous turns and appendBuffer=false resets buffer', () {
      audioService.prepareCaptureBufferForTest(
        captureBufferForEval: true,
        appendBuffer: true,
        maxCaptureSeconds: 10,
      );
      audioService.appendCaptureChunkForTest(Uint8List.fromList([1, 2, 3, 4]));

      // Second recording turn in the same session keeps turn 1 bytes.
      audioService.prepareCaptureBufferForTest(
        captureBufferForEval: true,
        appendBuffer: true,
        maxCaptureSeconds: 10,
      );
      audioService.appendCaptureChunkForTest(Uint8List.fromList([5, 6]));

      final combinedWav = audioService.buildRecordedWavBytes();
      expect(combinedWav, isNotNull);
      // 44-byte RIFF/WAVE header + 6 bytes PCM payload across 2 turns.
      expect(combinedWav!.length, equals(44 + 6));
      expect(combinedWav.sublist(44), equals([1, 2, 3, 4, 5, 6]));

      // appendBuffer: false resets to only newly captured chunks.
      audioService.prepareCaptureBufferForTest(
        captureBufferForEval: true,
        appendBuffer: false,
        maxCaptureSeconds: 10,
      );
      audioService.appendCaptureChunkForTest(Uint8List.fromList([9, 8]));

      final resetWav = audioService.buildRecordedWavBytes();
      expect(resetWav, isNotNull);
      expect(resetWav!.length, equals(44 + 2));
      expect(resetWav.sublist(44), equals([9, 8]));
    });
  });

  testWidgets('PracticeView renders manual Rekam/Kirim & Speaker controls at 360dp', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put<PracticeController>(controller);
    controller.errorMessage.value = null;
    controller.connectionState.value = LiveConnectionState.connected;
    controller.isMicActive.value = false;

    controller.appendTranscriptTurnForTest(
      TranscriptTurnModel(
        role: 'tutor',
        text: 'Hello! Tell me about your morning routine.',
        timestamp: DateTime(2026, 11, 13, 10, 5),
      ),
    );
    controller.appendTutorAudioChunk(Uint8List.fromList([1, 2, 3, 4]));
    controller.onTutorTurnComplete();

    controller.appendTranscriptTurnForTest(
      TranscriptTurnModel(
        role: 'user',
        text: 'I wake up at six AM.',
        timestamp: DateTime(2026, 11, 13, 10, 5, 20),
      ),
    );

    controller.appendTranscriptTurnForTest(
      TranscriptTurnModel(
        role: 'tutor',
        text: 'This turn has text only.',
        timestamp: DateTime(2026, 11, 13, 10, 6),
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: const PracticeView(),
      ),
    );
    await tester.pump();

    expect(find.text('Rekam'), findsOneWidget);
    expect(
      find.text('Ketuk tombol Rekam di bawah untuk mulai berbicara'),
      findsOneWidget,
    );
    expect(find.text('Dengar Ulang'), findsOneWidget);
    expect(find.text('Hanya teks'), findsOneWidget);

    // Simulate active recording state -> Kirim button & recording banner.
    controller.isMicActive.value = true;
    await tester.pump();

    expect(find.text('Kirim'), findsOneWidget);
    expect(
      find.text('Sedang merekam suara Anda... Ketuk Kirim jika selesai'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
