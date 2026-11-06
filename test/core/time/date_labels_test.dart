import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/core/time/date_labels.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';

void main() {
  // Thursday 05/11/2026, 23:30 in Brasília (already the 6th in UTC).
  final clock = FixedClock(DateTime.utc(2026, 11, 6, 2, 30));
  final labels = DateLabels(clock, FixedOffsetCalendar.brasilia);

  test('today is the user day, not the UTC day', () {
    expect(labels.today, LocalDate(2026, 11, 5));
  });

  test('greeting follows the local hour', () {
    String at(int utcHour) => DateLabels(
      FixedClock(DateTime.utc(2026, 11, 5, utcHour)),
      FixedOffsetCalendar.brasilia,
    ).greeting();
    expect(at(11), 'Bom dia'); // 08:00
    expect(at(16), 'Boa tarde'); // 13:00
    expect(at(23), 'Boa noite'); // 20:00
    expect(at(7), 'Boa noite'); // 04:00
  });

  test('day and time: today, yesterday, this year, other years', () {
    expect(labels.dayAndTime(DateTime.utc(2026, 11, 6, 1, 15)), 'Hoje · 22:15');
    expect(
      labels.dayAndTime(DateTime.utc(2026, 11, 4, 12, 5)),
      'Ontem · 09:05',
    );
    expect(labels.dayAndTime(DateTime.utc(2026, 10, 30, 22)), '30/10 · 19:00');
    expect(
      labels.dayAndTime(DateTime.utc(2025, 12, 31, 12)),
      '31/12/2025 · 09:00',
    );
  });

  test('day headers for the statement', () {
    expect(labels.day(LocalDate(2026, 11, 5)), 'Hoje');
    expect(labels.day(LocalDate(2026, 11, 4)), 'Ontem');
    expect(labels.day(LocalDate(2026, 11, 2)), 'seg, 02 de nov');
    expect(labels.day(LocalDate(2025, 11, 2)), 'dom, 02 de nov de 2025');
  });

  test('statement day headers', () {
    expect(labels.dayHeader(LocalDate(2026, 11, 5)), 'Hoje · 5 de nov');
    expect(labels.dayHeader(LocalDate(2026, 11, 4)), 'Ontem · 4 de nov');
    expect(labels.dayHeader(LocalDate(2026, 11, 2)), 'Seg · 2 de nov');
    expect(labels.dayHeader(LocalDate(2025, 11, 2)), 'Dom · 2 de nov de 2025');
  });

  test('full date and time in the user day', () {
    expect(
      labels.fullDateAndTime(DateTime.utc(2026, 11, 5, 1, 15)),
      '04/11/2026 · 22:15',
    );
  });

  test('month names', () {
    expect(labels.month(LocalDate(2026, 3, 1)), 'Março');
    expect(labels.monthShort(LocalDate(2026, 3, 1)), 'mar');
    expect(labels.fullDate(LocalDate(2026, 1, 9)), '09/01/2026');
  });
}
