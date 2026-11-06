import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/network/api_client_factory.dart';
import 'package:monte/core/network/fake/fake_http_adapter.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';
import 'package:monte/core/storage/secure_store.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/features/auth/data/auth_data.dart';
import 'package:monte/features/auth/data/fake/fake_auth_server.dart';
import 'package:monte/features/auth/domain/entities/cpf.dart';

/// Repository -> Dio (real pipeline) -> fake adapter -> fake auth server.
void main() {
  final demo = Cpf.tryParse('000.000.001-91')!;
  final other = Cpf.tryParse('529.982.247-25')!;
  late FixedClock clock;
  late FakeBackendSettings settings;
  late FakeHttpAdapter adapter;
  late MemorySecureStore store;
  late AuthRepositoryImpl repository;

  setUp(() {
    clock = FixedClock(DateTime.utc(2026, 11, 6, 10));
    settings = FakeBackendSettings();
    final server = FakeAuthServer(
      settings: settings,
      clock: clock,
      random: Random(1),
    );
    adapter = FakeHttpAdapter(
      settings: settings,
      routes: server.routes,
      sleep: (_) async {},
    );
    final dio = ApiClientFactory.create(
      baseUrl: ApiClientFactory.fakeBankBaseUrl,
      adapter: adapter,
      sleep: (_) async {},
    );
    store = MemorySecureStore();
    repository = AuthRepositoryImpl(
      AuthRemoteDataSource(dio),
      SessionStore(store),
      clock,
    );
  });

  test('right password: session with name, account and expiry', () async {
    final session = (await repository.signIn(demo, 'monte123')).valueOrNull!;

    expect(session.customerName, 'Kevyn Melo');
    expect(session.accountLabel, 'Conta 0001 · 12345-6');
    expect(session.expiresAt, clock.nowUtc().add(const Duration(hours: 12)));
    expect(session.accessToken, startsWith('demo_'));
    expect(await repository.storedSession(), session);
    expect(await repository.lastCpf(), demo);
  });

  test('wrong password counts down, then locks for 5 minutes', () async {
    expect(
      (await repository.signIn(demo, 'nope')).failureOrNull,
      const InvalidCredentialsFailure(attemptsLeft: 2),
    );
    expect(
      (await repository.signIn(demo, 'nope')).failureOrNull,
      const InvalidCredentialsFailure(attemptsLeft: 1),
    );
    expect(
      (await repository.signIn(demo, 'nope')).failureOrNull,
      const AccountLockedFailure(retryAfter: Duration(minutes: 5)),
    );
    // Even the right password is refused while locked.
    clock.advance(const Duration(minutes: 2));
    expect(
      (await repository.signIn(demo, 'monte123')).failureOrNull,
      const AccountLockedFailure(retryAfter: Duration(minutes: 3)),
    );
    clock.advance(const Duration(minutes: 3));
    expect((await repository.signIn(demo, 'monte123')).isOk, isTrue);
    expect(await repository.storedSession(), isNotNull);
  });

  test('a success resets the counter', () async {
    await repository.signIn(demo, 'nope');
    await repository.signIn(demo, 'monte123');
    expect(
      (await repository.signIn(demo, 'nope')).failureOrNull,
      const InvalidCredentialsFailure(attemptsLeft: 2),
    );
  });

  test('unknown CPF gets the same answer as a wrong password', () async {
    expect(
      (await repository.signIn(other, 'monte123')).failureOrNull,
      const InvalidCredentialsFailure(attemptsLeft: 2),
    );
  });

  test('wrong password scenario rejects even the demo password', () async {
    settings.scenario = FakeScenario.wrongPassword;
    expect(
      (await repository.signIn(demo, 'monte123')).failureOrNull,
      isA<InvalidCredentialsFailure>(),
    );
  });

  test('offline: no connection, and the POST is never retried', () async {
    settings.scenario = FakeScenario.offline;
    expect(
      (await repository.signIn(demo, 'monte123')).failureOrNull,
      const NoConnectionFailure(),
    );
    settings.scenario = FakeScenario.serverError;
    expect(
      (await repository.signIn(demo, 'monte123')).failureOrNull,
      const ServerFailure(statusCode: 500),
    );
    expect(adapter.requestCount, 1);
  });

  test('sign out forgets the session but keeps the CPF', () async {
    await repository.signIn(demo, 'monte123');
    await repository.signOut();
    expect(await repository.storedSession(), isNull);
    expect(await repository.lastCpf(), demo);
  });

  test(
    'a stored session that does not parse is dropped, not a crash',
    () async {
      store.values['monte.session.v1'] = '{"token": 42}';
      expect(await repository.storedSession(), isNull);
      expect(store.values.containsKey('monte.session.v1'), isFalse);

      store.values['monte.session.v1'] = jsonEncode({
        'token': 't',
        'cpf': '12345678900',
        'name': 'X',
        'account': 'Y',
        'expires_at': '2026-11-06T10:00:00Z',
      });
      expect(await repository.storedSession(), isNull);
    },
  );

  test('a garbled stored CPF is ignored', () async {
    store.values['monte.last_cpf.v1'] = 'abc';
    expect(await repository.lastCpf(), isNull);
  });

  group('server input validation', () {
    test('malformed login bodies get 400', () async {
      final dio = ApiClientFactory.create(
        baseUrl: ApiClientFactory.fakeBankBaseUrl,
        adapter: adapter,
      );
      for (final body in <Object?>[
        null,
        'text',
        {'cpf': '123', 'password': 'x'},
        {'cpf': 191, 'password': 'x'},
        {'cpf': '00000000191'},
      ]) {
        final status = await dio
            .post<Object?>('/v1/auth/login', data: body)
            .then((r) => r.statusCode, onError: (Object e) => 400);
        expect(status, 400, reason: '$body');
      }
    });
  });

  group('LoginResponseDto', () {
    test('rejects a non-positive expiry and missing customer', () {
      expect(
        () => LoginResponseDto.fromJson({
          'access_token': 't',
          'expires_in': 0,
          'customer': {'name': 'a', 'account': 'b'},
        }),
        throwsFormatException,
      );
      expect(
        () =>
            LoginResponseDto.fromJson({'access_token': 't', 'expires_in': 10}),
        throwsFormatException,
      );
    });
  });
}
