import 'package:material_ui/material_ui.dart';

/// ألوان التطبيق مبنية على لون أساسي واحد بنظام Material 3،
/// فيتولّد منه وضع فاتح ووضع داكن متناسقان تلقائياً.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF2E7D6B);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
    );
  }
}
