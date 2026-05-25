import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../data/srs_engine.dart';
import '../models/phrase.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Wikato',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
      ],
      child: ListView(
        children: [
          Text('Kumusta!', style: theme.textTheme.displayMedium),
          const SizedBox(height: 4),
          Text(
            'Pick where you want to learn today.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          const _StatsStrip(),
          const SizedBox(height: AppSpacing.md),
          const _ReviewCard(),
          const _PhraseOfTheDayCard(),
          const SizedBox(height: AppSpacing.md),
          const _RealSituationCard(),
          const SizedBox(height: AppSpacing.md),
          const _LessonsCard(),
          const SizedBox(height: AppSpacing.md),
          const _UtilityRow(),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ---------- Stats strip ----------

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () => context.push('/progress'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: ProgressStore.streakDays,
            builder: (context, streak, _) {
              return ValueListenableBuilder<int>(
                valueListenable: ProgressStore.todayCount,
                builder: (context, today, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: ProgressStore.dailyGoal,
                    builder: (context, goal, _) {
                      return ValueListenableBuilder<Set<String>>(
                        valueListenable: ProgressStore.savedPhraseIds,
                        builder: (context, saved, _) {
                          return Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.local_fire_department_rounded,
                                  value: streak == 0 ? '—' : '$streak',
                                  label: streak == 1 ? 'day' : 'days',
                                  color: AppColors.scenario,
                                ),
                              ),
                              const _StatDivider(),
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.check_circle_outline,
                                  value: '$today/$goal',
                                  label: 'today',
                                  color: today >= goal
                                      ? AppColors.success
                                      : AppColors.primary,
                                ),
                              ),
                              const _StatDivider(),
                              Expanded(
                                child: _StatItem(
                                  icon: Icons.bookmark_outline,
                                  value: '${saved.length}',
                                  label: 'saved',
                                  color: AppColors.saved,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: AppColors.outline,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
  }
}

// ---------- Review card (only when there are due cards) ----------

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, SrsCard>>(
      valueListenable: ProgressStore.srsState,
      builder: (context, state, _) {
        final due = SrsEngine.dueToday(state).length;
        if (due == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              onTap: () => context.push('/review'),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.replay_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review $due due',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Spaced repetition keeps them sticking.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------- Phrase of the day (compact) ----------

Phrase? _phraseOfTheDay({required Set<String> saved}) {
  final pool = ContentRepository.lessons
      .expand((l) => l.phraseIds)
      .toSet()
      .map(ContentRepository.findPhrase)
      .whereType<Phrase>()
      .toList(growable: false);
  if (pool.isEmpty) return null;

  final unsaved = pool.where((p) => !saved.contains(p.id)).toList();
  final candidates = unsaved.isNotEmpty ? unsaved : pool;
  final sorted = [...candidates]..sort((a, b) => a.id.compareTo(b.id));

  final now = DateTime.now();
  final epochDay = DateTime(now.year, now.month, now.day)
      .difference(DateTime(2025, 1, 1))
      .inDays;
  final index = epochDay.abs() % sorted.length;
  return sorted[index];
}

class _PhraseOfTheDayCard extends StatelessWidget {
  const _PhraseOfTheDayCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: ProgressStore.savedPhraseIds,
      builder: (context, saved, _) {
        final phrase = _phraseOfTheDay(saved: saved);
        if (phrase == null) return const SizedBox.shrink();
        final isSaved = saved.contains(phrase.id);
        return Material(
          color: AppColors.lessonSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => _toggleSave(phrase, isSaved),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.lesson,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PHRASE OF THE DAY',
                          style: TextStyle(
                            color: AppColors.lesson,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: phrase.native,
                                style: const TextStyle(
                                  color: AppColors.lesson,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: '  ·  ${phrase.english}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (phrase.romanization != null)
                          Text(
                            phrase.romanization!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: AppColors.saved,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleSave(Phrase phrase, bool wasSaved) async {
    HapticFeedback.selectionClick();
    await ProgressStore.setSaved(phrase.id, !wasSaved);
  }
}

// ---------- Real Situation Mode (compact featured) ----------

class _RealSituationCard extends StatelessWidget {
  const _RealSituationCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.scenario,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => context.push('/scenarios'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.theater_comedy_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Text(
                      'KEY',
                      style: TextStyle(
                        color: AppColors.scenario,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Real Situation Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Walk through real conversations, one reply at a time.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: const [
                  Text(
                    'Try a scenario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
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

// ---------- Lessons card (with live progress) ----------

class _LessonsCard extends StatelessWidget {
  const _LessonsCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: ProgressStore.correctlyAnsweredPhraseIds,
      builder: (context, _, _) {
        final lessons = ContentRepository.lessons;
        final done = lessons
            .where((l) => ProgressStore.isLessonComplete(l.phraseIds))
            .length;
        final total = lessons.length;
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => context.push('/lessons'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outline),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.lesson.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.lesson,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lessons',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          total == 0
                              ? 'No lessons yet'
                              : '$done / $total complete',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------- Utility row (Saved + Progress) ----------

class _UtilityRow extends StatelessWidget {
  const _UtilityRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MiniCard(
              icon: Icons.bookmark_rounded,
              label: 'Saved',
              sublabel: _SavedSublabel(),
              color: AppColors.saved,
              onTap: () => context.push('/saved'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MiniCard(
              icon: Icons.insights_rounded,
              label: 'Progress',
              sublabel: const Text(
                'Stats & SRS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              color: AppColors.primary,
              onTap: () => context.push('/progress'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget sublabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              sublabel,
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedSublabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: ProgressStore.savedPhraseIds,
      builder: (context, saved, _) {
        return Text(
          saved.isEmpty ? 'None yet' : '${saved.length} phrases',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }
}
