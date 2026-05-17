import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../components/primary_button.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

class _Dialect {
  const _Dialect(this.code, this.name, this.region);

  final String code;
  final String name;
  final String region;
}

const _dialects = <_Dialect>[
  _Dialect('tl', 'Tagalog', 'Luzon · National'),
  _Dialect('ceb', 'Cebuano', 'Visayas · Mindanao'),
  _Dialect('ilo', 'Ilocano', 'Northern Luzon'),
  _Dialect('hil', 'Hiligaynon', 'Western Visayas'),
  _Dialect('war', 'Waray', 'Eastern Visayas'),
  _Dialect('bik', 'Bikol', 'Bicol Region'),
];

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Choose a dialect',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇵🇭', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Philippines',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Pick the dialect you want to learn.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.95,
              ),
              itemCount: _dialects.length,
              itemBuilder: (context, i) {
                final dialect = _dialects[i];
                return _DialectTile(
                  dialect: dialect,
                  selected: _selected == dialect.code,
                  onTap: () => setState(() => _selected = dialect.code),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Continue',
            onPressed: _selected == null ? null : () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}

class _DialectTile extends StatelessWidget {
  const _DialectTile({
    required this.dialect,
    required this.selected,
    required this.onTap,
  });

  final _Dialect dialect;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.lessonSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  dialect.name[0],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.lesson,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(dialect.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                dialect.region,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
