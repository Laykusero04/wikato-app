import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/category_card.dart';
import '../widgets/featured_card.dart';
import '../widgets/progress_pill.dart';

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
          Row(
            children: const [
              ProgressPill(
                icon: Icons.check_circle_outline,
                label: '0 lessons done',
              ),
              SizedBox(width: AppSpacing.sm),
              ProgressPill(
                icon: Icons.bookmark_outline,
                label: '0 saved',
                color: AppColors.saved,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FeaturedCard(
            title: 'Real Situation Mode',
            subtitle:
                'Practice phrases for real-world conversations: ordering food, asking for help, talking to locals.',
            ctaLabel: 'Try a scenario',
            icon: Icons.theater_comedy_rounded,
            accent: AppColors.scenario,
            badgeLabel: 'KEY',
            onTap: () => context.push('/scenarios'),
          ),
          const SizedBox(height: AppSpacing.md),
          CategoryCard(
            title: 'Lessons',
            subtitle: 'Categories → phrases → quick exercises',
            icon: Icons.menu_book_rounded,
            accent: AppColors.lesson,
            onTap: () => context.push('/lessons'),
          ),
          const SizedBox(height: AppSpacing.md),
          CategoryCard(
            title: 'Saved phrases',
            subtitle: 'Your starred phrases for later',
            icon: Icons.bookmark_rounded,
            accent: AppColors.saved,
            onTap: () => context.push('/saved'),
          ),
        ],
      ),
    );
  }
}
