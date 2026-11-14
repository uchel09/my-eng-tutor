import 'dart:async';

import 'package:get/get.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../../../data/repositories/tutor_repository.dart';
import '../../../routes/app_pages.dart';
import '../models/flashcard_nav_args.dart';
import '../widgets/flashcard_dialogs.dart';
import '../widgets/flashcard_freetalk_sheet.dart';

/// Level 2 controller managing Sub-Decks within a parent [FlashcardDeck].
class FlashcardSubDecksController extends GetxController {
  FlashcardSubDecksController({
    required this.repository,
    FlashcardDeck? initialDeck,
  }) : _initialDeck = initialDeck;

  final TutorRepository repository;
  final FlashcardDeck? _initialDeck;

  late final FlashcardDeck? deck;

  final RxList<SubDeckWithStats> subDecks = <SubDeckWithStats>[].obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<List<SubDeckWithStats>>? _subDecksSub;

  String get deckTitle => deck?.name ?? 'Sub-Deck';

  @override
  void onInit() {
    super.onInit();
    final rawArgs = Get.arguments;
    if (_initialDeck != null) {
      deck = _initialDeck;
    } else if (rawArgs is FlashcardSubDecksArgs) {
      deck = rawArgs.deck;
    } else if (rawArgs is FlashcardDeck) {
      deck = rawArgs;
    } else {
      deck = null;
    }

    if (deck == null) {
      errorMessage.value = 'Data Deck flashcard tidak ditemukan.';
      isLoading.value = false;
      return;
    }

    _subscribeSubDecks();
  }

  void _subscribeSubDecks() {
    final parentDeck = deck;
    if (parentDeck == null) return;

    _subDecksSub?.cancel();
    isLoading.value = true;
    errorMessage.value = null;

    _subDecksSub = repository.watchSubDecksWithStats(parentDeck.id).listen(
      (items) {
        subDecks.assignAll(items);
        isLoading.value = false;
      },
      onError: (Object error) {
        errorMessage.value = 'Gagal memuat daftar sub-deck: $error';
        isLoading.value = false;
      },
    );
  }

  /// Retries subscribing to the reactive Sub-Deck stream.
  void retryLoad() => _subscribeSubDecks();

  /// Creates a new Sub-Deck inside the parent [deck] and returns its row ID.
  Future<int?> createSubDeck(String name, {String? description}) async {
    final parentDeck = deck;
    final trimmed = name.trim();
    if (parentDeck == null || trimmed.isEmpty) return null;

    final createdId = await repository.createSubDeck(
      deckId: parentDeck.id,
      name: trimmed,
      description: description,
    );
    showFlashcardSnackbar(
      title: 'Sub-Deck Dibuat',
      message: 'Sub-Deck "$trimmed" berhasil ditambahkan.',
    );
    return createdId;
  }

  /// Renames [subDeck] when [newName] is non-empty and changed.
  Future<void> renameSubDeck(FlashcardSubDeck subDeck, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == subDeck.name) return;

    await repository.renameSubDeck(subDeck.id, trimmed);
    showFlashcardSnackbar(
      title: 'Sub-Deck Diperbarui',
      message: 'Nama sub-deck diubah menjadi "$trimmed".',
    );
  }

  /// Deletes [subDeck] and cascades deletion to all flashcards inside it.
  Future<void> deleteSubDeck(FlashcardSubDeck subDeck) async {
    await repository.deleteSubDeck(subDeck.id);
    showFlashcardSnackbar(
      title: 'Sub-Deck Dihapus',
      message: 'Sub-Deck "${subDeck.name}" telah dihapus.',
    );
  }

  /// Navigates to Level 3 (Flashcard list & AI study screen) for [subDeck].
  void openSubDeck(FlashcardSubDeck subDeck) {
    Get.toNamed<void>(
      Routes.FLASHCARD_CARDS,
      arguments: FlashcardStudyArgs(
        subDeck: subDeck,
        deckName: deckTitle,
      ),
    );
  }

  /// Validates card availability inside [subDeck] before starting a targeted quiz.
  Future<void> startSubDeckQuiz(FlashcardSubDeck subDeck) async {
    final cards = await repository.getCardsBySubDeck(subDeck.id);
    if (cards.isEmpty) {
      showFlashcardSnackbar(
        title: 'Sub-Deck Kosong',
        message: "Belum ada kata di sub-deck '${subDeck.name}'.",
        isError: true,
      );
      return;
    }

    Get.toNamed<void>(
      Routes.FLASHCARD_QUIZ,
      arguments: FlashcardQuizArgs(
        scopeTitle: subDeck.name,
        scopeSubtitle: 'Sub-Deck • $deckTitle',
        cards: cards,
        deckId: deck?.id,
        subDeckId: subDeck.id,
      ),
    );
  }

  /// Launches a vocabulary-guided Free Talk Live session for [selection].
  void startSubDeckFreeTalk(FlashcardSubDeckFreeTalkSelection selection) {
    final practiceArgs = buildSubDeckFreeTalkPracticeArgs(selection);
    Get.toNamed<void>(Routes.PRACTICE, arguments: practiceArgs);
  }

  @override
  void onClose() {
    _subDecksSub?.cancel();
    super.onClose();
  }
}
