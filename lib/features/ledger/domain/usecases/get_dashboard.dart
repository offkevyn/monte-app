import 'package:meta/meta.dart';

import '../../../../core/freshness/data_freshness.dart';
import '../../../../core/result/result.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/time/local_calendar.dart';
import '../entities/dashboard_snapshot.dart';
import '../entities/date_span.dart';
import '../entities/transaction.dart';
import '../repositories/ledger_repository.dart';
import '../services/balance_calculator.dart';
import '../services/period_summary.dart';

/// Everything the dashboard shows.
@immutable
final class DashboardSummary {
  DashboardSummary({
    required this.balance,
    required this.summary,
    required List<Transaction> recent,
    required this.freshness,
  }) : recent = List.unmodifiable(recent);

  final BalanceBreakdown balance;

  /// Totals and chart of the selected period; `null` when the device does
  /// not have the whole period (offline): a partial total is never shown.
  final PeriodSummary? summary;

  /// Latest transactions of any status, newest first.
  final List<Transaction> recent;
  final DataFreshness freshness;
}

/// Turns the dashboard data into balance, period totals, chart and latest
/// transactions. The rules live in the domain (`BalanceCalculator`,
/// `PeriodSummarizer`); the data comes from the repository.
final class GetDashboard {
  const GetDashboard(this._repository, this._clock, this._calendar);

  final LedgerRepository _repository;
  final Clock _clock;
  final LocalCalendar _calendar;

  static const recentCount = 5;

  /// What is saved on the device, shown before the server answers.
  Future<Result<DashboardSummary?>> saved({
    PeriodPreset preset = PeriodPreset.thisMonth,
  }) async {
    final period = _resolve(preset);
    final result = await _repository.savedDashboard(period);
    return result.map(
      (snapshot) => snapshot == null ? null : _summarize(snapshot),
    );
  }

  /// Asks the server. With [force] (pull to refresh) it never reuses an
  /// answer from seconds ago.
  Future<Result<DashboardSummary>> call({
    PeriodPreset preset = PeriodPreset.thisMonth,
    bool force = false,
  }) async {
    final period = _resolve(preset);
    final result = await _repository.refreshDashboard(period, force: force);
    return result.map(_summarize);
  }

  DateSpan _resolve(PeriodPreset preset) =>
      preset.resolve(_calendar.dateOf(_clock.nowUtc()));

  DashboardSummary _summarize(DashboardSnapshot snapshot) {
    final inPeriod = snapshot.periodTransactions;
    final recent = snapshot.recent.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return DashboardSummary(
      balance: BalanceCalculator.compute(
        settled: snapshot.settledBalance,
        pending: snapshot.pendingDebits,
      ),
      summary: inPeriod == null
          ? null
          : PeriodSummarizer.summarize(
              transactions: inPeriod,
              period: snapshot.period,
              calendar: _calendar,
            ),
      recent: recent.take(recentCount).toList(),
      freshness: snapshot.freshness,
    );
  }
}
