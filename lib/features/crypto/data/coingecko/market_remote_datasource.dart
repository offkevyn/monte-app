import 'package:dio/dio.dart';

import '../../../../core/network/request_deduplicator.dart';
import '../../domain/entities/coin.dart';
import '../../domain/entities/market_data.dart';
import 'coingecko_config.dart';
import 'coingecko_mapper.dart';

/// Talks to CoinGecko. Throws on failure (Dio errors, parsing errors); the
/// repository wraps calls with `guardRequest` to turn them into `Result`.
abstract interface class MarketRemoteDataSource {
  /// One page of `/coins/markets` ordered by 24h volume.
  Future<MappedCoins> fetchMostTraded({
    required int page,
    required int perPage,
    CancelToken? cancelToken,
  });

  /// Current numbers of specific coins, in the order of [ids].
  Future<MappedCoins> fetchByIds(List<String> ids, {CancelToken? cancelToken});

  Future<List<String>> searchIds(String query, {CancelToken? cancelToken});

  Future<List<String>> trendingIds({CancelToken? cancelToken});

  Future<List<PricePoint>> fetchChart(
    String id,
    ChartRange range, {
    CancelToken? cancelToken,
  });
}

final class CoinGeckoRemoteDataSource implements MarketRemoteDataSource {
  CoinGeckoRemoteDataSource(this._dio, {RequestDeduplicator? deduplicator})
    : _dedup = deduplicator ?? RequestDeduplicator();

  final Dio _dio;
  final RequestDeduplicator _dedup;

  /// Search answers are cut to this many coins, each one costs nothing
  /// extra (one `/coins/markets` call brings all their prices).
  static const searchLimit = 20;
  static const trendingLimit = 15;

  @override
  Future<MappedCoins> fetchMostTraded({
    required int page,
    required int perPage,
    CancelToken? cancelToken,
  }) async => CoinGeckoMapper.coins(
    await _get(
      '/coins/markets',
      query: {
        ..._marketQuery,
        'order': 'volume_desc',
        'per_page': '$perPage',
        'page': '$page',
      },
      cancelToken: cancelToken,
    ),
  );

  @override
  Future<MappedCoins> fetchByIds(
    List<String> ids, {
    CancelToken? cancelToken,
  }) async {
    if (ids.isEmpty) return (coins: <Coin>[], skipped: 0);
    final mapped = CoinGeckoMapper.coins(
      await _get(
        '/coins/markets',
        query: {
          ..._marketQuery,
          'ids': ids.join(','),
          'per_page': '${ids.length}',
          'page': '1',
        },
        cancelToken: cancelToken,
      ),
    );
    // The API sorts by market value; keep the order that was asked for
    // (search relevance, trending position, order of the favorites).
    final byId = {for (final coin in mapped.coins) coin.id: coin};
    return (coins: [for (final id in ids) ?byId[id]], skipped: mapped.skipped);
  }

  @override
  Future<List<String>> searchIds(
    String query, {
    CancelToken? cancelToken,
  }) async => CoinGeckoMapper.searchIds(
    await _get('/search', query: {'query': query}, cancelToken: cancelToken),
    limit: searchLimit,
  );

  @override
  Future<List<String>> trendingIds({CancelToken? cancelToken}) async =>
      CoinGeckoMapper.trendingIds(
        await _get('/search/trending', cancelToken: cancelToken),
        limit: trendingLimit,
      );

  @override
  Future<List<PricePoint>> fetchChart(
    String id,
    ChartRange range, {
    CancelToken? cancelToken,
  }) async => CoinGeckoMapper.chart(
    await _get(
      '/coins/${Uri.encodeComponent(id)}/market_chart',
      query: {'vs_currency': CoinGeckoConfig.currency, 'days': '${range.days}'},
      cancelToken: cancelToken,
    ),
  );

  static const _marketQuery = {
    'vs_currency': CoinGeckoConfig.currency,
    'price_change_percentage': '24h',
  };

  /// Two screens asking for the same thing at once share one call, which
  /// matters with a limit of calls per minute.
  Future<Object?> _get(
    String path, {
    Map<String, String> query = const {},
    CancelToken? cancelToken,
  }) {
    final key = Uri(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
    return _dedup.run(
      key,
      (token) async => (await _dio.get<Object?>(
        path,
        queryParameters: query,
        cancelToken: token,
      )).data,
      cancelToken: cancelToken,
    );
  }
}
