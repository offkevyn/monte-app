import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Modular 6 also defines context.read/watch; the bloc ones are used here.
import 'package:flutter_modular/flutter_modular.dart'
    hide ModularWatchExtension;

import '../../../../core/failures/failure.dart';
import '../../../../core/money/money_formatter.dart';
import '../../../../core/theme/monte_theme.dart';
import '../../../../core/time/date_labels.dart';
import '../../../../core/ui/failure_message.dart';
import '../../../../core/ui/skeleton.dart';
import '../../../../core/ui/under_construction.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/presentation/ledger_labels.dart';
import '../../../ledger/presentation/widgets/transaction_tile.dart';
import '../statement_page.dart';
import 'transaction_detail_cubit.dart';

/// Opened by the named route `/extrato/transacao/:id`.
class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => Modular.get<TransactionDetailCubit>()..load(id),
    child: TransactionDetailView(
      id: id,
      money: Modular.get<MoneyFormatter>(),
      dates: Modular.get<DateLabels>(),
    ),
  );
}

class TransactionDetailView extends StatelessWidget {
  const TransactionDetailView({
    super.key,
    required this.id,
    required this.money,
    required this.dates,
  });

  final String id;
  final MoneyFormatter money;
  final DateLabels dates;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detalhes'),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Compartilhar comprovante',
          onPressed: () => showUnderConstruction(context, 'O comprovante'),
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
    ),
    body: BlocBuilder<TransactionDetailCubit, TransactionDetailState>(
      builder: (context, state) => switch (state) {
        DetailLoading() => const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Skeleton(width: 64, height: 64, radius: 32),
              SizedBox(height: 16),
              Skeleton(width: 180, height: 32),
              SizedBox(height: 24),
              Skeleton(height: 220),
            ],
          ),
        ),
        DetailFailed(:final failure) => _NotFound(
          message: failure is NotFoundFailure
              ? 'Não encontramos essa transação.'
              : failureMessage(failure),
          onRetry: failure is NotFoundFailure
              ? null
              : () => context.read<TransactionDetailCubit>().load(id),
        ),
        final DetailLoaded loaded => Stack(
          children: [
            _Details(
              transaction: loaded.transaction,
              money: money,
              dates: dates,
              missingDetails: loaded.missingDetails,
            ),
            if (loaded.refreshing)
              const LinearProgressIndicator(
                key: Key('detail.refreshing'),
                minHeight: 2,
              ),
          ],
        ),
      },
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({
    required this.transaction,
    required this.money,
    required this.dates,
    required this.missingDetails,
  });

  final Transaction transaction;
  final bool missingDetails;
  final MoneyFormatter money;
  final DateLabels dates;

  static const _prefix = StatementPage.heroPrefix;

  /// `tx_8f3a…c21e`: short enough to read, the copy button gets the rest.
  static String _shortId(String id) => id.length <= 14
      ? id
      : '${id.substring(0, 7)}…${id.substring(id.length - 4)}';

  Future<void> _copyId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: transaction.id));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('✓ Identificador copiado')));
  }

  String? _note() {
    final t = transaction;
    return switch (t.status) {
      TransactionStatus.pending when t.method == PaymentMethod.creditCard =>
        'Compras no crédito ficam pendentes até a confirmação da loja. O '
            'valor já está reservado no saldo.',
      TransactionStatus.pending =>
        'Ainda em processamento. Saídas pendentes já ficam reservadas no '
            'saldo.',
      TransactionStatus.failed =>
        'Essa transação não foi concluída e não mexe no saldo.',
      TransactionStatus.reversed =>
        'O valor foi devolvido e não conta no saldo.',
      TransactionStatus.completed => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final colors = context.monte;
    final text = Theme.of(context).textTheme;
    final color = t.isIncome ? colors.income : colors.expense;
    final when = dates.fullDateAndTime(t.occurredAt);
    final method = switch (t.method) {
      PaymentMethod.creditCard || PaymentMethod.debitCard
          when t.cardLastDigits != null =>
        '${LedgerLabels.method(t.method)} · final ${t.cardLastDigits}',
      _ => LedgerLabels.method(t.method),
    };
    final note = _note();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Center(
          child: Hero(
            tag: TransactionTile.iconHeroTag(_prefix, t.id),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                t.isIncome
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                color: color,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${LedgerLabels.type(t.type)} · ${LedgerLabels.method(t.method)}',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: colors.subtle),
        ),
        const SizedBox(height: 4),
        Center(
          child: Hero(
            tag: TransactionTile.amountHeroTag(_prefix, t.id),
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                money.format(t.signedAmount, showPlusSign: true),
                key: const Key('detail.amount'),
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  decoration:
                      t.status == TransactionStatus.failed ||
                          t.status == TransactionStatus.reversed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: StatusChip(status: t.status)),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _Field('Descrição', t.description),
                // Skipped when it only repeats the description.
                if (t.counterparty case final who? when who != t.description)
                  _Field(t.isIncome ? 'De' : 'Para', who),
                if (t.message case final message?)
                  _Field('Mensagem', '"$message"'),
                _Field('Data e hora', when),
                _Field(
                  'Tipo',
                  t.isIncome ? '↓ Entrada (crédito)' : '↑ Saída (débito)',
                ),
                _Field('Categoria', LedgerLabels.category(t.category)),
                _Field('Forma', method),
                _Field(
                  'Identificador',
                  _shortId(t.id),
                  trailing: TextButton.icon(
                    key: const Key('detail.copy'),
                    onPressed: () => _copyId(context),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar'),
                  ),
                  last: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          [
            'Horário local do aparelho.',
            ?note,
            if (missingDetails)
              'Sem conexão: alguns detalhes aparecem quando a internet voltar.',
          ].join(' '),
          style: text.bodySmall?.copyWith(color: colors.subtle),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            key: const Key('detail.support'),
            leading: Icon(Icons.headset_mic_outlined, color: colors.brand),
            title: const Text('Algo errado com essa transação?'),
            subtitle: const Text('Fale com o suporte'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showUnderConstruction(context, 'O suporte'),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.trailing, this.last = false});

  final String label;
  final String value;
  final Widget? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: context.monte.subtle),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  // Scrolls when the room is short (small phone with the keyboard open).
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 52, color: context.monte.subtle),
          const SizedBox(height: 12),
          Text(
            message,
            key: const Key('detail.error'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (onRetry != null)
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar de novo'),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Voltar'),
            ),
        ],
      ),
    ),
  );
}
