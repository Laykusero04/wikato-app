import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../components/primary_button.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../models/phrase.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/phrase_card.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openSaveSheet(Phrase phrase) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SavePhraseSheet(phrase: phrase),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ContentRepository.findLesson(widget.lessonId);
    if (lesson == null) {
      return const AppScaffold(
        title: 'Lesson not found',
        child: Center(child: Text('No such lesson.')),
      );
    }
    final phrases = ContentRepository.phrasesForLesson(lesson);

    final theme = Theme.of(context);
    return AppScaffold(
      title: lesson.title,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              '${_index + 1} of ${phrases.length}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: phrases.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final phrase = phrases[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.md,
                  ),
                  child: ValueListenableBuilder<Set<String>>(
                    valueListenable: ProgressStore.savedPhraseIds,
                    builder: (context, saved, _) => PhraseCard(
                      original: phrase.native,
                      translation: phrase.english,
                      pronunciation: phrase.romanization,
                      isSaved: saved.contains(phrase.id),
                      onSave: () => _openSaveSheet(phrase),
                      onPlay: () => HapticFeedback.lightImpact(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Try translation exercise',
            icon: Icons.quiz_outlined,
            onPressed: () =>
                context.push('/lessons/${lesson.id}/exercise'),
          ),
        ],
      ),
    );
  }
}

class _SavePhraseSheet extends StatelessWidget {
  const _SavePhraseSheet({required this.phrase});

  final Phrase phrase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(phrase.native, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(phrase.english, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Save to deck',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ValueListenableBuilder<List<String>>(
            valueListenable: ProgressStore.deckNames,
            builder: (context, names, _) {
              return ValueListenableBuilder<Map<String, Set<String>>>(
                valueListenable: ProgressStore.decks,
                builder: (context, _, _) {
                  final current = ProgressStore.deckOf(phrase.id);
                  return Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final name in names)
                        _DeckChip(
                          label: name,
                          selected: current == name,
                          onTap: () => _assign(context, name),
                        ),
                      _DeckChip(
                        label: '+ New deck',
                        selected: false,
                        isAction: true,
                        onTap: () => _createDeck(context),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          ValueListenableBuilder<Set<String>>(
            valueListenable: ProgressStore.savedPhraseIds,
            builder: (context, saved, _) {
              if (!saved.contains(phrase.id)) {
                return PrimaryButton(
                  label: 'Done',
                  onPressed: () => Navigator.of(context).pop(),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    label: 'Done',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: () => _unsave(context),
                    icon: const Icon(
                      Icons.bookmark_remove_outlined,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Remove from saved',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _assign(BuildContext context, String deckName) async {
    await ProgressStore.assignToDeck(phrase.id, deckName);
    HapticFeedback.lightImpact();
  }

  Future<void> _unsave(BuildContext context) async {
    await ProgressStore.setSaved(phrase.id, false);
    HapticFeedback.lightImpact();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _createDeck(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewDeckDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    await ProgressStore.addDeck(name);
    if (!context.mounted) return;
    await ProgressStore.assignToDeck(phrase.id, name.trim());
    HapticFeedback.lightImpact();
  }
}

class _DeckChip extends StatelessWidget {
  const _DeckChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAction = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isAction;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    if (selected) {
      bg = AppColors.saved.withValues(alpha: 0.18);
      fg = AppColors.saved;
      border = AppColors.saved;
    } else if (isAction) {
      bg = AppColors.surface;
      fg = AppColors.primary;
      border = AppColors.primary.withValues(alpha: 0.5);
    } else {
      bg = AppColors.surfaceAlt;
      fg = AppColors.textPrimary;
      border = AppColors.outline;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1.2),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.saved,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewDeckDialog extends StatefulWidget {
  const _NewDeckDialog();

  @override
  State<_NewDeckDialog> createState() => _NewDeckDialogState();
}

class _NewDeckDialogState extends State<_NewDeckDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New deck'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'e.g. Cebu trip',
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
