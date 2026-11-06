import 'package:monte/core/money/money.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';

/// Builds a valid transaction where only what the test cares about is set.
Transaction tx({
  String id = 'tx_1',
  TransactionType type = TransactionType.expense,
  int cents = 1000,
  TransactionStatus status = TransactionStatus.completed,
  DateTime? at,
  String description = 'Mercado Bom Preço',
  String? counterparty,
  PaymentMethod method = PaymentMethod.pix,
  TransactionCategory category = TransactionCategory.other,
}) => Transaction(
  id: id,
  description: description,
  amount: Money.cents(cents),
  type: type,
  status: status,
  occurredAt: at ?? DateTime.utc(2026, 11, 5, 15),
  method: method,
  category: category,
  counterparty: counterparty,
);

Transaction income(
  int cents, {
  String id = 'in',
  DateTime? at,
  TransactionStatus status = TransactionStatus.completed,
}) => tx(
  id: id,
  type: TransactionType.income,
  cents: cents,
  at: at,
  status: status,
);

Transaction expense(
  int cents, {
  String id = 'out',
  DateTime? at,
  TransactionStatus status = TransactionStatus.completed,
}) => tx(id: id, cents: cents, at: at, status: status);
