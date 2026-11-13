import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../../../data/providers/gemini_rest_provider.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/tts_service.dart';
import '../models/flashcard_nav_args.dart';

typedef QuizAnswerEntry = ({
  FlashcardQuizQuestion question,
  int selectedIndex,
  bool isCorrect,
});

/// Controller for interactive Flashcard AI & local-fallback multiple-choice quizzes.
class FlashcardQuizController extends GetxController {
  FlashcardQuizController({
    required this.repository,
    required this.ttsService,
    FlashcardQuizArgs? initialArgs,
    Random? random,
  })  : _initialArgs = initialArgs,
        _random = random ?? Random();

  final TutorRepository repository;
  final TtsService ttsService;
  final FlashcardQuizArgs? _initialArgs;
  final Random _random;

  late final FlashcardQuizArgs? args;

  final RxBool isLoading = true.obs;
  final RxBool isFallbackOfflineMode = false.obs;
  final RxString infoBanner = ''.obs;
  final RxString errorMessage = ''.obs;

  final RxList<FlashcardQuizQuestion> questions =
      <FlashcardQuizQuestion>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxnInt selectedOptionIndex = RxnInt();
  final RxBool isCurrentAnswered = false.obs;
  final RxInt correctCount = 0.obs;
  final RxBool isCompleted = false.obs;
  final RxList<QuizAnswerEntry> answerHistory = <QuizAnswerEntry>[].obs;

  static const List<String> _fallbackEnglishDistractors = <String>[
    'collaborate',
    'negotiate',
    'clarify',
    'resilient',
    'implement',
    'evaluate',
    'articulate',
    'delegate',
  ];

  static const List<String> _fallbackMeaningDistractors = <String>[
    'menunda keputusan',
    'memperjelas instruksi',
    'bekerja secara terpisah',
    'mengevaluasi hasil',
    'menyampaikan gagasan',
    'mengabaikan rincian',
    'mempersingkat jadwal',
    'menghindari risiko',
  ];

  @override
  void onInit() {
    super.onInit();
    final rawArgs = Get.arguments;
    if (_initialArgs != null) {
      args = _initialArgs;
    } else if (rawArgs is FlashcardQuizArgs) {
      args = rawArgs;
    } else {
      args = null;
    }

    unawaited(loadQuiz());
  }

  String get scopeTitle => args?.scopeTitle ?? 'Flashcard Quiz';

  String get scopeSubtitle => args?.scopeSubtitle ?? 'Latihan Kosakata';

  int get totalSourceCards => args?.cards.length ?? 0;

  FlashcardQuizQuestion? get currentQuestion {
    final idx = currentIndex.value;
    if (idx < 0 || idx >= questions.length) return null;
    return questions[idx];
  }

  bool get isLastQuestion =>
      questions.isNotEmpty && currentIndex.value >= questions.length - 1;

  double get accuracyPercent {
    if (questions.isEmpty) return 0;
    return (correctCount.value / questions.length) * 100;
  }

  String get motivationMessage {
    final pct = accuracyPercent;
    if (pct >= 85) {
      return 'Luar biasa! Penguasaan kosakatamu sudah sangat mantap.';
    }
    if (pct >= 65) {
      return 'Bagus sekali! Sedikit latihan lagi untuk mengingat semuanya dengan mulus.';
    }
    return 'Tetap semangat! Review kembali kata yang masih keliru agar cepat melekat.';
  }

  /// Fetches Gemini-generated quiz questions or seamlessly builds a local fallback quiz.
  Future<void> loadQuiz() async {
    final quizArgs = args;
    if (quizArgs == null || quizArgs.cards.isEmpty) {
      errorMessage.value = 'Belum ada kartu flashcard yang bisa diuji.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    isFallbackOfflineMode.value = false;
    infoBanner.value = '';
    errorMessage.value = '';
    currentIndex.value = 0;
    selectedOptionIndex.value = null;
    isCurrentAnswered.value = false;
    correctCount.value = 0;
    isCompleted.value = false;
    answerHistory.clear();
    questions.clear();

    try {
      final maxQuestions = quizArgs.cards.length.clamp(1, 20);
      final generated = await repository.generateFlashcardQuiz(
        cards: quizArgs.cards,
        scopeTitle: quizArgs.scopeTitle,
        maxQuestions: maxQuestions,
      );

      if (generated.isEmpty) {
        _activateLocalFallback(quizArgs.cards, 'soal AI kosong');
      } else {
        questions.assignAll(generated);
      }
    } on GeminiApiException catch (error) {
      _activateLocalFallback(
        quizArgs.cards,
        _shortenFailureReason(error.message),
      );
    } catch (_) {
      _activateLocalFallback(quizArgs.cards, 'koneksi bermasalah');
    } finally {
      isLoading.value = false;
    }
  }

  void _activateLocalFallback(List<Flashcard> cards, String reason) {
    isFallbackOfflineMode.value = true;
    infoBanner.value =
        'Mode Kuis Lokal: dibuat otomatis dari data kartu karena AI sedang tidak tersedia ($reason).';
    questions.assignAll(_buildLocalFallbackQuiz(cards));
  }

  String _shortenFailureReason(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('api key')) return 'API key belum diisi / tidak valid';
    if (lower.contains('429') || lower.contains('kuota')) {
      return 'kuota API habis';
    }
    if (lower.contains('timeout') || lower.contains('internet')) {
      return 'koneksi offline';
    }
    return raw.length > 55 ? '${raw.substring(0, 52)}...' : raw;
  }

  List<FlashcardQuizQuestion> _buildLocalFallbackQuiz(List<Flashcard> source) {
    final prioritized = List<Flashcard>.from(source)
      ..sort((a, b) {
        final masteryCmp = a.masteryLevel.compareTo(b.masteryLevel);
        if (masteryCmp != 0) return masteryCmp;
        final reviewCmp = a.reviewCount.compareTo(b.reviewCount);
        if (reviewCmp != 0) return reviewCmp;
        return a.id.compareTo(b.id);
      });

    final selected = prioritized
        .take(prioritized.length.clamp(1, 20))
        .toList(growable: false);

    final allWords = source
        .map((c) => c.word.trim())
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    final allMeanings = source
        .map((c) => c.meaningId.trim())
        .where((m) => m.isNotEmpty)
        .toList(growable: false);

    return selected.map((card) {
      final word = card.word.trim();
      final meaning = card.meaningId.trim();
      final maskedSentence = _findMaskedExample(card);

      if (maskedSentence != null) {
        final options = _buildFourOptions(
          correctAnswer: word,
          cardPool: allWords,
          fallbackPool: _fallbackEnglishDistractors,
        );
        return FlashcardQuizQuestion(
          cardId: card.id,
          word: card.word,
          questionPrompt:
              'Complete the sentence with the right word:\n"$maskedSentence"',
          options: options,
          correctIndex: options.indexOf(word),
          explanationId:
              "Jawaban yang tepat adalah '$word'${meaning.isNotEmpty ? ' ($meaning)' : ''} sesuai konteks kalimat.",
        );
      }

      if (meaning.isNotEmpty) {
        final options = _buildFourOptions(
          correctAnswer: meaning,
          cardPool: allMeanings,
          fallbackPool: _fallbackMeaningDistractors,
        );
        return FlashcardQuizQuestion(
          cardId: card.id,
          word: card.word,
          questionPrompt: 'What is the Indonesian meaning of "$word"?',
          options: options,
          correctIndex: options.indexOf(meaning),
          explanationId: "'$word' berarti '$meaning'.",
        );
      }

      final options = _buildFourOptions(
        correctAnswer: word,
        cardPool: allWords,
        fallbackPool: _fallbackEnglishDistractors,
      );
      return FlashcardQuizQuestion(
        cardId: card.id,
        word: card.word,
        questionPrompt:
            'Listen via the speaker button and select the matching English word:',
        options: options,
        correctIndex: options.indexOf(word),
        explanationId: "Kata target pada kartu ini adalah '$word'.",
      );
    }).toList(growable: false);
  }

  String? _findMaskedExample(Flashcard card) {
    final word = card.word.trim();
    if (word.isEmpty) return null;

    final examples = FlashcardExampleItem.decodeExamples(card.examplesJson);
    final exactPattern = RegExp(
      '\\b${RegExp.escape(word)}\\b',
      caseSensitive: false,
    );
    final loosePattern = RegExp(RegExp.escape(word), caseSensitive: false);

    for (final item in examples) {
      final sentence = item.en.trim();
      if (sentence.isEmpty) continue;
      if (exactPattern.hasMatch(sentence)) {
        return sentence.replaceFirst(exactPattern, '____');
      }
      if (loosePattern.hasMatch(sentence)) {
        return sentence.replaceFirst(loosePattern, '____');
      }
    }
    return null;
  }

  List<String> _buildFourOptions({
    required String correctAnswer,
    required List<String> cardPool,
    required List<String> fallbackPool,
  }) {
    final seen = <String>{correctAnswer.toLowerCase()};
    final distractors = <String>[];

    void addCandidates(List<String> source) {
      final shuffled = List<String>.from(source)..shuffle(_random);
      for (final raw in shuffled) {
        final clean = raw.trim();
        if (clean.isEmpty) continue;
        if (seen.add(clean.toLowerCase())) {
          distractors.add(clean);
          if (distractors.length == 3) return;
        }
      }
    }

    addCandidates(cardPool);
    if (distractors.length < 3) {
      addCandidates(fallbackPool);
    }

    var syntheticIdx = 1;
    while (distractors.length < 3) {
      final candidate = 'Option ${syntheticIdx++}';
      if (seen.add(candidate.toLowerCase())) {
        distractors.add(candidate);
      }
    }

    final options = <String>[correctAnswer, ...distractors]..shuffle(_random);
    return List<String>.unmodifiable(options);
  }

  /// Records the user's selected answer and persists card mastery review in Drift.
  Future<void> selectOption(int optionIndex) async {
    if (isCurrentAnswered.value || isCompleted.value) return;
    final question = currentQuestion;
    if (question == null ||
        optionIndex < 0 ||
        optionIndex >= question.options.length) {
      return;
    }

    selectedOptionIndex.value = optionIndex;
    isCurrentAnswered.value = true;

    final isCorrect = optionIndex == question.correctIndex;
    if (isCorrect) {
      correctCount.value += 1;
    }

    answerHistory.add((
      question: question,
      selectedIndex: optionIndex,
      isCorrect: isCorrect,
    ));

    try {
      await repository.recordCardReview(
        cardId: question.cardId,
        isCorrect: isCorrect,
      );
    } catch (_) {
      // Keep interactive quiz UI flowing even if review persistence fails.
    }
  }

  /// Advances to the next question or transitions to the final summary screen.
  void nextQuestion() {
    if (!isCurrentAnswered.value) return;
    unawaited(ttsService.stop());

    if (currentIndex.value + 1 < questions.length) {
      currentIndex.value += 1;
      selectedOptionIndex.value = null;
      isCurrentAnswered.value = false;
    } else {
      isCompleted.value = true;
    }
  }

  /// Speaks the target word of the active quiz question via `TtsService`.
  Future<void> speakWord() async {
    final word = currentQuestion?.word ?? '';
    await speakText(word);
  }

  /// Speaks [text] aloud or stops playback if the exact same text is active.
  Future<void> speakText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (ttsService.isSpeaking.value &&
        ttsService.activeText.value == trimmed) {
      await ttsService.stop();
      return;
    }
    await ttsService.speak(trimmed);
  }

  /// Restarts the quiz session and generates a fresh set of questions.
  Future<void> retakeQuiz() async {
    await ttsService.stop();
    await loadQuiz();
  }

  @override
  void onClose() {
    unawaited(ttsService.stop());
    super.onClose();
  }
}
