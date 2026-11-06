import 'package:meta/meta.dart';

import '../../../../core/money/money.dart';
import '../../../../core/money/scaled_decimal.dart';

/// A crypto quote in reais, stored as an integer of 1/100,000,000 of a real
/// (8 places, the same precision as a satoshi).
///
/// It is not [Money]: an account balance is always whole cents, but a coin
/// can be worth R$ 0,0000712. Rounding that to cents would show R$ 0,00. Both
/// types avoid `double`, so arithmetic stays exact.
@immutable
final class CryptoPrice implements Comparable<CryptoPrice> {
  const CryptoPrice.units(this.units);

  /// Parses a decimal string such as `"438899.39"` or `"7.12e-5"`.
  factory CryptoPrice.parse(String text) =>
      CryptoPrice.units(ScaledDecimal.parse(text, places));

  /// Reads a price that came as a JSON number.
  factory CryptoPrice.fromJsonNumber(num value) =>
      CryptoPrice.units(ScaledDecimal.fromJsonNumber(value, places));

  static const places = 8;
  static const unitsPerReal = 100000000;
  static const zero = CryptoPrice.units(0);

  final int units;

  bool get isNegative => units < 0;

  bool get isZero => units == 0;

  CryptoPrice abs() => CryptoPrice.units(units.abs());

  CryptoPrice operator -(CryptoPrice other) =>
      CryptoPrice.units(units - other.units);

  CryptoPrice operator +(CryptoPrice other) =>
      CryptoPrice.units(units + other.units);

  bool operator <(CryptoPrice other) => units < other.units;

  bool operator >(CryptoPrice other) => units > other.units;

  /// Only for drawing a chart, where a pixel is far coarser than the
  /// rounding of a double. Never used for arithmetic or display.
  double toChartValue() => units / unitsPerReal;

  @override
  int compareTo(CryptoPrice other) => units.compareTo(other.units);

  @override
  bool operator ==(Object other) =>
      other is CryptoPrice && other.units == units;

  @override
  int get hashCode => units.hashCode;

  @override
  String toString() => 'CryptoPrice($units units)';
}

/// A percentage with two decimal places, as hundredths of a percent:
/// 2,41% is `241`.
@immutable
final class PercentChange {
  const PercentChange.hundredths(this.hundredths);

  factory PercentChange.fromJsonNumber(num value) =>
      PercentChange.hundredths(ScaledDecimal.fromJsonNumber(value, 2));

  final int hundredths;

  bool get isPositive => hundredths > 0;

  bool get isNegative => hundredths < 0;

  @override
  bool operator ==(Object other) =>
      other is PercentChange && other.hundredths == hundredths;

  @override
  int get hashCode => hundredths.hashCode;

  @override
  String toString() => 'PercentChange($hundredths/100 %)';
}
