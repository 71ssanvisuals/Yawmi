/// أدوات التعامل مع التواريخ.
///
/// نخزّن كل يوم في قاعدة البيانات بمفتاح نصي ثابت بصيغة `yyyy-MM-dd`
/// (بالتوقيت المحلي للهاتف)، لأنه يُرتَّب أبجدياً بالترتيب الزمني نفسه
/// ويسهل الاستعلام عنه بـ BETWEEN.
class DateKey {
  DateKey._();

  static String fromDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime toDate(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static String today() => fromDate(DateTime.now());

  /// تاريخ اليوم بلا ساعات ودقائق.
  static DateTime todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

/// أسماء الأيام والشهور بالعربية دون الاعتماد على بيانات لغة خارجية.
class ArabicDates {
  ArabicDates._();

  /// مرتبة حسب [DateTime.weekday]: الاثنين = 1 ... الأحد = 7.
  static const List<String> weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<String> months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// رؤوس أعمدة التقويم، والأسبوع يبدأ بالسبت.
  static const List<String> calendarHeader = [
    'سبت',
    'أحد',
    'اثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
  ];

  static String weekday(DateTime d) => weekdays[d.weekday - 1];

  /// مثال: الاثنين، 16 نوفمبر 2026
  static String fullDate(DateTime d) =>
      '${weekday(d)}، ${d.day} ${months[d.month - 1]} ${d.year}';

  /// مثال: 16 نوفمبر
  static String dayMonth(DateTime d) => '${d.day} ${months[d.month - 1]}';

  /// مثال: نوفمبر 2026
  static String monthYear(DateTime d) => '${months[d.month - 1]} ${d.year}';

  /// عدد الخانات الفارغة قبل اليوم الأول من الشهر في تقويم يبدأ بالسبت.
  static int leadingBlanks(DateTime firstOfMonth) =>
      (firstOfMonth.weekday - DateTime.saturday) % 7;
}
