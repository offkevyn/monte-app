import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../core/money/money.dart';
import '../../../../core/money/money_formatter.dart';
import '../../../../core/theme/monte_theme.dart';
import '../../../../core/time/date_labels.dart';
import '../../../ledger/domain/services/period_summary.dart';

/// Income and expense bars per day (or per week on long periods).
///
/// Amounts stay in cents everywhere; they become `double` reais only here,
/// for the bar height, and the tooltip formats the original cents.
class MovementChart extends StatelessWidget {
  const MovementChart({
    super.key,
    required this.summary,
    required this.money,
    required this.dates,
    required this.hidden,
  });

  final PeriodSummary summary;
  final MoneyFormatter money;
  final DateLabels dates;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final colors = context.monte;
    final text = Theme.of(context).textTheme;
    final buckets = summary.buckets;
    final animate = !MediaQuery.disableAnimationsOf(context);

    String label(ChartBucket bucket) => dates.shortDate(bucket.span.first);

    return Semantics(
      label:
          'Gráfico de movimentação: entradas de '
          '${hidden ? 'valor oculto' : money.format(summary.totals.income)} e '
          'saídas de '
          '${hidden ? 'valor oculto' : money.format(summary.totals.expense)} '
          'em ${buckets.length} '
          '${summary.granularity == ChartGranularity.day ? 'dias' : 'semanas'}.',
      excludeSemantics: true,
      child: SizedBox(
        height: 170,
        child: SfCartesianChart(
          margin: EdgeInsets.zero,
          plotAreaBorderWidth: 0,
          primaryXAxis: CategoryAxis(
            majorGridLines: const MajorGridLines(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            axisLine: const AxisLine(width: 0),
            labelStyle: text.labelSmall?.copyWith(color: colors.subtle),
          ),
          primaryYAxis: const NumericAxis(isVisible: false),
          tooltipBehavior: TooltipBehavior(
            enable: !hidden,
            builder: (data, point, series, pointIndex, seriesIndex) {
              final bucket = data as ChartBucket;
              final value = seriesIndex == 0
                  ? bucket.totals.income
                  : bucket.totals.expense;
              return Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  '${seriesIndex == 0 ? 'Entradas' : 'Saídas'} · '
                  '${label(bucket)}\n${money.format(value)}',
                  style: text.labelSmall?.copyWith(color: Colors.white),
                ),
              );
            },
          ),
          series: [
            ColumnSeries<ChartBucket, String>(
              name: 'Entradas',
              dataSource: buckets,
              xValueMapper: (bucket, _) => label(bucket),
              yValueMapper: (bucket, _) => _reais(bucket.totals.income),
              color: colors.income,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              spacing: 0.15,
              animationDuration: animate ? 700 : 0,
            ),
            ColumnSeries<ChartBucket, String>(
              name: 'Saídas',
              dataSource: buckets,
              xValueMapper: (bucket, _) => label(bucket),
              yValueMapper: (bucket, _) => _reais(bucket.totals.expense),
              color: colors.expense,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              spacing: 0.15,
              animationDuration: animate ? 700 : 0,
            ),
          ],
        ),
      ),
    );
  }

  /// Bar height only; never used for arithmetic or display.
  static double _reais(Money amount) => amount.cents / 100;
}
