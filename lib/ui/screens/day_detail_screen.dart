import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../data/models/daily_task.dart';
import '../../data/models/journal_entry.dart';
import '../../data/planner_repository.dart';
import '../widgets/progress_card.dart';
import '../widgets/star_rating.dart';
import 'journal_screen.dart';

/// عرض يوم سابق من الأرشيف: حالة مهامه وتدوينته.
/// المهام للعرض فقط حفاظاً على السجل، والتدوينة قابلة للكتابة أو التعديل.
class DayDetailScreen extends StatefulWidget {
  const DayDetailScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late final PlannerRepository _repo;
  List<DailyTask> _tasks = const [];
  JournalEntry? _journal;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = context.read<PlannerRepository>();
    _repo.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _repo.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final tasks = await _repo.tasksFor(widget.dateKey);
    final journal = await _repo.journalFor(widget.dateKey);
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _journal = journal;
      _loading = false;
    });
  }

  void _openJournal() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JournalScreen(dateKey: widget.dateKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateKey.toDate(widget.dateKey);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final done = _tasks.where((t) => t.isDone).length;
    final journal = _journal;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(ArabicDates.dayMonth(date)),
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
                const SizedBox(height: 12),
                if (_tasks.isNotEmpty)
                  ProgressCard(done: done, total: _tasks.length),
                const SizedBox(height: 16),
                const _SectionTitle(icon: Icons.checklist, title: 'المهام'),
                if (_tasks.isEmpty)
                  const _EmptyNote(text: 'لا توجد مهام مسجّلة لهذا اليوم.')
                else
                  Card(
                    elevation: 0,
                    color: scheme.surfaceContainerHighest,
                    child: Column(
                      children: [
                        for (final t in _tasks)
                          ListTile(
                            leading: Icon(
                              t.isDone
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: t.isDone ? scheme.primary : scheme.outline,
                            ),
                            title: Text(
                              t.title,
                              style: TextStyle(
                                decoration: t.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: _taskSubtitle(t),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                const _SectionTitle(icon: Icons.edit_note, title: 'التدوينة'),
                if (journal == null)
                  const _EmptyNote(text: 'لم تُكتب تدوينة لهذا اليوم.')
                else
                  Card(
                    elevation: 0,
                    color: scheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (journal.rating > 0) ...[
                            StarRating(value: journal.rating, size: 26),
                            const SizedBox(height: 8),
                          ],
                          _JournalBlock(
                            title: 'ما تم إنجازه',
                            body: journal.achievements,
                          ),
                          _JournalBlock(
                            title: 'العقبات',
                            body: journal.obstacles,
                          ),
                          _JournalBlock(
                            title: 'أفكار وملاحظات',
                            body: journal.ideas,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openJournal,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(journal == null ? 'كتابة تدوينة' : 'تعديل التدوينة'),
                ),
              ],
            ),
    );
  }

  Widget? _taskSubtitle(DailyTask t) {
    final parts = <String>[
      if ((t.duration ?? '').isNotEmpty) t.duration!,
      if ((t.note ?? '').isNotEmpty) t.note!,
      if (t.isDone && t.doneAt != null)
        'أُنجزت الساعة ${t.doneAt!.hour.toString().padLeft(2, '0')}:${t.doneAt!.minute.toString().padLeft(2, '0')}',
    ];
    return parts.isEmpty ? null : Text(parts.join('  •  '));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _JournalBlock extends StatelessWidget {
  const _JournalBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(body.trim(), style: text.bodyLarge),
        ],
      ),
    );
  }
}
