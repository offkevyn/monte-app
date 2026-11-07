import 'package:meta/meta.dart';

import '../../../../core/money/money.dart';
import '../entities/transaction.dart';

/// The balance split the way banks show it.
@immutable
final class BalanceBreakdown {
  const BalanceBreakdown({required this.posted, required this.pendingDebits});

  /// Opening balance plus every completed movement, from the server.
  final Money posted;

  /// Expenses authorized but not settled yet (e.g. a card purchase still
  /// pending). The money is already reserved.
  final Money pendingDebits;

  /// What the user can spend now: posted minus what is reserved.
  Money get available => posted - pendingDebits;

  @override
  bool operator ==(Object other) =>
      other is BalanceBreakdown &&
      other.posted == posted &&
      other.pendingDebits == pendingDebits;

  @override
  int get hashCode => Object.hash(posted, pendingDebits);

  @override
  String toString() =>
      'BalanceBreakdown(posted: $posted, '
      'pendingDebits: $pendingDebits, available: $available)';
}

/// Balance rules, kept out of the UI and covered by tests.
///
/// The server owns the money: it sends the settled balance (opening balance
/// plus every completed movement). The app turns it into what the customer
/// can spend, following the status of each pending transaction:
///
/// | status    | income            | expense                    |
/// |-----------|-------------------|----------------------------|
/// | completed | already settled   | already settled            |
/// | pending   | ignored (not yet) | reserved: lowers available |
/// | failed    | ignored           | ignored                    |
/// | reversed  | ignored (undone)  | ignored (money returned)   |
abstract final class BalanceCalculator {
  static BalanceBreakdown compute({
    required Money settled,
    required Iterable<Transaction> pending,
  }) {
    var reserved = Money.zero;
    for (final transaction in pending) {
      if (transaction.status == TransactionStatus.pending &&
          transaction.isExpense) {
        reserved += transaction.amount;
      }
    }
    return BalanceBreakdown(posted: settled, pendingDebits: reserved);
  }
}
