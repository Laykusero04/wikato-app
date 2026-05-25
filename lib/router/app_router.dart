import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/language_select_screen.dart';
import '../screens/lesson_detail_screen.dart';
import '../screens/dialogue_screen.dart';
import '../screens/lessons_list_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/review_screen.dart';
import '../screens/saved_phrases_screen.dart';
import '../screens/scenario_detail_screen.dart';
import '../screens/scenarios_list_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/translation_exercise_screen.dart';

CustomTransitionPage<T> _sharedAxisPage<T>(Widget child) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.scaled,
        fillColor: Colors.transparent,
        child: child,
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, _) => const SplashScreen(),
    ),
    GoRoute(
      path: '/language',
      builder: (_, _) => const LanguageSelectScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, _) => const HomeScreen(),
    ),
    GoRoute(
      path: '/lessons',
      pageBuilder: (_, _) => _sharedAxisPage(const LessonsListScreen()),
    ),
    GoRoute(
      path: '/lessons/:id',
      builder: (_, state) =>
          LessonDetailScreen(lessonId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/lessons/:id/exercise',
      builder: (_, state) => TranslationExerciseScreen(
        lessonId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/scenarios',
      pageBuilder: (_, _) => _sharedAxisPage(const ScenariosListScreen()),
    ),
    GoRoute(
      path: '/scenarios/:id',
      builder: (_, state) =>
          ScenarioDetailScreen(scenarioId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/scenarios/:id/dialogue',
      builder: (_, state) =>
          DialogueScreen(scenarioId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/saved',
      pageBuilder: (_, _) => _sharedAxisPage(const SavedPhrasesScreen()),
    ),
    GoRoute(
      path: '/review',
      pageBuilder: (_, _) => _sharedAxisPage(const ReviewScreen()),
    ),
    GoRoute(
      path: '/progress',
      pageBuilder: (_, _) => _sharedAxisPage(const ProgressScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (_, _) => _sharedAxisPage(const SettingsScreen()),
    ),
  ],
);
