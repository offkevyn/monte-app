import 'package:meta/meta.dart';

import '../../../../core/result/result.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/local_calendar.dart';
import '../entities/date_span.dart';
import '../entities/ledger_snapshot.dart';
import '../entities/transaction.dart';
import '../repositories/ledger_repository.dart';
import '../services/balance_calculator.dart';
import '../services/period_summary.dart';

/// Everything the dashboard shows, computed from one snapshot.
@immutable
final class DashboardSummary {
  DashboardSummary({
    required this.balance,
    required this.summary,
    required List<Transaction> recent,
    required this.freshness,
  }) : recent = List.unmodifiable(recent);

  final BalanceBreakdown balance;
  final PeriodSummary summary;

  /// Latest transactions of any status, newest first.
  final List<Transaction> recent;
  final DataFreshness freshness;
}

/// Loads the ledger once and derives balance, period totals, chart and the
/// latest transactions from it.
final class GetDashboard {
  const GetDashboard(this._repository, this._clock, this._calendar);

  final LedgerRepository _repository;
  final Clock _clock;
  final LocalCalendar _calendar;

  static const recentCount = 5;

  Future<Result<DashboardSummary>> call({
    PeriodPreset preset = PeriodPreset.thisMonth,
    DateSpan? customPeriod,
    bool forceRefresh = false,
  }) async {
    final result = await _repository.loadSnapshot(forceRefresh: forceRefresh);
    return result.map((snapshot) {
      final today = _calendar.dateOf(_clock.nowUtc());
      final period = customPeriod ?? preset.resolve(today);
      final recent = snapshot.transactions.toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

      return DashboardSummary(
        balance: BalanceCalculator.compute(
          openingBalance: snapshot.openingBalance,
          transactions: snapshot.transactions,
        ),
        summary: PeriodSummarizer.summarize(
          transactions: snapshot.transactions,
          period: period,
          calendar: _calendar,
        ),
        recent: recent.take(recentCount).toList(),
        freshness: snapshot.freshness,
      );
    });
  }
}
