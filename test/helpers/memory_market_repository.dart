import 'dart:async';

import 'package:monte/core/async/cancel_signal.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/freshness/data_freshness.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/features/crypto/domain/entities/coin.dart';
import 'package:monte/features/crypto/domain/entities/market_data.dart';
import 'package:monte/features/crypto/domain/repositories/market_repository.dart';

/// Market data in memory that answers right away, so cubit and widget tests
/// can drive the real view models. Every call is recorded in [calls].
class MemoryMarketRepository implements MarketRepository {
  MemoryMarketRepository(this.market, {this.pageSize = 50});

  /// Most traded order; also the pool for ids, trending and search.
  List<Coin> market;
  final int pageSize;
  List<String> trendingIds = [];
  Map<String, List<String>> searches = {};
  Map<String, List<PricePoint>> charts = {};

  /// When set, every read fails with it.
  Failure? failWith;

  /// When set, only reads of a later page fail with it.
  Failure? failPagesWith;
  DataFreshness freshness = DataFreshness(
    syncedAt: DateTime.utc(2026, 11, 6, 17),
  );
  final calls = <String>[];

  final _favorites = <String>[];
  final _favoritesController = StreamController<Set<String>>.broadcast();

  MarketList _list(List<Coin> coins, {bool hasMore = false}) =>
      MarketList(coins: coins, freshness: freshness, hasMore: hasMore);

  List<Coin> _byIds(List<String> ids) {
    final byId = {for (final coin in market) coin.id: coin};
    return [for (final id in ids) ?byId[id]];
  }

  Result<T>? _fail<T>() {
    final failure = failWith;
    return failure == null ? null : Err(failure);
  }

  @override
  Future<Result<MarketList>> getMostTraded({
    required int page,
    bool forceRefresh = false,
  }) async {
    calls.add('mostTraded/$page${forceRefresh ? '!' : ''}');
    final pageFailure = failPagesWith;
    if (page > 1 && pageFailure != null) return Err(pageFailure);
    final failed = _fail<MarketList>();
    if (failed != null) return failed;
    final start = (page - 1) * pageSize;
    if (start >= market.length) return Ok(_list(const []));
    final end = (start + pageSize).clamp(0, market.length);
    return Ok(_list(market.sublist(start, end), hasMore: end < market.length));
  }

  @override
  Future<Result<MarketList>> getTrending({bool forceRefresh = false}) async {
    calls.add('trending');
    return _fail() ?? Ok(_list(_byIds(trendingIds)));
  }

  @override
  Future<Result<MarketList>> getFavorites({bool forceRefresh = false}) async {
    calls.add('favorites');
    return _fail() ?? Ok(_list(_byIds(_favorites)));
  }

  @override
  Future<Result<MarketList>> getCoins(
    List<String> ids, {
    bool forceRefresh = false,
  }) async {
    calls.add('coins/${ids.join(',')}');
    return _fail() ?? Ok(_list(_byIds(ids)));
  }

  @override
  Future<Result<MarketList>> search(
    String query, {
    CancelSignal? cancel,
  }) async {
    calls.add('search/$query');
    return _fail() ?? Ok(_list(_byIds(searches[query] ?? const [])));
  }

  @override
  Future<Result<CoinQuote>> getCoin(
    String id, {
    bool forceRefresh = false,
  }) async {
    calls.add('coin/$id');
    final failed = _fail<CoinQuote>();
    if (failed != null) return failed;
    final found = _byIds([id]);
    if (found.isEmpty) return const Err(NotFoundFailure());
    return Ok(CoinQuote(coin: found.single, freshness: freshness));
  }

  @override
  Future<Result<CoinChart>> getChart(
    String id,
    ChartRange range, {
    CancelSignal? cancel,
  }) async {
    calls.add('chart/$id/${range.name}');
    return _fail() ??
        Ok(
          CoinChart(
            coinId: id,
            range: range,
            points: charts['$id/${range.name}'] ?? const [],
            freshness: freshness,
          ),
        );
  }

  @override
  Stream<Set<String>> watchFavoriteIds() async* {
    yield _favorites.toSet();
    yield* _favoritesController.stream;
  }

  @override
  Future<Result<bool>> toggleFavorite(String id) async {
    final starred = !_favorites.remove(id);
    if (starred) _favorites.add(id);
    _favoritesController.add(_favorites.toSet());
    return Ok(starred);
  }

  @override
  Future<void> clear() async => _favorites.clear();
}
