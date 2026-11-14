import 'dart:async';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../../../data/providers/gemini_rest_provider.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../routes/app_pages.dart';
import '../models/daily_vocab_curriculum.dart';
import '../models/flashcard_nav_args.dart';
import '../widgets/flashcard_dialogs.dart';

/// Level 1 controller managing top-level Flashcard Decks and deck-wide quizzes.
class FlashcardsController extends GetxController {
  FlashcardsController({
    required this.repository,
    this.packInterRequestDelay = const Duration(milliseconds: 1200),
    this.packFormatRetryDelay = const Duration(milliseconds: 500),
  });

  final TutorRepository repository;
  final Duration packInterRequestDelay;
  final Duration packFormatRetryDelay;

  final RxList<DeckWithStats> decks = <DeckWithStats>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  // Reactive Daily Vocab AI pack downloader states.
  final RxBool isDownloadingPack = false.obs;
  final RxBool isDownloadPaused = false.obs;
  final RxInt packProgressCurrent = 0.obs;
  final RxInt packProgressTotal = 0.obs;
  final RxInt packInsertedCards = 0.obs;
  final RxString packStatusText = ''.obs;
  final RxnString packErrorMessage = RxnString();
  final RxnString activePackLevelFilter = RxnString();

  StreamSubscription<List<DeckWithStats>>? _decksSub;
  bool _pauseRequested = false;
  bool _isClosed = false;

  @override
  void onInit() {
    super.onInit();
    _subscribeDecks();
  }

  void _subscribeDecks() {
    _decksSub?.cancel();
    isLoading.value = true;
    errorMessage.value = null;

    _decksSub = repository.watchDecksWithStats().listen(
      (items) {
        decks.assignAll(items);
        isLoading.value = false;
      },
      onError: (Object error) {
        errorMessage.value = 'Gagal memuat daftar deck flashcard: $error';
        isLoading.value = false;
      },
    );
  }

  /// Retries subscribing to the reactive Deck list after an unexpected error.
  void retryLoad() => _subscribeDecks();

  /// Creates a new top-level Deck in Drift and returns its row ID.
  Future<int?> createDeck(String name, {String? description}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final createdId = await repository.createDeck(
      name: trimmed,
      description: description,
    );
    showFlashcardSnackbar(
      title: 'Deck Dibuat',
      message: 'Deck "$trimmed" berhasil ditambahkan.',
    );
    return createdId;
  }

  /// Renames an existing [deck] when [newName] is non-empty and changed.
  Future<void> renameDeck(FlashcardDeck deck, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == deck.name) return;

    await repository.renameDeck(deck.id, trimmed);
    showFlashcardSnackbar(
      title: 'Deck Diperbarui',
      message: 'Nama deck diubah menjadi "$trimmed".',
    );
  }

  /// Deletes [deck] along with all nested sub-decks and flashcards.
  Future<void> deleteDeck(FlashcardDeck deck) async {
    await repository.deleteDeck(deck.id);
    showFlashcardSnackbar(
      title: 'Deck Dihapus',
      message: 'Deck "${deck.name}" dan seluruh isinya telah dihapus.',
    );
  }

  /// Navigates to Level 2 (Sub-Deck list) for [deck].
  void openDeck(FlashcardDeck deck) {
    Get.toNamed<void>(
      Routes.FLASHCARD_SUBDECKS,
      arguments: FlashcardSubDecksArgs(deck: deck),
    );
  }

  /// Validates card availability across all Sub-Decks in [deck] before starting a quiz.
  Future<void> startDeckQuiz(FlashcardDeck deck) async {
    final cards = await repository.getCardsByDeck(deck.id);
    if (cards.isEmpty) {
      showFlashcardSnackbar(
        title: 'Deck Belum Memiliki Kata',
        message:
            "Belum ada kata di dalam sub-deck mana pun pada deck '${deck.name}'.",
        isError: true,
      );
      return;
    }

    Get.toNamed<void>(
      Routes.FLASHCARD_QUIZ,
      arguments: FlashcardQuizArgs(
        scopeTitle: deck.name,
        scopeSubtitle: 'Semua Sub-Deck di Deck ini',
        cards: cards,
        deckId: deck.id,
      ),
    );
  }

  /// Requests pausing the active curriculum pack download safely after the current batch.
  void pauseCurriculumDownload() {
    if (!isDownloadingPack.value) return;
    _pauseRequested = true;
    isDownloadPaused.value = true;
    packStatusText.value =
        'Menjeda unduhan setelah batch saat ini selesai disimpan...';
  }

  /// Resumes downloading the previously selected CEFR scope, skipping completed sub-decks.
  Future<void> resumeCurriculumDownload() {
    return downloadCurriculumPack(
      cefrLevelFilter: activePackLevelFilter.value,
    );
  }

  /// Downloads lightweight everyday-conversation vocabulary cards from AI
  /// across the fixed CEFR curriculum (4 levels x 12 sub-decks x 50 words).
  Future<void> downloadCurriculumPack({String? cefrLevelFilter}) async {
    if (isDownloadingPack.value || _isClosed) return;

    final topics = DailyVocabCurriculum.topicsForLevel(cefrLevelFilter);
    if (topics.isEmpty) return;

    final normalizedFilter = cefrLevelFilter?.trim().toUpperCase();
    activePackLevelFilter.value =
        (normalizedFilter == null || normalizedFilter.isEmpty)
            ? null
            : normalizedFilter;

    _pauseRequested = false;
    isDownloadingPack.value = true;
    isDownloadPaused.value = false;
    packProgressTotal.value = topics.length;
    packProgressCurrent.value = 0;
    packInsertedCards.value = 0;
    packErrorMessage.value = null;
    packStatusText.value = activePackLevelFilter.value == null
        ? 'Menyiapkan unduhan 4 Level CEFR (${topics.length} topik)...'
        : 'Menyiapkan unduhan level ${activePackLevelFilter.value} (${topics.length} topik)...';

    final deckIdByName = <String, int>{};
    final existingWordsByDeckId = <int, Set<String>>{};

    try {
      for (var i = 0; i < topics.length; i++) {
        if (_isClosed || _pauseRequested) {
          isDownloadPaused.value = true;
          packStatusText.value =
              'Unduhan dijeda (${packProgressCurrent.value}/${topics.length} topik, +${packInsertedCards.value} kata tersimpan).';
          return;
        }

        final topic = topics[i];
        try {
          final deckId = deckIdByName[topic.deckName] ??
              await repository.getOrCreateDeckByName(
                name: topic.deckName,
                description: topic.deckDescription,
              );
          deckIdByName[topic.deckName] = deckId;

          final subDeckId = await repository.getOrCreateSubDeckByName(
            deckId: deckId,
            name: topic.subDeckName,
            description: topic.subDeckDescription,
          );

          final existingSubCards = await repository.getCardsBySubDeck(subDeckId);
          var currentTopicCount = existingSubCards.length;
          final targetCount = topic.targetCount;
          final skipThreshold = targetCount >= 50 ? 45 : targetCount;
          if (currentTopicCount >= skipThreshold) {
            packProgressCurrent.value = i + 1;
            packStatusText.value =
                'Melewati ${topic.cefrLevel} • ${topic.subDeckName} ($currentTopicCount kata sudah lengkap)';
            continue;
          }

          final existingWords = existingWordsByDeckId[deckId] ??
              await repository.getExistingWordsInDeck(deckId);
          existingWordsByDeckId[deckId] = existingWords;

          const maxSubBatchSize = 25;
          const maxRequestsPerTopic = 3;
          var topicRequestCount = 0;
          var topicInsertedCount = 0;
          var consecutiveEmptyCount = 0;

          while (currentTopicCount < skipThreshold &&
              topicRequestCount < maxRequestsPerTopic) {
            if (_isClosed || _pauseRequested) {
              isDownloadPaused.value = true;
              packStatusText.value =
                  'Unduhan dijeda (${packProgressCurrent.value}/${topics.length} topik, +${packInsertedCards.value} kata tersimpan).';
              return;
            }

            final remainingNeeded =
                (targetCount - currentTopicCount).clamp(1, maxSubBatchSize);

            packStatusText.value =
                'Mengunduh ${topic.cefrLevel}: ${topic.subDeckName} ($currentTopicCount/$targetCount kata)...';

            final generatedItems = await _generateSubBatchWithRetry(
              cefrLevel: topic.cefrLevel,
              topicName: topic.subDeckName,
              count: remainingNeeded,
              avoidWords: existingWords.toList(growable: false),
            );
            if (_isClosed) return;
            topicRequestCount += 1;

            for (final item in generatedItems) {
              existingWords.add(item.word.trim().toLowerCase());
            }

            final seedInputs = generatedItems
                .map(
                  (item) => FlashcardSeedInput(
                    word: item.word,
                    phonetic: item.phonetic,
                    meaningId: item.meaningId,
                    partsOfSpeech: item.partsOfSpeech,
                  ),
                )
                .toList(growable: false);

            final insertedCount = seedInputs.isEmpty
                ? 0
                : await repository.bulkUpsertFlashcards(
                    subDeckId: subDeckId,
                    items: seedInputs,
                  );

            var exhaustedDuplicates = false;
            if (insertedCount == 0) {
              consecutiveEmptyCount += 1;
              if (consecutiveEmptyCount >= 2) {
                exhaustedDuplicates = true;
              }
            } else {
              consecutiveEmptyCount = 0;
              currentTopicCount += insertedCount;
              topicInsertedCount += insertedCount;
              packInsertedCards.value += insertedCount;
            }

            packStatusText.value =
                'Mengunduh ${topic.cefrLevel}: ${topic.subDeckName} ($currentTopicCount/$targetCount kata)...';

            final topicFinished = currentTopicCount >= skipThreshold ||
                topicRequestCount >= maxRequestsPerTopic ||
                exhaustedDuplicates;
            if (topicFinished) {
              packProgressCurrent.value = i + 1;
            }

            if (_pauseRequested) {
              isDownloadPaused.value = true;
              packStatusText.value =
                  'Unduhan dijeda (${packProgressCurrent.value}/${topics.length} topik, +${packInsertedCards.value} kata tersimpan).';
              return;
            }

            if (exhaustedDuplicates) {
              break;
            }

            final needsDelayAfterBatch = !topicFinished || i < topics.length - 1;
            if (needsDelayAfterBatch && packInterRequestDelay > Duration.zero) {
              await Future<void>.delayed(packInterRequestDelay);
              if (_isClosed || _pauseRequested) {
                isDownloadPaused.value = true;
                packStatusText.value =
                    'Unduhan dijeda (${packProgressCurrent.value}/${topics.length} topik, +${packInsertedCards.value} kata tersimpan).';
                return;
              }
            }
          }

          packProgressCurrent.value = i + 1;
          packStatusText.value = topicInsertedCount > 0
              ? 'Tersimpan +$topicInsertedCount kata baru di ${topic.cefrLevel} • ${topic.subDeckName} ($currentTopicCount/$targetCount kata)'
              : 'Melanjutkan ke topik berikutnya dari ${topic.cefrLevel} • ${topic.subDeckName} ($currentTopicCount/$targetCount kata)';
        } on GeminiApiException catch (error) {
          if (_isClosed) return;
          isDownloadPaused.value = true;
          packErrorMessage.value = error.message;
          packStatusText.value =
              'Berhenti di topik ${i + 1}/${topics.length}. +${packInsertedCards.value} kata sudah aman tersimpan dan bisa dilanjutkan.';
          showFlashcardSnackbar(
            title: 'Unduhan Paket Terhenti',
            message: error.message,
            isError: true,
          );
          return;
        } catch (error) {
          if (_isClosed) return;
          final msg = 'Gagal mengunduh "${topic.subDeckName}": $error';
          isDownloadPaused.value = true;
          packErrorMessage.value = msg;
          packStatusText.value =
              'Terhenti di topik ${i + 1}/${topics.length}. +${packInsertedCards.value} kata sudah tersimpan.';
          showFlashcardSnackbar(
            title: 'Unduhan Paket Gagal',
            message: msg,
            isError: true,
          );
          return;
        }
      }

      if (!_isClosed) {
        isDownloadPaused.value = false;
        packStatusText.value =
            'Selesai! Total +${packInsertedCards.value} kata baru siap dipelajari.';
        showFlashcardSnackbar(
          title: 'Paket Kosakata Selesai',
          message:
              'Total +${packInsertedCards.value} kata berhasil disimpan ke Flashcard.',
        );
      }
    } finally {
      isDownloadingPack.value = false;
    }
  }

  Future<List<GeneratedVocabPackItem>> _generateSubBatchWithRetry({
    required String cefrLevel,
    required String topicName,
    required int count,
    required List<String> avoidWords,
  }) async {
    try {
      return await repository.generateDailyVocabBatch(
        cefrLevel: cefrLevel,
        topicName: topicName,
        count: count,
        avoidWords: avoidWords,
      );
    } on GeminiApiException catch (error) {
      if (_isClosed || _pauseRequested || !_isRetryableFormatError(error)) {
        rethrow;
      }
      if (packFormatRetryDelay > Duration.zero) {
        await Future<void>.delayed(packFormatRetryDelay);
      }
      if (_isClosed || _pauseRequested) rethrow;
      return repository.generateDailyVocabBatch(
        cefrLevel: cefrLevel,
        topicName: topicName,
        count: count,
        avoidWords: avoidWords,
      );
    }
  }

  bool _isRetryableFormatError(GeminiApiException error) {
    final code = error.statusCode;
    if (code != null && code != 200) {
      return false;
    }
    final lower = error.message.toLowerCase();
    if (lower.contains('api key') ||
        lower.contains('internet') ||
        lower.contains('gagal menghubungi') ||
        lower.contains('timeout') ||
        lower.contains('kuota') ||
        lower.contains('batas pemakaian') ||
        lower.contains('429') ||
        lower.contains('401') ||
        lower.contains('403')) {
      return false;
    }
    return lower.contains('format') ||
        lower.contains('json') ||
        lower.contains('tidak mengembalikan') ||
        lower.contains('kosakata');
  }

  @override
  void onClose() {
    _isClosed = true;
    _pauseRequested = true;
    _decksSub?.cancel();
    super.onClose();
  }
}
