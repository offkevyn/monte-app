import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/security/biometric_authenticator.dart';
import 'package:monte/core/storage/app_preferences.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/features/auth/domain/usecases/auth_usecases.dart';
import 'package:monte/features/auth/presentation/current_session.dart';
import 'package:monte/features/auth/presentation/login/login_cubit.dart';
import 'package:monte/features/auth/presentation/splash/splash_cubit.dart';

import '../domain/auth_domain_test.dart'
    show FakeAuthRepository, demoCpf, sessionFor;

class FakeBiometrics implements BiometricAuthenticator {
  bool available = true;
  bool confirms = true;
  final reasons = <String>[];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    reasons.add(reason);
    return confirms;
  }
}

void main() {
  late FakeAuthRepository repository;
  late MemoryAppPreferences preferences;
  late FakeBiometrics biometrics;
  late CurrentSession current;

  setUp(() {
    repository = FakeAuthRepository();
    preferences = MemoryAppPreferences();
    biometrics = FakeBiometrics();
    current = CurrentSession();
  });

  group('LoginCubit', () {
    LoginCubit build() =>
        LoginCubit(SignIn(repository), preferences, biometrics, current);

    test('shows field errors and does not call the server', () async {
      final cubit = build()..cpfChanged('123.456.789-00');
      await cubit.submit();

      expect(cubit.state.cpfError, LoginCubit.invalidCpf);
      expect(cubit.state.passwordError, LoginCubit.emptyPassword);
      expect(repository.calls, isEmpty);
    });

    test('typing clears the error of that field', () async {
      final cubit = build();
      await cubit.submit();
      cubit.cpfChanged('0');
      expect(cubit.state.cpfError, isNull);
      expect(cubit.state.passwordError, LoginCubit.emptyPassword);
      cubit.passwordChanged('x');
      expect(cubit.state.passwordError, isNull);
    });

    test('demo shortcut fills both fields', () {
      final cubit = build()..fillDemoAccount();
      expect(cubit.state.cpf, '000.000.001-91');
      expect(cubit.state.password, 'monte123');
    });

    test('prefill uses the last CPF, if any', () {
      expect((build()..prefill(demoCpf)).state.cpf, '000.000.001-91');
      expect((build()..prefill(null)).state.cpf, '');
    });

    test('toggles the password visibility', () {
      final cubit = build()..togglePasswordVisibility();
      expect(cubit.state.obscurePassword, isFalse);
    });

    test('success with fingerprint available: offers it once', () async {
      final cubit = build()..fillDemoAccount();
      final steps = <LoginStep>[];
      final sub = cubit.stream.listen((s) => steps.add(s.step));

      await cubit.submit();
      // Stream events are delivered asynchronously.
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(steps, [LoginStep.submitting, LoginStep.offeringBiometrics]);
      expect(current.value, sessionFor());
      expect(cubit.state.password, isEmpty);
    });

    test('accepting the fingerprint confirms it and remembers', () async {
      final cubit = build()..fillDemoAccount();
      await cubit.submit();
      await cubit.acceptBiometrics();

      expect(biometrics.reasons, hasLength(1));
      expect(preferences.biometrics, isTrue);
      expect(preferences.offerShown, isTrue);
      expect(cubit.state.step, LoginStep.done);
    });

    test('a failed confirmation leaves the fingerprint off', () async {
      biometrics.confirms = false;
      final cubit = build()..fillDemoAccount();
      await cubit.submit();
      await cubit.acceptBiometrics();
      expect(preferences.biometrics, isFalse);
      expect(cubit.state.step, LoginStep.done);
    });

    test('declining never asks again', () async {
      final cubit = build()..fillDemoAccount();
      await cubit.submit();
      await cubit.declineBiometrics();
      expect(preferences.offerShown, isTrue);
      expect(preferences.biometrics, isFalse);
      expect(cubit.state.step, LoginStep.done);
    });

    test('no offer when already asked or no hardware', () async {
      preferences.offerShown = true;
      final asked = build()..fillDemoAccount();
      await asked.submit();
      expect(asked.state.step, LoginStep.done);

      preferences.offerShown = false;
      biometrics.available = false;
      final noHardware = build()..fillDemoAccount();
      await noHardware.submit();
      expect(noHardware.state.step, LoginStep.done);
    });

    test(
      'wrong password: message, password cleared, back to editing',
      () async {
        repository.answer = const Err(
          InvalidCredentialsFailure(attemptsLeft: 2),
        );
        final cubit = build()..fillDemoAccount();
        await cubit.submit();

        expect(cubit.state.step, LoginStep.editing);
        expect(
          cubit.state.failure,
          const InvalidCredentialsFailure(attemptsLeft: 2),
        );
        expect(cubit.state.password, isEmpty);
        expect(cubit.state.cpf, '000.000.001-91');
        expect(current.isSignedIn, isFalse);

        cubit.passwordChanged('a');
        expect(cubit.state.failure, isNull);
      },
    );

    test('offline keeps the typed password for a retry', () async {
      repository.answer = const Err(NoConnectionFailure());
      final cubit = build()..fillDemoAccount();
      await cubit.submit();
      expect(cubit.state.password, 'monte123');
      expect(cubit.state.failure, const NoConnectionFailure());
    });

    test('a second tap while submitting is ignored', () async {
      final cubit = build()..fillDemoAccount();
      await Future.wait([cubit.submit(), cubit.submit()]);
      expect(repository.calls, hasLength(1));
    });

    test('state equality covers every field', () {
      expect(const LoginState(), const LoginState());
      expect(const LoginState(cpf: '1'), isNot(const LoginState()));
      expect(const LoginState().isSubmitting, isFalse);
    });
  });

  group('SplashCubit', () {
    final clock = FixedClock(DateTime.utc(2026, 11, 6, 10));

    SplashCubit build() => SplashCubit(
      ResolveStart(repository, clock),
      preferences,
      biometrics,
      current,
    );

    test('no session goes to the login', () async {
      final cubit = build();
      await cubit.start();
      expect(cubit.state, isA<SplashGoToLogin>());
    });

    test('fingerprint confirmed opens the account', () async {
      repository.stored = sessionFor();
      preferences.biometrics = true;
      final cubit = build();
      await cubit.start();
      expect(cubit.state, isA<SplashGoHome>());
      expect(current.value, sessionFor());
    });

    test('fingerprint refused falls back to the password', () async {
      repository.stored = sessionFor();
      preferences.biometrics = true;
      biometrics.confirms = false;
      final cubit = build();
      await cubit.start();
      expect((cubit.state as SplashGoToLogin).lastCpf, demoCpf);
      expect(current.isSignedIn, isFalse);
    });
  });

  test('CurrentSession starts and ends', () {
    final session = CurrentSession()..start(sessionFor());
    expect(session.isSignedIn, isTrue);
    session.end();
    expect(session.value, isNull);
  });
}
