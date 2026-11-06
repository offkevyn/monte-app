import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/services/period_summary.dart';

import '../../../../helpers/transactions.dart';

void main() {
  const calendar = FixedOffsetCalendar.brasilia;
  final november = DateSpan(LocalDate(2026, 11, 1), LocalDate(2026, 11, 30));

  PeriodSummary summarize(List<Transaction> transactions, [DateSpan? period]) =>
      PeriodSummarizer.summarize(
        transactions: transactions,
        period: period ?? november,
        calendar: calendar,
      );

  test('empty period: zeros everywhere, but still one bar per day', () {
    final summary = summarize(const []);
    expect(summary.totals, PeriodTotals.empty);
    expect(summary.totals.net, Money.zero);
    expect(summary.buckets, hasLength(30));
    expect(summary.granularity, ChartGranularity.day);
  });

  test('sums income and expense of completed transactions only', () {
    final summary = summarize([
      income(500000, id: 'a', at: DateTime.utc(2026, 11, 5, 12)),
      expense(12990, id: 'b', at: DateTime.utc(2026, 11, 6, 12)),
      expense(9999, id: 'c', status: TransactionStatus.pending),
      income(7000, id: 'd', status: TransactionStatus.failed),
      expense(8000, id: 'e', status: TransactionStatus.reversed),
    ]);

    expect(summary.totals.income, const Money.cents(500000));
    expect(summary.totals.expense, const Money.cents(12990));
    expect(summary.totals.net, const Money.cents(500000 - 12990));
    expect(summary.totals.count, 2);
  });

  test('23:30 on the last day counts; 00:00 of the next month does not', () {
    final summary = summarize([
      // 30/11 23:30 in Brasília = 01/12 02:30 UTC
      expense(1000, id: 'last-minute', at: DateTime.utc(2026, 12, 1, 2, 30)),
      // 01/12 00:00 in Brasília
      expense(2000, id: 'next-month', at: DateTime.utc(2026, 12, 1, 3)),
      // 31/10 23:59 in Brasília
      expense(4000, id: 'last-month', at: DateTime.utc(2026, 11, 1, 2, 59)),
    ]);

    expect(summary.totals.expense, const Money.cents(1000));
    expect(summary.buckets.last.totals.expense, const Money.cents(1000));
    expect(
      summary.buckets.last.span,
      DateSpan.singleDay(LocalDate(2026, 11, 30)),
    );
  });

  test('bars add up to the period totals', () {
    final transactions = [
      for (var day = 1; day <= 30; day++)
        income(day * 100, id: 'd$day', at: DateTime.utc(2026, 11, day, 15)),
    ];
    final summary = summarize(transactions);

    final fromBars = summary.buckets.fold(
      Money.zero,
      (sum, bucket) => sum + bucket.totals.income,
    );
    expect(fromBars, summary.totals.income);
    expect(summary.buckets[4].totals.income, const Money.cents(500));
  });

  test('long periods switch to weekly bars, last week may be shorter', () {
    final ninetyDays = PeriodPreset.last90Days.resolve(LocalDate(2026, 11, 30));
    final summary = summarize([
      expense(100, id: 'first', at: DateTime.utc(2026, 9, 2, 12)),
      expense(200, id: 'last', at: DateTime.utc(2026, 11, 30, 12)),
    ], ninetyDays);

    expect(summary.granularity, ChartGranularity.week);
    expect(summary.buckets, hasLength(13)); // 90 days = 12 weeks + 6 days
    expect(summary.buckets.first.span.lengthInDays, 7);
    expect(summary.buckets.last.span.lengthInDays, 6);
    expect(summary.buckets.last.span.last, LocalDate(2026, 11, 30));
    expect(summary.buckets.first.totals.expense, const Money.cents(100));
    expect(summary.buckets.last.totals.expense, const Money.cents(200));
  });

  test('31 days is still daily', () {
    final summary = summarize(
      const [],
      DateSpan(LocalDate(2026, 12, 1), LocalDate(2026, 12, 31)),
    );
    expect(summary.granularity, ChartGranularity.day);
    expect(summary.buckets, hasLength(31));
  });

  test('value objects compare by value', () {
    const totals = PeriodTotals(
      income: Money.cents(1),
      expense: Money.zero,
      count: 1,
    );
    expect(
      totals,
      const PeriodTotals(income: Money.cents(1), expense: Money.zero, count: 1),
    );
    expect(totals.hashCode, totals.hashCode);
    expect(totals.toString(), contains('in:'));

    final bucket = ChartBucket(
      span: DateSpan.singleDay(LocalDate(2026, 11, 1)),
      totals: totals,
    );
    expect(
      bucket,
      ChartBucket(
        span: DateSpan.singleDay(LocalDate(2026, 11, 1)),
        totals: totals,
      ),
    );
    expect(bucket.hashCode, isNot(0));
    expect(bucket.toString(), contains('2026-11-01'));
  });
}
