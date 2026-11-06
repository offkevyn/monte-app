import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/network/json_reader.dart';
import 'package:monte/features/ledger/data/dtos/transaction_dto.dart';
import 'package:monte/features/ledger/data/mappers/transaction_mapper.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';

void main() {
  Map<String, Object?> validJson() => {
    'id': 'tx_8f3a1c21e000',
    'description': 'Supermercado Bom Preço',
    'amount_cents': 12990,
    'direction': 'debit',
    'status': 'completed',
    'occurred_at': '2026-11-04T22:47:00Z',
    'payment_method': 'credit_card',
    'category': 'groceries',
    'card_last4': '4821',
    'counterparty': 'Bom Preço Ltda',
    'message': null,
  };

  Transaction parse(Map<String, Object?> json) =>
      TransactionMapper.toEntity(TransactionDto.fromJson(json));

  group('valid payloads', () {
    test('become a full entity', () {
      final transaction = parse(validJson());
      expect(transaction.id, 'tx_8f3a1c21e000');
      expect(transaction.amount, const Money.cents(12990));
      expect(transaction.type, TransactionType.expense);
      expect(transaction.status, TransactionStatus.completed);
      expect(transaction.method, PaymentMethod.creditCard);
      expect(transaction.category, TransactionCategory.groceries);
      expect(transaction.cardLastDigits, '4821');
      expect(transaction.occurredAt, DateTime.utc(2026, 11, 4, 22, 47));
      expect(transaction.message, isNull);
    });

    test('a time with offset is converted to UTC', () {
      final transaction = parse({
        ...validJson(),
        'occurred_at': '2026-11-04T19:47:00-03:00',
      });
      expect(transaction.occurredAt, DateTime.utc(2026, 11, 4, 22, 47));
    });

    test('an unknown category is tolerated as "other"', () {
      expect(
        parse({...validJson(), 'category': 'pets'}).category,
        TransactionCategory.other,
      );
      expect(
        parse({...validJson()}..remove('category')).category,
        TransactionCategory.other,
      );
    });

    test('entity -> json -> entity gives the same transaction', () {
      final original = parse(validJson());
      final again = parse(TransactionMapper.fromEntity(original).toJson());
      expect(again, original);

      // Every enum value survives the round trip, so no mapping is missing.
      for (final method in PaymentMethod.values) {
        for (final status in TransactionStatus.values) {
          for (final type in TransactionType.values) {
            for (final category in TransactionCategory.values) {
              final entity = Transaction(
                id: 'tx_rt',
                description: 'Round trip',
                amount: const Money.cents(100),
                type: type,
                status: status,
                occurredAt: DateTime.utc(2026, 11, 5),
                method: method,
                category: category,
              );
              expect(
                parse(TransactionMapper.fromEntity(entity).toJson()),
                entity,
                reason: '$method $status $type $category',
              );
            }
          }
        }
      }
    });
  });

  group('broken payloads are rejected, never guessed', () {
    final cases = <String, Map<String, Object?> Function()>{
      'missing amount': () => validJson()..remove('amount_cents'),
      'amount as text': () => {...validJson(), 'amount_cents': '129,90'},
      'amount with decimals': () => {...validJson(), 'amount_cents': 129.9},
      'negative amount': () => {...validJson(), 'amount_cents': -100},
      'unknown status': () => {...validJson(), 'status': 'processing'},
      'unknown direction': () => {...validJson(), 'direction': 'sideways'},
      'unknown payment method': () => {
        ...validJson(),
        'payment_method': 'cheque',
      },
      'date without time zone': () => {
        ...validJson(),
        'occurred_at': '2026-11-05 14:32:00',
      },
      'not a date': () => {...validJson(), 'occurred_at': 'yesterdayZ'},
      'empty id': () => {...validJson(), 'id': '  '},
      'card with 3 digits': () => {...validJson(), 'card_last4': '482'},
      'counterparty as number': () => {...validJson(), 'counterparty': 42},
    };

    for (final MapEntry(key: name, value: build) in cases.entries) {
      test(name, () {
        expect(
          () => parse(build()),
          anyOf(throwsFormatException, throwsArgumentError),
        );
      });
    }

    test('a list is not an object', () {
      expect(() => TransactionDto.fromJson([1, 2]), throwsFormatException);
      expect(() => JsonReader.of('text'), throwsFormatException);
    });
  });

  group('pages', () {
    test('skip and count broken records instead of failing the page', () {
      final page = TransactionPageDto.fromJson({
        'data': [
          validJson(),
          {...validJson(), 'id': 'tx_2'}..remove('amount_cents'),
          {...validJson(), 'id': 'tx_3', 'status': 'processing'},
          {...validJson(), 'id': 'tx_4'},
          {...validJson(), 'id': 'tx_5', 'amount_cents': -100},
        ],
        'next_cursor': 'abc',
      });

      final mapped = TransactionMapper.toEntities(page);

      expect(mapped.items.map((t) => t.id), ['tx_8f3a1c21e000', 'tx_4']);
      expect(mapped.skipped, 3);
      expect(page.nextCursor, 'abc');
    });

    test('a page without the data list is invalid as a whole', () {
      expect(
        () => TransactionPageDto.fromJson({'items': <Object?>[]}),
        throwsFormatException,
      );
    });
  });

  group('account', () {
    test('reads the opening balance in reais', () {
      final dto = AccountDto.fromJson({
        'opening_balance_cents': 150000,
        'currency': 'BRL',
      });
      expect(TransactionMapper.openingBalance(dto), const Money.cents(150000));
      expect(dto.toJson()['currency'], 'BRL');
    });

    test('rejects another currency instead of showing the wrong symbol', () {
      final dto = AccountDto.fromJson({
        'opening_balance_cents': 100,
        'currency': 'USD',
      });
      expect(
        () => TransactionMapper.openingBalance(dto),
        throwsFormatException,
      );
    });
  });
}
