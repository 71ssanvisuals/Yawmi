/// مهمة ثابتة في الروتين اليومي، تُنسخ تلقائياً إلى قائمة كل يوم جديد.
class TaskTemplate {
  const TaskTemplate({
    this.id,
    required this.title,
    this.duration,
    this.note,
    this.sortOrder = 0,
  });

  final int? id;
  final String title;

  /// المدة كنص حر، مثل: "30 دقيقة" أو "ساعتان إلى 3 ساعات".
  final String? duration;

  /// ملاحظة التوقيت، مثل: "بعد الفجر".
  final String? note;
  final int sortOrder;

  factory TaskTemplate.fromMap(Map<String, Object?> map) => TaskTemplate(
        id: map['id'] as int?,
        title: map['title'] as String,
        duration: map['duration'] as String?,
        note: map['note'] as String?,
        sortOrder: (map['sort_order'] as int?) ?? 0,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'duration': duration,
        'note': note,
        'sort_order': sortOrder,
      };

  TaskTemplate copyWith({
    String? title,
    String? duration,
    String? note,
    int? sortOrder,
    bool clearDuration = false,
    bool clearNote = false,
  }) =>
      TaskTemplate(
        id: id,
        title: title ?? this.title,
        duration: clearDuration ? null : (duration ?? this.duration),
        note: clearNote ? null : (note ?? this.note),
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
