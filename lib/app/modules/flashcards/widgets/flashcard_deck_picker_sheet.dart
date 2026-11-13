import 'package:flutter/material.dart';

import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../../../data/repositories/tutor_repository.dart';
import 'flashcard_dialogs.dart';

/// Selected Deck + Sub-Deck destination returned by [showFlashcardDeckPickerSheet].
class FlashcardTargetSelection {
  const FlashcardTargetSelection({
    required this.deckId,
    required this.deckName,
    required this.subDeckId,
    required this.subDeckName,
  });

  final int deckId;
  final String deckName;
  final int subDeckId;
  final String subDeckName;

  String get targetLabel => '$deckName / $subDeckName';
}

/// Opens a two-step reusable bottom sheet allowing users to pick or create a
/// Deck and Sub-Deck destination for saving flashcards.
Future<FlashcardTargetSelection?> showFlashcardDeckPickerSheet({
  required BuildContext context,
  required TutorRepository repository,
  String title = 'Simpan ke Flashcard',
}) {
  return showModalBottomSheet<FlashcardTargetSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _FlashcardDeckPickerSheet(
      repository: repository,
      title: title,
    ),
  );
}

class _FlashcardDeckPickerSheet extends StatefulWidget {
  const _FlashcardDeckPickerSheet({
    required this.repository,
    required this.title,
  });

  final TutorRepository repository;
  final String title;

  @override
  State<_FlashcardDeckPickerSheet> createState() =>
      _FlashcardDeckPickerSheetState();
}

class _FlashcardDeckPickerSheetState extends State<_FlashcardDeckPickerSheet> {
  FlashcardDeck? _selectedDeck;
  bool _isCreating = false;

  Future<void> _handleCreateDeckInline() async {
    if (_isCreating) return;
    final input = await showFlashcardNamedInputDialog(
      context: context,
      title: 'Buat Deck Baru',
      nameLabel: 'Nama Deck',
      nameHint: 'Contoh: Business Word',
      showDescription: true,
      confirmLabel: 'Buat & Pilih',
    );
    if (input == null || !mounted) return;

    setState(() => _isCreating = true);
    try {
      final createdId = await widget.repository.createDeck(
        name: input.name,
        description: input.description,
      );
      final now = DateTime.now();
      if (!mounted) return;
      setState(() {
        _selectedDeck = FlashcardDeck(
          id: createdId,
          name: input.name,
          description: input.description,
          createdAt: now,
          updatedAt: now,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _handleCreateSubDeckInline(FlashcardDeck parentDeck) async {
    if (_isCreating) return;
    final input = await showFlashcardNamedInputDialog(
      context: context,
      title: 'Buat Sub-Deck di ${parentDeck.name}',
      nameLabel: 'Nama Sub-Deck',
      nameHint: 'Contoh: Business 1',
      confirmLabel: 'Buat & Pilih',
    );
    if (input == null || !mounted) return;

    setState(() => _isCreating = true);
    try {
      final createdSubDeckId = await widget.repository.createSubDeck(
        deckId: parentDeck.id,
        name: input.name,
        description: input.description,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        FlashcardTargetSelection(
          deckId: parentDeck.id,
          deckName: parentDeck.name,
          subDeckId: createdSubDeckId,
          subDeckName: input.name,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedDeck = _selectedDeck;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (selectedDeck != null)
                  IconButton(
                    tooltip: 'Kembali ke daftar Deck',
                    onPressed: () => setState(() => _selectedDeck = null),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedDeck == null
                            ? 'Langkah 1/2 • Pilih atau buat Deck'
                            : 'Langkah 2/2 • Pilih Sub-Deck di "${selectedDeck.name}"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedDeck == null) ...[
              OutlinedButton.icon(
                onPressed: _isCreating ? null : _handleCreateDeckInline,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('+ Buat Deck Baru'),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: StreamBuilder<List<DeckWithStats>>(
                  stream: widget.repository.watchDecksWithStats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final decks = snapshot.data ?? const <DeckWithStats>[];
                    if (decks.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Belum ada Deck flashcard.\nKetuk "+ Buat Deck Baru" di atas untuk memulai.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: decks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = decks[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              child: const Icon(Icons.folder_outlined),
                            ),
                            title: Text(
                              item.deck.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${item.subDeckCount} Sub-Deck • ${item.totalCardCount} Kata',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => setState(() => _selectedDeck = item.deck),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _isCreating
                    ? null
                    : () => _handleCreateSubDeckInline(selectedDeck),
                icon: const Icon(Icons.library_add_outlined),
                label: const Text('+ Buat Sub-Deck Baru'),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: StreamBuilder<List<SubDeckWithStats>>(
                  stream: widget.repository.watchSubDecksWithStats(
                    selectedDeck.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final subDecks =
                        snapshot.data ?? const <SubDeckWithStats>[];
                    if (subDecks.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Deck "${selectedDeck.name}" belum punya Sub-Deck.\nKetuk "+ Buat Sub-Deck Baru" untuk langsung memilih.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: subDecks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = subDecks[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.secondaryContainer,
                              foregroundColor: colorScheme.onSecondaryContainer,
                              child: const Icon(Icons.style_outlined),
                            ),
                            title: Text(
                              item.subDeck.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${item.cardCount} Kata'),
                            trailing: const Icon(Icons.check_circle_outline_rounded),
                            onTap: () => Navigator.of(context).pop(
                              FlashcardTargetSelection(
                                deckId: selectedDeck.id,
                                deckName: selectedDeck.name,
                                subDeckId: item.subDeck.id,
                                subDeckName: item.subDeck.name,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
