import 'package:material_ui/material_ui.dart';

/// تقييم بالنجوم من 1 إلى 5. إن لم يُمرَّر [onChanged] يصبح للعرض فقط.
/// الضغط على النجمة المختارة نفسها يلغي التقييم.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 34,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Colors.amber.shade600;
    final empty = Theme.of(context).colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= value;
        final icon = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? color : empty,
        );
        if (onChanged == null) return icon;
        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: '$star من 5',
          onPressed: () => onChanged!(star == value ? 0 : star),
          icon: icon,
        );
      }),
    );
  }
}
