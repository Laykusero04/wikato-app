/// Leitner-box spaced repetition algorithm.
///
/// Each phrase the user has seen lives in one of 5 boxes. Correct answers
/// promote a phrase one box up (capped at 5); wrong answers drop it back to
/// box 1. The next review date is computed from the new box's interval.
///
/// Intervals: box 1 → +1 day, box 2 → +2 days, box 3 → +4 days,
/// box 4 → +7 days, box 5 → +30 days.
library;

class SrsCard {
  const SrsCard({
    required this.box,
    required this.nextReview,
    required this.lastSeen,
  });

  /// 1-5. New cards start in box 1.
  final int box;

  /// Date-only. A card is "due" when nextReview <= today.
  final DateTime nextReview;
  final DateTime lastSeen;

  Map<String, dynamic> toJson() => {
        'b': box,
        'n': _formatDate(nextReview),
        'l': _formatDate(lastSeen),
      };

  factory SrsCard.fromJson(Map<String, dynamic> json) => SrsCard(
        box: (json['b'] as num).toInt(),
        nextReview: DateTime.parse(json['n'] as String),
        lastSeen: DateTime.parse(json['l'] as String),
      );
}

class SrsEngine {
  SrsEngine._();

  static const int maxBox = 5;

  static const List<int> _intervalDays = [1, 2, 4, 7, 30];

  /// Days a card in [box] should wait before its next review.
  static int intervalDaysForBox(int box) {
    final i = box.clamp(1, maxBox) - 1;
    return _intervalDays[i];
  }

  /// Pure transition: given a card's current state, return the next state
  /// after an answer.
  ///
  /// If [current] is null the card is new — correct goes to box 2, wrong to
  /// box 1 (still seen, still due tomorrow).
  static SrsCard advance(SrsCard? current, {required bool correct}) {
    final today = todayDate();
    final int nextBox;
    if (correct) {
      nextBox = current == null ? 2 : (current.box + 1).clamp(1, maxBox);
    } else {
      nextBox = 1;
    }
    final next = today.add(Duration(days: intervalDaysForBox(nextBox)));
    return SrsCard(box: nextBox, nextReview: next, lastSeen: today);
  }

  /// Returns the IDs from [state] that are due today or earlier.
  static List<String> dueToday(Map<String, SrsCard> state) {
    final today = todayDate();
    final due = <String>[];
    state.forEach((id, card) {
      if (!card.nextReview.isAfter(today)) due.add(id);
    });
    return due;
  }
}

DateTime todayDate() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

String _formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
