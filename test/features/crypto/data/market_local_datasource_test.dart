import 'package:flutter_test/flutter_test.dart';
import 'package:monte/features/crypto/data/local/market_local_datasource.dart';
import 'package:monte/features/crypto/domain/entities/crypto_price.dart';
import 'package:monte/features/crypto/domain/entities/market_data.dart';

import '../../../helpers/coins.dart';
import '../../../helpers/market_database.dart';

void main() {
  late MarketLocalDataSource local;
  final start = DateTime.utc(2026, 11);

  setUp(() => local = MarketLocalDataSource(testMarketDatabase()));

  List<PricePoint> points() => [
    PricePoint(at: DateTime.utc(2026, 11), price: CryptoPrice.parse('1')),
  ];

  group('prune', () {
    test('keeps charts of favorites and of the 20 latest coins', () async {
      await local.toggleFavorite('coin0', start);
      for (var i = 0; i < 25; i++) {
        await local.saveChart(
          'coin$i',
          ChartRange.day,
          points(),
          start.add(Duration(minutes: i)),
        );
      }

      await local.prune(now: start.add(const Duration(hours: 1)));

      // coin0 is starred; coin5..coin24 are the 20 most recent.
      expect(await local.readChart('coin0', ChartRange.day), isNotNull);
      for (var i = 1; i < 5; i++) {
        expect(
          await local.readChart('coin$i', ChartRange.day),
          isNull,
          reason: 'coin$i',
        );
      }
      for (var i = 5; i < 25; i++) {
        expect(await local.readChart('coin$i', ChartRange.day), isNotNull);
      }
    });

    test('forgets old coins nothing refers to', () async {
      await local.saveCoins([coin('old'), coin('starred')], start);
      await local.toggleFavorite('starred', start);
      await local.savePage(
        'mostTraded',
        1,
        [coin('listed')],
        syncedAt: start,
        hasMore: false,
        skipped: 0,
      );
      await local.saveCoins([
        coin('recent'),
      ], start.add(const Duration(days: 7)));

      await local.prune(now: start.add(const Duration(days: 8)));

      final kept = await local.coinsByIds([
        'old',
        'starred',
        'listed',
        'recent',
      ]);
      expect(kept!.coins.map((c) => c.id), ['starred', 'listed', 'recent']);
    });
  });

  test(
    'offline search matches every word, ignoring accents and case',
    () async {
      await local.saveCoins([
        coin('bitcoin', name: 'Bitcoin', symbol: 'btc', rank: 1),
        coin('bitcoin-cash', name: 'Bitcoin Cash', symbol: 'bch', rank: 20),
        coin('pepe', name: 'Pepe', symbol: 'pepe'),
      ], start);

      expect((await local.search('BÍTCOIN')).map((c) => c.id), [
        'bitcoin',
        'bitcoin-cash',
      ]);
      expect((await local.search('bit cash')).map((c) => c.id), [
        'bitcoin-cash',
      ]);
      expect(await local.search('%'), isEmpty);
      expect(await local.search('  '), isEmpty);
    },
  );
}
