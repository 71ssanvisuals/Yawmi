import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/database_helper.dart';
import 'data/planner_repository.dart';
import 'state/settings_controller.dart';
import 'state/today_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = PlannerRepository(DatabaseHelper.instance);
  final settings = SettingsController(repository);
  // تحميل المظهر قبل أول رسم لتجنّب وميض الألوان عند الفتح.
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        Provider<PlannerRepository>.value(value: repository),
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<TodayController>(
          create: (_) => TodayController(repository)..init(),
        ),
      ],
      child: const YawmiApp(),
    ),
  );
}
