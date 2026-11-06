import '../../../../core/result/result.dart';
import '../entities/ledger_snapshot.dart';
import '../entities/transaction.dart';
import '../entities/transaction_page.dart';

/// What the domain needs from the data layer. The implementation decides
/// where the data comes from (server, local database); the domain only sees
/// entities and `Result`.
abstract interface class LedgerRepository {
  /// Opening balance and every transaction, for balance and period totals.
  ///
  /// With [forceRefresh] it syncs with the server first (pull to refresh);
  /// otherwise it may answer from the local copy. When the sync fails but a
  /// local copy exists, it returns that copy marked as stale instead of an
  /// error.
  Future<Result<LedgerSnapshot>> loadSnapshot({bool forceRefresh = false});

  /// One page of the statement, newest first, already filtered.
  Future<Result<TransactionPage>> getTransactions(TransactionQuery query);

  /// A single transaction, for the detail screen.
  Future<Result<Transaction>> getTransaction(String id);
}
