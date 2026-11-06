import 'package:meta/meta.dart';

import '../../../../core/freshness/data_freshness.dart';
import 'transaction.dart';
import 'transaction_filter.dart';

/// A request for one page of the statement.
///
/// Pagination is by opaque cursor: the next page starts after the last item
/// already shown, so a new transaction arriving at the top does not shift
/// the pages and duplicate an item (which offset pagination would do).
@immutable
final class TransactionQuery {
  TransactionQuery({
    TransactionFilter? filter,
    this.cursor,
    this.limit = defaultLimit,
  }) : filter = filter ?? TransactionFilter.none {
    if (limit < 1 || limit > maxLimit) {
      throw ArgumentError.value(limit, 'limit', 'must be 1..$maxLimit');
    }
  }

  static const defaultLimit = 20;
  static const maxLimit = 100;

  final TransactionFilter filter;

  /// `null` for the first page.
  final String? cursor;
  final int limit;

  TransactionQuery nextPage(String cursor) =>
      TransactionQuery(filter: filter, cursor: cursor, limit: limit);

  @override
  bool operator ==(Object other) =>
      other is TransactionQuery &&
      other.filter == filter &&
      other.cursor == cursor &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(filter, cursor, limit);

  @override
  String toString() => 'TransactionQuery($filter, cursor: $cursor)';
}

/// One page of the statement, newest first.
@immutable
final class TransactionPage {
  TransactionPage({
    required List<Transaction> items,
    required this.nextCursor,
    required this.freshness,
  }) : items = List.unmodifiable(items);

  final List<Transaction> items;

  /// `null` when there is nothing after this page.
  final String? nextCursor;
  final DataFreshness freshness;

  bool get hasMore => nextCursor != null;
}
