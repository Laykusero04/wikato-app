import 'package:flutter/material.dart';

import 'dialogue.dart';
import 'icon_names.dart';

class Scenario {
  const Scenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.context,
    required this.iconName,
    required this.usefulPhraseIds,
    required this.sampleReply,
    this.dialogue,
  });

  final String id;
  final String title;
  final String subtitle;
  final String context;
  final String iconName;
  final List<String> usefulPhraseIds;
  final String sampleReply;

  /// Branching dialogue for "Real Situation Mode" practice. Optional — only
  /// scenarios with authored dialogues get an interactive run.
  final Dialogue? dialogue;

  IconData get icon => iconForName(iconName);

  bool get hasDialogue => dialogue != null;

  factory Scenario.fromJson(Map<String, dynamic> json) {
    final dialogueRaw = json['dialogue'] as Map<String, dynamic>?;
    return Scenario(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      context: json['context'] as String,
      iconName: json['icon'] as String,
      usefulPhraseIds: (json['useful_phrase_ids'] as List).cast<String>(),
      sampleReply: json['sample_reply'] as String,
      dialogue: dialogueRaw == null ? null : Dialogue.fromJson(dialogueRaw),
    );
  }
}
