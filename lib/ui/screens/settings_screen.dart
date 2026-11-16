import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';
import 'routine_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('المظهر', style: text.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('تلقائي'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('فاتح'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('داكن'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
          const SizedBox(height: 24),
          Text('المهام', style: text.titleMedium),
          const SizedBox(height: 4),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('الروتين اليومي'),
              subtitle: const Text('المهام التي تُنشأ تلقائياً كل يوم'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RoutineScreen()),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('عن التطبيق', style: text.titleMedium),
          const SizedBox(height: 4),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('بياناتك على هاتفك فقط'),
              subtitle: Text(
                'تُحفظ المهام والتدوينات في قاعدة بيانات محلية، '
                'ويعمل التطبيق بالكامل دون إنترنت.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
