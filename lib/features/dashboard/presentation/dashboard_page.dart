import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Modular 6 also defines context.read/watch; the bloc ones are used here.
import 'package:flutter_modular/flutter_modular.dart'
    hide ModularWatchExtension;

import '../../../app/routes.dart';
import '../../../core/failures/failure.dart';
import '../../../core/money/money_formatter.dart';
import '../../../core/theme/monte_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/time/date_labels.dart';
import '../../../core/ui/failure_message.dart';
import '../../../core/ui/skeleton.dart';
import '../../../core/ui/under_construction.dart';
import '../../auth/presentation/current_session.dart';
import '../../ledger/domain/entities/date_span.dart';
import '../../ledger/domain/usecases/get_dashboard.dart';
import '../../ledger/presentation/ledger_labels.dart';
import '../../ledger/presentation/widgets/sensitive_value.dart';
import '../../ledger/presentation/widgets/stale_banner.dart';
import '../../ledger/presentation/widgets/transaction_tile.dart';
import 'dashboard_cubit.dart';
import 'widgets/movement_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onOpenStatement,
    required this.onOpenCrypto,
  });

  final VoidCallback onOpenStatement;
  final VoidCallback onOpenCrypto;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => Modular.get<DashboardCubit>()..load(),
    child: DashboardView(
      customerName: Modular.get<CurrentSession>().value?.customerName ?? '',
      money: Modular.get<MoneyFormatter>(),
      dates: Modular.get<DateLabels>(),
      theme: Modular.get<ThemeController>(),
      onOpenStatement: onOpenStatement,
      onOpenCrypto: onOpenCrypto,
    ),
  );
}

/// Public so widget tests can pump it with their own cubit and labels.
class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.customerName,
    required this.money,
    required this.dates,
    required this.theme,
    required this.onOpenStatement,
    required this.onOpenCrypto,
    this.onOpenDetail = _openDetail,
  });

  static void _openDetail(String id) =>
      Modular.to.pushNamed(Routes.statementDetail(id));

  /// Opens a transaction; overridable so tests do not need the router.
  final ValueChanged<String> onOpenDetail;
  final String customerName;
  final MoneyFormatter money;
  final DateLabels dates;
  final ThemeController theme;
  final VoidCallback onOpenStatement;
  final VoidCallback onOpenCrypto;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final cubit = context.read<DashboardCubit>();
          final summary = state.summary;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: RefreshIndicator(
              onRefresh: cubit.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      customerName: customerName,
                      dates: dates,
                      theme: theme,
                      card: switch (state.status) {
                        DashboardStatus.ready => _BalanceCard(
                          summary: summary!,
                          state: state,
                          money: money,
                          dates: dates,
                          onToggle: cubit.toggleBalance,
                        ),
                        DashboardStatus.loading => const _CardSkeleton(),
                        DashboardStatus.failure => const SizedBox.shrink(),
                      },
                    ),
                  ),
                  ..._body(context, state, cubit),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          );
        },
      );

  List<Widget> _body(
    BuildContext context,
    DashboardState state,
    DashboardCubit cubit,
  ) {
    switch (state.status) {
      case DashboardStatus.loading:
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                label: 'Carregando',
                child: const Column(
                  children: [
                    Skeleton(height: 64),
                    SizedBox(height: 16),
                    Skeleton(height: 220),
                    SizedBox(height: 16),
                    Skeleton(height: 160),
                  ],
                ),
              ),
            ),
          ),
        ];
      case DashboardStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _ErrorView(
              failure: state.failure ?? const UnexpectedFailure('unknown'),
              onRetry: cubit.load,
            ),
          ),
        ];
      case DashboardStatus.ready:
        final summary = state.summary!;
        return [
          if (summary.freshness.isStale)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: StaleBanner(freshness: summary.freshness, dates: dates),
              ),
            ),
          SliverToBoxAdapter(
            child: _Shortcuts(
              onOpenStatement: onOpenStatement,
              onOpenCrypto: onOpenCrypto,
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'Movimentação',
              action: _PeriodPicker(
                selected: state.preset,
                dates: dates,
                onSelected: cubit.selectPeriod,
              ),
              child: MovementChart(
                summary: summary.summary,
                money: money,
                dates: dates,
                hidden: state.balanceHidden,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'Últimas transações',
              action: TextButton(
                onPressed: onOpenStatement,
                child: const Text('Ver extrato ›'),
              ),
              child: summary.recent.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhuma movimentação ainda. Quando o dinheiro '
                        'entrar ou sair, aparece aqui.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: context.monte.subtle),
                      ),
                    )
                  : Column(
                      children: [
                        for (final transaction in summary.recent)
                          TransactionTile(
                            transaction: transaction,
                            money: money,
                            dates: dates,
                            hidden: state.balanceHidden,
                            onTap: () => onOpenDetail(transaction.id),
                          ),
                      ],
                    ),
            ),
          ),
        ];
    }
  }
}

/// Green top with the mountain silhouette, greeting and the balance card
/// overlapping its bottom edge.
class _Header extends StatelessWidget {
  const _Header({
    required this.customerName,
    required this.dates,
    required this.theme,
    required this.card,
  });

  final String customerName;
  final DateLabels dates;
  final ThemeController theme;
  final Widget card;

  @override
  Widget build(BuildContext context) {
    final colors = context.monte;
    final text = Theme.of(context).textTheme;
    final first = customerName.trim().split(RegExp(r'\s+')).first;
    final initials = customerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          bottom: 70,
          child: CustomPaint(
            painter: _MountainsPainter(
              background: colors.brandDeep,
              hills: colors.brandMid,
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colors.gold,
                      child: Text(
                        initials.isEmpty ? 'M' : initials,
                        style: TextStyle(
                          color: colors.onGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${dates.greeting()},',
                            style: text.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          Text(
                            first.isEmpty ? 'cliente' : first,
                            style: text.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: dark ? 'Usar tema claro' : 'Usar tema escuro',
                      onPressed: () =>
                          theme.toggle(Theme.of(context).brightness),
                      icon: Icon(
                        dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Notificações',
                      onPressed: () =>
                          showUnderConstruction(context, 'As notificações'),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Padding(padding: const EdgeInsets.only(right: 8), child: card),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MountainsPainter extends CustomPainter {
  _MountainsPainter({required this.background, required this.hills});

  final Color background;
  final Color hills;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final w = size.width;
    final h = size.height;
    // Two rows of hills, the "mar de morros" of Minas.
    final back = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.2, h * 0.5, w * 0.4, h * 0.7)
      ..quadraticBezierTo(w * 0.62, h * 0.45, w * 0.82, h * 0.66)
      ..quadraticBezierTo(w * 0.92, h * 0.58, w, h * 0.62)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(back, Paint()..color = hills.withValues(alpha: 0.35));
    final front = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.3, h * 0.68, w * 0.55, h * 0.84)
      ..quadraticBezierTo(w * 0.8, h * 0.7, w, h * 0.8)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(front, Paint()..color = hills.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_MountainsPainter old) =>
      old.background != background || old.hills != hills;
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.summary,
    required this.state,
    required this.money,
    required this.dates,
    required this.onToggle,
  });

  final DashboardSummary summary;
  final DashboardState state;
  final MoneyFormatter money;
  final DateLabels dates;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.monte;
    final text = Theme.of(context).textTheme;
    final hidden = state.balanceHidden;
    final balance = summary.balance;
    final totals = summary.summary.totals;
    final period = LedgerLabels.periodShort(state.preset, dates);

    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Saldo disponível',
                    style: text.bodyMedium?.copyWith(color: colors.subtle),
                  ),
                ),
                IconButton(
                  key: const Key('dashboard.eye'),
                  tooltip: hidden ? 'Mostrar saldo' : 'Esconder saldo',
                  onPressed: onToggle,
                  icon: Icon(
                    hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colors.brand,
                  ),
                ),
              ],
            ),
            SensitiveValue(
              hidden: hidden,
              child: Text(
                money.format(balance.available),
                key: const Key('dashboard.balance'),
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: balance.available.isNegative ? colors.expense : null,
                ),
              ),
            ),
            if (!balance.pendingDebits.isZero)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SensitiveValue(
                  hidden: hidden,
                  child: Text(
                    '${money.format(balance.pendingDebits)} reservados em '
                    'compras pendentes',
                    style: text.bodySmall?.copyWith(color: colors.warning),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Flow(
                    label: 'Entradas · $period',
                    value: money.format(totals.income),
                    icon: Icons.south_west_rounded,
                    color: colors.income,
                    hidden: hidden,
                  ),
                ),
                Expanded(
                  child: _Flow(
                    label: 'Saídas · $period',
                    value: money.format(totals.expense),
                    icon: Icons.north_east_rounded,
                    color: colors.expense,
                    hidden: hidden,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Flow extends StatelessWidget {
  const _Flow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.hidden,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.labelSmall?.copyWith(color: context.monte.subtle),
              ),
              SensitiveValue(
                hidden: hidden,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 120, height: 14),
          SizedBox(height: 12),
          Skeleton(width: 200, height: 30),
          SizedBox(height: 18),
          Skeleton(height: 32),
        ],
      ),
    ),
  );
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.onOpenStatement, required this.onOpenCrypto});

  final VoidCallback onOpenStatement;
  final VoidCallback onOpenCrypto;

  @override
  Widget build(BuildContext context) {
    void soon(String feature) => showUnderConstruction(context, feature);
    final items = [
      (Icons.receipt_long_rounded, 'Extrato', onOpenStatement, true),
      (Icons.currency_bitcoin_rounded, 'Cripto', onOpenCrypto, true),
      (Icons.pix_rounded, 'Pix', () => soon('O Pix'), false),
      (Icons.qr_code_2_rounded, 'Boleto', () => soon('O boleto'), false),
      (Icons.credit_card_rounded, 'Cartões', () => soon('Os cartões'), false),
      (Icons.phone_android_rounded, 'Recarga', () => soon('A recarga'), false),
      (
        Icons.swap_horiz_rounded,
        'Transferir',
        () => soon('A transferência'),
        false,
      ),
      (Icons.savings_outlined, 'Empréstimo', () => soon('O empréstimo'), false),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (icon, label, onTap, real) = items[index];
          return _Shortcut(icon: icon, label: label, onTap: onTap, real: real);
        },
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.real,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Working features are gold; the rest open the "coming soon" popup.
  final bool real;

  @override
  Widget build(BuildContext context) {
    final colors = context.monte;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: real ? colors.gold : colors.chip,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: real ? colors.onGold : colors.brand),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.action,
    required this.child,
  });

  final String title;
  final Widget action;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                action,
              ],
            ),
            Padding(padding: const EdgeInsets.only(right: 8), child: child),
          ],
        ),
      ),
    ),
  );
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({
    required this.selected,
    required this.dates,
    required this.onSelected,
  });

  final PeriodPreset selected;
  final DateLabels dates;
  final ValueChanged<PeriodPreset> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<PeriodPreset>(
    key: const Key('dashboard.period'),
    tooltip: 'Escolher período',
    initialValue: selected,
    onSelected: onSelected,
    itemBuilder: (_) => [
      for (final preset in PeriodPreset.values)
        PopupMenuItem(
          value: preset,
          child: Text(LedgerLabels.periodTitle(preset, dates)),
        ),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LedgerLabels.periodTitle(selected, dates),
            style: TextStyle(
              color: context.monte.brand,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(Icons.expand_more_rounded, color: context.monte.brand),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            failure is NoConnectionFailure
                ? Icons.wifi_off_rounded
                : Icons.cloud_off_rounded,
            size: 56,
            color: context.monte.subtle,
          ),
          const SizedBox(height: 12),
          Text(
            failureMessage(failure),
            key: const Key('dashboard.error'),
            textAlign: TextAlign.center,
            style: text.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }
}
