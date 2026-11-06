import '../../../core/money/money.dart';
import '../../../core/money/money_formatter.dart';
import '../domain/entities/crypto_price.dart';

/// Texts for crypto numbers, computed from the exact integers (no double).
final class CryptoFormatter {
  const CryptoFormatter(this._money);

  final MoneyFormatter _money;

  static const _unitsPerCent = CryptoPrice.unitsPerReal ~/ 100;

  /// Non-breaking space, as in [MoneyFormatter], so `R$` never wraps alone.
  static const _space = ' ';
  static const _symbol = r'R$';

  /// `R$ 438.899,39` for a real or more; below that, up to four significant
  /// digits so small coins stay readable: `R$ 0,0000712`, `R$ 0,5012`.
  String price(CryptoPrice price, {bool showPlusSign = false}) {
    final units = price.units.abs();
    final sign = price.isNegative
        ? '-'
        : (showPlusSign && units > 0 ? '+' : '');
    if (units >= CryptoPrice.unitsPerReal) return '$sign${_cents(units)}';

    final fraction = units.toString().padLeft(CryptoPrice.places, '0');
    final firstDigit = fraction.indexOf(RegExp('[1-9]'));
    if (firstDigit < 0) return '$sign$_symbol${_space}0,00';
    final keep = (firstDigit + 4).clamp(2, CryptoPrice.places);
    final divisor = _pow10(CryptoPrice.places - keep);
    final rounded = (units + divisor ~/ 2) ~/ divisor;
    if (rounded >= _pow10(keep)) return '$sign${_cents(units)}';
    var digits = rounded.toString().padLeft(keep, '0');
    while (digits.length > 2 && digits.endsWith('0')) {
      digits = digits.substring(0, digits.length - 1);
    }
    return '$sign$_symbol${_space}0,$digits';
  }

  /// `▲ 2,41%`, `▼ 0,87%` or `0,00%`. The arrow carries the direction, so
  /// it never depends on color alone.
  String percent(PercentChange change) {
    final text = plainPercent(change);
    if (change.isPositive) return '▲ $text';
    if (change.isNegative) return '▼ $text';
    return text;
  }

  /// `2,41%` without direction, for when the arrow is already beside it.
  String plainPercent(PercentChange change) {
    final value = change.hundredths.abs();
    return '${value ~/ 100},${(value % 100).toString().padLeft(2, '0')}%';
  }

  /// `▲ R$ 10.330,12` for a price change.
  String change(CryptoPrice change) {
    final text = price(change.abs());
    if (change.isNegative) return '▼ $text';
    if (change.isZero) return text;
    return '▲ $text';
  }

  /// Big totals in words: `R$ 8,7 tri`, `R$ 120 mi`, `R$ 950,00`.
  String compact(Money money) {
    final reais = money.cents.abs() ~/ 100;
    for (final (size, word) in _scales) {
      if (reais >= size) {
        final tenths = (reais * 10 + size ~/ 2) ~/ size;
        final whole = tenths ~/ 10;
        final decimal = tenths % 10;
        final number = decimal == 0 ? '$whole' : '$whole,$decimal';
        final sign = money.isNegative ? '-' : '';
        return '$sign$_symbol$_space$number$_space$word';
      }
    }
    return _money.format(money);
  }

  static const _scales = [
    (1000000000000, 'tri'),
    (1000000000, 'bi'),
    (1000000, 'mi'),
    (1000, 'mil'),
  ];

  /// Rounds to cents (half up) and formats as money.
  String _cents(int units) =>
      _money.format(Money.cents((units + _unitsPerCent ~/ 2) ~/ _unitsPerCent));

  static int _pow10(int exponent) {
    var value = 1;
    for (var i = 0; i < exponent; i++) {
      value *= 10;
    }
    return value;
  }
}
