import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/failures/failure.dart';
import '../../../core/network/json_reader.dart';
import '../../../core/network/network_failures.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/secure_store.dart';
import '../../../core/time/clock.dart';
import '../domain/entities/cpf.dart';
import '../domain/entities/session.dart';
import '../domain/repositories/auth_repository.dart';

/// `POST /v1/auth/login` answer.
final class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    required this.expiresIn,
    required this.customerName,
    required this.account,
  });

  factory LoginResponseDto.fromJson(Object? source) {
    final json = JsonReader.of(source, 'login');
    final customer = JsonReader.of(json.json['customer'], 'customer');
    final expiresIn = json.integer('expires_in');
    if (expiresIn <= 0) {
      throw const FormatException('Field "expires_in" must be positive');
    }
    return LoginResponseDto(
      accessToken: json.string('access_token'),
      expiresIn: Duration(seconds: expiresIn),
      customerName: customer.string('name'),
      account: customer.string('account'),
    );
  }

  final String accessToken;
  final Duration expiresIn;
  final String customerName;
  final String account;
}

final class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// Throws on failure; the repository turns it into a `Failure`. Login is a
  /// POST, so the retry interceptor never repeats it (each try counts
  /// against the attempts limit).
  Future<LoginResponseDto> login(Cpf cpf, String password) async {
    final response = await _dio.post<Object?>(
      '/v1/auth/login',
      data: {'cpf': cpf.digits, 'password': password},
    );
    return LoginResponseDto.fromJson(response.data);
  }

  /// Reads the login-specific error bodies (attempts left, lock time).
  static Failure? mapLoginError(DioException error) {
    final response = error.response;
    final body = response?.data;
    final json = body is Map ? body : const <Object?, Object?>{};
    return switch (response?.statusCode) {
      401 => InvalidCredentialsFailure(
        attemptsLeft: json['attempts_left'] is int
            ? json['attempts_left'] as int
            : null,
      ),
      423 => AccountLockedFailure(
        retryAfter: json['retry_after_seconds'] is int
            ? Duration(seconds: json['retry_after_seconds'] as int)
            : null,
      ),
      _ => null,
    };
  }
}

/// Keeps the session in the secure store (Keystore / Keychain): the access
/// token is a credential and never goes to shared_preferences.
final class SessionStore {
  const SessionStore(this._store);

  final SecureStore _store;

  static const _sessionKey = 'monte.session.v1';
  static const _lastCpfKey = 'monte.last_cpf.v1';

  Future<void> save(Session session) async {
    await _store.write(
      _sessionKey,
      jsonEncode({
        'token': session.accessToken,
        'cpf': session.cpf.digits,
        'name': session.customerName,
        'account': session.accountLabel,
        'expires_at': session.expiresAt.toIso8601String(),
      }),
    );
    await _store.write(_lastCpfKey, session.cpf.digits);
  }

  /// A stored value that does not parse is treated as no session (and
  /// removed), never as a crash on startup.
  Future<Session?> read() async {
    final raw = await _store.read(_sessionKey);
    if (raw == null) return null;
    try {
      final json = JsonReader.of(jsonDecode(raw), 'session');
      final cpf = Cpf.tryParse(json.string('cpf'));
      if (cpf == null) throw const FormatException('Invalid stored CPF');
      return Session(
        accessToken: json.string('token'),
        cpf: cpf,
        customerName: json.string('name'),
        accountLabel: json.string('account'),
        expiresAt: json.instant('expires_at'),
      );
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<Cpf?> lastCpf() async {
    final raw = await _store.read(_lastCpfKey);
    return raw == null ? null : Cpf.tryParse(raw);
  }

  Future<void> clear() => _store.delete(_sessionKey);
}

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._sessions, this._clock);

  final AuthRemoteDataSource _remote;
  final SessionStore _sessions;
  final Clock _clock;

  @override
  Future<Result<Session>> signIn(Cpf cpf, String password) async {
    final result = await guardRequest(
      () => _remote.login(cpf, password),
      mapError: AuthRemoteDataSource.mapLoginError,
    );
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final dto):
        final session = Session(
          accessToken: dto.accessToken,
          cpf: cpf,
          customerName: dto.customerName,
          accountLabel: 'Conta ${dto.account}',
          expiresAt: _clock.nowUtc().add(dto.expiresIn),
        );
        try {
          await _sessions.save(session);
        } on Exception catch (error) {
          return Err(StorageFailure(error.runtimeType.toString()));
        }
        return Ok(session);
    }
  }

  @override
  Future<Session?> storedSession() => _sessions.read();

  @override
  Future<Cpf?> lastCpf() => _sessions.lastCpf();

  @override
  Future<void> signOut() => _sessions.clear();
}
