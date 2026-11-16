import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/date_utils.dart';
import '../data/models/daily_task.dart';
import '../data/planner_repository.dart';

/// يدير قائمة مهام اليوم الحالي، ويكتشف بداية اليوم الجديد تلقائياً:
/// عند فتح التطبيق، وعند العودة إليه من الخلفية، وكل دقيقة أثناء فتحه.
class TodayController extends ChangeNotifier with WidgetsBindingObserver {
  TodayController(this._repo);

  final PlannerRepository _repo;

  String _dateKey = DateKey.today();
  List<DailyTask> _tasks = const [];
  bool _loading = true;
  String? _error;
  Timer? _dayWatcher;
  bool _disposed = false;

  String get dateKey => _dateKey;
  DateTime get date => DateKey.toDate(_dateKey);
  List<DailyTask> get tasks => List.unmodifiable(_tasks);
  bool get loading => _loading;
  String? get error => _error;
  int get total => _tasks.length;
  int get doneCount => _tasks.where((t) => t.isDone).length;
  double get progress => total == 0 ? 0 : doneCount / total;

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    _dayWatcher = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkDayChange(),
    );
    await reload();
  }

  /// يعيد تحميل اليوم الحالي، وينشئ مهامه من الروتين إن كان يوماً جديداً.
  Future<void> reload() async {
    final today = DateKey.today();
    try {
      await _repo.ensureDay(today);
      final tasks = await _repo.tasksFor(today);
      _dateKey = today;
      _tasks = tasks;
      _error = null;
    } catch (e) {
      _error = 'تعذّر تحميل مهام اليوم: $e';
    }
    _loading = false;
    _notify();
  }

  void _checkDayChange() {
    if (DateKey.today() != _dateKey) reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkDayChange();
  }

  Future<void> toggle(DailyTask task) async {
    final id = task.id;
    if (id == null) return;
    final newValue = !task.isDone;
    // تحديث فوري للواجهة ثم الحفظ.
    _tasks = [
      for (final t in _tasks)
        if (t.id == id)
          t.copyWith(
            isDone: newValue,
            doneAt: newValue ? DateTime.now() : null,
            clearDoneAt: !newValue,
          )
        else
          t,
    ];
    _notify();
    try {
      await _repo.setTaskDone(id, newValue);
    } catch (_) {
      await reload();
    }
  }

  Future<void> addTask({
    required String title,
    String? duration,
    String? note,
    bool addToRoutine = false,
  }) async {
    await _repo.addTask(
      _dateKey,
      title: title,
      duration: duration,
      note: note,
      addToRoutine: addToRoutine,
    );
    await _refreshTasks();
  }

  Future<void> updateTask(DailyTask task) async {
    await _repo.updateTask(task);
    await _refreshTasks();
  }

  Future<void> deleteTask(DailyTask task) async {
    final id = task.id;
    if (id == null) return;
    await _repo.deleteTask(id);
    await _refreshTasks();
  }

  Future<void> _refreshTasks() async {
    _tasks = await _repo.tasksFor(_dateKey);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _dayWatcher?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
