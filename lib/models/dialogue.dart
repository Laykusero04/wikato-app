/// Branching scenario dialogue. Loaded from the optional `dialogue` field
/// on a scenario in `assets/content/scenarios.json`. The runtime walks
/// [nodes] starting at [startNodeId]; a node with `replies == null` is
/// terminal and shows [DialogueNode.endMessage] when reached.
class Dialogue {
  const Dialogue({
    required this.startNodeId,
    required this.nodes,
  });

  final String startNodeId;
  final Map<String, DialogueNode> nodes;

  DialogueNode? nodeById(String id) => nodes[id];

  factory Dialogue.fromJson(Map<String, dynamic> json) {
    final nodesRaw = (json['nodes'] as Map<String, dynamic>);
    return Dialogue(
      startNodeId: json['start'] as String,
      nodes: nodesRaw.map(
        (key, value) =>
            MapEntry(key, DialogueNode.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }
}

class DialogueNode {
  const DialogueNode({
    required this.speaker,
    required this.line,
    this.translation,
    this.replies,
    this.endMessage,
  });

  /// Display name of who speaks this line (e.g. "Vendor", "Local", "Driver").
  final String speaker;

  /// The line in the target language.
  final String line;

  /// Optional English gloss shown under the line.
  final String? translation;

  /// User options. `null` (or empty) marks this node as terminal.
  final List<DialogueReply>? replies;

  /// Wrap-up text shown when this terminal node is reached.
  final String? endMessage;

  bool get isTerminal => replies == null || replies!.isEmpty;

  factory DialogueNode.fromJson(Map<String, dynamic> json) {
    final repliesRaw = json['replies'] as List?;
    return DialogueNode(
      speaker: json['speaker'] as String,
      line: json['line'] as String,
      translation: json['translation'] as String?,
      replies: repliesRaw
          ?.cast<Map<String, dynamic>>()
          .map(DialogueReply.fromJson)
          .toList(growable: false),
      endMessage: json['end_message'] as String?,
    );
  }
}

class DialogueReply {
  const DialogueReply({
    required this.text,
    required this.nextNodeId,
    this.translation,
  });

  /// What the user "says" — shown verbatim as the user's chat bubble.
  final String text;

  /// Where to go next.
  final String nextNodeId;

  /// Optional English gloss for the reply.
  final String? translation;

  factory DialogueReply.fromJson(Map<String, dynamic> json) => DialogueReply(
        text: json['text'] as String,
        nextNodeId: json['next'] as String,
        translation: json['translation'] as String?,
      );
}
