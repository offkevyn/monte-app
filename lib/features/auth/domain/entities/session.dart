import 'package:meta/meta.dart';

import 'cpf.dart';

/// A signed-in customer.
@immutable
final class Session {
  Session({
    required this.accessToken,
    required this.cpf,
    required this.customerName,
    required this.accountLabel,
    required DateTime expiresAt,
  }) : expiresAt = expiresAt.toUtc();

  /// Sent to the API; kept only in the secure store, never shown or logged.
  final String accessToken;
  final Cpf cpf;
  final String customerName;

  /// `Conta 0001 · 12345-6`
  final String accountLabel;
  final DateTime expiresAt;

  String get firstName => customerName.trim().split(RegExp(r'\s+')).first;

  bool isExpiredAt(DateTime nowUtc) => !nowUtc.isBefore(expiresAt);

  @override
  bool operator ==(Object other) =>
      other is Session &&
      other.accessToken == accessToken &&
      other.cpf == cpf &&
      other.customerName == customerName &&
      other.accountLabel == accountLabel &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      Object.hash(accessToken, cpf, customerName, accountLabel, expiresAt);

  /// The token is left out so it can never leak through a log line.
  @override
  String toString() => 'Session($cpf, $customerName, expires $expiresAt)';
}
