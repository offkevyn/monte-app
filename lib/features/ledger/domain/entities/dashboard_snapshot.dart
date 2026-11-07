import 'package:meta/meta.dart';

import '../../../../core/freshness/data_freshness.dart';
import '../../../../core/money/money.dart';
import 'date_span.dart';
import 'transaction.dart';

/// What the dashboard needs, as the server sent it (or as it was saved on
/// the device). The settled balance comes from the server, which owns the
/// money; the app derives the available balance and the period totals.
@immutable
final class DashboardSnapshot {
  DashboardSnapshot({
    required this.settledBalance,
    required List<Transaction> pendingDebits,
    required List<Transaction> recent,
    required this.period,
    required List<Transaction>? periodTransactions,
    required this.freshness,
  }) : pendingDebits = List.unmodifiable(pendingDebits),
       recent = List.unmodifiable(recent),
       periodTransactions = periodTransactions == null
           ? null
           : List.unmodifiable(periodTransactions);

  /// Opening balance plus every completed movement, computed by the server.
  final Money settledBalance;

  /// Expenses authorized but not settled yet.
  final List<Transaction> pendingDebits;

  /// Newest transactions of any status, newest first.
  final List<Transaction> recent;

  /// The period asked for.
  final DateSpan period;

  /// Every transaction of [period], or `null` when the device does not have
  /// the whole period (offline, never downloaded). A partial list would
  /// give wrong totals, so it is never offered as if it were complete.
  final List<Transaction>? periodTransactions;

  final DataFreshness freshness;
}
