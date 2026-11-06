import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';

void main() {
  const brasilia = FixedOffsetCalendar.brasilia;

  group('FixedOffsetCalendar (Brasília, UTC-3)', () {
    test('a purchase at 23:30 local stays on that day, '
        'even though it is already the next day in UTC', () {
      final instant = DateTime.utc(2026, 11, 6, 2, 30); // 05/11 23:30 BRT

      expect(instant.day, 6, reason: 'the naive UTC day is wrong');
      expect(brasilia.dateOf(instant), LocalDate(2026, 11, 5));

      final wallClock = brasilia.wallClockOf(instant);
      expect((wallClock.hour, wallClock.minute), (23, 30));
    });

    test('last second of the month stays in the month', () {
      expect(
        brasilia.dateOf(DateTime.utc(2026, 12, 1, 2, 59, 59)),
        LocalDate(2026, 11, 30),
      );
      expect(
        brasilia.dateOf(DateTime.utc(2026, 12, 1, 3)),
        LocalDate(2026, 12, 1),
      );
    });

    test('new year in UTC is still 31/12 in Brasília', () {
      expect(
        brasilia.dateOf(DateTime.utc(2027, 1, 1, 1)),
        LocalDate(2026, 12, 31),
      );
    });

    test('local midnight is 03:00 UTC', () {
      expect(
        brasilia.startOf(LocalDate(2026, 11, 5)),
        DateTime.utc(2026, 11, 5, 3),
      );
    });

    test('a period ending on the 30th includes up to 23:59:59.999 local', () {
      final november = brasilia.rangeOf(
        LocalDate(2026, 11, 1),
        LocalDate(2026, 11, 30),
      );

      expect(november.start, DateTime.utc(2026, 11, 1, 3));
      expect(november.end, DateTime.utc(2026, 12, 1, 3));

      // 30/11 23:59:59.999 local
      expect(
        november.contains(DateTime.utc(2026, 12, 1, 2, 59, 59, 999)),
        isTrue,
      );
      // 01/12 00:00 local
      expect(november.contains(DateTime.utc(2026, 12, 1, 3)), isFalse);
      // 31/10 23:59:59 local
      expect(november.contains(DateTime.utc(2026, 11, 1, 2, 59, 59)), isFalse);
      // 01/11 00:00 local
      expect(november.contains(DateTime.utc(2026, 11, 1, 3)), isTrue);
    });

    test('a single day period covers exactly 24 hours', () {
      final day = brasilia.rangeOf(
        LocalDate(2026, 11, 5),
        LocalDate(2026, 11, 5),
      );
      expect(day.end.difference(day.start), const Duration(hours: 24));
    });

    test('accepts instants that are not flagged as UTC', () {
      final instant = DateTime.utc(2026, 11, 6, 2, 30);
      expect(brasilia.dateOf(instant.toLocal()), LocalDate(2026, 11, 5));
    });
  });

  group('DeviceCalendar', () {
    // CI runs these under TZ=America/Sao_Paulo and TZ=UTC; the properties
    // below must hold in any time zone.
    const device = DeviceCalendar();

    test('the start of a day falls on that same day', () {
      for (final date in [
        LocalDate(2026, 11, 5),
        LocalDate(2026, 12, 31),
        LocalDate(2028, 2, 29),
      ]) {
        final start = device.startOf(date);
        expect(start.isUtc, isTrue);
        expect(device.dateOf(start), date);
        expect(
          device.dateOf(start.subtract(const Duration(milliseconds: 1))),
          date.addDays(-1),
        );
      }
    });

    test('consecutive days form ranges with no gap', () {
      final first = device.rangeOf(
        LocalDate(2026, 11, 5),
        LocalDate(2026, 11, 5),
      );
      final second = device.rangeOf(
        LocalDate(2026, 11, 6),
        LocalDate(2026, 11, 6),
      );
      expect(first.end, second.start);
    });

    test('wall clock matches the device local time', () {
      final instant = DateTime.utc(2026, 11, 6, 2, 30);
      expect(device.wallClockOf(instant), instant.toLocal());
    });
  });

  group('UtcRange', () {
    test('rejects an empty or inverted range', () {
      final t = DateTime.utc(2026, 11, 5);
      expect(() => UtcRange(t, t), throwsArgumentError);
      expect(
        () => UtcRange(t, t.subtract(const Duration(seconds: 1))),
        throwsArgumentError,
      );
    });

    test('compares by value', () {
      final a = UtcRange(DateTime.utc(2026), DateTime.utc(2027));
      final b = UtcRange(DateTime.utc(2026), DateTime.utc(2027));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
