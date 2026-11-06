import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';

void main() {
  group('Money.parse', () {
    test('reads decimal strings into exact cents', () {
      expect(Money.parse('1234.56'), const Money.cents(123456));
      expect(Money.parse('1234.5'), const Money.cents(123450));
      expect(Money.parse('10'), const Money.cents(1000));
      expect(Money.parse('0.07'), const Money.cents(7));
      expect(Money.parse('-0.07'), const Money.cents(-7));
      expect(Money.parse(' 3.20 '), const Money.cents(320));
    });

    test('rejects anything that would need rounding or guessing', () {
      for (final input in ['', 'abc', '1,50', '1.234', '12.345', '1e3', '.5']) {
        expect(() => Money.parse(input), throwsFormatException, reason: input);
        expect(Money.tryParse(input), isNull, reason: input);
      }
    });

    test('has no floating point drift (0.1 + 0.2 == 0.3)', () {
      expect(Money.parse('0.1') + Money.parse('0.2'), Money.parse('0.3'));
    });
  });

  group('Money arithmetic', () {
    const a = Money.cents(1050);
    const b = Money.cents(300);

    test('adds, subtracts and negates', () {
      expect(a + b, const Money.cents(1350));
      expect(b - a, const Money.cents(-750));
      expect(-a, const Money.cents(-1050));
      expect((b - a).abs(), const Money.cents(750));
    });

    test('sums a list, empty list is zero', () {
      expect(Money.sum([a, b, -b]), a);
      expect(Money.sum(const []), Money.zero);
    });

    test('knows its sign', () {
      expect(Money.zero.isZero, isTrue);
      expect(a.isPositive, isTrue);
      expect((-a).isNegative, isTrue);
    });

    test('compares and orders', () {
      expect(a > b, isTrue);
      expect(b < a, isTrue);
      expect([a, b, Money.zero]..sort(), [Money.zero, b, a]);
      expect(const Money.cents(5).hashCode, const Money.cents(5).hashCode);
    });
  });
}
