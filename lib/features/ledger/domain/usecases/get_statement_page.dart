import '../../../../core/result/result.dart';
import '../entities/ledger_snapshot.dart';
import '../entities/transaction_filter.dart';
import '../entities/transaction_page.dart';
import '../repositories/ledger_repository.dart';

/// Fetches one page of the statement. Grouping by day happens on the
/// accumulated pages (see `DayGrouping`), not per page, so a day split
/// between two pages still shows as one section.
final class GetStatementPage {
  const GetStatementPage(this._repository);

  final LedgerRepository _repository;

  Future<Result<TransactionPage>> call(TransactionQuery query) =>
      _repository.getTransactions(query);
}

/// Pull to refresh on the statement: syncs with the server before the
/// first page is read again from the local database.
final class RefreshLedger {
  const RefreshLedger(this._repository);

  final LedgerRepository _repository;

  Future<Result<DataFreshness>> call() async =>
      (await _repository.loadSnapshot(forceRefresh: true))
          .map((snapshot) => snapshot.freshness);
}

/// Previews how many transactions a filter would show.
final class CountTransactions {
  const CountTransactions(this._repository);

  final LedgerRepository _repository;

  Future<Result<int>> call(TransactionFilter filter) =>
      _repository.countTransactions(filter);
}
