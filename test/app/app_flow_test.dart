import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/app/app_module.dart';
import 'package:monte/app/app_widget.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Part of the work (Dio's transformer, the storage mocks, the database
/// isolate) runs on real async, which the fake clock of widget tests never
/// advances. Alternates real time with fake frames until [target] shows up.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder target, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (target.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $target');
}

/// The real app (real modules, real binds, simulated bank, real encrypted
/// database in a temp folder) with only platform storage replaced by
/// in-memory versions. Catches wiring mistakes that unit tests cannot, like
/// a bind the injector cannot build.
void main() {
  late Directory support;

  setUp(() {
    support = Directory.systemTemp.createTempSync('monte_app_');
    PathProviderPlatform.instance = _TempPathProvider(support.path);
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    Modular.destroy();
    try {
      support.deleteSync(recursive: true);
    } on FileSystemException {
      // The database isolate may still hold the file on Windows.
    }
  });

  testWidgets(
    'splash -> login -> dashboard -> statement -> detail -> sign out',
    (tester) async {
      await tester.pumpWidget(
        ModularApp(module: AppModule(), child: const AppWidget()),
      );

      // Splash animation, then the login (the start screen is decided from
      // the secure store, which answers on real async).
      await pumpUntilFound(tester, find.text('Entre com seu CPF e senha.'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login.demo')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('login.submit')));

      // No fingerprint in the test environment, so no offer: straight to the
      // dashboard, filled from the simulated bank through the encrypted
      // database.
      await pumpUntilFound(tester, find.byKey(const Key('dashboard.balance')));
      expect(find.text('Saldo disponível'), findsOneWidget);
      expect(find.text('Kevyn'), findsOneWidget);

      // Statement tab, then a transaction through the named route
      // /extrato/transacao/:id, and back to the same list.
      await tester.tap(find.text('Extrato').last);
      await pumpUntilFound(tester, find.byKey(const Key('statement.search')));
      await pumpUntilFound(tester, find.textContaining(' · ').first);
      await tester.tap(find.byType(InkWell).at(3));
      await pumpUntilFound(tester, find.byKey(const Key('detail.amount')));
      expect(find.text('Detalhes'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await pumpUntilFound(tester, find.byKey(const Key('statement.search')));
      // Let the closing transition of the detail finish.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('detail.amount')), findsNothing);

      await tester.tap(find.text('Perfil'));
      await tester.pump(const Duration(milliseconds: 300));
      final signOut = find.byKey(const Key('home.signOut'));
      await tester.scrollUntilVisible(
        signOut,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(signOut);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('profile.confirmSignOut')),
      );
      await tester.tap(find.byKey(const Key('profile.confirmSignOut')));
      await pumpUntilFound(tester, find.text('Entre com seu CPF e senha.'));
    },
  );
}

final class _TempPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _TempPathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}
