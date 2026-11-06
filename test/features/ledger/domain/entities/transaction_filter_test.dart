import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/text/search_text.dart';
import 'package:monte/core/time/local_calendar.dart';
import 'package:monte/core/time/local_date.dart';
import 'package:monte/features/ledger/domain/entities/date_span.dart';
import 'package:monte/features/ledger/domain/entities/transaction.dart';
import 'package:monte/features/ledger/domain/entities/transaction_filter.dart';

import '../../../../helpers/transactions.dart';

void main() {
  const calendar = FixedOffsetCalendar.brasilia;

  final salary = tx(
    id: 'salary',
    type: TransactionType.income,
    description: 'Salário',
    counterparty: 'Monte Belo Cafés Ltda',
    at: DateTime.utc(2026, 11, 5, 12),
  );
  final coffee = tx(
    id: 'coffee',
    description: 'Café da Padaria São José',
    status: TransactionStatus.pending,
    at: DateTime.utc(2026, 11, 6, 2, 30), // 05/11 23:30 local
  );
  final refund = tx(
    id: 'refund',
    type: TransactionType.income,
    description: 'Estorno Loja',
    status: TransactionStatus.reversed,
    at: DateTime.utc(2026, 11, 10, 12),
  );
  final all = [salary, coffee, refund];

  List<String> apply(TransactionFilter filter) => [
    for (final t in all)
      if (filter.matches(t, calendar)) t.id,
  ];

  test('empty filter lets everything through', () {
    expect(TransactionFilter.none.isEmpty, isTrue);
    expect(TransactionFilter.none.activeCount, 0);
    expect(apply(TransactionFilter.none), ['salary', 'coffee', 'refund']);
  });

  test('filters by type and by status', () {
    expect(apply(TransactionFilter(types: {TransactionType.expense})), [
      'coffee',
    ]);
    expect(
      apply(
        TransactionFilter(
          statuses: {TransactionStatus.pending, TransactionStatus.reversed},
        ),
      ),
      ['coffee', 'refund'],
    );
  });

  test('combines every filter with AND', () {
    final filter = TransactionFilter(
      types: {TransactionType.income},
      statuses: {TransactionStatus.completed},
      period: DateSpan(LocalDate(2026, 11, 1), LocalDate(2026, 11, 5)),
      query: 'sal',
    );
    expect(filter.activeCount, 4);
    expect(apply(filter), ['salary']);
  });

  test('period uses the local day (23:30 belongs to the 5th)', () {
    final onlyThe5th = TransactionFilter(
      period: DateSpan.singleDay(LocalDate(2026, 11, 5)),
    );
    expect(apply(onlyThe5th), ['salary', 'coffee']);
  });

  test(
    'search ignores case and accents and also looks at the counterparty',
    () {
      expect(apply(TransactionFilter(query: 'CAFE')), ['salary', 'coffee']);
      expect(apply(TransactionFilter(query: 'padaria sao')), ['coffee']);
      expect(apply(TransactionFilter(query: 'salario')), ['salary']);
      expect(apply(TransactionFilter(query: 'pizza')), isEmpty);
    },
  );

  test('copyWith changes one thing and can clear the period', () {
    final withPeriod = TransactionFilter(
      period: DateSpan.singleDay(LocalDate(2026, 11, 5)),
      query: 'cafe',
    );
    final cleared = withPeriod.copyWith(clearPeriod: true);
    expect(cleared.period, isNull);
    expect(cleared.query, 'cafe');
    expect(
      withPeriod.copyWith(types: {TransactionType.income}).period,
      withPeriod.period,
    );
  });

  test('compares by value regardless of set order', () {
    final a = TransactionFilter(
      statuses: {TransactionStatus.pending, TransactionStatus.failed},
    );
    final b = TransactionFilter(
      statuses: {TransactionStatus.failed, TransactionStatus.pending},
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(TransactionFilter(statuses: {TransactionStatus.failed})));
    expect(a.toString(), contains('pending'));
  });

  test('the filter sets cannot be changed from outside', () {
    final filter = TransactionFilter(types: {TransactionType.income});
    expect(
      () => filter.types.add(TransactionType.expense),
      throwsUnsupportedError,
    );
  });

  group('SearchText', () {
    test('cleans user input', () {
      expect(
        SearchText.cleanQuery('   café    da   padaria  '),
        'café da padaria',
      );
      expect(SearchText.cleanQuery('x' * 200), hasLength(SearchText.maxLength));
      expect(TransactionFilter(query: '   ').query, isEmpty);
    });

    test('normalizes accents used in Portuguese', () {
      expect(SearchText.normalize('ÁÉÍÓÚ àâêô ãõ ç Ü'), 'aeiou aaeo ao c u');
    });
  });
}
