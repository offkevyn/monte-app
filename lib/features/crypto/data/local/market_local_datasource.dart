import 'package:drift/drift.dart';

import '../../../../core/money/money.dart';
import '../../../../core/text/search_text.dart';
import '../../domain/entities/coin.dart';
import '../../domain/entities/crypto_price.dart';
import '../../domain/entities/market_data.dart';
import 'market_database.dart';

/// A saved list page.
final class StoredPage {
  const StoredPage({
    required this.coins,
    required this.syncedAt,
    required this.hasMore,
    required this.skipped,
  });

  final List<Coin> coins;
  final DateTime syncedAt;
  final bool hasMore;
  final int skipped;
}

/// Saved coins and the oldest moment among them (the list is as fresh as
/// its oldest price).
final class StoredCoins {
  const StoredCoins({required this.coins, required this.savedAt});

  final List<Coin> coins;
  final DateTime savedAt;
}

final class StoredChart {
  const StoredChart({required this.points, required this.syncedAt});

  final List<PricePoint> points;
  final DateTime syncedAt;
}

/// Reads and writes `market.db`. Every screen of the crypto tab reads from
/// here; the API only refreshes it.
final class MarketLocalDataSource {
  MarketLocalDataSource(this._db);

  final MarketDatabase _db;

  // ---- lists ----

  Future<StoredPage?> readPage(String list, int page) async {
    final state =
        await (_db.select(_db.listPages)
              ..where((p) => p.listName.equals(list) & p.page.equals(page)))
            .getSingleOrNull();
    if (state == null) return null;

    final query =
        _db.select(_db.listEntries).join([
            innerJoin(
              _db.coins,
              _db.coins.id.equalsExp(_db.listEntries.coinId),
            ),
          ])
          ..where(
            _db.listEntries.listName.equals(list) &
                _db.listEntries.page.equals(page),
          )
          ..orderBy([OrderingTerm.asc(_db.listEntries.position)]);
    final rows = await query.get();
    return StoredPage(
      coins: [for (final row in rows) _toCoin(row.readTable(_db.coins))],
      syncedAt: _instant(state.syncedAtMicros),
      hasMore: state.hasMore,
      skipped: state.skippedRecords,
    );
  }

  /// Saves one page in a single transaction. Page 1 starts the list over
  /// (the ranking moves, so older pages would repeat or skip coins).
  Future<StoredPage> savePage(
    String list,
    int page,
    List<Coin> coins, {
    required DateTime syncedAt,
    required bool hasMore,
    required int skipped,
  }) => _db.transaction(() async {
    await (_db.delete(_db.listEntries)..where(
          (e) => e.listName.equals(list) & e.page.isBiggerOrEqualValue(page),
        ))
        .go();
    await (_db.delete(_db.listPages)..where(
          (p) => p.listName.equals(list) & p.page.isBiggerOrEqualValue(page),
        ))
        .go();
    await _upsertCoins(coins, syncedAt);
    await _db.batch((batch) {
      batch.insertAll(_db.listEntries, [
        for (final (index, coin) in coins.indexed)
          ListEntriesCompanion.insert(
            listName: list,
            page: page,
            position: index,
            coinId: coin.id,
          ),
      ]);
    });
    await _db
        .into(_db.listPages)
        .insert(
          ListPagesCompanion.insert(
            listName: list,
            page: page,
            syncedAtMicros: _micros(syncedAt),
            hasMore: hasMore,
            skippedRecords: Value(skipped),
          ),
        );
    return StoredPage(
      coins: coins,
      syncedAt: syncedAt.toUtc(),
      hasMore: hasMore,
      skipped: skipped,
    );
  });

  // ---- coins ----

  Future<void> saveCoins(List<Coin> coins, DateTime savedAt) =>
      _db.transaction(() => _upsertCoins(coins, savedAt));

  /// Saved coins among [ids], in the order of [ids]. `null` when none of
  /// them was ever saved.
  Future<StoredCoins?> coinsByIds(List<String> ids) async {
    if (ids.isEmpty) return null;
    final rows = await (_db.select(
      _db.coins,
    )..where((c) => c.id.isIn(ids))).get();
    if (rows.isEmpty) return null;
    final byId = {for (final row in rows) row.id: row};
    final ordered = [for (final id in ids) ?byId[id]];
    final oldest = ordered
        .map((row) => row.savedAtMicros)
        .reduce((a, b) => a < b ? a : b);
    // Some asked coin was never saved: treat the copy as old so the
    // repository tries the API.
    final complete = ordered.length == ids.length;
    return StoredCoins(
      coins: ordered.map(_toCoin).toList(),
      savedAt: complete ? _instant(oldest) : DateTime.utc(1970),
    );
  }

  /// Offline search: every word must appear in the name or symbol.
  Future<List<Coin>> search(String query, {int limit = 20}) async {
    final words = SearchText.normalize(SearchText.cleanQuery(query))
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return const [];
    final select = _db.select(_db.coins)
      ..where((c) {
        Expression<bool> all = const Constant(true);
        for (final word in words) {
          all =
              all &
              c.searchText.like('%${_escapeLike(word)}%', escapeChar: r'\');
        }
        return all;
      })
      ..orderBy([
        (c) =>
            OrderingTerm(expression: c.marketCapRank, nulls: NullsOrder.last),
      ])
      ..limit(limit);
    return (await select.get()).map(_toCoin).toList();
  }

  // ---- favorites ----

  Stream<Set<String>> watchFavoriteIds() => _db
      .select(_db.favorites)
      .watch()
      .map((rows) => {for (final row in rows) row.coinId});

  /// Starred ids, oldest star first.
  Future<List<String>> favoriteIds() async {
    final rows = await (_db.select(
      _db.favorites,
    )..orderBy([(f) => OrderingTerm.asc(f.addedAtMicros)])).get();
    return [for (final row in rows) row.coinId];
  }

  /// Returns whether the coin is starred after the change.
  Future<bool> toggleFavorite(String id, DateTime now) => _db.transaction(
    () async {
      final removed = await (_db.delete(
        _db.favorites,
      )..where((f) => f.coinId.equals(id))).go();
      if (removed > 0) return false;
      await _db
          .into(_db.favorites)
          .insert(
            FavoritesCompanion.insert(coinId: id, addedAtMicros: _micros(now)),
          );
      return true;
    },
  );

  // ---- charts ----

  Future<StoredChart?> readChart(String id, ChartRange range) async {
    final state =
        await (_db.select(_db.chartStates)
              ..where((s) => s.coinId.equals(id) & s.range.equals(range.name)))
            .getSingleOrNull();
    if (state == null) return null;
    final rows =
        await (_db.select(_db.chartPoints)
              ..where((p) => p.coinId.equals(id) & p.range.equals(range.name))
              ..orderBy([(p) => OrderingTerm.asc(p.atMicros)]))
            .get();
    return StoredChart(
      points: [
        for (final row in rows)
          PricePoint(
            at: _instant(row.atMicros),
            price: CryptoPrice.units(row.priceUnits),
          ),
      ],
      syncedAt: _instant(state.syncedAtMicros),
    );
  }

  Future<StoredChart> saveChart(
    String id,
    ChartRange range,
    List<PricePoint> points,
    DateTime syncedAt,
  ) => _db.transaction(() async {
    await (_db.delete(
      _db.chartPoints,
    )..where((p) => p.coinId.equals(id) & p.range.equals(range.name))).go();
    await _db.batch((batch) {
      batch.insertAll(_db.chartPoints, [
        for (final point in points)
          ChartPointsCompanion.insert(
            coinId: id,
            range: range.name,
            atMicros: _micros(point.at),
            priceUnits: point.price.units,
          ),
      ], mode: InsertMode.insertOrReplace);
    });
    await _db
        .into(_db.chartStates)
        .insertOnConflictUpdate(
          ChartStatesCompanion.insert(
            coinId: id,
            range: range.name,
            syncedAtMicros: _micros(syncedAt),
          ),
        );
    return StoredChart(points: points, syncedAt: syncedAt.toUtc());
  });

  /// Deletes everything (sign out).
  Future<void> clear() => _db.transaction(() async {
    for (final table in _db.allTables) {
      await _db.delete(table).go();
    }
  });

  // ---- helpers ----

  Future<void> _upsertCoins(List<Coin> coins, DateTime savedAt) =>
      _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.coins, [
          for (final coin in coins) _toRow(coin, savedAt),
        ]);
      });

  static CoinsCompanion _toRow(Coin coin, DateTime savedAt) =>
      CoinsCompanion.insert(
        id: coin.id,
        symbol: coin.symbol,
        name: coin.name,
        imageUrl: Value(coin.imageUrl),
        marketCapRank: Value(coin.marketCapRank),
        priceUnits: coin.price.units,
        change24hHundredths: Value(coin.change24h?.hundredths),
        priceChange24hUnits: Value(coin.priceChange24h?.units),
        high24hUnits: Value(coin.high24h?.units),
        low24hUnits: Value(coin.low24h?.units),
        marketCapCents: Value(coin.marketCap?.cents),
        totalVolumeCents: Value(coin.totalVolume?.cents),
        updatedAtMicros: Value(coin.updatedAt?.microsecondsSinceEpoch),
        savedAtMicros: _micros(savedAt),
        searchText: SearchText.normalize('${coin.name} ${coin.symbol}'),
      );

  static Coin _toCoin(CoinRow row) => Coin(
    id: row.id,
    symbol: row.symbol,
    name: row.name,
    imageUrl: row.imageUrl,
    marketCapRank: row.marketCapRank,
    price: CryptoPrice.units(row.priceUnits),
    change24h: row.change24hHundredths == null
        ? null
        : PercentChange.hundredths(row.change24hHundredths!),
    priceChange24h: _price(row.priceChange24hUnits),
    high24h: _price(row.high24hUnits),
    low24h: _price(row.low24hUnits),
    marketCap: _money(row.marketCapCents),
    totalVolume: _money(row.totalVolumeCents),
    updatedAt: row.updatedAtMicros == null
        ? null
        : _instant(row.updatedAtMicros!),
  );

  static CryptoPrice? _price(int? units) =>
      units == null ? null : CryptoPrice.units(units);

  static Money? _money(int? cents) => cents == null ? null : Money.cents(cents);

  static int _micros(DateTime instant) =>
      instant.toUtc().microsecondsSinceEpoch;

  static DateTime _instant(int micros) =>
      DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);

  static String _escapeLike(String word) => word
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
