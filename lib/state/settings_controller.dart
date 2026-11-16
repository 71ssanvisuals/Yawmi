import 'package:material_ui/material_ui.dart';

import '../data/planner_repository.dart';

/// إعدادات المظهر (فاتح / داكن / حسب النظام) محفوظة في قاعدة البيانات.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repo);

  final PlannerRepository _repo;
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      final saved = await _repo.getSetting(_themeKey);
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      // عند أي خطأ نبدأ بالمظهر الافتراضي، ولا نمنع فتح التطبيق.
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _repo.setSetting(_themeKey, mode.name);
  }
}
