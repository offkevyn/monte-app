import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/failures/failure.dart';
import '../../../../core/theme/monte_theme.dart';
import '../../domain/entities/coin.dart';
import '../../domain/entities/crypto_price.dart';
import '../crypto_formatter.dart';

/// The coin's logo, or its first letter when the image cannot load
/// (offline, or a coin without one).
class CoinAvatar extends StatelessWidget {
  const CoinAvatar({super.key, required this.coin, this.size = 40});

  final Coin coin;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.monte;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.chip, shape: BoxShape.circle),
      child: Text(
        coin.symbol.characters.first,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: colors.brand,
          fontSize: size * 0.42,
        ),
      ),
    );
    final url = coin.imageUrl;
    if (url == null) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => fallback,
        // The letter stays until the first frame of the image is decoded,
        // so the circle is never empty while it downloads.
        frameBuilder: (_, child, frame, synchronous) =>
            frame == null && !synchronous ? fallback : child,
      ),
    );
  }
}

/// `▲ 2,41%` in green or `▼ 0,87%` in red; the arrow and sign carry the
/// meaning, the color only helps.
class ChangeText extends StatelessWidget {
  const ChangeText({
    super.key,
    required this.change,
    required this.format,
    this.style,
  });

  final PercentChange? change;
  final CryptoFormatter format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final value = change;
    final colors = context.monte;
    if (value == null) {
      return Text('—', style: style?.copyWith(color: colors.subtle));
    }
    final color = value.isPositive
        ? colors.income
        : (value.isNegative ? colors.expense : colors.subtle);
    return Text(
      format.percent(value),
      style: (style ?? const TextStyle()).copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// One row of the crypto list: logo, name, symbol and rank, price and the
/// 24h change.
class CoinTile extends StatelessWidget {
  const CoinTile({
    super.key,
    required this.coin,
    required this.format,
    required this.onTap,
  });

  final Coin coin;
  final CryptoFormatter format;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rank = coin.marketCapRank;
    final change = coin.change24h;
    return Semantics(
      container: true,
      button: true,
      label:
          '${coin.name}, ${format.price(coin.price)}'
          '${change == null ? '' : ', ${_spoken(format.percent(change))} em 24 horas'}',
      excludeSemantics: true,
      child: InkWell(
        key: Key('coin.${coin.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CoinAvatar(coin: coin),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      rank == null ? coin.symbol : '${coin.symbol} · #$rank',
                      style: text.bodySmall?.copyWith(
                        color: context.monte.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    format.price(coin.price),
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ChangeText(
                    change: change,
                    format: format,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _spoken(String percent) =>
      percent.replaceFirst('▲', 'subiu').replaceFirst('▼', 'caiu');
}

/// Shown when CoinGecko answered 429: counts down the wait the server asked
/// for (or [fallbackWait] when it did not say) and then calls [onRetry]
/// once by itself.
class RateLimitBanner extends StatefulWidget {
  const RateLimitBanner({
    super.key,
    required this.failure,
    required this.onRetry,
    this.showingSaved = true,
  });

  static const fallbackWait = Duration(seconds: 30);

  final RateLimitedFailure failure;
  final VoidCallback onRetry;

  /// Adds "showing the last saved result".
  final bool showingSaved;

  @override
  State<RateLimitBanner> createState() => _RateLimitBannerState();
}

class _RateLimitBannerState extends State<RateLimitBanner> {
  late int _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final wait = widget.failure.retryAfter ?? RateLimitBanner.fallbackWait;
    _seconds = wait.inSeconds.clamp(1, 120);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds <= 1) {
        _timer?.cancel();
        widget.onRetry();
        return;
      }
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.monte;
    final text = Theme.of(context).textTheme;
    return Container(
      key: const Key('crypto.rateLimit'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 18, color: colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Muitas consultas seguidas. Tentando de novo em '
                    '$_seconds s',
                    style: text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.showingSaved)
                  Text(
                    'Mostrando o último resultado guardado.',
                    style: text.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
