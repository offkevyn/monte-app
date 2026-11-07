import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/async/cancel_signal.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/freshness/data_freshness.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/domain/entities/dashboard_snapshot.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/entities/transaction_filter.dart';
import 'package:monte/features/ledger/domain/entities/transaction_page.dart';
import 'package:monte/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:monte/features/ledger/domain/usecases/get_dashboard.dart';
import 'package:monte/features/ledger/domain/usecases/get_statement_page.dart';
import 'package:monte/features/ledger/domain/usecases/get_transaction_detail.dart';

import '../../../../helpers/transactions.dart';

/// Hand-written fake: records calls and answers with whatever the test set.
class FakeLedgerRepository implements LedgerRepository {
  Result<DashboardSnapshot>? dashboard;

  /// When set, [refreshDashboard] waits for it, like a slow server.
  Completer<void>? serverGate;

  /// When set, answers [refreshDashboard] for the period asked.
  Result<DashboardSnapshot> Function(DateSpan period)? dashboardFor;
  Result<DashboardSnapshot?> savedDashboardResult = const Ok(null);
  Result<TransactionPage>? page;
  Result<Transaction>? detail;
  Result<Transaction?> savedDetail = const Ok(null);

  final dashboardCalls = <({DateSpan period, bool force})>[];
  final pageCalls = <TransactionQuery>[];
  final detailCalls = <String>[];

  @override
  Future<Result<DashboardSnapshot?>> savedDashboard(DateSpan period) async =>
      savedDashboardResult;

  @override
  Future<Result<DashboardSnapshot>> refreshDashboard(
    DateSpan period, {
    bool force = false,
  }) async {
    dashboardCalls.add((period: period, force: force));
    await serverGate?.future;
    return dashboardFor?.call(period) ?? dashboard!;
  }

  @override
  Future<Result<TransactionPage>> getPage(
    TransactionQuery query, {
    bool force = false,
    CancelSignal? cancel,
  }) async {
    pageCalls.add(query);
    return page!;
  }

  @override
  Future<Result<TransactionPage?>> savedFirstPage(
    TransactionFilter filter,
  ) async => const Ok(null);

  @override
  Future<Result<Transaction?>> savedTransaction(String id) async {
    detailCalls.add('saved:$id');
    return savedDetail;
  }

  @override
  Future<Result<Transaction>> refreshTransaction(String id) async {
    detailCalls.add(id);
    return detail!;
  }

  Result<int> count = const Ok(0);
  final countCalls = <TransactionFilter>[];

  @override
  Future<Result<int>> countTransactions(
    TransactionFilter filter, {
    CancelSignal? cancel,
  }) async {
    countCalls.add(filter);
    return count;
  }

  @override
  void expireRecentFetches() {}

  @override
  Future<void> clear() async {}
}

void main() {
  late FakeLedgerRepository repository;
  final freshness = DataFreshness(
    syncedAt: DateTime.utc(2026, 11, 5, 12),
    syncFailure: const NoConnectionFailure(),
  );

  setUp(() => repository = FakeLedgerRepository());

  group('GetDashboard', () {
    // 05/11/2026 23:30 in Brasília: still the 5th for the user.
    final clock = FixedClock(DateTime.utc(2026, 11, 6, 2, 30));
    late GetDashboard getDashboard;

    setUp(() {
      getDashboard = GetDashboard(
        repository,
        clock,
        FixedOffsetCalendar.brasilia,
      );
    });

    DashboardSnapshot snapshot({
      int settled = 0,
      List<Transaction> pending = const [],
      List<Transaction> recent = const [],
      List<Transaction>? inPeriod = const [],
      DateSpan? period,
    }) => DashboardSnapshot(
      settledBalance: Money.cents(settled),
      pendingDebits: pending,
      recent: recent,
      period:
          period ?? DateSpan(LocalDate(2026, 11, 1), LocalDate(2026, 11, 5)),
      periodTransactions: inPeriod,
      freshness: freshness,
    );

    test('balance from the server, rules and totals from the domain', () async {
      final days = [
        for (var day = 1; day <= 5; day++)
          expense(1000, id: 'd$day', at: DateTime.utc(2026, 11, day, 15)),
      ];
      repository.dashboard = Ok(
        snapshot(
          settled: 600000,
          pending: [expense(2500, id: 'p', status: TransactionStatus.pending)],
          recent: [
            ...days,
            income(500000, id: 'oct', at: DateTime.utc(2026, 10, 30, 15)),
          ],
          inPeriod: days,
        ),
      );

      final summary = (await getDashboard()).valueOrNull!;

      expect(summary.balance.posted, const Money.cents(600000));
      expect(summary.balance.available, const Money.cents(597500));
      expect(summary.summary!.totals.expense, const Money.cents(5000));
      expect(summary.summary!.totals.income, Money.zero);
      expect(summary.recent.map((t) => t.id), ['d5', 'd4', 'd3', 'd2', 'd1']);
      expect(summary.freshness.isStale, isTrue);
    });

    test('asks for the preset resolved on the user day', () async {
      repository.dashboard = Ok(snapshot());
      await getDashboard(preset: PeriodPreset.last7Days, force: true);
      // 05/11 in Brasília, even though it is already the 6th in UTC.
      expect(
        repository.dashboardCalls.single.period,
        DateSpan(LocalDate(2026, 10, 30), LocalDate(2026, 11, 5)),
      );
      expect(repository.dashboardCalls.single.force, isTrue);
    });

    test('without the whole period on the device, no totals', () async {
      repository.dashboard = Ok(snapshot(settled: 100, inPeriod: null));
      final summary = (await getDashboard()).valueOrNull!;
      expect(summary.summary, isNull);
      expect(summary.balance.available, const Money.cents(100));
    });

    test('saved: nothing saved is null, a snapshot is summarized', () async {
      expect((await getDashboard.saved()).valueOrNull, isNull);
      repository.savedDashboardResult = Ok(snapshot(settled: 42));
      final saved = (await getDashboard.saved()).valueOrNull!;
      expect(saved.balance.available, const Money.cents(42));
    });

    test('passes the failure through untouched', () async {
      repository.dashboard = const Err(NoConnectionFailure());
      expect(
        await getDashboard(),
        const Err<DashboardSummary>(NoConnectionFailure()),
      );
    });
  });

  group('GetStatementPage', () {
    test('forwards the query to the repository', () async {
      final page = TransactionPage(
        items: [tx()],
        nextCursor: null,
        freshness: freshness,
      );
      repository.page = Ok(page);
      final query = TransactionQuery();

      final result = await GetStatementPage(repository)(query);

      expect(result.valueOrNull, same(page));
      expect(repository.pageCalls, [query]);
    });
  });

  test('CountTransactions forwards the filter', () async {
    repository.count = const Ok(23);
    final filter = TransactionFilter(query: 'cafe');
    expect(await CountTransactions(repository)(filter), const Ok(23));
    expect(repository.countCalls, [filter]);
  });

  group('GetTransactionDetail', () {
    test('loads a valid id, trimmed: saved first, then the server', () async {
      repository
        ..savedDetail = Ok(tx(id: 'tx_8f3a'))
        ..detail = Ok(tx(id: 'tx_8f3a'));
      final getDetail = GetTransactionDetail(repository);
      expect((await getDetail.saved(' tx_8f3a')).valueOrNull?.id, 'tx_8f3a');
      final result = await getDetail.refresh('  tx_8f3a ');
      expect(result.valueOrNull?.id, 'tx_8f3a');
      expect(repository.detailCalls, ['saved:tx_8f3a', 'tx_8f3a']);
    });

    test('ids outside the expected shape never reach the data layer', () async {
      final getDetail = GetTransactionDetail(repository);
      for (final id in [
        '',
        '   ',
        '../etc/passwd',
        'a b',
        "1' OR '1'='1",
        'x' * 65,
      ]) {
        expect(
          await getDetail.refresh(id),
          const Err<Transaction>(NotFoundFailure()),
          reason: id,
        );
        expect((await getDetail.saved(id)).valueOrNull, isNull, reason: id);
      }
      expect(repository.detailCalls, isEmpty);
    });
  });
}
