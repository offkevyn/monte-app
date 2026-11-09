import 'dart:io';

import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/app/app_module.dart';
import 'package:monte/app/app_widget.dart';
import 'package:monte/core/network/api_client_factory.dart';
import 'package:monte/core/network/fake/device_connection.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';
import 'package:monte/core/security/biometric_authenticator.dart';
import 'package:monte/core/storage/encrypted_database.dart';
import 'package:monte/core/time/clock.dart';
import 'package:monte/features/crypto/data/coingecko/coingecko_config.dart';
import 'package:monte/features/crypto/data/coingecko/market_remote_datasource.dart';
import 'package:monte/features/crypto/data/local/market_database.dart';
import 'package:monte/features/crypto/data/local/market_local_datasource.dart';
import 'package:monte/features/crypto/data/market_repository_impl.dart';
import 'package:monte/features/crypto/domain/repositories/market_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_coingecko.dart';

/// The fingerprint prompt is drawn by the system, outside Flutter, so the
/// test cannot answer it. The device says it has none, which also keeps a
/// phone with a fingerprint from offering it after the login.
class NoBiometrics implements BiometricAuthenticator {
  const NoBiometrics();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}

/// Leaves the device as if the app had just been installed: no session, no
/// preferences and no saved databases from an earlier run.
Future<void> wipeDevice() async {
  await const FlutterSecureStorage().deleteAll();
  await SharedPreferencesAsync().clear();
  final support = await getApplicationSupportDirectory();
  for (final entity in support.listSync()) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (name.startsWith('ledger.db') || name.startsWith('market.db')) {
      await entity.delete();
    }
  }
}

/// Starts the real app (real modules, plugins, encrypted databases and the
/// simulated bank) with CoinGecko answered by [coingecko].
Future<FakeBackendSettings> startApp(
  WidgetTester tester,
  FakeCoinGeckoAdapter coingecko,
) async {
  await tester.pumpWidget(
    ModularApp(module: AppModule(), child: const AppWidget()),
  );
  Modular
    ..replaceInstance<BiometricAuthenticator>(const NoBiometrics())
    // The simulated bank checks the phone's connection; tests decide it.
    ..replaceInstance<DeviceConnection>(
      DeviceConnection(lookup: (_) async => [InternetAddress.loopbackIPv4]),
    )
    ..replaceInstance<MarketRepository>(
      MarketRepositoryImpl(
        remote: CoinGeckoRemoteDataSource(
          ApiClientFactory.create(
            baseUrl: CoinGeckoConfig.baseUrl,
            adapter: coingecko,
          ),
        ),
        local: MarketLocalDataSource(
          openMarketDatabase(Modular.get<DatabaseKeyProvider>()),
        ),
        clock: Modular.get<Clock>(),
      ),
    );
  return Modular.get<FakeBackendSettings>();
}

/// Pumps frames on real time until [target] shows up. `pumpAndSettle` is
/// not used for loading: a spinner never settles.
Future<void> waitFor(WidgetTester tester, Finder target) =>
    waitUntil(tester, () => target.evaluate().isNotEmpty, '$target');

/// Pumps frames on real time until [done] holds.
Future<void> waitUntil(
  WidgetTester tester,
  bool Function() done,
  String what, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (done()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for $what');
}

/// Waits for [target] and taps it.
Future<void> tapWhenReady(WidgetTester tester, Finder target) async {
  await waitFor(tester, target);
  await tester.ensureVisible(target.first);
  await tester.pump();
  await tester.tap(target.first);
  await tester.pump();
}
