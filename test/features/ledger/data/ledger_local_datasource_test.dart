import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/data/fake/fake_ledger_generator.dart';
import 'package:monte/features/ledger/data/local/ledger_database.dart';
import 'package:monte/features/ledger/data/local/ledger_local_datasource.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/entities/transaction_filter.dart';
import 'package:monte/features/ledger/domain/entities/transaction_page.dart';

import '../../../helpers/ledger_database.dart';
import '../../../helpers/transactions.dart';

void main() {
  const calendar = FixedOffsetCalendar.brasilia;
  late LedgerDatabase db;
  late LedgerLocalDataSource local;
  final data = FakeLedgerGenerator.generate(
    seed: 42,
    count: 500,
    nowUtc: DateTime.utc(2026, 11, 6, 2, 30),
  );
  final syncedAt = DateTime.utc(2026, 11, 6, 2, 30);

  setUp(() async {
    db = testLedgerDatabase();
    local = LedgerLocalDataSource(db, calendar);
    await local.replaceAll(
      openingBalance: data.openingBalance,
      transactions: data.transactions,
      syncedAt: syncedAt,
      skippedRecords: 1,
    );
  });

  Future<List<Transaction>> readAll(TransactionFilter filter) async {
    final all = <Transaction>[];
    var query = TransactionQuery(filter: filter, limit: 13);
    while (true) {
      final page = await local.page(query);
      all.addAll(page.items);
      final next = page.nextCursor;
      if (next == null) return all;
      query = query.nextPage(next);
    }
  }

  test('stores and reads back the sync state', () async {
    final state = (await local.readSyncState())!;
    expect(state.openingBalance, data.openingBalance);
    expect(state.syncedAt, syncedAt);
    expect(state.skippedRecords, 1);
  });

  test('no sync yet means no state', () async {
    final empty = testLedgerDatabase();
    expect(
      await LedgerLocalDataSource(empty, calendar).readSyncState(),
      isNull,
    );
  });

  test('every transaction survives the round trip unchanged', () async {
    expect(await local.all(), data.transactions);
  });

  test('replaceAll swaps the whole copy', () async {
    await local.replaceAll(
      openingBalance: Money.zero,
      transactions: [tx(id: 'only')],
      syncedAt: syncedAt.add(const Duration(hours: 1)),
      skippedRecords: 0,
    );
    expect((await local.all()).map((t) => t.id), ['only']);
    expect((await local.readSyncState())!.openingBalance, Money.zero);
  });

  test('finds by id', () async {
    final target = data.transactions[42];
    expect(await local.byId(target.id), target);
    expect(await local.byId('tx_missing'), isNull);
  });

  test('pages walk everything once, in the statement order', () async {
    final all = await readAll(TransactionFilter.none);
    expect(all, data.transactions);
  });

  test(
    'SQL filters return exactly what the domain filter rules return',
    () async {
      final filters = [
        TransactionFilter(types: {TransactionType.income}),
        TransactionFilter(statuses: {TransactionStatus.reversed}),
        TransactionFilter(query: 'cafe'),
        TransactionFilter(query: 'PADARIA são'),
        TransactionFilter(query: 'pix rec'),
        TransactionFilter(
          period: DateSpan(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31)),
        ),
        TransactionFilter(
          types: {TransactionType.expense},
          statuses: {TransactionStatus.completed, TransactionStatus.pending},
          period: DateSpan(LocalDate(2026, 9, 15), LocalDate(2026, 11, 5)),
          query: 'uber',
        ),
      ];

      for (final filter in filters) {
        final expected = data.transactions
            .where((t) => filter.matches(t, calendar))
            .toList();
        expect(await readAll(filter), expected, reason: '$filter');
      }
    },
  );

  test('wildcards typed by the user are taken literally', () async {
    expect(await readAll(TransactionFilter(query: '%')), isEmpty);
    expect(await readAll(TransactionFilter(query: '_')), isEmpty);
  });

  test('a cursor this app did not create is rejected', () async {
    await expectLater(
      local.page(TransactionQuery(cursor: 'bm9wZQ==')),
      throwsFormatException,
    );
  });

  test('a page exactly at the end has no next cursor', () async {
    final page = await local.page(TransactionQuery(limit: 100));
    expect(page.nextCursor, isNotNull);
    final small = testLedgerDatabase();
    final smallLocal = LedgerLocalDataSource(small, calendar);
    await smallLocal.replaceAll(
      openingBalance: Money.zero,
      transactions: [
        tx(id: 'a'),
        tx(id: 'b'),
      ],
      syncedAt: syncedAt,
      skippedRecords: 0,
    );
    expect(
      (await smallLocal.page(TransactionQuery(limit: 2))).nextCursor,
      isNull,
    );
  });
}
