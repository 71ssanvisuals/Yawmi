import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'models/daily_task.dart';
import 'models/day_summary.dart';
import 'models/journal_entry.dart';
import 'models/task_template.dart';

/// طبقة الوصول إلى البيانات: كل قراءة وكتابة تمر من هنا.
///
/// [revision] يزداد بعد كل تعديل، لتعيد الشاشات المفتوحة (مثل الأرشيف)
/// تحميل بياناتها تلقائياً.
class PlannerRepository {
  PlannerRepository(this._helper);

  final DatabaseHelper _helper;
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<Database> get _db => _helper.database;

  void _changed() => revision.value++;

  String _now() => DateTime.now().toIso8601String();

  String? _clean(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  // ───────────────────────── الأيام ─────────────────────────

  /// ينشئ قائمة مهام اليوم من الروتين إن لم تكن قد أُنشئت من قبل.
  /// آمن عند استدعائه أكثر من مرة: لا يكرر المهام ولا يعيد ما حذفه المستخدم.
  Future<void> ensureDay(String date) async {
    final db = await _db;
    final created = await db.transaction<bool>((txn) async {
      final existing = await txn.query(
        'days',
        columns: ['date'],
        where: 'date = ?',
        whereArgs: [date],
        limit: 1,
      );
      if (existing.isNotEmpty) return false;

      await txn.insert('days', {'date': date, 'created_at': _now()});

      final templates = await txn.query(
        'task_templates',
        orderBy: 'sort_order ASC, id ASC',
      );
      var order = 0;
      for (final row in templates) {
        final t = TaskTemplate.fromMap(row);
        await txn.insert('daily_tasks', {
          'date': date,
          'template_id': t.id,
          'title': t.title,
          'duration': t.duration,
          'note': t.note,
          'is_done': 0,
          'sort_order': order++,
        });
      }
      return true;
    });
    if (created) _changed();
  }

  // ───────────────────────── مهام اليوم ─────────────────────────

  Future<List<DailyTask>> tasksFor(String date) async {
    final db = await _db;
    final rows = await db.query(
      'daily_tasks',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(DailyTask.fromMap).toList();
  }

  /// يضيف مهمة ليوم محدد، ويضيفها اختيارياً إلى الروتين لتتكرر في الأيام القادمة.
  Future<void> addTask(
    String date, {
    required String title,
    String? duration,
    String? note,
    bool addToRoutine = false,
  }) async {
    final db = await _db;
    final cleanTitle = title.trim();
    final cleanDuration = _clean(duration);
    final cleanNote = _clean(note);

    await db.transaction((txn) async {
      int? templateId;
      if (addToRoutine) {
        final nextTemplateOrder = Sqflite.firstIntValue(await txn.rawQuery(
              'SELECT COALESCE(MAX(sort_order), -1) + 1 FROM task_templates',
            )) ??
            0;
        templateId = await txn.insert('task_templates', {
          'title': cleanTitle,
          'duration': cleanDuration,
          'note': cleanNote,
          'sort_order': nextTemplateOrder,
          'created_at': _now(),
        });
      }

      final nextOrder = Sqflite.firstIntValue(await txn.rawQuery(
            'SELECT COALESCE(MAX(sort_order), -1) + 1 FROM daily_tasks WHERE date = ?',
            [date],
          )) ??
          0;

      await txn.insert('daily_tasks', {
        'date': date,
        'template_id': templateId,
        'title': cleanTitle,
        'duration': cleanDuration,
        'note': cleanNote,
        'is_done': 0,
        'sort_order': nextOrder,
      });
    });
    _changed();
  }

  /// يعدّل نص المهمة في هذا اليوم فقط (لا يمس الروتين).
  Future<void> updateTask(DailyTask task) async {
    final db = await _db;
    await db.update(
      'daily_tasks',
      {
        'title': task.title.trim(),
        'duration': _clean(task.duration),
        'note': _clean(task.note),
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
    _changed();
  }

  Future<void> setTaskDone(int id, bool done) async {
    final db = await _db;
    await db.update(
      'daily_tasks',
      {'is_done': done ? 1 : 0, 'done_at': done ? _now() : null},
      where: 'id = ?',
      whereArgs: [id],
    );
    _changed();
  }

  Future<void> deleteTask(int id) async {
    final db = await _db;
    await db.delete('daily_tasks', where: 'id = ?', whereArgs: [id]);
    _changed();
  }

  // ───────────────────────── الروتين الثابت ─────────────────────────

  Future<List<TaskTemplate>> templates() async {
    final db = await _db;
    final rows =
        await db.query('task_templates', orderBy: 'sort_order ASC, id ASC');
    return rows.map(TaskTemplate.fromMap).toList();
  }

  Future<void> addTemplate({
    required String title,
    String? duration,
    String? note,
  }) async {
    final db = await _db;
    final next = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COALESCE(MAX(sort_order), -1) + 1 FROM task_templates',
        )) ??
        0;
    await db.insert('task_templates', {
      'title': title.trim(),
      'duration': _clean(duration),
      'note': _clean(note),
      'sort_order': next,
      'created_at': _now(),
    });
    _changed();
  }

  Future<void> updateTemplate(TaskTemplate template) async {
    final db = await _db;
    await db.update(
      'task_templates',
      {
        'title': template.title.trim(),
        'duration': _clean(template.duration),
        'note': _clean(template.note),
      },
      where: 'id = ?',
      whereArgs: [template.id],
    );
    _changed();
  }

  Future<void> deleteTemplate(int id) async {
    final db = await _db;
    await db.delete('task_templates', where: 'id = ?', whereArgs: [id]);
    _changed();
  }

  /// يحفظ الترتيب الجديد للروتين كما هو في القائمة المعطاة.
  Future<void> reorderTemplates(List<TaskTemplate> ordered) async {
    final db = await _db;
    final batch = db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(
        'task_templates',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [ordered[i].id],
      );
    }
    await batch.commit(noResult: true);
    _changed();
  }

  // ───────────────────────── التدوين ─────────────────────────

  Future<JournalEntry?> journalFor(String date) async {
    final db = await _db;
    final rows = await db.query(
      'journal_entries',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    return rows.isEmpty ? null : JournalEntry.fromMap(rows.first);
  }

  /// يحفظ التدوينة أو يحذفها إن أصبحت فارغة تماماً.
  Future<void> saveJournal(JournalEntry entry) async {
    final db = await _db;
    if (entry.isEmpty) {
      await db.delete(
        'journal_entries',
        where: 'date = ?',
        whereArgs: [entry.date],
      );
    } else {
      await db.insert(
        'journal_entries',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    _changed();
  }

  // ───────────────────────── الأرشيف ─────────────────────────

  /// ملخصات كل الأيام المسجّلة بين تاريخين (شاملة الطرفين).
  Future<Map<String, DaySummary>> summariesBetween(
    String startKey,
    String endKey,
  ) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT d.date AS date,
        (SELECT COUNT(*) FROM daily_tasks t WHERE t.date = d.date) AS total,
        (SELECT COUNT(*) FROM daily_tasks t
           WHERE t.date = d.date AND t.is_done = 1) AS done,
        (SELECT COUNT(*) FROM journal_entries j WHERE j.date = d.date) AS has_journal,
        (SELECT j.rating FROM journal_entries j WHERE j.date = d.date) AS rating
      FROM (
        SELECT date FROM days WHERE date BETWEEN ? AND ?
        UNION
        SELECT date FROM daily_tasks WHERE date BETWEEN ? AND ?
        UNION
        SELECT date FROM journal_entries WHERE date BETWEEN ? AND ?
      ) d
      ORDER BY d.date DESC
    ''', [startKey, endKey, startKey, endKey, startKey, endKey]);

    return {
      for (final row in rows) (row['date'] as String): DaySummary.fromMap(row),
    };
  }

  // ───────────────────────── الإعدادات ─────────────────────────

  Future<String?> getSetting(String key) async {
    final db = await _db;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _db;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
