import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/gemini_constants.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../../../data/models/practice_args.dart';
import '../../../data/repositories/tutor_repository.dart';

/// Maximum number of vocabulary words targeted in a single Free Talk session.
const int maxFreeTalkTargetWords = 10;

/// Selects up to [maxWords] (capped at [maxFreeTalkTargetWords]) unique words
/// from [cards], prioritizing `needsReview` (1) and `unstudied` (0) before `mastered` (2).
List<Flashcard> selectAutoFreeTalkVocabulary(
  List<Flashcard> cards, {
  int maxWords = maxFreeTalkTargetWords,
  math.Random? random,
}) {
  final effectiveCap = math.min(maxWords, maxFreeTalkTargetWords);
  if (effectiveCap <= 0 || cards.isEmpty) {
    return const <Flashcard>[];
  }

  final rng = random ?? math.Random();
  final seenWords = <String>{};
  final needsReviewBucket = <Flashcard>[];
  final unstudiedBucket = <Flashcard>[];
  final masteredBucket = <Flashcard>[];

  for (final card in cards) {
    final normalized = card.word.trim().toLowerCase();
    if (normalized.isEmpty || !seenWords.add(normalized)) continue;

    final status = FlashcardStudyStatus.clamp(card.studyStatus);
    if (status == FlashcardStudyStatus.needsReview) {
      needsReviewBucket.add(card);
    } else if (status == FlashcardStudyStatus.unstudied) {
      unstudiedBucket.add(card);
    } else {
      masteredBucket.add(card);
    }
  }

  needsReviewBucket.shuffle(rng);
  unstudiedBucket.shuffle(rng);
  masteredBucket.shuffle(rng);

  final ordered = <Flashcard>[
    ...needsReviewBucket,
    ...unstudiedBucket,
    ...masteredBucket,
  ];
  return ordered.take(effectiveCap).toList(growable: false);
}

/// Extracts an explicit CEFR level hint (`A1`–`C2`) from deck/sub-deck titles.
String detectCefrHintFromTitles(
  List<String?> titles, {
  String fallback = 'A2',
}) {
  final regex = RegExp(r'\b(A1|A2|B1|B2|C1|C2)\b', caseSensitive: false);
  for (final raw in titles) {
    if (raw == null || raw.trim().isEmpty) continue;
    final match = regex.firstMatch(raw);
    if (match != null) {
      return match.group(1)!.toUpperCase();
    }
  }
  return fallback.toUpperCase();
}

/// Result returned when configuring a Sub-Deck vocabulary Free Talk session.
class FlashcardSubDeckFreeTalkSelection {
  const FlashcardSubDeckFreeTalkSelection({
    required this.targetVocabulary,
    required this.subDeckTitle,
    this.deckTitle,
    this.cefrHint,
    this.optionalTopic,
  });

  final List<String> targetVocabulary;
  final String subDeckTitle;
  final String? deckTitle;
  final String? cefrHint;
  final String? optionalTopic;
}

/// Builds uniform [PracticeArgs] for launching a vocabulary-guided Free Talk session.
PracticeArgs buildSubDeckFreeTalkPracticeArgs(
  FlashcardSubDeckFreeTalkSelection selection, {
  String fallbackCefr = 'A2',
}) {
  final cleanedWords = <String>[];
  final seen = <String>{};
  for (final raw in selection.targetVocabulary) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    if (seen.add(trimmed.toLowerCase())) {
      cleanedWords.add(trimmed);
      if (cleanedWords.length >= maxFreeTalkTargetWords) break;
    }
  }

  final subDeckTitle = selection.subDeckTitle.trim();
  final topic = selection.optionalTopic?.trim();
  final hasTopic = topic != null && topic.isNotEmpty;

  final cefr = (selection.cefrHint?.trim().isNotEmpty == true)
      ? selection.cefrHint!.trim().toUpperCase()
      : detectCefrHintFromTitles(
          <String?>[selection.deckTitle, subDeckTitle],
          fallback: fallbackCefr,
        );

  final title = hasTopic
      ? 'Free Talk: $topic ($subDeckTitle)'
      : 'Free Talk: $subDeckTitle';

  final scenarioPrompt = hasTopic
      ? 'Have an engaging two-way English conversation about "$topic" while naturally weaving in your target words from "$subDeckTitle".'
      : 'Have an engaging two-way English conversation practicing your target vocabulary from "$subDeckTitle".';

  return PracticeArgs(
    sessionType: 'free_talk',
    targetCefrLevel: cefr,
    title: title,
    scenarioPrompt: scenarioPrompt,
    mode: 'live_roleplay',
    targetDurationSec: GeminiConstants.defaultTargetDurationSec * 2,
    customTopic: hasTopic ? topic : subDeckTitle,
    targetVocabulary: cleanedWords,
    vocabSubDeckTitle: subDeckTitle,
  );
}

/// Opens a keyboard-safe BottomSheet to pick 1–10 vocabulary words for Free Talk.
Future<FlashcardSubDeckFreeTalkSelection?> showFlashcardSubDeckFreeTalkSheet({
  required BuildContext context,
  required TutorRepository repository,
  FlashcardSubDeck? fixedSubDeck,
  String? fixedDeckName,
  String fallbackCefr = 'A2',
  VoidCallback? onOpenFlashcardsTab,
}) {
  return showModalBottomSheet<FlashcardSubDeckFreeTalkSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                fixedSubDeck != null
                    ? 'Free Talk: ${fixedSubDeck.name}'
                    : 'Free Talk Kosakata Sub-Deck',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih hingga 10 kata agar tutor AI memancingmu memakainya dalam obrolan.',
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              FlashcardSubDeckFreeTalkSelector(
                repository: repository,
                fixedSubDeck: fixedSubDeck,
                fixedDeckName: fixedDeckName,
                fallbackCefr: fallbackCefr,
                showSubmitActions: true,
                onOpenFlashcardsTab: () {
                  Navigator.of(sheetContext).pop();
                  onOpenFlashcardsTab?.call();
                },
                onSubmitted: (selection) {
                  Navigator.of(sheetContext).pop(selection);
                },
                onCancel: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Reusable Deck/Sub-Deck + Auto/Manual (max 10 words) Free Talk vocabulary selector.
class FlashcardSubDeckFreeTalkSelector extends StatefulWidget {
  const FlashcardSubDeckFreeTalkSelector({
    super.key,
    required this.repository,
    this.fixedSubDeck,
    this.fixedDeckName,
    this.fallbackCefr = 'A2',
    this.showSubmitActions = false,
    this.onSelectionChanged,
    this.onSubmitted,
    this.onCancel,
    this.onOpenFlashcardsTab,
  });

  final TutorRepository repository;
  final FlashcardSubDeck? fixedSubDeck;
  final String? fixedDeckName;
  final String fallbackCefr;
  final bool showSubmitActions;
  final ValueChanged<FlashcardSubDeckFreeTalkSelection?>? onSelectionChanged;
  final ValueChanged<FlashcardSubDeckFreeTalkSelection>? onSubmitted;
  final VoidCallback? onCancel;
  final VoidCallback? onOpenFlashcardsTab;

  @override
  State<FlashcardSubDeckFreeTalkSelector> createState() =>
      _FlashcardSubDeckFreeTalkSelectorState();
}

class _FlashcardSubDeckFreeTalkSelectorState
    extends State<FlashcardSubDeckFreeTalkSelector> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final math.Random _random = math.Random();

  bool _isLoading = true;
  bool _isManualMode = false;

  List<DeckWithStats> _decks = const <DeckWithStats>[];
  int? _selectedDeckId;

  List<FlashcardSubDeck> _subDecks = const <FlashcardSubDeck>[];
  int? _selectedSubDeckId;

  List<Flashcard> _cards = const <Flashcard>[];
  List<Flashcard> _autoSelectedCards = const <Flashcard>[];
  final Set<int> _manualSelectedCardIds = <int>{};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      if (widget.fixedSubDeck != null) {
        final cards = await widget.repository.getCardsBySubDeck(
          widget.fixedSubDeck!.id,
        );
        if (!mounted) return;
        _subDecks = <FlashcardSubDeck>[widget.fixedSubDeck!];
        _selectedSubDeckId = widget.fixedSubDeck!.id;
        _applyLoadedCards(cards);
        return;
      }

      final decks = await widget.repository.getDecksWithStats();
      if (!mounted) return;
      _decks = decks;
      if (decks.isEmpty) {
        _cards = const <Flashcard>[];
        _autoSelectedCards = const <Flashcard>[];
        _manualSelectedCardIds.clear();
        setState(() => _isLoading = false);
        _notifySelectionChanged();
        return;
      }

      final preferredDeck = decks.firstWhere(
        (d) => d.totalCardCount > 0,
        orElse: () => decks.first,
      );
      await _selectDeck(preferredDeck.deck.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _notifySelectionChanged();
    }
  }

  Future<void> _selectDeck(int deckId) async {
    setState(() {
      _selectedDeckId = deckId;
      _isLoading = true;
    });
    final subDecks = await widget.repository.getSubDecksByDeck(deckId);
    if (!mounted) return;
    _subDecks = subDecks;
    if (subDecks.isEmpty) {
      _selectedSubDeckId = null;
      _applyLoadedCards(const <Flashcard>[]);
      return;
    }
    await _selectSubDeck(subDecks.first.id);
  }

  Future<void> _selectSubDeck(int subDeckId) async {
    setState(() {
      _selectedSubDeckId = subDeckId;
      _isLoading = true;
    });
    final cards = await widget.repository.getCardsBySubDeck(subDeckId);
    if (!mounted) return;
    _applyLoadedCards(cards);
  }

  void _applyLoadedCards(List<Flashcard> cards) {
    _cards = cards;
    _manualSelectedCardIds.clear();
    _searchQuery = '';
    _searchController.clear();
    _autoSelectedCards = selectAutoFreeTalkVocabulary(
      cards,
      maxWords: maxFreeTalkTargetWords,
      random: _random,
    );
    setState(() => _isLoading = false);
    _notifySelectionChanged();
  }

  void _clearManualSelection() {
    if (_manualSelectedCardIds.isEmpty) return;
    setState(() {
      _manualSelectedCardIds.clear();
    });
    _notifySelectionChanged();
  }

  void _fillManualFromAuto() {
    if (_autoSelectedCards.isEmpty) return;
    setState(() {
      _manualSelectedCardIds
        ..clear()
        ..addAll(
          _autoSelectedCards
              .take(maxFreeTalkTargetWords)
              .map((c) => c.id),
        );
    });
    _notifySelectionChanged();
  }

  void _reshuffleAutoWords() {
    setState(() {
      _autoSelectedCards = selectAutoFreeTalkVocabulary(
        _cards,
        maxWords: maxFreeTalkTargetWords,
        random: _random,
      );
    });
    _notifySelectionChanged();
  }

  String? get _activeDeckTitle {
    if (widget.fixedDeckName != null) return widget.fixedDeckName;
    for (final d in _decks) {
      if (d.deck.id == _selectedDeckId) return d.deck.name;
    }
    return null;
  }

  FlashcardSubDeck? get _activeSubDeck {
    if (widget.fixedSubDeck != null) return widget.fixedSubDeck;
    for (final s in _subDecks) {
      if (s.id == _selectedSubDeckId) return s;
    }
    return null;
  }

  FlashcardSubDeckFreeTalkSelection? _buildCurrentSelection() {
    final subDeck = _activeSubDeck;
    if (subDeck == null || _cards.isEmpty) return null;

    final selectedWords = _isManualMode
        ? _cards
            .where((c) => _manualSelectedCardIds.contains(c.id))
            .map((c) => c.word.trim())
            .where((w) => w.isNotEmpty)
            .take(maxFreeTalkTargetWords)
            .toList(growable: false)
        : _autoSelectedCards
            .map((c) => c.word.trim())
            .where((w) => w.isNotEmpty)
            .take(maxFreeTalkTargetWords)
            .toList(growable: false);

    if (selectedWords.isEmpty) return null;

    final deckTitle = _activeDeckTitle;
    final topic = _topicController.text.trim();
    return FlashcardSubDeckFreeTalkSelection(
      targetVocabulary: selectedWords,
      subDeckTitle: subDeck.name,
      deckTitle: deckTitle,
      cefrHint: detectCefrHintFromTitles(
        <String?>[deckTitle, subDeck.name],
        fallback: widget.fallbackCefr,
      ),
      optionalTopic: topic.isEmpty ? null : topic,
    );
  }

  void _notifySelectionChanged() {
    widget.onSelectionChanged?.call(_buildCurrentSelection());
  }

  List<Flashcard> get _filteredManualCards {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _cards;
    return _cards
        .where(
          (c) =>
              c.word.toLowerCase().contains(q) ||
              c.meaningId.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  Color _statusColor(int studyStatus, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    switch (FlashcardStudyStatus.clamp(studyStatus)) {
      case FlashcardStudyStatus.mastered:
        return isDark ? Colors.green.shade300 : Colors.green.shade700;
      case FlashcardStudyStatus.needsReview:
        return isDark ? Colors.amber.shade300 : Colors.amber.shade800;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.fixedSubDeck == null && _decks.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Belum ada Deck Flashcard tersimpan. Tambahkan kata atau unduh paket kosakata di tab Flashcard terlebih dahulu.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (widget.onOpenFlashcardsTab != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: widget.onOpenFlashcardsTab,
              icon: const Icon(Icons.style_outlined),
              label: const Text('Buka Tab Flashcard'),
            ),
          ],
          if (widget.showSubmitActions) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onCancel,
                child: const Text('Tutup'),
              ),
            ),
          ],
        ],
      );
    }

    final selection = _buildCurrentSelection();
    final selectedCount = _manualSelectedCardIds.length;
    final manualLimitReached = selectedCount >= maxFreeTalkTargetWords;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.fixedSubDeck == null) ...[
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Pilih Deck',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _selectedDeckId,
                items: _decks
                    .map(
                      (d) => DropdownMenuItem<int>(
                        value: d.deck.id,
                        child: Text(
                          '${d.deck.name} (${d.totalCardCount})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null && value != _selectedDeckId) {
                    _selectDeck(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_subDecks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Deck ini belum memiliki Sub-Deck.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            )
          else
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Pilih Sub-Deck',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedSubDeckId,
                  items: _subDecks
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: s.id,
                          child: Text(
                            s.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null && value != _selectedSubDeckId) {
                      _selectSubDeck(value);
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],
        if (_cards.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Belum ada kata di sub-deck ini. Tambahkan kata dulu di tab Flashcard.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (widget.onOpenFlashcardsTab != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: widget.onOpenFlashcardsTab,
              icon: const Icon(Icons.style_outlined),
              label: const Text('Buka Tab Flashcard'),
            ),
          ],
        ] else ...[
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Otomatis (Maks. 10)'),
                ),
              ),
              ButtonSegment<bool>(
                value: true,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Pilih Manual (1–10)'),
                ),
              ),
            ],
            selected: <bool>{_isManualMode},
            onSelectionChanged: (selected) {
              if (selected.isEmpty) return;
              setState(() => _isManualMode = selected.first);
              _notifySelectionChanged();
            },
          ),
          const SizedBox(height: 10),
          if (!_isManualMode) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dipilih ${_autoSelectedCards.length} kata (prioritas Belum & Perlu Ulang):',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_cards.length > maxFreeTalkTargetWords)
                  TextButton.icon(
                    onPressed: _reshuffleAutoWords,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.shuffle_rounded, size: 16),
                    label: const Text('Acak Ulang'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _autoSelectedCards
                  .map(
                    (card) => Chip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(
                        card.word,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Terpilih: $selectedCount / $maxFreeTalkTargetWords kata',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: manualLimitReached
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (selectedCount > 0)
                  TextButton.icon(
                    onPressed: _clearManualSelection,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Kosongkan'),
                  )
                else if (_autoSelectedCards.isNotEmpty)
                  TextButton.icon(
                    onPressed: _fillManualFromAuto,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(
                      _autoSelectedCards.length >= maxFreeTalkTargetWords
                          ? 'Isi 10 Acak'
                          : 'Isi ${_autoSelectedCards.length} Acak',
                    ),
                  ),
              ],
            ),
            if (manualLimitReached) ...[
              const SizedBox(height: 2),
              Text(
                'Maksimal 10 kata per sesi agar obrolan fokus (hapus centang lain atau ketuk Kosongkan)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                hintText: 'Cari kata...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _filteredManualCards.map((card) {
                      final isChecked = _manualSelectedCardIds.contains(card.id);
                      final isDisabled = !isChecked && manualLimitReached;
                      final statusColor = _statusColor(card.studyStatus, theme);
                      return InkWell(
                        onTap: isDisabled
                            ? null
                            : () {
                                setState(() {
                                  if (isChecked) {
                                    _manualSelectedCardIds.remove(card.id);
                                  } else if (_manualSelectedCardIds.length <
                                      maxFreeTalkTargetWords) {
                                    _manualSelectedCardIds.add(card.id);
                                  }
                                });
                                _notifySelectionChanged();
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                visualDensity: VisualDensity.compact,
                                value: isChecked,
                                onChanged: isDisabled
                                    ? null
                                    : (checked) {
                                        setState(() {
                                          if (checked == true &&
                                              _manualSelectedCardIds.length <
                                                  maxFreeTalkTargetWords) {
                                            _manualSelectedCardIds.add(card.id);
                                          } else {
                                            _manualSelectedCardIds.remove(
                                              card.id,
                                            );
                                          }
                                        });
                                        _notifySelectionChanged();
                                      },
                              ),
                              Expanded(
                                child: Opacity(
                                  opacity: isDisabled ? 0.45 : 1.0,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card.word,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (card.meaningId.trim().isNotEmpty)
                                        Text(
                                          card.meaningId.trim(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color:
                                                    colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  FlashcardStudyStatus.labelId(card.studyStatus),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _topicController,
            onChanged: (_) => _notifySelectionChanged(),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Topik / Situasi Tambahan (opsional)',
              hintText: 'Misal: Ngobrol di kafe',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        if (widget.showSubmitActions) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: selection == null
                      ? null
                      : () => widget.onSubmitted?.call(selection),
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: const Text('Mulai Free Talk'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
