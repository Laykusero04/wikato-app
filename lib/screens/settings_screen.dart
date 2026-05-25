import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../data/dialects.dart';
import '../data/notification_service.dart';
import '../data/progress_store.dart';
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
          ValueListenableBuilder<String?>(
            valueListenable: ProgressStore.languageCode,
            builder: (context, code, _) => CategoryCard(
              title: 'Change dialect',
              subtitle: 'Currently learning: ${dialectNameFor(code)}',
              icon: Icons.translate_rounded,
              accent: AppColors.primary,
              onTap: () => context.go('/language'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _ReminderTile(),
          const SizedBox(height: AppSpacing.md),
          CategoryCard(
            title: 'Reset progress',
            subtitle: 'Clear saved phrases, streak, and lesson progress',
            icon: Icons.restart_alt_rounded,
            accent: AppColors.error,
            onTap: () => _confirmReset(context),
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

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This will remove all saved phrases, your streak, and any '
          "lesson progress. You can't undo this.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await NotificationService.cancelAll();
      await ProgressStore.resetAll();
      HapticFeedback.mediumImpact();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Progress reset')));
    }
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ProgressStore.reminderEnabled,
      builder: (context, enabled, _) {
        return ValueListenableBuilder<int>(
          valueListenable: ProgressStore.reminderHour,
          builder: (context, hour, _) {
            final timeLabel = _formatHour(hour);
            return CategoryCard(
              title: 'Daily reminder',
              subtitle: enabled
                  ? 'Every day at $timeLabel'
                  : 'Off — tap to enable',
              icon: Icons.notifications_active_outlined,
              accent: AppColors.scenario,
              onTap: enabled ? () => _pickTime(context, hour) : null,
              trailing: Switch(
                value: enabled,
                onChanged: (next) => _toggle(context, next),
                activeThumbColor: AppColors.scenario,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggle(BuildContext context, bool next) async {
    if (next) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Notification permission denied. Enable it in system settings.',
              ),
            ),
          );
        return;
      }
      await ProgressStore.setReminderEnabled(true);
      await NotificationService.scheduleDaily(
        ProgressStore.reminderHour.value,
      );
    } else {
      await ProgressStore.setReminderEnabled(false);
      await NotificationService.cancelAll();
    }
  }

  Future<void> _pickTime(BuildContext context, int currentHour) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
    );
    if (picked == null) return;
    await ProgressStore.setReminderHour(picked.hour);
    if (ProgressStore.reminderEnabled.value) {
      await NotificationService.scheduleDaily(picked.hour);
    }
  }

  String _formatHour(int hour) {
    final dt = DateTime(2025, 1, 1, hour);
    final h12 = dt.hour == 0
        ? 12
        : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h12:00 $suffix';
  }
}
