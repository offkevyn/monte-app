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
import '../../../core/time/date_labels.dart';
import '../../../core/ui/failure_message.dart';
import '../../../core/ui/on_visit.dart';
import '../../../core/ui/skeleton.dart';
import '../../../core/ui/stale_banner.dart';
import '../../../core/ui/under_construction.dart';
import '../../ledger/domain/entities/transaction.dart';
import '../../ledger/domain/entities/transaction_filter.dart';
import '../../ledger/domain/services/day_grouping.dart';
import '../../ledger/domain/usecases/get_statement_page.dart';
import '../../ledger/presentation/ledger_labels.dart';
import '../../ledger/presentation/widgets/transaction_tile.dart';
import 'bloc/statement_bloc.dart';
import 'filter_sheet.dart';

typedef OpenFilters = Future<TransactionFilter?> Function(
  BuildContext context,
  TransactionFilter current,
);

class StatementPage extends StatelessWidget {
  const StatementPage({super.key, this.visits});

  /// Fires when this tab is on screen again (see `OnVisit`).
  final Stream<Visit>? visits;

  /// Hero prefix shared with the detail screen.
  static const heroPrefix = 'statement';

  @override
  Widget build(BuildContext context) {
    final dates = Modular.get<DateLabels>();
    return BlocProvider(
      create: (_) =>
          Modular.get<StatementBloc>()..add(const StatementStarted()),
      child: StatementView(
        visits: visits,
        money: Modular.get<MoneyFormatter>(),
        dates: dates,
        onOpenDetail: (id) => Modular.to.pushNamed(Routes.statementDetail(id)),
        openFilters: (context, current) => showFilterSheet(
          context,
          current: current,
          count: Modular.get<CountTransactions>(),
          dates: dates,
        ),
      ),
    );
  }
}

/// Public so widget tests can pump it with their own bloc and callbacks.
class StatementView extends StatefulWidget {
  const StatementView({
    super.key,
    required this.money,
    required this.dates,
    required this.onOpenDetail,
    required this.openFilters,
    this.visits,
  });

  /// Tab picked: back to the top. App back to the foreground: news, held
  /// behind the pill when the person is down the list.
  final Stream<Visit>? visits;
  final MoneyFormatter money;
  final DateLabels dates;
  final ValueChanged<String> onOpenDetail;
  final OpenFilters openFilters;

  @override
  State<StatementView> createState() => _StatementViewState();
}

class _StatementViewState extends State<StatementView> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  /// Within this distance of the top the list counts as "at the top".
  static const _topSlack = 48.0;

  /// How close to the end (in pixels) the next page starts loading, so
  /// the user rarely sees the footer skeleton.
  static const _prefetchDistance = 600.0;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _atTop => !_scroll.hasClients || _scroll.offset < _topSlack;

  void _onVisit(BuildContext context, Visit visit) {
    final bloc = context.read<StatementBloc>();
    switch (visit) {
      case Visit.tab:
        if (_scroll.hasClients) _scroll.jumpTo(0);
        bloc.add(const StatementTabOpened());
      case Visit.resume:
        bloc.add(StatementResumed(atTop: _atTop));
    }
  }

  void _showNew() {
    context.read<StatementBloc>().add(const StatementNewShown());
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final bloc = context.read<StatementBloc>();
    if (notification.metrics.extentAfter < _prefetchDistance) {
      bloc.add(const StatementNextPageRequested());
    }
    // Scrolled back to the top by hand: the news held back go in.
    if (notification.metrics.pixels < _topSlack && bloc.state.newOnTop > 0) {
      bloc.add(const StatementNewShown());
    }
    return false;
  }

  Future<void> _openFilters(TransactionFilter current) async {
    final applied = await widget.openFilters(context, current);
    if (applied != null && mounted) {
      context.read<StatementBloc>().add(StatementFilterChanged(applied));
    }
  }

  void _clearSearch() {
    _search.clear();
    context.read<StatementBloc>().add(const StatementQueryChanged(''));
    setState(() {});
  }

  void _setFilter(TransactionFilter filter) =>
      context.read<StatementBloc>().add(StatementFilterChanged(filter));

  @override
  Widget build(BuildContext context) =>
      OnVisit(visits: widget.visits, onVisit: _onVisit, child: _page(context));

  Widget _page(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    child: SafeArea(
      bottom: false,
      child: BlocBuilder<StatementBloc, StatementState>(
        builder: (context, state) => Column(
          children: [
            _header(context),
            _searchBar(context, state.filter),
            SizedBox(
              height: 3,
              child: state.reloading
                  ? const LinearProgressIndicator(minHeight: 3)
                  : null,
            ),
            _activeFilters(state.filter),
            Expanded(child: _body(context, state)),
          ],
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Extrato',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Exportar PDF',
          onPressed: () => showUnderConstruction(context, 'O PDF do extrato'),
          icon: const Icon(Icons.picture_as_pdf_outlined),
        ),
      ],
    ),
  );

  Widget _searchBar(BuildContext context, TransactionFilter filter) {
    final active = filter.activeCount - (filter.query.isEmpty ? 0 : 1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('statement.search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (text) {
                context.read<StatementBloc>().add(StatementQueryChanged(text));
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Buscar por descrição',
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
          ),
          const SizedBox(width: 4),
          IconButton(
            key: const Key('statement.filters'),
            tooltip: active == 0 ? 'Filtros' : 'Filtros, $active ativos',
            onPressed: () => _openFilters(filter),
            icon: Badge(
              isLabelVisible: active > 0,
              label: Text('$active'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeFilters(TransactionFilter filter) {
    final dates = widget.dates;
    final chips = <Widget>[
      if (filter.types.isNotEmpty)
        _chip(
          filter.types.length == 1
              ? (filter.types.first == TransactionType.income
                    ? 'Entradas'
                    : 'Saídas')
              : 'Entradas e saídas',
          () => _setFilter(filter.copyWith(types: {})),
        ),
      if (filter.statuses.isNotEmpty)
        _chip(
          TransactionStatus.values
              .where(filter.statuses.contains)
              .map(LedgerLabels.status)
              .toList()
              .join(', '),
          () => _setFilter(filter.copyWith(statuses: {})),
        ),
      if (filter.period case final period?)
        _chip(
          LedgerLabels.periodOf(period, dates),
          () => _setFilter(filter.copyWith(clearPeriod: true)),
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(spacing: 8, runSpacing: 4, children: chips),
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) => InputChip(
    label: Text(label),
    onDeleted: onRemove,
    deleteButtonTooltipMessage: 'Remover filtro $label',
  );

  Widget _body(BuildContext context, StatementState state) {
    final bloc = context.read<StatementBloc>();
    switch (state.status) {
      case StatementStatus.initial || StatementStatus.loading:
        return Semantics(
          label: 'Carregando extrato',
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 7; i++) ...[
                const Skeleton(height: 52),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      case StatementStatus.failure:
        return _Message(
          icon: state.failure is NoConnectionFailure
              ? Icons.wifi_off_rounded
              : Icons.cloud_off_rounded,
          text: failureMessage(
            state.failure ?? const UnexpectedFailure('unknown'),
          ),
          action: 'Tentar de novo',
          onAction: () => bloc.add(const StatementStarted()),
        );
      case StatementStatus.ready when state.items.isEmpty:
        final filtered = !state.filter.isEmpty;
        return _Message(
          key: const Key('statement.empty'),
          icon: filtered
              ? Icons.search_off_rounded
              : Icons.receipt_long_rounded,
          text: filtered
              ? 'Nada encontrado com esses filtros.'
              : 'Nenhuma movimentação ainda. Quando o dinheiro entrar ou '
                    'sair, aparece aqui.',
          action: filtered ? 'Limpar filtros' : null,
          onAction: filtered
              ? () {
                  _search.clear();
                  bloc.add(StatementFilterChanged(TransactionFilter.none));
                  bloc.add(const StatementQueryChanged(''));
                }
              : null,
        );
      case StatementStatus.ready:
        return NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator(
            onRefresh: () async {
              bloc.add(const StatementRefreshed());
              await bloc.stream.firstWhere((s) => !s.reloading);
            },
            child: Stack(
              children: [
                _list(context, state),
                if (state.newOnTop > 0)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _NewOnTopPill(state.newOnTop, _showNew),
                    ),
                  ),
              ],
            ),
          ),
        );
    }
  }

  Widget _list(BuildContext context, StatementState state) => CustomScrollView(
    // Keeps the scroll position when coming back from the detail.
    key: const PageStorageKey('statement.list'),
    controller: _scroll,
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      if (state.freshness case final freshness? when freshness.isStale)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: StaleBanner(
              freshness: freshness,
              dates: widget.dates,
              deviceOnly: state.fromDevice && !state.filter.isEmpty,
            ),
          ),
        ),
      for (final group in state.groups) ..._group(group),
      SliverToBoxAdapter(child: _footer(context, state)),
    ],
  );

  List<Widget> _group(DayGroup group) {
    final text = Theme.of(context).textTheme;
    final net = group.net;
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        sliver: SliverToBoxAdapter(
          child: Semantics(
            header: true,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.dates.dayHeader(group.date),
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.monte.subtle,
                    ),
                  ),
                ),
                Text(
                  widget.money.format(net, showPlusSign: true),
                  style: text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: net.isNegative
                        ? context.monte.expense
                        : (net.isPositive
                              ? context.monte.income
                              : context.monte.subtle),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverList.builder(
          itemCount: group.transactions.length,
          itemBuilder: (context, index) {
            final transaction = group.transactions[index];
            return TransactionTile(
              transaction: transaction,
              money: widget.money,
              dates: widget.dates,
              showDay: false,
              heroTagPrefix: StatementPage.heroPrefix,
              onTap: () => widget.onOpenDetail(transaction.id),
            );
          },
        ),
      ),
    ];
  }

  Widget _footer(BuildContext context, StatementState state) {
    final subtle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.monte.subtle);
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            Skeleton(height: 52),
            SizedBox(height: 12),
            Skeleton(height: 52),
          ],
        ),
      );
    }
    if (state.pageFailure case final failure?) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(failureMessage(failure), textAlign: TextAlign.center),
            TextButton(
              key: const Key('statement.retryPage'),
              onPressed: () => context.read<StatementBloc>().add(
                const StatementNextPageRequested(),
              ),
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      );
    }
    if (state.limitReached) {
      return Padding(
        key: const Key('statement.limit'),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          children: [
            Icon(Icons.manage_search_rounded, color: context.monte.subtle),
            const SizedBox(height: 6),
            Text(
              state.filter.isEmpty
                  ? 'Pra ver transações mais antigas, use a busca ou o '
                        'filtro de período.'
                  : 'Pra ver mais, refine a busca ou o filtro.',
              textAlign: TextAlign.center,
              style: subtle,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Text(
        state.hasMore ? '' : 'Isso é tudo por aqui.',
        textAlign: TextAlign.center,
        style: subtle,
      ),
    );
  }
}

/// "↑ 2 novas transações", floating at the top of the list while news wait
/// for the person to come back up.
class _NewOnTopPill extends StatelessWidget {
  const _NewOnTopPill(this.count, this.onTap);

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const Key('statement.newOnTop'),
      color: scheme.primary,
      elevation: 3,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: scheme.onPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                count == 1 ? '1 nova transação' : '$count novas transações',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: context.monte.subtle),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
