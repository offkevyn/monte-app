import 'package:monte/core/money/money.dart';
import 'package:monte/features/crypto/domain/entities/coin.dart';
import 'package:monte/features/crypto/domain/entities/crypto_price.dart';

/// A coin with sensible defaults; only what the test cares about changes.
Coin coin(
  String id, {
  String? symbol,
  String? name,
  String price = '100',
  int? rank,
  int? changeHundredths = 150,
}) => Coin(
  id: id,
  symbol: symbol ?? id.substring(0, id.length < 3 ? id.length : 3),
  name: name ?? '${id[0].toUpperCase()}${id.substring(1)}',
  price: CryptoPrice.parse(price),
  marketCapRank: rank,
  change24h: changeHundredths == null
      ? null
      : PercentChange.hundredths(changeHundredths),
  priceChange24h: CryptoPrice.parse('1.5'),
  high24h: CryptoPrice.parse(price),
  low24h: CryptoPrice.parse(price),
  marketCap: const Money.cents(870000000000000),
  totalVolume: const Money.cents(12000000000),
  updatedAt: DateTime.utc(2026, 11, 6, 17, 31),
);

/// A CoinGecko `/coins/markets` item, as the API sends it.
Map<String, Object?> marketJson(
  String id, {
  String? symbol,
  String? name,
  num price = 100,
  int? rank = 1,
}) => {
  'id': id,
  'symbol': symbol ?? id.substring(0, id.length < 3 ? id.length : 3),
  'name': name ?? '${id[0].toUpperCase()}${id.substring(1)}',
  'image': 'https://coin-images.coingecko.com/coins/images/1/large/$id.png',
  'current_price': price,
  'market_cap': 8700000000000,
  'market_cap_rank': rank,
  'total_volume': 120000000,
  'high_24h': price,
  'low_24h': price,
  'price_change_24h': 1.5,
  'price_change_percentage_24h': 1.5,
  'last_updated': '2026-11-06T17:31:00.000Z',
};
