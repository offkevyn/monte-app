import '../../../../core/money/money.dart';
import '../../../../core/money/scaled_decimal.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/entities/coin.dart';
import '../../domain/entities/crypto_price.dart';
import '../../domain/entities/market_data.dart';

/// Coins read from a list response, and how many items were left out
/// because they could not be read.
typedef MappedCoins = ({List<Coin> coins, int skipped});

/// Turns CoinGecko's JSON into domain entities. It is the only piece of the
/// app that knows the API's field names.
///
/// Prices arrive as JSON numbers and go straight to exact scaled integers
/// ([CryptoPrice], [Money]), so no `double` is kept anywhere.
abstract final class CoinGeckoMapper {
  /// One item of `/coins/markets`. Throws [FormatException] or
  /// [ArgumentError] when it cannot be a valid coin.
  static Coin coin(Object? json) {
    final reader = JsonReader.of(json, 'coin');
    final price = reader.optionalNumber('current_price');
    if (price == null) {
      throw const FormatException('Coin without a current price');
    }
    return Coin(
      id: reader.string('id'),
      symbol: reader.string('symbol'),
      name: reader.string('name'),
      imageUrl: reader.optionalString('image'),
      marketCapRank: reader.optionalInteger('market_cap_rank'),
      price: CryptoPrice.fromJsonNumber(price),
      change24h: _map(
        reader.optionalNumber('price_change_percentage_24h'),
        PercentChange.fromJsonNumber,
      ),
      priceChange24h: _price(reader.optionalNumber('price_change_24h')),
      high24h: _price(reader.optionalNumber('high_24h')),
      low24h: _price(reader.optionalNumber('low_24h')),
      marketCap: _money(reader.optionalNumber('market_cap')),
      totalVolume: _money(reader.optionalNumber('total_volume')),
      updatedAt: _instant(reader.optionalString('last_updated')),
    );
  }

  /// A whole `/coins/markets` response. A broken item is skipped and
  /// counted instead of failing the list: one odd coin should not hide
  /// the other forty-nine.
  static MappedCoins coins(Object? body) {
    if (body is! List) {
      throw const FormatException('Expected a list of coins');
    }
    final coins = <Coin>[];
    final seen = <String>{};
    var skipped = 0;
    for (final item in body) {
      try {
        final parsed = coin(item);
        // The API may repeat a coin when the ranking moves between pages.
        if (seen.add(parsed.id)) coins.add(parsed);
      } on FormatException {
        skipped++;
      } on ArgumentError {
        skipped++;
      }
    }
    return (coins: coins, skipped: skipped);
  }

  /// Ids from `/search`, best match first.
  static List<String> searchIds(Object? body, {required int limit}) {
    final coins = JsonReader.of(body).list('coins');
    return _ids(coins.map((item) => JsonReader.of(item, 'coins[]')), limit);
  }

  /// Ids from `/search/trending`, in CoinGecko's order.
  static List<String> trendingIds(Object? body, {required int limit}) {
    final coins = JsonReader.of(body).list('coins');
    return _ids(
      coins.map(
        (entry) => JsonReader.of(JsonReader.of(entry).json['item'], 'item'),
      ),
      limit,
    );
  }

  /// `prices` of `/coins/{id}/market_chart`: pairs of
  /// `[milliseconds since epoch, price]`, returned oldest first. A pair
  /// that cannot be read is dropped; one bad point should not hide the
  /// chart.
  static List<PricePoint> chart(Object? body) {
    final prices = JsonReader.of(body).list('prices');
    final points = <PricePoint>[];
    for (final pair in prices) {
      if (pair is! List || pair.length < 2) continue;
      final [millis, price, ...] = pair;
      if (millis is! num || price is! num || price < 0) continue;
      try {
        points.add(
          PricePoint(
            at: DateTime.fromMillisecondsSinceEpoch(
              millis.toInt(),
              isUtc: true,
            ),
            price: CryptoPrice.fromJsonNumber(price),
          ),
        );
      } on FormatException {
        continue;
      }
    }
    return points..sort((a, b) => a.at.compareTo(b.at));
  }

  static List<String> _ids(Iterable<JsonReader> items, int limit) {
    final ids = <String>[];
    for (final item in items) {
      final id = item.optionalString('id');
      if (id != null && !ids.contains(id)) ids.add(id);
      if (ids.length == limit) break;
    }
    return ids;
  }

  static T? _map<T>(num? value, T Function(num) convert) =>
      value == null ? null : convert(value);

  static CryptoPrice? _price(num? value) =>
      _map(value, CryptoPrice.fromJsonNumber);

  /// Totals are rounded to whole cents.
  static Money? _money(num? value) =>
      _map(value, (v) => Money.cents(ScaledDecimal.fromJsonNumber(v, 2)));

  static DateTime? _instant(String? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    // A date without an offset is ambiguous, so it is rejected.
    if (parsed == null || !parsed.isUtc) {
      throw FormatException('Field "last_updated" is not a UTC date', raw);
    }
    return parsed.toUtc();
  }
}
