import 'dart:async';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../../../data/providers/gemini_rest_provider.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/tts_service.dart';
import '../models/flashcard_nav_args.dart';
import '../widgets/flashcard_dialogs.dart';

/// Level 3 controller managing interactive Flashcards, TTS pronunciation, and AI study content.
class FlashcardStudyController extends GetxController {
  FlashcardStudyController({
    required this.repository,
    required this.ttsService,
    AudioService? audioService,
    FlashcardStudyArgs? initialArgs,
  })  : _audioService = audioService,
        _initialArgs = initialArgs;

  final TutorRepository repository;
  final TtsService ttsService;
  final AudioService? _audioService;
  final FlashcardStudyArgs? _initialArgs;

  /// Resolves injected [AudioService] or falls back to GetX registry when available.
  AudioService? get resolvedAudioService {
    if (_audioService != null) return _audioService;
    if (Get.isRegistered<AudioService>()) {
      return Get.find<AudioService>();
    }
    return null;
  }

  late final FlashcardSubDeck? subDeck;
  late final String deckName;

  final RxList<Flashcard> cards = <Flashcard>[].obs;
  final RxInt activeIndex = 0.obs;
  final RxBool isStudyMode = true.obs;
  final RxBool isCardFlipped = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isGeneratingAi = false.obs;
  final RxBool isSavingDraft = false.obs;
  final RxnString errorMessage = RxnString();
  final RxnString aiErrorMessage = RxnString();

  final RxMap<int, FlashcardPracticeDraft> unsavedDrafts =
      <int, FlashcardPracticeDraft>{}.obs;
  final RxMap<int, bool> includeAll16TensesByCard = <int, bool>{}.obs;
  final RxMap<String, int> practicedSentenceScores = <String, int>{}.obs;

  StreamSubscription<List<Flashcard>>? _cardsSub;

  String get subDeckTitle => subDeck?.name ?? 'Flashcards';

  Flashcard? get activeCard {
    if (cards.isEmpty) return null;
    final idx = activeIndex.value.clamp(0, cards.length - 1);
    return cards[idx];
  }

  @override
  void onInit() {
    super.onInit();
    final rawArgs = Get.arguments;
    if (_initialArgs != null) {
      subDeck = _initialArgs.subDeck;
      deckName = _initialArgs.deckName;
    } else if (rawArgs is FlashcardStudyArgs) {
      subDeck = rawArgs.subDeck;
      deckName = rawArgs.deckName;
    } else if (rawArgs is FlashcardSubDeck) {
      subDeck = rawArgs;
      deckName = 'Flashcards';
    } else {
      subDeck = null;
      deckName = 'Flashcards';
    }

    if (subDeck == null) {
      errorMessage.value = 'Data Sub-Deck flashcard tidak ditemukan.';
      isLoading.value = false;
      return;
    }

    _subscribeCards();
  }

  void _subscribeCards() {
    final targetSubDeck = subDeck;
    if (targetSubDeck == null) return;

    _cardsSub?.cancel();
    isLoading.value = true;
    errorMessage.value = null;

    _cardsSub = repository.watchFlashcardsBySubDeck(targetSubDeck.id).listen(
      (items) {
        final previousCardId = activeCard?.id;
        cards.assignAll(items);
        if (items.isEmpty) {
          activeIndex.value = 0;
          isCardFlipped.value = false;
        } else if (previousCardId != null) {
          final preservedIdx = items.indexWhere((c) => c.id == previousCardId);
          if (preservedIdx >= 0) {
            activeIndex.value = preservedIdx;
          } else {
            activeIndex.value = activeIndex.value.clamp(0, items.length - 1);
            isCardFlipped.value = false;
          }
        } else {
          activeIndex.value = activeIndex.value.clamp(0, items.length - 1);
        }
        isLoading.value = false;
      },
      onError: (Object error) {
        errorMessage.value = 'Gagal memuat kartu flashcard: $error';
        isLoading.value = false;
      },
    );
  }

  /// Retries loading cards from Drift after an unexpected stream error.
  void retryLoad() => _subscribeCards();

  /// Switches between Study Mode (`true`) and List Mode (`false`).
  void setStudyMode(bool studyMode) {
    isStudyMode.value = studyMode;
  }

  /// Jumps directly to card at [index] and activates Study Mode.
  void selectCardAndStudy(int index) {
    if (cards.isEmpty) return;
    activeIndex.value = index.clamp(0, cards.length - 1);
    isCardFlipped.value = false;
    aiErrorMessage.value = null;
    isStudyMode.value = true;
  }

  /// Toggles front/back flip state on the active study card.
  void toggleFlip() {
    isCardFlipped.value = !isCardFlipped.value;
  }

  /// Advances to the next card in the Sub-Deck.
  void nextCard() {
    if (activeIndex.value < cards.length - 1) {
      activeIndex.value += 1;
      isCardFlipped.value = false;
      aiErrorMessage.value = null;
    }
  }

  /// Moves back to the previous card in the Sub-Deck.
  void previousCard() {
    if (activeIndex.value > 0) {
      activeIndex.value -= 1;
      isCardFlipped.value = false;
      aiErrorMessage.value = null;
    }
  }

  /// Adds (or deduplicates) a manual flashcard in the active Sub-Deck.
  Future<int?> addWord({
    required String word,
    String meaningId = '',
    String wordType = 'non_verb',
  }) async {
    final targetSubDeck = subDeck;
    final trimmed = word.trim();
    if (targetSubDeck == null || trimmed.isEmpty) return null;

    final cardId = await repository.createFlashcard(
      subDeckId: targetSubDeck.id,
      word: trimmed,
      meaningId: meaningId.trim(),
      wordType: wordType,
    );

    final updatedList = await repository.getCardsBySubDeck(targetSubDeck.id);
    cards.assignAll(updatedList);
    final idx = updatedList.indexWhere((c) => c.id == cardId);
    if (idx >= 0) {
      activeIndex.value = idx;
    }
    isCardFlipped.value = false;
    aiErrorMessage.value = null;

    showFlashcardSnackbar(
      title: 'Kata Ditambahkan',
      message: '"$trimmed" tersimpan di ${targetSubDeck.name}.',
    );
    return cardId;
  }

  /// Deletes [card] permanently from Drift and discards any unsaved local draft.
  Future<void> deleteWord(Flashcard card) async {
    await ttsService.stop();
    await repository.deleteFlashcard(card.id);
    unsavedDrafts.remove(card.id);
    includeAll16TensesByCard.remove(card.id);
    aiErrorMessage.value = null;
    isCardFlipped.value = false;

    showFlashcardSnackbar(
      title: 'Kata Dihapus',
      message: '"${card.word}" telah dihapus.',
    );
  }

  /// Returns any unsaved local AI draft for [cardId], or `null` if unchanged.
  FlashcardPracticeDraft? draftFor(int cardId) => unsavedDrafts[cardId];

  /// Whether [cardId] has local AI content waiting to be saved to Drift.
  bool hasUnsavedChanges(int cardId) => unsavedDrafts.containsKey(cardId);

  /// Whether full 16-tense mode is enabled for [cardId].
  bool includeAll16TensesFor(int cardId) =>
      includeAll16TensesByCard[cardId] ?? false;

  /// Toggles the 16-tenses preference for a verb card.
  void setIncludeAll16Tenses(int cardId, bool enabled) {
    includeAll16TensesByCard[cardId] = enabled;
  }

  /// Returns the highest pronunciation practice score achieved in this session for [sentence].
  int? bestScoreForSentence(String sentence) {
    final key = sentence.trim();
    if (key.isEmpty) return null;
    return practicedSentenceScores[key];
  }

  /// Stores [score] for [sentence] in this study session if it improves the best score.
  void recordSentencePracticeScore(String sentence, int score) {
    final key = sentence.trim();
    if (key.isEmpty) return;
    final clamped = score.clamp(0, 100);
    final previous = practicedSentenceScores[key];
    if (previous == null || clamped > previous) {
      practicedSentenceScores[key] = clamped;
      practicedSentenceScores.refresh();
    }
  }

  String effectiveWordType(Flashcard card) =>
      draftFor(card.id)?.wordType ?? card.wordType;

  String effectivePhonetic(Flashcard card) =>
      draftFor(card.id)?.phonetic ?? card.phonetic ?? '';

  String effectiveMeaningId(Flashcard card) =>
      draftFor(card.id)?.meaningId ?? card.meaningId;

  List<FlashcardExampleItem> effectiveExamples(Flashcard card) =>
      draftFor(card.id)?.examples ??
      FlashcardExampleItem.decodeExamples(card.examplesJson);

  String effectiveConversation(Flashcard card) =>
      draftFor(card.id)?.conversation ?? card.aiConversation;

  /// Speaks [text] via `TtsService` or stops playback if the exact same line is speaking.
  Future<void> toggleSpeak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (ttsService.isSpeaking.value &&
        ttsService.activeText.value == trimmed) {
      await ttsService.stop();
      return;
    }
    await ttsService.speak(trimmed);
  }

  /// Returns only the English dialog portion before `"Terjemahan:"` for natural TTS playback.
  String extractEnglishConversation(String rawConversation) {
    final trimmed = rawConversation.trim();
    if (trimmed.isEmpty) return '';
    final markerIdx = trimmed.indexOf(
      RegExp(r'\n\s*Terjemahan\s*:', caseSensitive: false),
    );
    if (markerIdx > 0) {
      return trimmed.substring(0, markerIdx).trim();
    }
    return trimmed;
  }

  /// Generates AI phonetic, meaning, example sentences, and mini dialog into a local draft.
  Future<void> generateAiContent(
    Flashcard card, {
    bool avoidCurrentExamples = false,
  }) async {
    if (isGeneratingAi.value) return;

    final currentExamples = effectiveExamples(card);
    final avoidList = avoidCurrentExamples
        ? currentExamples
            .map((e) => e.en.trim())
            .where((s) => s.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    isGeneratingAi.value = true;
    aiErrorMessage.value = null;

    try {
      final result = await repository.generateFlashcardPracticeContent(
        word: card.word,
        currentMeaningId: effectiveMeaningId(card),
        wordTypeHint: effectiveWordType(card),
        includeAll16Tenses: includeAll16TensesFor(card.id),
        avoidSentences: avoidList,
      );

      unsavedDrafts[card.id] = FlashcardPracticeDraft(
        wordType: result.wordType,
        phonetic: result.phonetic,
        meaningId: result.meaningId,
        examples: result.examples,
        conversation: result.conversation,
      );
      unsavedDrafts.refresh();
    } on GeminiApiException catch (error) {
      aiErrorMessage.value = error.message;
      showFlashcardSnackbar(
        title: 'AI Tidak Dapat Memproses',
        message: error.message,
        isError: true,
      );
    } catch (error) {
      final msg = 'Gagal membuat latihan kalimat dengan AI: $error';
      aiErrorMessage.value = msg;
      showFlashcardSnackbar(
        title: 'Terjadi Kesalahan',
        message: msg,
        isError: true,
      );
    } finally {
      isGeneratingAi.value = false;
    }
  }

  /// Regenerates fresh sentences and conversation while avoiding currently displayed lines.
  Future<void> replaceExamples(Flashcard card) async {
    await generateAiContent(card, avoidCurrentExamples: true);
  }

  /// Persists the local AI draft for [card] to Drift and clears its unsaved marker.
  Future<void> saveDraftToDatabase(Flashcard card) async {
    final draft = unsavedDrafts[card.id];
    if (draft == null || isSavingDraft.value) return;

    isSavingDraft.value = true;
    try {
      await repository.updateFlashcardPracticeContent(
        cardId: card.id,
        phonetic: draft.phonetic,
        meaningId: draft.meaningId,
        wordType: draft.wordType,
        examples: draft.examples,
        aiConversation: draft.conversation,
      );
      unsavedDrafts.remove(card.id);
      unsavedDrafts.refresh();
      showFlashcardSnackbar(
        title: 'Tersimpan',
        message: 'Konten latihan untuk "${card.word}" berhasil disimpan.',
      );
    } finally {
      isSavingDraft.value = false;
    }
  }

  @override
  void onClose() {
    _cardsSub?.cancel();
    unawaited(ttsService.stop());
    super.onClose();
  }
}
