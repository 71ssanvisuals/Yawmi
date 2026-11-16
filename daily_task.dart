/// مهمة ضمن قائمة يوم محدد.
class DailyTask {
  const DailyTask({
    this.id,
    required this.date,
    this.templateId,
    required this.title,
    this.duration,
    this.note,
    this.isDone = false,
    this.doneAt,
    this.sortOrder = 0,
  });

  final int? id;

  /// مفتاح اليوم بصيغة yyyy-MM-dd.
  final String date;

  /// معرّف مهمة الروتين التي نُسخت منها (إن وُجدت).
  final int? templateId;
  final String title;
  final String? duration;
  final String? note;
  final bool isDone;
  final DateTime? doneAt;
  final int sortOrder;

  bool get isFromRoutine => templateId != null;

  factory DailyTask.fromMap(Map<String, Object?> map) {
    final doneAtRaw = map['done_at'] as String?;
    return DailyTask(
      id: map['id'] as int?,
      date: map['date'] as String,
      templateId: map['template_id'] as int?,
      title: map['title'] as String,
      duration: map['duration'] as String?,
      note: map['note'] as String?,
      isDone: (map['is_done'] as int? ?? 0) == 1,
      doneAt: doneAtRaw == null ? null : DateTime.tryParse(doneAtRaw),
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'template_id': templateId,
        'title': title,
        'duration': duration,
        'note': note,
        'is_done': isDone ? 1 : 0,
        'done_at': doneAt?.toIso8601String(),
        'sort_order': sortOrder,
      };

  DailyTask copyWith({
    String? title,
    String? duration,
    String? note,
    bool? isDone,
    DateTime? doneAt,
    bool clearDuration = false,
    bool clearNote = false,
    bool clearDoneAt = false,
  }) =>
      DailyTask(
        id: id,
        date: date,
        templateId: templateId,
        title: title ?? this.title,
        duration: clearDuration ? null : (duration ?? this.duration),
        note: clearNote ? null : (note ?? this.note),
        isDone: isDone ?? this.isDone,
        doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
        sortOrder: sortOrder,
      );
}
