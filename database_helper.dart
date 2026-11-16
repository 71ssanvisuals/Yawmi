import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// مسؤول عن فتح قاعدة بيانات SQLite المحلية وإنشاء الجداول وترقيتها.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'yawmi.db';

  /// ارفع هذا الرقم عند تغيير بنية الجداول، وأضف خطوة الترقية في [_onUpgrade].
  static const int _dbVersion = 1;

  /// المهام الافتراضية للروتين اليومي، تُزرع مرة واحدة عند إنشاء القاعدة.
  static const List<Map<String, String?>> defaultRoutine = [
    {
      'title': 'ورد القرآن والتجويد',
      'duration': '30 دقيقة',
      'note': 'بعد الفجر',
    },
    {
      'title': 'دراسة أكاديمية زاد',
      'duration': '45 دقيقة',
      'note': null,
    },
    {
      'title': 'مذاكرة مواد الـ GED',
      'duration': 'ساعتان إلى 3 ساعات',
      'note': null,
    },
    {
      'title': 'البحث عن عمل والتقديم وتطوير المهارات',
      'duration': 'ساعة واحدة',
      'note': null,
    },
    {
      'title': 'ورد الأذكار وقراءة حرة / رياضة',
      'duration': null,
      'note': null,
    },
  ];

  Future<Database>? _database;

  /// يُعيد الاتصال نفسه دائماً، ويضمن فتح القاعدة مرة واحدة حتى مع الطلبات المتزامنة.
  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE task_templates (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT    NOT NULL,
        duration    TEXT,
        note        TEXT,
        sort_order  INTEGER NOT NULL DEFAULT 0,
        created_at  TEXT    NOT NULL
      )
    ''');

    // سجل الأيام التي وُلّدت قائمتها؛ يمنع إعادة توليد مهام حذفها المستخدم.
    batch.execute('''
      CREATE TABLE days (
        date        TEXT PRIMARY KEY,
        created_at  TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE daily_tasks (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        date         TEXT    NOT NULL,
        template_id  INTEGER,
        title        TEXT    NOT NULL,
        duration     TEXT,
        note         TEXT,
        is_done      INTEGER NOT NULL DEFAULT 0,
        done_at      TEXT,
        sort_order   INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute('CREATE INDEX idx_daily_tasks_date ON daily_tasks(date)');

    batch.execute('''
      CREATE TABLE journal_entries (
        date          TEXT PRIMARY KEY,
        achievements  TEXT    NOT NULL DEFAULT '',
        obstacles     TEXT    NOT NULL DEFAULT '',
        ideas         TEXT    NOT NULL DEFAULT '',
        rating        INTEGER NOT NULL DEFAULT 0,
        updated_at    TEXT    NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE settings (
        key    TEXT PRIMARY KEY,
        value  TEXT NOT NULL
      )
    ''');

    final now = DateTime.now().toIso8601String();
    for (var i = 0; i < defaultRoutine.length; i++) {
      final t = defaultRoutine[i];
      batch.insert('task_templates', {
        'title': t['title'],
        'duration': t['duration'],
        'note': t['note'],
        'sort_order': i,
        'created_at': now,
      });
    }

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // مثال لترقية مستقبلية:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE daily_tasks ADD COLUMN category TEXT');
    // }
  }
}
