import 'package:meta/meta.dart';

import '../../../../core/money/money.dart';

/// Direction of the money. The amount itself is always non-negative; the
/// type says whether it comes in or goes out.
enum TransactionType { income, expense }

enum TransactionStatus { completed, pending, failed, reversed }

enum TransactionCategory {
  groceries,
  food,
  transport,
  bills,
  shopping,
  health,
  leisure,
  subscriptions,
  salary,
  transfer,
  other,
}

enum PaymentMethod { pix, creditCard, debitCard, boleto, bankTransfer }

/// One movement in the account statement.
@immutable
final class Transaction {
  /// Throws an [ArgumentError] for values that can never be valid. Mappers
  /// call this inside a guard and turn the error into an
  /// `InvalidDataFailure`, so a broken record never reaches the UI.
  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.status,
    required DateTime occurredAt,
    required this.method,
    this.category = TransactionCategory.other,
    this.cardLastDigits,
    this.counterparty,
    this.message,
    this.detailed = true,
  }) : occurredAt = occurredAt.toUtc() {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (description.trim().isEmpty) {
      throw ArgumentError.value(description, 'description', 'is empty');
    }
    if (amount.isNegative) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
    final digits = cardLastDigits;
    if (digits != null && !RegExp(r'^\d{4}$').hasMatch(digits)) {
      throw ArgumentError.value(digits, 'cardLastDigits', 'must be 4 digits');
    }
  }

  final String id;
  final String description;

  /// Always zero or positive. Use [signedAmount] for arithmetic.
  final Money amount;
  final TransactionType type;
  final TransactionStatus status;

  /// When it happened, in UTC.
  final DateTime occurredAt;
  final PaymentMethod method;
  final TransactionCategory category;

  /// Last four digits of the card, only for card payments.
  final String? cardLastDigits;

  /// Who paid or got paid (store, person, employer).
  final String? counterparty;

  /// Free text attached by the sender, e.g. a Pix message.
  final String? message;

  /// False when only the summary sent by the list is known: [cardLastDigits]
  /// and [message] arrive with the detail endpoint.
  final bool detailed;

  /// Same transaction with what the detail endpoint adds.
  Transaction withDetails({String? cardLastDigits, String? message}) =>
      Transaction(
        id: id,
        description: description,
        amount: amount,
        type: type,
        status: status,
        occurredAt: occurredAt,
        method: method,
        category: category,
        cardLastDigits: cardLastDigits,
        counterparty: counterparty,
        message: message,
      );

  bool get isIncome => type == TransactionType.income;

  bool get isExpense => type == TransactionType.expense;

  /// Positive for income, negative for expense.
  Money get signedAmount => isIncome ? amount : -amount;

  @override
  bool operator ==(Object other) =>
      other is Transaction &&
      other.id == id &&
      other.description == description &&
      other.amount == amount &&
      other.type == type &&
      other.status == status &&
      other.occurredAt == occurredAt &&
      other.method == method &&
      other.category == category &&
      other.cardLastDigits == cardLastDigits &&
      other.counterparty == counterparty &&
      other.message == message &&
      other.detailed == detailed;

  @override
  int get hashCode => Object.hash(
    id,
    description,
    amount,
    type,
    status,
    occurredAt,
    method,
    category,
    cardLastDigits,
    counterparty,
    message,
    detailed,
  );

  @override
  String toString() =>
      'Transaction($id, ${type.name}, ${status.name}, $amount, $occurredAt)';
}
