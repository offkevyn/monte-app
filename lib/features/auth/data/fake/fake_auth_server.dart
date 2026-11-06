import 'dart:math';

import '../../../../core/network/fake/fake_http_adapter.dart';
import '../../../../core/network/fake/fake_scenario.dart';
import '../../../../core/security/random_hex.dart';
import '../../../../core/time/clock.dart';

/// Login endpoint of the simulated bank.
///
/// Behaves like a careful real one: the same answer for an unknown CPF and
/// a wrong password (no account enumeration), a counter of wrong attempts
/// per CPF and a temporary lock after [maxAttempts].
final class FakeAuthServer {
  FakeAuthServer({required this.settings, required this._clock, Random? random})
    : _random = random ?? Random.secure();

  static const demoCpf = '00000000191';
  static const demoPassword = 'monte123';
  static const maxAttempts = 3;
  static const lockDuration = Duration(minutes: 5);
  static const sessionDuration = Duration(hours: 12);

  final FakeBackendSettings settings;
  final Clock _clock;
  final Random _random;

  final _failures = <String, int>{};
  final _lockedUntil = <String, DateTime>{};

  List<FakeRoute> get routes => [FakeRoute('POST', '/v1/auth/login', _login)];

  FakeResponse _login(FakeRequest request) {
    final body = request.body;
    if (body is! Map ||
        body['cpf'] is! String ||
        body['password'] is! String ||
        !RegExp(r'^\d{11}$').hasMatch(body['cpf'] as String)) {
      return FakeResponse.error(400, 'invalid_request');
    }
    final cpf = body['cpf'] as String;
    final password = body['password'] as String;
    final now = _clock.nowUtc();

    final lockedUntil = _lockedUntil[cpf];
    if (lockedUntil != null && now.isBefore(lockedUntil)) {
      return _locked(lockedUntil.difference(now));
    }
    _lockedUntil.remove(cpf);

    final accepted =
        settings.scenario != FakeScenario.wrongPassword &&
        cpf == demoCpf &&
        password == demoPassword;
    if (accepted) {
      _failures.remove(cpf);
      return FakeResponse(200, {
        'access_token': _token(),
        'expires_in': sessionDuration.inSeconds,
        'customer': {'name': 'Kevyn Melo', 'account': '0001 · 12345-6'},
      });
    }

    final failures = (_failures[cpf] ?? 0) + 1;
    if (failures >= maxAttempts) {
      _failures.remove(cpf);
      _lockedUntil[cpf] = now.add(lockDuration);
      return _locked(lockDuration);
    }
    _failures[cpf] = failures;
    return FakeResponse(401, {
      'error': 'invalid_credentials',
      'attempts_left': maxAttempts - failures,
    });
  }

  FakeResponse _locked(Duration wait) => FakeResponse(423, {
    'error': 'account_locked',
    'retry_after_seconds': wait.inSeconds,
  });

  String _token() => 'demo_${randomHex(_random, 16)}';
}
