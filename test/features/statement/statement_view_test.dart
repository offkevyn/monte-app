import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/money/money_formatter.dart';
import 'package:monte/core/theme/monte_theme.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/core/time/date_labels.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/entities/transaction_filter.dart';
import 'package:monte/features/ledger/domain/usecases/get_statement_page.dart';
import 'package:monte/features/ledger/domain/usecases/get_transaction_detail.dart';
import 'package:monte/features/statement/presentation/bloc/statement_bloc.dart';
import 'package:monte/features/statement/presentation/detail/transaction_detail_cubit.dart';
import 'package:monte/features/statement/presentation/detail/transaction_detail_page.dart';
import 'package:monte/features/statement/presentation/filter_sheet.dart';
import 'package:monte/features/statement/presentation/statement_page.dart';

import '../../helpers/memory_ledger_repository.dart';
import '../../helpers/transactions.dart';

void main() {
  const calendar = FixedOffsetCalendar.brasilia;
  // Thursday 05/11/2026, 14:00 in Brasília.
  final dates = DateLabels(FixedClock(DateTime.utc(2026, 11, 5, 17)), calendar);
  final money = MoneyFormatter();

  /// 45 transactions, one per hour going back from 05/11 14:00 local.
  List<Transaction> manyTransactions() => [
    for (var i = 0; i < 45; i++)
      tx(
        id: 'tx_$i',
        type: i.isEven ? TransactionType.expense : TransactionType.income,
        description: i == 3 ? 'Café da Padaria' : 'Mercado $i',
        status: i == 5 ? TransactionStatus.failed : TransactionStatus.completed,
        cents: 1000 + i,
        at: DateTime.utc(2026, 11, 5, 17).subtract(Duration(hours: i * 3)),
      ),
  ];

  group('StatementView', () {
    late MemoryLedgerRepository repository;
    late List<String> opened;
    TransactionFilter? sheetAnswer;

    Future<StatementBloc> pump(WidgetTester tester) async {
      opened = [];
      final bloc = StatementBloc(
        GetStatementPage(repository),
        RefreshLedger(repository),
        calendar,
        debounce: const Duration(milliseconds: 50),
      )..add(const StatementStarted());
      // The provider owns the bloc, like in the app. Awaiting close() here
      // would hang: under the fake clock of widget tests, cancelling the
      // debounce transformer never completes (it does in real time, see
      // statement_bloc_test).
      await tester.pumpWidget(
        MaterialApp(
          theme: MonteTheme.light,
          home: Scaffold(
            body: BlocProvider(
              create: (_) => bloc,
              child: StatementView(
                money: money,
                dates: dates,
                onOpenDetail: opened.add,
                openFilters: (_, _) async => sheetAnswer,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return bloc;
    }

    setUp(() {
      repository = MemoryLedgerRepository(manyTransactions());
      sheetAnswer = null;
    });

    testWidgets('groups by day with the day total and opens a detail', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Hoje · 5 de nov'), findsOneWidget);
      expect(find.textContaining('· Pix'), findsWidgets);

      await tester.tap(find.text('Mercado 0'));
      expect(opened, ['tx_0']);
    });

    testWidgets('search waits for a pause, then filters', (tester) async {
      final bloc = await pump(tester);
      await tester.enterText(find.byKey(const Key('statement.search')), 'cafe');
      await tester.pump(const Duration(milliseconds: 20));
      expect(bloc.state.filter.query, isEmpty, reason: 'still debouncing');

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Café da Padaria'), findsOneWidget);
      expect(find.text('Mercado 0'), findsNothing);

      await tester.tap(find.byTooltip('Limpar busca'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Mercado 0'), findsOneWidget);
    });

    testWidgets('scrolling to the end loads every page once', (tester) async {
      final bloc = await pump(tester);
      expect(bloc.state.items, hasLength(20));

      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pumpAndSettle();
      }
      expect(bloc.state.items, hasLength(45));
      expect(bloc.state.items.map((t) => t.id).toSet(), hasLength(45));
      expect(find.text('Isso é tudo por aqui.'), findsOneWidget);
    });

    testWidgets('filters from the sheet become removable chips', (
      tester,
    ) async {
      // tx_5 is the only failed one, and it is an income.
      sheetAnswer = TransactionFilter(
        types: {TransactionType.income},
        statuses: {TransactionStatus.failed},
        period: PeriodPreset.last30Days.resolve(LocalDate(2026, 11, 5)),
      );
      final bloc = await pump(tester);

      await tester.tap(find.byKey(const Key('statement.filters')));
      await tester.pumpAndSettle();
      expect(find.text('Entradas'), findsOneWidget);
      expect(find.text('Falhou'), findsWidgets);
      expect(find.text('Últimos 30 dias'), findsOneWidget);
      expect(find.byTooltip('Filtros, 3 ativos'), findsOneWidget);
      expect(bloc.state.items.single.id, 'tx_5');

      await tester.tap(find.byTooltip('Remover filtro Falhou'));
      await tester.pumpAndSettle();
      expect(bloc.state.filter.statuses, isEmpty);
      expect(bloc.state.filter.types, {TransactionType.income});
    });

    testWidgets('no result explains and offers to clear', (tester) async {
      sheetAnswer = TransactionFilter(
        period: DateSpan.singleDay(LocalDate(2020, 1, 1)),
      );
      await pump(tester);
      await tester.tap(find.byKey(const Key('statement.filters')));
      await tester.pumpAndSettle();
      expect(find.text('Nada encontrado com esses filtros.'), findsOneWidget);

      await tester.tap(find.text('Limpar filtros'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Mercado 0'), findsOneWidget);
    });

    testWidgets('empty account shows its own message', (tester) async {
      repository = MemoryLedgerRepository(const []);
      await pump(tester);
      expect(find.textContaining('Nenhuma movimentação ainda'), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      repository.failWith = const NoConnectionFailure();
      await pump(tester);
      expect(find.text('Tentar de novo'), findsOneWidget);

      repository.failWith = null;
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();
      expect(find.text('Mercado 0'), findsOneWidget);
    });

    testWidgets('PDF says it is coming soon', (tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('Exportar PDF'));
      await tester.pumpAndSettle();
      expect(find.textContaining('subindo o morro'), findsOneWidget);
    });
  });

  group('Filter sheet', () {
    late MemoryLedgerRepository repository;

    setUp(() => repository = MemoryLedgerRepository(manyTransactions()));

    test('cubit edits a draft and keeps the count updated', () async {
      final cubit = FilterSheetCubit(
        CountTransactions(repository),
        TransactionFilter(query: 'mercado'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.count, 44);

      cubit.setType(TransactionType.income);
      await Future<void>.delayed(Duration.zero);
      // 22 incomes, minus tx_3 (the café, not a "mercado").
      expect(cubit.state.count, 21);

      cubit
        ..toggleStatus(TransactionStatus.failed)
        ..toggleStatus(TransactionStatus.failed);
      expect(cubit.state.draft.statuses, isEmpty);

      cubit.setPeriod(DateSpan.singleDay(LocalDate(2026, 11, 5)));
      expect(cubit.state.draft.period, isNotNull);
      cubit.setPeriod(null);
      expect(cubit.state.draft.period, isNull);

      cubit.clear();
      expect(cubit.state.draft, TransactionFilter(query: 'mercado'));
      await cubit.close();
    });

    testWidgets('picks type, status and period and returns them', (
      tester,
    ) async {
      TransactionFilter? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: MonteTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showFilterSheet(
                context,
                current: TransactionFilter.none,
                count: CountTransactions(repository),
                dates: dates,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Ver 45 transações'), findsOneWidget);

      await tester.tap(find.text('Saídas'));
      await tester.tap(find.text('Falhou'));
      await tester.tap(find.text('7 dias'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('De 30/10/2026 até 05/11/2026'),
        findsOneWidget,
      );
      expect(find.text('Nenhuma transação'), findsOneWidget);

      await tester.tap(find.byKey(const Key('filters.apply')));
      await tester.pumpAndSettle();
      expect(result!.types, {TransactionType.expense});
      expect(result!.statuses, {TransactionStatus.failed});
      expect(result!.period!.lengthInDays, 7);
    });
  });

  group('Transaction detail', () {
    late MemoryLedgerRepository repository;
    final pix = tx(
      id: 'tx_19bd5a2c77a0',
      type: TransactionType.income,
      cents: 120000,
      description: 'Pix recebido',
      counterparty: 'Ana Souza',
      category: TransactionCategory.transfer,
      at: DateTime.utc(2026, 11, 5, 17, 32),
    );
    final pendingCard = Transaction(
      id: 'tx_8f3a00000c21e',
      description: 'Supermercado Serra Azul',
      amount: const Money.cents(25430),
      type: TransactionType.expense,
      status: TransactionStatus.pending,
      occurredAt: DateTime.utc(2026, 11, 4, 22, 47),
      method: PaymentMethod.creditCard,
      category: TransactionCategory.groceries,
      cardLastDigits: '4821',
    );

    Future<void> pump(WidgetTester tester, String id) async {
      final cubit = TransactionDetailCubit(GetTransactionDetail(repository));
      unawaited(cubit.load(id));
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: MonteTheme.light,
          home: BlocProvider.value(
            value: cubit,
            child: TransactionDetailView(id: id, money: money, dates: dates),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() => repository = MemoryLedgerRepository([pix, pendingCard]));

    testWidgets('income: who sent it, type, method and short id', (
      tester,
    ) async {
      await pump(tester, pix.id);
      expect(find.text('Entrada · Pix'), findsOneWidget);
      expect(find.text('+R\$ 1.200,00'), findsOneWidget);
      expect(find.text('Concluída'), findsOneWidget);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('05/11/2026 · 14:32'), findsOneWidget);
      expect(find.text('↓ Entrada (crédito)'), findsOneWidget);
      expect(find.text('tx_19bd…77a0'), findsOneWidget);
    });

    testWidgets('pending card purchase explains the reservation', (
      tester,
    ) async {
      await pump(tester, pendingCard.id);
      expect(find.text('Crédito · final 4821'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
      expect(
        find.textContaining('pendentes até a confirmação'),
        findsOneWidget,
      );
      expect(find.text('04/11/2026 · 19:47'), findsOneWidget);
    });

    testWidgets('copies the full id and confirms', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      await pump(tester, pix.id);
      await tester.tap(find.byKey(const Key('detail.copy')));
      await tester.pumpAndSettle();
      expect(copied, pix.id);
      expect(find.text('✓ Identificador copiado'), findsOneWidget);
    });

    testWidgets('unknown id says so, without a retry', (tester) async {
      await pump(tester, 'tx_nope');
      expect(find.text('Não encontramos essa transação.'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);
    });

    testWidgets('other failures can retry', (tester) async {
      repository.failWith = const NoConnectionFailure();
      await pump(tester, pix.id);
      expect(find.text('Tentar de novo'), findsOneWidget);
      repository.failWith = null;
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Souza'), findsOneWidget);
    });

    testWidgets('support and receipt are coming soon', (tester) async {
      await pump(tester, pix.id);
      await tester.scrollUntilVisible(
        find.byKey(const Key('detail.support')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('detail.support')));
      await tester.pumpAndSettle();
      expect(find.text('O suporte tá subindo o morro 🏔'), findsOneWidget);
    });
  });
}
