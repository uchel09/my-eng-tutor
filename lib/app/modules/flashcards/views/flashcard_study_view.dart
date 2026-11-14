import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_state_widgets.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/flashcard_dao.dart';
import '../controllers/flashcard_study_controller.dart';
import '../widgets/flashcard_dialogs.dart';
import '../widgets/flashcard_freetalk_sheet.dart';
import '../widgets/flashcard_progress_circle.dart';
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

  Future<void> _openEditWordDialog(BuildContext context, Flashcard card) async {
    final input = await showFlashcardEditWordDialog(
      context: context,
      initialWord: card.word,
      initialPhonetic: controller.effectivePhonetic(card),
      initialMeaningId: controller.effectiveMeaningId(card),
      initialPartsOfSpeech: controller.effectivePartsOfSpeech(card),
    );
    if (input == null) return;
    await controller.editWord(
      card,
      word: input.word,
      phonetic: input.phonetic,
      meaningId: input.meaningId,
      partsOfSpeech: input.partsOfSpeech,
    );
  }

  Future<void> _confirmDeleteCard(BuildContext context, Flashcard card) async {
    final confirmed = await showFlashcardConfirmDeleteDialog(
      context: context,
      title: 'Hapus Kata "${card.word}"?',
      message:
          'Kartu beserta contoh kalimatnya akan dihapus dari sub-deck ini.',
    );
    if (confirmed) {
      await controller.deleteWord(card);
    }
  }

  Future<void> _openFreeTalkSheet(BuildContext context) async {
    final subDeck = controller.subDeck;
    if (subDeck == null) return;
    if (controller.cards.isEmpty) {
      showFlashcardSnackbar(
        title: 'Sub-Deck Kosong',
        message: "Tambahkan kata terlebih dahulu sebelum memulai Free Talk.",
        isError: true,
      );
      return;
    }
    final selection = await showFlashcardSubDeckFreeTalkSheet(
      context: context,
      repository: controller.repository,
      fixedSubDeck: subDeck,
      fixedDeckName: controller.deckName,
    );
    if (selection != null) {
      controller.startSubDeckFreeTalk(selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(controller.subDeckTitle, overflow: TextOverflow.ellipsis),
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
          Obx(
            () => TextButton.icon(
              onPressed: controller.subDeck == null || controller.cards.isEmpty
                  ? null
                  : () => _openFreeTalkSheet(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.record_voice_over_rounded, size: 18),
              label: const Text('Free Talk'),
            ),
          ),
          IconButton(
            tooltip: 'Tambah Kata',
            onPressed: controller.subDeck == null
                ? null
                : () => _openAddWordDialog(context),
            icon: const Icon(Icons.add_rounded),
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
            _SubDeckStudySummaryStrip(controller: controller),
            Expanded(
              child: studyMode
                  ? _StudyDetailPanel(
                      controller: controller,
                      onEditCard: (card) => _openEditWordDialog(context, card),
                      onDeleteCard: (card) => _confirmDeleteCard(context, card),
                    )
                  : _CardsListPanel(
                      controller: controller,
                      onEditCard: (card) => _openEditWordDialog(context, card),
                      onDeleteCard: (card) => _confirmDeleteCard(context, card),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _SubDeckStudySummaryStrip extends StatelessWidget {
  const _SubDeckStudySummaryStrip({required this.controller});

  final FlashcardStudyController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final total = controller.cards.length;
      final mastered = controller.masteredCount;
      final needsReview = controller.needsReviewCount;
      final unstudied = controller.unstudiedCount;
      final percent = controller.progressPercent;
      final barColor = FlashcardProgressCircle.colorForProgress(
        percent,
        total > 0,
        colorScheme,
      );
      final textColor = FlashcardProgressCircle.textColorForProgress(
        percent,
        total > 0,
        colorScheme,
      );

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '$percent% Hafal',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$mastered/$total Hafal • $needsReview Ulang • $unstudied Belum',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0.0 : mastered / total,
                minHeight: 5,
                backgroundColor: colorScheme.outlineVariant.withValues(
                  alpha: 0.3,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CardsListPanel extends StatelessWidget {
  const _CardsListPanel({
    required this.controller,
    required this.onEditCard,
    required this.onDeleteCard,
  });

  final FlashcardStudyController controller;
  final ValueChanged<Flashcard> onEditCard;
  final ValueChanged<Flashcard> onDeleteCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final activePosFilter = controller.selectedPosFilter.value;
      final activeStatusFilter = controller.selectedStudyStatusFilter.value;
      final cards = controller.filteredCards;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final option
                      in FlashcardStudyController.studyStatusFilterOptions)
                    FilterChip(
                      label: Text(option),
                      selected: option == activeStatusFilter,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (_) =>
                          controller.setStudyStatusFilter(option),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              itemCount: FlashcardStudyController.posFilterOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, chipIdx) {
                final option =
                    FlashcardStudyController.posFilterOptions[chipIdx];
                final selected = option == activePosFilter;
                return FilterChip(
                  label: Text(option),
                  selected: selected,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) => controller.setPosFilter(option),
                );
              },
            ),
          ),
          Expanded(
            child: cards.isEmpty
                ? _FilteredCardsEmptyState(
                    posFilter: activePosFilter,
                    statusFilter: activeStatusFilter,
                    onReset: controller.resetFilters,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final phonetic = controller.effectivePhonetic(card);
                      final meaning = controller.effectiveMeaningId(card);
                      final posList = controller.effectivePartsOfSpeech(card);
                      final hasUnsaved =
                          controller.hasUnsavedChanges(card.id);

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () =>
                              controller.selectCardByIdAndStudy(card.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            card.word,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (phonetic.isNotEmpty)
                                            Text(
                                              phonetic,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color:
                                                    colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          _CardStudyStatusQuickMenu(
                                            studyStatus: card.studyStatus,
                                            onSelected: (status) => controller
                                                .setCardStudyStatus(
                                                  card,
                                                  status,
                                                ),
                                          ),
                                          if (hasUnsaved)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .tertiaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Draft',
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: colorScheme
                                                      .onTertiaryContainer,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      if (posList.isNotEmpty) ...[
                                        Text(
                                          posList.join(' • '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: colorScheme.secondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        meaning.isNotEmpty
                                            ? meaning
                                            : 'Arti belum diisi — ketuk untuk lengkapi dengan AI',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
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
                                  final speaking =
                                      controller.ttsService.isSpeaking.value &&
                                      controller.ttsService.activeText.value ==
                                          card.word.trim();
                                  return IconButton(
                                    tooltip: 'Dengarkan pelafalan',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    onPressed: () =>
                                        controller.toggleSpeak(card.word),
                                    icon: Icon(
                                      speaking
                                          ? Icons.graphic_eq_rounded
                                          : Icons.volume_up_rounded,
                                      size: 20,
                                      color: speaking
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                }),
                                IconButton(
                                  tooltip: 'Edit kata',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  onPressed: () => onEditCard(card),
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hapus kata',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  onPressed: () => onDeleteCard(card),
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}

class _StudyDetailPanel extends StatelessWidget {
  const _StudyDetailPanel({
    required this.controller,
    required this.onEditCard,
    required this.onDeleteCard,
  });

  final FlashcardStudyController controller;
  final ValueChanged<Flashcard> onEditCard;
  final ValueChanged<Flashcard> onDeleteCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final activePosFilter = controller.selectedPosFilter.value;
      final activeStatusFilter = controller.selectedStudyStatusFilter.value;
      final visibleCards = controller.filteredCards;
      final card = controller.activeCard;
      if (card == null) {
        return _FilteredCardsEmptyState(
          posFilter: activePosFilter,
          statusFilter: activeStatusFilter,
          onReset: controller.resetFilters,
        );
      }

      final total = visibleCards.length;
      final safeIdx = controller.activeIndex.value.clamp(0, total - 1);
      final currentNumber = safeIdx + 1;
      final isFlipped = controller.isCardFlipped.value;
      final phonetic = controller.effectivePhonetic(card);
      final meaning = controller.effectiveMeaningId(card);
      final partsOfSpeech = controller.effectivePartsOfSpeech(card);
      final isHybrid = controller.isHybridVerbCard(card);
      final isVerb16Enabled = controller.isVerb16TensesEnabled(card);
      final activeTab = controller.activeExampleTabFor(card.id);
      final examples = controller.effectiveExamples(card);
      final verb16Examples = controller.effectiveVerb16TensesExamples(card);
      final conversation = controller.effectiveConversation(card);
      final hasUnsaved = controller.hasUnsavedChanges(card.id);
      final hasAnyContent = controller.hasAnyContent(card);
      final isGenerating = controller.isGeneratingAi.value;
      final isSaving = controller.isSavingDraft.value;
      final aiError = controller.aiErrorMessage.value;
      final showReplaceButton = isHybrid
          ? (activeTab == 1 ? verb16Examples.isNotEmpty : examples.isNotEmpty)
          : examples.isNotEmpty;

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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                tooltip: 'Edit kartu ini',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => onEditCard(card),
                icon: Icon(
                  Icons.edit_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip: 'Hapus kartu ini',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
            phonetic: phonetic,
            meaningId: meaning,
            partsOfSpeech: partsOfSpeech,
            isFlipped: isFlipped,
            controller: controller,
          ),
          const SizedBox(height: 10),
          _StudyStatusSelectorBar(
            studyStatus: card.studyStatus,
            onSelectStatus: (status) =>
                controller.setCardStudyStatus(card, status),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: colorScheme.primary,
                      ),
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
                        hasContent: hasAnyContent,
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
                          !hasAnyContent ? 'Lengkapi dengan AI' : 'Generate AI',
                        ),
                      ),
                      if (showReplaceButton)
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
            card: card,
            examples: examples,
            verb16Examples: verb16Examples,
            isVerb16Enabled: isVerb16Enabled,
            isGenerating: isGenerating,
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
    required this.phonetic,
    required this.meaningId,
    required this.partsOfSpeech,
    required this.isFlipped,
    required this.controller,
  });

  final Flashcard card;
  final String phonetic;
  final String meaningId;
  final List<String> partsOfSpeech;
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
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
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
                        if (partsOfSpeech.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(
                                alpha: 0.65,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Jenis kata dideteksi saat Lengkapi dengan AI',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          for (final pos in partsOfSpeech)
                            _PosBadgeChip(
                              label: pos,
                              isVerb: FlashcardPosHelper.isVerbPos(pos),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    final target = card.word.trim();
                    final isTarget =
                        target.isNotEmpty &&
                        controller.ttsService.activeText.value == target;
                    final loading =
                        isTarget && controller.ttsService.isLoadingAudio.value;
                    final speaking =
                        isTarget &&
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

class _PosBadgeChip extends StatelessWidget {
  const _PosBadgeChip({required this.label, required this.isVerb});

  final String label;
  final bool isVerb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = isVerb
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final fgColor = isVerb
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fgColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExamplesSection extends StatelessWidget {
  const _ExamplesSection({
    required this.card,
    required this.examples,
    required this.verb16Examples,
    required this.isVerb16Enabled,
    required this.isGenerating,
    required this.controller,
  });

  final Flashcard card;
  final List<FlashcardExampleItem> examples;
  final List<FlashcardExampleItem> verb16Examples;
  final bool isVerb16Enabled;
  final bool isGenerating;
  final FlashcardStudyController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nonVerbParts = controller.nonVerbPartsFor(card);
    final isHybrid = controller.isHybridVerbCard(card);
    final isPureVerb = controller.isPureVerbCard(card);
    final activeTab = isHybrid ? controller.activeExampleTabFor(card.id) : 0;

    final displayedExamples = (isHybrid && activeTab == 1)
        ? (isVerb16Enabled ? verb16Examples : const <FlashcardExampleItem>[])
        : examples;

    final headerModeLabel = isHybrid
        ? (activeTab == 1 ? 'Verb • 16 Tenses' : nonVerbParts.join(' • '))
        : (displayedExamples.length >= 16 ? '16 Tenses' : 'Kontekstual');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote_rounded, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contoh Kalimat (${displayedExamples.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (displayedExamples.isNotEmpty)
                  Flexible(
                    child: Text(
                      headerModeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            if (isPureVerb) ...[
              const SizedBox(height: 10),
              _Verb16TensesSwitchCard(
                title: 'Gunakan Semua 16 Tenses',
                subtitle: isVerb16Enabled
                    ? 'Menampilkan 16 kalimat lintas seluruh English tenses.'
                    : 'Mode ringkas: contoh kalimat Verb sehari-hari (5 kalimat).',
                value: isVerb16Enabled,
                enabled: !isGenerating,
                onChanged: (val) =>
                    controller.setVerb16TensesEnabled(card, val),
              ),
            ] else if (isHybrid) ...[
              const SizedBox(height: 10),
              _HybridExampleTabSelector(
                tab1Label: examples.isNotEmpty
                    ? '${nonVerbParts.join(' • ')} (${examples.length})'
                    : nonVerbParts.join(' • '),
                tab2Label: verb16Examples.isNotEmpty
                    ? '16 Tenses (Verb) (${verb16Examples.length})'
                    : '16 Tenses (Verb)',
                activeIndex: activeTab,
                onSelect: (index) =>
                    controller.setActiveExampleTab(card.id, index),
              ),
              if (activeTab == 1) ...[
                const SizedBox(height: 10),
                if (!isVerb16Enabled || verb16Examples.isEmpty)
                  _HybridVerb16InviteCard(
                    word: card.word,
                    nonVerbLabel: nonVerbParts.join(' • '),
                    hasExisting16: verb16Examples.isNotEmpty,
                    isGenerating: isGenerating,
                    onActivate: () =>
                        controller.setVerb16TensesEnabled(card, true),
                  )
                else
                  _Verb16TensesSwitchCard(
                    title: '16 Tenses (Verb) Aktif',
                    subtitle:
                        'Matikan sementara jika ingin menyembunyikan tanpa menghapus.',
                    value: true,
                    enabled: !isGenerating,
                    onChanged: (val) =>
                        controller.setVerb16TensesEnabled(card, val),
                  ),
              ],
            ],
            const SizedBox(height: 10),
            if (isHybrid &&
                activeTab == 1 &&
                (!isVerb16Enabled || verb16Examples.isEmpty))
              const SizedBox.shrink()
            else if (displayedExamples.isEmpty)
              Text(
                'Belum ada contoh kalimat. Tekan "Lengkapi dengan AI" di atas untuk membuat kalimat & audio pengucapan.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < displayedExamples.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _ExampleSentenceTile(
                      item: displayedExamples[i],
                      controller: controller,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Verb16TensesSwitchCard extends StatelessWidget {
  const _Verb16TensesSwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      ),
    );
  }
}

class _HybridExampleTabSelector extends StatelessWidget {
  const _HybridExampleTabSelector({
    required this.tab1Label,
    required this.tab2Label,
    required this.activeIndex,
    required this.onSelect,
  });

  final String tab1Label;
  final String tab2Label;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildTab({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: selected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          buildTab(
            label: tab1Label,
            selected: activeIndex == 0,
            onTap: () => onSelect(0),
          ),
          const SizedBox(width: 4),
          buildTab(
            label: tab2Label,
            selected: activeIndex == 1,
            onTap: () => onSelect(1),
          ),
        ],
      ),
    );
  }
}

class _HybridVerb16InviteCard extends StatelessWidget {
  const _HybridVerb16InviteCard({
    required this.word,
    required this.nonVerbLabel,
    required this.hasExisting16,
    required this.isGenerating,
    required this.onActivate,
  });

  final String word;
  final String nonVerbLabel;
  final bool hasExisting16;
  final bool isGenerating;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasExisting16
                ? '16 Tenses (Verb) untuk "$word" sudah siap di memori/kartu.'
                : 'Buat 16 kalimat khusus fungsi Verb untuk "$word" di seluruh 16 English tenses. Kalimat di tab $nonVerbLabel tidak akan tertimpa.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: isGenerating ? null : onActivate,
            icon: isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              hasExisting16
                  ? 'Tampilkan 16 Tenses (Verb)'
                  : 'Aktifkan & Generate 16 Tenses (Verb)',
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleSentenceTile extends StatelessWidget {
  const _ExampleSentenceTile({required this.item, required this.controller});

  final FlashcardExampleItem item;
  final FlashcardStudyController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trimmedPos = item.pos.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
                    if (trimmedPos.isNotEmpty)
                      _PosBadgeChip(
                        label: trimmedPos,
                        isVerb: FlashcardPosHelper.isVerbPos(trimmedPos),
                      ),
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
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Obx(() {
                      final bestScore = controller.bestScoreForSentence(
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
                          color: badgeColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          '$bestScore%',
                          style: theme.textTheme.labelSmall?.copyWith(
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
                      final isTarget =
                          target.isNotEmpty &&
                          controller.ttsService.activeText.value == target;
                      final loading =
                          isTarget &&
                          controller.ttsService.isLoadingAudio.value;
                      final speaking =
                          isTarget &&
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
                        onPressed: () => controller.toggleSpeak(item.en),
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
                                    : colorScheme.onSurfaceVariant,
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
                            targetWord: controller.activeCard?.word,
                            repository: controller.repository,
                            ttsService: controller.ttsService,
                            audioService: controller.resolvedAudioService,
                            onEvaluated: (score) => controller
                                .recordSentencePracticeScore(item.en, score),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.mic_none_rounded, size: 16),
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
                  final isTarget =
                      target.isNotEmpty &&
                      controller.ttsService.activeText.value == target;
                  final loading =
                      isTarget && controller.ttsService.isLoadingAudio.value;
                  final speaking =
                      isTarget &&
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

class _SaveStatusPill extends StatelessWidget {
  const _SaveStatusPill({required this.hasUnsaved, required this.hasContent});

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

class _StudyStatusVisual {
  const _StudyStatusVisual({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
}

_StudyStatusVisual _studyStatusVisual(int status, ThemeData theme) {
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  switch (FlashcardStudyStatus.clamp(status)) {
    case FlashcardStudyStatus.needsReview:
      final accent = isDark ? Colors.amber.shade300 : Colors.amber.shade800;
      return _StudyStatusVisual(
        label: 'Perlu Ulang',
        icon: Icons.refresh_rounded,
        foreground: accent,
        background: Colors.amber.shade700.withValues(alpha: 0.16),
        border: Colors.amber.shade700,
      );
    case FlashcardStudyStatus.mastered:
      final accent = isDark ? Colors.green.shade300 : Colors.green.shade700;
      return _StudyStatusVisual(
        label: 'Hafal',
        icon: Icons.check_circle_rounded,
        foreground: accent,
        background: Colors.green.shade600.withValues(alpha: 0.16),
        border: Colors.green.shade600,
      );
    case FlashcardStudyStatus.unstudied:
    default:
      return _StudyStatusVisual(
        label: 'Belum',
        icon: Icons.radio_button_unchecked_rounded,
        foreground: colorScheme.onSurfaceVariant,
        background: colorScheme.surfaceContainerHighest,
        border: colorScheme.outline,
      );
  }
}

class _StudyStatusSelectorBar extends StatelessWidget {
  const _StudyStatusSelectorBar({
    required this.studyStatus,
    required this.onSelectStatus,
  });

  final int studyStatus;
  final ValueChanged<int> onSelectStatus;

  static const List<int> _statuses = <int>[
    FlashcardStudyStatus.unstudied,
    FlashcardStudyStatus.needsReview,
    FlashcardStudyStatus.mastered,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeStatus = FlashcardStudyStatus.clamp(studyStatus);

    return Row(
      children: [
        for (var i = 0; i < _statuses.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                final option = _statuses[i];
                final visual = _studyStatusVisual(option, theme);
                final selected = activeStatus == option;
                return Material(
                  color: selected
                      ? visual.background
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelectStatus(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? visual.border
                              : colorScheme.outlineVariant,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            visual.icon,
                            size: 16,
                            color: selected
                                ? visual.foreground
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              visual.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: selected
                                    ? visual.foreground
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _CardStudyStatusQuickMenu extends StatelessWidget {
  const _CardStudyStatusQuickMenu({
    required this.studyStatus,
    required this.onSelected,
  });

  final int studyStatus;
  final ValueChanged<int> onSelected;

  static const List<int> _statuses = <int>[
    FlashcardStudyStatus.unstudied,
    FlashcardStudyStatus.needsReview,
    FlashcardStudyStatus.mastered,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _studyStatusVisual(studyStatus, theme);

    return PopupMenuButton<int>(
      tooltip: 'Ubah status belajar',
      initialValue: FlashcardStudyStatus.clamp(studyStatus),
      onSelected: onSelected,
      itemBuilder: (context) {
        return _statuses.map((option) {
          final itemVisual = _studyStatusVisual(option, theme);
          return PopupMenuItem<int>(
            value: option,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(itemVisual.icon, size: 18, color: itemVisual.foreground),
                const SizedBox(width: 8),
                Text(itemVisual.label),
              ],
            ),
          );
        }).toList(growable: false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: visual.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: visual.border.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(visual.icon, size: 13, color: visual.foreground),
            const SizedBox(width: 4),
            Text(
              visual.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: visual.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: visual.foreground,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilteredCardsEmptyState extends StatelessWidget {
  const _FilteredCardsEmptyState({
    required this.posFilter,
    required this.statusFilter,
    required this.onReset,
  });

  final String posFilter;
  final String statusFilter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parts = <String>[
      if (statusFilter != 'Semua') 'status "$statusFilter"',
      if (posFilter != 'Semua') 'jenis kata "$posFilter"',
    ];
    final criteria = parts.isEmpty
        ? 'filter aktif'
        : parts.join(' dan ');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_off_rounded,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada kartu dengan $criteria di sub-deck ini.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onReset,
              child: const Text('Tampilkan Semua'),
            ),
          ],
        ),
      ),
    );
  }
}
