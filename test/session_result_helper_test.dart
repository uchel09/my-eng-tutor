import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Value;

import 'package:my_english_tutor/app/data/local/app_database.dart';
import 'package:my_english_tutor/app/data/models/practice_args.dart';
import 'package:my_english_tutor/app/data/models/session_result_args.dart';
import 'package:my_english_tutor/app/data/models/speech_insight_model.dart';
import 'package:my_english_tutor/app/data/models/transcript_turn_model.dart';
import 'package:my_english_tutor/app/data/providers/gemini_rest_provider.dart';
import 'package:my_english_tutor/app/data/repositories/tutor_repository.dart';
import 'package:my_english_tutor/app/modules/session_result/controllers/session_result_controller.dart';

class _FakeGeminiRestProvider extends GeminiRestProvider {
  @override
  Future<SpeechInsightModel> evaluateSpeakingSession({
    required String apiKey,
    required String model,
    required String targetCefrLevel,
    required String sessionType,
    required String lessonTitle,
    required String scenarioPrompt,
    required bool bilingualBeginnerSupport,
    required List<TranscriptTurnModel> transcript,
    dynamic recordedAudioWavBytes,
  }) async {
    return const SpeechInsightModel(
      overallScore: 86,
      fluencyScore: 85,
      grammarScore: 87,
      vocabScore: 86,
      pronunciationScore: 84,
      fillerCount: 0,
      detectedFillers: <String>[],
      aiSummary: 'Great articulation and clear pacing.',
      mistakes: <MistakeItemModel>[],
      vocabSuggestions: <VocabSuggestionModel>[
        VocabSuggestionModel(
          word: 'articulate',
          meaningId: 'fasih dan jelas',
          exampleSentence: 'She is very articulate during meetings.',
          cefrLevel: 'B2',
        ),
        VocabSuggestionModel(
          word: 'resilient',
          meaningId: 'tangguh',
          exampleSentence: 'Stay resilient through challenges.',
          cefrLevel: 'B2',
        ),
      ],
    );
  }
}

void main() {
  late AppDatabase db;
  late TutorRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.roadmapDao.watchAllLevelsWithLessons().first;
    repository = TutorRepository(
      database: db,
      restProvider: GeminiRestProvider(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'getMistakesForSession and getVocabForSession filter by sessionId',
    () async {
      final now = DateTime(2026, 11, 13, 16, 0);

      final session1Id = await db.practiceDao.saveSessionWithInsights(
        session: PracticeSessionsCompanion.insert(
          sessionType: 'free_talk',
          startedAt: now,
          overallScore: const Value(80),
          passed: const Value(true),
        ),
        mistakesList: [
          MistakesCompanion.insert(
            sessionId: 0,
            originalSentence: 'I go yesterday.',
            correctedSentence: 'I went yesterday.',
            explanation: 'Use past tense.',
            category: 'grammar',
            createdAt: now,
          ),
        ],
        vocabList: [
          VocabItemsCompanion.insert(
            word: 'itinerary',
            meaningId: 'rencana perjalanan',
            exampleSentence: 'Here is our travel itinerary.',
            cefrLevel: 'B1',
            createdAt: now,
          ),
        ],
      );

      final session2Id = await db.practiceDao.saveSessionWithInsights(
        session: PracticeSessionsCompanion.insert(
          sessionType: 'free_talk',
          startedAt: now.add(const Duration(minutes: 5)),
          overallScore: const Value(88),
          passed: const Value(true),
        ),
        mistakesList: [
          MistakesCompanion.insert(
            sessionId: 0,
            originalSentence: 'She have two cats.',
            correctedSentence: 'She has two cats.',
            explanation: 'Third-person singular uses has.',
            category: 'grammar',
            createdAt: now,
          ),
        ],
        vocabList: [
          VocabItemsCompanion.insert(
            word: 'concise',
            meaningId: 'ringkas dan jelas',
            exampleSentence: 'Keep your summary concise.',
            cefrLevel: 'B2',
            createdAt: now,
          ),
        ],
      );

      final mistakes1 = await repository.getMistakesForSession(session1Id);
      final vocab1 = await repository.getVocabForSession(session1Id);
      expect(mistakes1, hasLength(1));
      expect(mistakes1.first.correctedSentence, equals('I went yesterday.'));
      expect(vocab1, hasLength(1));
      expect(vocab1.first.word, equals('itinerary'));

      final mistakes2 = await repository.getMistakesForSession(session2Id);
      final vocab2 = await repository.getVocabForSession(session2Id);
      expect(mistakes2, hasLength(1));
      expect(mistakes2.first.correctedSentence, equals('She has two cats.'));
      expect(vocab2, hasLength(1));
      expect(vocab2.first.word, equals('concise'));
    },
  );

  test(
    'findNextUnlockedLabelAfter returns next lesson or next level label',
    () async {
      final roadmap = await repository.watchRoadmap().first;
      final a1Lesson1 = roadmap[0].lessons[0];
      final a1LastLesson = roadmap[0].lessons.last;
      final c2LastLesson = roadmap[5].lessons.last;

      // Not completed yet -> null
      expect(await repository.findNextUnlockedLabelAfter(a1Lesson1.id), isNull);

      // Complete A1 Lesson 1 with score 80 -> returns A1 Lesson 2
      await db.roadmapDao.unlockNextLessonOrLevel(a1Lesson1.id, 80);
      expect(
        await repository.findNextUnlockedLabelAfter(a1Lesson1.id),
        equals('A1: Daily Routine'),
      );

      // Complete A1 final lesson with score 85 -> returns A2 Lesson 1
      await db.roadmapDao.unlockNextLessonOrLevel(a1LastLesson.id, 85);
      expect(
        await repository.findNextUnlockedLabelAfter(a1LastLesson.id),
        equals('A2 Elementary: Talking About Yesterday'),
      );

      // Complete final C2 lesson -> null (no next level)
      await db.roadmapDao.unlockNextLessonOrLevel(c2LastLesson.id, 90);
      expect(
        await repository.findNextUnlockedLabelAfter(c2LastLesson.id),
        isNull,
      );
    },
  );

  test(
    'evaluateAndSaveSession does not auto-save vocabSuggestions until user selects',
    () async {
      Get.testMode = true;
      addTearDown(Get.reset);

      final fakeRepo = TutorRepository(
        database: db,
        restProvider: _FakeGeminiRestProvider(),
      );
      final started = DateTime(2026, 11, 13, 18, 0);

      final output = await fakeRepo.evaluateAndSaveSession(
        sessionType: 'free_talk',
        targetCefrLevel: 'B2',
        lessonTitle: 'Free Talk',
        scenarioPrompt: 'Discuss a meaningful project.',
        startedAt: started,
        endedAt: started.add(const Duration(seconds: 70)),
        durationSec: 70,
        transcript: <TranscriptTurnModel>[
          TranscriptTurnModel(
            role: 'user',
            text: 'I worked on an articulate presentation.',
            timestamp: started,
          ),
        ],
      );

      expect(output.insight.vocabSuggestions, hasLength(2));
      // Vocabulary table must stay empty until user explicitly saves items.
      expect(await fakeRepo.watchAllVocab().first, isEmpty);

      final savedId = await fakeRepo.saveSuggestedVocab(
        sessionId: output.sessionId,
        word: output.insight.vocabSuggestions.first.word,
        meaningId: output.insight.vocabSuggestions.first.meaningId,
        exampleSentence: output.insight.vocabSuggestions.first.exampleSentence,
        cefrLevel: output.insight.vocabSuggestions.first.cefrLevel,
      );
      final savedList = await fakeRepo.watchAllVocab().first;
      expect(savedList, hasLength(1));
      expect(savedList.first.id, equals(savedId));
      expect(savedList.first.sessionId, equals(output.sessionId));
      expect(savedList.first.word, equals('articulate'));

      await fakeRepo.deleteVocab(savedId);
      expect(await fakeRepo.watchAllVocab().first, isEmpty);

      // Verify controller toggleSaveVocab & saveAllSuggestedVocab.
      final controller = SessionResultController(repository: fakeRepo);
      controller.args = SessionResultArgs(
        practiceArgs: PracticeArgs(
          sessionType: 'free_talk',
          targetCefrLevel: 'B2',
          title: 'Free Talk',
          scenarioPrompt: 'Prompt',
          mode: 'live_roleplay',
          targetDurationSec: 90,
        ),
        transcript: const <TranscriptTurnModel>[],
        durationSec: 70,
      );
      await controller.evaluateSession();
      expect(controller.savedVocabIdsByWord, isEmpty);
      expect(await fakeRepo.watchAllVocab().first, isEmpty);

      await controller.toggleSaveVocab(output.insight.vocabSuggestions.first);
      expect(controller.isVocabSaved('articulate'), isTrue);
      expect(controller.isVocabSaved('resilient'), isFalse);

      await controller.saveAllSuggestedVocab();
      expect(controller.isVocabSaved('resilient'), isTrue);
      expect(await fakeRepo.watchAllVocab().first, hasLength(2));

      // Toggling saved item deletes it from Drift.
      await controller.toggleSaveVocab(output.insight.vocabSuggestions.first);
      expect(controller.isVocabSaved('articulate'), isFalse);
      expect(await fakeRepo.watchAllVocab().first, hasLength(1));
      controller.onClose();
    },
  );
}
