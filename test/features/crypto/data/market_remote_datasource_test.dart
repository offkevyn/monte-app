import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/network/api_client_factory.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';
import 'package:monte/core/network/network_failures.dart';
import 'package:monte/core/network/retry_interceptor.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/features/crypto/data/coingecko/coingecko_config.dart';
import 'package:monte/features/crypto/data/coingecko/market_remote_datasource.dart';
import 'package:monte/features/crypto/data/coingecko/simulated_conditions_interceptor.dart';
import 'package:monte/features/crypto/domain/entities/market_data.dart';

import '../../../helpers/coins.dart';
import '../../../helpers/scripted_adapter.dart';

void main() {
  Dio dio(
    ScriptedAdapter adapter, {
    List<Interceptor> interceptors = const [],
  }) => ApiClientFactory.create(
    baseUrl: CoinGeckoConfig.baseUrl,
    adapter: adapter,
    headers: CoinGeckoConfig.headers(key: 'CG-test'),
    interceptors: interceptors,
    retryPolicy: const RetryPolicy(baseDelay: Duration.zero, jitter: 0),
    sleep: (_) async {},
  );

  test('the key goes in the header, never in the URL', () async {
    final adapter = ScriptedAdapter([const ScriptStep.ok(<Object?>[])]);
    await CoinGeckoRemoteDataSource(dio(adapter))
        .fetchMostTraded(page: 1, perPage: 50);

    final request = adapter.requests.single;
    expect(request.headers['x-cg-demo-api-key'], 'CG-test');
    expect(request.uri.toString(), isNot(contains('CG-test')));
  });

  test('no key means no header (public access)', () {
    expect(CoinGeckoConfig.headers(), isEmpty);
  });

  test('most traded asks one page in reais by volume', () async {
    final adapter = ScriptedAdapter([
      ScriptStep.ok([marketJson('tether'), marketJson('bitcoin')]),
    ]);
    final mapped = await CoinGeckoRemoteDataSource(dio(adapter))
        .fetchMostTraded(page: 3, perPage: 50);

    final query = adapter.requests.single.queryParameters;
    expect(adapter.requests.single.path, '/coins/markets');
    expect(query['vs_currency'], 'brl');
    expect(query['order'], 'volume_desc');
    expect(query['page'], '3');
    expect(query['per_page'], '50');
    expect(mapped.coins.map((c) => c.id), ['tether', 'bitcoin']);
  });

  test('fetchByIds keeps the order that was asked for', () async {
    final adapter = ScriptedAdapter([
      ScriptStep.ok([marketJson('bitcoin'), marketJson('pepe')]),
    ]);
    final mapped = await CoinGeckoRemoteDataSource(dio(adapter))
        .fetchByIds(['pepe', 'gone', 'bitcoin']);

    expect(adapter.requests.single.queryParameters['ids'], 'pepe,gone,bitcoin');
    expect(mapped.coins.map((c) => c.id), ['pepe', 'bitcoin']);
  });

  test('fetchByIds with no ids spends no call', () async {
    final adapter = ScriptedAdapter([]);
    final mapped = await CoinGeckoRemoteDataSource(dio(adapter)).fetchByIds([]);
    expect(mapped.coins, isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test('search, trending and chart hit the right endpoints', () async {
    final adapter = ScriptedAdapter([
      const ScriptStep.ok({
        'coins': [
          {'id': 'solana'},
        ],
      }),
      const ScriptStep.ok({
        'coins': [
          {
            'item': {'id': 'pepe'},
          },
        ],
      }),
      const ScriptStep.ok({
        'prices': [
          [1793910300000, 1.5],
        ],
      }),
    ]);
    final remote = CoinGeckoRemoteDataSource(dio(adapter));

    expect(await remote.searchIds('sol'), ['solana']);
    expect(await remote.trendingIds(), ['pepe']);
    expect(await remote.fetchChart('bitcoin', ChartRange.week), hasLength(1));

    expect(adapter.requests[0].path, '/search');
    expect(adapter.requests[0].queryParameters['query'], 'sol');
    expect(adapter.requests[1].path, '/search/trending');
    expect(adapter.requests[2].path, '/coins/bitcoin/market_chart');
    expect(adapter.requests[2].queryParameters['days'], '7');
  });

  test('two screens asking the same page share one call', () async {
    final adapter = ScriptedAdapter([
      ScriptStep.ok([marketJson('bitcoin')], const Duration(milliseconds: 20)),
    ]);
    final remote = CoinGeckoRemoteDataSource(dio(adapter));
    final results = await Future.wait([
      remote.fetchMostTraded(page: 1, perPage: 50),
      remote.fetchMostTraded(page: 1, perPage: 50),
    ]);
    expect(adapter.requests, hasLength(1));
    expect(results[0].coins, results[1].coins);
  });

  group('SimulatedConditionsInterceptor', () {
    late FakeBackendSettings settings;
    late FixedClock clock;
    late SimulatedConditionsInterceptor simulated;

    setUp(() {
      settings = FakeBackendSettings();
      clock = FixedClock(DateTime.utc(2026, 11, 6, 17));
      simulated = SimulatedConditionsInterceptor(settings, clock);
    });

    Future<Object?> call(ScriptedAdapter adapter) async {
      try {
        final client = dio(adapter, interceptors: [simulated]);
        return (await client.get<Object?>('/ping')).data;
      } on DioException catch (error) {
        return failureFromDio(error);
      }
    }

    test('normal lets every request through', () async {
      final adapter = ScriptedAdapter([const ScriptStep.ok()]);
      expect(await call(adapter), {'ok': true});
    });

    test('offline fails as no connection, without reaching the API', () async {
      settings.scenario = FakeScenario.offline;
      final adapter = ScriptedAdapter([]);
      expect(await call(adapter), const NoConnectionFailure());
      expect(adapter.requests, isEmpty);
    });

    test('server error answers 500 after the retries', () async {
      settings.scenario = FakeScenario.serverError;
      expect(
        await call(ScriptedAdapter([])),
        const ServerFailure(statusCode: 500),
      );
    });

    test(
      'rate limit answers 429 with the seconds left, then recovers',
      () async {
        settings.scenario = FakeScenario.rateLimited;
        final adapter = ScriptedAdapter([
          const ScriptStep.ok(),
          const ScriptStep.ok(),
        ]);

        expect(
          await call(adapter),
          const RateLimitedFailure(retryAfter: Duration(seconds: 15)),
        );
        clock.advance(const Duration(seconds: 10));
        expect(
          await call(adapter),
          const RateLimitedFailure(retryAfter: Duration(seconds: 5)),
        );
        clock.advance(const Duration(seconds: 5));
        expect(await call(adapter), {'ok': true});
        // Served once: does not come back until the scenario is picked again.
        expect(await call(adapter), {'ok': true});
        expect(adapter.requests, hasLength(2));
      },
    );
  });
}
