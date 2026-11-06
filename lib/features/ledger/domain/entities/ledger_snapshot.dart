import 'package:meta/meta.dart';

import '../../../../core/money/money.dart';
import 'transaction.dart';

/// How fresh a piece of data is. The UI shows a "last updated" banner when
/// [isStale] is true (served from the local cache after a failed sync).
@immutable
final class DataFreshness {
  DataFreshness({required DateTime syncedAt, required this.isStale})
    : syncedAt = syncedAt.toUtc();

  /// Last successful sync with the server, in UTC.
  final DateTime syncedAt;
  final bool isStale;

  @override
  bool operator ==(Object other) =>
      other is DataFreshness &&
      other.syncedAt == syncedAt &&
      other.isStale == isStale;

  @override
  int get hashCode => Object.hash(syncedAt, isStale);

  @override
  String toString() => 'DataFreshness($syncedAt, stale: $isStale)';
}

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
