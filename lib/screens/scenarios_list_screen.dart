import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/primary_button.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

class ScenariosListScreen extends StatelessWidget {
  const ScenariosListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Real Situation Mode',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text('Scenario list (Phase 4)', style: theme.textTheme.bodyMedium),
          const Spacer(),
          PrimaryButton(
            label: 'Open sample scenario',
            onPressed: () => context.push('/scenarios/1'),
          ),
        ],
      ),
    );
  }
}
