import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../data/models/journal_entry.dart';
import '../../data/planner_repository.dart';
import '../widgets/star_rating.dart';

enum _SaveStatus { idle, pending, saving, saved }

/// تدوينة يوم محدد مع حفظ تلقائي أثناء الكتابة.
///
/// تُستخدم في تبويب «التدوينة» لليوم الحالي، وتُفتح من الأرشيف لأي يوم سابق.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen>
    with WidgetsBindingObserver {
  late final PlannerRepository _repo;
  final _achievements = TextEditingController();
  final _obstacles = TextEditingController();
  final _ideas = TextEditingController();

  /// اليوم الذي تعرض الحقول بياناته حالياً؛ كل حفظ يذهب إليه.
  late String _loadedFor;
  int _rating = 0;
  int _tasksDone = 0;
  int _tasksTotal = 0;
  bool _loading = true;
  bool _dirty = false;
  _SaveStatus _status = _SaveStatus.idle;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _repo = context.read<PlannerRepository>();
    _loadedFor = widget.dateKey;
    WidgetsBinding.instance.addObserver(this);
    _repo.revision.addListener(_refreshTaskCounts);
    _load(widget.dateKey);
  }

  /// يحدّث سطر «المهام المنجزة» عند تغيير المهام من تبويب آخر.
  Future<void> _refreshTaskCounts() async {
    final dateKey = _loadedFor;
    final tasks = await _repo.tasksFor(dateKey);
    if (!mounted || dateKey != _loadedFor) return;
    setState(() {
      _tasksTotal = tasks.length;
      _tasksDone = tasks.where((t) => t.isDone).length;
    });
  }

  @override
  void didUpdateWidget(covariant JournalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // عند انتقال اليوم (منتصف الليل) يُحفظ ما كُتب لليوم السابق أولاً.
    if (oldWidget.dateKey != widget.dateKey) {
      _switchDay(widget.dateKey);
    }
  }

  Future<void> _switchDay(String newKey) async {
    _debounce?.cancel();
    await _saveNow();
    if (!mounted) return;
    setState(() => _loading = true);
    await _load(newKey);
  }

  Future<void> _load(String dateKey) async {
    final entry = await _repo.journalFor(dateKey);
    final tasks = await _repo.tasksFor(dateKey);
    if (!mounted) return;
    setState(() {
      _loadedFor = dateKey;
      _achievements.text = entry?.achievements ?? '';
      _obstacles.text = entry?.obstacles ?? '';
      _ideas.text = entry?.ideas ?? '';
      _rating = entry?.rating ?? 0;
      _tasksTotal = tasks.length;
      _tasksDone = tasks.where((t) => t.isDone).length;
      _dirty = false;
      _status = _SaveStatus.idle;
      _loading = false;
    });
  }

  JournalEntry _snapshot() => JournalEntry(
        date: _loadedFor,
        achievements: _achievements.text,
        obstacles: _obstacles.text,
        ideas: _ideas.text,
        rating: _rating,
      );

  void _onEdited() {
    _dirty = true;
    if (_status != _SaveStatus.pending) {
      setState(() => _status = _SaveStatus.pending);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _saveNow);
  }

  Future<void> _saveNow() async {
    if (!_dirty) return;
    _dirty = false;
    final entry = _snapshot();
    if (mounted) setState(() => _status = _SaveStatus.saving);
    await _repo.saveJournal(entry);
    if (mounted && !_dirty) setState(() => _status = _SaveStatus.saved);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // حفظ فوري إذا خرج المستخدم من التطبيق أثناء الكتابة.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _debounce?.cancel();
      _saveNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repo.revision.removeListener(_refreshTaskCounts);
    _debounce?.cancel();
    if (_dirty) {
      // لا يمكن الانتظار داخل dispose؛ الحفظ يكتمل في الخلفية.
      unawaited(_repo.saveJournal(_snapshot()));
    }
    _achievements.dispose();
    _obstacles.dispose();
    _ideas.dispose();
    super.dispose();
  }

  bool get _isToday => _loadedFor == DateKey.today();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final date = DateKey.toDate(_loadedFor);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_isToday ? 'تدوينة اليوم' : 'تدوينة ${ArabicDates.dayMonth(date)}'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: _SaveIndicator(status: _status),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(
                  ArabicDates.fullDate(date),
                  style: text.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (_tasksTotal > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'المهام المنجزة: $_tasksDone من $_tasksTotal',
                    style: text.bodyMedium?.copyWith(color: scheme.primary),
                  ),
                ],
                const SizedBox(height: 16),
                _JournalField(
                  controller: _achievements,
                  label: 'ما الذي أنجزته اليوم؟',
                  icon: Icons.emoji_events_outlined,
                  onChanged: _onEdited,
                ),
                _JournalField(
                  controller: _obstacles,
                  label: 'العقبات والتحديات',
                  icon: Icons.report_problem_outlined,
                  onChanged: _onEdited,
                ),
                _JournalField(
                  controller: _ideas,
                  label: 'أفكار وملاحظات',
                  icon: Icons.lightbulb_outline,
                  onChanged: _onEdited,
                ),
                const SizedBox(height: 8),
                Text('تقييم اليوم', style: text.titleMedium),
                const SizedBox(height: 4),
                Center(
                  child: StarRating(
                    value: _rating,
                    size: 40,
                    onChanged: (v) {
                      setState(() => _rating = v);
                      _onEdited();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يُحفظ ما تكتبه تلقائياً.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}

class _JournalField extends StatelessWidget {
  const _JournalField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        minLines: 3,
        maxLines: 10,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: Icon(icon),
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.status});

  final _SaveStatus status;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: color);
    return switch (status) {
      _SaveStatus.idle => const SizedBox.shrink(),
      _SaveStatus.pending ||
      _SaveStatus.saving =>
        Center(child: Text('جارٍ الحفظ…', style: style)),
      _SaveStatus.saved => Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: color),
              const SizedBox(width: 4),
              Text('محفوظ', style: style),
            ],
          ),
        ),
    };
  }
}
