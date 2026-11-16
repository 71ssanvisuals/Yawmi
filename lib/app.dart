import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'state/settings_controller.dart';
import 'ui/home_shell.dart';

class YawmiApp extends StatelessWidget {
  const YawmiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsController, ThemeMode>(
      (s) => s.themeMode,
    );

    return MaterialApp(
      title: 'يومي',
      debugShowCheckedModeBanner: false,
      // العربية لغة وحيدة للتطبيق، فيصبح الاتجاه من اليمين لليسار تلقائياً.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}
