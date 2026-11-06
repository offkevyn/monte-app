import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/freshness/data_freshness.dart';
import 'package:monte/features/crypto/domain/entities/coin.dart';
import 'package:monte/features/crypto/domain/entities/crypto_price.dart';
import 'package:monte/features/crypto/domain/entities/market_data.dart';

import '../../../helpers/coins.dart';

void main() {
  group('CryptoPrice', () {
    test('keeps prices smaller than a cent', () {
      final shib = CryptoPrice.fromJsonNumber(0.0000712);
      expect(shib.units, 7120);
      expect(shib.isZero, isFalse);
    });

    test('does exact arithmetic and comparison', () {
      final a = CryptoPrice.parse('0.1');
      final b = CryptoPrice.parse('0.2');
      expect(a + b, CryptoPrice.parse('0.3'));
      expect(a - b, CryptoPrice.parse('-0.1'));
      expect((a - b).isNegative, isTrue);
      expect((a - b).abs(), a);
      expect(a < b, isTrue);
      expect(b > a, isTrue);
      expect(a.compareTo(b), lessThan(0));
    });

    test('converts to double only for the chart', () {
      expect(CryptoPrice.parse('1.5').toChartValue(), 1.5);
    });
  });

  group('PercentChange', () {
    test('stores hundredths of a percent', () {
      final change = PercentChange.fromJsonNumber(2.4137);
      expect(change.hundredths, 241);
      expect(change.isPositive, isTrue);
      expect(PercentChange.fromJsonNumber(-0.87).isNegative, isTrue);
      expect(
        PercentChange.fromJsonNumber(0),
        const PercentChange.hundredths(0),
      );
    });
  });

  group('Coin', () {
    test('normalizes the symbol and keeps instants in UTC', () {
      final coin = Coin(
        id: 'bitcoin',
        symbol: ' btc ',
        name: 'Bitcoin',
        price: CryptoPrice.parse('1'),
        updatedAt: DateTime.parse('2026-11-06T10:00:00-03:00'),
      );
      expect(coin.symbol, 'BTC');
      expect(coin.updatedAt, DateTime.utc(2026, 11, 6, 13));
    });

    test('rejects values that can never be valid', () {
      Coin build({
        String id = 'x',
        String symbol = 'x',
        String name = 'x',
        String price = '1',
        int? rank,
      }) => Coin(
        id: id,
        symbol: symbol,
        name: name,
        price: CryptoPrice.parse(price),
        marketCapRank: rank,
      );

      expect(() => build(id: ' '), throwsArgumentError);
      expect(() => build(symbol: ''), throwsArgumentError);
      expect(() => build(name: ''), throwsArgumentError);
      expect(() => build(price: '-1'), throwsArgumentError);
      expect(() => build(rank: 0), throwsArgumentError);
      expect(build(rank: 1).marketCapRank, 1);
    });

    test('compares by value', () {
      expect(coin('bitcoin'), coin('bitcoin'));
      expect(coin('bitcoin').hashCode, coin('bitcoin').hashCode);
      expect(coin('bitcoin'), isNot(coin('bitcoin', price: '2')));
    });
  });

  group('CoinChart', () {
    PricePoint point(int hour, String price) => PricePoint(
      at: DateTime.utc(2026, 11, 6, hour),
      price: CryptoPrice.parse(price),
    );

    CoinChart chart(List<PricePoint> points) => CoinChart(
      coinId: 'bitcoin',
      range: ChartRange.day,
      points: points,
      freshness: DataFreshness(syncedAt: DateTime.utc(2026, 11, 6)),
    );

    test('finds the bounds and the change of the period', () {
      final value = chart([point(1, '10'), point(2, '7.5'), point(3, '12')]);
      expect(value.bounds, (CryptoPrice.parse('7.5'), CryptoPrice.parse('12')));
      expect(value.change, CryptoPrice.parse('2'));
    });

    test('has no bounds or change without enough points', () {
      expect(chart([]).bounds, isNull);
      expect(chart([point(1, '10')]).change, isNull);
    });

    test('ranges map to the days CoinGecko expects', () {
      expect(ChartRange.values.map((r) => r.days), [1, 7, 30, 365]);
    });
  });
}
