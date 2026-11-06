import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/money/money.dart';
import 'package:monte/core/money/money_formatter.dart';

void main() {
  final formatter = MoneyFormatter();
  // Formatted values use a non-breaking space after R$.
  String brl(String digits) => 'R\$ $digits';

  test('formats in pt-BR with thousands and decimal separators', () {
    expect(formatter.format(Money.zero), brl('0,00'));
    expect(formatter.format(const Money.cents(5)), brl('0,05'));
    expect(formatter.format(const Money.cents(123456)), brl('1.234,56'));
    expect(formatter.format(const Money.cents(100000000)), brl('1.000.000,00'));
  });

  test('puts the minus sign before the symbol', () {
    expect(formatter.format(const Money.cents(-123456)), '-${brl('1.234,56')}');
  });

  test('adds a plus sign only when asked and only for positives', () {
    expect(
      formatter.format(const Money.cents(5000), showPlusSign: true),
      '+${brl('50,00')}',
    );
    expect(formatter.format(Money.zero, showPlusSign: true), brl('0,00'));
    expect(
      formatter.format(const Money.cents(-5000), showPlusSign: true),
      '-${brl('50,00')}',
    );
  });

  test('keeps precision beyond the range where double loses cents', () {
    // 2^53 + 1 cents cannot be represented exactly as a double.
    const huge = Money.cents(9007199254740993);
    expect(formatter.format(huge), brl('90.071.992.547.409,93'));
  });
}
