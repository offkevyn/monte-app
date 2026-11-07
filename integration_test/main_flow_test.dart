import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/fake_coingecko.dart';
import 'support/harness.dart';

/// Main flow: login, statement, detail, crypto and sign out.
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

  testWidgets('a full visit: login, statement, detail, crypto and sign out', (
    tester,
  ) async {
    await startApp(tester, coingecko);

    // Fresh install: splash, then the login.
    await tapWhenReady(tester, find.byKey(const Key('login.demo')));
    await tapWhenReady(tester, find.byKey(const Key('login.submit')));

    // Dashboard filled from the simulated bank through the encrypted
    // database, with the crypto card from the local CoinGecko.
    await waitFor(tester, find.byKey(const Key('dashboard.balance')));
    expect(find.text('Saldo disponível'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('dashboard.balance')),
      const Offset(0, -500),
    );
    await waitFor(tester, find.byKey(const Key('dashboard.crypto')));
    await tester.drag(
      find.byKey(const Key('dashboard.crypto')),
      const Offset(0, 500),
    );

    // Statement: search, open a transaction and come back.
    await tester.tap(find.text('Extrato').last);
    await waitFor(tester, find.byKey(const Key('statement.search')));
    await tester.enterText(
      find.byKey(const Key('statement.search')),
      'Padaria',
    );
    await waitFor(tester, find.text('Padaria São José'));
    expect(find.text('Supermercado Bom Preço'), findsNothing);

    await tester.tap(find.text('Padaria São José').first);
    await waitFor(tester, find.byKey(const Key('detail.amount')));
    expect(find.text('Detalhes'), findsOneWidget);
    await tapWhenReady(tester, find.byTooltip('Voltar'));
    await waitFor(tester, find.byKey(const Key('statement.search')));

    // Search and filter together: no bakery purchase is money coming in.
    await tapWhenReady(tester, find.byKey(const Key('statement.filters')));
    await tapWhenReady(tester, find.text('Entradas'));
    await tapWhenReady(tester, find.byKey(const Key('filters.apply')));
    await waitFor(tester, find.byKey(const Key('statement.empty')));

    // Crypto: the most traded list, then one coin.
    await tester.tap(find.text('Cripto').last);
    await tapWhenReady(tester, find.byKey(const Key('coin.bitcoin')));
    await waitFor(tester, find.byKey(const Key('coin.price')));
    await waitUntil(
      tester,
      () => coingecko.paths.contains('/coins/bitcoin/market_chart'),
      'the price chart',
    );
    await tapWhenReady(tester, find.byTooltip('Voltar'));
    await waitFor(tester, find.byKey(const Key('crypto.search')));

    // Profile: sign out asks first, then back to the login.
    await tester.tap(find.text('Perfil').last);
    await tapWhenReady(tester, find.byKey(const Key('home.signOut')));
    await tapWhenReady(tester, find.byKey(const Key('profile.confirmSignOut')));
    await waitFor(tester, find.byKey(const Key('login.submit')));
  });
}
