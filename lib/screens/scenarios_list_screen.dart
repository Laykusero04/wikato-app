import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/badge_chip.dart';
import '../widgets/section_header.dart';

class ScenariosListScreen extends StatelessWidget {
  const ScenariosListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scenarios = ContentRepository.scenarios;
    return AppScaffold(
      title: 'Real Situation Mode',
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: ProgressStore.completedScenarioIds,
        builder: (context, completed, _) {
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: scenarios.length + 1,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              if (i == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  child: SectionHeader(
                    title: 'Practice real situations',
                    subtitle:
                        'Walk into the moment with the phrases you actually need.',
                  ),
                );
              }
              final scenario = scenarios[i - 1];
              final phraseCount =
                  ContentRepository.phrasesForScenario(scenario).length;
              return _ScenarioCard(
                scenario: scenario,
                phraseCount: phraseCount,
                completed: completed.contains(scenario.id),
                onTap: () => context.push('/scenarios/${scenario.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.scenario,
    required this.phraseCount,
    required this.completed,
    required this.onTap,
  });

  final Scenario scenario;
  final int phraseCount;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.scenario,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -24,
              child: Icon(
                scenario.icon,
                size: 180,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Padding(
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
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          scenario.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      if (scenario.hasDialogue) ...[
                        const BadgeChip(
                          label: 'Dialogue',
                          color: Colors.white,
                          foregroundColor: AppColors.scenario,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      if (completed)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 22,
                        )
                      else
                        const BadgeChip(
                          label: 'Real situation',
                          color: Colors.white,
                          foregroundColor: AppColors.scenario,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    scenario.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    scenario.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$phraseCount useful phrases',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
