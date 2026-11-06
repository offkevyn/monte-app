import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/ledger_snapshot.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/entities/transaction_page.dart';
import 'package:monte/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:monte/features/ledger/domain/usecases/get_dashboard.dart';
import 'package:monte/features/ledger/domain/usecases/get_statement_page.dart';
import 'package:monte/features/ledger/domain/usecases/get_transaction_detail.dart';

import '../../../../helpers/transactions.dart';

/// Hand-written fake: records calls and answers with whatever the test set.
class FakeLedgerRepository implements LedgerRepository {
  Result<LedgerSnapshot>? snapshot;
  Result<TransactionPage>? page;
  Result<Transaction>? detail;

  final snapshotCalls = <bool>[];
  final pageCalls = <TransactionQuery>[];
  final detailCalls = <String>[];

  @override
  Future<Result<LedgerSnapshot>> loadSnapshot({
    bool forceRefresh = false,
  }) async {
    snapshotCalls.add(forceRefresh);
    return snapshot!;
  }

  @override
  Future<Result<TransactionPage>> getTransactions(
    TransactionQuery query,
  ) async {
    pageCalls.add(query);
    return page!;
  }

  @override
  Future<Result<Transaction>> getTransaction(String id) async {
    detailCalls.add(id);
    return detail!;
  }

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

    test(
      'derives balance, totals and recent items from one snapshot',
      () async {
        repository.snapshot = Ok(
          LedgerSnapshot(
            openingBalance: const Money.cents(100000),
            transactions: [
              for (var day = 1; day <= 7; day++)
                expense(1000, id: 'd$day', at: DateTime.utc(2026, 11, day, 15)),
              income(500000, id: 'oct', at: DateTime.utc(2026, 10, 30, 15)),
            ],
            freshness: freshness,
          ),
        );

        final result = await getDashboard();
        final summary = result.valueOrNull!;

        expect(
          summary.balance.available,
          const Money.cents(100000 + 500000 - 7000),
        );
        // "This month" on the user's 5th covers 01..05 only.
        expect(
          summary.summary.period,
          DateSpan(LocalDate(2026, 11, 1), LocalDate(2026, 11, 5)),
        );
        expect(summary.summary.totals.expense, const Money.cents(5000));
        expect(summary.summary.totals.income, Money.zero);
        expect(summary.recent.map((t) => t.id), ['d7', 'd6', 'd5', 'd4', 'd3']);
        expect(summary.freshness.isStale, isTrue);
        expect(repository.snapshotCalls, [false]);
      },
    );

    test('custom period wins over the preset; refresh is forwarded', () async {
      repository.snapshot = Ok(
        LedgerSnapshot(
          openingBalance: Money.zero,
          transactions: const [],
          freshness: freshness,
        ),
      );
      final custom = DateSpan(LocalDate(2026, 1, 1), LocalDate(2026, 1, 10));

      final result = await getDashboard(
        preset: PeriodPreset.last7Days,
        customPeriod: custom,
        forceRefresh: true,
      );

      expect(result.valueOrNull!.summary.period, custom);
      expect(result.valueOrNull!.recent, isEmpty);
      expect(repository.snapshotCalls, [true]);
    });

    test('passes the failure through untouched', () async {
      repository.snapshot = const Err(NoConnectionFailure());
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

  group('GetTransactionDetail', () {
    test('loads a valid id, trimmed', () async {
      repository.detail = Ok(tx(id: 'tx_8f3a'));
      final result = await GetTransactionDetail(repository)('  tx_8f3a ');
      expect(result.valueOrNull?.id, 'tx_8f3a');
      expect(repository.detailCalls, ['tx_8f3a']);
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
          await getDetail(id),
          const Err<Transaction>(NotFoundFailure()),
          reason: id,
        );
      }
      expect(repository.detailCalls, isEmpty);
    });
  });
}
