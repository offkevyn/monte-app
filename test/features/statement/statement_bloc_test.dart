import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/async/cancel_signal.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/freshness/data_freshness.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/domain/entities/dashboard_snapshot.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
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
  final forced = <bool>[];
  final cancels = <CancelSignal?>[];
  final _pending = <Completer<Result<TransactionPage>>>[];

  /// What [savedFirstPage] answers.
  TransactionPage? saved;

  int get pendingCount => _pending.where((c) => !c.isCompleted).length;

  @override
  Future<Result<TransactionPage>> getPage(
    TransactionQuery query, {
    bool force = false,
    CancelSignal? cancel,
  }) {
    requests.add(query);
    forced.add(force);
    cancels.add(cancel);
    final completer = Completer<Result<TransactionPage>>();
    _pending.add(completer);
    return completer.future;
  }

  /// Answers request number [index] (0 based).
  void answer(int index, Result<TransactionPage> result) =>
      _pending[index].complete(result);

  @override
  Future<Result<TransactionPage?>> savedFirstPage(
    TransactionFilter filter,
  ) async => Ok(saved);

  @override
  Future<Result<int>> countTransactions(
    TransactionFilter filter, {
    CancelSignal? cancel,
  }) async => const Ok(0);

  @override
  Future<Result<Transaction?>> savedTransaction(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<Transaction>> refreshTransaction(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<DashboardSnapshot?>> savedDashboard(DateSpan period) =>
      throw UnimplementedError();

  @override
  Future<Result<DashboardSnapshot>> refreshDashboard(
    DateSpan period, {
    bool force = false,
  }) => throw UnimplementedError();

  @override
  void expireRecentFetches() {}

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

  test('pull to refresh forces the server, other loads do not', () async {
    await startWith(page(['a']));
    bloc.add(const StatementRefreshed());
    await settle();
    expect(repository.forced, [false, true]);
  });

  test(
    'what is saved shows first, then the server answer replaces it',
    () async {
      repository.saved = page(['old']);
      bloc.add(const StatementStarted());
      await settle();
      expect(bloc.state.status, StatementStatus.ready);
      expect(bloc.state.items.map((t) => t.id), ['old']);
      expect(bloc.state.reloading, isTrue, reason: 'thin bar while updating');

      repository.answer(0, Ok(page(['new', 'old'])));
      await settle();
      expect(bloc.state.items.map((t) => t.id), ['new', 'old']);
      expect(bloc.state.reloading, isFalse);
    },
  );

  test('a new search cancels the request of the old one', () async {
    await startWith(page(['a']));
    bloc.add(const StatementQueryChanged('pix'));
    await settle(60);
    bloc.add(const StatementQueryChanged('padaria'));
    await settle(60);
    expect(repository.cancels[1]!.isCancelled, isTrue);
    expect(repository.cancels[2]!.isCancelled, isFalse);
  });

  test('news on top keep the pages already loaded below', () async {
    await startWith(page(['c', 'd'], next: 'cursor-d'));
    bloc.add(const StatementNextPageRequested());
    await settle();
    repository.answer(1, Ok(page(['e', 'f'], next: 'cursor-f', day: 4)));
    await settle();

    // A Pix arrived: the fresh first page ends at "d", already on screen.
    bloc.add(const StatementVisited());
    await settle();
    repository.answer(2, Ok(page(['pix', 'c', 'd'], next: 'cursor-d')));
    await settle();
    expect(bloc.state.items.map((t) => t.id), ['pix', 'c', 'd', 'e', 'f']);
    expect(bloc.state.nextCursor, 'cursor-f');
  });

  test('offline pages from the device are flagged for the banner', () async {
    final offline = TransactionPage(
      items: page(['a']).items,
      nextCursor: null,
      freshness: DataFreshness(
        syncedAt: DateTime.utc(2026, 11, 5),
        syncFailure: const NoConnectionFailure(),
      ),
      fromDevice: true,
    );
    await startWith(offline);
    expect(bloc.state.fromDevice, isTrue);
  });

  test('coming back to the tab only reloads the unfiltered list', () async {
    await startWith(page(['a']));
    bloc.add(StatementFilterChanged(TransactionFilter.none));
    await settle();
    bloc.add(
      StatementFilterChanged(
        TransactionFilter(types: const {TransactionType.income}),
      ),
    );
    await settle();
    final before = repository.requests.length;
    bloc.add(const StatementVisited());
    await settle();
    expect(repository.requests, hasLength(before));
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
