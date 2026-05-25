import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors/app_colors.dart';
import '../components/primary_button.dart';
import '../data/progress_store.dart';
import '../theme/app_theme.dart';
import 'exercise_step.dart';

export 'exercise_step.dart';

/// Reports one phrase's outcome from a step to the runner.
class StepResult {
  const StepResult({required this.phraseId, required this.correct});

  final String phraseId;
  final bool correct;
}

/// Runs a list of [ExerciseStep]s. Dispatches each step to its renderer,
/// records per-phrase results to [ProgressStore], shows a summary on
/// completion, and pops via [onFinish].
class ExerciseRunner extends StatefulWidget {
  const ExerciseRunner({
    super.key,
    required this.steps,
    required this.onFinish,
  });

  final List<ExerciseStep> steps;
  final VoidCallback onFinish;

  @override
  State<ExerciseRunner> createState() => _ExerciseRunnerState();
}

class _ExerciseRunnerState extends State<ExerciseRunner> {
  int _index = 0;
  int _correctPhrases = 0;
  int _totalPhrases = 0;
  bool _finished = false;

  bool get _isLast => _index >= widget.steps.length - 1;

  Future<void> _onStepCompleted(List<StepResult> results) async {
    for (final r in results) {
      _totalPhrases += 1;
      if (r.correct) _correctPhrases += 1;
      await ProgressStore.recordExerciseResult(
        phraseId: r.phraseId,
        correct: r.correct,
      );
    }
    if (!mounted) return;
    if (_isLast) {
      setState(() => _finished = true);
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return _Summary(
        correct: _correctPhrases,
        total: _totalPhrases,
        onDone: widget.onFinish,
      );
    }

    final step = widget.steps[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressBar(index: _index, total: widget.steps.length),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: switch (step) {
            ChoiceStep s => _ChoiceStepView(
                key: ValueKey('choice-$_index'),
                step: s,
                isLast: _isLast,
                onCompleted: _onStepCompleted,
              ),
            TypeStep s => _TypeStepView(
                key: ValueKey('type-$_index'),
                step: s,
                isLast: _isLast,
                onCompleted: _onStepCompleted,
              ),
            MatchStep s => _MatchStepView(
                key: ValueKey('match-$_index'),
                step: s,
                isLast: _isLast,
                onCompleted: _onStepCompleted,
              ),
            WordOrderStep s => _WordOrderStepView(
                key: ValueKey('order-$_index'),
                step: s,
                isLast: _isLast,
                onCompleted: _onStepCompleted,
              ),
          },
        ),
      ],
    );
  }
}

// ---------- Chrome ----------

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : (index + 1) / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${index + 1} of $total',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.lessonSoft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(
            color: AppColors.lesson,
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.correct,
    required this.total,
    required this.onDone,
  });

  final int correct;
  final int total;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allRight = total > 0 && correct == total;
    final color = allRight ? AppColors.success : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Icon(
          allRight ? Icons.celebration_rounded : Icons.emoji_events_outlined,
          size: 72,
          color: color,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          allRight ? 'All correct!' : 'Nice work',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$correct of $total right',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        PrimaryButton(label: 'Done', onPressed: onDone),
      ],
    );
  }
}

// ---------- Choice (forward / reverse / fill-blank) ----------

class _ChoiceStepView extends StatefulWidget {
  const _ChoiceStepView({
    super.key,
    required this.step,
    required this.isLast,
    required this.onCompleted,
  });

  final ChoiceStep step;
  final bool isLast;
  final Future<void> Function(List<StepResult>) onCompleted;

  @override
  State<_ChoiceStepView> createState() => _ChoiceStepViewState();
}

class _ChoiceStepViewState extends State<_ChoiceStepView> {
  String? _selected;

  bool get _answered => _selected != null;
  bool get _isCorrect => _selected == widget.step.correct;

  void _select(String option) {
    if (_answered) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = option);
  }

  Future<void> _next() async {
    HapticFeedback.lightImpact();
    await widget.onCompleted([
      StepResult(phraseId: widget.step.phraseId, correct: _isCorrect),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = widget.step;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(step.instruction, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        _PromptCard(text: step.prompt),
        const SizedBox(height: AppSpacing.xl),
        ...step.options.map((option) {
          final isSelected = _selected == option;
          final isCorrectOption = option == step.correct;
          final state = !_answered
              ? _OptionState.idle
              : isSelected
                  ? (isCorrectOption
                      ? _OptionState.selectedCorrect
                      : _OptionState.selectedWrong)
                  : (isCorrectOption
                      ? _OptionState.revealCorrect
                      : _OptionState.disabled);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _OptionButton(
              label: option,
              state: state,
              onTap: _answered ? null : () => _select(option),
            ),
          );
        }),
        const Spacer(),
        if (_answered) ...[
          _Feedback(correct: _isCorrect, expected: step.correct),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: widget.isLast ? 'See results' : 'Next',
            onPressed: _next,
          ),
        ],
      ],
    );
  }
}

// ---------- Type the answer ----------

class _TypeStepView extends StatefulWidget {
  const _TypeStepView({
    super.key,
    required this.step,
    required this.isLast,
    required this.onCompleted,
  });

  final TypeStep step;
  final bool isLast;
  final Future<void> Function(List<StepResult>) onCompleted;

  @override
  State<_TypeStepView> createState() => _TypeStepViewState();
}

class _TypeStepViewState extends State<_TypeStepView> {
  final TextEditingController _controller = TextEditingController();
  bool _checked = false;
  bool _isCorrect = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (_checked) return;
    final input = _controller.text;
    final isCorrect = _normalize(input) == _normalize(widget.step.expected);
    HapticFeedback.selectionClick();
    setState(() {
      _checked = true;
      _isCorrect = isCorrect;
    });
  }

  Future<void> _next() async {
    HapticFeedback.lightImpact();
    await widget.onCompleted([
      StepResult(phraseId: widget.step.phraseId, correct: _isCorrect),
    ]);
  }

  /// Lowercase, strip punctuation, collapse whitespace. Filipino dialects
  /// rarely use diacritics; if that changes later, fold accents here too.
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'''[.,?!"'\-]'''), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = widget.step;
    final canCheck = !_checked && _controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(step.instruction, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        _PromptCard(text: step.prompt),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _controller,
          enabled: !_checked,
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (canCheck) _check();
          },
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Type your answer',
            border: OutlineInputBorder(),
          ),
        ),
        const Spacer(),
        if (_checked) ...[
          _Feedback(correct: _isCorrect, expected: step.expected),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: widget.isLast ? 'See results' : 'Next',
            onPressed: _next,
          ),
        ] else
          PrimaryButton(
            label: 'Check',
            icon: Icons.check_rounded,
            onPressed: canCheck ? _check : null,
          ),
      ],
    );
  }
}

// ---------- Match pairs ----------

class _MatchStepView extends StatefulWidget {
  const _MatchStepView({
    super.key,
    required this.step,
    required this.isLast,
    required this.onCompleted,
  });

  final MatchStep step;
  final bool isLast;
  final Future<void> Function(List<StepResult>) onCompleted;

  @override
  State<_MatchStepView> createState() => _MatchStepViewState();
}

class _MatchStepViewState extends State<_MatchStepView> {
  /// Selected indices into the original pairs list.
  int? _selectedLeft;
  int? _selectedRight;

  /// Indices of pairs already locked as matched.
  final Set<int> _locked = <int>{};

  /// Phrase IDs that had at least one wrong-match attempt during this round.
  final Set<String> _wrongPhraseIds = <String>{};

  /// Brief red-flash window after a wrong match (so the user sees what they
  /// picked before it deselects).
  int? _wrongLeft;
  int? _wrongRight;

  late final List<int> _rightOrder; // right-column display order

  @override
  void initState() {
    super.initState();
    _rightOrder = List<int>.generate(widget.step.pairs.length, (i) => i)
      ..shuffle();
  }

  Future<void> _onPick(int leftIndex, int rightIndex) async {
    if (_locked.contains(leftIndex) || _locked.contains(rightIndex)) return;

    if (leftIndex == rightIndex) {
      // Correct match. Lock it green.
      HapticFeedback.lightImpact();
      setState(() {
        _locked.add(leftIndex);
        _selectedLeft = null;
        _selectedRight = null;
      });
      if (_locked.length == widget.step.pairs.length) {
        await Future<void>.delayed(const Duration(milliseconds: 280));
        if (!mounted) return;
        await _complete();
      }
      return;
    }

    // Wrong match. Flash red, mark both phrases as failed, then deselect.
    final wrongLeftId = widget.step.pairs[leftIndex].phraseId;
    final wrongRightId = widget.step.pairs[rightIndex].phraseId;
    setState(() {
      _wrongPhraseIds.add(wrongLeftId);
      _wrongPhraseIds.add(wrongRightId);
      _wrongLeft = leftIndex;
      _wrongRight = rightIndex;
    });
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _wrongLeft = null;
      _wrongRight = null;
      _selectedLeft = null;
      _selectedRight = null;
    });
  }

  void _tapLeft(int i) {
    if (_locked.contains(i)) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedLeft = i);
    final r = _selectedRight;
    if (r != null) {
      // Defer one frame so the red flash state has time to mount.
      Future<void>.microtask(() => _onPick(i, r));
    }
  }

  void _tapRight(int i) {
    if (_locked.contains(i)) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedRight = i);
    final l = _selectedLeft;
    if (l != null) {
      Future<void>.microtask(() => _onPick(l, i));
    }
  }

  Future<void> _complete() async {
    final results = <StepResult>[];
    for (final pair in widget.step.pairs) {
      results.add(StepResult(
        phraseId: pair.phraseId,
        correct: !_wrongPhraseIds.contains(pair.phraseId),
      ));
    }
    await widget.onCompleted(results);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pairs = widget.step.pairs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.step.instruction, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < pairs.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _MatchTile(
                          label: pairs[i].left,
                          state: _tileState(i, isLeft: true),
                          onTap: () => _tapLeft(i),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  children: [
                    for (final i in _rightOrder)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _MatchTile(
                          label: pairs[i].right,
                          state: _tileState(i, isLeft: false),
                          onTap: () => _tapRight(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _OptionState _tileState(int pairIndex, {required bool isLeft}) {
    if (_locked.contains(pairIndex)) return _OptionState.selectedCorrect;
    final flash = isLeft ? _wrongLeft : _wrongRight;
    if (flash == pairIndex) return _OptionState.selectedWrong;
    final sel = isLeft ? _selectedLeft : _selectedRight;
    if (sel == pairIndex) return _OptionState.revealCorrect;
    return _OptionState.idle;
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visuals = _optionVisuals(state);
    return Material(
      color: visuals.background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: state == _OptionState.selectedCorrect ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: visuals.border, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: visuals.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Word order ----------

class _WordOrderStepView extends StatefulWidget {
  const _WordOrderStepView({
    super.key,
    required this.step,
    required this.isLast,
    required this.onCompleted,
  });

  final WordOrderStep step;
  final bool isLast;
  final Future<void> Function(List<StepResult>) onCompleted;

  @override
  State<_WordOrderStepView> createState() => _WordOrderStepViewState();
}

class _WordOrderStepViewState extends State<_WordOrderStepView> {
  /// Indices into `widget.step.correctOrder` currently placed in the answer,
  /// in placement order.
  final List<int> _placed = <int>[];

  /// Display order of the shuffled tiles (indices into correctOrder).
  late final List<int> _tileOrder;

  bool _checked = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _tileOrder = List<int>.generate(widget.step.correctOrder.length, (i) => i)
      ..shuffle();
    // If the shuffle happens to land in correct order, reshuffle once to
    // avoid trivial sessions.
    if (_listEquals(_tileOrder, List.generate(_tileOrder.length, (i) => i))) {
      _tileOrder.shuffle();
    }
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _add(int idx) {
    if (_checked || _placed.contains(idx)) return;
    HapticFeedback.selectionClick();
    setState(() => _placed.add(idx));
  }

  void _removeAtPlaced(int placedPos) {
    if (_checked) return;
    HapticFeedback.selectionClick();
    setState(() => _placed.removeAt(placedPos));
  }

  void _check() {
    if (_checked) return;
    final expected = List<int>.generate(
      widget.step.correctOrder.length,
      (i) => i,
    );
    final ok = _listEquals(_placed, expected);
    HapticFeedback.selectionClick();
    setState(() {
      _checked = true;
      _isCorrect = ok;
    });
  }

  Future<void> _next() async {
    HapticFeedback.lightImpact();
    await widget.onCompleted([
      StepResult(phraseId: widget.step.phraseId, correct: _isCorrect),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final words = widget.step.correctOrder;
    final canCheck = !_checked && _placed.length == words.length;
    final expectedSentence = words.join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.step.instruction, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        _PromptCard(text: widget.step.prompt),
        const SizedBox(height: AppSpacing.lg),
        // Build area
        Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(
              color: _checked
                  ? (_isCorrect ? AppColors.success : AppColors.error)
                  : AppColors.outline,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (var p = 0; p < _placed.length; p++)
                _WordTile(
                  label: words[_placed[p]],
                  onTap: () => _removeAtPlaced(p),
                  faded: _checked,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Available area
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final idx in _tileOrder)
              if (!_placed.contains(idx))
                _WordTile(
                  label: words[idx],
                  onTap: () => _add(idx),
                ),
          ],
        ),
        const Spacer(),
        if (_checked) ...[
          _Feedback(correct: _isCorrect, expected: expectedSentence),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: widget.isLast ? 'See results' : 'Next',
            onPressed: _next,
          ),
        ] else
          PrimaryButton(
            label: 'Check',
            icon: Icons.check_rounded,
            onPressed: canCheck ? _check : null,
          ),
      ],
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.label,
    required this.onTap,
    this.faded = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: faded
          ? AppColors.surfaceAlt
          : AppColors.lessonSoft,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: faded ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: faded ? AppColors.textTertiary : AppColors.lesson,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Shared option button + feedback ----------

enum _OptionState {
  idle,
  selectedCorrect,
  selectedWrong,
  revealCorrect,
  disabled,
}

class _OptionVisuals {
  const _OptionVisuals({
    required this.border,
    required this.background,
    required this.foreground,
    this.trailingIcon,
  });
  final Color border;
  final Color background;
  final Color foreground;
  final IconData? trailingIcon;
}

_OptionVisuals _optionVisuals(_OptionState state) {
  switch (state) {
    case _OptionState.idle:
      return const _OptionVisuals(
        border: AppColors.outline,
        background: AppColors.surface,
        foreground: AppColors.textPrimary,
      );
    case _OptionState.selectedCorrect:
      return _OptionVisuals(
        border: AppColors.success,
        background: AppColors.success.withValues(alpha: 0.10),
        foreground: AppColors.success,
        trailingIcon: Icons.check_circle_rounded,
      );
    case _OptionState.selectedWrong:
      return _OptionVisuals(
        border: AppColors.error,
        background: AppColors.error.withValues(alpha: 0.10),
        foreground: AppColors.error,
        trailingIcon: Icons.cancel_rounded,
      );
    case _OptionState.revealCorrect:
      return const _OptionVisuals(
        border: AppColors.success,
        background: AppColors.surface,
        foreground: AppColors.success,
        trailingIcon: Icons.check_circle_outline_rounded,
      );
    case _OptionState.disabled:
      return const _OptionVisuals(
        border: AppColors.outline,
        background: AppColors.surface,
        foreground: AppColors.textTertiary,
      );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = _optionVisuals(state);
    return Material(
      color: v.background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: v.border, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: v.foreground,
                  ),
                ),
              ),
              if (v.trailingIcon != null)
                Icon(v.trailingIcon, color: v.foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct, required this.expected});

  final bool correct;
  final String expected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct ? AppColors.success : AppColors.error;
    final icon =
        correct ? Icons.celebration_rounded : Icons.refresh_rounded;
    final title = correct ? 'Nice one!' : 'Not quite';
    final body =
        correct ? 'You got it.' : 'Expected: $expected';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
