import '../../../../core/result/result.dart';
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
