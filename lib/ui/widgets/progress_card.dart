import 'package:material_ui/material_ui.dart';

/// بطاقة نسبة الإنجاز مع شريط تقدم.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.done,
    required this.total,
    this.title,
  });

  final int done;
  final int total;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ratio = total == 0 ? 0.0 : done / total;
    final percent = (ratio * 100).round();
    final allDone = total > 0 && done == total;

    final String message;
    if (total == 0) {
      message = 'لا توجد مهام بعد';
    } else if (allDone) {
      message = 'أحسنت، أتممت كل المهام 🎉';
    } else {
      message = 'أنجزت $done من $total';
    }

    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: text.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: text.bodyLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: text.headlineSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: scheme.surface.withValues(alpha: 0.6),
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
