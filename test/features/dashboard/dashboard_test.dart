import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/freshness/data_freshness.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/money/money_formatter.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/storage/app_preferences.dart';
import 'package:monte/core/theme/monte_theme.dart';
import 'package:monte/core/theme/theme_controller.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/core/time/date_labels.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/dashboard/presentation/dashboard_cubit.dart';
import 'package:monte/features/dashboard/presentation/dashboard_page.dart';
import 'package:monte/features/ledger/domain/entities/dashboard_snapshot.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/usecases/get_dashboard.dart';

import '../../helpers/transactions.dart';
import '../auth/presentation/auth_cubits_test.dart' show FakeBiometrics;
import '../ledger/domain/usecases/usecases_test.dart' show FakeLedgerRepository;

void main() {
  const calendar = FixedOffsetCalendar.brasilia;
  // Thursday 05/11/2026, 14:00 in Brasília.
  final clock = FixedClock(DateTime.utc(2026, 11, 5, 17));
  final dates = DateLabels(clock, calendar);
  final money = MoneyFormatter();

  late FakeLedgerRepository repository;
  late MemoryAppPreferences preferences;
  late FakeBiometrics biometrics;

  final thisMonth = DateSpan(LocalDate(2026, 11, 1), LocalDate(2026, 11, 5));

  DashboardSnapshot snapshot({
    Failure? syncFailure,
    DateSpan? period,
    bool wholePeriod = true,
  }) {
    final transactions = [
      tx(
        id: 'salary',
        type: TransactionType.income,
        cents: 500000,
        description: 'Salário',
        at: DateTime.utc(2026, 11, 5, 12),
      ),
      expense(12990, id: 'market', at: DateTime.utc(2026, 11, 4, 12)),
      expense(
        7269,
        id: 'pending',
        at: DateTime.utc(2026, 11, 5, 13),
        status: TransactionStatus.pending,
      ),
    ];
    return DashboardSnapshot(
      // 1000 + 5000 - 129,90 settled by the server.
      settledBalance: const Money.cents(587010),
      pendingDebits: [transactions.last],
      recent: transactions,
      period: period ?? thisMonth,
      periodTransactions: wholePeriod ? transactions : null,
      freshness: DataFreshness(
        syncedAt: DateTime.utc(2026, 11, 5, 17, 32),
        syncFailure: syncFailure,
      ),
    );
  }

  List<bool> calls() => [for (final c in repository.dashboardCalls) c.force];

  DashboardCubit buildCubit() => DashboardCubit(
    GetDashboard(repository, clock, calendar),
    preferences,
    biometrics,
  );

  setUp(() {
    repository = FakeLedgerRepository()
      ..dashboardFor = ((period) => Ok(snapshot(period: period)));
    preferences = MemoryAppPreferences();
    biometrics = FakeBiometrics();
  });

  group('DashboardCubit', () {
    test('loads balance and totals of this month', () async {
      final cubit = buildCubit();
      await cubit.load();

      expect(cubit.state.status, DashboardStatus.ready);
      final summary = cubit.state.summary!;
      // 1000 + 5000 - 129,90 completed, minus 72,69 reserved.
      expect(summary.balance.available, const Money.cents(587010 - 7269));
      expect(summary.summary!.totals.income, const Money.cents(500000));
      expect(calls(), [false]);
    });

    test('hidden balance comes back from preferences', () async {
      preferences.hidden = true;
      final cubit = buildCubit();
      await cubit.load();
      expect(cubit.state.balanceHidden, isTrue);
    });

    test('toggling saves the choice', () async {
      final cubit = buildCubit();
      await cubit.load();
      await cubit.toggleBalance();
      expect(cubit.state.balanceHidden, isTrue);
      expect(preferences.hidden, isTrue);
      await cubit.toggleBalance();
      expect(preferences.hidden, isFalse);
    });

    test('revealing asks for the fingerprint when turned on', () async {
      preferences
        ..hidden = true
        ..balanceBiometrics = true;
      biometrics.confirms = false;
      final cubit = buildCubit();
      await cubit.load();

      await cubit.toggleBalance();
      expect(cubit.state.balanceHidden, isTrue, reason: 'refused');

      biometrics.confirms = true;
      await cubit.toggleBalance();
      expect(cubit.state.balanceHidden, isFalse);
      expect(biometrics.reasons, hasLength(2));

      // Hiding never asks.
      await cubit.toggleBalance();
      expect(biometrics.reasons, hasLength(2));
    });

    test('changing the period asks the server for that period', () async {
      final cubit = buildCubit();
      await cubit.load();
      await cubit.selectPeriod(PeriodPreset.last7Days);
      expect(cubit.state.preset, PeriodPreset.last7Days);
      expect(cubit.state.summary!.summary!.buckets, hasLength(7));
      expect(calls(), [false, false]);

      await cubit.selectPeriod(PeriodPreset.last7Days);
      expect(calls(), hasLength(2), reason: 'same period');
    });

    test('pull to refresh forces the server; a visit does not', () async {
      final cubit = buildCubit();
      await cubit.load();
      await cubit.refresh();
      await cubit.refreshIfNeeded();
      expect(calls(), [false, true, false]);
      expect(cubit.state.refreshing, isFalse);
    });

    test('what is saved shows before the server answers', () async {
      repository
        ..savedDashboardResult = Ok(snapshot())
        ..serverGate = Completer<void>();
      final cubit = buildCubit();
      final loading = cubit.load();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, DashboardStatus.ready);
      expect(cubit.state.refreshing, isTrue, reason: 'thin bar on top');

      repository.serverGate!.complete();
      await loading;
      expect(cubit.state.refreshing, isFalse);
    });

    test('offline without the whole period: balance but no totals', () async {
      repository.dashboardFor = (period) => Ok(
        snapshot(
          period: period,
          wholePeriod: false,
          syncFailure: const NoConnectionFailure(),
        ),
      );
      final cubit = buildCubit();
      await cubit.load();
      expect(cubit.state.summary!.summary, isNull);
      expect(
        cubit.state.summary!.balance.available,
        const Money.cents(587010 - 7269),
      );
    });

    test('first load failing shows the error; retry recovers', () async {
      repository.dashboardFor = (_) => const Err(NoConnectionFailure());
      final cubit = buildCubit();
      await cubit.load();
      expect(cubit.state.status, DashboardStatus.failure);
      expect(cubit.state.failure, const NoConnectionFailure());

      repository.dashboardFor = (period) => Ok(snapshot(period: period));
      await cubit.load();
      expect(cubit.state.status, DashboardStatus.ready);
      expect(cubit.state.failure, isNull);
    });

    test('a failed refresh keeps the data on screen', () async {
      final cubit = buildCubit();
      await cubit.load();
      repository.dashboardFor = (_) =>
          const Err(ServerFailure(statusCode: 500));
      await cubit.refresh();
      expect(cubit.state.status, DashboardStatus.ready);
      expect(cubit.state.summary, isNotNull);
    });

    test('a cancelled load changes nothing', () async {
      final cubit = buildCubit();
      await cubit.load();
      repository.dashboardFor = (_) => const Err(CancelledFailure());
      await cubit.refresh();
      expect(cubit.state.failure, isNull);
      expect(cubit.state.status, DashboardStatus.ready);
    });
  });

  group('DashboardView', () {
    late int statementOpened;
    late int cryptoOpened;

    Future<DashboardCubit> pump(WidgetTester tester) async {
      statementOpened = 0;
      cryptoOpened = 0;
      final cubit = buildCubit();
      await cubit.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: MonteTheme.light,
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: DashboardView(
                customerName: 'Kevyn Melo',
                money: money,
                dates: dates,
                theme: ThemeController(preferences),
                onOpenStatement: () => statementOpened++,
                onOpenCrypto: () => cryptoOpened++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return cubit;
    }

    testWidgets('shows greeting, balance, pending note and totals', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Boa tarde,'), findsOneWidget);
      expect(find.text('Kevyn'), findsOneWidget);
      expect(find.text('KM'), findsOneWidget);
      expect(
        find.text(money.format(const Money.cents(579741))),
        findsOneWidget,
      );
      expect(
        find.textContaining('reservados em compras pendentes'),
        findsOneWidget,
      );
      expect(find.text('Entradas · nov'), findsOneWidget);
      expect(find.text('Saídas · nov'), findsOneWidget);
      expect(find.text('Novembro'), findsOneWidget);
    });

    testWidgets('eye hides the values for screen readers too', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('dashboard.eye')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('oculto')), findsWidgets);
      expect(find.byTooltip('Mostrar saldo'), findsOneWidget);
    });

    testWidgets('shortcuts: real ones navigate, the others say soon', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.bySemanticsLabel('Extrato'));
      await tester.tap(find.bySemanticsLabel('Cripto'));
      expect(statementOpened, 1);
      expect(cryptoOpened, 1);

      await tester.tap(find.bySemanticsLabel('Pix'));
      await tester.pumpAndSettle();
      expect(find.text('O Pix tá subindo o morro 🏔'), findsOneWidget);
    });

    testWidgets('"Ver extrato" opens the statement', (tester) async {
      await pump(tester);
      await tester.scrollUntilVisible(
        find.text('Ver extrato ›'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Ver extrato ›'));
      expect(statementOpened, 1);
    });

    testWidgets('period picker changes the chart period', (tester) async {
      final cubit = await pump(tester);
      await tester.tap(find.byKey(const Key('dashboard.period')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Últimos 7 dias').last);
      await tester.pumpAndSettle();
      expect(cubit.state.preset, PeriodPreset.last7Days);
      expect(find.text('Entradas · 7 dias'), findsOneWidget);
    });

    testWidgets('stale data shows the yellow strip with the time', (
      tester,
    ) async {
      repository.dashboardFor = (_) =>
          Ok(snapshot(syncFailure: const NoConnectionFailure()));
      await pump(tester);
      expect(
        find.text('Sem conexão. Mostrando dados de hoje, 14:32.'),
        findsOneWidget,
      );
    });

    testWidgets('offline without the period: a note instead of totals', (
      tester,
    ) async {
      repository.dashboardFor = (period) => Ok(
        snapshot(
          period: period,
          wholePeriod: false,
          syncFailure: const NoConnectionFailure(),
        ),
      );
      await pump(tester);
      expect(find.byKey(const Key('dashboard.periodOffline')), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('lists the latest transactions with direction and sign', (
      tester,
    ) async {
      await pump(tester);
      await tester.scrollUntilVisible(
        find.text('Salário'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('+R\$ 5.000,00'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Entrada, Salário, R\$')),
        findsOneWidget,
      );
    });

    testWidgets('error screen with retry', (tester) async {
      repository.dashboardFor = (_) => const Err(NoConnectionFailure());
      final cubit = await pump(tester);
      expect(find.byKey(const Key('dashboard.error')), findsOneWidget);

      repository.dashboardFor = (period) => Ok(snapshot(period: period));
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();
      expect(cubit.state.status, DashboardStatus.ready);
    });

    testWidgets('error screen keeps the greeting on the green top', (
      tester,
    ) async {
      repository.dashboardFor = (_) => const Err(NoConnectionFailure());
      await pump(tester);
      final green = tester.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_MountainsPainter',
        ),
      );
      final name = tester.getRect(find.text('Kevyn'));
      expect(green.top <= name.top && name.bottom <= green.bottom, isTrue);
    });

    testWidgets('empty account explains instead of showing a blank list', (
      tester,
    ) async {
      repository.dashboardFor = (period) => Ok(
        DashboardSnapshot(
          settledBalance: Money.zero,
          pendingDebits: const [],
          recent: const [],
          period: period,
          periodTransactions: const [],
          freshness: DataFreshness(syncedAt: DateTime.utc(2026, 11, 5)),
        ),
      );
      await pump(tester);
      await tester.scrollUntilVisible(
        find.textContaining('Nenhuma movimentação'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Nenhuma movimentação'), findsOneWidget);
    });
  });
}
