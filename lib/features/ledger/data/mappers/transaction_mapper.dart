import '../../../../core/money/money.dart';
import '../../domain/entities/transaction.dart';
import '../dtos/transaction_dto.dart';

/// Converts between the API format and domain entities.
///
/// Strict where guessing would be dangerous (status, direction, currency):
/// an unknown status could hide a failed payment, so the record is rejected.
/// Tolerant where it is harmless: an unknown category becomes `other`.
abstract final class TransactionMapper {
  static const _directions = {
    'credit': TransactionType.income,
    'debit': TransactionType.expense,
  };

  static const _statuses = {
    'completed': TransactionStatus.completed,
    'pending': TransactionStatus.pending,
    'failed': TransactionStatus.failed,
    'reversed': TransactionStatus.reversed,
  };

  static const _methods = {
    'pix': PaymentMethod.pix,
    'credit_card': PaymentMethod.creditCard,
    'debit_card': PaymentMethod.debitCard,
    'boleto': PaymentMethod.boleto,
    'bank_transfer': PaymentMethod.bankTransfer,
  };

  static final _categories = {
    for (final category in TransactionCategory.values)
      _snakeCase(category.name): category,
  };

  /// Throws [FormatException] or [ArgumentError] for invalid records.
  ///
  /// [detailed] is false for list items, which carry only the summary.
  static Transaction toEntity(TransactionDto dto, {bool detailed = true}) =>
      Transaction(
        id: dto.id,
        description: dto.description.trim(),
        amount: Money.cents(dto.amountCents),
        type: _lookup(_directions, dto.direction, 'direction'),
        status: _lookup(_statuses, dto.status, 'status'),
        occurredAt: dto.occurredAt,
        method: _lookup(_methods, dto.paymentMethod, 'payment_method'),
        category: _categories[dto.category] ?? TransactionCategory.other,
        cardLastDigits: dto.cardLast4,
        counterparty: dto.counterparty?.trim(),
        message: dto.message?.trim(),
        detailed: detailed,
      );

  /// Maps a page, dropping (and counting) records that are invalid.
  static ({List<Transaction> items, int skipped}) toEntities(
    TransactionPageDto page,
  ) {
    final items = <Transaction>[];
    var skipped = page.skippedItems;
    for (final dto in page.items) {
      try {
        items.add(toEntity(dto, detailed: false));
      } on FormatException {
        skipped++;
      } on ArgumentError {
        skipped++;
      }
    }
    return (items: items, skipped: skipped);
  }

  static TransactionDto fromEntity(Transaction transaction) => TransactionDto(
    id: transaction.id,
    description: transaction.description,
    amountCents: transaction.amount.cents,
    direction: _reverse(_directions, transaction.type),
    status: _reverse(_statuses, transaction.status),
    occurredAt: transaction.occurredAt,
    paymentMethod: _reverse(_methods, transaction.method),
    category: _snakeCase(transaction.category.name),
    cardLast4: transaction.cardLastDigits,
    counterparty: transaction.counterparty,
    message: transaction.message,
  );

  /// Only Brazilian reais are supported; anything else is rejected rather
  /// than shown with the wrong symbol.
  static Money balance(AccountDto dto) {
    if (dto.currency != 'BRL') {
      throw FormatException('Unsupported currency', dto.currency);
    }
    return Money.cents(dto.balanceCents);
  }

  static T _lookup<T>(Map<String, T> table, String value, String field) =>
      table[value] ?? (throw FormatException('Unknown $field', value));

  static String _reverse<T>(Map<String, T> table, T value) =>
      table.entries.firstWhere((entry) => entry.value == value).key;

  static String _snakeCase(String camel) => camel.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}
