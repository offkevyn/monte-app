import 'package:intl/intl.dart';

import 'money.dart';

/// Formats [Money] as Brazilian currency (`R$ 1.234,56`).
///
/// The integer part and the cents are formatted separately from the integer
/// value, so no `double` is created even for display.
final class MoneyFormatter {
  MoneyFormatter({String locale = 'pt_BR'})
    : _units = NumberFormat('#,##0', locale),
      _decimalSeparator = NumberFormat('#,##0', locale).symbols.DECIMAL_SEP;

  /// Non-breaking space between the symbol and the number, as `intl` does,
  /// so `R$` never wraps alone to the next line.
  static const _space = ' ';
  static const _symbol = r'R$';

  final NumberFormat _units;
  final String _decimalSeparator;

  /// `R$ 1.234,56`, or `-R$ 1.234,56` for negative amounts.
  ///
  /// With [showPlusSign], positive amounts get a leading `+`, used for
  /// incoming transactions so the direction never depends on color alone.
  String format(Money money, {bool showPlusSign = false}) {
    final absolute = money.cents.abs();
    final units = _units.format(absolute ~/ 100);
    final cents = (absolute % 100).toString().padLeft(2, '0');
    final sign = money.isNegative
        ? '-'
        : (showPlusSign && money.isPositive ? '+' : '');
    return '$sign$_symbol$_space$units$_decimalSeparator$cents';
  }
}
