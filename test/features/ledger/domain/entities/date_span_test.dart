import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';

void main() {
  group('DateSpan', () {
    test('swaps dates picked in reverse order', () {
      final span = DateSpan(LocalDate(2026, 11, 30), LocalDate(2026, 11, 1));
      expect(span.first, LocalDate(2026, 11, 1));
      expect(span.last, LocalDate(2026, 11, 30));
    });

    test('counts both ends', () {
      expect(DateSpan.singleDay(LocalDate(2026, 11, 5)).lengthInDays, 1);
      expect(
        DateSpan(LocalDate(2026, 11, 1), LocalDate(2026, 11, 30)).lengthInDays,
        30,
      );
      expect(
        DateSpan(LocalDate(2026, 12, 25), LocalDate(2027, 1, 5)).lengthInDays,
        12,
      );
    });

    test('contains its ends and nothing outside', () {
      final span = DateSpan(LocalDate(2026, 11, 1), LocalDate(2026, 11, 30));
      expect(span.contains(LocalDate(2026, 11, 1)), isTrue);
      expect(span.contains(LocalDate(2026, 11, 30)), isTrue);
      expect(span.contains(LocalDate(2026, 10, 31)), isFalse);
      expect(span.contains(LocalDate(2026, 12, 1)), isFalse);
    });

    test('lists its days in order', () {
      final span = DateSpan(LocalDate(2026, 12, 30), LocalDate(2027, 1, 2));
      expect(span.days, [
        LocalDate(2026, 12, 30),
        LocalDate(2026, 12, 31),
        LocalDate(2027, 1, 1),
        LocalDate(2027, 1, 2),
      ]);
    });

    test('compares by value', () {
      final a = DateSpan.singleDay(LocalDate(2026, 11, 5));
      expect(a, DateSpan.singleDay(LocalDate(2026, 11, 5)));
      expect(a.hashCode, DateSpan.singleDay(LocalDate(2026, 11, 5)).hashCode);
      expect(a.toString(), 'DateSpan(2026-11-05..2026-11-05)');
    });
  });

  group('PeriodPreset', () {
    final today = LocalDate(2026, 11, 5);

    test('rolling windows end today and include it', () {
      expect(
        PeriodPreset.last7Days.resolve(today),
        DateSpan(LocalDate(2026, 10, 30), today),
      );
      expect(PeriodPreset.last7Days.resolve(today).lengthInDays, 7);
      expect(PeriodPreset.last30Days.resolve(today).lengthInDays, 30);
      expect(PeriodPreset.last90Days.resolve(today).lengthInDays, 90);
    });

    test('this month goes from day 1 to today', () {
      expect(
        PeriodPreset.thisMonth.resolve(today),
        DateSpan(LocalDate(2026, 11, 1), today),
      );
      final firstDay = LocalDate(2026, 11, 1);
      expect(
        PeriodPreset.thisMonth.resolve(firstDay),
        DateSpan.singleDay(firstDay),
      );
    });

    test('last month is the whole previous month, across the year', () {
      expect(
        PeriodPreset.lastMonth.resolve(today),
        DateSpan(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31)),
      );
      expect(
        PeriodPreset.lastMonth.resolve(LocalDate(2027, 1, 15)),
        DateSpan(LocalDate(2026, 12, 1), LocalDate(2026, 12, 31)),
      );
      expect(
        PeriodPreset.lastMonth.resolve(LocalDate(2028, 3, 31)),
        DateSpan(LocalDate(2028, 2, 1), LocalDate(2028, 2, 29)),
      );
    });
  });
}
