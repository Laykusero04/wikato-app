import 'package:flutter/material.dart';

import 'icon_names.dart';

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.iconName,
    required this.phraseIds,
  });

  final String id;
  final String title;
  final String iconName;
  final List<String> phraseIds;

  IconData get icon => iconForName(iconName);

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        title: json['title'] as String,
        iconName: json['icon'] as String,
        phraseIds: (json['phrase_ids'] as List).cast<String>(),
      );
}
