import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../data/models/daily_task.dart';
import '../../state/today_controller.dart';
import '../widgets/dialogs.dart';
import '../widgets/progress_card.dart';
import '../widgets/task_form_sheet.dart';

/// الشاشة الرئيسية: مهام اليوم مع شريط التقدم.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final controller = context.read<TodayController>();
    final result = await showTaskFormSheet(
      context,
      heading: 'مهمة جديدة لليوم',
      showRoutineOption: true,
    );
    if (result == null) return;
    await controller.addTask(
      title: result.title,
      duration: result.duration,
      note: result.note,
      addToRoutine: result.addToRoutine,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TodayController>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('مهام اليوم'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('مهمة جديدة'),
      ),
      body: c.loading
          ? const Center(child: CircularProgressIndicator())
          : c.error != null
              ? _ErrorView(message: c.error!, onRetry: c.reload)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    Text(
                      ArabicDates.fullDate(c.date),
                      style: text.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ProgressCard(done: c.doneCount, total: c.total),
                    const SizedBox(height: 16),
                    if (c.tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(Icons.checklist,
                                size: 56, color: scheme.outline),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد مهام لهذا اليوم',
                              style: text.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    else
                      for (final task in c.tasks)
                        _TaskTile(key: ValueKey(task.id), task: task),
                  ],
                ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({super.key, required this.task});

  final DailyTask task;

  Future<void> _edit(BuildContext context) async {
    final controller = context.read<TodayController>();
    final result = await showTaskFormSheet(
      context,
      heading: 'تعديل المهمة',
      initialTitle: task.title,
      initialDuration: task.duration,
      initialNote: task.note,
      hint: task.isFromRoutine
          ? 'التعديل هنا يخص اليوم فقط. لتغيير المهمة في الأيام القادمة عدّلها من «الروتين اليومي» في الإعدادات.'
          : null,
    );
    if (result == null) return;
    await controller.updateTask(
      task.copyWith(
        title: result.title,
        duration: result.duration,
        note: result.note,
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final controller = context.read<TodayController>();
    final ok = await confirmDialog(
      context,
      title: 'حذف المهمة',
      message: 'هل تريد حذف «${task.title}» من قائمة اليوم؟',
    );
    if (ok) await controller.deleteTask(task);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final meta = <Widget>[
      if ((task.duration ?? '').isNotEmpty)
        _MetaChip(icon: Icons.schedule, label: task.duration!),
      if ((task.note ?? '').isNotEmpty)
        _MetaChip(icon: Icons.wb_twilight, label: task.note!),
      if (task.isFromRoutine)
        const _MetaChip(icon: Icons.repeat, label: 'روتين'),
    ];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: task.isDone
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : scheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.read<TodayController>().toggle(task),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: task.isDone,
                onChanged: (_) => context.read<TodayController>().toggle(task),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: text.titleMedium?.copyWith(
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                          color: task.isDone
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(spacing: 12, runSpacing: 4, children: meta),
                      ],
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'خيارات',
                onSelected: (v) {
                  if (v == 'edit') _edit(context);
                  if (v == 'delete') _delete(context);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('تعديل'),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('حذف'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
