import 'package:flutter/foundation.dart';

/// An amount of Brazilian reais stored as an integer number of cents.
///
/// Money never goes through `double`: `0.1 + 0.2` is not `0.3` in binary
/// floating point, and a statement that is off by one cent is a bug a bank
/// cannot ship. All arithmetic here is exact integer arithmetic.
@immutable
final class Money implements Comparable<Money> {
  const Money.cents(this.cents);

  /// Parses a decimal string with a dot separator, as APIs usually send it:
  /// `"1234.5"`, `"-0.07"`, `"10"`. At most two decimal places are accepted,
  /// because rounding silently would hide a data problem.
  ///
  /// Throws a [FormatException] for anything else.
  factory Money.parse(String input) {
    final match = _decimalPattern.firstMatch(input.trim());
    if (match == null) {
      throw FormatException('Invalid money amount', input);
    }
    final isNegative = match.group(1) != null;
    final units = int.parse(match.group(2)!);
    final fraction = int.parse((match.group(3) ?? '').padRight(2, '0'));
    final cents = units * 100 + fraction;
    return Money.cents(isNegative ? -cents : cents);
  }

  /// Same as [Money.parse], but returns `null` instead of throwing.
  static Money? tryParse(String input) {
    try {
      return Money.parse(input);
    } on FormatException {
      return null;
    }
  }

  static const zero = Money.cents(0);

  static final _decimalPattern = RegExp(r'^(-)?(\d+)(?:\.(\d{1,2}))?$');

  final int cents;

  bool get isZero => cents == 0;

  bool get isNegative => cents < 0;

  bool get isPositive => cents > 0;

  Money abs() => Money.cents(cents.abs());

  Money operator +(Money other) => Money.cents(cents + other.cents);

  Money operator -(Money other) => Money.cents(cents - other.cents);

  Money operator -() => Money.cents(-cents);

  bool operator <(Money other) => cents < other.cents;

  bool operator >(Money other) => cents > other.cents;

  /// Sums a list of amounts; an empty list is [Money.zero].
  static Money sum(Iterable<Money> amounts) =>
      amounts.fold(zero, (total, amount) => total + amount);

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => 'Money($cents cents)';
}
