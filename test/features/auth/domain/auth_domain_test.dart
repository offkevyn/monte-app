import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/features/auth/domain/entities/cpf.dart';
import 'package:monte/features/auth/domain/entities/session.dart';
import 'package:monte/features/auth/domain/repositories/auth_repository.dart';
import 'package:monte/features/auth/domain/usecases/auth_usecases.dart';

final demoCpf = Cpf.tryParse('000.000.001-91')!;

Session sessionFor({DateTime? expiresAt}) => Session(
  accessToken: 'demo_token',
  cpf: demoCpf,
  customerName: 'Kevyn Melo',
  accountLabel: 'Conta 0001 · 12345-6',
  expiresAt: expiresAt ?? DateTime.utc(2026, 11, 6, 12),
);

class FakeAuthRepository implements AuthRepository {
  Session? stored;
  Cpf? last;
  Result<Session> answer = Ok(sessionFor());
  final calls = <String>[];

  @override
  Future<Result<Session>> signIn(Cpf cpf, String password) async {
    calls.add('signIn ${cpf.digits} $password');
    return answer;
  }

  @override
  Future<Session?> storedSession() async => stored;

  @override
  Future<Cpf?> lastCpf() async => last;

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    stored = null;
  }
}

void main() {
  group('Cpf', () {
    test('accepts valid numbers, masked or not', () {
      expect(Cpf.tryParse('000.000.001-91')?.digits, '00000000191');
      expect(Cpf.tryParse('00000000191'), isNotNull);
      expect(Cpf.tryParse('529.982.247-25'), isNotNull);
      expect(Cpf.tryParse(' 529 982 247 25 '), isNotNull);
    });

    test('rejects wrong check digits, sizes and repeated digits', () {
      for (final bad in [
        '',
        '123.456.789-00',
        '529.982.247-24',
        '0000000019',
        '000000001911',
        '111.111.111-11',
        '000.000.000-00',
        'abc.def.ghi-jk',
      ]) {
        expect(Cpf.tryParse(bad), isNull, reason: bad);
      }
    });

    test('a check digit that computes to 10 becomes 0', () {
      // 123.456.789-09: the second digit math gives 10 -> 0.
      expect(Cpf.tryParse('123.456.789-09'), isNotNull);
    });

    test('formats, masks and never prints the full number', () {
      expect(demoCpf.formatted, '000.000.001-91');
      expect(demoCpf.masked, '***.000.001-**');
      expect(demoCpf.toString(), isNot(contains('00000000191')));
      expect(demoCpf, Cpf.tryParse('00000000191'));
      expect(demoCpf.hashCode, Cpf.tryParse('00000000191').hashCode);
    });
  });

  group('Session', () {
    test('knows when it expired and the first name', () {
      final session = sessionFor(expiresAt: DateTime.utc(2026, 11, 6, 12));
      expect(session.isExpiredAt(DateTime.utc(2026, 11, 6, 11, 59)), isFalse);
      expect(session.isExpiredAt(DateTime.utc(2026, 11, 6, 12)), isTrue);
      expect(session.firstName, 'Kevyn');
    });

    test('never prints the token', () {
      expect(sessionFor().toString(), isNot(contains('demo_token')));
      expect(sessionFor(), sessionFor());
      expect(sessionFor().hashCode, sessionFor().hashCode);
    });
  });

  group('SignIn', () {
    test('does not spend an attempt on an empty password', () async {
      final repository = FakeAuthRepository();
      final result = await SignIn(repository)(demoCpf, '');
      expect(result.failureOrNull, isA<InvalidCredentialsFailure>());
      expect(repository.calls, isEmpty);
    });

    test('forwards CPF digits and password', () async {
      final repository = FakeAuthRepository();
      expect((await SignIn(repository)(demoCpf, 'monte123')).isOk, isTrue);
      expect(repository.calls, ['signIn 00000000191 monte123']);
    });
  });

  group('ResolveStart', () {
    final clock = FixedClock(DateTime.utc(2026, 11, 6, 10));

    test('no session: login with the last CPF', () async {
      final repository = FakeAuthRepository()..last = demoCpf;
      final start = await ResolveStart(repository, clock)(
        biometricsEnabled: true,
      );
      expect(start, isA<GoToLogin>());
      expect((start as GoToLogin).lastCpf, demoCpf);
    });

    test('expired session: signs out and asks for the password', () async {
      final repository = FakeAuthRepository()
        ..stored = sessionFor(expiresAt: DateTime.utc(2026, 11, 6, 9))
        ..last = demoCpf;
      final start = await ResolveStart(repository, clock)(
        biometricsEnabled: true,
      );
      expect(start, isA<GoToLogin>());
      expect(repository.calls, ['signOut']);
    });

    test('valid session with fingerprint on: unlock with it', () async {
      final repository = FakeAuthRepository()..stored = sessionFor();
      final start = await ResolveStart(repository, clock)(
        biometricsEnabled: true,
      );
      expect((start as UnlockWithBiometrics).session, sessionFor());
    });

    test(
      'valid session without fingerprint: password again, CPF filled',
      () async {
        final repository = FakeAuthRepository()..stored = sessionFor();
        final start = await ResolveStart(repository, clock)(
          biometricsEnabled: false,
        );
        expect((start as GoToLogin).lastCpf, demoCpf);
      },
    );
  });

  test('SignOut delegates to the repository', () async {
    final repository = FakeAuthRepository();
    await SignOut(repository)();
    expect(repository.calls, ['signOut']);
  });
}
