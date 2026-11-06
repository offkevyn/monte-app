import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/scaled_decimal.dart';

void main() {
  group('ScaledDecimal.parse', () {
    test('scales plain decimals exactly', () {
      expect(ScaledDecimal.parse('438899.39', 8), 43889939000000);
      expect(ScaledDecimal.parse('10', 2), 1000);
      expect(ScaledDecimal.parse('0.1', 2), 10);
      expect(ScaledDecimal.parse('-2.5', 2), -250);
      expect(ScaledDecimal.parse('+3', 0), 3);
    });

    test('reads the exponent form Dart prints for tiny and huge numbers', () {
      expect(ScaledDecimal.parse('7.12e-7', 8), 71);
      expect(ScaledDecimal.parse('1e-8', 8), 1);
      expect(ScaledDecimal.parse('1.5E3', 2), 150000);
      expect(ScaledDecimal.parse('1.5e2', 0), 150);
    });

    test('rounds extra places half away from zero', () {
      expect(ScaledDecimal.parse('0.125', 2), 13);
      expect(ScaledDecimal.parse('0.124', 2), 12);
      expect(ScaledDecimal.parse('-0.125', 2), -13);
      expect(ScaledDecimal.parse('0.000000005', 8), 1);
      expect(ScaledDecimal.parse('0.000000004', 8), 0);
    });

    test('rejects what is not a number or does not fit 64 bits', () {
      for (final bad in ['', ' ', '.', 'abc', '1,5', '1.2.3', 'e5', '--1']) {
        expect(
          () => ScaledDecimal.parse(bad, 2),
          throwsFormatException,
          reason: bad,
        );
      }
      expect(() => ScaledDecimal.parse('1e30', 8), throwsFormatException);
    });
  });

  group('ScaledDecimal.fromJsonNumber', () {
    test('goes through the shortest text, not the binary value', () {
      // 0.1 + 0.2 in binary is 0.30000000000000004.
      expect(ScaledDecimal.fromJsonNumber(0.1, 2), 10);
      expect(ScaledDecimal.fromJsonNumber(0.0000712, 8), 7120);
      expect(ScaledDecimal.fromJsonNumber(438899.39, 8), 43889939000000);
      expect(ScaledDecimal.fromJsonNumber(42, 2), 4200);
    });

    test('rejects NaN and infinity', () {
      expect(
        () => ScaledDecimal.fromJsonNumber(double.nan, 2),
        throwsFormatException,
      );
      expect(
        () => ScaledDecimal.fromJsonNumber(double.infinity, 2),
        throwsFormatException,
      );
    });
  });
}
