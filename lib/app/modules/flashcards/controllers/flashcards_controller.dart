import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final RxBool isExportingFlashcards = false.obs;
  final RxBool isImportingFlashcards = false.obs;

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

  /// Exports all Decks, Sub-Decks, and Flashcards to a portable JSON file
  /// and opens the platform share sheet.
  Future<void> exportFlashcards() async {
    if (isExportingFlashcards.value || _isClosed) return;
    isExportingFlashcards.value = true;
    try {
      final payload = await repository.exportFlashcardsJson();
      final exportedDecks = payload['decks'];
      if (exportedDecks is! List || exportedDecks.isEmpty) {
        showFlashcardSnackbar(
          title: 'Belum Ada Flashcard',
          message:
              'Buat atau unduh minimal 1 deck sebelum mengekspor file JSON.',
          isError: true,
        );
        return;
      }

      final encoded = const JsonEncoder.withIndent('  ').convert(payload);
      final timestamp = _formatFileTimestamp(DateTime.now());
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}${Platform.pathSeparator}my_english_tutor_flashcards_$timestamp.json',
      );
      await file.writeAsString(encoded, encoding: utf8);

      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path, mimeType: 'application/json')],
          text: 'Export Flashcards My English Tutor ($timestamp)',
          subject: 'My English Tutor Flashcards',
        ),
      );
    } catch (error) {
      showFlashcardSnackbar(
        title: 'Gagal Export Flashcard',
        message: 'Tidak dapat mengekspor flashcard: $error',
        isError: true,
      );
    } finally {
      isExportingFlashcards.value = false;
    }
  }

  /// Picks a Flashcards `.json` file, confirms merge import, and merges new
  /// decks, sub-decks, and cards without overwriting existing study progress.
  Future<void> importFlashcards() async {
    if (isImportingFlashcards.value || _isClosed) return;
    isImportingFlashcards.value = true;
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Pilih File Flashcard JSON',
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final rawJson = utf8.decode(bytes);
      final decoded = jsonDecode(rawJson);

      if (decoded is! Map<String, dynamic> ||
          !_hasRecognizableFlashcardPayload(decoded)) {
        throw const FormatException(
          'Format file Flashcard JSON tidak valid. Pastikan file berisi daftar decks atau backup flashcard.',
        );
      }

      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Import Flashcard JSON?'),
          content: const Text(
            'Kosakata baru akan ditambahkan ke Deck & Sub-Deck terkait. Kata dan progress belajar yang sudah Anda miliki tetap aman dan tidak dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back<bool>(result: false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Get.back<bool>(result: true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      await importFlashcardsPayload(decoded);
    } on FormatException catch (error) {
      showFlashcardSnackbar(
        title: 'File Flashcard Tidak Valid',
        message: error.message,
        isError: true,
      );
    } catch (error) {
      showFlashcardSnackbar(
        title: 'Gagal Import Flashcard',
        message: 'Tidak dapat mengimpor file flashcard: $error',
        isError: true,
      );
    } finally {
      isImportingFlashcards.value = false;
    }
  }

  /// Merges [payload] directly into local Drift tables and shows a summary snackbar.
  Future<FlashcardImportResult> importFlashcardsPayload(
    Map<String, dynamic> payload,
  ) async {
    final result = await repository.importFlashcardsJson(payload);
    showFlashcardSnackbar(
      title: 'Import Flashcard Berhasil',
      message:
          '${result.insertedCount} kata baru ditambahkan '
          '(${result.updatedCount} diperbarui, ${result.skippedCount} sudah ada).',
    );
    return result;
  }

  bool _hasRecognizableFlashcardPayload(Map<String, dynamic> json) {
    final decks = json['decks'];
    if (decks is List && decks.isNotEmpty) {
      return true;
    }
    final legacyDecks = json['flashcardDecks'];
    final legacySubDecks = json['flashcardSubDecks'];
    final legacyCards = json['flashcards'];
    return legacyDecks is List &&
        legacyDecks.isNotEmpty &&
        legacySubDecks is List &&
        legacyCards is List;
  }

  String _formatFileTimestamp(DateTime now) {
    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _isClosed = true;
    _pauseRequested = true;
    _decksSub?.cancel();
    super.onClose();
  }
}
