import 'package:flutter/material.dart';

import '../../../../core/money/money_formatter.dart';
import '../../../../core/theme/monte_theme.dart';
import '../../../../core/time/date_labels.dart';
import '../../domain/entities/transaction.dart';
import '../ledger_labels.dart';
import 'sensitive_value.dart';

/// One transaction in a list (dashboard and statement).
///
/// Direction never depends on color alone: there is an arrow, a sign and,
/// for screen readers, the type written out. Failed and reversed amounts are
/// struck through because they do not count in the balance.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.money,
    required this.dates,
    this.hidden = false,
    this.showDay = true,
    this.onTap,
  });

  final Transaction transaction;
  final MoneyFormatter money;
  final DateLabels dates;

  /// Balance hidden: the amount is blurred.
  final bool hidden;

  /// `Hoje · 14:32` (dashboard) or just `14:32` (statement, under a day
  /// header).
  final bool showDay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final colors = context.monte;
    final text = Theme.of(context).textTheme;
    final color = t.isIncome ? colors.income : colors.expense;
    final notCounted =
        t.status == TransactionStatus.failed ||
        t.status == TransactionStatus.reversed;
    final when = showDay
        ? dates.dayAndTime(t.occurredAt)
        : dates.time(t.occurredAt);
    final amount = money.format(t.signedAmount, showPlusSign: true);
    final status = t.status == TransactionStatus.completed
        ? null
        : LedgerLabels.status(t.status);

    // One node per transaction, so a screen reader reads each on its own.
    return Semantics(
      container: true,
      button: onTap != null,
      label: [
        LedgerLabels.type(t.type),
        LedgerLabels.title(t),
        if (hidden) 'valor oculto' else money.format(t.amount),
        when,
        LedgerLabels.status(t.status),
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  t.isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LedgerLabels.title(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            when,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: colors.subtle,
                            ),
                          ),
                        ),
                        if (status != null) ...[
                          const SizedBox(width: 6),
                          _StatusChip(status: t.status, label: status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SensitiveValue(
                hidden: hidden,
                child: Text(
                  amount,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: notCounted ? colors.subtle : color,
                    decoration: notCounted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

  final TransactionStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.monte;
    final color = switch (status) {
      TransactionStatus.pending => colors.warning,
      TransactionStatus.failed => colors.expense,
      TransactionStatus.reversed ||
      TransactionStatus.completed => colors.subtle,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
