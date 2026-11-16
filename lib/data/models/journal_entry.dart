/// تدوينة يوم واحد: ما أُنجز، والعقبات، والأفكار، وتقييم اليوم.
class JournalEntry {
  const JournalEntry({
    required this.date,
    this.achievements = '',
    this.obstacles = '',
    this.ideas = '',
    this.rating = 0,
    this.updatedAt,
  });

  final String date;
  final String achievements;
  final String obstacles;
  final String ideas;

  /// من 0 (بلا تقييم) إلى 5 نجوم.
  final int rating;
  final DateTime? updatedAt;

  bool get isEmpty =>
      achievements.trim().isEmpty &&
      obstacles.trim().isEmpty &&
      ideas.trim().isEmpty &&
      rating == 0;

  factory JournalEntry.fromMap(Map<String, Object?> map) {
    final updatedRaw = map['updated_at'] as String?;
    return JournalEntry(
      date: map['date'] as String,
      achievements: (map['achievements'] as String?) ?? '',
      obstacles: (map['obstacles'] as String?) ?? '',
      ideas: (map['ideas'] as String?) ?? '',
      rating: (map['rating'] as int?) ?? 0,
      updatedAt: updatedRaw == null ? null : DateTime.tryParse(updatedRaw),
    );
  }

  Map<String, Object?> toMap() => {
        'date': date,
        'achievements': achievements,
        'obstacles': obstacles,
        'ideas': ideas,
        'rating': rating,
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };
}
