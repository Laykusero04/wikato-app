import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';

class ScenarioDetailScreen extends StatelessWidget {
  const ScenarioDetailScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Scenario $scenarioId',
      child: Center(
        child: Text(
          'Scenario detail (Phase 4)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
