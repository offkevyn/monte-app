import 'package:monte/core/async/cancel_signal.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/freshness/data_freshness.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/features/ledger/domain/entities/dashboard_snapshot.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/entities/transaction_filter.dart';
import 'package:monte/features/ledger/domain/entities/transaction_page.dart';
import 'package:monte/features/ledger/domain/repositories/ledger_repository.dart';

/// Ledger in memory that filters with the domain rules and pages by index.
/// Answers right away, so widget tests can drive the real blocs.
class MemoryLedgerRepository implements LedgerRepository {
  MemoryLedgerRepository(
    List<Transaction> transactions, {
    this.calendar = FixedOffsetCalendar.brasilia,
  }) : transactions = transactions.toList()
         ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  final List<Transaction> transactions;
  final LocalCalendar calendar;

  /// When set, every call fails with it.
  Failure? failWith;
  final freshness = DataFreshness(syncedAt: DateTime.utc(2026, 11, 5, 17));

  /// What [savedFirstPage] answers; `null` means nothing saved.
  TransactionPage? saved;

  /// Every query sent to [getPage], with its options.
  final pageCalls = <({TransactionQuery query, bool force})>[];

  @override
  Future<Result<TransactionPage>> getPage(
    TransactionQuery query, {
    bool force = false,
    CancelSignal? cancel,
  }) async {
    pageCalls.add((query: query, force: force));
    final failure = failWith;
    if (failure != null) return Err(failure);
    final matching = transactions
        .where((t) => query.filter.matches(t, calendar))
        .toList();
    final start = query.cursor == null ? 0 : int.parse(query.cursor!);
    final end = (start + query.limit).clamp(0, matching.length);
    return Ok(
      TransactionPage(
        items: matching.sublist(start, end),
        nextCursor: end < matching.length ? '$end' : null,
        freshness: freshness,
      ),
    );
  }

  @override
  Future<Result<TransactionPage?>> savedFirstPage(
    TransactionFilter filter,
  ) async => Ok(saved);

  @override
  Future<Result<int>> countTransactions(
    TransactionFilter filter, {
    CancelSignal? cancel,
  }) async => Ok(transactions.where((t) => filter.matches(t, calendar)).length);

  /// When true, [savedTransaction] finds nothing, as on a fresh install.
  bool nothingSaved = false;

  @override
  Future<Result<Transaction?>> savedTransaction(String id) async {
    if (nothingSaved) return const Ok(null);
    for (final transaction in transactions) {
      if (transaction.id == id) return Ok(transaction);
    }
    return const Ok(null);
  }

  @override
  Future<Result<Transaction>> refreshTransaction(String id) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    for (final transaction in transactions) {
      if (transaction.id == id) return Ok(transaction);
    }
    return const Err(NotFoundFailure());
  }

  DashboardSnapshot _dashboard(DateSpan period) => DashboardSnapshot(
    settledBalance: Money.zero,
    pendingDebits: const [],
    recent: transactions.take(5).toList(),
    period: period,
    periodTransactions: transactions,
    freshness: freshness,
  );

  @override
  Future<Result<DashboardSnapshot?>> savedDashboard(DateSpan period) async =>
      Ok(_dashboard(period));

  @override
  Future<Result<DashboardSnapshot>> refreshDashboard(
    DateSpan period, {
    bool force = false,
  }) async => Ok(_dashboard(period));

  @override
  void expireRecentFetches() {}

  @override
  Future<void> clear() async {}
}
