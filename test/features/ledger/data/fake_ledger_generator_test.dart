import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/features/ledger/data/fake/fake_ledger_generator.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';

void main() {
  final now = DateTime.utc(2026, 11, 6, 2, 30);

  FakeLedgerData generate({int seed = 42, int count = 500}) =>
      FakeLedgerGenerator.generate(seed: seed, count: count, nowUtc: now);

  test('same seed gives the same account; another seed does not', () {
    expect(generate().transactions, generate().transactions);
    expect(generate().openingBalance, generate().openingBalance);
    expect(
      generate(seed: 7).transactions.first,
      isNot(generate().transactions.first),
    );
  });

  test(
    'has exactly the requested volume, unique ids, nothing in the future',
    () {
      for (final count in [50, 500, 10000]) {
        final data = generate(count: count);
        expect(data.transactions, hasLength(count));
        expect(data.transactions.map((t) => t.id).toSet(), hasLength(count));
        expect(
          data.transactions.every((t) => !t.occurredAt.isAfter(now)),
          isTrue,
        );
      }
    },
  );

  test('is sorted in paging order (newest first, then id)', () {
    final list = generate().transactions;
    for (var i = 1; i < list.length; i++) {
      expect(
        FakeLedgerGenerator.compareForPaging(list[i - 1], list[i]),
        lessThanOrEqualTo(0),
      );
    }
  });

  test('running balance never drops below R\$ 1.500,00', () {
    final data = generate(count: 10000);
    var running = data.openingBalance;
    var lowest = running;
    for (final t in data.transactions.reversed) {
      if (t.status == TransactionStatus.completed) {
        running += t.signedAmount;
        if (running < lowest) lowest = running;
      }
    }
    expect(lowest, const Money.cents(150000));
  });

  test('only the last three days can be pending', () {
    final pending = generate(count: 10000).transactions
        .where((t) => t.status == TransactionStatus.pending);
    expect(pending, isNotEmpty);
    for (final t in pending) {
      expect(now.difference(t.occurredAt), lessThan(const Duration(days: 3)));
    }
  });

  test('includes every status, salaries and late night purchases', () {
    final list = generate(count: 10000).transactions;
    expect(list.map((t) => t.status).toSet(), TransactionStatus.values.toSet());
    expect(
      list.where((t) => t.category == TransactionCategory.salary),
      isNotEmpty,
    );
    // Between 21:00 and 23:59 in Brasília = already the next day in UTC.
    expect(list.where((t) => t.occurredAt.hour < 3), isNotEmpty);
  });

  test('cards carry the last digits, other methods do not', () {
    for (final t in generate().transactions) {
      final isCard =
          t.method == PaymentMethod.creditCard ||
          t.method == PaymentMethod.debitCard;
      expect(t.cardLastDigits != null, isCard, reason: t.id);
    }
  });

  test('a brand new account has only its last few days', () {
    final now = DateTime.utc(2026, 11, 6, 2, 30);
    final data = FakeLedgerGenerator.generate(seed: 7, count: 3, nowUtc: now);
    expect(data.transactions, hasLength(3));
    for (final t in data.transactions) {
      expect(now.difference(t.occurredAt).inDays, lessThanOrEqualTo(3));
    }
  });

  test('empty account', () {
    final data = generate(count: 0);
    expect(data.transactions, isEmpty);
    expect(data.openingBalance, Money.zero);
  });
}
