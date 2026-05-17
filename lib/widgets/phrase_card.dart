import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors/app_colors.dart';
import '../theme/app_theme.dart';

class PhraseCard extends StatefulWidget {
  const PhraseCard({
    super.key,
    required this.original,
    required this.translation,
    this.pronunciation,
    this.onSave,
    this.onPlay,
    this.isSaved = false,
  });

  final String original;
  final String translation;
  final String? pronunciation;
  final VoidCallback? onSave;
  final VoidCallback? onPlay;
  final bool isSaved;

  @override
  State<PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<PhraseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    HapticFeedback.selectionClick();
    if (_controller.status == AnimationStatus.completed) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = _controller.value;
          final angle = value * math.pi;
          final showBack = value > 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildBack(context),
                  )
                : _buildFront(context),
          );
        },
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    final theme = Theme.of(context);
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionRow(
            isSaved: widget.isSaved,
            onPlay: widget.onPlay,
            onSave: widget.onSave,
          ),
          const Spacer(),
          Text(widget.original, style: theme.textTheme.displayLarge),
          const SizedBox(height: AppSpacing.md),
          _TapHint(label: 'Tap to reveal translation'),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final theme = Theme.of(context);
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionRow(
            isSaved: widget.isSaved,
            onPlay: widget.onPlay,
            onSave: widget.onSave,
          ),
          const Spacer(),
          if (widget.pronunciation != null) ...[
            Text(
              widget.pronunciation!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            widget.translation,
            style: theme.textTheme.displayMedium?.copyWith(
              color: AppColors.lesson,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TapHint(label: 'Tap to flip back'),
          const Spacer(),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isSaved,
    required this.onPlay,
    required this.onSave,
  });

  final bool isSaved;
  final VoidCallback? onPlay;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPlay,
          icon: const Icon(Icons.volume_up_rounded),
          color: AppColors.primary,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primarySoft,
          ),
        ),
        IconButton(
          onPressed: onSave,
          icon: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border,
          ),
          color: AppColors.saved,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.savedSoft,
          ),
        ),
      ],
    );
  }
}

class _TapHint extends StatelessWidget {
  const _TapHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(
          Icons.touch_app_outlined,
          size: 14,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
