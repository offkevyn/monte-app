import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../../../core/theme/monte_theme.dart';
import '../../../core/time/date_labels.dart';
import '../../../core/time/local_date.dart';
import '../../ledger/domain/entities/date_span.dart';
import '../../ledger/domain/entities/transaction.dart';
import '../../ledger/domain/entities/transaction_filter.dart';
import '../../ledger/domain/usecases/get_statement_page.dart';
import '../../ledger/presentation/ledger_labels.dart';

final class FilterSheetState extends Equatable {
  const FilterSheetState({required this.draft, this.count});

  /// Filters being edited; only applied when the user confirms.
  final TransactionFilter draft;

  /// How many transactions the draft would show; `null` while counting.
  final int? count;

  @override
  List<Object?> get props => [draft, count];
}

/// ViewModel of the filter sheet: edits a draft and keeps the count of the
/// "Ver N transações" button up to date.
class FilterSheetCubit extends Cubit<FilterSheetState> {
  FilterSheetCubit(this._count, TransactionFilter initial)
    : super(FilterSheetState(draft: initial)) {
    _recount();
  }

  final CountTransactions _count;
  var _countRequest = 0;

  /// `null` means all types.
  void setType(TransactionType? type) =>
      _update(state.draft.copyWith(types: type == null ? {} : {type}));

  void toggleStatus(TransactionStatus status) {
    final statuses = {...state.draft.statuses};
    if (!statuses.remove(status)) statuses.add(status);
    _update(state.draft.copyWith(statuses: statuses));
  }

  /// `null` means all time.
  void setPeriod(DateSpan? period) => _update(
    period == null
        ? state.draft.copyWith(clearPeriod: true)
        : state.draft.copyWith(period: period),
  );

  /// "Limpar": everything except the search text, which has its own field.
  void clear() => _update(TransactionFilter(query: state.draft.query));

  void _update(TransactionFilter draft) {
    emit(FilterSheetState(draft: draft));
    _recount();
  }

  Future<void> _recount() async {
    // Only the answer for the latest draft is shown.
    final request = ++_countRequest;
    final draft = state.draft;
    final result = await _count(draft);
    if (isClosed || request != _countRequest) return;
    if (result case Ok(value: final count)) {
      emit(FilterSheetState(draft: draft, count: count));
    }
  }
}

/// Opens the sheet and returns the filter the user applied, or `null` when
/// dismissed.
Future<TransactionFilter?> showFilterSheet(
  BuildContext context, {
  required TransactionFilter current,
  required CountTransactions count,
  required DateLabels dates,
}) => showModalBottomSheet<TransactionFilter>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => BlocProvider(
    create: (_) => FilterSheetCubit(count, current),
    child: FilterSheetView(dates: dates),
  ),
);

/// Public so widget tests can pump it with their own cubit.
class FilterSheetView extends StatelessWidget {
  const FilterSheetView({super.key, required this.dates});

  final DateLabels dates;

  static const _presets = [
    PeriodPreset.last7Days,
    PeriodPreset.last30Days,
    PeriodPreset.last90Days,
  ];

  Future<void> _pickCustom(BuildContext context, FilterSheetCubit cubit) async {
    final today = dates.today;
    DateTime asDate(LocalDate d) => DateTime(d.year, d.month, d.day);
    final current = cubit.state.draft.period;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: asDate(today.addDays(-730)),
      lastDate: asDate(today),
      initialDateRange: current == null
          ? null
          : DateTimeRange(
              start: asDate(current.first),
              end: asDate(current.last),
            ),
      helpText: 'Escolha o período',
      saveText: 'Aplicar',
    );
    if (picked == null) return;
    cubit.setPeriod(
      DateSpan(
        LocalDate(picked.start.year, picked.start.month, picked.start.day),
        LocalDate(picked.end.year, picked.end.month, picked.end.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return BlocBuilder<FilterSheetCubit, FilterSheetState>(
      builder: (context, state) {
        final cubit = context.read<FilterSheetCubit>();
        final draft = state.draft;
        final type = draft.types.length == 1 ? draft.types.first : null;
        final period = draft.period;
        final preset = period == null
            ? null
            : _presets
                  .where((p) => p.resolve(dates.today) == period)
                  .firstOrNull;
        final custom = period != null && preset == null;

        Widget title(String label) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Semantics(
            header: true,
            child: Text(
              label,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filtrar',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('filters.clear'),
                      onPressed: cubit.clear,
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
                title('Tipo'),
                SegmentedButton<TransactionType?>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: null, label: Text('Todas')),
                    ButtonSegment(
                      value: TransactionType.income,
                      icon: Icon(Icons.south_west_rounded, size: 16),
                      label: Text('Entradas'),
                    ),
                    ButtonSegment(
                      value: TransactionType.expense,
                      icon: Icon(Icons.north_east_rounded, size: 16),
                      label: Text('Saídas'),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (selection) =>
                      cubit.setType(selection.first),
                ),
                title('Status'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in TransactionStatus.values)
                      FilterChip(
                        label: Text(LedgerLabels.status(status)),
                        selected: draft.statuses.contains(status),
                        onSelected: (_) => cubit.toggleStatus(status),
                      ),
                  ],
                ),
                title('Período'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tudo'),
                      selected: period == null,
                      onSelected: (_) => cubit.setPeriod(null),
                    ),
                    for (final p in _presets)
                      ChoiceChip(
                        label: Text(LedgerLabels.periodShort(p, dates)),
                        selected: preset == p,
                        onSelected: (_) =>
                            cubit.setPeriod(p.resolve(dates.today)),
                      ),
                    ChoiceChip(
                      key: const Key('filters.custom'),
                      avatar: const Icon(Icons.date_range_rounded, size: 18),
                      label: const Text('Personalizado'),
                      selected: custom,
                      onSelected: (_) => _pickCustom(context, cubit),
                    ),
                  ],
                ),
                if (period != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'De ${dates.fullDate(period.first)} '
                      'até ${dates.fullDate(period.last)}',
                      style: text.bodySmall?.copyWith(
                        color: context.monte.subtle,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('filters.apply'),
                  onPressed: () => Navigator.of(context).pop(draft),
                  child: Text(switch (state.count) {
                    null => 'Ver transações',
                    0 => 'Nenhuma transação',
                    1 => 'Ver 1 transação',
                    final n => 'Ver $n transações',
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
