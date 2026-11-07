import '../../../../core/network/json_reader.dart';

/// A transaction exactly as the API sends it (snake_case, cents as int,
/// enums as strings). Validates the shape; the meaning is checked when the
/// mapper turns it into an entity.
final class TransactionDto {
  const TransactionDto({
    required this.id,
    required this.description,
    required this.amountCents,
    required this.direction,
    required this.status,
    required this.occurredAt,
    required this.paymentMethod,
    this.category,
    this.cardLast4,
    this.counterparty,
    this.message,
  });

  factory TransactionDto.fromJson(Object? source) {
    final json = JsonReader.of(source, 'transaction');
    return TransactionDto(
      id: json.string('id'),
      description: json.string('description'),
      amountCents: json.integer('amount_cents'),
      direction: json.string('direction'),
      status: json.string('status'),
      occurredAt: json.instant('occurred_at'),
      paymentMethod: json.string('payment_method'),
      category: json.optionalString('category'),
      cardLast4: json.optionalString('card_last4'),
      counterparty: json.optionalString('counterparty'),
      message: json.optionalString('message'),
    );
  }

  final String id;
  final String description;
  final int amountCents;

  /// `credit` (money in) or `debit` (money out).
  final String direction;
  final String status;
  final DateTime occurredAt;
  final String paymentMethod;
  final String? category;
  final String? cardLast4;
  final String? counterparty;
  final String? message;

  Map<String, Object?> toJson() => {
    'id': id,
    'description': description,
    'amount_cents': amountCents,
    'direction': direction,
    'status': status,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'payment_method': paymentMethod,
    'category': category,
    'card_last4': cardLast4,
    'counterparty': counterparty,
    'message': message,
  };
}

/// `GET /v1/account`: the settled balance, computed by the server.
final class AccountDto {
  const AccountDto({
    required this.balanceCents,
    required this.currency,
    required this.asOf,
  });

  factory AccountDto.fromJson(Object? source) {
    final json = JsonReader.of(source, 'account');
    return AccountDto(
      balanceCents: json.integer('balance_cents'),
      currency: json.string('currency'),
      asOf: json.instant('as_of'),
    );
  }

  /// Opening balance plus every completed movement, as of [asOf].
  final int balanceCents;
  final String currency;
  final DateTime asOf;

  Map<String, Object?> toJson() => {
    'balance_cents': balanceCents,
    'currency': currency,
    'as_of': asOf.toUtc().toIso8601String(),
  };
}

/// One page of `GET /v1/transactions`.
///
/// Items that fail to parse are skipped and counted instead of failing the
/// whole page: one corrupted record should not hide the other nineteen. The
/// count lets the app log it and warn that the list may be incomplete.
final class TransactionPageDto {
  const TransactionPageDto({
    required this.items,
    required this.skippedItems,
    required this.nextCursor,
    this.total,
  });

  factory TransactionPageDto.fromJson(Object? source) {
    final json = JsonReader.of(source, 'transaction page');
    final items = <TransactionDto>[];
    var skipped = 0;
    for (final raw in json.list('data')) {
      try {
        items.add(TransactionDto.fromJson(raw));
      } on FormatException {
        skipped++;
      }
    }
    return TransactionPageDto(
      items: items,
      skippedItems: skipped,
      nextCursor: json.optionalString('next_cursor'),
      total: json.optionalInteger('total'),
    );
  }

  final List<TransactionDto> items;
  final int skippedItems;
  final String? nextCursor;

  /// How many transactions match the filter on the server, across pages.
  final int? total;
}
