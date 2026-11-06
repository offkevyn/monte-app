import 'package:meta/meta.dart';

/// A Brazilian CPF that passed the check digit validation.
///
/// Only [Cpf.tryParse] creates one, so any `Cpf` in the code is known to be
/// valid: validation happens once, at the border.
@immutable
final class Cpf {
  const Cpf._(this.digits);

  /// Accepts masked (`000.000.001-91`) or plain input. Returns `null` for
  /// anything that is not a valid CPF.
  static Cpf? tryParse(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return null;
    // 000.000.000-00, 111.111.111-11... pass the math but are not real.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return null;

    final numbers = digits.split('').map(int.parse).toList();
    if (_checkDigit(numbers.sublist(0, 9)) != numbers[9]) return null;
    if (_checkDigit(numbers.sublist(0, 10)) != numbers[10]) return null;
    return Cpf._(digits);
  }

  /// Weighted sum with weights from (length + 1) down to 2, mod 11.
  static int _checkDigit(List<int> numbers) {
    var sum = 0;
    for (var i = 0; i < numbers.length; i++) {
      sum += numbers[i] * (numbers.length + 1 - i);
    }
    final rest = (sum * 10) % 11;
    return rest == 10 ? 0 : rest;
  }

  /// Eleven digits, no punctuation, as the API expects.
  final String digits;

  /// `000.000.001-91`
  String get formatted =>
      '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
      '${digits.substring(6, 9)}-${digits.substring(9)}';

  /// `***.000.001-**`, for places where the full number is not needed.
  String get masked =>
      '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';

  @override
  bool operator ==(Object other) => other is Cpf && other.digits == digits;

  @override
  int get hashCode => digits.hashCode;

  /// Masked on purpose: a CPF should not end up in logs in full.
  @override
  String toString() => 'Cpf($masked)';
}
