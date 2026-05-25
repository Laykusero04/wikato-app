import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../components/primary_button.dart';
import '../data/content_repository.dart';
import '../data/progress_store.dart';
import '../models/dialogue.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';

/// Chat-style branching dialogue runner. Walks a [Dialogue] node graph,
/// rendering NPC lines as left-aligned bubbles and the user's reply choices
/// as bottom cards. Terminal nodes show an outcome card.
class DialogueScreen extends StatefulWidget {
  const DialogueScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  State<DialogueScreen> createState() => _DialogueScreenState();
}

class _DialogueScreenState extends State<DialogueScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<_Bubble> _messages = <_Bubble>[];

  Dialogue? _dialogue;
  String? _currentNodeId;
  bool _recordedCompletion = false;

  @override
  void initState() {
    super.initState();
    final scenario = ContentRepository.findScenario(widget.scenarioId);
    final dialogue = scenario?.dialogue;
    _dialogue = dialogue;
    if (dialogue != null) {
      _enterNode(dialogue.startNodeId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _enterNode(String nodeId) {
    final node = _dialogue?.nodeById(nodeId);
    if (node == null) return;
    setState(() {
      _currentNodeId = nodeId;
      _messages.add(_Bubble.npc(
        speaker: node.speaker,
        text: node.line,
        translation: node.translation,
      ));
    });
    _scrollToBottom();
    if (node.isTerminal) {
      _onReachedTerminal();
    }
  }

  void _onReply(DialogueReply reply) {
    HapticFeedback.selectionClick();
    setState(() {
      _messages.add(_Bubble.user(
        text: reply.text,
        translation: reply.translation,
      ));
    });
    _scrollToBottom();
    // Brief delay so the user's bubble lands before the NPC responds.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _enterNode(reply.nextNodeId);
    });
  }

  Future<void> _onReachedTerminal() async {
    if (_recordedCompletion) return;
    _recordedCompletion = true;
    await ProgressStore.recordScenarioComplete(widget.scenarioId);
  }

  void _restart() {
    if (_dialogue == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.clear();
      _currentNodeId = null;
    });
    _enterNode(_dialogue!.startNodeId);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenario = ContentRepository.findScenario(widget.scenarioId);
    final dialogue = _dialogue;
    if (scenario == null || dialogue == null) {
      return const AppScaffold(
        title: 'Dialogue',
        child: Center(child: Text('No dialogue available.')),
      );
    }

    final currentNode = _currentNodeId == null
        ? null
        : dialogue.nodeById(_currentNodeId!);
    final isTerminal = currentNode?.isTerminal ?? false;

    return AppScaffold(
      title: scenario.title,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, i) =>
                  _ChatBubble(bubble: _messages[i]),
            ),
          ),
          if (isTerminal)
            _OutcomeCard(
              endMessage: currentNode?.endMessage ?? 'End of dialogue.',
              onRestart: _restart,
              onDone: () => context.pop(),
            )
          else if (currentNode != null)
            _ReplyPanel(
              replies: currentNode.replies!,
              onPick: _onReply,
            ),
        ],
      ),
    );
  }
}

// ---------- Data ----------

class _Bubble {
  const _Bubble({
    required this.speaker,
    required this.text,
    required this.isUser,
    this.translation,
  });

  factory _Bubble.npc({
    required String speaker,
    required String text,
    String? translation,
  }) =>
      _Bubble(
        speaker: speaker,
        text: text,
        translation: translation,
        isUser: false,
      );

  factory _Bubble.user({
    required String text,
    String? translation,
  }) =>
      _Bubble(
        speaker: 'You',
        text: text,
        translation: translation,
        isUser: true,
      );

  final String speaker;
  final String text;
  final String? translation;
  final bool isUser;
}

// ---------- Chat bubble ----------

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.bubble});

  final _Bubble bubble;

  @override
  Widget build(BuildContext context) {
    final isUser = bubble.isUser;
    final bg = isUser ? AppColors.primary : AppColors.scenarioSoft;
    final fg = isUser ? Colors.white : AppColors.textPrimary;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final crossAlign =
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final speakerColor =
        isUser ? AppColors.primary : AppColors.scenario;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Align(
        alignment: align,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Column(
            crossAxisAlignment: crossAlign,
            children: [
              Text(
                bubble.speaker,
                style: TextStyle(
                  color: speakerColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadius.lg),
                    topRight: const Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(isUser ? AppRadius.lg : 4),
                    bottomRight: Radius.circular(isUser ? 4 : AppRadius.lg),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: crossAlign,
                  children: [
                    Text(
                      bubble.text,
                      style: TextStyle(
                        color: fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    if (bubble.translation != null &&
                        bubble.translation!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bubble.translation!,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
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

// ---------- Reply panel ----------

class _ReplyPanel extends StatelessWidget {
  const _ReplyPanel({required this.replies, required this.onPick});

  final List<DialogueReply> replies;
  final void Function(DialogueReply) onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your reply',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final reply in replies)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ReplyCard(
                reply: reply,
                onTap: () => onPick(reply),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({required this.reply, required this.onTap});

  final DialogueReply reply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    if (reply.translation != null &&
                        reply.translation!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        reply.translation!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Outcome ----------

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({
    required this.endMessage,
    required this.onRestart,
    required this.onDone,
  });

  final String endMessage;
  final VoidCallback onRestart;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  endMessage,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Restart'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.scenario,
                    side: const BorderSide(color: AppColors.scenario),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: 'Done',
                  onPressed: onDone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
