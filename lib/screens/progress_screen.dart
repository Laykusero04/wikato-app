import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../data/srs_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

/// Current-snapshot stats screen. No persisted history — everything here
/// is derived live from [ProgressStore].
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Your progress',
      child: ListView(
        children: [
          const _StreakHero(),
          const SizedBox(height: AppSpacing.lg),
          const _StatsGrid(),
          const SizedBox(height: AppSpacing.lg),
          const _BoxDistribution(),
        ],
      ),
    );
  }
}

// ---------- Streak hero ----------

class _StreakHero extends StatelessWidget {
  const _StreakHero();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ProgressStore.streakDays,
      builder: (context, streak, _) {
        return ValueListenableBuilder<int>(
          valueListenable: ProgressStore.todayCount,
          builder: (context, today, _) {
            return ValueListenableBuilder<int>(
              valueListenable: ProgressStore.dailyGoal,
              builder: (context, goal, _) {
                final fraction = goal == 0 ? 0.0 : (today / goal).clamp(0, 1);
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.scenario, Color(0xFFD45128)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            streak == 0 ? 'No streak yet' : '$streak day streak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '$today / $goal exercises today',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: fraction.toDouble(),
                          minHeight: 8,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ---------- Stats grid ----------

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: ProgressStore.correctlyAnsweredPhraseIds,
      builder: (context, answered, _) {
        return ValueListenableBuilder<Map<String, SrsCard>>(
          valueListenable: ProgressStore.srsState,
          builder: (context, srs, _) {
            return ValueListenableBuilder<Set<String>>(
              valueListenable: ProgressStore.completedScenarioIds,
              builder: (context, scenarios, _) {
                final allLessons = ContentRepository.lessons;
                final completedLessons = allLessons
                    .where((l) => ProgressStore.isLessonComplete(l.phraseIds))
                    .length;
                final masteredCount = ProgressStore.masteredPhraseCount();
                final encountered = srs.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.menu_book_rounded,
                            label: 'Lessons',
                            value:
                                '$completedLessons / ${allLessons.length}',
                            accent: AppColors.lesson,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.theater_comedy_rounded,
                            label: 'Scenarios',
                            value: '${scenarios.length}',
                            accent: AppColors.scenario,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.workspace_premium_rounded,
                            label: 'Mastered',
                            value: '$masteredCount',
                            accent: AppColors.success,
                            subtitle: 'in box 5',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.bolt_rounded,
                            label: 'Seen',
                            value: '$encountered',
                            accent: AppColors.primary,
                            subtitle: 'phrases tried',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- SRS box distribution ----------

class _BoxDistribution extends StatelessWidget {
  const _BoxDistribution();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, SrsCard>>(
      valueListenable: ProgressStore.srsState,
      builder: (context, srs, _) {
        if (srs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Text(
              'Finish a few exercises and your spaced-repetition boxes will show here.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          );
        }
        final counts = List<int>.filled(SrsEngine.maxBox, 0);
        for (final card in srs.values) {
          final box = card.box.clamp(1, SrsEngine.maxBox) - 1;
          counts[box] += 1;
        }
        final max = counts.reduce((a, b) => a > b ? a : b);

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SRS boxes',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How many phrases sit in each spaced-repetition box. Box 5 = mastered.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < counts.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _BoxBar(
                    box: i + 1,
                    count: counts[i],
                    max: max,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BoxBar extends StatelessWidget {
  const _BoxBar({
    required this.box,
    required this.count,
    required this.max,
  });

  final int box;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : count / max;
    final color = _colorForBox(box);
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            'Box $box',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Color _colorForBox(int box) {
    switch (box) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.scenario;
      case 3:
        return AppColors.saved;
      case 4:
        return AppColors.primary;
      case 5:
      default:
        return AppColors.success;
    }
  }
}
