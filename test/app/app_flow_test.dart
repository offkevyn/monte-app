import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/app/app_module.dart';
import 'package:monte/app/app_widget.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The real app (real modules, real binds, simulated bank) with only the
/// platform storage replaced by in-memory versions. Catches wiring mistakes
/// that unit tests cannot, like a bind the injector cannot build.
/// Part of the request path (Dio's transformer, the storage mocks) runs on
/// real async work, which the fake clock of widget tests never advances.
/// Alternates a little real time with fake frames until things settle.
Future<void> settleWithRealAsync(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.pumpAndSettle();
}

/// The real app (real modules, real binds, simulated bank) with only the
/// platform storage replaced by in-memory versions. Catches wiring mistakes
/// that unit tests cannot, like a bind the injector cannot build.
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(Modular.destroy);

  testWidgets('splash -> login -> demo account -> home -> sign out', (
    tester,
  ) async {
    await tester.pumpWidget(
      ModularApp(module: AppModule(), child: const AppWidget()),
    );

    // Splash animation, then the login.
    await tester.pumpAndSettle();
    expect(find.text('Entre com seu CPF e senha.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login.demo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('login.submit')));
    await settleWithRealAsync(tester);

    // No fingerprint in the test environment, so no offer: straight in.
    expect(find.text('Olá, Kevyn 👋'), findsOneWidget);
    expect(find.text('Conta 0001 · 12345-6'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home.signOut')));
    await settleWithRealAsync(tester);
    expect(find.text('Entre com seu CPF e senha.'), findsOneWidget);
  });
}
