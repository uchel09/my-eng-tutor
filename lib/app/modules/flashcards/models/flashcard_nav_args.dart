import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';

/// Typed navigation arguments for the Level 2 Sub-Deck list screen.
class FlashcardSubDecksArgs {
  const FlashcardSubDecksArgs({required this.deck});

  final FlashcardDeck deck;
}

/// Typed navigation arguments for the Level 3 Flashcard study & AI screen.
class FlashcardStudyArgs {
  const FlashcardStudyArgs({
    required this.subDeck,
    required this.deckName,
  });

  final FlashcardSubDeck subDeck;
  final String deckName;
}

/// Unsaved local draft for AI-generated practice content on a single flashcard.
class FlashcardPracticeDraft {
  const FlashcardPracticeDraft({
    required this.wordType,
    this.partsOfSpeech = const <String>[],
    required this.phonetic,
    required this.meaningId,
    required this.examples,
    this.verbTensesExamples = const <FlashcardExampleItem>[],
    required this.conversation,
  });

  final String wordType;
  final List<String> partsOfSpeech;
  final String phonetic;
  final String meaningId;
  final List<FlashcardExampleItem> examples;
  final List<FlashcardExampleItem> verbTensesExamples;
  final String conversation;

  FlashcardPracticeDraft copyWith({
    String? wordType,
    List<String>? partsOfSpeech,
    String? phonetic,
    String? meaningId,
    List<FlashcardExampleItem>? examples,
    List<FlashcardExampleItem>? verbTensesExamples,
    String? conversation,
  }) {
    return FlashcardPracticeDraft(
      wordType: wordType ?? this.wordType,
      partsOfSpeech: partsOfSpeech ?? this.partsOfSpeech,
      phonetic: phonetic ?? this.phonetic,
      meaningId: meaningId ?? this.meaningId,
      examples: examples ?? this.examples,
      verbTensesExamples: verbTensesExamples ?? this.verbTensesExamples,
      conversation: conversation ?? this.conversation,
    );
  }
}

/// Typed navigation arguments for the Flashcard AI Quiz screen.
class FlashcardQuizArgs {
  const FlashcardQuizArgs({
    required this.scopeTitle,
    required this.scopeSubtitle,
    required this.cards,
    this.deckId,
    this.subDeckId,
  });

  final String scopeTitle;
  final String scopeSubtitle;
  final List<Flashcard> cards;
  final int? deckId;
  final int? subDeckId;
}
