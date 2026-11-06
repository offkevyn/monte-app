import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/features/crypto/data/coingecko/coingecko_mapper.dart';
import 'package:monte/features/crypto/domain/entities/crypto_price.dart';

import '../../../helpers/coins.dart';

void main() {
  group('coin', () {
    test('reads a /coins/markets item into exact values', () {
      final coin = CoinGeckoMapper.coin({
        ...marketJson('bitcoin', symbol: 'btc', name: 'Bitcoin'),
        'current_price': 438899.39,
        'price_change_24h': -0.000192282293641099,
        'price_change_percentage_24h': 2.41378,
        'market_cap': 8700000000000.4,
      });

      expect(coin.id, 'bitcoin');
      expect(coin.symbol, 'BTC');
      expect(coin.price, CryptoPrice.parse('438899.39'));
      expect(coin.priceChange24h, CryptoPrice.parse('-0.00019228'));
      expect(coin.change24h, const PercentChange.hundredths(241));
      expect(coin.marketCap, const Money.cents(870000000000040));
      expect(coin.marketCapRank, 1);
      expect(coin.updatedAt, DateTime.utc(2026, 11, 6, 17, 31));
    });

    test('accepts missing optional numbers', () {
      final coin = CoinGeckoMapper.coin({
        ...marketJson('tiny'),
        'high_24h': null,
        'low_24h': null,
        'market_cap_rank': null,
        'price_change_percentage_24h': null,
        'last_updated': null,
        'image': null,
      });
      expect(coin.high24h, isNull);
      expect(coin.marketCapRank, isNull);
      expect(coin.change24h, isNull);
      expect(coin.updatedAt, isNull);
      expect(coin.imageUrl, isNull);
    });

    test('rejects items that cannot be a coin', () {
      expect(
        () => CoinGeckoMapper.coin({...marketJson('x'), 'current_price': null}),
        throwsFormatException,
      );
      expect(
        () => CoinGeckoMapper.coin({...marketJson('x'), 'current_price': '1'}),
        throwsFormatException,
      );
      expect(
        () => CoinGeckoMapper.coin({...marketJson('x'), 'id': ''}),
        throwsFormatException,
      );
      expect(
        () => CoinGeckoMapper.coin({...marketJson('x'), 'current_price': -1}),
        throwsArgumentError,
      );
      expect(
        () => CoinGeckoMapper.coin({
          ...marketJson('x'),
          'last_updated': '2026-11-06T17:31:00',
        }),
        throwsFormatException,
      );
      expect(() => CoinGeckoMapper.coin('nope'), throwsFormatException);
    });
  });

  group('coins', () {
    test('skips and counts broken items, and drops repeated ids', () {
      final mapped = CoinGeckoMapper.coins([
        marketJson('bitcoin'),
        {...marketJson('broken'), 'current_price': null},
        marketJson('ethereum'),
        marketJson('bitcoin'),
        'not an object',
      ]);
      expect(mapped.coins.map((c) => c.id), ['bitcoin', 'ethereum']);
      expect(mapped.skipped, 2);
    });

    test('fails when the body is not a list', () {
      expect(() => CoinGeckoMapper.coins({'a': 1}), throwsFormatException);
    });
  });

  test('searchIds keeps the order, removes repeats and cuts at the limit', () {
    final ids = CoinGeckoMapper.searchIds({
      'coins': [
        {'id': 'solana'},
        {'id': 'solv'},
        {'id': 'solana'},
        {'name': 'no id'},
        {'id': 'sol-wormhole'},
      ],
      'exchanges': <Object?>[],
    }, limit: 2);
    expect(ids, ['solana', 'solv']);
  });

  test('trendingIds reads the nested item', () {
    final ids = CoinGeckoMapper.trendingIds({
      'coins': [
        {
          'item': {'id': 'pepe', 'score': 0},
        },
        {
          'item': {'id': 'sui', 'score': 1},
        },
      ],
    }, limit: 15);
    expect(ids, ['pepe', 'sui']);
  });

  test('chart reads pairs, drops bad ones and sorts by time', () {
    final points = CoinGeckoMapper.chart({
      'prices': [
        [1793996370000, 417049.31],
        [1793910300000, 417614.2252472732],
        ['x', 1],
        [1793910400000],
        [1793910500000, -5],
        'bad',
      ],
      'market_caps': <Object?>[],
    });
    expect(points, hasLength(2));
    expect(points.first.at.isBefore(points.last.at), isTrue);
    expect(points.first.price, CryptoPrice.parse('417614.22524727'));
    expect(points.first.at.isUtc, isTrue);
  });
}
