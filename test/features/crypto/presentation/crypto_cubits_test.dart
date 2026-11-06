import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/freshness/data_freshness.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/features/crypto/domain/entities/crypto_price.dart';
import 'package:monte/features/crypto/domain/entities/market_data.dart';
import 'package:monte/features/crypto/domain/usecases/market_usecases.dart';
import 'package:monte/features/crypto/presentation/detail/coin_detail_cubit.dart';
import 'package:monte/features/crypto/presentation/highlights/crypto_highlights_cubit.dart';
import 'package:monte/features/crypto/presentation/list/crypto_list_cubit.dart';

import '../../../helpers/coins.dart';
import '../../../helpers/memory_market_repository.dart';

/// Lets timers (debounce) and async gaps run in real time.
Future<void> settle([int millis = 40]) =>
    Future<void>.delayed(Duration(milliseconds: millis));

void main() {
  final clock = FixedClock(DateTime.utc(2026, 11, 6, 17));
  late MemoryMarketRepository repository;

  setUp(() {
    repository = MemoryMarketRepository([
      coin('bitcoin', name: 'Bitcoin'),
      coin('ethereum', name: 'Ethereum'),
      coin('solana', name: 'Solana'),
      for (var i = 0; i < 60; i++) coin('coin$i'),
    ]);
  });

  group('CryptoListCubit', () {
    CryptoListCubit build() => CryptoListCubit(
      LoadMarketTab(repository, clock),
      SearchCoins(repository, clock),
      repository,
      debounce: const Duration(milliseconds: 10),
    );

    test('loads the first page of the most traded', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.status, CryptoListStatus.ready);
      expect(cubit.state.coins, hasLength(50));
      expect(cubit.state.hasMore, isTrue);
      await cubit.close();
    });

    test('loads more pages without repeating a coin', () async {
      final cubit = build();
      await cubit.load();
      // The ranking moved: page 2 now starts with a coin of page 1.
      repository.market = [
        ...repository.market.take(50),
        repository.market[10],
        ...repository.market.skip(50),
      ];
      await cubit.loadMore();
      final ids = cubit.state.coins.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, hasLength(63));
      expect(cubit.state.hasMore, isFalse);

      await cubit.loadMore();
      expect(repository.calls.where((c) => c.startsWith('mostTraded')), [
        'mostTraded/1',
        'mostTraded/2',
      ]);
      await cubit.close();
    });

    test('a failed page keeps the list and offers a retry', () async {
      final cubit = build();
      await cubit.load();
      repository.failPagesWith = const NoConnectionFailure();
      await cubit.loadMore();
      expect(cubit.state.coins, hasLength(50));
      expect(cubit.state.pageFailure, const NoConnectionFailure());

      repository.failPagesWith = null;
      await cubit.loadMore();
      expect(cubit.state.pageFailure, isNull);
      expect(cubit.state.coins, hasLength(63));
      await cubit.close();
    });

    test('switching tabs loads that list', () async {
      repository.trendingIds = ['solana', 'bitcoin'];
      final cubit = build();
      await cubit.load();
      await cubit.selectTab(MarketTab.trending);
      expect(cubit.state.tab, MarketTab.trending);
      expect(cubit.state.coins.map((c) => c.id), ['solana', 'bitcoin']);
      expect(cubit.state.hasMore, isFalse);

      await cubit.selectTab(MarketTab.trending);
      expect(repository.calls.where((c) => c == 'trending'), hasLength(1));
      await cubit.close();
    });

    test('typing fast spends a single search', () async {
      repository.searches['bitcoin'] = ['bitcoin'];
      final cubit = build();
      await cubit.load();
      for (final text in ['b', 'bi', 'bit', 'bitc', 'bitco', 'bitcoin']) {
        cubit.queryChanged(text);
      }
      await settle();
      expect(repository.calls.where((c) => c.startsWith('search/')), [
        'search/bitcoin',
      ]);
      expect(cubit.state.searching, isTrue);
      expect(cubit.state.coins.single.id, 'bitcoin');
      await cubit.close();
    });

    test('clearing the search goes back to the tab', () async {
      repository.searches['sol'] = ['solana'];
      final cubit = build();
      await cubit.load();
      cubit.queryChanged('sol');
      await settle();
      expect(cubit.state.coins.single.id, 'solana');

      cubit.queryChanged('s');
      await settle();
      expect(cubit.state.searching, isFalse);
      expect(cubit.state.coins, hasLength(50));
      await cubit.close();
    });

    test('nothing to show becomes the error state', () async {
      repository.failWith = const NoConnectionFailure();
      final cubit = build();
      await cubit.load();
      expect(cubit.state.status, CryptoListStatus.failure);
      expect(cubit.state.failure, const NoConnectionFailure());
      await cubit.close();
    });

    test('a failed refresh keeps the coins on screen', () async {
      final cubit = build();
      await cubit.load();
      repository.failWith = const RateLimitedFailure();
      await cubit.refresh();
      expect(cubit.state.status, CryptoListStatus.ready);
      expect(cubit.state.coins, hasLength(50));
      expect(cubit.state.refreshing, isFalse);
      expect(repository.calls.last, 'mostTraded/1!');
      await cubit.close();
    });

    test('starring a coin refreshes the favorites tab', () async {
      final cubit = build();
      await cubit.load();
      await cubit.selectTab(MarketTab.favorites);
      expect(cubit.state.coins, isEmpty);

      await repository.toggleFavorite('ethereum');
      await settle();
      expect(cubit.state.coins.single.id, 'ethereum');
      await cubit.close();
    });
  });

  group('CoinDetailCubit', () {
    test(
      'loads quote, chart and star; switching period reloads the chart',
      () async {
        repository.charts['bitcoin/week'] = [
          PricePoint(at: DateTime.utc(2026, 11), price: CryptoPrice.parse('1')),
          PricePoint(
            at: DateTime.utc(2026, 11, 2),
            price: CryptoPrice.parse('2'),
          ),
        ];
        await repository.toggleFavorite('bitcoin');
        final cubit = CoinDetailCubit(repository);

        await cubit.load('bitcoin');
        await settle();
        expect(cubit.state.status, CoinDetailStatus.ready);
        expect(cubit.state.quote!.coin.id, 'bitcoin');
        expect(cubit.state.favorite, isTrue);
        expect(cubit.state.chart!.range, ChartRange.day);

        await cubit.selectRange(ChartRange.week);
        expect(cubit.state.chart!.points, hasLength(2));
        expect(cubit.state.chartLoading, isFalse);

        await cubit.toggleFavorite();
        await settle();
        expect(cubit.state.favorite, isFalse);
        await cubit.close();
      },
    );

    test('an unknown coin is a failure', () async {
      final cubit = CoinDetailCubit(repository);
      await cubit.load('nope');
      expect(cubit.state.status, CoinDetailStatus.failure);
      expect(cubit.state.failure, const NotFoundFailure());
      await cubit.close();
    });

    test('a failed chart keeps the quote', () async {
      final cubit = CoinDetailCubit(repository);
      await cubit.load('bitcoin');
      repository.failWith = const TimeoutFailure();
      await cubit.selectRange(ChartRange.year);
      expect(cubit.state.status, CoinDetailStatus.ready);
      expect(cubit.state.chartFailure, const TimeoutFailure());

      await cubit.refresh();
      expect(cubit.state.quote, isNotNull);
      expect(cubit.state.failure, const TimeoutFailure());
      await cubit.close();
    });
  });

  group('highlights', () {
    test('without favorites it shows the best known coins', () async {
      final result = await LoadHighlights(repository)();
      expect(result.valueOrNull!.coins.map((c) => c.id), [
        'bitcoin',
        'ethereum',
        'solana',
      ]);
    });

    test('with favorites it shows the first three', () async {
      for (final id in ['coin1', 'coin2', 'coin3', 'coin4']) {
        await repository.toggleFavorite(id);
      }
      final result = await LoadHighlights(repository)();
      expect(result.valueOrNull!.coins.map((c) => c.id), [
        'coin1',
        'coin2',
        'coin3',
      ]);
    });

    test('the card keeps the last list when a refresh fails', () async {
      final cubit = CryptoHighlightsCubit(LoadHighlights(repository));
      await cubit.load();
      expect(cubit.state.list!.coins, hasLength(3));

      repository.failWith = const NoConnectionFailure();
      await cubit.load(forceRefresh: true);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.list!.coins, hasLength(3));
      await cubit.close();
    });

    test('the card has nothing when the first load fails', () async {
      repository.failWith = const NoConnectionFailure();
      final cubit = CryptoHighlightsCubit(LoadHighlights(repository));
      await cubit.load();
      expect(cubit.state.list, isNull);
      expect(cubit.state.loading, isFalse);
      await cubit.close();
    });
  });

  test('stale freshness reaches the list state', () async {
    repository.freshness = DataFreshness(
      syncedAt: DateTime.utc(2026, 11, 6, 12),
      syncFailure: const NoConnectionFailure(),
    );
    final cubit = CryptoListCubit(
      LoadMarketTab(repository, clock),
      SearchCoins(repository, clock),
      repository,
    );
    await cubit.load();
    expect(cubit.state.freshness!.isStale, isTrue);
    expect(await repository.toggleFavorite('x'), const Ok(true));
    await cubit.close();
  });
}
