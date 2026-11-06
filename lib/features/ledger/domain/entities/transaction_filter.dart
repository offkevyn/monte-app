import 'package:meta/meta.dart';

import '../../../../core/time/local_calendar.dart';
import '../services/search_text.dart';
import 'date_span.dart';
import 'transaction.dart';

/// Combined statement filters. An empty set means "any".
///
/// The data layer applies the same rules when it queries (local database or
/// server), and [matches] is the reference implementation that tests and the
/// simulated backend use, so both sides agree on what a filter means.
@immutable
final class TransactionFilter {
  TransactionFilter({
    Set<TransactionType> types = const {},
    Set<TransactionStatus> statuses = const {},
    this.period,
    String query = '',
  }) : types = Set.unmodifiable(types),
       statuses = Set.unmodifiable(statuses),
       query = SearchText.cleanQuery(query);

  static final none = TransactionFilter();

  final Set<TransactionType> types;
  final Set<TransactionStatus> statuses;

  /// Days to include, in the user's calendar. `null` means all time.
  final DateSpan? period;

  /// Search text, already trimmed and limited to [SearchText.maxLength].
  final String query;

  bool get isEmpty =>
      types.isEmpty && statuses.isEmpty && period == null && query.isEmpty;

  /// How many filter groups are active, for the badge on the filter button.
  int get activeCount => [
    types.isNotEmpty,
    statuses.isNotEmpty,
    period != null,
    query.isNotEmpty,
  ].where((active) => active).length;

  bool matches(Transaction transaction, LocalCalendar calendar) {
    if (types.isNotEmpty && !types.contains(transaction.type)) return false;
    if (statuses.isNotEmpty && !statuses.contains(transaction.status)) {
      return false;
    }
    final period = this.period;
    if (period != null &&
        !period.contains(calendar.dateOf(transaction.occurredAt))) {
      return false;
    }
    if (query.isNotEmpty) {
      final haystack = [
        transaction.description,
        transaction.counterparty ?? '',
      ].join(' ');
      if (!SearchText.matches(haystack, query)) return false;
    }
    return true;
  }

  TransactionFilter copyWith({
    Set<TransactionType>? types,
    Set<TransactionStatus>? statuses,
    DateSpan? period,
    bool clearPeriod = false,
    String? query,
  }) => TransactionFilter(
    types: types ?? this.types,
    statuses: statuses ?? this.statuses,
    period: clearPeriod ? null : (period ?? this.period),
    query: query ?? this.query,
  );

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      _sameSet(other.types, types) &&
      _sameSet(other.statuses, statuses) &&
      other.period == period &&
      other.query == query;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(types),
    Object.hashAllUnordered(statuses),
    period,
    query,
  );

  @override
  String toString() =>
      'TransactionFilter(types: $types, statuses: $statuses, '
      'period: $period, query: "$query")';

  static bool _sameSet<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
