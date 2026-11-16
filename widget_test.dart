import 'package:flutter_test/flutter_test.dart';
import 'package:yawmi/core/date_utils.dart';
import 'package:yawmi/data/models/journal_entry.dart';

void main() {
  group('DateKey', () {
    test('يحوّل التاريخ إلى مفتاح والعكس', () {
      final d = DateTime(2026, 3, 7);
      expect(DateKey.fromDate(d), '2026-03-07');
      expect(DateKey.toDate('2026-03-07'), d);
    });

    test('المفاتيح تُرتَّب زمنياً', () {
      final keys = ['2026-11-02', '2025-12-31', '2026-01-15']..sort();
      expect(keys, ['2025-12-31', '2026-01-15', '2026-11-02']);
    });
  });

  group('ArabicDates', () {
    test('اسم اليوم والشهر', () {
      // 16 نوفمبر 2026 يوم اثنين.
      expect(
        ArabicDates.fullDate(DateTime(2026, 11, 16)),
        'الاثنين، 16 نوفمبر 2026',
      );
    });

    test('خانات بداية الشهر في تقويم يبدأ بالسبت', () {
      // 1 نوفمبر 2026 يوم أحد ← خانة واحدة فارغة (السبت).
      expect(ArabicDates.leadingBlanks(DateTime(2026, 11, 1)), 1);
      // 1 أغسطس 2026 يوم سبت ← لا خانات فارغة.
      expect(ArabicDates.leadingBlanks(DateTime(2026, 8, 1)), 0);
    });
  });

  test('التدوينة الفارغة تُعرَف كفارغة', () {
    expect(const JournalEntry(date: '2026-11-16').isEmpty, isTrue);
    expect(const JournalEntry(date: '2026-11-16', rating: 3).isEmpty, isFalse);
  });
}
