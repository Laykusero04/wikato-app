import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/lesson.dart';
import '../models/phrase.dart';
import '../models/scenario.dart';

/// Loads bundled JSON content once at app startup and serves it
/// synchronously for the rest of the app's lifetime.
class ContentRepository {
  ContentRepository._();

  static List<Lesson> _lessons = const [];
  static List<Scenario> _scenarios = const [];
  static Map<String, Phrase> _phrasesById = const {};
  static String? _loadedCode;

  static String? get loadedCode => _loadedCode;

  static Future<void> preload(String langCode) async {
    if (_loadedCode == langCode) return;
    final lessonsRaw =
        await rootBundle.loadString('assets/content/lessons.json');
    final phrasesRaw =
        await rootBundle.loadString('assets/content/phrases_$langCode.json');
    final scenariosRaw =
        await rootBundle.loadString('assets/content/scenarios.json');

    final lessonsJson =
        (json.decode(lessonsRaw) as List).cast<Map<String, dynamic>>();
    final phrasesJson =
        (json.decode(phrasesRaw) as List).cast<Map<String, dynamic>>();
    final scenariosJson =
        (json.decode(scenariosRaw) as List).cast<Map<String, dynamic>>();

    _lessons = lessonsJson.map(Lesson.fromJson).toList(growable: false);
    _scenarios =
        scenariosJson.map(Scenario.fromJson).toList(growable: false);
    _phrasesById = {
      for (final json in phrasesJson)
        json['id'] as String: Phrase.fromJson(json),
    };
    _loadedCode = langCode;
  }

  static List<Lesson> get lessons => _lessons;
  static List<Scenario> get scenarios => _scenarios;

  static Lesson? findLesson(String id) {
    for (final lesson in _lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  static Scenario? findScenario(String id) {
    for (final scenario in _scenarios) {
      if (scenario.id == id) return scenario;
    }
    return null;
  }

  static Phrase? findPhrase(String id) => _phrasesById[id];

  static List<Phrase> phrasesForLesson(Lesson lesson) => lesson.phraseIds
      .map((id) => _phrasesById[id])
      .whereType<Phrase>()
      .toList(growable: false);

  static List<Phrase> phrasesForScenario(Scenario scenario) =>
      scenario.usefulPhraseIds
          .map((id) => _phrasesById[id])
          .whereType<Phrase>()
          .toList(growable: false);
}
