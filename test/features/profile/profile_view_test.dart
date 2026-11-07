import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';
import 'package:monte/core/platform/link_opener.dart';
import 'package:monte/core/storage/app_preferences.dart';
import 'package:monte/core/theme/monte_theme.dart';
import 'package:monte/core/theme/theme_controller.dart';
import 'package:monte/features/auth/domain/usecases/auth_usecases.dart';
import 'package:monte/features/auth/presentation/current_session.dart';
import 'package:monte/features/crypto/domain/repositories/market_repository.dart';
import 'package:monte/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:monte/features/profile/presentation/profile_cubit.dart';
import 'package:monte/features/profile/presentation/profile_page.dart';

import '../auth/domain/auth_domain_test.dart' show FakeAuthRepository;
import '../auth/presentation/auth_cubits_test.dart' show FakeBiometrics;
import 'profile_cubit_test.dart' show FixedAppInfo;

class _MockLedger extends Mock implements LedgerRepository {}

class _MockMarket extends Mock implements MarketRepository {}

class _FakeLinks implements LinkOpener {
  bool opens = true;
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return opens;
  }
}

void main() {
  late MemoryAppPreferences preferences;
  late FakeBiometrics biometrics;
  late ThemeController theme;
  late _FakeLinks links;
  late ProfileCubit cubit;
  late int signedOut;
  late int dataResets;
  late List<bool> clears;

  setUp(() {
    preferences = MemoryAppPreferences();
    biometrics = FakeBiometrics();
    theme = ThemeController(preferences);
    links = _FakeLinks();
    signedOut = 0;
    dataResets = 0;
    clears = [];
    final ledger = _MockLedger();
    final market = _MockMarket();
    when(ledger.clear).thenAnswer((_) async {});
    when(market.clear).thenAnswer((_) async {});
    cubit = ProfileCubit(
      preferences: preferences,
      biometrics: biometrics,
      appInfo: const FixedAppInfo(),
      signOut: SignOut(FakeAuthRepository(), userData: [ledger, market]),
      session: CurrentSession(),
    );
  });

  tearDown(() => cubit.close());

  var pixes = 0;
  setUp(() => pixes = 0);

  Future<void> pump(WidgetTester tester, {FakeBackendSettings? dev}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: MonteTheme.light,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: ProfileView(
              customerName: 'Kevyn Melo',
              accountLabel: 'Conta 0001 · 12345-6',
              theme: theme,
              links: links,
              devSettings: dev,
              onSimulatePix: () => pixes++,
              onDataReset: (clear) {
                dataResets++;
                clears.add(clear);
              },
              onSignedOut: () => signedOut++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool switchValue(WidgetTester tester, String key) =>
      tester.widget<SwitchListTile>(find.byKey(Key(key))).value;

  testWidgets('shows who is signed in, the version and no dev section', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('KM'), findsOneWidget);
    expect(find.text('Kevyn Melo'), findsOneWidget);
    expect(find.text('Conta 0001 · 12345-6'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.byKey(const Key('profile.devScenarios')), findsNothing);
    expect(find.byKey(const Key('profile.devPix')), findsNothing);
  });

  testWidgets('dev builds can make a Pix arrive', (tester) async {
    await pump(tester, dev: FakeBackendSettings());
    await tester.tap(find.byKey(const Key('profile.devPix')));
    await tester.pump();
    expect(pixes, 1);
    expect(
      find.textContaining('Pix de R\$ 50,00 chega em 10 s'),
      findsOneWidget,
    );
  });

  testWidgets('the switches follow the cubit', (tester) async {
    await pump(tester);
    expect(switchValue(tester, 'profile.loginBiometrics'), isFalse);

    await tester.tap(find.byKey(const Key('profile.loginBiometrics')));
    await tester.pumpAndSettle();
    expect(switchValue(tester, 'profile.loginBiometrics'), isTrue);
    expect(preferences.biometrics, isTrue);

    await tester.tap(find.byKey(const Key('profile.balanceBiometrics')));
    await tester.pumpAndSettle();
    expect(switchValue(tester, 'profile.balanceBiometrics'), isTrue);
  });

  testWidgets('without a fingerprint on the device the switches are off', (
    tester,
  ) async {
    biometrics.available = false;
    await pump(tester);
    expect(find.text('Cadastre uma digital no aparelho pra usar'), findsOne);
    final tile = tester.widget<SwitchListTile>(
      find.byKey(const Key('profile.loginBiometrics')),
    );
    expect(tile.onChanged, isNull);
  });

  testWidgets('the theme picker changes and saves the theme', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    expect(theme.value, ThemeMode.dark);
    expect(preferences.theme, 'dark');
  });

  testWidgets('"Por que Monte?" tells the story of the name', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('profile.whyMonte')));
    await tester.pumpAndSettle();
    expect(find.text('Monte Belo'), findsOneWidget);
    expect(find.text('A moeda de ouro'), findsOneWidget);
  });

  testWidgets('"Feito por" opens GitHub, and says so when it cannot', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('profile.madeBy')));
    await tester.pumpAndSettle();
    expect(links.opened.single, ProfileView.github);
    expect(find.byType(SnackBar), findsNothing);

    links.opens = false;
    await tester.tap(find.byKey(const Key('profile.madeBy')));
    await tester.pumpAndSettle();
    expect(find.textContaining('github.com/offkevyn'), findsOneWidget);
  });

  testWidgets('sign out asks first; cancelling keeps the user in', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('home.signOut')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(signedOut, 0);

    await tester.tap(find.byKey(const Key('home.signOut')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile.confirmSignOut')));
    await tester.pumpAndSettle();
    expect(signedOut, 1);
  });

  testWidgets('dev builds show the scenario and reload after a change', (
    tester,
  ) async {
    final settings = FakeBackendSettings();
    await pump(tester, dev: settings);
    expect(find.text('1.0.0 (dev)'), findsOneWidget);
    expect(find.text('Normal · 500 transações'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile.devScenarios')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dev.scenario.slow')));
    await tester.tap(find.byKey(const Key('dev.apply')));
    await tester.pumpAndSettle();

    expect(settings.scenario, FakeScenario.slow);
    expect(find.text('Lento (3 s) · 500 transações'), findsOneWidget);
    expect(dataResets, 1);
    expect(clears, [false], reason: 'a new scenario keeps what is saved');

    await tester.tap(find.byKey(const Key('profile.devScenarios')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dev.volume.large')));
    await tester.tap(find.byKey(const Key('dev.apply')));
    await tester.pumpAndSettle();
    expect(clears, [false, true], reason: 'a new volume is another account');
  });
}
