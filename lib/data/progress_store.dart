import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'srs_engine.dart';

/// Persistent user state, backed by `shared_preferences`.
///
/// UI subscribes to these notifiers via [ValueListenableBuilder] for reactive
/// updates. All mutations go through methods here so the algorithm logic in
/// [SrsEngine] stays a pure layer below.
class ProgressStore {
  ProgressStore._();

  // ---- Storage keys ----
  static const _kSavedPhraseIdsLegacy = 'saved_phrase_ids';
  static const _kDecks = 'phrase_decks_v2';
  static const _kDeckNames = 'deck_names_v2';
  static const _kLastUsedDeck = 'last_used_deck';
  static const _kLanguageCode = 'language_code';
  static const _kSrsState = 'srs_state';
  static const _kCorrectlyAnswered = 'correctly_answered_phrase_ids';
  static const _kCompletedScenarios = 'completed_scenario_ids';
  static const _kStreakDays = 'streak_days';
  static const _kLastActiveDate = 'last_active_date';
  static const _kTodayCount = 'today_count';
  static const _kDailyGoal = 'daily_goal';
  static const _kReminderHour = 'reminder_hour';
  static const _kReminderEnabled = 'reminder_enabled';
  static const _kFirstLessonComplete = 'first_lesson_complete';

  static const int defaultDailyGoal = 5;
  static const int defaultReminderHour = 19;

  /// The deck used when the user saves a phrase without picking one. Always
  /// present in [deckNames].
  static const String defaultDeckName = 'Saved';

  static late SharedPreferences _prefs;

  // ---- Notifiers ----

  /// Source of truth for saved phrases: deck name -> set of phrase IDs.
  /// Each phrase belongs to exactly one deck (one-deck-per-phrase model).
  static final ValueNotifier<Map<String, Set<String>>> decks =
      ValueNotifier<Map<String, Set<String>>>(<String, Set<String>>{});

  /// Ordered list of all decks (including empty ones).
  static final ValueNotifier<List<String>> deckNames =
      ValueNotifier<List<String>>(const <String>[]);

  /// Last deck the user assigned a phrase to. Used as the default target
  /// when `setSaved(..., true)` is called without specifying a deck.
  static final ValueNotifier<String> lastUsedDeck =
      ValueNotifier<String>(defaultDeckName);

  /// Derived: flat set of every saved phrase ID across all decks.
  static final ValueNotifier<Set<String>> savedPhraseIds =
      ValueNotifier<Set<String>>(<String>{});

  static final ValueNotifier<String?> languageCode =
      ValueNotifier<String?>(null);

  static final ValueNotifier<Map<String, SrsCard>> srsState =
      ValueNotifier<Map<String, SrsCard>>(<String, SrsCard>{});

  static final ValueNotifier<Set<String>> correctlyAnsweredPhraseIds =
      ValueNotifier<Set<String>>(<String>{});

  static final ValueNotifier<Set<String>> completedScenarioIds =
      ValueNotifier<Set<String>>(<String>{});

  static final ValueNotifier<int> streakDays = ValueNotifier<int>(0);
  static final ValueNotifier<int> todayCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> dailyGoal =
      ValueNotifier<int>(defaultDailyGoal);

  static final ValueNotifier<bool> reminderEnabled = ValueNotifier<bool>(false);
  static final ValueNotifier<int> reminderHour =
      ValueNotifier<int>(defaultReminderHour);

  /// True once the user has completed a full exercise. Gates the
  /// "want a daily reminder?" opt-in so we don't pop the OS permission
  /// dialog at first launch.
  static final ValueNotifier<bool> firstLessonComplete =
      ValueNotifier<bool>(false);

  // ---- Init / reset ----
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    await _loadDecksWithMigration();

    languageCode.value = _prefs.getString(_kLanguageCode);
    correctlyAnsweredPhraseIds.value =
        (_prefs.getStringList(_kCorrectlyAnswered) ?? const <String>[]).toSet();
    completedScenarioIds.value =
        (_prefs.getStringList(_kCompletedScenarios) ?? const <String>[]).toSet();
    srsState.value = _decodeSrs(_prefs.getString(_kSrsState));

    streakDays.value = _prefs.getInt(_kStreakDays) ?? 0;
    todayCount.value = _prefs.getInt(_kTodayCount) ?? 0;
    dailyGoal.value = _prefs.getInt(_kDailyGoal) ?? defaultDailyGoal;
    reminderEnabled.value = _prefs.getBool(_kReminderEnabled) ?? false;
    reminderHour.value = _prefs.getInt(_kReminderHour) ?? defaultReminderHour;
    firstLessonComplete.value = _prefs.getBool(_kFirstLessonComplete) ?? false;

    _resetTodayCountIfNewDay();
  }

  static Future<void> _loadDecksWithMigration() async {
    final raw = _prefs.getString(_kDecks);
    final namesRaw = _prefs.getStringList(_kDeckNames);
    final lastUsed = _prefs.getString(_kLastUsedDeck);

    if (raw != null) {
      // Already on v2 model.
      final parsed = _decodeDecks(raw);
      final names = (namesRaw != null && namesRaw.isNotEmpty)
          ? List<String>.from(namesRaw)
          : parsed.keys.toList();
      if (!names.contains(defaultDeckName)) {
        names.insert(0, defaultDeckName);
      }
      decks.value = parsed;
      deckNames.value = names;
      lastUsedDeck.value = lastUsed ?? defaultDeckName;
    } else {
      // Migrate from legacy savedPhraseIds StringList, or start fresh.
      final legacy = _prefs.getStringList(_kSavedPhraseIdsLegacy);
      final initial = <String, Set<String>>{
        defaultDeckName:
            (legacy ?? const <String>[]).toSet(),
      };
      decks.value = initial;
      deckNames.value = <String>[defaultDeckName];
      lastUsedDeck.value = defaultDeckName;
      await _persistDecks();
    }
    _refreshSavedPhraseIds();
  }

  static Future<void> resetAll() async {
    await _prefs.clear();
    decks.value = <String, Set<String>>{defaultDeckName: <String>{}};
    deckNames.value = <String>[defaultDeckName];
    lastUsedDeck.value = defaultDeckName;
    savedPhraseIds.value = <String>{};
    languageCode.value = null;
    srsState.value = <String, SrsCard>{};
    correctlyAnsweredPhraseIds.value = <String>{};
    completedScenarioIds.value = <String>{};
    streakDays.value = 0;
    todayCount.value = 0;
    dailyGoal.value = defaultDailyGoal;
    reminderEnabled.value = false;
    reminderHour.value = defaultReminderHour;
    firstLessonComplete.value = false;
    await _persistDecks();
  }

  // ---- Saved phrases & decks ----

  static bool isSaved(String phraseId) =>
      savedPhraseIds.value.contains(phraseId);

  static String? deckOf(String phraseId) {
    for (final entry in decks.value.entries) {
      if (entry.value.contains(phraseId)) return entry.key;
    }
    return null;
  }

  /// Adds or removes a saved phrase. When saving, the phrase is assigned to
  /// [deckName] if given, otherwise to the user's [lastUsedDeck].
  static Future<void> setSaved(
    String phraseId,
    bool saved, {
    String? deckName,
  }) async {
    if (saved) {
      final target = deckName ?? lastUsedDeck.value;
      await assignToDeck(phraseId, target);
    } else {
      await _removeFromAllDecks(phraseId);
    }
  }

  /// Moves a phrase into [deckName] (creating the deck if it doesn't yet
  /// exist). If the phrase was already saved elsewhere, removes it from
  /// its previous deck.
  static Future<void> assignToDeck(String phraseId, String deckName) async {
    final next = _cloneDecks();
    // Ensure target deck exists.
    next.putIfAbsent(deckName, () => <String>{});
    // Remove from any other deck first.
    for (final entry in next.entries) {
      if (entry.key != deckName) entry.value.remove(phraseId);
    }
    next[deckName]!.add(phraseId);
    decks.value = next;

    if (!deckNames.value.contains(deckName)) {
      deckNames.value = [...deckNames.value, deckName];
    }
    await _setLastUsedDeck(deckName);
    await _persistDecks();
    _refreshSavedPhraseIds();
  }

  static Future<void> _removeFromAllDecks(String phraseId) async {
    final current = decks.value;
    var changed = false;
    final next = <String, Set<String>>{};
    for (final entry in current.entries) {
      if (entry.value.contains(phraseId)) {
        final reduced = {...entry.value}..remove(phraseId);
        next[entry.key] = reduced;
        changed = true;
      } else {
        next[entry.key] = entry.value;
      }
    }
    if (!changed) return;
    decks.value = next;
    await _persistDecks();
    _refreshSavedPhraseIds();
  }

  static Future<void> addDeck(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (deckNames.value.contains(trimmed)) return;
    final next = _cloneDecks();
    next[trimmed] = <String>{};
    decks.value = next;
    deckNames.value = [...deckNames.value, trimmed];
    await _persistDecks();
  }

  /// Renames a deck. Default deck can't be renamed.
  static Future<void> renameDeck(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    if (oldName == defaultDeckName) return;
    if (!deckNames.value.contains(oldName)) return;
    if (deckNames.value.contains(trimmed)) return;
    final next = _cloneDecks();
    final phrases = next.remove(oldName) ?? <String>{};
    next[trimmed] = phrases;
    decks.value = next;
    deckNames.value = [
      for (final n in deckNames.value) if (n == oldName) trimmed else n
    ];
    if (lastUsedDeck.value == oldName) {
      await _setLastUsedDeck(trimmed);
    }
    await _persistDecks();
  }

  /// Removes a deck. Its phrases are moved into the default deck. The
  /// default deck itself cannot be removed.
  static Future<void> removeDeck(String name) async {
    if (name == defaultDeckName) return;
    if (!deckNames.value.contains(name)) return;
    final next = _cloneDecks();
    final phrases = next.remove(name) ?? <String>{};
    next.putIfAbsent(defaultDeckName, () => <String>{});
    next[defaultDeckName]!.addAll(phrases);
    decks.value = next;
    deckNames.value = [
      for (final n in deckNames.value) if (n != name) n
    ];
    if (lastUsedDeck.value == name) {
      await _setLastUsedDeck(defaultDeckName);
    }
    await _persistDecks();
    _refreshSavedPhraseIds();
  }

  static Set<String> phrasesInDeck(String deckName) =>
      decks.value[deckName] ?? <String>{};

  static Future<void> _setLastUsedDeck(String name) async {
    lastUsedDeck.value = name;
    await _prefs.setString(_kLastUsedDeck, name);
  }

  // ---- Language ----
  static Future<void> setLanguageCode(String code) async {
    if (languageCode.value == code) return;
    await _prefs.setString(_kLanguageCode, code);
    languageCode.value = code;
  }

  // ---- Exercise result (the high-level entry point) ----

  /// Called by exercise screens when the user answers a phrase. Advances
  /// the SRS box, marks the phrase as correctly answered (if [correct]),
  /// and updates the daily streak + today count.
  static Future<void> recordExerciseResult({
    required String phraseId,
    required bool correct,
  }) async {
    final nextSrs =
        SrsEngine.advance(srsState.value[phraseId], correct: correct);
    final nextMap = {...srsState.value, phraseId: nextSrs};
    srsState.value = nextMap;
    await _prefs.setString(_kSrsState, _encodeSrs(nextMap));

    if (correct && !correctlyAnsweredPhraseIds.value.contains(phraseId)) {
      final next = {...correctlyAnsweredPhraseIds.value, phraseId};
      await _prefs.setStringList(_kCorrectlyAnswered, next.toList());
      correctlyAnsweredPhraseIds.value = next;
    }

    await _advanceStreakIfNeeded();
    todayCount.value = todayCount.value + 1;
    await _prefs.setInt(_kTodayCount, todayCount.value);
  }

  /// Called when the user finishes a branching dialogue. Marks the scenario
  /// as completed and counts the run toward today's goal + streak. Does
  /// NOT touch SRS — dialogue replies don't have a single "right answer".
  static Future<void> recordScenarioComplete(String scenarioId) async {
    if (!completedScenarioIds.value.contains(scenarioId)) {
      final next = {...completedScenarioIds.value, scenarioId};
      await _prefs.setStringList(_kCompletedScenarios, next.toList());
      completedScenarioIds.value = next;
    }
    await _advanceStreakIfNeeded();
    todayCount.value = todayCount.value + 1;
    await _prefs.setInt(_kTodayCount, todayCount.value);
  }

  static bool isLessonComplete(List<String> phraseIds) {
    if (phraseIds.isEmpty) return false;
    final done = correctlyAnsweredPhraseIds.value;
    return phraseIds.every(done.contains);
  }

  static int correctlyAnsweredCount(List<String> phraseIds) {
    final done = correctlyAnsweredPhraseIds.value;
    return phraseIds.where(done.contains).length;
  }

  /// Count of phrases that have made it to box 5 ("mastered" in SRS terms).
  static int masteredPhraseCount() {
    var count = 0;
    for (final card in srsState.value.values) {
      if (card.box >= SrsEngine.maxBox) count++;
    }
    return count;
  }

  static Future<void> markFirstLessonComplete() async {
    if (firstLessonComplete.value) return;
    await _prefs.setBool(_kFirstLessonComplete, true);
    firstLessonComplete.value = true;
  }

  // ---- Reminder settings ----
  static Future<void> setReminderEnabled(bool enabled) async {
    if (reminderEnabled.value == enabled) return;
    await _prefs.setBool(_kReminderEnabled, enabled);
    reminderEnabled.value = enabled;
  }

  static Future<void> setReminderHour(int hour) async {
    final clamped = hour.clamp(0, 23);
    if (reminderHour.value == clamped) return;
    await _prefs.setInt(_kReminderHour, clamped);
    reminderHour.value = clamped;
  }

  // ---- Internals ----

  static Future<void> _advanceStreakIfNeeded() async {
    final today = todayDate();
    final lastStr = _prefs.getString(_kLastActiveDate);
    final last = lastStr == null ? null : DateTime.parse(lastStr);

    if (last != null && _sameDay(last, today)) {
      return;
    }

    if (last != null && _sameDay(last.add(const Duration(days: 1)), today)) {
      streakDays.value = streakDays.value + 1;
    } else {
      streakDays.value = 1;
    }
    todayCount.value = 0;

    await _prefs.setInt(_kStreakDays, streakDays.value);
    await _prefs.setInt(_kTodayCount, 0);
    await _prefs.setString(_kLastActiveDate, _formatDate(today));
  }

  static void _resetTodayCountIfNewDay() {
    final lastStr = _prefs.getString(_kLastActiveDate);
    if (lastStr == null) return;
    final last = DateTime.parse(lastStr);
    if (!_sameDay(last, todayDate())) {
      todayCount.value = 0;
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _encodeSrs(Map<String, SrsCard> state) =>
      jsonEncode(state.map((k, v) => MapEntry(k, v.toJson())));

  static Map<String, SrsCard> _decodeSrs(String? raw) {
    if (raw == null || raw.isEmpty) return <String, SrsCard>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, SrsCard.fromJson(v as Map<String, dynamic>)),
      );
    } catch (_) {
      return <String, SrsCard>{};
    }
  }

  static Map<String, Set<String>> _decodeDecks(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map(
        (key, value) => MapEntry(
          key,
          (value as List).cast<String>().toSet(),
        ),
      );
    } catch (_) {
      return <String, Set<String>>{
        defaultDeckName: <String>{},
      };
    }
  }

  static Map<String, Set<String>> _cloneDecks() {
    return {
      for (final entry in decks.value.entries) entry.key: {...entry.value},
    };
  }

  static Future<void> _persistDecks() async {
    final encoded = jsonEncode(
      decks.value.map((k, v) => MapEntry(k, v.toList())),
    );
    await _prefs.setString(_kDecks, encoded);
    await _prefs.setStringList(_kDeckNames, deckNames.value);
  }

  static void _refreshSavedPhraseIds() {
    final all = <String>{};
    for (final set in decks.value.values) {
      all.addAll(set);
    }
    savedPhraseIds.value = all;
  }
}
