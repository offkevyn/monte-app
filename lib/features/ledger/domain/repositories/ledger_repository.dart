import '../../../../core/async/cancel_signal.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/user_data.dart';
import '../entities/dashboard_snapshot.dart';
import '../entities/date_span.dart';
import '../entities/transaction.dart';
import '../entities/transaction_filter.dart';
import '../entities/transaction_page.dart';

/// What the domain needs from the data layer.
///
/// Every screen works the same way: show what is saved on the device right
/// away (`saved…`), then ask the server (`refresh…` / [getPage]), which
/// saves the answer and returns it. When the server cannot be reached, the
/// saved copy comes back marked as stale instead of an error.
abstract interface class LedgerRepository implements UserData {
  /// Dashboard data saved on the device, without touching the network.
  /// `null` when nothing was saved yet.
  Future<Result<DashboardSnapshot?>> savedDashboard(DateSpan period);

  /// Settled balance, pending debits, newest transactions and the whole
  /// [period] from the server. Skips the network when the same period was
  /// fetched seconds ago, unless [force] (pull to refresh).
  Future<Result<DashboardSnapshot>> refreshDashboard(
    DateSpan period, {
    bool force = false,
  });

  /// One page of the statement, newest first, filtered by the server.
  ///
  /// Pages are saved so they can be shown offline later. When the server
  /// cannot be reached, the page is read from what is saved, with
  /// [TransactionPage.fromDevice] set. [cancel] drops a request the screen
  /// no longer needs (a newer search replaced it).
  Future<Result<TransactionPage>> getPage(
    TransactionQuery query, {
    bool force = false,
    CancelSignal? cancel,
  });

  /// The first page as saved on the device, to show while [getPage] asks the
  /// server. `null` when nothing is saved.
  Future<Result<TransactionPage?>> savedFirstPage(TransactionFilter filter);

  /// How many transactions match [filter], for the "Ver N transações"
  /// button. Counts what is saved when the server cannot be reached.
  Future<Result<int>> countTransactions(
    TransactionFilter filter, {
    CancelSignal? cancel,
  });

  /// A transaction as saved on the device (maybe only its summary).
  Future<Result<Transaction?>> savedTransaction(String id);

  /// The full transaction from the server, saved for later.
  Future<Result<Transaction>> refreshTransaction(String id);

  /// Forgets when things were last fetched, so the next screen asks the
  /// server even if it did seconds ago (the dev picker changed the bank).
  void expireRecentFetches();

  /// Deletes everything saved (sign out), so no customer data stays on the
  /// device.
  @override
  Future<void> clear();
}
