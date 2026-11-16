import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/task_template.dart';
import '../../data/planner_repository.dart';
import '../widgets/dialogs.dart';
import '../widgets/task_form_sheet.dart';

/// إدارة الروتين اليومي: المهام التي تُنشأ تلقائياً في بداية كل يوم.
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  late final PlannerRepository _repo;
  List<TaskTemplate> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo = context.read<PlannerRepository>();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.templates();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final r = await showTaskFormSheet(context, heading: 'مهمة جديدة في الروتين');
    if (r == null) return;
    await _repo.addTemplate(title: r.title, duration: r.duration, note: r.note);
    await _load();
  }

  Future<void> _edit(TaskTemplate t) async {
    final r = await showTaskFormSheet(
      context,
      heading: 'تعديل مهمة الروتين',
      initialTitle: t.title,
      initialDuration: t.duration,
      initialNote: t.note,
    );
    if (r == null) return;
    await _repo.updateTemplate(
      t.copyWith(title: r.title, duration: r.duration, note: r.note),
    );
    await _load();
  }

  Future<void> _delete(TaskTemplate t) async {
    final ok = await confirmDialog(
      context,
      title: 'حذف من الروتين',
      message: 'لن تُنشأ «${t.title}» في الأيام القادمة. '
          'سجلات الأيام السابقة لن تتأثر.',
    );
    if (!ok || t.id == null) return;
    await _repo.deleteTemplate(t.id!);
    await _load();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    await _repo.reorderTemplates(_items);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('الروتين اليومي')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('إضافة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  color: scheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: scheme.onSecondaryContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'تُنشأ هذه المهام تلقائياً في بداية كل يوم جديد. '
                            'التعديلات هنا تسري من الغد ولا تغيّر قائمة اليوم الحالي. '
                            'اضغط مطولاً على مهمة واسحبها لتغيير ترتيبها.',
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Text(
                            'الروتين فارغ. أضف مهمتك الأولى.',
                            style: text.bodyLarge,
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                          itemCount: _items.length,
                          onReorderItem: _reorder,
                          itemBuilder: (context, i) {
                            final t = _items[i];
                            final subtitle = [
                              if ((t.duration ?? '').isNotEmpty) t.duration!,
                              if ((t.note ?? '').isNotEmpty) t.note!,
                            ].join('  •  ');
                            return Card(
                              key: ValueKey(t.id),
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              color: scheme.surfaceContainerHighest,
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: scheme.primary,
                                  foregroundColor: scheme.onPrimary,
                                  child: Text('${i + 1}'),
                                ),
                                title: Text(t.title),
                                subtitle:
                                    subtitle.isEmpty ? null : Text(subtitle),
                                onTap: () => _edit(t),
                                trailing: IconButton(
                                  tooltip: 'حذف',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(t),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
