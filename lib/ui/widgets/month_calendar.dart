import 'package:material_ui/material_ui.dart';

import '../../core/date_utils.dart';
import '../../data/models/day_summary.dart';

/// تقويم شهري يبدأ بالسبت، يلوّن كل يوم حسب نسبة إنجاز مهامه
/// ويضع نقطة تحت الأيام التي فيها تدوينة.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.summaries,
    required this.onDayTap,
  });

  /// أي تاريخ داخل الشهر المعروض.
  final DateTime month;
  final Map<String, DaySummary> summaries;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final blanks = ArabicDates.leadingBlanks(first);
    final cellCount = ((blanks + daysInMonth + 6) ~/ 7) * 7;
    final today = DateKey.todayDate();

    return Column(
      children: [
        Row(
          children: [
            for (final name in ArabicDates.calendarHeader)
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - blanks + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(month.year, month.month, dayNumber);
            return _DayCell(
              date: date,
              summary: summaries[DateKey.fromDate(date)],
              isToday: date == today,
              isFuture: date.isAfter(today),
              onTap: () => onDayTap(date),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.summary,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime date;
  final DaySummary? summary;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = summary;

    Color background = Colors.transparent;
    Color foreground = isFuture ? scheme.outline : scheme.onSurface;
    if (s != null && s.total > 0) {
      if (s.isComplete) {
        background = scheme.primary;
        foreground = scheme.onPrimary;
      } else if (s.done > 0) {
        background = scheme.primaryContainer;
        foreground = scheme.onPrimaryContainer;
      } else {
        background = scheme.surfaceContainerHighest;
        foreground = scheme.onSurfaceVariant;
      }
    }

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isToday
            ? BorderSide(color: scheme.tertiary, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isFuture ? null : onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: foreground,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (s?.hasJournal ?? false)
                    ? (s!.isComplete ? scheme.onPrimary : scheme.tertiary)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// مفتاح ألوان التقويم.
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall;

    Widget swatch(Color color, String label, {bool dot = false}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: dot ? 7 : 14,
              height: dot ? 7 : 14,
              decoration: BoxDecoration(
                color: color,
                shape: dot ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: dot ? null : BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Text(label, style: style),
          ],
        );

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        swatch(scheme.surfaceContainerHighest, 'لا إنجاز'),
        swatch(scheme.primaryContainer, 'إنجاز جزئي'),
        swatch(scheme.primary, 'إنجاز كامل'),
        swatch(scheme.tertiary, 'تدوينة', dot: true),
      ],
    );
  }
}
