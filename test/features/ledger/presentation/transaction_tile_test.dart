import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money_formatter.dart';
import 'package:monte/core/theme/monte_theme.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/core/time/date_labels.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/presentation/ledger_labels.dart';
import 'package:monte/features/ledger/presentation/widgets/transaction_tile.dart';

import '../../../helpers/transactions.dart';

void main() {
  final dates = DateLabels(
    FixedClock(DateTime.utc(2026, 11, 5, 17)),
    FixedOffsetCalendar.brasilia,
  );

  Future<void> pump(
    WidgetTester tester,
    Transaction transaction, {
    bool hidden = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: MonteTheme.light,
      home: Scaffold(
        body: TransactionTile(
          transaction: transaction,
          money: MoneyFormatter(),
          dates: dates,
          hidden: hidden,
          onTap: () {},
        ),
      ),
    ),
  );

  testWidgets('income: arrow, plus sign and who sent it', (tester) async {
    await pump(
      tester,
      tx(
        type: TransactionType.income,
        cents: 120000,
        description: 'Pix recebido',
        counterparty: 'Ana Souza',
        category: TransactionCategory.transfer,
        at: DateTime.utc(2026, 11, 5, 17, 32),
      ),
    );
    expect(find.text('Pix recebido · Ana Souza'), findsOneWidget);
    expect(find.text('+R\$ 1.200,00'), findsOneWidget);
    expect(find.text('Hoje · 14:32'), findsOneWidget);
    expect(find.byIcon(Icons.south_west_rounded), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('^Entrada, Pix recebido · Ana Souza, .*Concluída'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('failed expense is struck through and says why', (tester) async {
    await pump(tester, tx(status: TransactionStatus.failed));
    expect(find.text('Falhou'), findsOneWidget);
    final amount = tester.widget<Text>(find.textContaining('R\$'));
    expect(amount.style?.decoration, TextDecoration.lineThrough);
    expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
  });

  testWidgets('hidden balance hides the amount from screen readers', (
    tester,
  ) async {
    await pump(tester, tx(), hidden: true);
    expect(find.bySemanticsLabel(RegExp('valor oculto')), findsOneWidget);
  });

  test('labels cover every value in Portuguese', () {
    for (final status in TransactionStatus.values) {
      expect(LedgerLabels.status(status), isNotEmpty);
    }
    for (final category in TransactionCategory.values) {
      expect(LedgerLabels.category(category), isNotEmpty);
    }
    for (final method in PaymentMethod.values) {
      expect(LedgerLabels.method(method), isNotEmpty);
    }
    expect(LedgerLabels.type(TransactionType.expense), 'Saída');
    expect(LedgerLabels.periodTitle(PeriodPreset.lastMonth, dates), 'Outubro');
    expect(LedgerLabels.periodShort(PeriodPreset.lastMonth, dates), 'out');
    expect(
      LedgerLabels.periodTitle(PeriodPreset.last90Days, dates),
      'Últimos 90 dias',
    );
    expect(LedgerLabels.periodShort(PeriodPreset.last30Days, dates), '30 dias');
  });
}
