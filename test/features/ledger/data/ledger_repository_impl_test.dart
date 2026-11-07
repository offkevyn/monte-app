import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/async/cancel_signal.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/network/api_client_factory.dart';
import 'package:monte/core/network/fake/fake_http_adapter.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';
import 'package:monte/core/network/retry_interceptor.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/data/datasources/ledger_remote_datasource.dart';
import 'package:monte/features/ledger/data/dtos/transaction_dto.dart';
import 'package:monte/features/ledger/data/fake/fake_ledger_server.dart';
import 'package:monte/features/ledger/data/local/ledger_local_datasource.dart';
import 'package:monte/features/ledger/data/repositories/ledger_repository_impl.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/entities/transaction_filter.dart';
import 'package:monte/features/ledger/domain/entities/transaction_page.dart';

import '../../../helpers/ledger_database.dart';

/// Real pipeline end to end: repository -> remote datasource -> Dio with
/// retry -> fake adapter -> fake server, and the encrypted local database.
void main() {
  const calendar = FixedOffsetCalendar.brasilia;
  late FakeBackendSettings settings;
  late FakeLedgerServer server;
  late FakeHttpAdapter adapter;
  late FixedClock clock;
  late LedgerLocalDataSource local;
  late _CountingRemote remote;
  late LedgerRepositoryImpl repository;

  /// What the fake bank thinks of the session token.
  var sessionValid = true;

  // 05/11/2026 23:30 in Brasília.
  final now = DateTime.utc(2026, 11, 6, 2, 30);
  final thisMonth = DateSpan(LocalDate(2026, 11, 1), LocalDate(2026, 11, 5));
  final lastWeek = DateSpan(LocalDate(2026, 10, 30), LocalDate(2026, 11, 5));

  LedgerRepositoryImpl build(LedgerRemoteDataSource remote) =>
      LedgerRepositoryImpl(remote: remote, local: local, clock: clock);

  setUp(() {
    clock = FixedClock(now);
    settings = FakeBackendSettings();
    sessionValid = true;
    server = FakeLedgerServer(
      settings: settings,
      clock: clock,
      authorize: (_) => sessionValid,
    );
    adapter = FakeHttpAdapter(
      settings: settings,
      routes: server.routes,
      sleep: (_) async {},
    );
    final dio = ApiClientFactory.create(
      baseUrl: ApiClientFactory.fakeBankBaseUrl,
      adapter: adapter,
      retryPolicy: const RetryPolicy(jitter: 0),
      sleep: (_) async {},
    );
    local = LedgerLocalDataSource(testLedgerDatabase(), calendar);
    remote = _CountingRemote(DioLedgerRemoteDataSource(dio, calendar));
    repository = build(remote);
  });

  Money settledOnServer() => server.data.transactions
      .where((t) => t.status == TransactionStatus.completed)
      .fold(server.data.openingBalance, (sum, t) => sum + t.signedAmount);

  List<String> idsIn(DateSpan span) => [
    for (final t in server.data.transactions)
      if (span.contains(calendar.dateOf(t.occurredAt))) t.id,
  ];

  group('dashboard', () {
    test('balance from the server, the whole period, pending debits', () async {
      final snapshot = (await repository.refreshDashboard(thisMonth))
          .valueOrNull!;

      expect(snapshot.settledBalance, settledOnServer());
      expect(snapshot.periodTransactions!.map((t) => t.id), idsIn(thisMonth));
      expect(snapshot.pendingDebits.map((t) => t.id), [
        for (final t in server.data.transactions)
          if (t.status == TransactionStatus.pending && t.isExpense) t.id,
      ]);
      expect(snapshot.recent, hasLength(20));
      expect(snapshot.freshness.isStale, isFalse);
    });

    test('it downloads the period, not the whole account', () async {
      await repository.refreshDashboard(lastWeek);
      expect(
        remote.bulkFilters.where((f) => f.period != null).single.period,
        lastWeek,
      );
      final before = await local.inPeriod(
        DateSpan(LocalDate(2026, 1, 1), LocalDate(2026, 10, 1)),
      );
      final pendingIds = {
        for (final t in server.data.transactions)
          if (t.status == TransactionStatus.pending) t.id,
      };
      expect(
        before.where((t) => !pendingIds.contains(t.id)),
        isEmpty,
        reason: 'only the period (and pending debits) were asked',
      );
    });

    test('saved: nothing before the first refresh, then the copy', () async {
      expect((await repository.savedDashboard(thisMonth)).valueOrNull, isNull);
      await repository.refreshDashboard(thisMonth);
      final saved = (await repository.savedDashboard(thisMonth)).valueOrNull!;
      expect(saved.settledBalance, settledOnServer());
      expect(saved.periodTransactions!.map((t) => t.id), idsIn(thisMonth));
    });

    test(
      'a period inside the saved one is offered; outside, no totals',
      () async {
        await repository.refreshDashboard(lastWeek);
        final inside = DateSpan(LocalDate(2026, 11, 1), LocalDate(2026, 11, 5));
        final outside = DateSpan(LocalDate(2026, 9, 1), LocalDate(2026, 9, 30));
        final insideSnapshot = (await repository.savedDashboard(inside))
            .valueOrNull!;
        expect(
          insideSnapshot.periodTransactions!.map((t) => t.id),
          idsIn(inside),
        );
        final outsideSnapshot = (await repository.savedDashboard(outside))
            .valueOrNull!;
        expect(outsideSnapshot.periodTransactions, isNull);
      },
    );

    test('offline: the saved copy, marked stale', () async {
      await repository.refreshDashboard(thisMonth, force: true);
      settings.scenario = FakeScenario.offline;
      final snapshot = (await repository.refreshDashboard(
        thisMonth,
        force: true,
      )).valueOrNull!;
      expect(snapshot.freshness.isStale, isTrue);
      expect(snapshot.freshness.syncFailure, const NoConnectionFailure());
      expect(snapshot.settledBalance, settledOnServer());
    });

    test('offline with nothing saved: the failure', () async {
      settings.scenario = FakeScenario.offline;
      expect(
        (await repository.refreshDashboard(thisMonth)).failureOrNull,
        const NoConnectionFailure(),
      );
    });

    test(
      'seconds later the device answers; pull to refresh does not',
      () async {
        await repository.refreshDashboard(thisMonth);
        final calls = remote.accountCalls;
        clock.advance(const Duration(seconds: 10));
        await repository.refreshDashboard(thisMonth);
        expect(remote.accountCalls, calls, reason: 'switching tabs fast');

        await repository.refreshDashboard(thisMonth, force: true);
        expect(remote.accountCalls, calls + 1);

        clock.advance(const Duration(seconds: 31));
        await repository.refreshDashboard(thisMonth);
        expect(remote.accountCalls, calls + 2);
      },
    );

    test('two screens refreshing at once share the requests', () async {
      await Future.wait([
        repository.refreshDashboard(thisMonth),
        repository.refreshDashboard(thisMonth),
      ]);
      expect(remote.accountCalls, 1);
    });

    test('a rejected session reaches the screen, not old data', () async {
      await repository.refreshDashboard(thisMonth);
      final result = await build(_AlwaysUnauthorized())
          .refreshDashboard(thisMonth, force: true);
      expect(result.failureOrNull, const UnauthorizedFailure());
    });

    test('a server repeating its cursor cannot loop forever', () async {
      final result = await build(_RepeatingCursor())
          .refreshDashboard(thisMonth);
      expect(result.failureOrNull, isA<InvalidDataFailure>());
    });
  });

  group('statement', () {
    test('pages come from the server and are saved', () async {
      final first = (await repository.getPage(TransactionQuery())).valueOrNull!;
      expect(
        first.items.map((t) => t.id),
        server.data.transactions.take(20).map((t) => t.id),
      );
      expect(first.items.first.detailed, isFalse, reason: 'list = summary');
      expect(first.fromDevice, isFalse);

      final second = (await repository.getPage(
        TransactionQuery().nextPage(first.nextCursor!),
      )).valueOrNull!;
      expect(
        second.items.map((t) => t.id),
        server.data.transactions.skip(20).take(20).map((t) => t.id),
      );
      expect(await local.byId(second.items.last.id), isNotNull);
    });

    test('the screen gets what the device has, not the raw answer', () async {
      final first = (await repository.getPage(TransactionQuery())).valueOrNull!;
      final opened = server.data.transactions
          .take(20)
          .firstWhere((t) => t.cardLastDigits != null);
      await repository.refreshTransaction(opened.id);

      // The list refreshes over a detail opened before: the summary from the
      // server does not wipe the card and the message saved on the device.
      final again = (await repository.getPage(
        TransactionQuery(),
        force: true,
      )).valueOrNull!;
      final row = again.items.firstWhere((t) => t.id == opened.id);
      expect(row.detailed, isTrue);
      expect(row.cardLastDigits, opened.cardLastDigits);
      expect(again.items.map((t) => t.id), first.items.map((t) => t.id));
    });

    test('the dashboard after a refresh is the copy just saved', () async {
      final fresh = (await repository.refreshDashboard(thisMonth)).valueOrNull!;
      final saved = (await repository.savedDashboard(thisMonth)).valueOrNull!;
      expect(fresh.settledBalance, saved.settledBalance);
      expect(fresh.recent, saved.recent);
      expect(fresh.pendingDebits, saved.pendingDebits);
      expect(fresh.periodTransactions, saved.periodTransactions);
    });

    test('filters and search are done by the server', () async {
      final filter = TransactionFilter(query: 'padaria');
      final page = (await repository.getPage(TransactionQuery(filter: filter)))
          .valueOrNull!;
      expect(remote.queries.last.filter, filter);
      expect(
        page.items.map((t) => t.id),
        server.data.transactions
            .where((t) => filter.matches(t, calendar))
            .take(20)
            .map((t) => t.id),
      );
    });

    test('offline with a filter: what is saved, flagged as such', () async {
      await repository.getPage(TransactionQuery(), force: true);
      settings.scenario = FakeScenario.offline;
      final filter = TransactionFilter(types: const {TransactionType.income});
      final page = (await repository.getPage(TransactionQuery(filter: filter)))
          .valueOrNull!;
      expect(page.fromDevice, isTrue);
      expect(page.freshness.isStale, isTrue);
      final saved = server.data.transactions.take(20).where((t) => t.isIncome);
      expect(page.items.map((t) => t.id), saved.map((t) => t.id));
    });

    test('offline with nothing saved: the failure', () async {
      settings.scenario = FakeScenario.offline;
      expect(
        (await repository.getPage(TransactionQuery())).failureOrNull,
        const NoConnectionFailure(),
      );
    });

    test('saved first page: null on a fresh install, then the copy', () async {
      expect(
        (await repository.savedFirstPage(TransactionFilter.none)).valueOrNull,
        isNull,
      );
      await repository.getPage(TransactionQuery());
      final saved = (await repository.savedFirstPage(TransactionFilter.none))
          .valueOrNull!;
      expect(saved.items, hasLength(20));
    });

    test('the first page fetched seconds ago comes from the device', () async {
      await repository.getPage(TransactionQuery());
      final before = remote.queries.length;
      clock.advance(const Duration(seconds: 5));
      await repository.getPage(TransactionQuery());
      expect(remote.queries, hasLength(before));
      await repository.getPage(TransactionQuery(), force: true);
      expect(remote.queries, hasLength(before + 1));
    });

    test('the device answering seconds later does not end the list', () async {
      // Right after login only the first page is saved: the device does not
      // know if more exist, so the list must keep asking the server.
      await repository.getPage(TransactionQuery());
      clock.advance(const Duration(seconds: 5));
      var page = (await repository.getPage(TransactionQuery())).valueOrNull!;
      expect(page.nextCursor, isNotNull);

      var total = page.items.length;
      while (page.nextCursor != null) {
        page = (await repository.getPage(
          TransactionQuery().nextPage(page.nextCursor!),
        )).valueOrNull!;
        total += page.items.length;
      }
      expect(total, server.data.transactions.length);
    });

    test('a cancelled request is reported as cancelled', () async {
      final cancel = CancelSignal()..cancel();
      final result = await repository.getPage(
        TransactionQuery(filter: TransactionFilter(query: 'pix')),
        cancel: cancel,
      );
      expect(result.failureOrNull, const CancelledFailure());
    });

    test('count: the server total, or what is saved when offline', () async {
      final filter = TransactionFilter(types: const {TransactionType.income});
      final online = (await repository.countTransactions(filter)).valueOrNull;
      expect(online, server.data.transactions.where((t) => t.isIncome).length);

      await repository.getPage(TransactionQuery(), force: true);
      settings.scenario = FakeScenario.offline;
      final offline = (await repository.countTransactions(filter)).valueOrNull;
      expect(
        offline,
        server.data.transactions.take(20).where((t) => t.isIncome).length,
      );
    });

    test('the cache stays small after scrolling far', () async {
      var query = TransactionQuery(limit: 100);
      for (var i = 0; i < 4; i++) {
        final page = (await repository.getPage(query)).valueOrNull!;
        query = query.nextPage(page.nextCursor!);
      }
      // A first page refresh prunes back to the newest ones.
      await repository.getPage(TransactionQuery(), force: true);
      expect(
        await local.count(TransactionFilter.none),
        LedgerLocalDataSource.keepNewest,
      );
    });
  });

  group('detail', () {
    test('saved summary first, then the full record, saved', () async {
      final withCard = server.data.transactions.firstWhere(
        (t) => t.cardLastDigits != null,
      );
      await local.saveSummaries([
        Transaction(
          id: withCard.id,
          description: withCard.description,
          amount: withCard.amount,
          type: withCard.type,
          status: withCard.status,
          occurredAt: withCard.occurredAt,
          method: withCard.method,
          category: withCard.category,
          counterparty: withCard.counterparty,
          detailed: false,
        ),
      ]);
      final summary = (await repository.savedTransaction(withCard.id))
          .valueOrNull;
      expect(summary?.detailed, isFalse);

      final full = (await repository.refreshTransaction(withCard.id))
          .valueOrNull!;
      expect(full.detailed, isTrue);
      expect(full.cardLastDigits, withCard.cardLastDigits);
      expect(
        (await repository.savedTransaction(withCard.id)).valueOrNull,
        full,
      );
    });

    test('unknown id: not found', () async {
      expect(
        (await repository.refreshTransaction('tx_unknown')).failureOrNull,
        const NotFoundFailure(),
      );
    });
  });

  test('a Pix arriving at the fake bank shows on the next look', () async {
    await repository.refreshDashboard(thisMonth);
    final before = settledOnServer();
    final pix = server.receivePix();

    final page = (await repository.getPage(
      TransactionQuery(),
      force: true,
    )).valueOrNull!;
    expect(page.items.first.id, pix.id);
    final snapshot = (await repository.refreshDashboard(
      thisMonth,
      force: true,
    )).valueOrNull!;
    expect(snapshot.settledBalance, before + const Money.cents(5000));
  });

  test(
    'the bank refusing the session: 401 on every endpoint, no fallback',
    () async {
      await repository.refreshDashboard(thisMonth);
      sessionValid = false;

      final dashboard = await repository.refreshDashboard(
        thisMonth,
        force: true,
      );
      final page = await repository.getPage(TransactionQuery(), force: true);
      final detail = await repository.refreshTransaction(
        server.data.transactions.first.id,
      );
      for (final result in [dashboard, page, detail]) {
        expect(result.failureOrNull, const UnauthorizedFailure());
      }
    },
  );

  test('expiring recent fetches makes the next refresh ask again', () async {
    await repository.refreshDashboard(thisMonth);
    repository.expireRecentFetches();
    await repository.refreshDashboard(thisMonth);
    expect(remote.accountCalls, 2);
    expect(await local.isEmpty(), isFalse, reason: 'nothing deleted');
  });

  test('clear empties the device and forgets recent fetches', () async {
    await repository.refreshDashboard(thisMonth);
    await repository.clear();
    expect(await local.isEmpty(), isTrue);
    expect((await repository.savedDashboard(thisMonth)).valueOrNull, isNull);
    final calls = remote.accountCalls;
    await repository.refreshDashboard(thisMonth);
    expect(remote.accountCalls, calls + 1);
  });
}

/// Passes everything through and counts what was asked.
final class _CountingRemote implements LedgerRemoteDataSource {
  _CountingRemote(this._inner);

  final LedgerRemoteDataSource _inner;
  var accountCalls = 0;
  final queries = <TransactionQuery>[];
  final bulkFilters = <TransactionFilter>[];

  @override
  Future<AccountDto> fetchAccount({CancelToken? cancelToken}) {
    accountCalls++;
    return _inner.fetchAccount(cancelToken: cancelToken);
  }

  @override
  Future<TransactionPageDto> fetchBulkPage(
    TransactionFilter filter, {
    String? cursor,
    CancelToken? cancelToken,
  }) {
    bulkFilters.add(filter);
    return _inner.fetchBulkPage(filter, cursor: cursor);
  }

  @override
  Future<TransactionPageDto> fetchTransactions(
    TransactionQuery query, {
    CancelToken? cancelToken,
  }) {
    queries.add(query);
    return _inner.fetchTransactions(query, cancelToken: cancelToken);
  }

  @override
  Future<TransactionDto> fetchTransaction(
    String id, {
    CancelToken? cancelToken,
  }) => _inner.fetchTransaction(id);
}

final class _AlwaysUnauthorized implements LedgerRemoteDataSource {
  Never _fail() => throw DioException.badResponse(
    statusCode: 401,
    requestOptions: RequestOptions(),
    response: Response<Object?>(
      requestOptions: RequestOptions(),
      statusCode: 401,
    ),
  );

  @override
  Future<AccountDto> fetchAccount({CancelToken? cancelToken}) async => _fail();

  @override
  Future<TransactionPageDto> fetchBulkPage(
    TransactionFilter filter, {
    String? cursor,
    CancelToken? cancelToken,
  }) async => _fail();

  @override
  Future<TransactionPageDto> fetchTransactions(
    TransactionQuery query, {
    CancelToken? cancelToken,
  }) async => _fail();

  @override
  Future<TransactionDto> fetchTransaction(
    String id, {
    CancelToken? cancelToken,
  }) async => _fail();
}

final class _RepeatingCursor implements LedgerRemoteDataSource {
  @override
  Future<AccountDto> fetchAccount({CancelToken? cancelToken}) async =>
      AccountDto(balanceCents: 0, currency: 'BRL', asOf: DateTime.utc(2026));

  @override
  Future<TransactionPageDto> fetchBulkPage(
    TransactionFilter filter, {
    String? cursor,
    CancelToken? cancelToken,
  }) async =>
      const TransactionPageDto(items: [], skippedItems: 0, nextCursor: 'same');

  @override
  Future<TransactionPageDto> fetchTransactions(
    TransactionQuery query, {
    CancelToken? cancelToken,
  }) async =>
      const TransactionPageDto(items: [], skippedItems: 0, nextCursor: null);

  @override
  Future<TransactionDto> fetchTransaction(
    String id, {
    CancelToken? cancelToken,
  }) => throw UnimplementedError();
}
