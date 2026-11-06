import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart'
    hide ModularWatchExtension;

import '../../../../app/routes.dart';
import '../../../../core/theme/monte_theme.dart';
import '../../../../core/ui/skeleton.dart';
import '../crypto_formatter.dart';
import '../widgets/coin_widgets.dart';
import 'crypto_highlights_cubit.dart';

/// Small card on the dashboard with three coins (the favorites, or BTC,
/// ETH and SOL) and a link to the crypto tab.
class CryptoHighlightsCard extends StatelessWidget {
  const CryptoHighlightsCard({super.key, required this.onOpenAll});

  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => Modular.get<CryptoHighlightsCubit>()..load(),
    child: CryptoHighlightsView(
      format: Modular.get<CryptoFormatter>(),
      onOpenAll: onOpenAll,
    ),
  );
}

class CryptoHighlightsView extends StatelessWidget {
  const CryptoHighlightsView({
    super.key,
    required this.format,
    required this.onOpenAll,
    this.onOpenCoin = _openCoin,
  });

  static void _openCoin(String id) =>
      Modular.to.pushNamed(Routes.cryptoCoin(id));

  final CryptoFormatter format;
  final VoidCallback onOpenAll;
  final ValueChanged<String> onOpenCoin;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<CryptoHighlightsCubit, CryptoHighlightsState>(
        builder: (context, state) {
          final list = state.list;
          if (!state.loading && list == null) return const SizedBox.shrink();
          final text = Theme.of(context).textTheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Card(
              key: const Key('dashboard.crypto'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                'Cripto agora',
                                style: text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: onOpenAll,
                            child: const Text('Ver tudo ›'),
                          ),
                        ],
                      ),
                    ),
                    if (list == null)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Skeleton(height: 120),
                      )
                    else ...[
                      for (final coin in list.coins)
                        CoinTile(
                          coin: coin,
                          format: format,
                          onTap: () => onOpenCoin(coin.id),
                        ),
                      if (list.freshness.isStale)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: Text(
                            'Cotações guardadas no aparelho.',
                            style: text.bodySmall?.copyWith(
                              color: context.monte.subtle,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
}
