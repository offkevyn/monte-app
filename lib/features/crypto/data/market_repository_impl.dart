import 'package:dio/dio.dart';

import '../../../core/async/cancel_signal.dart';
import '../../../core/failures/failure.dart';
import '../../../core/freshness/data_freshness.dart';
import '../../../core/network/network_failures.dart';
import '../../../core/result/result.dart';
import '../../../core/time/clock.dart';
import '../domain/entities/coin.dart';
import '../domain/entities/market_data.dart';
import '../domain/repositories/market_repository.dart';
import 'coingecko/market_remote_datasource.dart';
import 'local/market_local_datasource.dart';

/// Offline-first access to CoinGecko, following the same rules as the
/// ledger repository:
///
/// - Fresh copy (saved less than [freshFor] ago): answer from the device,
///   spend no API call.
/// - Old or missing copy: ask the API and save the answer.
/// - API failed (no connection, 429, 5xx) and a copy exists: answer with it
///   marked as stale, and do not ask again for [retryCooldown] (asking
///   again during a 429 only makes the limit last longer).
/// - API failed and nothing was ever saved: the failure goes up.
final class MarketRepositoryImpl implements MarketRepository {
  MarketRepositoryImpl({
    required this._remote,
    required this._local,
    required this._clock,
    this.freshFor = const Duration(seconds: 60),
    this.chartFreshFor = const Duration(minutes: 5),
    this.retryCooldown = const Duration(seconds: 30),
    this.pageSize = 50,
  });

  final MarketRemoteDataSource _remote;
  final MarketLocalDataSource _local;
  final Clock _clock;

  /// CoinGecko itself caches these answers for 30 to 60 seconds.
  final Duration freshFor;
  final Duration chartFreshFor;
  final Duration retryCooldown;
  final int pageSize;

  static const _mostTraded = 'mostTraded';
  static const _trending = 'trending';

  /// Last failure per request kind, for the cooldown.
  final _failures = <String, ({Failure failure, DateTime at})>{};

  @override
  Future<Result<MarketList>> getMostTraded({
    required int page,
    bool forceRefresh = false,
  }) => _readThrough<StoredPage, MappedCoinsPage, MarketList>(
    key: '$_mostTraded/$page',
    readLocal: () => _local.readPage(_mostTraded, page),
    syncedAtOf: (stored) => stored.syncedAt,
    fetch: () async {
      final mapped = await _remote.fetchMostTraded(
        page: page,
        perPage: pageSize,
      );
      // A full page (even with broken items left out) means there may be
      // more after it.
      final full = mapped.coins.length + mapped.skipped >= pageSize;
      return (coins: mapped.coins, skipped: mapped.skipped, hasMore: full);
    },
    save: (fetched, now) => _local.savePage(
      _mostTraded,
      page,
      fetched.coins,
      syncedAt: now,
      hasMore: fetched.hasMore,
      skipped: fetched.skipped,
    ),
    build: _pageToList,
    forceRefresh: forceRefresh,
  );

  @override
  Future<Result<MarketList>> getTrending({bool forceRefresh = false}) =>
      _readThrough<StoredPage, MappedCoinsPage, MarketList>(
        key: _trending,
        readLocal: () => _local.readPage(_trending, 1),
        syncedAtOf: (stored) => stored.syncedAt,
        fetch: () async {
          final ids = await _remote.trendingIds();
          final mapped = await _remote.fetchByIds(ids);
          return (coins: mapped.coins, skipped: mapped.skipped, hasMore: false);
        },
        save: (fetched, now) => _local.savePage(
          _trending,
          1,
          fetched.coins,
          syncedAt: now,
          hasMore: false,
          skipped: fetched.skipped,
        ),
        build: _pageToList,
        forceRefresh: forceRefresh,
      );

  @override
  Future<Result<MarketList>> getFavorites({bool forceRefresh = false}) async {
    final idsResult = await _guardLocal(_local.favoriteIds);
    if (idsResult case Err(:final failure)) return Err(failure);
    final ids = idsResult.valueOrNull!;
    if (ids.isEmpty) {
      return Ok(
        MarketList(
          coins: const [],
          freshness: DataFreshness(syncedAt: _clock.nowUtc()),
        ),
      );
    }
    return _readThrough<StoredCoins, MappedCoinsPage, MarketList>(
      key: 'favorites/${ids.join(',')}',
      readLocal: () => _local.coinsByIds(ids),
      syncedAtOf: (stored) => stored.savedAt,
      fetch: () async {
        final mapped = await _remote.fetchByIds(ids);
        return (coins: mapped.coins, skipped: mapped.skipped, hasMore: false);
      },
      save: (fetched, now) async {
        await _local.saveCoins(fetched.coins, now);
        return StoredCoins(coins: fetched.coins, savedAt: now);
      },
      build: (stored, freshness) =>
          MarketList(coins: stored.coins, freshness: freshness),
      forceRefresh: forceRefresh,
    );
  }

  @override
  Future<Result<MarketList>> search(
    String query, {
    CancelSignal? cancel,
  }) async {
    final token = _tokenFor(cancel);
    final fetched = await guardRequest(() async {
      final ids = await _remote.searchIds(query, cancelToken: token);
      return _remote.fetchByIds(ids, cancelToken: token);
    });
    final now = _clock.nowUtc();
    switch (fetched) {
      case Ok(:final value):
        final saved = await _guardLocal(
          () => _local.saveCoins(value.coins, now),
        );
        if (saved case Err(:final failure)) return Err(failure);
        return Ok(
          MarketList(
            coins: value.coins,
            freshness: DataFreshness(
              syncedAt: now,
              skippedRecords: value.skipped,
            ),
          ),
        );
      case Err(:final failure) when failure is CancelledFailure:
        return Err(failure);
      case Err(:final failure):
        // No API: search what is already on the device.
        final local = await _guardLocal(() => _local.search(query));
        return local.map(
          (coins) => MarketList(
            coins: coins,
            freshness: DataFreshness(
              syncedAt: _latestUpdate(coins) ?? now,
              syncFailure: failure,
            ),
          ),
        );
    }
  }

  @override
  Future<Result<CoinQuote>> getCoin(
    String id, {
    bool forceRefresh = false,
  }) async {
    final result =
        await _readThrough<
          StoredCoins,
          MappedCoinsPage,
          (List<Coin>, DataFreshness)
        >(
          key: 'coin/$id',
          readLocal: () => _local.coinsByIds([id]),
          syncedAtOf: (stored) => stored.savedAt,
          fetch: () async {
            final mapped = await _remote.fetchByIds([id]);
            return (
              coins: mapped.coins,
              skipped: mapped.skipped,
              hasMore: false,
            );
          },
          save: (fetched, now) async {
            await _local.saveCoins(fetched.coins, now);
            return StoredCoins(coins: fetched.coins, savedAt: now);
          },
          build: (stored, freshness) => (stored.coins, freshness),
          forceRefresh: forceRefresh,
        );
    return switch (result) {
      Ok(value: (final coins, final freshness)) when coins.isNotEmpty => Ok(
        CoinQuote(coin: coins.first, freshness: freshness),
      ),
      Ok() => const Err(NotFoundFailure()),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<CoinChart>> getChart(
    String id,
    ChartRange range, {
    CancelSignal? cancel,
  }) {
    final token = _tokenFor(cancel);
    return _readThrough<StoredChart, List<PricePoint>, CoinChart>(
      key: 'chart/$id/${range.name}',
      readLocal: () => _local.readChart(id, range),
      syncedAtOf: (stored) => stored.syncedAt,
      freshFor: chartFreshFor,
      fetch: () => _remote.fetchChart(id, range, cancelToken: token),
      save: (points, now) => _local.saveChart(id, range, points, now),
      build: (stored, freshness) => CoinChart(
        coinId: id,
        range: range,
        points: stored.points,
        freshness: freshness,
      ),
      forceRefresh: false,
    );
  }

  @override
  Stream<Set<String>> watchFavoriteIds() => _local.watchFavoriteIds();

  @override
  Future<Result<bool>> toggleFavorite(String id) =>
      _guardLocal(() => _local.toggleFavorite(id, _clock.nowUtc()));

  @override
  Future<void> clear() async {
    _failures.clear();
    await _local.clear();
  }

  /// The common flow of every read; see the class comment.
  Future<Result<R>> _readThrough<S, F, R>({
    required String key,
    required Future<S?> Function() readLocal,
    required DateTime Function(S stored) syncedAtOf,
    required Future<F> Function() fetch,
    required Future<S> Function(F fetched, DateTime now) save,
    required R Function(S stored, DataFreshness freshness) build,
    required bool forceRefresh,
    Duration? freshFor,
  }) async {
    final localResult = await _guardLocal(readLocal);
    if (localResult case Err(:final failure)) return Err(failure);
    final local = localResult.valueOrNull;
    final now = _clock.nowUtc();
    final lastFailure = _failures[key];

    if (local != null && !forceRefresh) {
      final syncedAt = syncedAtOf(local);
      if (now.difference(syncedAt) < (freshFor ?? this.freshFor)) {
        return Ok(build(local, _freshness(syncedAt, local)));
      }
      if (lastFailure != null &&
          now.difference(lastFailure.at) < retryCooldown) {
        return Ok(
          build(local, _freshness(syncedAt, local, lastFailure.failure)),
        );
      }
    }

    final fetched = await guardRequest(fetch);
    switch (fetched) {
      case Ok(:final value):
        _failures.remove(key);
        final saved = await _guardLocal(() => save(value, _clock.nowUtc()));
        return saved.map(
          (stored) => build(stored, _freshness(syncedAtOf(stored), stored)),
        );
      case Err(:final failure):
        if (failure is! CancelledFailure) {
          _failures[key] = (failure: failure, at: _clock.nowUtc());
        }
        if (local == null || failure is CancelledFailure) return Err(failure);
        return Ok(build(local, _freshness(syncedAtOf(local), local, failure)));
    }
  }

  static DataFreshness _freshness(
    DateTime syncedAt,
    Object? stored, [
    Failure? failure,
  ]) => DataFreshness(
    syncedAt: syncedAt,
    syncFailure: failure,
    skippedRecords: stored is StoredPage ? stored.skipped : 0,
  );

  static MarketList _pageToList(StoredPage page, DataFreshness freshness) =>
      MarketList(
        coins: page.coins,
        hasMore: page.hasMore,
        freshness: freshness,
      );

  static DateTime? _latestUpdate(List<Coin> coins) {
    DateTime? latest;
    for (final coin in coins) {
      final at = coin.updatedAt;
      if (at != null && (latest == null || at.isAfter(latest))) latest = at;
    }
    return latest;
  }

  /// Bridges the domain's [CancelSignal] to Dio's [CancelToken].
  static CancelToken? _tokenFor(CancelSignal? signal) {
    if (signal == null) return null;
    final token = CancelToken();
    if (signal.isCancelled) {
      token.cancel();
    } else {
      signal.whenCancelled.then((_) => token.cancel());
    }
    return token;
  }

  /// Local database errors become [StorageFailure].
  static Future<Result<T>> _guardLocal<T>(Future<T> Function() read) async {
    try {
      return Ok(await read());
    } on FormatException catch (error) {
      return Err(InvalidDataFailure(error.message));
    } on ArgumentError catch (error) {
      return Err(InvalidDataFailure('${error.name}: ${error.message}'));
    } on Exception catch (error) {
      return Err(StorageFailure(error.runtimeType.toString()));
    }
  }
}

/// Coins fetched for a list, before saving.
typedef MappedCoinsPage = ({List<Coin> coins, int skipped, bool hasMore});
