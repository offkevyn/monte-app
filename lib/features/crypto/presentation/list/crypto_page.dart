import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart'
    hide ModularWatchExtension;

import '../../../../app/routes.dart';
import '../../../../core/failures/failure.dart';
import '../../../../core/theme/monte_theme.dart';
import '../../../../core/time/date_labels.dart';
import '../../../../core/ui/failure_message.dart';
import '../../../../core/ui/skeleton.dart';
import '../../../../core/ui/stale_banner.dart';
import '../../domain/entities/market_data.dart';
import '../crypto_formatter.dart';
import '../widgets/coin_widgets.dart';
import 'crypto_list_cubit.dart';

/// The crypto tab: most traded, trending and favorites, plus the search.
class CryptoPage extends StatelessWidget {
  const CryptoPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => Modular.get<CryptoListCubit>()..load(),
    child: CryptoView(
      format: Modular.get<CryptoFormatter>(),
      dates: Modular.get<DateLabels>(),
    ),
  );
}

/// Public so widget tests can pump it with their own cubit.
class CryptoView extends StatefulWidget {
  const CryptoView({
    super.key,
    required this.format,
    required this.dates,
    this.onOpenCoin = _openCoin,
  });

  static void _openCoin(String id) =>
      Modular.to.pushNamed(Routes.cryptoCoin(id));

  final CryptoFormatter format;
  final DateLabels dates;
  final ValueChanged<String> onOpenCoin;

  @override
  State<CryptoView> createState() => _CryptoViewState();
}

class _CryptoViewState extends State<CryptoView> {
  final _search = TextEditingController();
  static const _prefetchDistance = 600.0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < _prefetchDistance) {
      context.read<CryptoListCubit>().loadMore();
    }
    return false;
  }

  void _clearSearch() {
    _search.clear();
    context.read<CryptoListCubit>().queryChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    child: SafeArea(
      bottom: false,
      child: BlocBuilder<CryptoListCubit, CryptoListState>(
        builder: (context, state) {
          final cubit = context.read<CryptoListCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              _searchField(context),
              if (!state.searching) _tabs(state, cubit),
              SizedBox(
                height: 2,
                child: state.refreshing && state.coins.isNotEmpty
                    ? const LinearProgressIndicator(
                        key: Key('crypto.refreshing'),
                        minHeight: 2,
                      )
                    : null,
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: RefreshIndicator(
                    onRefresh: cubit.refresh,
                    child: _body(context, state, cubit),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _header(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Cripto',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'dados CoinGecko',
              style: text.bodySmall?.copyWith(color: context.monte.subtle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: TextField(
      key: const Key('crypto.search'),
      controller: _search,
      textInputAction: TextInputAction.search,
      onChanged: (text) {
        context.read<CryptoListCubit>().queryChanged(text);
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Buscar moeda',
        prefixIcon: const Icon(Icons.search_rounded),
        isDense: true,
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                onPressed: _clearSearch,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    ),
  );

  Widget _tabs(CryptoListState state, CryptoListCubit cubit) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: [
            for (final tab in MarketTab.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: Key('crypto.tab.${tab.name}'),
                  label: Text(_tabLabel(tab)),
                  avatar: tab == MarketTab.favorites
                      ? const Icon(Icons.star_rounded, size: 18)
                      : null,
                  selected: state.tab == tab,
                  onSelected: (_) => cubit.selectTab(tab),
                ),
              ),
          ],
        ),
      );

  static String _tabLabel(MarketTab tab) => switch (tab) {
    MarketTab.mostTraded => 'Mais negociadas',
    MarketTab.trending => 'Em alta',
    MarketTab.favorites => 'Favoritas',
  };

  Widget _body(
    BuildContext context,
    CryptoListState state,
    CryptoListCubit cubit,
  ) {
    switch (state.status) {
      case CryptoListStatus.loading:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Semantics(
              label: 'Carregando',
              child: Column(
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    const Skeleton(height: 52),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        );
      case CryptoListStatus.failure:
        final failure = state.failure ?? const UnexpectedFailure('unknown');
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Icon(
              failure is NoConnectionFailure
                  ? Icons.wifi_off_rounded
                  : Icons.cloud_off_rounded,
              size: 56,
              color: context.monte.subtle,
            ),
            const SizedBox(height: 12),
            Text(
              failure is NoConnectionFailure
                  ? 'Sem internet e ainda não tem cotação guardada no '
                        'aparelho. Assim que a conexão voltar, puxe pra '
                        'atualizar.'
                  : failureMessage(failure),
              key: const Key('crypto.error'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (failure is RateLimitedFailure)
              RateLimitBanner(
                failure: failure,
                onRetry: cubit.refresh,
                showingSaved: false,
              )
            else
              Center(
                child: FilledButton(
                  onPressed: cubit.refresh,
                  child: const Text('Tentar de novo'),
                ),
              ),
          ],
        );
      case CryptoListStatus.ready:
        return ListView.builder(
          key: PageStorageKey('crypto.list.${state.tab.name}'),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.coins.length + 3,
          itemBuilder: (context, index) {
            if (index == 0) return _notice(context, state, cubit);
            if (index == state.coins.length + 1) {
              return _footer(context, state, cubit);
            }
            if (index == state.coins.length + 2) return _attribution(context);
            final coin = state.coins[index - 1];
            return CoinTile(
              coin: coin,
              format: widget.format,
              onTap: () => widget.onOpenCoin(coin.id),
            );
          },
        );
    }
  }

  /// Banner on top: 429 countdown, offline copy, or an empty result.
  Widget _notice(
    BuildContext context,
    CryptoListState state,
    CryptoListCubit cubit,
  ) {
    final freshness = state.freshness;
    final failure = freshness?.syncFailure;
    final banner = switch (failure) {
      RateLimitedFailure() => RateLimitBanner(
        key: ValueKey(freshness),
        failure: failure,
        onRetry: cubit.refresh,
      ),
      null => null,
      _ when state.searching => _plainBanner(
        context,
        'Sem conexão. Buscando só nas moedas guardadas no aparelho.',
      ),
      _ => StaleBanner(freshness: freshness!, dates: widget.dates),
    };
    final empty = state.coins.isEmpty ? _empty(context, state) : null;
    if (banner == null && empty == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(children: [?banner, ?empty]),
    );
  }

  Widget _plainBanner(BuildContext context, String message) => Container(
    key: const Key('crypto.offlineSearch'),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: context.monte.gold.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );

  Widget _empty(BuildContext context, CryptoListState state) {
    final (icon, message) = state.searching
        ? (
            Icons.search_off_rounded,
            'Nenhuma moeda encontrada para "${state.query}".',
          )
        : switch (state.tab) {
            MarketTab.favorites => (
              Icons.star_outline_rounded,
              'Nenhuma favorita ainda. Abra uma moeda e toque na estrela '
                  'pra ela aparecer aqui.',
            ),
            _ => (Icons.inbox_outlined, 'Nada por aqui agora.'),
          };
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: context.monte.subtle),
          const SizedBox(height: 12),
          Text(
            message,
            key: const Key('crypto.empty'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _footer(
    BuildContext context,
    CryptoListState state,
    CryptoListCubit cubit,
  ) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Skeleton(height: 52),
      );
    }
    final failure = state.pageFailure;
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(failureMessage(failure), textAlign: TextAlign.center),
            TextButton(
              key: const Key('crypto.retryPage'),
              onPressed: cubit.loadMore,
              child: const Text('Tentar carregar mais'),
            ),
          ],
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  /// CoinGecko's free plan asks for attribution.
  Widget _attribution(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    child: Text(
      'Dados fornecidos por CoinGecko. Cotação informativa, não é '
      'recomendação de investimento.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.monte.subtle),
    ),
  );
}
