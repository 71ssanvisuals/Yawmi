import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/today_controller.dart';
import 'screens/history_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';

/// الهيكل الرئيسي بأربعة تبويبات. IndexedStack يُبقي حالة كل تبويب
/// (مثل نص التدوينة) محفوظة عند التنقل بينها.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // زر الرجوع في أي تبويب غير الأول يعيد إلى «اليوم» بدل إغلاق التطبيق.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            TodayScreen(),
            _TodayJournalTab(),
            HistoryScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'اليوم',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note_outlined),
              selectedIcon: Icon(Icons.edit_note),
              label: 'التدوينة',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'السجل',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

/// تبويب التدوينة يتبع تاريخ اليوم الحالي، وينتقل تلقائياً عند بداية يوم جديد.
class _TodayJournalTab extends StatelessWidget {
  const _TodayJournalTab();

  @override
  Widget build(BuildContext context) {
    final dateKey = context.select<TodayController, String>((c) => c.dateKey);
    return JournalScreen(dateKey: dateKey);
  }
}
