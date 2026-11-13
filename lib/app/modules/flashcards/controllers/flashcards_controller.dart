import 'dart:async';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../routes/app_pages.dart';
import '../models/flashcard_nav_args.dart';
import '../widgets/flashcard_dialogs.dart';

/// Level 1 controller managing top-level Flashcard Decks and deck-wide quizzes.
class FlashcardsController extends GetxController {
  FlashcardsController({required this.repository});

  final TutorRepository repository;

  final RxList<DeckWithStats> decks = <DeckWithStats>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<List<DeckWithStats>>? _decksSub;

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

  @override
  void onClose() {
    _decksSub?.cancel();
    super.onClose();
  }
}
