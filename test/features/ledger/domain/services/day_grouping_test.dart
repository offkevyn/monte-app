import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/services/day_grouping.dart';

import '../../../../helpers/transactions.dart';

void main() {
  const calendar = FixedOffsetCalendar.brasilia;

  test('empty list gives no groups', () {
    expect(DayGrouping.group(const [], calendar), isEmpty);
  });

  test('groups by the local day, not the UTC day', () {
    final lateNight = expense(
      1,
      id: 'late',
      at: DateTime.utc(2026, 11, 6, 2, 30),
    );
    final morning = expense(
      2,
      id: 'morning',
      at: DateTime.utc(2026, 11, 5, 12),
    );
    final nextDay = expense(3, id: 'next', at: DateTime.utc(2026, 11, 6, 3));

    final groups = DayGrouping.group([morning, nextDay, lateNight], calendar);

    expect(groups.map((g) => g.date), [
      LocalDate(2026, 11, 6),
      LocalDate(2026, 11, 5),
    ]);
    // 23:30 on the 5th in Brasília joins the 5th, newest first.
    expect(groups[1].transactions, [lateNight, morning]);
    expect(groups[0].transactions, [nextDay]);
  });

  test('day split between two pages ends up in one section', () {
    final page1 = [
      expense(1, id: 'a', at: DateTime.utc(2026, 11, 5, 20)),
      expense(2, id: 'b', at: DateTime.utc(2026, 11, 5, 18)),
    ];
    final page2 = [
      expense(3, id: 'c', at: DateTime.utc(2026, 11, 5, 10)),
      expense(4, id: 'd', at: DateTime.utc(2026, 11, 4, 10)),
    ];

    final groups = DayGrouping.group([...page1, ...page2], calendar);

    expect(groups, hasLength(2));
    expect(groups.first.transactions.map((t) => t.id), ['a', 'b', 'c']);
  });

  test('same instant is ordered by id so the list never jumps', () {
    final at = DateTime.utc(2026, 11, 5, 12);
    final groups = DayGrouping.group([
      expense(1, id: 'b', at: at),
      expense(1, id: 'a', at: at),
    ], calendar);
    expect(groups.single.transactions.map((t) => t.id), ['a', 'b']);
  });

  test('day net counts only completed transactions', () {
    final groups = DayGrouping.group([
      income(10000, id: 'a'),
      expense(2500, id: 'b'),
      expense(9999, id: 'c', status: TransactionStatus.pending),
      income(5000, id: 'd', status: TransactionStatus.reversed),
    ], calendar);

    expect(groups.single.net, const Money.cents(7500));
  });

  test('groups compare by value', () {
    final a = DayGroup(date: LocalDate(2026, 11, 5), transactions: [tx()]);
    final b = DayGroup(date: LocalDate(2026, 11, 5), transactions: [tx()]);
    final c = DayGroup(
      date: LocalDate(2026, 11, 5),
      transactions: [tx(id: 'x')],
    );
    final d = DayGroup(date: LocalDate(2026, 11, 5), transactions: const []);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
    expect(a, isNot(d));
    expect(a.toString(), contains('1 items'));
  });
}
