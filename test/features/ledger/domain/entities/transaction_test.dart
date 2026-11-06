import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';

import '../../../../helpers/transactions.dart';

void main() {
  Transaction build({
    String id = 'tx_1',
    String description = 'Padaria',
    int cents = 500,
    String? cardLastDigits,
  }) => Transaction(
    id: id,
    description: description,
    amount: Money.cents(cents),
    type: TransactionType.expense,
    status: TransactionStatus.completed,
    occurredAt: DateTime.utc(2026, 11, 5),
    method: PaymentMethod.creditCard,
    cardLastDigits: cardLastDigits,
  );

  test('rejects records that can never be valid', () {
    expect(() => build(id: '  '), throwsArgumentError);
    expect(() => build(description: ''), throwsArgumentError);
    expect(() => build(cents: -1), throwsArgumentError);
    expect(() => build(cardLastDigits: '48'), throwsArgumentError);
    expect(() => build(cardLastDigits: '48a1'), throwsArgumentError);
  });

  test('accepts zero amounts and a 4 digit card', () {
    expect(build(cents: 0).amount, Money.zero);
    expect(build(cardLastDigits: '4821').cardLastDigits, '4821');
  });

  test('signed amount follows the type', () {
    expect(income(1000).signedAmount, const Money.cents(1000));
    expect(expense(1000).signedAmount, const Money.cents(-1000));
    expect(income(1).isIncome, isTrue);
    expect(expense(1).isExpense, isTrue);
  });

  test('stores the instant in UTC', () {
    final local = DateTime.utc(2026, 11, 6, 2, 30).toLocal();
    final transaction = tx(at: local);
    expect(transaction.occurredAt.isUtc, isTrue);
    expect(transaction.occurredAt, DateTime.utc(2026, 11, 6, 2, 30));
  });

  test('compares by value', () {
    expect(tx(), tx());
    expect(tx().hashCode, tx().hashCode);
    expect(tx(), isNot(tx(cents: 1001)));
    expect(tx().toString(), contains('tx_1'));
  });
}
