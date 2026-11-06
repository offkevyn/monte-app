/// Exact conversion of decimal numbers to integers with a fixed number of
/// places, used wherever a value arrives with a fraction (an API price, a
/// percentage) and must not go through `double` arithmetic.
abstract final class ScaledDecimal {
  static final _pattern = RegExp(
    r'^([+-])?(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$',
  );
  static final _maxInt = BigInt.parse('9223372036854775807');

  /// `"438899.39"` with 8 places is `43889939000000`. Accepts the exponent
  /// form Dart prints for very small or very large numbers (`"7.12e-7"`).
  ///
  /// Extra places are rounded half away from zero, the way a person would
  /// round a price on paper. Throws a [FormatException] for anything that is
  /// not a number or does not fit in 64 bits.
  static int parse(String text, int places) {
    final match = _pattern.firstMatch(text.trim());
    final whole = match?.group(2) ?? '';
    final fraction = match?.group(3) ?? '';
    if (match == null || (whole.isEmpty && fraction.isEmpty)) {
      throw FormatException('Invalid decimal number', text);
    }
    final digits = BigInt.parse(
      '$whole$fraction'.isEmpty ? '0' : '$whole$fraction',
    );
    final exponent = int.parse(match.group(4) ?? '0');
    final shift = exponent - fraction.length + places;

    BigInt scaled;
    if (shift >= 0) {
      scaled = digits * BigInt.from(10).pow(shift);
    } else {
      final divisor = BigInt.from(10).pow(-shift);
      scaled = digits ~/ divisor;
      if ((digits % divisor) * BigInt.two >= divisor) scaled += BigInt.one;
    }
    if (scaled > _maxInt) {
      throw FormatException('Decimal number too large', text);
    }
    final value = scaled.toInt();
    return match.group(1) == '-' ? -value : value;
  }

  /// Same as [parse] for a number that came decoded from JSON. A `double`
  /// is read through its shortest text form (`0.1` stays `"0.1"`), so the
  /// binary rounding error of the double never reaches the result.
  static int fromJsonNumber(num value, int places) {
    if (!value.isFinite) {
      throw FormatException('Number is not finite', '$value');
    }
    return parse(value.toString(), places);
  }
}
