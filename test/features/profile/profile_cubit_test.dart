import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:monte/core/platform/app_info.dart';
import 'package:monte/core/storage/app_preferences.dart';
import 'package:monte/features/auth/domain/usecases/auth_usecases.dart';
import 'package:monte/features/auth/presentation/current_session.dart';
import 'package:monte/features/crypto/domain/repositories/market_repository.dart';
import 'package:monte/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:monte/features/profile/presentation/profile_cubit.dart';

import '../auth/domain/auth_domain_test.dart'
    show FakeAuthRepository, sessionFor;
import '../auth/presentation/auth_cubits_test.dart' show FakeBiometrics;

class _MockLedger extends Mock implements LedgerRepository {}

class _MockMarket extends Mock implements MarketRepository {}

class FixedAppInfo implements AppInfo {
  const FixedAppInfo([this.value = '1.0.0']);

  final String? value;

  @override
  Future<String?> version() async => value;
}

void main() {
  late MemoryAppPreferences preferences;
  late FakeBiometrics biometrics;
  late FakeAuthRepository auth;
  late _MockLedger ledger;
  late _MockMarket market;
  late CurrentSession session;

  setUp(() {
    preferences = MemoryAppPreferences();
    biometrics = FakeBiometrics();
    auth = FakeAuthRepository()..stored = sessionFor();
    ledger = _MockLedger();
    market = _MockMarket();
    when(ledger.clear).thenAnswer((_) async {});
    when(market.clear).thenAnswer((_) async {});
    session = CurrentSession()..start(sessionFor());
  });

  ProfileCubit build() => ProfileCubit(
    preferences: preferences,
    biometrics: biometrics,
    appInfo: const FixedAppInfo(),
    signOut: SignOut(auth),
    ledger: ledger,
    market: market,
    session: session,
  );

  test('load reads the switches, the device support and the version', () async {
    preferences
      ..biometrics = true
      ..balanceBiometrics = false;
    final cubit = build();
    await cubit.load();
    expect(
      cubit.state,
      const ProfileState(
        loaded: true,
        biometricsAvailable: true,
        loginBiometrics: true,
        version: '1.0.0',
      ),
    );
  });

  group('login with fingerprint', () {
    test('turning on asks for the fingerprint and saves it', () async {
      final cubit = build();
      await cubit.setLoginBiometrics(enabled: true);
      expect(biometrics.reasons, hasLength(1));
      expect(preferences.biometrics, isTrue);
      expect(preferences.offerShown, isTrue);
      expect(cubit.state.loginBiometrics, isTrue);
    });

    test('a cancelled fingerprint keeps it off', () async {
      biometrics.confirms = false;
      final cubit = build();
      await cubit.setLoginBiometrics(enabled: true);
      expect(preferences.biometrics, isFalse);
      expect(cubit.state.loginBiometrics, isFalse);
    });

    test('turning off does not ask', () async {
      preferences.biometrics = true;
      final cubit = build();
      await cubit.load();
      await cubit.setLoginBiometrics(enabled: false);
      expect(biometrics.reasons, isEmpty);
      expect(preferences.biometrics, isFalse);
      expect(cubit.state.loginBiometrics, isFalse);
    });
  });

  group('fingerprint for the balance', () {
    test('turning on asks for the fingerprint', () async {
      final cubit = build();
      await cubit.setBalanceBiometrics(enabled: true);
      expect(biometrics.reasons.single, contains('proteger o saldo'));
      expect(preferences.balanceBiometrics, isTrue);
      expect(cubit.state.balanceBiometrics, isTrue);
    });

    test('turning off also asks, and a failure keeps the protection', () async {
      preferences.balanceBiometrics = true;
      biometrics.confirms = false;
      final cubit = build();
      await cubit.load();
      await cubit.setBalanceBiometrics(enabled: false);
      expect(biometrics.reasons.single, contains('tirar a proteção'));
      expect(preferences.balanceBiometrics, isTrue);
      expect(cubit.state.balanceBiometrics, isTrue);
    });
  });

  test('sign out wipes the session and both local databases', () async {
    final cubit = build();
    await cubit.signOut();
    expect(auth.calls, contains('signOut'));
    expect(auth.stored, isNull);
    verify(ledger.clear).called(1);
    verify(market.clear).called(1);
    expect(session.isSignedIn, isFalse);
    expect(cubit.state.signingOut, isTrue);

    // A second tap while it runs does nothing.
    await cubit.signOut();
    verifyNever(ledger.clear);
  });
}
