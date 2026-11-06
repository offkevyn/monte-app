import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/freshness/data_freshness.dart';
import 'package:monte/core/money/money_formatter.dart';
import 'package:monte/core/theme/monte_theme.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/core/time/date_labels.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/features/crypto/domain/entities/crypto_price.dart';
import 'package:monte/features/crypto/domain/entities/market_data.dart';
import 'package:monte/features/crypto/domain/usecases/market_usecases.dart';
import 'package:monte/features/crypto/presentation/crypto_formatter.dart';
import 'package:monte/features/crypto/presentation/detail/coin_detail_cubit.dart';
import 'package:monte/features/crypto/presentation/detail/coin_detail_page.dart';
import 'package:monte/features/crypto/presentation/highlights/crypto_highlights_card.dart';
import 'package:monte/features/crypto/presentation/highlights/crypto_highlights_cubit.dart';
import 'package:monte/features/crypto/presentation/list/crypto_list_cubit.dart';
import 'package:monte/features/crypto/presentation/list/crypto_page.dart';

import '../../../helpers/coins.dart';
import '../../../helpers/memory_market_repository.dart';

void main() {
  final clock = FixedClock(DateTime.utc(2026, 11, 6, 17));
  final dates = DateLabels(clock, FixedOffsetCalendar.brasilia);
  final format = CryptoFormatter(MoneyFormatter());
  late MemoryMarketRepository repository;

  setUpAll(() async {
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    repository = MemoryMarketRepository([
      coin('bitcoin', name: 'Bitcoin', symbol: 'btc', rank: 1, price: '417209'),
      coin('pepe', name: 'Pepe', symbol: 'pepe', price: '0.0000712'),
    ]);
  });

  Widget app(Widget child) => MaterialApp(
    theme: MonteTheme.light,
    home: Scaffold(body: child),
  );

  group('CryptoView', () {
    late List<String> opened;

    Future<void> pump(WidgetTester tester) async {
      opened = [];
      await tester.pumpWidget(
        app(
          BlocProvider(
            create: (_) => CryptoListCubit(
              LoadMarketTab(repository, clock),
              SearchCoins(repository, clock),
              repository,
              debounce: const Duration(milliseconds: 50),
            )..load(),
            child: CryptoView(
              format: format,
              dates: dates,
              onOpenCoin: opened.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists coins with price and change, and opens one', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('BTC · #1'), findsOneWidget);
      expect(find.text('▲ 1,50%'), findsNWidgets(2));
      expect(find.textContaining('0,0000712'), findsOneWidget);
      expect(
        find.textContaining('Dados fornecidos por CoinGecko'),
        findsOneWidget,
      );

      await tester.tap(find.text('Bitcoin'));
      expect(opened, ['bitcoin']);
    });

    testWidgets('empty favorites explain how to add one', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('crypto.tab.favorites')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('crypto.empty')), findsOneWidget);
      expect(find.textContaining('toque na estrela'), findsOneWidget);
    });

    testWidgets('search hides the tabs and shows the result', (tester) async {
      repository.searches['pep'] = ['pepe'];
      await pump(tester);
      await tester.enterText(find.byKey(const Key('crypto.search')), 'pep');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('crypto.tab.trending')), findsNothing);
      expect(find.text('Pepe'), findsOneWidget);
      expect(find.text('Bitcoin'), findsNothing);
    });

    testWidgets('no connection and nothing saved shows the error', (
      tester,
    ) async {
      repository.failWith = const NoConnectionFailure();
      await pump(tester);
      expect(find.byKey(const Key('crypto.error')), findsOneWidget);
      expect(find.textContaining('Sem internet'), findsOneWidget);

      repository.failWith = null;
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();
      expect(find.text('Bitcoin'), findsOneWidget);
    });

    testWidgets('offline copy shows the stale banner', (tester) async {
      repository.freshness = DataFreshness(
        syncedAt: DateTime.utc(2026, 11, 6, 15),
        syncFailure: const NoConnectionFailure(),
      );
      await pump(tester);
      expect(find.byKey(const Key('stale.banner')), findsOneWidget);
    });

    testWidgets('a 429 counts down and tries again by itself', (tester) async {
      repository.freshness = DataFreshness(
        syncedAt: DateTime.utc(2026, 11, 6, 17),
        syncFailure: const RateLimitedFailure(retryAfter: Duration(seconds: 3)),
      );
      await pump(tester);
      expect(find.textContaining('Tentando de novo em 3 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Tentando de novo em 2 s'), findsOneWidget);

      repository.freshness = DataFreshness(
        syncedAt: DateTime.utc(2026, 11, 6, 17, 1),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(repository.calls.last, 'mostTraded/1!');
      expect(find.byKey(const Key('crypto.rateLimit')), findsNothing);
    });
  });

  group('CoinDetailView', () {
    Future<void> pump(WidgetTester tester, String id) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MonteTheme.light,
          home: BlocProvider(
            create: (_) => CoinDetailCubit(repository)..load(id),
            child: CoinDetailView(format: format, dates: dates),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows price, change, stats and the chart', (tester) async {
      repository.charts['bitcoin/day'] = [
        for (var h = 0; h < 5; h++)
          PricePoint(
            at: DateTime.utc(2026, 11, 6, h),
            price: CryptoPrice.parse('${417000 + h * 50}'),
          ),
      ];
      await pump(tester, 'bitcoin');

      expect(find.byKey(const Key('coin.price')), findsOneWidget);
      expect(find.textContaining('417.209,00'), findsWidgets);
      expect(find.textContaining('(1,50%) · 24h'), findsOneWidget);
      expect(find.text('Valor de mercado'), findsOneWidget);
      expect(find.textContaining('8,7'), findsOneWidget);
      expect(find.byType(PriceChart), findsOneWidget);
    });

    testWidgets('the star adds and removes the favorite', (tester) async {
      await pump(tester, 'bitcoin');
      expect(find.byTooltip('Adicionar às favoritas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('coin.favorite')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Tirar das favoritas'), findsOneWidget);
    });

    testWidgets('picking a period with no history says so', (tester) async {
      await pump(tester, 'bitcoin');
      await tester.tap(find.text('1a'));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('chart/bitcoin/year'));
      expect(find.text('Sem histórico pra esse período.'), findsOneWidget);
    });

    testWidgets('unknown coin', (tester) async {
      await pump(tester, 'nope');
      expect(find.text('Não encontramos essa moeda.'), findsOneWidget);
    });
  });

  group('CryptoHighlightsView', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          BlocProvider(
            create: (_) =>
                CryptoHighlightsCubit(LoadHighlights(repository))..load(),
            child: CryptoHighlightsView(
              format: format,
              onOpenAll: () {},
              onOpenCoin: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the default coins', (tester) async {
      await pump(tester);
      expect(find.text('Cripto agora'), findsOneWidget);
      expect(find.text('Bitcoin'), findsOneWidget);
    });

    testWidgets('hides itself when nothing could be loaded', (tester) async {
      repository.failWith = const NoConnectionFailure();
      await pump(tester);
      expect(find.byKey(const Key('dashboard.crypto')), findsNothing);
    });
  });
}
