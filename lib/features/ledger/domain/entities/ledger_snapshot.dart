import 'package:meta/meta.dart';

import '../../../../core/freshness/data_freshness.dart';
import '../../../../core/money/money.dart';
import 'transaction.dart';

/// The whole account as stored locally: the balance the account opened with
/// and every transaction since. Balance and totals are computed from this one
/// source, so dashboard, statement and detail can never disagree.
@immutable
final class LedgerSnapshot {
  LedgerSnapshot({
    required this.openingBalance,
    required List<Transaction> transactions,
    required this.freshness,
  }) : transactions = List.unmodifiable(transactions);

  final Money openingBalance;
  final List<Transaction> transactions;
  final DataFreshness freshness;
}
