import 'package:meta/meta.dart';

import '../../../../core/money/money.dart';
import 'crypto_price.dart';

/// A coin and its market numbers in reais, as CoinGecko last reported them.
@immutable
final class Coin {
  /// Throws an [ArgumentError] for values that can never be valid; mappers
  /// turn it into an `InvalidDataFailure`.
  Coin({
    required this.id,
    required String symbol,
    required this.name,
    required this.price,
    this.imageUrl,
    this.marketCapRank,
    this.change24h,
    this.priceChange24h,
    this.high24h,
    this.low24h,
    this.marketCap,
    this.totalVolume,
    DateTime? updatedAt,
  }) : symbol = symbol.trim().toUpperCase(),
       updatedAt = updatedAt?.toUtc() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (this.symbol.isEmpty) {
      throw ArgumentError.value(symbol, 'symbol', 'must not be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (price.isNegative) {
      throw ArgumentError.value(price, 'price', 'must not be negative');
    }
    final rank = marketCapRank;
    if (rank != null && rank < 1) {
      throw ArgumentError.value(rank, 'marketCapRank', 'must be positive');
    }
  }

  /// CoinGecko id, e.g. `bitcoin`. Used in every request about the coin.
  final String id;

  /// Ticker in upper case, e.g. `BTC`.
  final String symbol;
  final String name;
  final String? imageUrl;

  /// Position by market value (1 = biggest), when CoinGecko ranks it.
  final int? marketCapRank;
  final CryptoPrice price;

  /// Variation in the last 24 hours.
  final PercentChange? change24h;
  final CryptoPrice? priceChange24h;
  final CryptoPrice? high24h;
  final CryptoPrice? low24h;

  /// Totals in reais are huge (trillions) but have no use for fractions of a
  /// cent, so they fit [Money].
  final Money? marketCap;
  final Money? totalVolume;

  /// When CoinGecko last updated these numbers, in UTC.
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) =>
      other is Coin &&
      other.id == id &&
      other.symbol == symbol &&
      other.name == name &&
      other.imageUrl == imageUrl &&
      other.marketCapRank == marketCapRank &&
      other.price == price &&
      other.change24h == change24h &&
      other.priceChange24h == priceChange24h &&
      other.high24h == high24h &&
      other.low24h == low24h &&
      other.marketCap == marketCap &&
      other.totalVolume == totalVolume &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    symbol,
    name,
    imageUrl,
    marketCapRank,
    price,
    change24h,
    priceChange24h,
    high24h,
    low24h,
    marketCap,
    totalVolume,
    updatedAt,
  );

  @override
  String toString() => 'Coin($id, $symbol, $price)';
}
