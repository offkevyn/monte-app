import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/network/api_client_factory.dart';
import 'package:monte/core/network/fake/fake_http_adapter.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';
import 'package:monte/core/network/retry_interceptor.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/features/ledger/data/datasources/ledger_remote_datasource.dart';
import 'package:monte/features/ledger/data/dtos/transaction_dto.dart';
import 'package:monte/features/ledger/data/fake/fake_ledger_server.dart';
import 'package:monte/features/ledger/data/local/ledger_local_datasource.dart';
import 'package:monte/features/ledger/data/repositories/ledger_repository_impl.dart';
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
  late LedgerRepositoryImpl repository;

  LedgerRepositoryImpl build(LedgerRemoteDataSource remote) =>
      LedgerRepositoryImpl(remote: remote, local: local, clock: clock);

  setUp(() {
    clock = FixedClock(DateTime.utc(2026, 11, 6, 2, 30));
    settings = FakeBackendSettings();
    server = FakeLedgerServer(settings: settings, clock: clock);
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
    repository = build(DioLedgerRemoteDataSource(dio, calendar));
  });

  test('first load syncs everything and answers from the database', () async {
    final snapshot = (await repository.loadSnapshot()).valueOrNull!;

    expect(snapshot.transactions, server.data.transactions);
    expect(snapshot.openingBalance, server.data.openingBalance);
    expect(snapshot.freshness.isStale, isFalse);
    expect(snapshot.freshness.syncedAt, clock.nowUtc());
    // 1 account + 1 page of 500.
    expect(adapter.requestCount, 2);
  });

  test('inside the freshness window it does not touch the network', () async {
    await repository.loadSnapshot();
    clock.advance(const Duration(minutes: 4));
    await repository.loadSnapshot();
    await repository.getTransactions(TransactionQuery());
    await repository.getTransaction(server.data.transactions.first.id);
    expect(adapter.requestCount, 2);
  });

  test('after the window, or on pull to refresh, it syncs again', () async {
    await repository.loadSnapshot();
    clock.advance(const Duration(minutes: 6));
    await repository.loadSnapshot();
    expect(adapter.requestCount, 4);

    await repository.loadSnapshot(forceRefresh: true);
    expect(adapter.requestCount, 6);
  });

  test(
    'offline with a local copy: serves it, marked stale with the reason',
    () async {
      await repository.loadSnapshot();
      settings.scenario = FakeScenario.offline;

      final snapshot = (await repository.loadSnapshot(forceRefresh: true))
          .valueOrNull!;

      expect(snapshot.transactions, hasLength(500));
      expect(snapshot.freshness.isStale, isTrue);
      expect(snapshot.freshness.syncFailure, const NoConnectionFailure());
      expect(snapshot.freshness.syncedAt, DateTime.utc(2026, 11, 6, 2, 30));
    },
  );

  test(
    'offline on the very first launch: the failure reaches the screen',
    () async {
      settings.scenario = FakeScenario.offline;
      expect(
        (await repository.loadSnapshot()).failureOrNull,
        const NoConnectionFailure(),
      );
      expect(
        (await repository.getTransactions(TransactionQuery())).failureOrNull,
        const NoConnectionFailure(),
      );
    },
  );

  test(
    'after a failed sync it waits before trying the network again',
    () async {
      await repository.loadSnapshot();
      clock.advance(const Duration(minutes: 10));
      settings.scenario = FakeScenario.offline;

      await repository.loadSnapshot(); // fails, serves stale
      final afterFailure = adapter.requestCount;

      // Paging through the statement right after must not retry every time.
      for (var i = 0; i < 3; i++) {
        final page = await repository.getTransactions(TransactionQuery());
        expect(page.valueOrNull!.freshness.isStale, isTrue);
      }
      expect(adapter.requestCount, afterFailure);

      // Back online and past the cooldown: syncs and the banner goes away.
      settings.scenario = FakeScenario.normal;
      clock.advance(const Duration(seconds: 31));
      final page = await repository.getTransactions(TransactionQuery());
      expect(page.valueOrNull!.freshness.isStale, isFalse);
    },
  );

  test('a sync that fails halfway keeps the previous copy intact', () async {
    await repository.loadSnapshot();
    final before = (await repository.loadSnapshot()).valueOrNull!.transactions;

    final flaky = _FailOnSecondPage(
      DioLedgerRemoteDataSource(
        ApiClientFactory.create(
          baseUrl: ApiClientFactory.fakeBankBaseUrl,
          adapter: adapter,
          sleep: (_) async {},
        ),
        calendar,
      ),
    );
    settings.updateData(volume: FakeVolume.large); // needs many pages now
    final result = await build(flaky).loadSnapshot(forceRefresh: true);

    expect(result.valueOrNull!.freshness.isStale, isTrue);
    expect(result.valueOrNull!.transactions, before);
  });

  test('simultaneous loads share one sync', () async {
    await Future.wait([
      repository.loadSnapshot(),
      repository.loadSnapshot(),
      repository.getTransactions(TransactionQuery()),
    ]);
    expect(adapter.requestCount, 2);
  });

  test('statement pages come filtered from the database', () async {
    final filter = TransactionFilter(types: {TransactionType.income});
    final page = (await repository.getTransactions(
      TransactionQuery(filter: filter),
    )).valueOrNull!;
    expect(page.items, isNotEmpty);
    expect(page.items.every((t) => t.isIncome), isTrue);
    expect(page.hasMore, isTrue);
  });

  test('a cursor from elsewhere becomes InvalidDataFailure', () async {
    final result = await repository.getTransactions(
      TransactionQuery(cursor: 'bm9wZQ=='),
    );
    expect(result.failureOrNull, isA<InvalidDataFailure>());
  });

  test('detail: found, and NotFound for an unknown id', () async {
    final target = server.data.transactions[10];
    expect((await repository.getTransaction(target.id)).valueOrNull, target);
    expect(
      (await repository.getTransaction('tx_unknown')).failureOrNull,
      const NotFoundFailure(),
    );
  });

  test('corrupted records are left out and counted', () async {
    settings.scenario = FakeScenario.corruptedData;
    final snapshot = (await repository.loadSnapshot()).valueOrNull!;
    // One page of 500: positions 3, 10, ..., 493 are broken (71).
    expect(snapshot.freshness.skippedRecords, 71);
    expect(snapshot.transactions, hasLength(500 - 71));
  });

  test('session expired is reported even with a local copy', () async {
    await repository.loadSnapshot();
    final expired = build(_AlwaysUnauthorized());
    expect(
      (await expired.loadSnapshot(forceRefresh: true)).failureOrNull,
      const UnauthorizedFailure(),
    );
  });

  test('clear wipes the local copy, so the next read syncs again', () async {
    await repository.loadSnapshot();
    await repository.clear();
    expect(await local.readSyncState(), isNull);
    expect(await local.all(), isEmpty);

    await repository.loadSnapshot();
    expect(adapter.requestCount, 4);
  });

  test('a server that repeats its cursor does not loop forever', () async {
    final result = await build(_RepeatingCursor()).loadSnapshot();
    expect(result.failureOrNull, isA<InvalidDataFailure>());
  });
}

/// Delegates to the real datasource but fails on the second sync page.
final class _FailOnSecondPage implements LedgerRemoteDataSource {
  _FailOnSecondPage(this._inner);

  final LedgerRemoteDataSource _inner;
  var _pages = 0;

  @override
  Future<AccountDto> fetchAccount({CancelToken? cancelToken}) =>
      _inner.fetchAccount();

  @override
  Future<TransactionPageDto> fetchSyncPage({String? cursor, int limit = 500}) {
    if (++_pages == 2) {
      throw DioException.connectionError(
        requestOptions: RequestOptions(),
        reason: 'dropped',
      );
    }
    return _inner.fetchSyncPage(cursor: cursor, limit: limit);
  }

  @override
  Future<TransactionPageDto> fetchTransactions(
    TransactionQuery query, {
    CancelToken? cancelToken,
  }) => _inner.fetchTransactions(query);

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
  Future<TransactionPageDto> fetchSyncPage({
    String? cursor,
    int limit = 500,
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
      const AccountDto(openingBalanceCents: 0, currency: 'BRL');

  @override
  Future<TransactionPageDto> fetchSyncPage({
    String? cursor,
    int limit = 500,
  }) async =>
      const TransactionPageDto(items: [], skippedItems: 0, nextCursor: 'same');

  @override
  Future<TransactionPageDto> fetchTransactions(
    TransactionQuery query, {
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<TransactionDto> fetchTransaction(
    String id, {
    CancelToken? cancelToken,
  }) => throw UnimplementedError();
}
