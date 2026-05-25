import 'package:flutter/material.dart';

const Map<String, IconData> _iconByName = {
  // Lesson categories
  'waving_hand': Icons.waving_hand_rounded,
  'chat_bubble': Icons.chat_bubble_outline_rounded,
  'help_outline': Icons.help_outline_rounded,
  'restaurant': Icons.restaurant_rounded,
  'person_pin': Icons.person_pin_circle_rounded,
  'tag': Icons.tag_rounded,

  // Scenario categories
  'handshake': Icons.handshake_rounded,
  'navigation': Icons.navigation_rounded,
  'storefront': Icons.storefront_rounded,
  'directions_walk': Icons.directions_walk_rounded,
  'theater': Icons.theater_comedy_rounded,
};

IconData iconForName(String name) => _iconByName[name] ?? Icons.book_outlined;
