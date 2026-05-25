import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../components/primary_button.dart';
import '../data/content_repository.dart';
import '../data/exercise_builder.dart';
import '../data/notification_service.dart';
import '../data/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/exercise_runner.dart';

class TranslationExerciseScreen extends StatefulWidget {
  const TranslationExerciseScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<TranslationExerciseScreen> createState() =>
      _TranslationExerciseScreenState();
}

class _TranslationExerciseScreenState extends State<TranslationExerciseScreen> {
  late final List<ExerciseStep> _steps;

  @override
  void initState() {
    super.initState();
    final lesson = ContentRepository.findLesson(widget.lessonId);
    _steps = lesson == null
        ? const []
        : ExerciseBuilder.stepsForPhraseIds(lesson.phraseIds);
  }

  Future<void> _onFinish() async {
    final wasFirst = !ProgressStore.firstLessonComplete.value;
    await ProgressStore.markFirstLessonComplete();
    if (!mounted) return;
    if (wasFirst && !ProgressStore.reminderEnabled.value) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _ReminderOptInSheet(),
      );
    }
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      return const AppScaffold(
        title: 'Exercise',
        child: Center(child: Text('No phrases to practice.')),
      );
    }
    return AppScaffold(
      title: 'Translation exercise',
      child: ExerciseRunner(steps: _steps, onFinish: _onFinish),
    );
  }
}

class _ReminderOptInSheet extends StatelessWidget {
  const _ReminderOptInSheet();

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
          const Icon(
            Icons.notifications_active_outlined,
            size: 48,
            color: AppColors.scenario,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Want a daily nudge?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A short reminder at 7pm to keep your streak going. You can change the time anytime.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Enable reminders',
            icon: Icons.check_rounded,
            onPressed: () => _enable(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }

  Future<void> _enable(BuildContext context) async {
    final granted = await NotificationService.requestPermission();
    if (!granted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Enable in system settings.'),
          ),
        );
      Navigator.of(context).pop();
      return;
    }
    await ProgressStore.setReminderEnabled(true);
    await NotificationService.scheduleDaily(
      ProgressStore.reminderHour.value,
    );
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}
