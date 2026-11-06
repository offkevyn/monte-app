import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/async/cancel_signal.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/features/crypto/data/coingecko/coingecko_mapper.dart';
import 'package:monte/features/crypto/data/coingecko/market_remote_datasource.dart';
import 'package:monte/features/crypto/data/local/market_local_datasource.dart';
import 'package:monte/features/crypto/data/market_repository_impl.dart';
import 'package:monte/features/crypto/domain/entities/coin.dart';
import 'package:monte/features/crypto/domain/entities/crypto_price.dart';
import 'package:monte/features/crypto/domain/entities/market_data.dart';

import '../../../helpers/coins.dart';
import '../../../helpers/market_database.dart';

/// CoinGecko stand-in: answers from in-memory data, counts calls, and can
/// fail the way Dio fails.
class _FakeRemote implements MarketRemoteDataSource {
  _FakeRemote(this.market);

  List<Coin> market;
  List<String> trending = ['pepe', 'bitcoin'];
  Map<String, List<String>> searches = {};
  Map<String, List<PricePoint>> charts = {};
  DioException Function(RequestOptions options)? failWith;
  Completer<void>? gate;
  final calls = <String>[];

  Future<void> _call(String name, CancelToken? token) async {
    calls.add(name);
    final waiting = gate;
    if (waiting != null) {
      await Future.any([waiting.future, if (token != null) token.whenCancel]);
      if (token?.isCancelled ?? false) {
        throw DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.cancel,
        );
      }
    }
    final fail = failWith;
    if (fail != null) throw fail(RequestOptions(path: name));
  }

  @override
  Future<MappedCoins> fetchMostTraded({
    required int page,
    required int perPage,
    CancelToken? cancelToken,
  }) async {
    await _call('markets/$page', cancelToken);
    final start = (page - 1) * perPage;
    final end = (start + perPage).clamp(0, market.length);
    return (
      coins: start >= market.length ? <Coin>[] : market.sublist(start, end),
      skipped: 0,
    );
  }

  @override
  Future<MappedCoins> fetchByIds(
    List<String> ids, {
    CancelToken? cancelToken,
  }) async {
    await _call('ids/${ids.join(',')}', cancelToken);
    final byId = {for (final c in market) c.id: c};
    return (coins: [for (final id in ids) ?byId[id]], skipped: 0);
  }

  @override
  Future<List<String>> searchIds(
    String query, {
    CancelToken? cancelToken,
  }) async {
    await _call('search/$query', cancelToken);
    return searches[query] ?? const [];
  }

  @override
  Future<List<String>> trendingIds({CancelToken? cancelToken}) async {
    await _call('trending', cancelToken);
    return trending;
  }

  @override
  Future<List<PricePoint>> fetchChart(
    String id,
    ChartRange range, {
    CancelToken? cancelToken,
  }) async {
    await _call('chart/$id/${range.name}', cancelToken);
    return charts['$id/${range.name}'] ?? const [];
  }
}

DioException _offline(RequestOptions options) =>
    DioException.connectionError(requestOptions: options, reason: 'offline');

DioException _rateLimited(RequestOptions options) => DioException.badResponse(
  statusCode: 429,
  requestOptions: options,
  response: Response<Object?>(requestOptions: options, statusCode: 429),
);

void main() {
  late _FakeRemote remote;
  late FixedClock clock;
  late MarketLocalDataSource local;
  late MarketRepositoryImpl repository;

  final hundred = [for (var i = 0; i < 100; i++) coin('coin$i', rank: i + 1)];

  setUp(() {
    remote = _FakeRemote([
      coin('bitcoin', name: 'Bitcoin', symbol: 'btc', rank: 1),
      coin('pepe', name: 'Pepe', symbol: 'pepe', rank: 30),
      coin('solana', name: 'Solana', symbol: 'sol', rank: 5),
      ...hundred,
    ]);
    clock = FixedClock(DateTime.utc(2026, 11, 6, 17));
    local = MarketLocalDataSource(testMarketDatabase());
    repository = MarketRepositoryImpl(
      remote: remote,
      local: local,
      clock: clock,
    );
  });

  group('most traded', () {
    test('pages through the API and saves each page', () async {
      final first = (await repository.getMostTraded(page: 1)).valueOrNull!;
      final second = (await repository.getMostTraded(page: 2)).valueOrNull!;
      final third = (await repository.getMostTraded(page: 3)).valueOrNull!;

      expect(first.coins.first.id, 'bitcoin');
      expect(first.hasMore, isTrue);
      expect(second.coins, hasLength(50));
      expect(third.coins, hasLength(3));
      expect(third.hasMore, isFalse);
      expect(first.freshness.isStale, isFalse);
    });

    test('a fresh copy answers without calling the API', () async {
      await repository.getMostTraded(page: 1);
      clock.advance(const Duration(seconds: 59));
      await repository.getMostTraded(page: 1);
      expect(remote.calls, ['markets/1']);

      clock.advance(const Duration(seconds: 1));
      await repository.getMostTraded(page: 1);
      expect(remote.calls, ['markets/1', 'markets/1']);
    });

    test('pull to refresh always asks the API', () async {
      await repository.getMostTraded(page: 1);
      await repository.getMostTraded(page: 1, forceRefresh: true);
      expect(remote.calls, hasLength(2));
    });

    test('offline with a saved copy answers it as stale', () async {
      await repository.getMostTraded(page: 1);
      clock.advance(const Duration(minutes: 10));
      remote.failWith = _offline;

      final list = (await repository.getMostTraded(page: 1)).valueOrNull!;

      expect(list.coins, hasLength(50));
      expect(list.freshness.isStale, isTrue);
      expect(list.freshness.syncFailure, const NoConnectionFailure());
      expect(list.freshness.syncedAt, DateTime.utc(2026, 11, 6, 17));
    });

    test('after a 429 it waits the cooldown before asking again', () async {
      await repository.getMostTraded(page: 1);
      clock.advance(const Duration(minutes: 2));
      remote.failWith = _rateLimited;

      final first = (await repository.getMostTraded(page: 1)).valueOrNull!;
      expect(first.freshness.syncFailure, isA<RateLimitedFailure>());

      clock.advance(const Duration(seconds: 10));
      final second = (await repository.getMostTraded(page: 1)).valueOrNull!;
      expect(second.freshness.syncFailure, isA<RateLimitedFailure>());
      expect(remote.calls, ['markets/1', 'markets/1']);

      clock.advance(const Duration(seconds: 25));
      remote.failWith = null;
      final third = (await repository.getMostTraded(page: 1)).valueOrNull!;
      expect(third.freshness.isStale, isFalse);
      expect(remote.calls, hasLength(3));
    });

    test('offline with nothing saved is an error', () async {
      remote.failWith = _offline;
      expect(
        await repository.getMostTraded(page: 1),
        const Err<MarketList>(NoConnectionFailure()),
      );
    });

    test('refreshing page 1 starts the list over', () async {
      await repository.getMostTraded(page: 1);
      await repository.getMostTraded(page: 2);
      await repository.getMostTraded(page: 1, forceRefresh: true);

      expect(await local.readPage('mostTraded', 2), isNull);
    });
  });

  test('trending fetches the ids, then their prices, in order', () async {
    final list = (await repository.getTrending()).valueOrNull!;
    expect(list.coins.map((c) => c.id), ['pepe', 'bitcoin']);
    expect(list.hasMore, isFalse);
    expect(remote.calls, ['trending', 'ids/pepe,bitcoin']);
  });

  group('favorites', () {
    test('star, list in star order, unstar', () async {
      final watched = <Set<String>>[];
      final sub = repository.watchFavoriteIds().listen(watched.add);

      expect((await repository.getFavorites()).valueOrNull!.coins, isEmpty);
      expect(remote.calls, isEmpty);

      expect(await repository.toggleFavorite('solana'), const Ok(true));
      clock.advance(const Duration(seconds: 1));
      expect(await repository.toggleFavorite('bitcoin'), const Ok(true));

      final list = (await repository.getFavorites()).valueOrNull!;
      expect(list.coins.map((c) => c.id), ['solana', 'bitcoin']);

      expect(await repository.toggleFavorite('solana'), const Ok(false));
      await pumpEventQueue();
      expect(watched.last, {'bitcoin'});
      await sub.cancel();
    });

    test('offline, favorites come from the saved prices', () async {
      await repository.toggleFavorite('bitcoin');
      await repository.getFavorites();
      clock.advance(const Duration(minutes: 5));
      remote.failWith = _offline;

      final list = (await repository.getFavorites()).valueOrNull!;
      expect(list.coins.single.id, 'bitcoin');
      expect(list.freshness.isStale, isTrue);
    });
  });

  group('search', () {
    test('asks the API and keeps its relevance order', () async {
      remote.searches['sol'] = ['solana', 'coin1'];
      final list = (await repository.search('sol')).valueOrNull!;
      expect(list.coins.map((c) => c.id), ['solana', 'coin1']);
      expect(list.freshness.isStale, isFalse);
    });

    test('offline searches the coins already saved, accents ignored', () async {
      await repository.getMostTraded(page: 1);
      remote.failWith = _offline;

      final list = (await repository.search('Sólana')).valueOrNull!;

      expect(list.coins.map((c) => c.id), ['solana']);
      expect(list.freshness.syncFailure, const NoConnectionFailure());
    });

    test('a cancelled search is reported as cancelled', () async {
      remote.gate = Completer<void>();
      final cancel = CancelSignal();
      final pending = repository.search('sol', cancel: cancel);
      cancel.cancel();
      expect(await pending, const Err<MarketList>(CancelledFailure()));
    });
  });

  group('coin and chart', () {
    test('a coin comes from the saved copy while fresh', () async {
      await repository.getMostTraded(page: 1);
      final quote = (await repository.getCoin('bitcoin')).valueOrNull!;
      expect(quote.coin.id, 'bitcoin');
      expect(remote.calls, ['markets/1']);
    });

    test('an unknown coin is not found', () async {
      expect(
        await repository.getCoin('nope'),
        const Err<CoinQuote>(NotFoundFailure()),
      );
    });

    test('the chart is saved and served offline as stale', () async {
      final points = [
        for (var h = 0; h < 3; h++)
          PricePoint(
            at: DateTime.utc(2026, 11, 6, h),
            price: CryptoPrice.parse('${100 + h}.5'),
          ),
      ];
      remote.charts['bitcoin/week'] = points;

      final chart = (await repository.getChart(
        'bitcoin',
        ChartRange.week,
      )).valueOrNull!;
      expect(chart.points, points);

      clock.advance(const Duration(minutes: 6));
      remote.failWith = _offline;
      final offline = (await repository.getChart(
        'bitcoin',
        ChartRange.week,
      )).valueOrNull!;
      expect(offline.points, points);
      expect(offline.freshness.isStale, isTrue);
    });
  });

  test('clear deletes everything, favorites included', () async {
    await repository.getMostTraded(page: 1);
    await repository.toggleFavorite('bitcoin');
    await repository.clear();

    expect(await local.readPage('mostTraded', 1), isNull);
    expect(await local.favoriteIds(), isEmpty);
  });
}
