import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart'
    hide ModularWatchExtension;
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../core/failures/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/monte_theme.dart';
import '../../../../core/time/date_labels.dart';
import '../../../../core/ui/failure_message.dart';
import '../../../../core/ui/skeleton.dart';
import '../../../../core/ui/stale_banner.dart';
import '../../domain/entities/coin.dart';
import '../../domain/entities/crypto_price.dart';
import '../../domain/entities/market_data.dart';
import '../crypto_formatter.dart';
import '../widgets/coin_widgets.dart';
import 'coin_detail_cubit.dart';

/// Named route `/cripto/moeda/:id`.
class CoinDetailPage extends StatelessWidget {
  const CoinDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => Modular.get<CoinDetailCubit>()..load(id),
    child: CoinDetailView(
      format: Modular.get<CryptoFormatter>(),
      dates: Modular.get<DateLabels>(),
    ),
  );
}

class CoinDetailView extends StatelessWidget {
  const CoinDetailView({super.key, required this.format, required this.dates});

  final CryptoFormatter format;
  final DateLabels dates;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CoinDetailCubit, CoinDetailState>(
        builder: (context, state) {
          final cubit = context.read<CoinDetailCubit>();
          final coin = state.quote?.coin;
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: coin == null
                  ? const Text('Cripto')
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CoinAvatar(coin: coin, size: 26),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            coin.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
              actions: [
                if (coin != null)
                  IconButton(
                    key: const Key('coin.favorite'),
                    tooltip: state.favorite
                        ? 'Tirar das favoritas'
                        : 'Adicionar às favoritas',
                    onPressed: cubit.toggleFavorite,
                    icon: Icon(
                      state.favorite
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: state.favorite ? context.monte.gold : null,
                    ),
                  ),
              ],
            ),
            body: switch (state.status) {
              CoinDetailStatus.loading => const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Skeleton(width: 220, height: 36),
                    SizedBox(height: 12),
                    Skeleton(width: 180, height: 18),
                    SizedBox(height: 20),
                    Skeleton(height: 240),
                  ],
                ),
              ),
              CoinDetailStatus.failure => _Failed(
                failure: state.failure ?? const UnexpectedFailure('unknown'),
                onRetry: cubit.refresh,
              ),
              CoinDetailStatus.ready => RefreshIndicator(
                onRefresh: cubit.refresh,
                child: _Details(
                  state: state,
                  format: format,
                  dates: dates,
                  cubit: cubit,
                ),
              ),
            },
          );
        },
      );
}

class _Details extends StatelessWidget {
  const _Details({
    required this.state,
    required this.format,
    required this.dates,
    required this.cubit,
  });

  final CoinDetailState state;
  final CryptoFormatter format;
  final DateLabels dates;
  final CoinDetailCubit cubit;

  @override
  Widget build(BuildContext context) {
    final quote = state.quote!;
    final coin = quote.coin;
    final text = Theme.of(context).textTheme;
    final colors = context.monte;
    final failure = quote.freshness.syncFailure;
    final change = coin.priceChange24h;
    final percent = coin.change24h;
    // The direction comes from the change in reais when there is one: a
    // small move can round to 0,00% and still be a fall.
    final direction = change?.units.sign ?? percent?.hundredths.sign ?? 0;
    final changeColor = switch (direction) {
      > 0 => colors.income,
      < 0 => colors.expense,
      _ => colors.subtle,
    };

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (failure is RateLimitedFailure)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RateLimitBanner(
              key: ValueKey(quote.freshness),
              failure: failure,
              onRetry: cubit.refresh,
            ),
          )
        else if (quote.freshness.isStale)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StaleBanner(freshness: quote.freshness, dates: dates),
          ),
        Text(
          'Preço atual',
          style: text.bodySmall?.copyWith(color: colors.subtle),
        ),
        Text(
          format.price(coin.price),
          key: const Key('coin.price'),
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (change != null || percent != null)
          Text(
            [
              if (change != null) format.change(change),
              if (percent != null) '(${format.plainPercent(percent)})',
              '· 24h',
            ].join(' '),
            style: text.bodyMedium?.copyWith(
              color: changeColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(height: 16),
        SegmentedButton<ChartRange>(
          key: const Key('coin.ranges'),
          showSelectedIcon: false,
          segments: [
            for (final range in ChartRange.values)
              ButtonSegment(value: range, label: Text(_rangeLabel(range))),
          ],
          selected: {state.range},
          onSelectionChanged: (selection) =>
              cubit.selectRange(selection.single),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: _ChartArea(state: state, format: format, cubit: cubit),
        ),
        const SizedBox(height: 16),
        _Stats(coin: coin, format: format),
        const SizedBox(height: 16),
        Text(
          'Atualizado às ${dates.time(coin.updatedAt ?? quote.freshness.syncedAt)}'
          ' · cotação informativa, não é recomendação.\n'
          'Dados fornecidos por CoinGecko.',
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: colors.subtle),
        ),
      ],
    );
  }

  static String _rangeLabel(ChartRange range) => switch (range) {
    ChartRange.day => '24h',
    ChartRange.week => '7d',
    ChartRange.month => '30d',
    ChartRange.year => '1a',
  };
}

class _ChartArea extends StatelessWidget {
  const _ChartArea({
    required this.state,
    required this.format,
    required this.cubit,
  });

  final CoinDetailState state;
  final CryptoFormatter format;
  final CoinDetailCubit cubit;

  @override
  Widget build(BuildContext context) {
    final chart = state.chart;
    final failure = state.chartFailure;
    if (chart == null || chart.range != state.range) {
      if (failure != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(failureMessage(failure), textAlign: TextAlign.center),
              TextButton(
                onPressed: () => cubit.selectRange(state.range),
                child: const Text('Tentar de novo'),
              ),
            ],
          ),
        );
      }
      return const Skeleton(height: 230);
    }
    if (chart.points.length < 2) {
      return const Center(child: Text('Sem histórico pra esse período.'));
    }
    return AnimatedOpacity(
      opacity: state.chartLoading ? 0.4 : 1,
      duration: const Duration(milliseconds: 200),
      child: PriceChart(chart: chart, format: format),
    );
  }
}

/// Line chart of the period. Prices become `double` only to place the
/// line on the screen; the tooltip formats the exact integer.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.chart, required this.format});

  final CoinChart chart;
  final CryptoFormatter format;

  @override
  Widget build(BuildContext context) {
    final colors = context.monte;
    final points = chart.points;
    final up = !(chart.change?.isNegative ?? false);
    final color = up ? colors.income : colors.expense;
    final (low, high) = chart.bounds!;
    return Semantics(
      label:
          'Gráfico do período: de ${format.price(points.first.price)} '
          'para ${format.price(points.last.price)}, mínima de '
          '${format.price(low)} e máxima de ${format.price(high)}.',
      excludeSemantics: true,
      child: SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        primaryXAxis: const DateTimeAxis(isVisible: false),
        primaryYAxis: const NumericAxis(isVisible: false),
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          builder: (context, details) {
            final index = details.pointIndex;
            if (index == null || index >= points.length) {
              return const SizedBox.shrink();
            }
            final point = points[index];
            return Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.brandDeep,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${format.price(point.price)}\n${_when(point.at)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            );
          },
        ),
        series: [
          AreaSeries<PricePoint, DateTime>(
            dataSource: points,
            xValueMapper: (point, _) => point.at.toLocal(),
            yValueMapper: (point, _) => point.price.toChartValue(),
            color: color.withValues(alpha: 0.15),
            borderColor: color,
            animationDuration: 400,
          ),
        ],
      ),
    );
  }

  String _when(DateTime at) {
    final local = at.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.coin, required this.format});

  final Coin coin;
  final CryptoFormatter format;

  @override
  Widget build(BuildContext context) {
    String price(CryptoPrice? value) =>
        value == null ? '—' : format.price(value);
    String total(Money? value) => value == null ? '—' : format.compact(value);
    final items = [
      ('Máxima 24h', price(coin.high24h)),
      ('Mínima 24h', price(coin.low24h)),
      ('Valor de mercado', total(coin.marketCap)),
      ('Volume 24h', total(coin.totalVolume)),
    ];
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 14,
          children: [
            for (final (label, value) in items)
              FractionallySizedBox(
                widthFactor: 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.bodySmall?.copyWith(
                        color: context.monte.subtle,
                      ),
                    ),
                    Text(
                      value,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.failure, required this.onRetry});

  final Failure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            failure is NotFoundFailure
                ? Icons.search_off_rounded
                : Icons.cloud_off_rounded,
            size: 56,
            color: context.monte.subtle,
          ),
          const SizedBox(height: 12),
          Text(
            failure is NotFoundFailure
                ? 'Não encontramos essa moeda.'
                : failureMessage(failure),
            key: const Key('coin.error'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (failure case final RateLimitedFailure limited)
            RateLimitBanner(
              failure: limited,
              onRetry: onRetry,
              showingSaved: false,
            )
          else if (failure is! NotFoundFailure)
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar de novo'),
            ),
        ],
      ),
    ),
  );
}
