import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/local/daos/flashcard_dao.dart';
import '../../../data/services/tts_service.dart';

/// Displays a consistent Material 3 snackbar when an overlay context exists.
void showFlashcardSnackbar({
  required String title,
  required String message,
  bool isError = false,
}) {
  if (Get.overlayContext == null) return;
  try {
    final colorScheme = Get.theme.colorScheme;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: isError
          ? colorScheme.errorContainer
          : colorScheme.primaryContainer,
      colorText: isError
          ? colorScheme.onErrorContainer
          : colorScheme.onPrimaryContainer,
      duration: const Duration(seconds: 3),
    );
  } catch (_) {
    // Safe fallback during pure headless unit tests without Navigator overlay.
  }
}

/// Result returned from a Deck / Sub-Deck name + optional description dialog.
class FlashcardNamedInput {
  const FlashcardNamedInput({
    required this.name,
    this.description,
  });

  final String name;
  final String? description;
}

/// Result returned from the manual Add Word dialog in Level 3 Flashcards.
class FlashcardWordInput {
  const FlashcardWordInput({
    required this.word,
    required this.meaningId,
    this.wordType = 'non_verb',
  });

  final String word;
  final String meaningId;
  final String wordType;
}

/// Result returned from the Edit Flashcard dialog in Level 3 Flashcards.
class FlashcardEditInput {
  const FlashcardEditInput({
    required this.word,
    required this.phonetic,
    required this.meaningId,
    required this.partsOfSpeech,
  });

  final String word;
  final String phonetic;
  final String meaningId;
  final List<String> partsOfSpeech;
}

/// Opens a keyboard-safe dialog for creating or renaming a Deck or Sub-Deck.
Future<FlashcardNamedInput?> showFlashcardNamedInputDialog({
  required BuildContext context,
  required String title,
  required String nameLabel,
  required String nameHint,
  String initialName = '',
  String initialDescription = '',
  bool showDescription = false,
  String descriptionHint = 'Deskripsi singkat (opsional)',
  String confirmLabel = 'Simpan',
}) {
  return showDialog<FlashcardNamedInput>(
    context: context,
    builder: (_) => _FlashcardNamedInputDialog(
      title: title,
      nameLabel: nameLabel,
      nameHint: nameHint,
      initialName: initialName,
      initialDescription: initialDescription,
      showDescription: showDescription,
      descriptionHint: descriptionHint,
      confirmLabel: confirmLabel,
    ),
  );
}

/// Opens a confirmation dialog before deleting a Deck, Sub-Deck, or Flashcard.
Future<bool> showFlashcardConfirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      );
    },
  );
  return result == true;
}

/// Supported actions inside the bottom sheet on Deck and Sub-Deck cards.
enum FlashcardEntityAction {
  open,
  quiz,
  freeTalk,
  rename,
  delete,
}

/// Opens a shared ModalBottomSheet for either a Deck or a Sub-Deck.
Future<FlashcardEntityAction?> showFlashcardEntityActionsSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String openLabel,
  required IconData openIcon,
  bool showFreeTalkAction = false,
}) {
  return showModalBottomSheet<FlashcardEntityAction>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final colorScheme = theme.colorScheme;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(openIcon, color: colorScheme.primary),
                  title: Text(openLabel),
                  onTap: () => Navigator.of(sheetContext)
                      .pop(FlashcardEntityAction.open),
                ),
                ListTile(
                  leading: Icon(Icons.bolt_rounded, color: colorScheme.tertiary),
                  title: const Text('Mulai Tes'),
                  onTap: () => Navigator.of(sheetContext)
                      .pop(FlashcardEntityAction.quiz),
                ),
                if (showFreeTalkAction)
                  ListTile(
                    leading: Icon(
                      Icons.record_voice_over_rounded,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Free Talk dengan AI'),
                    subtitle: const Text(
                      'Latih kata sub-deck ini dalam percakapan live (maks. 10 kata)',
                    ),
                    onTap: () => Navigator.of(sheetContext)
                        .pop(FlashcardEntityAction.freeTalk),
                  ),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: colorScheme.secondary),
                  title: const Text('Ganti Nama'),
                  onTap: () => Navigator.of(sheetContext)
                      .pop(FlashcardEntityAction.rename),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                  title: Text(
                    'Hapus',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.of(sheetContext)
                      .pop(FlashcardEntityAction.delete),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Opens a modal dialog for manually adding a new English word to a Sub-Deck.
Future<FlashcardWordInput?> showFlashcardAddWordDialog({
  required BuildContext context,
}) {
  return showDialog<FlashcardWordInput>(
    context: context,
    builder: (_) => const _FlashcardAddWordDialog(),
  );
}

/// Opens a keyboard-safe dialog to edit an existing flashcard word and details.
Future<FlashcardEditInput?> showFlashcardEditWordDialog({
  required BuildContext context,
  required String initialWord,
  String initialPhonetic = '',
  String initialMeaningId = '',
  List<String> initialPartsOfSpeech = const <String>[],
}) {
  return showDialog<FlashcardEditInput>(
    context: context,
    builder: (_) => _FlashcardEditWordDialog(
      initialWord: initialWord,
      initialPhonetic: initialPhonetic,
      initialMeaningId: initialMeaningId,
      initialPartsOfSpeech: initialPartsOfSpeech,
    ),
  );
}

class _FlashcardNamedInputDialog extends StatefulWidget {
  const _FlashcardNamedInputDialog({
    required this.title,
    required this.nameLabel,
    required this.nameHint,
    required this.initialName,
    required this.initialDescription,
    required this.showDescription,
    required this.descriptionHint,
    required this.confirmLabel,
  });

  final String title;
  final String nameLabel;
  final String nameHint;
  final String initialName;
  final String initialDescription;
  final bool showDescription;
  final String descriptionHint;
  final String confirmLabel;

  @override
  State<_FlashcardNamedInputDialog> createState() =>
      _FlashcardNamedInputDialogState();
}

class _FlashcardNamedInputDialogState
    extends State<_FlashcardNamedInputDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      setState(() => _errorText = '${widget.nameLabel} wajib diisi.');
      return;
    }

    final desc = _descController.text.trim();
    Navigator.of(context).pop(
      FlashcardNamedInput(
        name: trimmedName,
        description: desc.isEmpty ? null : desc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: widget.showDescription
                  ? TextInputAction.next
                  : TextInputAction.done,
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onSubmitted: widget.showDescription ? null : (_) => _submit(),
              decoration: InputDecoration(
                labelText: widget.nameLabel,
                hintText: widget.nameHint,
                errorText: _errorText,
              ),
            ),
            if (widget.showDescription) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: widget.descriptionHint,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _FlashcardAddWordDialog extends StatefulWidget {
  const _FlashcardAddWordDialog();

  @override
  State<_FlashcardAddWordDialog> createState() =>
      _FlashcardAddWordDialogState();
}

class _FlashcardAddWordDialogState extends State<_FlashcardAddWordDialog> {
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  String? _wordError;

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmedWord = _wordController.text.trim();
    if (trimmedWord.isEmpty) {
      setState(() => _wordError = 'Kata bahasa Inggris wajib diisi.');
      return;
    }

    Navigator.of(context).pop(
      FlashcardWordInput(
        word: trimmedWord,
        meaningId: _meaningController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Kata Flashcard'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _wordController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_wordError != null) {
                  setState(() => _wordError = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Kata / Frasa Inggris *',
                hintText: 'Contoh: schedule',
                errorText: _wordError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _meaningController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Arti Bahasa Indonesia (opsional)',
                hintText: 'Contoh: jadwal / menjadwalkan',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Tambahkan'),
        ),
      ],
    );
  }
}

class _FlashcardEditWordDialog extends StatefulWidget {
  const _FlashcardEditWordDialog({
    required this.initialWord,
    required this.initialPhonetic,
    required this.initialMeaningId,
    required this.initialPartsOfSpeech,
  });

  final String initialWord;
  final String initialPhonetic;
  final String initialMeaningId;
  final List<String> initialPartsOfSpeech;

  @override
  State<_FlashcardEditWordDialog> createState() =>
      _FlashcardEditWordDialogState();
}

class _FlashcardEditWordDialogState extends State<_FlashcardEditWordDialog> {
  late final TextEditingController _wordController;
  late final TextEditingController _phoneticController;
  late final TextEditingController _meaningController;
  late final TextEditingController _posController;
  String? _wordError;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.initialWord);
    _phoneticController = TextEditingController(text: widget.initialPhonetic);
    _meaningController = TextEditingController(text: widget.initialMeaningId);
    _posController = TextEditingController(
      text: widget.initialPartsOfSpeech.join(', '),
    );
  }

  @override
  void dispose() {
    _wordController.dispose();
    _phoneticController.dispose();
    _meaningController.dispose();
    _posController.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmedWord = _wordController.text.trim();
    if (trimmedWord.isEmpty) {
      setState(() => _wordError = 'Kata / Frasa Inggris wajib diisi.');
      return;
    }

    final normalizedPos = FlashcardPosHelper.normalizePartsOfSpeech(
      _posController.text.split(','),
    );

    Navigator.of(context).pop(
      FlashcardEditInput(
        word: trimmedWord,
        phonetic: _phoneticController.text.trim(),
        meaningId: _meaningController.text.trim(),
        partsOfSpeech: normalizedPos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Flashcard'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _wordController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_wordError != null) {
                  setState(() => _wordError = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Kata / Frasa Inggris *',
                hintText: 'Contoh: schedule',
                errorText: _wordError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneticController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Fonetik IPA (opsional)',
                hintText: 'Contoh: /ˈskedʒ.uːl/',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _meaningController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Arti Bahasa Indonesia (opsional)',
                hintText: 'Contoh: jadwal / menjadwalkan',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _posController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Jenis Kata (opsional, pisah koma)',
                hintText: 'Contoh: Noun, Verb',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

/// Compact reactive pill indicating the active or most recent [TtsService] voice source.
class FlashcardVoiceSourceChip extends StatelessWidget {
  const FlashcardVoiceSourceChip({
    super.key,
    required this.ttsService,
  });

  final TtsService ttsService;

  void _showFallbackDiagnosticDialog(BuildContext context) {
    final detail = ttsService.lastFallbackDetail.value ??
        ttsService.lastFallbackReason.value ??
        'Menggunakan suara perangkat (offline/kuota habis).';
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Info Suara Offline (TTS)'),
          content: Text(detail),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final isLoading = ttsService.isLoadingAudio.value;
      final source = ttsService.activeVoiceSource.value;

      if (!isLoading && source.isEmpty) {
        return const SizedBox.shrink();
      }

      final String label;
      final IconData? iconData;
      final Color fgColor;
      final Color bgColor;
      final isOfflineFallback = !isLoading && source == 'offline_tts';

      if (isLoading) {
        label = 'Memuat suara AI...';
        iconData = null;
        fgColor = colorScheme.primary;
        bgColor = colorScheme.primaryContainer.withValues(alpha: 0.45);
      } else if (source == 'ai') {
        label = 'Suara AI';
        iconData = Icons.auto_awesome_rounded;
        fgColor = colorScheme.primary;
        bgColor = colorScheme.primaryContainer.withValues(alpha: 0.55);
      } else if (source == 'cache') {
        label = 'Suara AI (Cache)';
        iconData = Icons.bolt_rounded;
        fgColor = colorScheme.secondary;
        bgColor = colorScheme.secondaryContainer.withValues(alpha: 0.7);
      } else {
        label = 'Suara Offline (TTS)';
        iconData = Icons.record_voice_over_outlined;
        fgColor = colorScheme.onSurfaceVariant;
        bgColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.8);
      }

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isOfflineFallback
              ? () => _showFallbackDiagnosticDialog(context)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fgColor,
                    ),
                  )
                else
                  Icon(iconData, size: 14, color: fgColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isOfflineFallback) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: fgColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
