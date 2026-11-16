import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../data/models/day_summary.dart';
import '../../data/planner_repository.dart';
import '../widgets/month_calendar.dart';
import 'day_detail_screen.dart';

/// الأرشيف: تقويم شهري + إحصاءات الشهر + قائمة الأيام المسجّلة.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final PlannerRepository _repo;
  late DateTime _month;
  Map<String, DaySummary> _data = const {};
  bool _loading = true;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _repo = context.read<PlannerRepository>();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _repo.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _repo.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_requestId;
    final start = DateKey.fromDate(DateTime(_month.year, _month.month, 1));
    final end = DateKey.fromDate(DateTime(_month.year, _month.month + 1, 0));
    final data = await _repo.summariesBetween(start, end);
    // تجاهل النتائج القديمة إن تغيّر الشهر أثناء التحميل.
    if (!mounted || request != _requestId) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _loading = true;
    });
    _load();
  }

  void _openDay(DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DayDetailScreen(dateKey: DateKey.fromDate(date)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final days = _data.values.toList()..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('السجل والأرشيف')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'الشهر السابق',
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    ArabicDates.monthYear(_month),
                    style: text.titleLarge,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'الشهر التالي',
                onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  MonthCalendar(
                    month: _month,
                    summaries: _data,
                    onDayTap: _openDay,
                  ),
                  const SizedBox(height: 12),
                  const CalendarLegend(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _MonthStats(days: days),
            const SizedBox(height: 16),
            Text('الأيام المسجّلة', style: text.titleMedium),
            const SizedBox(height: 8),
            if (days.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'لا توجد سجلات في هذا الشهر',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              for (final day in days)
                _DayTile(
                  summary: day,
                  onTap: () => _openDay(DateKey.toDate(day.date)),
                ),
          ],
        ],
      ),
    );
  }
}

class _MonthStats extends StatelessWidget {
  const _MonthStats({required this.days});

  final List<DaySummary> days;

  @override
  Widget build(BuildContext context) {
    final withTasks = days.where((d) => d.total > 0).toList();
    final avg = withTasks.isEmpty
        ? 0
        : (withTasks.map((d) => d.ratio).reduce((a, b) => a + b) /
                withTasks.length *
                100)
            .round();
    final journals = days.where((d) => d.hasJournal).length;
    final rated = days.where((d) => d.rating > 0).toList();
    final avgRating = rated.isEmpty
        ? '—'
        : (rated.map((d) => d.rating).reduce((a, b) => a + b) / rated.length)
            .toStringAsFixed(1);

    return Row(
      children: [
        _StatBox(label: 'أيام مسجّلة', value: '${days.length}'),
        const SizedBox(width: 8),
        _StatBox(label: 'متوسط الإنجاز', value: '$avg%'),
        const SizedBox(width: 8),
        _StatBox(label: 'تدوينات', value: '$journals'),
        const SizedBox(width: 8),
        _StatBox(label: 'متوسط التقييم', value: avgRating),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: text.titleLarge?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: text.labelSmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.summary, required this.onTap});

  final DaySummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = DateKey.toDate(summary.date);
    final parts = <String>[
      if (summary.total > 0) 'المهام ${summary.done}/${summary.total}',
      if (summary.rating > 0) '★' * summary.rating,
      if (summary.hasJournal) 'فيه تدوينة',
    ];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: scheme.surfaceContainerHighest,
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: summary.ratio,
                strokeWidth: 4,
                backgroundColor: scheme.surface,
              ),
              Text(
                '${summary.percent}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        title: Text(ArabicDates.fullDate(date)),
        subtitle: parts.isEmpty ? null : Text(parts.join('  •  ')),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
