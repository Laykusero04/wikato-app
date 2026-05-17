import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../components/primary_button.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

class TranslationExerciseScreen extends StatefulWidget {
  const TranslationExerciseScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<TranslationExerciseScreen> createState() =>
      _TranslationExerciseScreenState();
}

class _TranslationExerciseScreenState extends State<TranslationExerciseScreen> {
  static const String _question = 'Kumusta';
  static const String _correct = 'Hello';
  static const List<String> _options = <String>[
    'Goodbye',
    'Hello',
    'Thank you',
    'Please',
  ];

  String? _selected;

  bool get _answered => _selected != null;
  bool get _isCorrect => _selected == _correct;

  void _select(String option) {
    setState(() => _selected = option);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Translation exercise',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Translate this phrase:', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: AppColors.lessonSoft,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Center(
              child: Text(
                _question,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: AppColors.lesson,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ..._options.map((option) {
            final isSelected = _selected == option;
            final isCorrectOption = option == _correct;
            final state = !_answered
                ? _OptionState.idle
                : isSelected
                ? (isCorrectOption
                      ? _OptionState.selectedCorrect
                      : _OptionState.selectedWrong)
                : (isCorrectOption
                      ? _OptionState.revealCorrect
                      : _OptionState.disabled);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _OptionButton(
                label: option,
                state: state,
                onTap: _answered ? null : () => _select(option),
              ),
            );
          }),
          const Spacer(),
          if (_answered) ...[
            _Feedback(correct: _isCorrect),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Done',
              onPressed: () => context.pop(),
            ),
          ],
        ],
      ),
    );
  }
}

enum _OptionState {
  idle,
  selectedCorrect,
  selectedWrong,
  revealCorrect,
  disabled,
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border;
    final Color background;
    final Color foreground;
    final IconData? trailingIcon;

    switch (state) {
      case _OptionState.idle:
        border = AppColors.outline;
        background = AppColors.surface;
        foreground = AppColors.textPrimary;
        trailingIcon = null;
      case _OptionState.selectedCorrect:
        border = AppColors.success;
        background = AppColors.success.withValues(alpha: 0.10);
        foreground = AppColors.success;
        trailingIcon = Icons.check_circle_rounded;
      case _OptionState.selectedWrong:
        border = AppColors.error;
        background = AppColors.error.withValues(alpha: 0.10);
        foreground = AppColors.error;
        trailingIcon = Icons.cancel_rounded;
      case _OptionState.revealCorrect:
        border = AppColors.success;
        background = AppColors.surface;
        foreground = AppColors.success;
        trailingIcon = Icons.check_circle_outline_rounded;
      case _OptionState.disabled:
        border = AppColors.outline;
        background = AppColors.surface;
        foreground = AppColors.textTertiary;
        trailingIcon = null;
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct});

  final bool correct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct ? AppColors.success : AppColors.error;
    final icon = correct
        ? Icons.celebration_rounded
        : Icons.refresh_rounded;
    final title = correct ? 'Nice one!' : 'Not quite';
    final body = correct
        ? 'You picked the right translation.'
        : 'The correct answer is highlighted above.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
