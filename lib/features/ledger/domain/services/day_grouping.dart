import 'package:meta/meta.dart';

import '../../../../core/money/money.dart';
import '../../../../core/time/local_calendar.dart';
import '../../../../core/time/local_date.dart';
import '../entities/transaction.dart';

/// Statement section: one day in the user's calendar and its transactions.
@immutable
final class DayGroup {
  DayGroup({required this.date, required List<Transaction> transactions})
    : transactions = List.unmodifiable(transactions);

  final LocalDate date;

  /// Newest first.
  final List<Transaction> transactions;

  /// Net of the completed transactions of the day, shown in the header.
  Money get net => Money.sum(
    transactions
        .where((t) => t.status == TransactionStatus.completed)
        .map((t) => t.signedAmount),
  );

  @override
  bool operator ==(Object other) =>
      other is DayGroup &&
      other.date == date &&
      _sameList(other.transactions, transactions);

  @override
  int get hashCode => Object.hash(date, Object.hashAll(transactions));

  @override
  String toString() => 'DayGroup($date, ${transactions.length} items)';

  static bool _sameList(List<Transaction> a, List<Transaction> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

abstract final class DayGrouping {
  /// Groups by the user's day (never the UTC day), newest day first.
  ///
  /// Works on the accumulated pages of the statement: calling it again after
  /// a new page arrives merges the new items into the right days, even when
  /// a day is split between two pages.
  static List<DayGroup> group(
    Iterable<Transaction> transactions,
    LocalCalendar calendar,
  ) {
    final sorted = transactions.toList()
      ..sort((a, b) {
        final byTime = b.occurredAt.compareTo(a.occurredAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });

    final groups = <DayGroup>[];
    LocalDate? currentDate;
    var current = <Transaction>[];
    for (final transaction in sorted) {
      final date = calendar.dateOf(transaction.occurredAt);
      if (date != currentDate) {
        if (currentDate != null) {
          groups.add(DayGroup(date: currentDate, transactions: current));
        }
        currentDate = date;
        current = [];
      }
      current.add(transaction);
    }
    if (currentDate != null) {
      groups.add(DayGroup(date: currentDate, transactions: current));
    }
    return groups;
  }
}
