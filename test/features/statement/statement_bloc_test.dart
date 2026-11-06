import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/domain/entities/ledger_snapshot.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/entities/transaction_filter.dart';
import 'package:monte/features/ledger/domain/entities/transaction_page.dart';
import 'package:monte/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:monte/features/ledger/domain/usecases/get_statement_page.dart';
import 'package:monte/features/statement/presentation/bloc/statement_bloc.dart';

import '../../helpers/transactions.dart';

/// Repository whose page answers are released by the test, one by one, so
/// ordering (debounce, cancellation, stale pages) can be checked exactly.
class ControlledRepository implements LedgerRepository {
  final requests = <TransactionQuery>[];
  final _pending = <Completer<Result<TransactionPage>>>[];
  var refreshes = 0;

  int get pendingCount => _pending.where((c) => !c.isCompleted).length;

  @override
  Future<Result<TransactionPage>> getTransactions(TransactionQuery query) {
    requests.add(query);
    final completer = Completer<Result<TransactionPage>>();
    _pending.add(completer);
    return completer.future;
  }

  /// Answers request number [index] (0 based).
  void answer(int index, Result<TransactionPage> result) =>
      _pending[index].complete(result);

  @override
  Future<Result<LedgerSnapshot>> loadSnapshot({
    bool forceRefresh = false,
  }) async {
    refreshes++;
    return Ok(
      LedgerSnapshot(
        openingBalance: Money.zero,
        transactions: const [],
        freshness: DataFreshness(syncedAt: DateTime.utc(2026, 11, 5)),
      ),
    );
  }

  @override
  Future<Result<int>> countTransactions(TransactionFilter filter) async =>
      const Ok(0);

  @override
  Future<Result<Transaction>> getTransaction(String id) =>
      throw UnimplementedError();

  @override
  Future<void> clear() async {}
}

TransactionPage page(List<String> ids, {String? next, int day = 5}) =>
    TransactionPage(
      items: [
        for (final (i, id) in ids.indexed)
          tx(id: id, at: DateTime.utc(2026, 11, day, 20 - i)),
      ],
      nextCursor: next,
      freshness: DataFreshness(syncedAt: DateTime.utc(2026, 11, 5)),
    );

void main() {
  late ControlledRepository repository;
  late StatementBloc bloc;

  /// Lets queued events, microtasks and short timers run.
  Future<void> settle([int ms = 0]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  setUp(() {
    repository = ControlledRepository();
    bloc = StatementBloc(
      GetStatementPage(repository),
      RefreshLedger(repository),
      FixedOffsetCalendar.brasilia,
      debounce: const Duration(milliseconds: 40),
    );
  });

  tearDown(() => bloc.close());

  Future<void> startWith(TransactionPage first) async {
    bloc.add(const StatementStarted());
    await settle();
    repository.answer(repository.requests.length - 1, Ok(first));
    await settle();
  }

  test('first load: skeleton, then the grouped first page', () async {
    bloc.add(const StatementStarted());
    await settle();
    expect(bloc.state.status, StatementStatus.loading);

    repository.answer(0, Ok(page(['a', 'b'], next: 'c1')));
    await settle();

    expect(bloc.state.status, StatementStatus.ready);
    expect(bloc.state.items.map((t) => t.id), ['a', 'b']);
    expect(bloc.state.groups.single.date, LocalDate(2026, 11, 5));
    expect(bloc.state.hasMore, isTrue);
    expect(repository.requests.single.limit, 20);
  });

  test('typing fast searches only once, with the last text', () async {
    await startWith(page(['a']));

    for (final text in ['c', 'ca', 'caf', 'cafe']) {
      bloc.add(StatementQueryChanged(text));
      await settle(10);
    }
    expect(repository.requests, hasLength(1), reason: 'still debouncing');

    await settle(80);
    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.filter.query, 'cafe');
  });

  test('the same search again (even with extra spaces) is skipped', () async {
    await startWith(page(['a']));
    bloc.add(const StatementQueryChanged('cafe'));
    await settle(80);
    repository.answer(1, Ok(page(['b'])));
    await settle();

    bloc.add(const StatementQueryChanged('  cafe '));
    await settle(80);
    expect(repository.requests, hasLength(2));
  });

  test('an old search answering late never replaces the new one', () async {
    await startWith(page(['a']));

    bloc.add(const StatementQueryChanged('mer'));
    await settle(80); // request 1 (slow)
    bloc.add(const StatementQueryChanged('uber'));
    await settle(80); // request 2

    repository.answer(2, Ok(page(['uber-1'])));
    await settle();
    repository.answer(1, Ok(page(['mer-1']))); // too late
    await settle();

    expect(bloc.state.filter.query, 'uber');
    expect(bloc.state.items.map((t) => t.id), ['uber-1']);
  });

  test('a new search keeps the old list visible while it loads', () async {
    await startWith(page(['a']));
    bloc.add(const StatementQueryChanged('x'));
    await settle(80);

    expect(bloc.state.reloading, isTrue);
    expect(bloc.state.status, StatementStatus.ready);
    expect(bloc.state.items, isNotEmpty);
  });

  test('changing filters keeps the search text', () async {
    await startWith(page(['a']));
    bloc.add(const StatementQueryChanged('cafe'));
    await settle(80);
    repository.answer(1, Ok(page(['b'])));
    await settle();

    bloc.add(
      StatementFilterChanged(
        TransactionFilter(statuses: {TransactionStatus.pending}),
      ),
    );
    await settle();

    final filter = repository.requests.last.filter;
    expect(filter.query, 'cafe');
    expect(filter.statuses, {TransactionStatus.pending});
  });

  test('next page appends and regroups across days', () async {
    await startWith(page(['a', 'b'], next: 'c1'));

    bloc.add(const StatementNextPageRequested());
    await settle();
    expect(bloc.state.loadingMore, isTrue);
    expect(repository.requests.last.cursor, 'c1');

    repository.answer(1, Ok(page(['c', 'd'], day: 4)));
    await settle();

    expect(bloc.state.items.map((t) => t.id), ['a', 'b', 'c', 'd']);
    expect(bloc.state.groups, hasLength(2));
    expect(bloc.state.hasMore, isFalse);
    expect(bloc.state.loadingMore, isFalse);
  });

  test('scroll firing many times loads the next page only once', () async {
    await startWith(page(['a'], next: 'c1'));
    for (var i = 0; i < 5; i++) {
      bloc.add(const StatementNextPageRequested());
    }
    await settle();
    expect(repository.requests, hasLength(2));
  });

  test('no next page at the end of the list', () async {
    await startWith(page(['a']));
    bloc.add(const StatementNextPageRequested());
    await settle();
    expect(repository.requests, hasLength(1));
  });

  test('a page from before a new search is dropped', () async {
    await startWith(page(['a'], next: 'c1'));
    bloc.add(const StatementNextPageRequested());
    await settle(); // request 1 (next page, old filter)

    bloc.add(
      StatementFilterChanged(
        TransactionFilter(types: {TransactionType.income}),
      ),
    );
    await settle(); // request 2
    repository.answer(2, Ok(page(['income-1'])));
    await settle();
    repository.answer(1, Ok(page(['old-2'])));
    await settle();

    expect(bloc.state.items.map((t) => t.id), ['income-1']);
  });

  test('a failed next page keeps the list and allows a retry', () async {
    await startWith(page(['a'], next: 'c1'));
    bloc.add(const StatementNextPageRequested());
    await settle();
    repository.answer(1, const Err(NoConnectionFailure()));
    await settle();

    expect(bloc.state.pageFailure, const NoConnectionFailure());
    expect(bloc.state.items, hasLength(1));

    bloc.add(const StatementNextPageRequested());
    await settle();
    repository.answer(2, Ok(page(['b'], day: 4)));
    await settle();
    expect(bloc.state.pageFailure, isNull);
    expect(bloc.state.items, hasLength(2));
  });

  test('first load failing shows the error; with a list it keeps it', () async {
    bloc.add(const StatementStarted());
    await settle();
    repository.answer(0, const Err(NoConnectionFailure()));
    await settle();
    expect(bloc.state.status, StatementStatus.failure);

    bloc.add(const StatementStarted());
    await settle();
    repository.answer(1, Ok(page(['a'])));
    await settle();
    expect(bloc.state.status, StatementStatus.ready);

    bloc.add(const StatementQueryChanged('x'));
    await settle(80);
    repository.answer(2, const Err(ServerFailure(statusCode: 500)));
    await settle();
    expect(bloc.state.status, StatementStatus.ready);
    expect(bloc.state.failure, const ServerFailure(statusCode: 500));
  });

  test('a cancelled load just stops the progress bar', () async {
    await startWith(page(['a']));
    bloc.add(const StatementQueryChanged('x'));
    await settle(80);
    repository.answer(1, const Err(CancelledFailure()));
    await settle();
    expect(bloc.state.reloading, isFalse);
    expect(bloc.state.failure, isNull);
  });

  test('pull to refresh syncs before reading the first page', () async {
    await startWith(page(['a']));
    bloc.add(const StatementRefreshed());
    await settle();
    expect(repository.refreshes, 1);
    expect(repository.requests, hasLength(2));
  });

  test('closes cleanly after searches (no leaked subscriptions)', () async {
    await startWith(page(['a']));
    bloc.add(const StatementQueryChanged('cafe'));
    await settle(80);
    repository.answer(1, Ok(page(['b'])));
    bloc.add(const StatementQueryChanged('caf'));
    await bloc.close().timeout(const Duration(seconds: 2));
    expect(bloc.isClosed, isTrue);
  });

  test('empty result is a ready state, not an error', () async {
    await startWith(page([]));
    expect(bloc.state.isEmpty, isTrue);
  });
}
