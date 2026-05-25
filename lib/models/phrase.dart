class Phrase {
  const Phrase({
    required this.id,
    required this.native,
    required this.english,
    this.romanization,
    this.example,
  });

  final String id;
  final String native;
  final String english;
  final String? romanization;
  final String? example;

  factory Phrase.fromJson(Map<String, dynamic> json) => Phrase(
        id: json['id'] as String,
        native: json['native'] as String,
        english: json['english'] as String,
        romanization: json['romanization'] as String?,
        example: json['example'] as String?,
      );
}
