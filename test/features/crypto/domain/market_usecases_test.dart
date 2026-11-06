import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:monte/core/async/cancel_signal.dart';
import 'package:monte/core/freshness/data_freshness.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/features/crypto/domain/entities/market_data.dart';
import 'package:monte/features/crypto/domain/repositories/market_repository.dart';
import 'package:monte/features/crypto/domain/usecases/market_usecases.dart';

import '../../../helpers/coins.dart';

class _MockRepository extends Mock implements MarketRepository {}

void main() {
  late _MockRepository repository;
  final clock = FixedClock(DateTime.utc(2026, 11, 6, 17));
  final list = MarketList(
    coins: [coin('bitcoin')],
    freshness: DataFreshness(syncedAt: DateTime.utc(2026, 11, 6, 17)),
    hasMore: true,
  );

  setUp(() => repository = _MockRepository());

  group('LoadMarketTab', () {
    test('asks the repository for the right list and page', () async {
      when(() => repository.getMostTraded(page: 2, forceRefresh: true))
          .thenAnswer((_) async => Ok(list));
      when(() => repository.getTrending()).thenAnswer((_) async => Ok(list));
      when(() => repository.getFavorites()).thenAnswer((_) async => Ok(list));
      final load = LoadMarketTab(repository, clock);

      expect(
        await load(MarketTab.mostTraded, page: 2, forceRefresh: true),
        Ok(list),
      );
      expect(await load(MarketTab.trending), Ok(list));
      expect(await load(MarketTab.favorites), Ok(list));
    });

    test('single page tabs end after page 1 without calling the API', () async {
      final load = LoadMarketTab(repository, clock);
      final result = await load(MarketTab.trending, page: 2);
      final value = result.valueOrNull!;
      expect(value.coins, isEmpty);
      expect(value.hasMore, isFalse);
      verifyZeroInteractions(repository);
    });

    test('pages start at 1', () {
      expect(
        () => LoadMarketTab(repository, clock)(MarketTab.mostTraded, page: 0),
        throwsArgumentError,
      );
    });
  });

  group('SearchCoins', () {
    test('short queries spend no API call', () async {
      final search = SearchCoins(repository, clock);
      for (final query in ['', ' ', 'b', ' b ']) {
        final result = await search(query);
        expect(result.valueOrNull!.coins, isEmpty, reason: query);
      }
      verifyZeroInteractions(repository);
    });

    test('normalizes spaces before searching', () async {
      final cancel = CancelSignal();
      when(() => repository.search('bit coin', cancel: cancel))
          .thenAnswer((_) async => Ok(list));

      final result = await SearchCoins(repository, clock)(
        '  bit   coin ',
        cancel: cancel,
      );

      expect(result, Ok(list));
    });
  });

  test('CancelSignal completes once', () async {
    final signal = CancelSignal();
    expect(signal.isCancelled, isFalse);
    signal
      ..cancel()
      ..cancel();
    await signal.whenCancelled;
    expect(signal.isCancelled, isTrue);
  });
}
