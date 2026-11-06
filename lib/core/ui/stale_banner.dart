import 'package:flutter/material.dart';

import '../failures/failure.dart';
import '../freshness/data_freshness.dart';
import '../theme/monte_theme.dart';
import '../time/date_labels.dart';

/// Yellow strip: the numbers on screen are the local copy, and since when.
class StaleBanner extends StatelessWidget {
  const StaleBanner({super.key, required this.freshness, required this.dates});

  final DataFreshness freshness;
  final DateLabels dates;

  @override
  Widget build(BuildContext context) {
    final colors = context.monte;
    final reason = freshness.syncFailure is NoConnectionFailure
        ? 'Sem conexão.'
        : 'Não deu pra atualizar.';
    final when = dates.dayAndTime(freshness.syncedAt).replaceAll(' · ', ', ');
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('stale.banner'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.gold.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 18, color: colors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$reason Mostrando dados de ${when[0].toLowerCase()}'
                '${when.substring(1)}.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
