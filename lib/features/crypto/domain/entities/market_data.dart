import 'package:meta/meta.dart';

import '../../../../core/freshness/data_freshness.dart';
import 'coin.dart';
import 'crypto_price.dart';

/// The lists of the crypto tab.
enum MarketTab {
  /// Biggest 24h trading volume, paginated.
  mostTraded,

  /// What people are searching for on CoinGecko right now.
  trending,

  /// Coins the user starred, saved on the device.
  favorites,
}

/// A list of coins and how fresh it is.
@immutable
final class MarketList {
  MarketList({
    required List<Coin> coins,
    required this.freshness,
    this.hasMore = false,
  }) : coins = List.unmodifiable(coins);

  final List<Coin> coins;

  /// Whether another page can be requested.
  final bool hasMore;
  final DataFreshness freshness;
}

/// One coin with the freshness of its numbers, for the detail screen.
@immutable
final class CoinQuote {
  const CoinQuote({required this.coin, required this.freshness});

  final Coin coin;
  final DataFreshness freshness;
}

/// Periods of the price chart.
enum ChartRange {
  day(1),
  week(7),
  month(30),
  year(365);

  const ChartRange(this.days);

  /// Days of history, as CoinGecko's `days` parameter.
  final int days;
}

/// One point of the chart.
@immutable
final class PricePoint {
  PricePoint({required DateTime at, required this.price}) : at = at.toUtc();

  /// In UTC.
  final DateTime at;
  final CryptoPrice price;

  @override
  bool operator ==(Object other) =>
      other is PricePoint && other.at == at && other.price == price;

  @override
  int get hashCode => Object.hash(at, price);

  @override
  String toString() => 'PricePoint($at, $price)';
}

/// Price history of a coin for one period, oldest point first.
@immutable
final class CoinChart {
  CoinChart({
    required this.coinId,
    required this.range,
    required List<PricePoint> points,
    required this.freshness,
  }) : points = List.unmodifiable(points);

  final String coinId;
  final ChartRange range;
  final List<PricePoint> points;
  final DataFreshness freshness;

  /// Lowest and highest price of the period, or `null` with no points.
  (CryptoPrice, CryptoPrice)? get bounds {
    if (points.isEmpty) return null;
    var low = points.first.price;
    var high = low;
    for (final point in points) {
      if (point.price < low) low = point.price;
      if (point.price > high) high = point.price;
    }
    return (low, high);
  }

  /// Change from the first to the last point of the period.
  CryptoPrice? get change =>
      points.length < 2 ? null : points.last.price - points.first.price;
}
