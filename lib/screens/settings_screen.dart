import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/category_card.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Settings',
      child: ListView(
        children: [
          const SectionHeader(
            title: 'Preferences',
            subtitle: 'Adjust how Wikato works for you.',
          ),
          const SizedBox(height: AppSpacing.md),
          CategoryCard(
            title: 'Change dialect',
            subtitle: 'Currently learning: Tagalog',
            icon: Icons.translate_rounded,
            accent: AppColors.primary,
            onTap: () => context.go('/language'),
          ),
          const SizedBox(height: AppSpacing.md),
          CategoryCard(
            title: 'Reset progress',
            subtitle: 'Clear saved phrases and lesson progress',
            icon: Icons.restart_alt_rounded,
            accent: AppColors.error,
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          CategoryCard(
            title: 'About Wikato',
            subtitle: 'Version, credits, contact',
            icon: Icons.info_outline_rounded,
            accent: AppColors.lesson,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
