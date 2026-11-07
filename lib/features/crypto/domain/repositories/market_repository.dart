import '../../../../core/async/cancel_signal.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/user_data.dart';
import '../entities/market_data.dart';

/// Crypto market data, read from CoinGecko and kept on the device.
///
/// Same rule as the ledger: the local database is the source of truth. A
/// read answers from it while it is fresh, otherwise asks the API and
/// saves the answer. When the API fails (no connection, 429) and something
/// was saved before, that copy comes back marked as stale instead of an
/// error.
abstract interface class MarketRepository implements UserData {
  /// One page of the most traded coins. Pages start at 1.
  Future<Result<MarketList>> getMostTraded({
    required int page,
    bool forceRefresh = false,
  });

  Future<Result<MarketList>> getTrending({bool forceRefresh = false});

  /// Starred coins with current prices, in the order they were starred.
  Future<Result<MarketList>> getFavorites({bool forceRefresh = false});

  /// Specific coins, in the order of [ids] (coins CoinGecko no longer knows
  /// are left out).
  Future<Result<MarketList>> getCoins(
    List<String> ids, {
    bool forceRefresh = false,
  });

  /// Coins whose name or symbol match [query]. Without a connection it
  /// searches only the coins already saved, and says so in the freshness.
  Future<Result<MarketList>> search(String query, {CancelSignal? cancel});

  Future<Result<CoinQuote>> getCoin(String id, {bool forceRefresh = false});

  Future<Result<CoinChart>> getChart(
    String id,
    ChartRange range, {
    CancelSignal? cancel,
  });

  /// Ids of the starred coins, emitting again on every change, so the list,
  /// the detail and the dashboard card agree.
  Stream<Set<String>> watchFavoriteIds();

  /// Stars or unstars a coin. Returns whether it is starred now.
  Future<Result<bool>> toggleFavorite(String id);

  /// Deletes everything saved (on sign out, favorites are personal).
  @override
  Future<void> clear();
}
