import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../components/primary_button.dart';
import '../data/mock_lessons.dart';
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
  final Set<String> _saved = <String>{};
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openSaveSheet(MockPhrase phrase) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SavePhraseSheet(
        phrase: phrase,
        initiallySaved: _saved.contains(phrase.id),
        onChanged: (next) {
          setState(() {
            if (next) {
              _saved.add(phrase.id);
            } else {
              _saved.remove(phrase.id);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = findLessonById(widget.lessonId);
    if (lesson == null) {
      return const AppScaffold(
        title: 'Lesson not found',
        child: Center(child: Text('No such lesson.')),
      );
    }

    final theme = Theme.of(context);
    return AppScaffold(
      title: lesson.title,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              '${_index + 1} of ${lesson.phrases.length}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: lesson.phrases.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final phrase = lesson.phrases[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.md,
                  ),
                  child: PhraseCard(
                    original: phrase.original,
                    translation: phrase.translation,
                    pronunciation: phrase.pronunciation,
                    isSaved: _saved.contains(phrase.id),
                    onSave: () => _openSaveSheet(phrase),
                    onPlay: () => HapticFeedback.lightImpact(),
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

class _SavePhraseSheet extends StatefulWidget {
  const _SavePhraseSheet({
    required this.phrase,
    required this.initiallySaved,
    required this.onChanged,
  });

  final MockPhrase phrase;
  final bool initiallySaved;
  final ValueChanged<bool> onChanged;

  @override
  State<_SavePhraseSheet> createState() => _SavePhraseSheetState();
}

class _SavePhraseSheetState extends State<_SavePhraseSheet> {
  late bool _saved = widget.initiallySaved;

  void _toggle(bool next) {
    setState(() => _saved = next);
    widget.onChanged(next);
    HapticFeedback.lightImpact();
  }

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
          Text(widget.phrase.original, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            widget.phrase.translation,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Material(
            color: _saved ? AppColors.savedSoft : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: () => _toggle(!_saved),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      _saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border,
                      color: AppColors.saved,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _saved ? 'Saved to your phrases' : 'Save this phrase',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Switch(
                      value: _saved,
                      onChanged: _toggle,
                      activeThumbColor: AppColors.saved,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
