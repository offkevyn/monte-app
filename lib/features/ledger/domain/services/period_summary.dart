import 'package:meta/meta.dart';

import '../../../../core/money/money.dart';
import '../../../../core/time/local_calendar.dart';
import '../entities/date_span.dart';
import '../entities/transaction.dart';

/// Income and expense of a period. Only completed transactions count: a
/// pending purchase may still fail, and a reversed one never happened.
@immutable
final class PeriodTotals {
  const PeriodTotals({
    required this.income,
    required this.expense,
    required this.count,
  });

  static const empty = PeriodTotals(
    income: Money.zero,
    expense: Money.zero,
    count: 0,
  );

  /// Sum of incoming amounts (positive).
  final Money income;

  /// Sum of outgoing amounts (positive).
  final Money expense;

  /// How many completed transactions were counted.
  final int count;

  Money get net => income - expense;

  PeriodTotals add(Transaction transaction) => PeriodTotals(
    income: transaction.isIncome ? income + transaction.amount : income,
    expense: transaction.isExpense ? expense + transaction.amount : expense,
    count: count + 1,
  );

  @override
  bool operator ==(Object other) =>
      other is PeriodTotals &&
      other.income == income &&
      other.expense == expense &&
      other.count == count;

  @override
  int get hashCode => Object.hash(income, expense, count);

  @override
  String toString() => 'PeriodTotals(in: $income, out: $expense, n: $count)';
}

/// One bar of the dashboard chart.
@immutable
final class ChartBucket {
  const ChartBucket({required this.span, required this.totals});

  final DateSpan span;
  final PeriodTotals totals;

  @override
  bool operator ==(Object other) =>
      other is ChartBucket && other.span == span && other.totals == totals;

  @override
  int get hashCode => Object.hash(span, totals);

  @override
  String toString() => 'ChartBucket($span, $totals)';
}

enum ChartGranularity { day, week }

@immutable
final class PeriodSummary {
  PeriodSummary({
    required this.period,
    required this.totals,
    required List<ChartBucket> buckets,
    required this.granularity,
  }) : buckets = List.unmodifiable(buckets);

  final DateSpan period;
  final PeriodTotals totals;

  /// Oldest first, one per day or per week, empty buckets included so the
  /// chart shows the quiet days too.
  final List<ChartBucket> buckets;
  final ChartGranularity granularity;
}

/// Builds the dashboard numbers for a period.
abstract final class PeriodSummarizer {
  /// Periods up to this many days get one bar per day; longer ones get one
  /// bar per week so the chart stays readable on a phone.
  static const maxDailyBars = 31;

  static PeriodSummary summarize({
    required Iterable<Transaction> transactions,
    required DateSpan period,
    required LocalCalendar calendar,
  }) {
    final granularity = period.lengthInDays <= maxDailyBars
        ? ChartGranularity.day
        : ChartGranularity.week;
    final bucketDays = granularity == ChartGranularity.day ? 1 : 7;
    final bucketCount = (period.lengthInDays + bucketDays - 1) ~/ bucketDays;
    final bucketTotals = List.filled(bucketCount, PeriodTotals.empty);
    final range = calendar.rangeOf(period.first, period.last);

    var totals = PeriodTotals.empty;
    for (final transaction in transactions) {
      if (transaction.status != TransactionStatus.completed) continue;
      if (!range.contains(transaction.occurredAt)) continue;

      totals = totals.add(transaction);
      final day = calendar.dateOf(transaction.occurredAt);
      final index = period.first.daysUntil(day) ~/ bucketDays;
      bucketTotals[index] = bucketTotals[index].add(transaction);
    }

    final buckets = [
      for (var i = 0; i < bucketCount; i++)
        ChartBucket(
          span: DateSpan(
            period.first.addDays(i * bucketDays),
            _min(period.first.addDays((i + 1) * bucketDays - 1), period.last),
          ),
          totals: bucketTotals[i],
        ),
    ];

    return PeriodSummary(
      period: period,
      totals: totals,
      buckets: buckets,
      granularity: granularity,
    );
  }

  static T _min<T extends Comparable<T>>(T a, T b) =>
      a.compareTo(b) <= 0 ? a : b;
}
