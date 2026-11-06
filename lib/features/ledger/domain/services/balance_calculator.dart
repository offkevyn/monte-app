import 'package:meta/meta.dart';

import '../../../../core/money/money.dart';
import '../entities/transaction.dart';

/// The balance split the way banks show it.
@immutable
final class BalanceBreakdown {
  const BalanceBreakdown({required this.posted, required this.pendingDebits});

  /// Opening balance plus every completed movement.
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
/// | status    | income            | expense                    |
/// |-----------|-------------------|----------------------------|
/// | completed | adds to posted    | subtracts from posted      |
/// | pending   | ignored (not yet) | reserved: lowers available |
/// | failed    | ignored           | ignored                    |
/// | reversed  | ignored (undone)  | ignored (money returned)   |
abstract final class BalanceCalculator {
  static BalanceBreakdown compute({
    required Money openingBalance,
    required Iterable<Transaction> transactions,
  }) {
    var posted = openingBalance;
    var pendingDebits = Money.zero;
    for (final transaction in transactions) {
      switch (transaction.status) {
        case TransactionStatus.completed:
          posted += transaction.signedAmount;
        case TransactionStatus.pending when transaction.isExpense:
          pendingDebits += transaction.amount;
        case TransactionStatus.pending:
        case TransactionStatus.failed:
        case TransactionStatus.reversed:
          break;
      }
    }
    return BalanceBreakdown(posted: posted, pendingDebits: pendingDebits);
  }
}
