import '../../../../core/async/cancel_signal.dart';
import '../../../../core/freshness/data_freshness.dart';
import '../../../../core/result/result.dart';
import '../../../../core/time/clock.dart';
import '../entities/market_data.dart';
import '../repositories/market_repository.dart';

/// Loads one page of a crypto tab. Trending and favorites have a single
/// page; asking for page 2 of them returns an empty last page.
final class LoadMarketTab {
  const LoadMarketTab(this._repository, this._clock);

  final MarketRepository _repository;
  final Clock _clock;

  Future<Result<MarketList>> call(
    MarketTab tab, {
    int page = 1,
    bool forceRefresh = false,
  }) async {
    if (page < 1) throw ArgumentError.value(page, 'page', 'starts at 1');
    if (tab != MarketTab.mostTraded && page > 1) {
      return Ok(
        MarketList(
          coins: const [],
          freshness: DataFreshness(syncedAt: _clock.nowUtc()),
        ),
      );
    }
    return switch (tab) {
      MarketTab.mostTraded => _repository.getMostTraded(
        page: page,
        forceRefresh: forceRefresh,
      ),
      MarketTab.trending => _repository.getTrending(forceRefresh: forceRefresh),
      MarketTab.favorites => _repository.getFavorites(
        forceRefresh: forceRefresh,
      ),
    };
  }
}

/// Searches coins. Fewer than [minLength] characters (after trimming) is
/// not a search yet: it answers with no results and spends no API call,
/// which matters on a plan limited to a few calls per minute.
final class SearchCoins {
  const SearchCoins(this._repository, this._clock);

  static const minLength = 2;

  final MarketRepository _repository;
  final Clock _clock;

  Future<Result<MarketList>> call(String query, {CancelSignal? cancel}) async {
    final cleaned = normalize(query);
    if (cleaned.length < minLength) {
      return Ok(
        MarketList(
          coins: const [],
          freshness: DataFreshness(syncedAt: _clock.nowUtc()),
        ),
      );
    }
    return _repository.search(cleaned, cancel: cancel);
  }

  /// Trims and collapses inner spaces, so `"  bit   coin "` and
  /// `"bit coin"` are the same search.
  static String normalize(String query) =>
      query.trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Coins for the dashboard card: the first starred ones, or the best known
/// coins when nothing is starred yet.
final class LoadHighlights {
  const LoadHighlights(this._repository);

  static const size = 3;
  static const defaults = ['bitcoin', 'ethereum', 'solana'];

  final MarketRepository _repository;

  Future<Result<MarketList>> call({bool forceRefresh = false}) async {
    final favorites = await _repository.getFavorites(
      forceRefresh: forceRefresh,
    );
    if (favorites case Ok(:final value) when value.coins.isNotEmpty) {
      return Ok(
        MarketList(
          coins: value.coins.take(size).toList(),
          freshness: value.freshness,
        ),
      );
    }
    return _repository.getCoins(defaults, forceRefresh: forceRefresh);
  }
}
