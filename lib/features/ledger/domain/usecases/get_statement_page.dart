import '../../../../core/async/cancel_signal.dart';
import '../../../../core/result/result.dart';
import '../entities/transaction_filter.dart';
import '../entities/transaction_page.dart';
import '../repositories/ledger_repository.dart';

/// Fetches one page of the statement. Grouping by day happens on the
/// accumulated pages (see `DayGrouping`), not per page, so a day split
/// between two pages still shows as one section.
final class GetStatementPage {
  const GetStatementPage(this._repository);

  final LedgerRepository _repository;

  /// The first page as saved on the device, shown while the server answers.
  Future<Result<TransactionPage?>> saved(TransactionFilter filter) =>
      _repository.savedFirstPage(filter);

  /// [force] skips the "fetched seconds ago" shortcut (pull to refresh).
  Future<Result<TransactionPage>> call(
    TransactionQuery query, {
    bool force = false,
    CancelSignal? cancel,
  }) => _repository.getPage(query, force: force, cancel: cancel);
}

/// Previews how many transactions a filter would show.
final class CountTransactions {
  const CountTransactions(this._repository);

  final LedgerRepository _repository;

  Future<Result<int>> call(TransactionFilter filter, {CancelSignal? cancel}) =>
      _repository.countTransactions(filter, cancel: cancel);
}
