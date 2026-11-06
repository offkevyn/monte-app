import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/freshness/data_freshness.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/features/ledger/domain/entities/ledger_snapshot.dart';
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

  @override
  Future<Result<TransactionPage>> getTransactions(
    TransactionQuery query,
  ) async {
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
  Future<Result<int>> countTransactions(TransactionFilter filter) async =>
      Ok(transactions.where((t) => filter.matches(t, calendar)).length);

  @override
  Future<Result<Transaction>> getTransaction(String id) async {
    final failure = failWith;
    if (failure != null) return Err(failure);
    for (final transaction in transactions) {
      if (transaction.id == id) return Ok(transaction);
    }
    return const Err(NotFoundFailure());
  }

  @override
  Future<Result<LedgerSnapshot>> loadSnapshot({
    bool forceRefresh = false,
  }) async => Ok(
    LedgerSnapshot(
      openingBalance: Money.zero,
      transactions: transactions,
      freshness: freshness,
    ),
  );

  @override
  Future<void> clear() async {}
}
