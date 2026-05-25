/// One unit of work inside an [ExerciseRunner] session.
///
/// Each subclass renders with its own widget and reports per-phrase results
/// back to the runner — most steps yield one result, but [MatchStep] yields
/// one per matched pair.
sealed class ExerciseStep {
  const ExerciseStep({required this.instruction});

  /// Small label shown above the prompt — e.g. "Translate to English".
  final String instruction;
}

/// Multiple-choice question. Covers forward translate, reverse translate,
/// and fill-in-the-blank — they share the same UI shape (prompt + 4
/// buttons), only the prompt + correct vary.
class ChoiceStep extends ExerciseStep {
  const ChoiceStep({
    required this.phraseId,
    required super.instruction,
    required this.prompt,
    required this.correct,
    required this.options,
  }) : assert(options.length >= 2);

  final String phraseId;
  final String prompt;
  final String correct;
  final List<String> options;
}

/// Free-text production. User reads [prompt], types [expected]. Matching
/// is case- and punctuation-insensitive (see ExerciseRunner's normalizer).
class TypeStep extends ExerciseStep {
  const TypeStep({
    required this.phraseId,
    required super.instruction,
    required this.prompt,
    required this.expected,
  });

  final String phraseId;
  final String prompt;
  final String expected;
}

/// A small batch of phrases the user pairs up by tapping left + right.
/// Yields a result per [MatchPair] back to the runner.
class MatchStep extends ExerciseStep {
  const MatchStep({required super.instruction, required this.pairs})
      : assert(pairs.length >= 2);

  final List<MatchPair> pairs;
}

class MatchPair {
  const MatchPair({
    required this.phraseId,
    required this.left,
    required this.right,
  });

  /// Tracked for SRS / completion when this pair is matched.
  final String phraseId;
  final String left;
  final String right;
}

/// User arranges scrambled native-language word tiles into the right order
/// to match the [prompt] (the English translation).
class WordOrderStep extends ExerciseStep {
  const WordOrderStep({
    required this.phraseId,
    required super.instruction,
    required this.prompt,
    required this.correctOrder,
  }) : assert(correctOrder.length >= 2);

  final String phraseId;
  final String prompt;
  final List<String> correctOrder;
}
