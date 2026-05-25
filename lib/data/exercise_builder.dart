
import 'dart:math';

import '../models/phrase.dart';
import '../widgets/exercise_step.dart';
import 'content_repository.dart';

/// Builds a mixed list of [ExerciseStep]s — choice, type, match-pairs,
/// and word-order — for both the lesson exercise screen and the review
/// screen. Per-phrase, picks 2 random eligible variants; sessions also
/// get one match-pairs round if there are enough phrases.
class ExerciseBuilder {
  ExerciseBuilder._();

  static const int _choiceOptions = 4;
  static const int _maxMatchPairs = 5;
  static const int _variantsPerPhrase = 2;

  static List<ExerciseStep> stepsForPhraseIds(
    List<String> phraseIds, {
    int? seed,
  }) {
    final rng = seed == null ? Random() : Random(seed);
    final pool = _phrasePool();
    final phrases = phraseIds
        .map(ContentRepository.findPhrase)
        .whereType<Phrase>()
        .toList(growable: false);
    if (phrases.isEmpty) return const [];

    final steps = <ExerciseStep>[];
    for (final phrase in phrases) {
      final variants = _eligibleVariants(phrase);
      variants.shuffle(rng);
      final picks = variants.take(_variantsPerPhrase);
      for (final variant in picks) {
        final step = _buildStep(variant, phrase, pool, rng);
        if (step != null) steps.add(step);
      }
    }
    steps.shuffle(rng);

    // One match-pairs round at the start if we have enough phrases.
    if (phrases.length >= 3) {
      final matchPairs = _buildMatchPairs(phrases, rng);
      if (matchPairs.length >= 2) {
        steps.insert(
          0,
          MatchStep(
            instruction: 'Match each phrase with its translation:',
            pairs: matchPairs,
          ),
        );
      }
    }
    return steps;
  }

  // ---------- internals ----------

  static List<Phrase> _phrasePool() => ContentRepository.lessons
      .expand((l) => l.phraseIds)
      .map(ContentRepository.findPhrase)
      .whereType<Phrase>()
      .toList(growable: false);

  static List<_Variant> _eligibleVariants(Phrase phrase) {
    final multiWord = _nativeWords(phrase.native).length >= 2;
    return [
      _Variant.forwardChoice,
      _Variant.reverseChoice,
      _Variant.typeEnglish,
      _Variant.typeNative,
      if (multiWord) _Variant.fillBlank,
      if (multiWord) _Variant.wordOrder,
    ];
  }

  static ExerciseStep? _buildStep(
    _Variant variant,
    Phrase phrase,
    List<Phrase> pool,
    Random rng,
  ) {
    switch (variant) {
      case _Variant.forwardChoice:
        return _forwardChoice(phrase, pool, rng);
      case _Variant.reverseChoice:
        return _reverseChoice(phrase, pool, rng);
      case _Variant.typeEnglish:
        return TypeStep(
          phraseId: phrase.id,
          instruction: 'Type the English translation:',
          prompt: phrase.native,
          expected: phrase.english,
        );
      case _Variant.typeNative:
        return TypeStep(
          phraseId: phrase.id,
          instruction: 'Type it in the local language:',
          prompt: phrase.english,
          expected: phrase.native,
        );
      case _Variant.fillBlank:
        return _fillBlank(phrase, pool, rng);
      case _Variant.wordOrder:
        return _wordOrder(phrase, rng);
    }
  }

  static ChoiceStep _forwardChoice(Phrase target, List<Phrase> pool, Random rng) {
    final distractors = _pickDistractors(
      pool: pool,
      exclude: target,
      n: _choiceOptions - 1,
      pickAnswer: (p) => p.english,
      rng: rng,
    );
    final options = [target.english, ...distractors]..shuffle(rng);
    return ChoiceStep(
      phraseId: target.id,
      instruction: 'Translate to English:',
      prompt: target.native,
      correct: target.english,
      options: options,
    );
  }

  static ChoiceStep _reverseChoice(Phrase target, List<Phrase> pool, Random rng) {
    final distractors = _pickDistractors(
      pool: pool,
      exclude: target,
      n: _choiceOptions - 1,
      pickAnswer: (p) => p.native,
      rng: rng,
    );
    final options = [target.native, ...distractors]..shuffle(rng);
    return ChoiceStep(
      phraseId: target.id,
      instruction: 'Translate from English:',
      prompt: target.english,
      correct: target.native,
      options: options,
    );
  }

  static ChoiceStep? _fillBlank(Phrase target, List<Phrase> pool, Random rng) {
    final words = _nativeWords(target.native);
    if (words.length < 2) return null;
    final blankIndex = rng.nextInt(words.length);
    final answer = words[blankIndex];
    final blanked = [
      for (var i = 0; i < words.length; i++)
        if (i == blankIndex) '___' else words[i],
    ].join(' ');

    final distractorWords = _distractorWords(
      pool: pool,
      exclude: answer.toLowerCase(),
      n: _choiceOptions - 1,
      rng: rng,
    );
    final options = [answer, ...distractorWords]..shuffle(rng);
    return ChoiceStep(
      phraseId: target.id,
      instruction: 'Fill the blank — "${target.english}":',
      prompt: blanked,
      correct: answer,
      options: options,
    );
  }

  static WordOrderStep? _wordOrder(Phrase target, Random rng) {
    final words = _nativeWords(target.native);
    if (words.length < 2) return null;
    return WordOrderStep(
      phraseId: target.id,
      instruction: 'Arrange the words — "${target.english}":',
      prompt: target.english,
      correctOrder: words,
    );
  }

  static List<MatchPair> _buildMatchPairs(List<Phrase> phrases, Random rng) {
    final shuffled = [...phrases]..shuffle(rng);
    final take = shuffled.take(_maxMatchPairs).toList();
    return [
      for (final p in take)
        MatchPair(phraseId: p.id, left: p.english, right: p.native),
    ];
  }

  static List<String> _pickDistractors({
    required List<Phrase> pool,
    required Phrase exclude,
    required int n,
    required String Function(Phrase) pickAnswer,
    required Random rng,
  }) {
    final correctAnswer = pickAnswer(exclude);
    final candidates = pool
        .where((p) => p.id != exclude.id)
        .map(pickAnswer)
        .where((s) => s != correctAnswer)
        .toSet()
        .toList()
      ..shuffle(rng);
    if (candidates.length <= n) return candidates;
    return candidates.take(n).toList();
  }

  /// For fill-in-the-blank: gather single native words from the wider pool
  /// to use as distractors for the missing word.
  static List<String> _distractorWords({
    required List<Phrase> pool,
    required String exclude,
    required int n,
    required Random rng,
  }) {
    final all = <String>{};
    for (final p in pool) {
      for (final w in _nativeWords(p.native)) {
        if (w.toLowerCase() != exclude) all.add(w);
      }
    }
    final list = all.toList()..shuffle(rng);
    if (list.length <= n) return list;
    return list.take(n).toList();
  }

  static List<String> _nativeWords(String native) {
    return native
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
  }
}

enum _Variant {
  forwardChoice,
  reverseChoice,
  typeEnglish,
  typeNative,
  fillBlank,
  wordOrder,
}
