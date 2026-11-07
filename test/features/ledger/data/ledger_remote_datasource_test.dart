import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/network/api_client_factory.dart';
import 'package:monte/core/network/fake/fake_http_adapter.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';
import 'package:monte/core/network/network_failures.dart';
import 'package:monte/core/network/retry_interceptor.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/data/datasources/ledger_remote_datasource.dart';
import 'package:monte/features/ledger/data/fake/fake_ledger_server.dart';
import 'package:monte/features/ledger/data/mappers/transaction_mapper.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/entities/transaction_filter.dart';
import 'package:monte/features/ledger/domain/entities/transaction_page.dart';

/// Datasource + Dio + retry + fake adapter + fake server, all real: the same
/// pipeline the app runs, with time and waits under control.
void main() {
  const calendar = FixedOffsetCalendar.brasilia;
  late FakeBackendSettings settings;
  late FakeLedgerServer server;
  late FakeHttpAdapter adapter;
  late DioLedgerRemoteDataSource source;
  late List<Duration> retryWaits;

  setUp(() {
    retryWaits = [];
    settings = FakeBackendSettings(volume: FakeVolume.small);
    server = FakeLedgerServer(
      settings: settings,
      clock: FixedClock(DateTime.utc(2026, 11, 6, 2, 30)),
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
      sleep: (d) async => retryWaits.add(d),
    );
    source = DioLedgerRemoteDataSource(dio, calendar);
  });

  /// Walks every page, like scrolling to the end of the statement.
  Future<List<Transaction>> readAll(
    TransactionFilter filter, {
    int limit = 7,
  }) async {
    final all = <Transaction>[];
    var query = TransactionQuery(filter: filter, limit: limit);
    while (true) {
      final page = await source.fetchTransactions(query);
      all.addAll(TransactionMapper.toEntities(page).items);
      final next = page.nextCursor;
      if (next == null) return all;
      query = query.nextPage(next);
    }
  }

  test('account answers the settled balance, computed by the server', () async {
    final account = await source.fetchAccount();
    expect(account.currency, 'BRL');
    final settled = server.data.transactions
        .where((t) => t.status == TransactionStatus.completed)
        .fold(server.data.openingBalance, (sum, t) => sum + t.signedAmount);
    expect(account.balanceCents, settled.cents);
    expect(account.asOf, DateTime.utc(2026, 11, 6, 2, 30));
  });

  test(
    'the list sends summaries and the total; the detail sends all',
    () async {
      final page = await source.fetchTransactions(TransactionQuery(limit: 5));
      expect(page.total, server.data.transactions.length);
      for (final item in page.items) {
        expect(item.cardLast4, isNull);
        expect(item.message, isNull);
      }
      final summary = TransactionMapper.toEntities(page).items.first;
      expect(summary.detailed, isFalse);

      final withCard = server.data.transactions.firstWhere(
        (t) => t.cardLastDigits != null,
      );
      final detail = TransactionMapper.toEntity(
        await source.fetchTransaction(withCard.id),
      );
      expect(detail.detailed, isTrue);
      expect(detail.cardLastDigits, withCard.cardLastDigits);
    },
  );

  test('a bulk page brings up to 500 of a filter', () async {
    final page = await source.fetchBulkPage(TransactionFilter.none);
    expect(page.items, hasLength(server.data.transactions.length));
    expect(page.nextCursor, isNull);
  });

  test(
    'paging through everything returns each transaction once, in order',
    () async {
      final all = await readAll(TransactionFilter.none);
      expect(all.map((t) => t.id), server.data.transactions.map((t) => t.id));
      expect(all.map((t) => t.id).toSet(), hasLength(all.length));
    },
  );

  test('server filters agree with the domain filter rules', () async {
    final filters = [
      TransactionFilter(types: {TransactionType.income}),
      TransactionFilter(
        statuses: {TransactionStatus.pending, TransactionStatus.failed},
      ),
      TransactionFilter(query: 'padaria'),
      TransactionFilter(query: 'PIX recebido'),
      TransactionFilter(
        period: DateSpan(LocalDate(2026, 10, 20), LocalDate(2026, 10, 31)),
      ),
      TransactionFilter(
        types: {TransactionType.expense},
        statuses: {TransactionStatus.completed},
        period: DateSpan(LocalDate(2026, 10, 1), LocalDate(2026, 11, 5)),
        query: 'uber',
      ),
    ];

    for (final filter in filters) {
      final expected = server.data.transactions
          .where((t) => filter.matches(t, calendar))
          .toList();
      expect(
        (await readAll(filter)).map((t) => t.id),
        expected.map((t) => t.id),
        reason: '$filter',
      );
    }
  });

  test('detail by id, and 404 for an unknown id', () async {
    final known = server.data.transactions[3];
    final dto = await source.fetchTransaction(known.id);
    expect(TransactionMapper.toEntity(dto), known);

    final result = await guardRequest(() => source.fetchTransaction('tx_nope'));
    expect(result.failureOrNull, const NotFoundFailure());
  });

  test('a forged cursor is refused by the server', () async {
    final result = await guardRequest(
      () => source.fetchTransactions(TransactionQuery(cursor: 'not-a-cursor')),
    );
    expect(result.failureOrNull, const ServerFailure(statusCode: 400));
  });

  group('scenarios', () {
    test('empty: no transactions and zero balance', () async {
      settings.scenario = FakeScenario.empty;
      expect(await readAll(TransactionFilter.none), isEmpty);
      expect((await source.fetchAccount()).balanceCents, 0);
      final detail = await guardRequest(
        () => source.fetchTransaction(server.data.transactions.first.id),
      );
      expect(detail.failureOrNull, const NotFoundFailure());
    });

    test('offline: retries, then reports no connection', () async {
      settings.scenario = FakeScenario.offline;
      final result = await guardRequest(source.fetchAccount);
      expect(result.failureOrNull, const NoConnectionFailure());
      expect(retryWaits, hasLength(3));
    });

    test('server error: retries, then reports the 500', () async {
      settings.scenario = FakeScenario.serverError;
      final result = await guardRequest(source.fetchAccount);
      expect(result.failureOrNull, const ServerFailure(statusCode: 500));
      expect(adapter.requestCount, 4);
    });

    test('rate limited: waits Retry-After twice, then succeeds', () async {
      settings.scenario = FakeScenario.rateLimited;
      final account = await source.fetchAccount();
      expect(account.currency, 'BRL');
      expect(retryWaits, [
        const Duration(seconds: 1),
        const Duration(seconds: 1),
      ]);
    });

    test('corrupted data: broken records are skipped and counted', () async {
      settings.scenario = FakeScenario.corruptedData;
      final page = await source.fetchTransactions(TransactionQuery());
      final mapped = TransactionMapper.toEntities(page);
      expect(mapped.skipped, 3); // positions 3, 10 and 17
      expect(mapped.items, hasLength(17));
    });

    test('changing the volume regenerates the data', () async {
      expect(server.data.transactions, hasLength(50));
      settings.updateData(volume: FakeVolume.medium);
      expect(server.data.transactions, hasLength(500));
    });
  });

  group('request handling', () {
    test('identical calls at the same time reach the server once', () async {
      await Future.wait([
        source.fetchAccount(),
        source.fetchAccount(),
        source.fetchAccount(),
      ]);
      expect(adapter.requestCount, 1);
    });

    test('a cancelled search reports CancelledFailure', () async {
      final token = CancelToken()..cancel('user typed again');
      final result = await guardRequest(
        () => source.fetchTransactions(TransactionQuery(), cancelToken: token),
      );
      expect(result.failureOrNull, const CancelledFailure());
    });

    test('unknown route answers 404', () async {
      final dio = ApiClientFactory.create(
        baseUrl: ApiClientFactory.fakeBankBaseUrl,
        adapter: adapter,
      );
      final result = await guardRequest(() => dio.get<Object?>('/v2/nothing'));
      expect(result.failureOrNull, const NotFoundFailure());
    });

    test('limit outside the allowed range is refused', () async {
      final dio = ApiClientFactory.create(
        baseUrl: ApiClientFactory.fakeBankBaseUrl,
        adapter: adapter,
      );
      final result = await guardRequest(
        () => dio.get<Object?>(
          '/v1/transactions',
          queryParameters: {'limit': '9999'},
        ),
      );
      expect(result.failureOrNull, const ServerFailure(statusCode: 400));
    });
  });

  group('encodeQuery', () {
    test('first page with no filter only sends the limit', () {
      expect(
        DioLedgerRemoteDataSource.encodeQuery(TransactionQuery(), calendar),
        {'limit': '20'},
      );
    });

    test('sends the period as UTC instants of the local days', () {
      final params = DioLedgerRemoteDataSource.encodeQuery(
        TransactionQuery(
          filter: TransactionFilter(
            types: {TransactionType.expense, TransactionType.income},
            statuses: {TransactionStatus.pending},
            period: DateSpan(LocalDate(2026, 11, 1), LocalDate(2026, 11, 30)),
            query: '  café  ',
          ),
          cursor: 'abc',
          limit: 50,
        ),
        calendar,
      );
      expect(params, {
        'limit': '50',
        'cursor': 'abc',
        'type': 'credit,debit',
        'status': 'pending',
        'from': '2026-11-01T03:00:00.000Z',
        'to': '2026-12-01T03:00:00.000Z',
        'q': 'café',
      });
    });
  });
}
