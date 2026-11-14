import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../../../data/providers/gemini_rest_provider.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/services/tts_service.dart';
import '../../../routes/app_pages.dart';
import '../models/flashcard_nav_args.dart';
import '../widgets/flashcard_dialogs.dart';
import '../widgets/flashcard_freetalk_sheet.dart';

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
  final RxString selectedPosFilter = 'Semua'.obs;
  final RxString selectedStudyStatusFilter = 'Semua'.obs;
  final RxnString errorMessage = RxnString();
  final RxnString aiErrorMessage = RxnString();

  static const List<String> posFilterOptions = <String>[
    'Semua',
    'Verb',
    'Noun',
    'Adjective',
    'Adverb',
    'Multi-POS',
    'Lainnya',
  ];

  static const List<String> studyStatusFilterOptions = <String>[
    'Semua',
    'Belum',
    'Perlu Ulang',
    'Hafal',
  ];

  final RxMap<int, FlashcardPracticeDraft> unsavedDrafts =
      <int, FlashcardPracticeDraft>{}.obs;
  final RxMap<int, bool> includeAll16TensesByCard = <int, bool>{}.obs;
  final RxMap<int, int> activeExampleTabByCard = <int, int>{}.obs;
  final RxMap<String, int> practicedSentenceScores = <String, int>{}.obs;

  final Map<int, List<FlashcardExampleItem>> _pureVerbShortExamplesCache =
      <int, List<FlashcardExampleItem>>{};
  final Map<int, List<FlashcardExampleItem>> _pureVerb16ExamplesCache =
      <int, List<FlashcardExampleItem>>{};

  StreamSubscription<List<Flashcard>>? _cardsSub;

  String get subDeckTitle => subDeck?.name ?? 'Flashcards';

  int get masteredCount =>
      cards.where((c) => c.studyStatus == FlashcardStudyStatus.mastered).length;

  int get needsReviewCount => cards
      .where((c) => c.studyStatus == FlashcardStudyStatus.needsReview)
      .length;

  int get unstudiedCount => cards
      .where((c) => c.studyStatus == FlashcardStudyStatus.unstudied)
      .length;

  int get progressPercent => cards.isEmpty
      ? 0
      : ((masteredCount / cards.length) * 100).round().clamp(0, 100);

  bool get hasActiveFilters =>
      selectedPosFilter.value != 'Semua' ||
      selectedStudyStatusFilter.value != 'Semua';

  Flashcard? get activeCard {
    final list = filteredCards;
    if (list.isEmpty) return null;
    final idx = activeIndex.value.clamp(0, list.length - 1);
    return list[idx];
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
        _syncActiveIndexToFiltered(preferredCardId: previousCardId);
        isLoading.value = false;
      },
      onError: (Object error) {
        errorMessage.value = 'Gagal memuat kartu flashcard: $error';
        isLoading.value = false;
      },
    );
  }

  void _syncActiveIndexToFiltered({int? preferredCardId}) {
    final visible = filteredCards;
    if (visible.isEmpty) {
      activeIndex.value = 0;
      isCardFlipped.value = false;
      return;
    }
    if (preferredCardId != null) {
      final preservedIdx = visible.indexWhere((c) => c.id == preferredCardId);
      if (preservedIdx >= 0) {
        activeIndex.value = preservedIdx;
        return;
      }
    }
    activeIndex.value = activeIndex.value.clamp(0, visible.length - 1);
    isCardFlipped.value = false;
  }

  /// Retries loading cards from Drift after an unexpected stream error.
  void retryLoad() => _subscribeCards();

  /// Switches between Study Mode (`true`) and List Mode (`false`).
  void setStudyMode(bool studyMode) {
    isStudyMode.value = studyMode;
  }

  /// Updates the active Part-of-Speech filter chip consistently for Study and List modes.
  void setPosFilter(String filter) {
    final previousCardId = activeCard?.id;
    selectedPosFilter.value = filter;
    _syncActiveIndexToFiltered(preferredCardId: previousCardId);
  }

  /// Updates the active study status filter chip (`Semua`, `Belum`, `Perlu Ulang`, `Hafal`).
  void setStudyStatusFilter(String filter) {
    final previousCardId = activeCard?.id;
    selectedStudyStatusFilter.value = filter;
    _syncActiveIndexToFiltered(preferredCardId: previousCardId);
  }

  /// Resets both POS and study status filters back to `'Semua'`.
  void resetFilters() {
    final previousCardId = activeCard?.id;
    selectedPosFilter.value = 'Semua';
    selectedStudyStatusFilter.value = 'Semua';
    _syncActiveIndexToFiltered(preferredCardId: previousCardId);
  }

  /// Returns cards matching both [selectedPosFilter] and [selectedStudyStatusFilter].
  List<Flashcard> get filteredCards {
    final posFilter = selectedPosFilter.value;
    final statusFilter = selectedStudyStatusFilter.value;
    if (posFilter == 'Semua' && statusFilter == 'Semua') {
      return cards.toList(growable: false);
    }
    return cards
        .where(
          (card) =>
              matchesPosFilter(card, posFilter) &&
              matchesStudyStatusFilter(card, statusFilter),
        )
        .toList(growable: false);
  }

  /// Checks whether [card] matches the given study status [filter].
  bool matchesStudyStatusFilter(Flashcard card, String filter) {
    switch (filter) {
      case 'Semua':
        return true;
      case 'Belum':
        return card.studyStatus == FlashcardStudyStatus.unstudied;
      case 'Perlu Ulang':
        return card.studyStatus == FlashcardStudyStatus.needsReview;
      case 'Hafal':
        return card.studyStatus == FlashcardStudyStatus.mastered;
      default:
        return true;
    }
  }

  /// Checks whether [card] matches the given List Mode POS [filter].
  bool matchesPosFilter(Flashcard card, String filter) {
    final posList = effectivePartsOfSpeech(card);
    switch (filter) {
      case 'Semua':
        return true;
      case 'Verb':
        return FlashcardPosHelper.hasVerbPos(posList);
      case 'Noun':
        return posList.any((p) => p == 'Noun');
      case 'Adjective':
        return posList.any((p) => p == 'Adjective');
      case 'Adverb':
        return posList.any((p) => p == 'Adverb');
      case 'Multi-POS':
        return posList.length > 1;
      case 'Lainnya':
        if (posList.isEmpty) return true;
        return posList.any(
          (p) =>
              !FlashcardPosHelper.isVerbPos(p) &&
              p != 'Noun' &&
              p != 'Adjective' &&
              p != 'Adverb',
        );
      default:
        return true;
    }
  }

  /// Jumps directly to card at [index] within [filteredCards] and activates Study Mode.
  void selectCardAndStudy(int index) {
    final visible = filteredCards;
    if (visible.isEmpty) return;
    activeIndex.value = index.clamp(0, visible.length - 1);
    isCardFlipped.value = false;
    aiErrorMessage.value = null;
    isStudyMode.value = true;
  }

  /// Finds [cardId] in [filteredCards] (or resets filters if needed) and activates Study Mode.
  void selectCardByIdAndStudy(int cardId) {
    final visibleIdx = filteredCards.indexWhere((c) => c.id == cardId);
    if (visibleIdx >= 0) {
      selectCardAndStudy(visibleIdx);
      return;
    }
    final allIdx = cards.indexWhere((c) => c.id == cardId);
    if (allIdx < 0) return;
    selectedPosFilter.value = 'Semua';
    selectedStudyStatusFilter.value = 'Semua';
    selectCardAndStudy(allIdx);
  }

  /// Toggles front/back flip state on the active study card.
  void toggleFlip() {
    isCardFlipped.value = !isCardFlipped.value;
  }

  /// Advances to the next card in [filteredCards].
  void nextCard() {
    final visible = filteredCards;
    if (visible.isEmpty) return;
    final safeIdx = activeIndex.value.clamp(0, visible.length - 1);
    if (safeIdx < visible.length - 1) {
      activeIndex.value = safeIdx + 1;
      isCardFlipped.value = false;
      aiErrorMessage.value = null;
    }
  }

  /// Moves back to the previous card in [filteredCards].
  void previousCard() {
    final visible = filteredCards;
    if (visible.isEmpty) return;
    final safeIdx = activeIndex.value.clamp(0, visible.length - 1);
    if (safeIdx > 0) {
      activeIndex.value = safeIdx - 1;
      isCardFlipped.value = false;
      aiErrorMessage.value = null;
    }
  }

  /// Updates [card]'s 3-state study status (`0` Belum, `1` Perlu Ulang, `2` Hafal).
  Future<void> setCardStudyStatus(Flashcard card, int studyStatus) async {
    final normalized = FlashcardStudyStatus.clamp(studyStatus);
    final previousActiveId = activeCard?.id;

    await repository.updateCardStudyStatus(
      cardId: card.id,
      studyStatus: normalized,
    );

    final idx = cards.indexWhere((c) => c.id == card.id);
    if (idx >= 0) {
      cards[idx] = cards[idx].copyWith(studyStatus: normalized);
      cards.refresh();
    }
    _syncActiveIndexToFiltered(preferredCardId: previousActiveId);
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
    if (filteredCards.indexWhere((c) => c.id == cardId) < 0) {
      selectedPosFilter.value = 'Semua';
      selectedStudyStatusFilter.value = 'Semua';
    }
    final idx = filteredCards.indexWhere((c) => c.id == cardId);
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

  /// Updates core fields of an existing [card] in Drift and syncs any unsaved draft.
  Future<bool> editWord(
    Flashcard card, {
    required String word,
    String phonetic = '',
    String meaningId = '',
    List<String> partsOfSpeech = const <String>[],
  }) async {
    final trimmedWord = word.trim();
    if (trimmedWord.isEmpty) {
      showFlashcardSnackbar(
        title: 'Input Tidak Valid',
        message: 'Kata bahasa Inggris wajib diisi.',
        isError: true,
      );
      return false;
    }

    final trimmedPhonetic = phonetic.trim();
    final trimmedMeaning = meaningId.trim();
    final normalizedPos = FlashcardPosHelper.normalizePartsOfSpeech(
      partsOfSpeech,
    );
    final resolvedWordType = FlashcardPosHelper.deriveWordType(normalizedPos);
    final wordChanged = trimmedWord != card.word.trim();

    try {
      await repository.updateFlashcardPracticeContent(
        cardId: card.id,
        word: trimmedWord,
        phonetic: trimmedPhonetic,
        meaningId: trimmedMeaning,
        partsOfSpeech: normalizedPos,
      );
    } on StateError catch (error) {
      showFlashcardSnackbar(
        title: 'Kata Sudah Ada',
        message: error.message,
        isError: true,
      );
      return false;
    } on ArgumentError catch (error) {
      showFlashcardSnackbar(
        title: 'Input Tidak Valid',
        message: '${error.message ?? error}',
        isError: true,
      );
      return false;
    } catch (error) {
      showFlashcardSnackbar(
        title: 'Gagal Memperbarui Kartu',
        message: 'Tidak dapat menyimpan perubahan: $error',
        isError: true,
      );
      return false;
    }

    if (wordChanged) {
      _pureVerbShortExamplesCache.remove(card.id);
      _pureVerb16ExamplesCache.remove(card.id);
      aiErrorMessage.value = null;
    }

    final existingDraft = unsavedDrafts[card.id];
    if (existingDraft != null) {
      _storeDraft(
        card.id,
        existingDraft.copyWith(
          wordType: resolvedWordType,
          partsOfSpeech: normalizedPos,
          phonetic: trimmedPhonetic,
          meaningId: trimmedMeaning,
        ),
      );
    }

    final updatedCard = card.copyWith(
      word: trimmedWord,
      phonetic: drift.Value(trimmedPhonetic.isEmpty ? null : trimmedPhonetic),
      meaningId: trimmedMeaning,
      wordType: resolvedWordType,
      partsOfSpeechJson: FlashcardPosHelper.encodePartsOfSpeech(normalizedPos),
    );

    final previousActiveId = activeCard?.id;
    final idx = cards.indexWhere((c) => c.id == card.id);
    if (idx >= 0) {
      cards[idx] = updatedCard;
      cards.refresh();
    }
    if (previousActiveId != null) {
      _syncActiveIndexToFiltered(preferredCardId: previousActiveId);
    } else {
      _syncActiveIndexToFiltered();
    }

    if (!hasVerbFor(updatedCard)) {
      includeAll16TensesByCard[card.id] = false;
      activeExampleTabByCard[card.id] = 0;
    }

    showFlashcardSnackbar(
      title: 'Perubahan Disimpan',
      message: '"$trimmedWord" berhasil diperbarui.',
    );
    return true;
  }

  /// Deletes [card] permanently from Drift and discards any unsaved local draft.
  Future<void> deleteWord(Flashcard card) async {
    await ttsService.stop();
    await repository.deleteFlashcard(card.id);
    unsavedDrafts.remove(card.id);
    includeAll16TensesByCard.remove(card.id);
    activeExampleTabByCard.remove(card.id);
    _pureVerbShortExamplesCache.remove(card.id);
    _pureVerb16ExamplesCache.remove(card.id);
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

  /// Whether full 16-tense mode was explicitly toggled ON for [cardId].
  bool includeAll16TensesFor(int cardId) =>
      includeAll16TensesByCard[cardId] ?? false;

  /// Effective Parts of Speech (Title Case, unlimited combinations) for [card].
  List<String> effectivePartsOfSpeech(Flashcard card) {
    final draft = draftFor(card.id);
    if (draft != null) {
      if (draft.partsOfSpeech.isNotEmpty) {
        return draft.partsOfSpeech;
      }
      return draft.wordType == 'verb'
          ? const <String>['Verb']
          : const <String>[];
    }
    final decoded = FlashcardPosHelper.decodePartsOfSpeech(
      card.partsOfSpeechJson,
    );
    if (decoded.isNotEmpty) return decoded;
    return card.wordType == 'verb'
        ? const <String>['Verb']
        : const <String>[];
  }

  /// Whether [card] includes `'Verb'` or `'Phrasal Verb'`.
  bool hasVerbFor(Flashcard card) =>
      FlashcardPosHelper.hasVerbPos(effectivePartsOfSpeech(card));

  /// Non-verb POS labels for [card].
  List<String> nonVerbPartsFor(Flashcard card) =>
      FlashcardPosHelper.nonVerbPosList(effectivePartsOfSpeech(card));

  /// Whether [card] is a hybrid multi-POS word combining Verb + non-verb POS.
  bool isHybridVerbCard(Flashcard card) =>
      FlashcardPosHelper.isHybridWithVerb(effectivePartsOfSpeech(card));

  /// Whether [card] only functions as Verb / Phrasal Verb without non-verb POS.
  bool isPureVerbCard(Flashcard card) =>
      hasVerbFor(card) && nonVerbPartsFor(card).isEmpty;

  /// Active example section tab index for hybrid cards (`0` = Non-Verb, `1` = 16 Tenses Verb).
  int activeExampleTabFor(int cardId) => activeExampleTabByCard[cardId] ?? 0;

  /// Switches the active example tab on hybrid cards without discarding data.
  void setActiveExampleTab(int cardId, int tabIndex) {
    activeExampleTabByCard[cardId] = tabIndex == 1 ? 1 : 0;
  }

  /// Effective 16-tenses activation state for [card], respecting explicit toggle and stored data.
  bool isVerb16TensesEnabled(Flashcard card) {
    final explicit = includeAll16TensesByCard[card.id];
    if (explicit != null) return explicit;
    if (isHybridVerbCard(card)) {
      return effectiveVerb16TensesExamples(card).isNotEmpty;
    }
    if (isPureVerbCard(card)) {
      return effectiveExamples(card).length >= 16;
    }
    return false;
  }

  /// Updates the raw boolean state for the 16-tenses switch.
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

  List<FlashcardExampleItem> effectiveNonVerbExamples(Flashcard card) =>
      effectiveExamples(card);

  List<FlashcardExampleItem> effectiveVerb16TensesExamples(Flashcard card) =>
      draftFor(card.id)?.verbTensesExamples ??
      FlashcardExampleItem.decodeExamples(card.verbTensesExamplesJson);

  String effectiveConversation(Flashcard card) =>
      draftFor(card.id)?.conversation ?? card.aiConversation;

  bool hasAnyContent(Flashcard card) =>
      effectiveExamples(card).isNotEmpty ||
      effectiveVerb16TensesExamples(card).isNotEmpty ||
      effectiveConversation(card).trim().isNotEmpty;

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

  FlashcardPracticeDraft _baselineDraft(Flashcard card) {
    final existing = draftFor(card.id);
    if (existing != null) return existing;
    return FlashcardPracticeDraft(
      wordType: card.wordType,
      partsOfSpeech: effectivePartsOfSpeech(card),
      phonetic: effectivePhonetic(card),
      meaningId: effectiveMeaningId(card),
      examples: effectiveExamples(card),
      verbTensesExamples: effectiveVerb16TensesExamples(card),
      conversation: effectiveConversation(card),
    );
  }

  void _storeDraft(int cardId, FlashcardPracticeDraft draft) {
    unsavedDrafts[cardId] = draft;
    unsavedDrafts.refresh();
  }

  Future<void> _runAiGeneration(Future<void> Function() task) async {
    if (isGeneratingAi.value) return;

    isGeneratingAi.value = true;
    aiErrorMessage.value = null;
    try {
      await task();
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

  /// Generates AI phonetic, POS, meaning, examples, and mini dialog into a local draft.
  Future<void> generateAiContent(
    Flashcard card, {
    bool avoidCurrentExamples = false,
  }) async {
    if (avoidCurrentExamples) {
      await replaceExamples(card);
      return;
    }

    await _runAiGeneration(() async {
      final knownPos = effectivePartsOfSpeech(card);
      final isKnownPureVerb =
          FlashcardPosHelper.hasVerbPos(knownPos) &&
          FlashcardPosHelper.nonVerbPosList(knownPos).isEmpty;
      final request16Tenses = isKnownPureVerb && isVerb16TensesEnabled(card);

      final result = await repository.generateFlashcardPracticeContent(
        word: card.word,
        currentMeaningId: effectiveMeaningId(card),
        knownPartsOfSpeech: knownPos,
        mode: request16Tenses
            ? FlashcardExampleGenerationMode.verb16TensesOnly
            : FlashcardExampleGenerationMode.standard,
        includeAll16Tenses: request16Tenses,
      );

      final detectedPos = result.partsOfSpeech.isNotEmpty
          ? result.partsOfSpeech
          : (result.wordType == 'verb'
                ? const <String>['Verb']
                : const <String>[]);
      final isHybrid = FlashcardPosHelper.isHybridWithVerb(detectedPos);
      final hasVerb = FlashcardPosHelper.hasVerbPos(detectedPos);

      if (!hasVerb) {
        includeAll16TensesByCard[card.id] = false;
        activeExampleTabByCard[card.id] = 0;
      }

      var verbExamples = isHybrid
          ? effectiveVerb16TensesExamples(card)
          : const <FlashcardExampleItem>[];

      if (isHybrid &&
          includeAll16TensesFor(card.id) &&
          verbExamples.isEmpty) {
        final verbResult = await repository.generateFlashcardPracticeContent(
          word: card.word,
          currentMeaningId: result.meaningId,
          knownPartsOfSpeech: detectedPos,
          mode: FlashcardExampleGenerationMode.verb16TensesOnly,
          includeAll16Tenses: true,
        );
        verbExamples = verbResult.examples;
      }

      if (!isHybrid && hasVerb) {
        if (result.examples.length >= 16) {
          _pureVerb16ExamplesCache[card.id] = result.examples;
          _pureVerbShortExamplesCache.remove(card.id);
        } else {
          _pureVerbShortExamplesCache[card.id] = result.examples;
          _pureVerb16ExamplesCache.remove(card.id);
        }
      } else {
        _pureVerbShortExamplesCache.remove(card.id);
        _pureVerb16ExamplesCache.remove(card.id);
      }

      _storeDraft(
        card.id,
        FlashcardPracticeDraft(
          wordType: FlashcardPosHelper.deriveWordType(
            detectedPos,
            fallback: result.wordType,
          ),
          partsOfSpeech: detectedPos,
          phonetic: result.phonetic,
          meaningId: result.meaningId,
          examples: result.examples,
          verbTensesExamples: verbExamples,
          conversation: result.conversation,
        ),
      );
    });
  }

  /// Toggles 16-Tenses (Verb) mode for either Pure Verb or Hybrid cards without overwriting Tab 1.
  Future<void> setVerb16TensesEnabled(Flashcard card, bool enabled) async {
    includeAll16TensesByCard[card.id] = enabled;

    if (!hasVerbFor(card)) return;

    final currentDraft = _baselineDraft(card);
    if (isHybridVerbCard(card)) {
      if (!enabled) return;

      final existingVerb16 = effectiveVerb16TensesExamples(card);
      if (existingVerb16.length >= 16) {
        // Restore previously generated or persisted 16 Verb sentences without wiping Tab 1.
        _storeDraft(card.id, currentDraft);
        return;
      }

      await _runAiGeneration(() async {
        final knownPos = effectivePartsOfSpeech(card);
        final result = await repository.generateFlashcardPracticeContent(
          word: card.word,
          currentMeaningId: effectiveMeaningId(card),
          wordTypeHint: 'verb',
          knownPartsOfSpeech: knownPos,
          mode: FlashcardExampleGenerationMode.verb16TensesOnly,
          includeAll16Tenses: true,
        );

        _storeDraft(
          card.id,
          currentDraft.copyWith(
            wordType: 'verb',
            partsOfSpeech: knownPos,
            phonetic: currentDraft.phonetic.isNotEmpty
                ? currentDraft.phonetic
                : result.phonetic,
            meaningId: currentDraft.meaningId.isNotEmpty
                ? currentDraft.meaningId
                : result.meaningId,
            verbTensesExamples: result.examples,
            conversation: currentDraft.conversation.isNotEmpty
                ? currentDraft.conversation
                : result.conversation,
          ),
        );
      });
      return;
    }

    // Pure Verb mode: switch between 5 contextual Verb sentences and full 16 Tenses in `examples`.
    if (!enabled) {
      if (currentDraft.examples.length >= 16) {
        _pureVerb16ExamplesCache[card.id] = currentDraft.examples;
      }
      final cachedShort = _pureVerbShortExamplesCache[card.id];
      if (cachedShort != null && cachedShort.isNotEmpty) {
        _storeDraft(card.id, currentDraft.copyWith(examples: cachedShort));
      }
      return;
    }

    if (currentDraft.examples.isNotEmpty && currentDraft.examples.length < 16) {
      _pureVerbShortExamplesCache[card.id] = currentDraft.examples;
    }
    if (currentDraft.examples.length >= 16) {
      _pureVerb16ExamplesCache[card.id] = currentDraft.examples;
      return;
    }

    final cached16 = _pureVerb16ExamplesCache[card.id];
    if (cached16 != null && cached16.length >= 16) {
      _storeDraft(card.id, currentDraft.copyWith(examples: cached16));
      return;
    }

    await _runAiGeneration(() async {
      final knownPos = effectivePartsOfSpeech(card);
      final result = await repository.generateFlashcardPracticeContent(
        word: card.word,
        currentMeaningId: effectiveMeaningId(card),
        wordTypeHint: 'verb',
        knownPartsOfSpeech: knownPos,
        mode: FlashcardExampleGenerationMode.verb16TensesOnly,
        includeAll16Tenses: true,
      );

      _pureVerb16ExamplesCache[card.id] = result.examples;
      _storeDraft(
        card.id,
        currentDraft.copyWith(
          wordType: 'verb',
          partsOfSpeech: knownPos.isNotEmpty ? knownPos : result.partsOfSpeech,
          phonetic: currentDraft.phonetic.isNotEmpty
              ? currentDraft.phonetic
              : result.phonetic,
          meaningId: currentDraft.meaningId.isNotEmpty
              ? currentDraft.meaningId
              : result.meaningId,
          examples: result.examples,
          conversation: currentDraft.conversation.isNotEmpty
              ? currentDraft.conversation
              : result.conversation,
        ),
      );
    });
  }

  /// Regenerates fresh sentences for the currently visible section/tab only.
  Future<void> replaceExamples(Flashcard card) async {
    await _runAiGeneration(() async {
      final currentDraft = _baselineDraft(card);
      final knownPos = effectivePartsOfSpeech(card);

      if (isHybridVerbCard(card)) {
        final activeTab = activeExampleTabFor(card.id);
        if (activeTab == 1) {
          includeAll16TensesByCard[card.id] = true;
          final avoidList = currentDraft.verbTensesExamples
              .map((e) => e.en.trim())
              .where((s) => s.isNotEmpty)
              .toList(growable: false);

          final result = await repository.generateFlashcardPracticeContent(
            word: card.word,
            currentMeaningId: effectiveMeaningId(card),
            wordTypeHint: 'verb',
            knownPartsOfSpeech: knownPos,
            mode: FlashcardExampleGenerationMode.verb16TensesOnly,
            includeAll16Tenses: true,
            avoidSentences: avoidList,
          );

          _storeDraft(
            card.id,
            currentDraft.copyWith(
              partsOfSpeech: knownPos,
              verbTensesExamples: result.examples,
            ),
          );
          return;
        }

        // Tab 1 (Non-Verb POS) regeneration: preserve Tab 2 `verbTensesExamples` completely.
        final avoidList = currentDraft.examples
            .map((e) => e.en.trim())
            .where((s) => s.isNotEmpty)
            .toList(growable: false);

        final result = await repository.generateFlashcardPracticeContent(
          word: card.word,
          currentMeaningId: effectiveMeaningId(card),
          knownPartsOfSpeech: knownPos,
          mode: FlashcardExampleGenerationMode.nonVerbOnly,
          includeAll16Tenses: false,
          avoidSentences: avoidList,
        );

        _storeDraft(
          card.id,
          currentDraft.copyWith(
            partsOfSpeech: knownPos,
            examples: result.examples,
          ),
        );
        return;
      }

      final isPureVerb = isPureVerbCard(card);
      final want16Tenses = isPureVerb && isVerb16TensesEnabled(card);
      final avoidList = currentDraft.examples
          .map((e) => e.en.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);

      final FlashcardExampleGenerationMode mode;
      if (want16Tenses) {
        mode = FlashcardExampleGenerationMode.verb16TensesOnly;
      } else if (nonVerbPartsFor(card).isNotEmpty) {
        mode = FlashcardExampleGenerationMode.nonVerbOnly;
      } else {
        mode = FlashcardExampleGenerationMode.standard;
      }

      final result = await repository.generateFlashcardPracticeContent(
        word: card.word,
        currentMeaningId: effectiveMeaningId(card),
        wordTypeHint: isPureVerb ? 'verb' : null,
        knownPartsOfSpeech: knownPos,
        mode: mode,
        includeAll16Tenses: want16Tenses,
        avoidSentences: avoidList,
      );

      final mergedPos = knownPos.isNotEmpty ? knownPos : result.partsOfSpeech;
      if (isPureVerb) {
        if (want16Tenses) {
          _pureVerb16ExamplesCache[card.id] = result.examples;
        } else {
          _pureVerbShortExamplesCache[card.id] = result.examples;
        }
      }

      _storeDraft(
        card.id,
        currentDraft.copyWith(
          wordType: FlashcardPosHelper.deriveWordType(
            mergedPos,
            fallback: result.wordType,
          ),
          partsOfSpeech: mergedPos,
          phonetic: currentDraft.phonetic.isNotEmpty
              ? currentDraft.phonetic
              : result.phonetic,
          meaningId: currentDraft.meaningId.isNotEmpty
              ? currentDraft.meaningId
              : result.meaningId,
          examples: result.examples,
          conversation: result.conversation.isNotEmpty
              ? result.conversation
              : currentDraft.conversation,
        ),
      );
    });
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
        partsOfSpeech: draft.partsOfSpeech,
        examples: draft.examples,
        verbTensesExamples: draft.verbTensesExamples,
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

  /// Launches a vocabulary-guided Free Talk Live session for [selection].
  void startSubDeckFreeTalk(FlashcardSubDeckFreeTalkSelection selection) {
    final practiceArgs = buildSubDeckFreeTalkPracticeArgs(selection);
    Get.toNamed<void>(Routes.PRACTICE, arguments: practiceArgs);
  }

  @override
  void onClose() {
    _cardsSub?.cancel();
    unawaited(ttsService.stop());
    super.onClose();
  }
}
