import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/services/balance_calculator.dart';

import '../../../../helpers/transactions.dart';

void main() {
  BalanceBreakdown compute(List<Transaction> pending, {int settled = 0}) =>
      BalanceCalculator.compute(
        settled: Money.cents(settled),
        pending: pending,
      );

  test('nothing pending: available is the settled balance', () {
    final balance = compute(const [], settled: 150000);
    expect(balance.posted, const Money.cents(150000));
    expect(balance.available, const Money.cents(150000));
    expect(balance.pendingDebits, Money.zero);
  });

  test('a brand new account with nothing at all is zero', () {
    expect(compute(const []).available, Money.zero);
  });

  test('pending expense is reserved: lowers available, not settled', () {
    final balance = compute([
      expense(30000, id: 'b', status: TransactionStatus.pending),
      expense(4550, id: 'c', status: TransactionStatus.pending),
    ], settled: 100000);

    expect(balance.posted, const Money.cents(100000));
    expect(balance.pendingDebits, const Money.cents(34550));
    expect(balance.available, const Money.cents(65450));
  });

  test('only pending expenses count, whatever else is in the list', () {
    // The server sends pending debits; anything else that slips in (a debit
    // that settled meanwhile, pending income) must not move the balance.
    final balance = compute([
      income(100000, id: 'a', status: TransactionStatus.pending),
      expense(5000, id: 'b', status: TransactionStatus.failed),
      expense(8000, id: 'd', status: TransactionStatus.reversed),
      expense(9000, id: 'e'),
    ], settled: 1000);

    expect(
      balance,
      const BalanceBreakdown(
        posted: Money.cents(1000),
        pendingDebits: Money.zero,
      ),
    );
  });

  test('can go negative (overdraft) without breaking', () {
    final balance = compute([
      expense(2500, status: TransactionStatus.pending),
    ], settled: 1000);
    expect(balance.available, const Money.cents(-1500));
  });

  test('a negative settled balance stays exact', () {
    expect(compute(const [], settled: -999).available, const Money.cents(-999));
  });

  test('zero amount pending changes nothing', () {
    expect(
      compute([expense(0, status: TransactionStatus.pending)]).available,
      Money.zero,
    );
  });

  test('10 000 pending debits add up to the exact cent', () {
    // 0,03 reserved 10 000 times: a double would drift here.
    final pending = [
      for (var i = 0; i < 10000; i++)
        expense(3, id: 'out$i', status: TransactionStatus.pending),
    ];
    expect(
      compute(pending, settled: 100000).available,
      const Money.cents(70000),
    );
  });

  test('breakdown has value equality and a readable toString', () {
    const a = BalanceBreakdown(
      posted: Money.cents(1),
      pendingDebits: Money.zero,
    );
    expect(
      a,
      const BalanceBreakdown(posted: Money.cents(1), pendingDebits: Money.zero),
    );
    expect(a.hashCode, isNot(0));
    expect(a.toString(), contains('available'));
  });
}
