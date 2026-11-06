import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/features/ledger/domain/entities/ledger_snapshot.dart';
import 'package:monte/features/ledger/domain/entities/transaction_filter.dart';
import 'package:monte/features/ledger/domain/entities/transaction_page.dart';

import '../../../../helpers/transactions.dart';

void main() {
  final freshness = DataFreshness(syncedAt: DateTime.utc(2026, 11, 5, 12));

  test('query validates the page size', () {
    expect(() => TransactionQuery(limit: 0), throwsArgumentError);
    expect(
      () => TransactionQuery(limit: TransactionQuery.maxLimit + 1),
      throwsArgumentError,
    );
    expect(TransactionQuery().limit, TransactionQuery.defaultLimit);
    expect(TransactionQuery().filter, TransactionFilter.none);
  });

  test('next page keeps filter and size and only moves the cursor', () {
    final first = TransactionQuery(
      filter: TransactionFilter(query: 'cafe'),
      limit: 50,
    );
    final second = first.nextPage('cursor-2');

    expect(second.cursor, 'cursor-2');
    expect(second.filter, first.filter);
    expect(second.limit, 50);
    expect(second, isNot(first));
    expect(second, first.nextPage('cursor-2'));
    expect(second.hashCode, first.nextPage('cursor-2').hashCode);
    expect(second.toString(), contains('cursor-2'));
  });

  test('page knows when there is more', () {
    final page = TransactionPage(
      items: [tx()],
      nextCursor: 'abc',
      freshness: freshness,
    );
    expect(page.hasMore, isTrue);
    expect(
      TransactionPage(
        items: const [],
        nextCursor: null,
        freshness: freshness,
      ).hasMore,
      isFalse,
    );
    expect(() => page.items.add(tx()), throwsUnsupportedError);
  });

  test('freshness is stored in UTC and compares by value', () {
    final local = DateTime.utc(2026, 11, 5, 12).toLocal();
    final a = DataFreshness(
      syncedAt: local,
      syncFailure: const NoConnectionFailure(),
      skippedRecords: 2,
    );
    expect(a.syncedAt.isUtc, isTrue);
    expect(
      a,
      DataFreshness(
        syncedAt: DateTime.utc(2026, 11, 5, 12),
        syncFailure: const NoConnectionFailure(),
        skippedRecords: 2,
      ),
    );
    expect(a.hashCode, isNot(freshness.hashCode));
    expect(a.isStale, isTrue);
    expect(freshness.isStale, isFalse);
    expect(a.toString(), contains('skipped: 2'));
  });
}
