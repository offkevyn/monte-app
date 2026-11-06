import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/time/local_date.dart';

void main() {
  group('LocalDate', () {
    test('rejects days that do not exist', () {
      expect(() => LocalDate(2026, 2, 29), throwsArgumentError);
      expect(() => LocalDate(2026, 4, 31), throwsArgumentError);
      expect(() => LocalDate(2026, 13, 1), throwsArgumentError);
      expect(LocalDate(2028, 2, 29).day, 29); // leap year
    });

    test('adds days across month and year boundaries', () {
      expect(LocalDate(2026, 11, 30).addDays(1), LocalDate(2026, 12, 1));
      expect(LocalDate(2026, 12, 31).addDays(1), LocalDate(2027, 1, 1));
      expect(LocalDate(2027, 3, 1).addDays(-1), LocalDate(2027, 2, 28));
      expect(LocalDate(2028, 3, 1).addDays(-1), LocalDate(2028, 2, 29));
    });

    test('counts whole days between dates', () {
      final start = LocalDate(2026, 11, 5);
      expect(start.daysUntil(start), 0);
      expect(start.daysUntil(LocalDate(2026, 12, 5)), 30);
      expect(start.daysUntil(LocalDate(2026, 11, 1)), -4);
      expect(LocalDate(2028, 2, 28).daysUntil(LocalDate(2028, 3, 1)), 2);
    });

    test('finds the first and last day of the month', () {
      expect(LocalDate(2026, 11, 17).firstDayOfMonth, LocalDate(2026, 11, 1));
      expect(LocalDate(2026, 11, 17).lastDayOfMonth, LocalDate(2026, 11, 30));
      expect(LocalDate(2026, 12, 5).lastDayOfMonth, LocalDate(2026, 12, 31));
      expect(LocalDate(2027, 2, 5).lastDayOfMonth, LocalDate(2027, 2, 28));
      expect(LocalDate(2028, 2, 5).lastDayOfMonth, LocalDate(2028, 2, 29));
    });

    test('orders and compares by value', () {
      final a = LocalDate(2026, 11, 5);
      final b = LocalDate(2026, 11, 6);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a, LocalDate(2026, 11, 5));
      expect(a.hashCode, LocalDate(2026, 11, 5).hashCode);
      expect([b, a]..sort(), [a, b]);
      expect(LocalDate(2025, 12, 31).isBefore(LocalDate(2026, 1, 1)), isTrue);
    });

    test('knows the weekday and prints ISO', () {
      expect(LocalDate(2026, 11, 5).weekday, DateTime.thursday);
      expect(LocalDate(2026, 1, 9).toString(), '2026-01-09');
    });
  });
}
