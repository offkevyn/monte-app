import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';

import 'support/fake_coingecko.dart';
import 'support/harness.dart';

/// Failures on both backends and the way back from them.
///
/// The real app on a device or emulator: real plugins (Keystore, shared
/// preferences), real encrypted databases and the simulated bank. Only
/// CoinGecko is answered locally (see [FakeCoinGeckoAdapter]). Each file
/// starts the app once, from a clean install.
///
/// Run with `fvm flutter test integration_test` and an emulator open.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final coingecko = FakeCoinGeckoAdapter();
  setUpAll(wipeDevice);

  testWidgets('errors show up and the app recovers from them', (tester) async {
    final bank = await startApp(tester, coingecko);
    bank.scenario = FakeScenario.serverError;
    coingecko.failing = true;

    // The bank answers 500: the login says so and keeps what was typed.
    await tapWhenReady(tester, find.byKey(const Key('login.demo')));
    await tapWhenReady(tester, find.byKey(const Key('login.submit')));
    await waitFor(tester, find.byKey(const Key('login.serverError')));

    // The bank is back: the same tap goes in.
    bank.scenario = FakeScenario.normal;
    await tapWhenReady(tester, find.byKey(const Key('login.submit')));
    await waitFor(tester, find.byKey(const Key('dashboard.balance')));

    // CoinGecko still failing and nothing saved yet: error with a retry.
    await tester.tap(find.text('Cripto').last);
    await waitFor(tester, find.byKey(const Key('crypto.error')));

    coingecko.failing = false;
    await tapWhenReady(tester, find.text('Tentar de novo'));
    await waitFor(tester, find.byKey(const Key('coin.bitcoin')));
  });
}
