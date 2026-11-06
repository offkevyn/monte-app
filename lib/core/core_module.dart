import 'package:flutter_modular/flutter_modular.dart';

import 'money/money_formatter.dart';
import 'network/fake/fake_scenario.dart';
import 'security/biometric_authenticator.dart';
import 'storage/app_preferences.dart';
import 'storage/encrypted_database.dart';
import 'storage/secure_store.dart';
import 'time/clock.dart';
import 'time/local_calendar.dart';

/// Dependencies shared by every feature. Feature modules list it in
/// `imports` and receive these binds by their interface type.
///
/// Binds are written as factories with `Modular.get` so every constructor
/// argument is explicit, instead of letting the injector guess optional
/// parameters.
class CoreModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i
      ..addSingleton<Clock>(SystemClock.new)
      ..addSingleton<LocalCalendar>(DeviceCalendar.new)
      ..addSingleton<MoneyFormatter>(() => MoneyFormatter())
      ..addSingleton<SecureStore>(() => const PlatformSecureStore())
      ..addSingleton<AppPreferences>(() => SharedAppPreferences())
      ..addSingleton<BiometricAuthenticator>(
        () => LocalBiometricAuthenticator(),
      )
      ..addSingleton<DatabaseKeyProvider>(
        () => DatabaseKeyProvider(Modular.get<SecureStore>()),
      )
      ..addSingleton<FakeBackendSettings>(() => FakeBackendSettings());
  }
}
