import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../components/primary_button.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../models/phrase.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

/// Special filter value that means "show every deck". Not a real deck name.
const String _allFilter = '__all__';

class SavedPhrasesScreen extends StatefulWidget {
  const SavedPhrasesScreen({super.key});

  @override
  State<SavedPhrasesScreen> createState() => _SavedPhrasesScreenState();
}

class _SavedPhrasesScreenState extends State<SavedPhrasesScreen> {
  String _filter = _allFilter;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Saved phrases',
      child: ValueListenableBuilder<List<String>>(
        valueListenable: ProgressStore.deckNames,
        builder: (context, names, _) {
          return ValueListenableBuilder<Map<String, Set<String>>>(
            valueListenable: ProgressStore.decks,
            builder: (context, decks, _) {
              final allSavedIds = <String>{};
              for (final set in decks.values) {
                allSavedIds.addAll(set);
              }

              if (allSavedIds.isEmpty) {
                return const _EmptyState();
              }

              final idsForFilter = _filter == _allFilter
                  ? allSavedIds
                  : (decks[_filter] ?? <String>{});

              final phrases = idsForFilter
                  .map(ContentRepository.findPhrase)
                  .whereType<Phrase>()
                  .where(_matchesQuery)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 38,
                    child: _DeckFilterRow(
                      names: names,
                      decks: decks,
                      selected: _filter,
                      onSelect: (next) => setState(() => _filter = next),
                      onManage: _openDeckSheet,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: phrases.isEmpty
                        ? _EmptyFilter(query: _query, deck: _filter)
                        : ListView.separated(
                            itemCount: phrases.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, i) {
                              final p = phrases[i];
                              return _SavedRow(
                                phrase: p,
                                deck: ProgressStore.deckOf(p.id),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool _matchesQuery(Phrase p) {
    if (_query.trim().isEmpty) return true;
    final q = _query.toLowerCase();
    return p.native.toLowerCase().contains(q) ||
        p.english.toLowerCase().contains(q) ||
        (p.romanization?.toLowerCase().contains(q) ?? false);
  }

  void _openDeckSheet(String deckName) {
    if (deckName == ProgressStore.defaultDeckName) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManageDeckSheet(
        deckName: deckName,
        onDeleted: () {
          if (_filter == deckName) {
            setState(() => _filter = _allFilter);
          }
        },
      ),
    );
  }
}

// ---------- Search ----------

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search saved phrases',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

// ---------- Deck filter row ----------

class _DeckFilterRow extends StatelessWidget {
  const _DeckFilterRow({
    required this.names,
    required this.decks,
    required this.selected,
    required this.onSelect,
    required this.onManage,
  });

  final List<String> names;
  final Map<String, Set<String>> decks;
  final String selected;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onManage;

  @override
  Widget build(BuildContext context) {
    final allCount =
        decks.values.fold<int>(0, (sum, set) => sum + set.length);
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      children: [
        _FilterChip(
          label: 'All',
          count: allCount,
          selected: selected == _allFilter,
          onTap: () => onSelect(_allFilter),
        ),
        const SizedBox(width: AppSpacing.xs),
        for (final name in names) ...[
          _FilterChip(
            label: name,
            count: decks[name]?.length ?? 0,
            selected: selected == name,
            onTap: () => onSelect(name),
            onLongPress: name == ProgressStore.defaultDeckName
                ? null
                : () => onManage(name),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.saved : AppColors.surface;
    final fg = selected ? Colors.white : AppColors.textPrimary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.saved : AppColors.outline,
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: fg.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Saved row ----------

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.phrase, required this.deck});

  final Phrase phrase;
  final String? deck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey('saved-${phrase.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) async {
        await ProgressStore.setSaved(phrase.id, false);
        HapticFeedback.mediumImpact();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Removed "${phrase.english}"'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => ProgressStore.setSaved(
                  phrase.id,
                  true,
                  deckName: deck,
                ),
              ),
            ),
          );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: Material(
        color: AppColors.savedSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.bookmark_rounded, color: AppColors.saved),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phrase.native,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(phrase.english, style: theme.textTheme.bodyMedium),
                    if (phrase.romanization != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        phrase.romanization!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (deck != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.saved.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          deck!,
                          style: const TextStyle(
                            color: AppColors.saved,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Manage deck sheet ----------

class _ManageDeckSheet extends StatelessWidget {
  const _ManageDeckSheet({
    required this.deckName,
    required this.onDeleted,
  });

  final String deckName;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(deckName, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Rename'),
            onTap: () => _rename(context),
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
            ),
            title: const Text(
              'Delete deck',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text(
              'Its phrases move back to "Saved".',
            ),
            onTap: () => _delete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: deckName),
    );
    if (newName == null || newName.trim().isEmpty) return;
    await ProgressStore.renameDeck(deckName, newName);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete(BuildContext context) async {
    await ProgressStore.removeDeck(deckName);
    onDeleted();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename deck'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------- Empty states ----------

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter({required this.query, required this.deck});

  final String query;
  final String deck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = query.trim().isNotEmpty;
    final body = hasQuery
        ? 'No phrases match "$query"${deck == _allFilter ? '' : ' in this deck'}.'
        : 'This deck is empty. Save phrases here from any lesson.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery
                  ? Icons.search_off_rounded
                  : Icons.bookmark_border_rounded,
              size: 44,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              body,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.savedSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 44,
                color: AppColors.saved,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No saved phrases yet',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the bookmark on any phrase to keep it here for quick reference.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Browse lessons',
              icon: Icons.menu_book_rounded,
              onPressed: () => context.go('/lessons'),
            ),
          ],
        ),
      ),
    );
  }
}
