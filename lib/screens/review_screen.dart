import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../components/primary_button.dart';
import '../data/exercise_builder.dart';
import '../data/progress_store.dart';
import '../data/srs_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/exercise_runner.dart';

/// Spaced-repetition review session. Pulls all phrases due today from
/// [SrsEngine] and runs them through [ExerciseRunner]. Shows an empty
/// state when nothing is due.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final List<ExerciseStep> _steps;

  @override
  void initState() {
    super.initState();
    final due = SrsEngine.dueToday(ProgressStore.srsState.value);
    _steps = ExerciseBuilder.stepsForPhraseIds(due);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Review',
      child: _steps.isEmpty
          ? const _AllCaughtUp()
          : ExerciseRunner(
              steps: _steps,
              onFinish: () {
                if (!context.mounted) return;
                context.pop();
              },
            ),
    );
  }
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 72,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'All caught up',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Nothing due right now. Finish a lesson to grow your review pool.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        PrimaryButton(
          label: 'Browse lessons',
          icon: Icons.menu_book_rounded,
          onPressed: () => context.go('/lessons'),
        ),
      ],
    );
  }
}
