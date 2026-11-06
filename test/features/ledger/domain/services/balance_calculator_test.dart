import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/services/balance_calculator.dart';

import '../../../../helpers/transactions.dart';

void main() {
  BalanceBreakdown compute(List<Transaction> transactions, {int opening = 0}) =>
      BalanceCalculator.compute(
        openingBalance: Money.cents(opening),
        transactions: transactions,
      );

  test('no transactions: balance is the opening balance', () {
    final balance = compute(const [], opening: 150000);
    expect(balance.available, const Money.cents(150000));
    expect(balance.pendingDebits, Money.zero);
  });

  test('a brand new account with nothing at all is zero', () {
    expect(compute(const []).available, Money.zero);
  });

  test('completed income adds and completed expense subtracts', () {
    final balance = compute([
      income(500000, id: 'a'),
      expense(12990, id: 'b'),
      expense(4550, id: 'c'),
    ], opening: 10000);

    expect(balance.posted, const Money.cents(10000 + 500000 - 12990 - 4550));
    expect(balance.available, balance.posted);
  });

  test('pending expense is reserved: lowers available, not posted', () {
    final balance = compute([
      income(100000, id: 'a'),
      expense(30000, id: 'b', status: TransactionStatus.pending),
    ]);

    expect(balance.posted, const Money.cents(100000));
    expect(balance.pendingDebits, const Money.cents(30000));
    expect(balance.available, const Money.cents(70000));
  });

  test('pending income, failed and reversed do not move the balance', () {
    final balance = compute([
      income(100000, id: 'a', status: TransactionStatus.pending),
      expense(5000, id: 'b', status: TransactionStatus.failed),
      income(7000, id: 'c', status: TransactionStatus.failed),
      expense(8000, id: 'd', status: TransactionStatus.reversed),
      income(9000, id: 'e', status: TransactionStatus.reversed),
    ], opening: 1000);

    expect(
      balance,
      const BalanceBreakdown(
        posted: Money.cents(1000),
        pendingDebits: Money.zero,
      ),
    );
  });

  test('can go negative (overdraft) without breaking', () {
    final balance = compute([expense(2500)], opening: 1000);
    expect(balance.available, const Money.cents(-1500));
  });

  test('zero amount transactions change nothing', () {
    expect(compute([expense(0), income(0, id: 'z')]).available, Money.zero);
  });

  test('10 000 transactions add up to the exact cent', () {
    // 0,10 in and 0,03 out, 5 000 times each: a double would drift here.
    final transactions = [
      for (var i = 0; i < 5000; i++) ...[
        income(10, id: 'in$i'),
        expense(3, id: 'out$i'),
      ],
    ];
    expect(compute(transactions).available, const Money.cents(35000));
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
