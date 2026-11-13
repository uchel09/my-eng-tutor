import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_state_widgets.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../controllers/flashcard_study_controller.dart';
import '../widgets/flashcard_dialogs.dart';
import '../widgets/sentence_pronunciation_sheet.dart';

class FlashcardStudyView extends GetView<FlashcardStudyController> {
  const FlashcardStudyView({super.key});

  Future<void> _openAddWordDialog(BuildContext context) async {
    final input = await showFlashcardAddWordDialog(context: context);
    if (input == null) return;
    await controller.addWord(
      word: input.word,
      meaningId: input.meaningId,
      wordType: input.wordType,
    );
  }

  Future<void> _confirmDeleteCard(BuildContext context, Flashcard card) async {
    final confirmed = await showFlashcardConfirmDeleteDialog(
      context: context,
      title: 'Hapus Kata "${card.word}"?',
      message: 'Kartu beserta contoh kalimatnya akan dihapus dari sub-deck ini.',
    );
    if (confirmed) {
      await controller.deleteWord(card);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.subDeckTitle,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              controller.deckName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: controller.subDeck == null
                  ? null
                  : () => _openAddWordDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Kata'),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingView(message: 'Memuat kartu flashcard...');
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return AppErrorView(
            message: error,
            onRetry: controller.subDeck == null ? null : controller.retryLoad,
          );
        }

        if (controller.cards.isEmpty) {
          return AppEmptyView(
            icon: Icons.style_outlined,
            title: 'Sub-Deck Masih Kosong',
            subtitle:
                'Tambahkan kata bahasa Inggris pertama ke "${controller.subDeckTitle}" lalu lengkapi contoh & suaranya dengan AI.',
            actionLabel: '+ Tambah Kata',
            onAction: () => _openAddWordDialog(context),
          );
        }

        final studyMode = controller.isStudyMode.value;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          icon: Icon(Icons.style_outlined, size: 18),
                          label: Text('Belajar'),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          icon: Icon(Icons.view_list_rounded, size: 18),
                          label: Text('Daftar'),
                        ),
                      ],
                      selected: <bool>{studyMode},
                      onSelectionChanged: (selection) {
                        if (selection.isEmpty) return;
                        controller.setStudyMode(selection.first);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _openAddWordDialog(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: studyMode
                  ? _StudyDetailPanel(
                      controller: controller,
                      onDeleteCard: (card) => _confirmDeleteCard(context, card),
                    )
                  : _CardsListPanel(
                      controller: controller,
                      onDeleteCard: (card) => _confirmDeleteCard(context, card),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _CardsListPanel extends StatelessWidget {
  const _CardsListPanel({
    required this.controller,
    required this.onDeleteCard,
  });

  final FlashcardStudyController controller;
  final ValueChanged<Flashcard> onDeleteCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final cards = controller.cards;
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final card = cards[index];
          final wordType = controller.effectiveWordType(card);
          final phonetic = controller.effectivePhonetic(card);
          final meaning = controller.effectiveMeaningId(card);
          final hasUnsaved = controller.hasUnsavedChanges(card.id);

          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => controller.selectCardAndStudy(index),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                card.word,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (phonetic.isNotEmpty)
                                Text(
                                  phonetic,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              _WordTypeChip(wordType: wordType),
                              if (hasUnsaved)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Draft',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meaning.isNotEmpty
                                ? meaning
                                : 'Arti belum diisi — ketuk untuk lengkapi dengan AI',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: meaning.isNotEmpty
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: meaning.isNotEmpty
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(() {
                      final speaking = controller.ttsService.isSpeaking.value &&
                          controller.ttsService.activeText.value ==
                              card.word.trim();
                      return IconButton(
                        tooltip: 'Dengarkan pelafalan',
                        onPressed: () => controller.toggleSpeak(card.word),
                        icon: Icon(
                          speaking
                              ? Icons.graphic_eq_rounded
                              : Icons.volume_up_rounded,
                          color: speaking
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      );
                    }),
                    IconButton(
                      tooltip: 'Hapus kata',
                      onPressed: () => onDeleteCard(card),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _StudyDetailPanel extends StatelessWidget {
  const _StudyDetailPanel({
    required this.controller,
    required this.onDeleteCard,
  });

  final FlashcardStudyController controller;
  final ValueChanged<Flashcard> onDeleteCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final card = controller.activeCard;
      if (card == null) return const SizedBox.shrink();

      final total = controller.cards.length;
      final currentNumber = controller.activeIndex.value + 1;
      final isFlipped = controller.isCardFlipped.value;
      final wordType = controller.effectiveWordType(card);
      final phonetic = controller.effectivePhonetic(card);
      final meaning = controller.effectiveMeaningId(card);
      final examples = controller.effectiveExamples(card);
      final conversation = controller.effectiveConversation(card);
      final hasUnsaved = controller.hasUnsavedChanges(card.id);
      final isGenerating = controller.isGeneratingAi.value;
      final isSaving = controller.isSavingDraft.value;
      final all16Tenses = controller.includeAll16TensesFor(card.id);
      final aiError = controller.aiErrorMessage.value;

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Row(
            children: [
              IconButton.outlined(
                tooltip: 'Kartu sebelumnya',
                onPressed: currentNumber > 1 ? controller.previousCard : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Kartu $currentNumber dari $total',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Kartu berikutnya',
                onPressed: currentNumber < total ? controller.nextCard : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Hapus kartu ini',
                onPressed: () => onDeleteCard(card),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FlipFlashcardTile(
            card: card,
            wordType: wordType,
            phonetic: phonetic,
            meaningId: meaning,
            isFlipped: isFlipped,
            controller: controller,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Latihan AI & Kalimat',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _SaveStatusPill(
                        hasUnsaved: hasUnsaved,
                        hasContent:
                            examples.isNotEmpty || conversation.isNotEmpty,
                      ),
                    ],
                  ),
                  if (aiError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aiError,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (wordType == 'verb') ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile.adaptive(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        value: all16Tenses,
                        onChanged: isGenerating
                            ? null
                            : (val) => controller.setIncludeAll16Tenses(
                                  card.id,
                                  val,
                                ),
                        title: const Text(
                          'Gunakan Semua 16 Tenses',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          all16Tenses
                              ? 'AI akan membuat lengkap 16 kalimat lintas tenses saat Generate.'
                              : 'Mode ringkas: minimal 5 kalimat variasi tenses.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: isGenerating
                            ? null
                            : () => controller.generateAiContent(card),
                        icon: isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          examples.isEmpty && conversation.isEmpty
                              ? 'Lengkapi dengan AI'
                              : 'Generate AI',
                        ),
                      ),
                      if (examples.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: isGenerating
                              ? null
                              : () => controller.replaceExamples(card),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Ganti Latihan Kalimat'),
                        ),
                      FilledButton.tonalIcon(
                        onPressed: (!hasUnsaved || isSaving || isGenerating)
                            ? null
                            : () => controller.saveDraftToDatabase(card),
                        icon: Icon(
                          hasUnsaved
                              ? Icons.save_outlined
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(hasUnsaved ? 'Simpan' : 'Tersimpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FlashcardVoiceSourceChip(ttsService: controller.ttsService),
          ),
          const SizedBox(height: 12),
          _ExamplesSection(
            examples: examples,
            wordType: wordType,
            controller: controller,
          ),
          if (conversation.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _MiniConversationCard(
              conversation: conversation,
              controller: controller,
            ),
          ],
        ],
      );
    });
  }
}

class _FlipFlashcardTile extends StatelessWidget {
  const _FlipFlashcardTile({
    required this.card,
    required this.wordType,
    required this.phonetic,
    required this.meaningId,
    required this.isFlipped,
    required this.controller,
  });

  final Flashcard card;
  final String wordType;
  final String phonetic;
  final String meaningId;
  final bool isFlipped;
  final FlashcardStudyController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isFlipped
          ? colorScheme.secondaryContainer.withValues(alpha: 0.45)
          : colorScheme.primaryContainer.withValues(alpha: 0.38),
      child: InkWell(
        onTap: controller.toggleFlip,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _WordTypeChip(wordType: wordType),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Mastery ${card.masteryLevel}/5',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    final target = card.word.trim();
                    final isTarget = target.isNotEmpty &&
                        controller.ttsService.activeText.value == target;
                    final loading =
                        isTarget && controller.ttsService.isLoadingAudio.value;
                    final speaking = isTarget &&
                        !loading &&
                        controller.ttsService.isSpeaking.value;
                    return IconButton.filledTonal(
                      tooltip: 'Putar suara kata',
                      onPressed: () => controller.toggleSpeak(card.word),
                      iconSize: 26,
                      icon: loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(
                              speaking
                                  ? Icons.graphic_eq_rounded
                                  : Icons.volume_up_rounded,
                              color: speaking
                                  ? colorScheme.primary
                                  : colorScheme.onSecondaryContainer,
                            ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: isFlipped
                    ? Column(
                        key: ValueKey<String>('back_${card.id}'),
                        children: [
                          Text(
                            card.word,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            meaningId.trim().isNotEmpty
                                ? meaningId.trim()
                                : 'Arti bahasa Indonesia belum tersedia. Ketuk "Lengkapi dengan AI" di bawah.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: meaningId.trim().isNotEmpty
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (card.reviewCount > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Direview ${card.reviewCount}x',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Column(
                        key: ValueKey<String>('front_${card.id}'),
                        children: [
                          Text(
                            card.word,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (phonetic.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              phonetic.trim(),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      isFlipped
                          ? 'Ketuk kartu untuk melihat kata'
                          : 'Ketuk kartu untuk balik & lihat arti',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamplesSection extends StatelessWidget {
  const _ExamplesSection({
    required this.examples,
    required this.wordType,
    required this.controller,
  });

  final List<FlashcardExampleItem> examples;
  final String wordType;
  final FlashcardStudyController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote_rounded, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contoh Kalimat (${examples.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  wordType == 'verb' ? 'Tenses' : 'Kontekstual',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (examples.isEmpty)
              Text(
                'Belum ada contoh kalimat. Tekan "Lengkapi dengan AI" di atas untuk membuat kalimat & audio pengucapan.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: examples.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = examples[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (item.tense.trim().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.tense.trim(),
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color:
                                              colorScheme.onSecondaryContainer,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  Obx(() {
                                    final bestScore =
                                        controller.bestScoreForSentence(
                                      item.en,
                                    );
                                    if (bestScore == null) {
                                      return const SizedBox.shrink();
                                    }
                                    final isStrong = bestScore >= 80;
                                    final badgeColor = isStrong
                                        ? const Color(0xFF16A34A)
                                        : colorScheme.primary;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            badgeColor.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color:
                                              badgeColor.withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Text(
                                        '$bestScore%',
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color: badgeColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Obx(() {
                                    final target = item.en.trim();
                                    final isTarget = target.isNotEmpty &&
                                        controller.ttsService.activeText.value ==
                                            target;
                                    final loading = isTarget &&
                                        controller
                                            .ttsService.isLoadingAudio.value;
                                    final speaking = isTarget &&
                                        !loading &&
                                        controller.ttsService.isSpeaking.value;
                                    return IconButton(
                                      tooltip: 'Dengarkan kalimat',
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () =>
                                          controller.toggleSpeak(item.en),
                                      icon: loading
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colorScheme.primary,
                                              ),
                                            )
                                          : Icon(
                                              speaking
                                                  ? Icons.graphic_eq_rounded
                                                  : Icons.volume_up_outlined,
                                              size: 20,
                                              color: speaking
                                                  ? colorScheme.primary
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                    );
                                  }),
                                  const SizedBox(width: 4),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      unawaited(
                                        showSentencePronunciationSheet(
                                          context: context,
                                          sentence: item.en,
                                          meaningId: item.id,
                                          targetWord:
                                              controller.activeCard?.word,
                                          repository: controller.repository,
                                          ttsService: controller.ttsService,
                                          audioService:
                                              controller.resolvedAudioService,
                                          onEvaluated: (score) => controller
                                              .recordSentencePracticeScore(
                                            item.en,
                                            score,
                                          ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(
                                      Icons.mic_none_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Practice'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.en,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item.id.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.id.trim(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniConversationCard extends StatelessWidget {
  const _MiniConversationCard({
    required this.conversation,
    required this.controller,
  });

  final String conversation;
  final FlashcardStudyController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spokenSegment = controller.extractEnglishConversation(conversation);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.forum_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mini Conversation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Obx(() {
                  final target = spokenSegment.trim();
                  final isTarget = target.isNotEmpty &&
                      controller.ttsService.activeText.value == target;
                  final loading =
                      isTarget && controller.ttsService.isLoadingAudio.value;
                  final speaking = isTarget &&
                      !loading &&
                      controller.ttsService.isSpeaking.value;
                  return IconButton.filledTonal(
                    tooltip: 'Dengarkan percakapan',
                    onPressed: () => controller.toggleSpeak(spokenSegment),
                    icon: loading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(
                            speaking
                                ? Icons.graphic_eq_rounded
                                : Icons.volume_up_rounded,
                          ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              conversation.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordTypeChip extends StatelessWidget {
  const _WordTypeChip({required this.wordType});

  final String wordType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isVerb = wordType == 'verb';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerb
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isVerb ? 'Verb' : 'Non-Verb',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isVerb
              ? colorScheme.onTertiaryContainer
              : colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SaveStatusPill extends StatelessWidget {
  const _SaveStatusPill({
    required this.hasUnsaved,
    required this.hasContent,
  });

  final bool hasUnsaved;
  final bool hasContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (hasUnsaved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Belum disimpan',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onTertiaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (hasContent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Tersimpan',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
