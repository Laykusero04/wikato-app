import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/category_card.dart';
import '../widgets/section_header.dart';

class LessonsListScreen extends StatelessWidget {
  const LessonsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lessons = ContentRepository.lessons;
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
            child: ValueListenableBuilder<Set<String>>(
              valueListenable: ProgressStore.correctlyAnsweredPhraseIds,
              builder: (context, done, _) {
                return ListView.separated(
                  itemCount: lessons.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final lesson = lessons[i];
                    final mastered = lesson.phraseIds
                        .where(done.contains)
                        .length;
                    final total = lesson.phraseIds.length;
                    final complete = mastered == total && total > 0;
                    return CategoryCard(
                      title: lesson.title,
                      subtitle: complete
                          ? 'Lesson complete'
                          : '$mastered / $total mastered',
                      icon: lesson.icon,
                      accent: AppColors.lesson,
                      onTap: () => context.push('/lessons/${lesson.id}'),
                      trailing: _LessonTrailing(
                        lesson: lesson,
                        mastered: mastered,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTrailing extends StatelessWidget {
  const _LessonTrailing({required this.lesson, required this.mastered});

  final Lesson lesson;
  final int mastered;

  @override
  Widget build(BuildContext context) {
    final total = lesson.phraseIds.length;
    if (total == 0) {
      return const Icon(Icons.chevron_right, color: AppColors.textTertiary);
    }
    if (mastered == total) {
      return const Icon(
        Icons.check_circle_rounded,
        color: AppColors.success,
      );
    }
    if (mastered == 0) {
      return const Icon(Icons.chevron_right, color: AppColors.textTertiary);
    }
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: mastered / total,
            strokeWidth: 3,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lesson),
          ),
        ],
      ),
    );
  }
}
