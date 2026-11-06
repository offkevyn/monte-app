import 'dart:math';

import '../../../../core/money/money.dart';
import '../../domain/entities/transaction.dart';

/// Generated account used by the simulated backend.
final class FakeLedgerData {
  const FakeLedgerData({
    required this.openingBalance,
    required this.transactions,
  });

  final Money openingBalance;

  /// Newest first; ties broken by id, the order the API pages in.
  final List<Transaction> transactions;
}

/// Builds a believable account from a seed: same seed, same data.
///
/// Times are spread between 07:00 and 23:59 Brasília time on purpose, so
/// the "late night purchase that is already tomorrow in UTC" case shows up
/// in the demo too.
abstract final class FakeLedgerGenerator {
  static const _brasilia = Duration(hours: -3);

  static FakeLedgerData generate({
    required int seed,
    required int count,
    required DateTime nowUtc,
  }) {
    if (count == 0) {
      return const FakeLedgerData(openingBalance: Money.zero, transactions: []);
    }
    final random = Random(seed);
    // About four movements a day, at least a month of history.
    final days = max(30, count ~/ 4);
    final start = nowUtc.subtract(Duration(days: days));
    final usedIds = <String>{};
    final transactions = <Transaction>[];

    // Salary on the 5th of every month in the window.
    for (
      var month = DateTime.utc(start.year, start.month, 5, 12);
      month.isBefore(nowUtc) && transactions.length < count;
      month = DateTime.utc(month.year, month.month + 1, 5, 12)
    ) {
      if (month.isBefore(start)) continue;
      transactions.add(
        Transaction(
          id: _id(random, usedIds),
          description: 'Salário',
          amount: const Money.cents(485000),
          type: TransactionType.income,
          status: TransactionStatus.completed,
          occurredAt: month,
          method: PaymentMethod.bankTransfer,
          category: TransactionCategory.salary,
          counterparty: 'Cooperativa Café Sul de Minas',
        ),
      );
    }

    while (transactions.length < count) {
      final template = _templates[random.nextInt(_templates.length)];
      final occurredAt = _randomInstant(random, start, nowUtc);
      final amount =
          template.minCents +
          random.nextInt(template.maxCents - template.minCents + 1);
      final isCard =
          template.method == PaymentMethod.creditCard ||
          template.method == PaymentMethod.debitCard;
      transactions.add(
        Transaction(
          id: _id(random, usedIds),
          description: template.description,
          amount: Money.cents(amount),
          type: template.type,
          status: _status(random, occurredAt, nowUtc),
          occurredAt: occurredAt,
          method: template.method,
          category: template.category,
          cardLastDigits: isCard ? '4821' : null,
          counterparty:
              template.counterparty ?? _people[random.nextInt(_people.length)],
          message:
              template.type == TransactionType.income &&
                  template.method == PaymentMethod.pix &&
                  random.nextInt(3) == 0
              ? _messages[random.nextInt(_messages.length)]
              : null,
        ),
      );
    }

    transactions.sort(compareForPaging);
    return FakeLedgerData(
      openingBalance: _openingBalanceThatNeverGoesNegative(transactions),
      transactions: transactions,
    );
  }

  /// Newest first, then id ascending: the order the statement pages in.
  static int compareForPaging(Transaction a, Transaction b) {
    final byTime = b.occurredAt.compareTo(a.occurredAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }

  /// Picks an opening balance so the running balance stays at or above
  /// R$ 1.500,00, keeping the demo account believable at any volume.
  static Money _openingBalanceThatNeverGoesNegative(
    List<Transaction> newestFirst,
  ) {
    var running = 0;
    var lowest = 0;
    for (final transaction in newestFirst.reversed) {
      if (transaction.status == TransactionStatus.completed) {
        running += transaction.signedAmount.cents;
        lowest = min(lowest, running);
      }
    }
    return Money.cents(-lowest + 150000);
  }

  static TransactionStatus _status(Random random, DateTime at, DateTime now) {
    // Only recent movements can still be pending.
    final recent = now.difference(at) < const Duration(days: 3);
    final roll = random.nextInt(100);
    if (recent && roll < 30) return TransactionStatus.pending;
    if (roll < 4) return TransactionStatus.failed;
    if (roll < 7) return TransactionStatus.reversed;
    return TransactionStatus.completed;
  }

  static DateTime _randomInstant(Random random, DateTime start, DateTime end) {
    final dayCount = max(1, end.difference(start).inDays);
    final day = start.add(Duration(days: random.nextInt(dayCount)));
    // Local wall clock 07:00..23:59 in Brasília, converted back to UTC.
    final localMidnight = DateTime.utc(day.year, day.month, day.day);
    final minutes = 7 * 60 + random.nextInt(17 * 60);
    final instant = localMidnight
        .add(Duration(minutes: minutes))
        .subtract(_brasilia);
    return instant.isAfter(end)
        ? end.subtract(const Duration(minutes: 5))
        : instant;
  }

  static String _id(Random random, Set<String> used) {
    while (true) {
      final hex = List.generate(
        12,
        (_) => random.nextInt(16).toRadixString(16),
      ).join();
      final id = 'tx_$hex';
      if (used.add(id)) return id;
    }
  }

  static const _people = [
    'Ana Souza',
    'João Pereira',
    'Mariana Lima',
    'Rafael Costa',
    'Beatriz Alves',
    'Lucas Martins',
  ];

  static const _messages = [
    'Valeu pelo almoço!',
    'Parte do aluguel',
    'Presente de aniversário 🎉',
    'Rachando a conta',
  ];

  static const _templates = [
    _Template(
      'Supermercado Bom Preço',
      TransactionCategory.groceries,
      PaymentMethod.debitCard,
      2500,
      38000,
      counterparty: 'Bom Preço Ltda',
    ),
    _Template(
      'Hortifruti Monte Belo',
      TransactionCategory.groceries,
      PaymentMethod.pix,
      1200,
      9000,
      counterparty: 'Hortifruti Monte Belo',
    ),
    _Template(
      'Padaria São José',
      TransactionCategory.food,
      PaymentMethod.debitCard,
      800,
      4500,
      counterparty: 'Padaria São José',
    ),
    _Template(
      'Restaurante Sabor de Minas',
      TransactionCategory.food,
      PaymentMethod.creditCard,
      3500,
      12000,
      counterparty: 'Sabor de Minas',
    ),
    _Template(
      'iFood',
      TransactionCategory.food,
      PaymentMethod.creditCard,
      2800,
      9500,
      counterparty: 'iFood',
    ),
    _Template(
      'Uber',
      TransactionCategory.transport,
      PaymentMethod.creditCard,
      900,
      6500,
      counterparty: 'Uber do Brasil',
    ),
    _Template(
      'Posto Ipiranga',
      TransactionCategory.transport,
      PaymentMethod.debitCard,
      8000,
      25000,
      counterparty: 'Posto Ipiranga',
    ),
    _Template(
      'Conta de luz',
      TransactionCategory.bills,
      PaymentMethod.boleto,
      9000,
      26000,
      counterparty: 'Cemig',
    ),
    _Template(
      'Internet fibra',
      TransactionCategory.bills,
      PaymentMethod.boleto,
      9990,
      12990,
      counterparty: 'Vivo',
    ),
    _Template(
      'Drogaria Araújo',
      TransactionCategory.health,
      PaymentMethod.debitCard,
      1500,
      18000,
      counterparty: 'Drogaria Araújo',
    ),
    _Template(
      'Cinema',
      TransactionCategory.leisure,
      PaymentMethod.creditCard,
      2400,
      9000,
      counterparty: 'Cinemark',
    ),
    _Template(
      'Netflix',
      TransactionCategory.subscriptions,
      PaymentMethod.creditCard,
      2190,
      5590,
      counterparty: 'Netflix',
    ),
    _Template(
      'Spotify',
      TransactionCategory.subscriptions,
      PaymentMethod.creditCard,
      2190,
      3490,
      counterparty: 'Spotify',
    ),
    _Template(
      'Magazine Luiza',
      TransactionCategory.shopping,
      PaymentMethod.creditCard,
      5000,
      89000,
      counterparty: 'Magalu',
    ),
    _Template(
      'Pix enviado',
      TransactionCategory.transfer,
      PaymentMethod.pix,
      1000,
      30000,
    ),
    _Template(
      'Pix recebido',
      TransactionCategory.transfer,
      PaymentMethod.pix,
      1000,
      60000,
      type: TransactionType.income,
    ),
    _Template(
      'Pix recebido',
      TransactionCategory.transfer,
      PaymentMethod.pix,
      2000,
      15000,
      type: TransactionType.income,
    ),
  ];
}

final class _Template {
  const _Template(
    this.description,
    this.category,
    this.method,
    this.minCents,
    this.maxCents, {
    this.type = TransactionType.expense,
    this.counterparty,
  });

  final String description;
  final TransactionCategory category;
  final PaymentMethod method;
  final int minCents;
  final int maxCents;
  final TransactionType type;
  final String? counterparty;
}
