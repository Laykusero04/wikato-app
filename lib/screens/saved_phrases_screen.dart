import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';

class SavedPhrasesScreen extends StatelessWidget {
  const SavedPhrasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Saved phrases',
      child: Center(
        child: Text(
          'Saved list (Phase 5)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
