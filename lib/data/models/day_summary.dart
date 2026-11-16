/// ملخص يوم للأرشيف والتقويم.
class DaySummary {
  const DaySummary({
    required this.date,
    required this.total,
    required this.done,
    required this.hasJournal,
    required this.rating,
  });

  final String date;
  final int total;
  final int done;
  final bool hasJournal;
  final int rating;

  double get ratio => total == 0 ? 0 : done / total;
  bool get isComplete => total > 0 && done == total;
  int get percent => (ratio * 100).round();

  factory DaySummary.fromMap(Map<String, Object?> map) => DaySummary(
        date: map['date'] as String,
        total: (map['total'] as int?) ?? 0,
        done: (map['done'] as int?) ?? 0,
        hasJournal: ((map['has_journal'] as int?) ?? 0) == 1,
        rating: (map['rating'] as int?) ?? 0,
      );
}
