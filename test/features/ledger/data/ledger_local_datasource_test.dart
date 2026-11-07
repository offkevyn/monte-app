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
    await local.saveSummaries(data.transactions);
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

  test('every transaction survives the round trip unchanged', () async {
    expect(await readAll(TransactionFilter.none), data.transactions);
  });

  test('a list summary never erases details already saved', () async {
    final full = tx(
      id: 'card',
      counterparty: 'Loja',
    ).withDetails(cardLastDigits: '4821', message: 'obrigado');
    await local.saveDetail(full, openedAt: syncedAt);
    final summary = Transaction(
      id: 'card',
      description: full.description,
      amount: full.amount,
      type: full.type,
      status: TransactionStatus.completed,
      occurredAt: full.occurredAt,
      method: full.method,
      counterparty: 'Loja',
      detailed: false,
    );
    await local.saveSummaries([summary]);
    final saved = (await local.byId('card'))!;
    expect(saved.detailed, isTrue);
    expect(saved.cardLastDigits, '4821');
    expect(saved.message, 'obrigado');
  });

  test('a summary updates the status of a saved row', () async {
    final pending = expense(1000, id: 'p', status: TransactionStatus.pending);
    await local.saveSummaries([pending]);
    await local.saveSummaries([expense(1000, id: 'p')]);
    expect((await local.byId('p'))!.status, TransactionStatus.completed);
  });

  test('dashboard state round trip, with the pending ids', () async {
    final period = DateSpan(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31));
    final pending = expense(10, id: 'pend', status: TransactionStatus.pending);
    expect(await local.readDashboardState(), isNull);
    await local.saveDashboard(
      balance: const Money.cents(123456),
      period: period,
      pendingDebits: [pending],
      transactions: const [],
      syncedAt: syncedAt,
      skippedRecords: 2,
    );
    final state = (await local.readDashboardState())!;
    expect(state.balance, const Money.cents(123456));
    expect(state.period, period);
    expect(state.pendingIds, ['pend']);
    expect(state.syncedAt, syncedAt);
    expect(state.skippedRecords, 2);
    expect(await local.byIds(['pend', 'nope']), [pending]);
  });

  test('statement mark round trip', () async {
    expect(await local.readStatementState(), isNull);
    await local.markStatementSynced(syncedAt: syncedAt, skippedRecords: 3);
    final mark = (await local.readStatementState())!;
    expect(mark.syncedAt, syncedAt);
    expect(mark.skippedRecords, 3);
  });

  test('inPeriod returns the whole period by the user calendar', () async {
    final october = DateSpan(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31));
    expect(
      await local.inPeriod(october),
      data.transactions
          .where((t) => october.contains(calendar.dateOf(t.occurredAt)))
          .toList(),
    );
  });

  test(
    'prune keeps the newest, the period, the pending and the opened',
    () async {
      final oldest = data.transactions.last;
      final pending = data.transactions[400];
      final opened = data.transactions[450];
      final october = DateSpan(LocalDate(2026, 10, 1), LocalDate(2026, 10, 31));
      await local.saveDashboard(
        balance: Money.zero,
        period: october,
        pendingDebits: [pending],
        transactions: const [],
        syncedAt: syncedAt,
        skippedRecords: 0,
      );
      await local.saveDetail(opened, openedAt: syncedAt);

      await local.prune();

      final left = await readAll(TransactionFilter.none);
      final ids = left.map((t) => t.id).toSet();
      expect(
        ids.containsAll(
          data.transactions
              .take(LedgerLocalDataSource.keepNewest)
              .map((t) => t.id),
        ),
        isTrue,
      );
      expect(ids, containsAll([pending.id, opened.id]));
      expect(
        ids.containsAll(
          data.transactions
              .where((t) => october.contains(calendar.dateOf(t.occurredAt)))
              .map((t) => t.id),
        ),
        isTrue,
      );
      if (!october.contains(calendar.dateOf(oldest.occurredAt)) &&
          oldest.id != pending.id &&
          oldest.id != opened.id) {
        expect(ids, isNot(contains(oldest.id)));
      }
      expect(left.length, lessThan(data.transactions.length));
    },
  );

  test('clear empties everything', () async {
    await local.markStatementSynced(syncedAt: syncedAt, skippedRecords: 0);
    await local.clear();
    expect(await local.isEmpty(), isTrue);
    expect(await local.readStatementState(), isNull);
  });

  test('finds by id', () async {
    final target = data.transactions[42];
    expect(await local.byId(target.id), target);
    expect(await local.byId('tx_missing'), isNull);
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

  test('count agrees with the pages for the same filter', () async {
    for (final filter in [
      TransactionFilter.none,
      TransactionFilter(types: {TransactionType.income}),
      TransactionFilter(query: 'padaria'),
    ]) {
      expect(
        await local.count(filter),
        (await readAll(filter)).length,
        reason: '$filter',
      );
    }
  });

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
    await smallLocal.saveSummaries([tx(id: 'a'), tx(id: 'b')]);
    expect(
      (await smallLocal.page(TransactionQuery(limit: 2))).nextCursor,
      isNull,
    );
  });
}
