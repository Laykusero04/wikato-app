import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../data/mock_lessons.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/category_card.dart';
import '../widgets/section_header.dart';

class LessonsListScreen extends StatelessWidget {
  const LessonsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lessons',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Pick a lesson',
            subtitle: 'Tap a category to start practicing.',
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: mockLessons.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                final lesson = mockLessons[i];
                return CategoryCard(
                  title: lesson.title,
                  subtitle: '${lesson.phrases.length} phrases',
                  icon: lesson.icon,
                  accent: AppColors.lesson,
                  onTap: () => context.push('/lessons/${lesson.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
