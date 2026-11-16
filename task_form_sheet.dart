import 'package:material_ui/material_ui.dart';

/// نتيجة نموذج إضافة/تعديل مهمة.
class TaskFormResult {
  const TaskFormResult({
    required this.title,
    this.duration,
    this.note,
    this.addToRoutine = false,
  });

  final String title;
  final String? duration;
  final String? note;
  final bool addToRoutine;
}

/// يفتح نموذج المهمة من أسفل الشاشة، ويعيد null إن أُغلق دون حفظ.
Future<TaskFormResult?> showTaskFormSheet(
  BuildContext context, {
  required String heading,
  String? initialTitle,
  String? initialDuration,
  String? initialNote,
  bool showRoutineOption = false,
  String? hint,
}) {
  return showModalBottomSheet<TaskFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _TaskForm(
      heading: heading,
      initialTitle: initialTitle,
      initialDuration: initialDuration,
      initialNote: initialNote,
      showRoutineOption: showRoutineOption,
      hint: hint,
    ),
  );
}

class _TaskForm extends StatefulWidget {
  const _TaskForm({
    required this.heading,
    this.initialTitle,
    this.initialDuration,
    this.initialNote,
    required this.showRoutineOption,
    this.hint,
  });

  final String heading;
  final String? initialTitle;
  final String? initialDuration;
  final String? initialNote;
  final bool showRoutineOption;
  final String? hint;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title =
      TextEditingController(text: widget.initialTitle);
  late final TextEditingController _duration =
      TextEditingController(text: widget.initialDuration);
  late final TextEditingController _note =
      TextEditingController(text: widget.initialNote);
  bool _addToRoutine = false;

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      TaskFormResult(
        title: _title.text.trim(),
        duration: _duration.text.trim(),
        note: _note.text.trim(),
        addToRoutine: _addToRoutine,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.heading, style: text.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                autofocus: widget.initialTitle == null,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'اسم المهمة',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'اكتب اسم المهمة' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _duration,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'المدة (اختياري)',
                  hintText: 'مثال: 30 دقيقة',
                  prefixIcon: Icon(Icons.schedule),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'التوقيت أو ملاحظة (اختياري)',
                  hintText: 'مثال: بعد الفجر',
                  prefixIcon: Icon(Icons.wb_twilight),
                  border: OutlineInputBorder(),
                ),
              ),
              if (widget.showRoutineOption) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _addToRoutine,
                  onChanged: (v) => setState(() => _addToRoutine = v),
                  title: const Text('أضفها إلى الروتين اليومي'),
                  subtitle: const Text('تتكرر تلقائياً في كل يوم جديد'),
                ),
              ],
              if (widget.hint != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.hint!,
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
