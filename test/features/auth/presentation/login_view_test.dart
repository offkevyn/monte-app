import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/result/result.dart';
import 'package:monte/core/storage/app_preferences.dart';
import 'package:monte/core/theme/monte_theme.dart';
import 'package:monte/features/auth/domain/usecases/auth_usecases.dart';
import 'package:monte/features/auth/presentation/cpf_input_formatter.dart';
import 'package:monte/features/auth/presentation/current_session.dart';
import 'package:monte/features/auth/presentation/login/login_cubit.dart';
import 'package:monte/features/auth/presentation/login/login_page.dart';

import '../domain/auth_domain_test.dart' show FakeAuthRepository;
import 'auth_cubits_test.dart' show FakeBiometrics;

void main() {
  late FakeAuthRepository repository;
  late LoginCubit cubit;
  var signedIn = 0;

  setUp(() {
    signedIn = 0;
    repository = FakeAuthRepository();
    cubit = LoginCubit(
      SignIn(repository),
      MemoryAppPreferences(),
      FakeBiometrics()..available = false,
      CurrentSession(),
    );
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: MonteTheme.light,
      home: BlocProvider.value(
        value: cubit,
        child: LoginView(onSignedIn: () => signedIn++),
      ),
    ),
  );

  testWidgets('empty submit shows both field messages', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pump();

    expect(find.text(LoginCubit.invalidCpf), findsOneWidget);
    expect(find.text(LoginCubit.emptyPassword), findsOneWidget);
  });

  testWidgets('typing the CPF applies the mask', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('login.cpf')), '00000000191');
    expect(find.text('000.000.001-91'), findsOneWidget);
    expect(cubit.state.cpf, '000.000.001-91');
  });

  testWidgets('demo hint fills the form', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('login.demo')));
    await tester.pump();
    expect(find.text('000.000.001-91'), findsOneWidget);
    expect(cubit.state.password, 'monte123');
  });

  testWidgets('server error appears in a card above the form', (tester) async {
    repository.answer = const Err(InvalidCredentialsFailure(attemptsLeft: 1));
    await pump(tester);
    await tester.tap(find.byKey(const Key('login.demo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login.serverError')), findsOneWidget);
    expect(find.textContaining('mais 1 tentativa'), findsOneWidget);
  });

  testWidgets('eye button shows and hides the password', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();
    expect(find.byTooltip('Esconder senha'), findsOneWidget);
  });

  testWidgets('"Esqueci minha senha" opens the under construction popup', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    expect(find.textContaining('subindo o morro'), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('subindo o morro'), findsNothing);
  });

  testWidgets('after the first login, offers the fingerprint once', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();
    cubit = LoginCubit(
      SignIn(repository),
      preferences,
      FakeBiometrics(),
      CurrentSession(),
    );
    await pump(tester);
    await tester.tap(find.byKey(const Key('login.demo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Entrar com a digital?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('biometrics.accept')));
    await tester.pumpAndSettle();

    expect(find.text('Entrar com a digital?'), findsNothing);
    expect(preferences.biometrics, isTrue);
    expect(cubit.state.step, LoginStep.done);
    expect(signedIn, 1);
  });

  testWidgets('"Agora não" closes the offer without turning it on', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();
    cubit = LoginCubit(
      SignIn(repository),
      preferences,
      FakeBiometrics(),
      CurrentSession(),
    );
    await pump(tester);
    await tester.tap(find.byKey(const Key('login.demo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('login.submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('biometrics.decline')));
    await tester.pumpAndSettle();

    expect(preferences.biometrics, isFalse);
    expect(preferences.offerShown, isTrue);
  });

  group('CpfInputFormatter', () {
    TextEditingValue format(String text) => CpfInputFormatter()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

    test('formats while typing and stops at 11 digits', () {
      expect(format('000').text, '000');
      expect(format('0000').text, '000.0');
      expect(format('0000000019').text, '000.000.001-9');
      expect(format('000000001912345').text, '000.000.001-91');
      expect(format('ab0c0').text, '00');
      expect(format('00000000191').selection.baseOffset, 14);
    });
  });

  testWidgets('long-pressing the logo opens the dev tools when present', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MonteTheme.light,
        home: BlocProvider.value(
          value: cubit,
          child: LoginView(onOpenDevTools: (_) => opened++),
        ),
      ),
    );
    await tester.longPress(find.byKey(const Key('login.logo')));
    expect(opened, 1);
  });

  testWidgets('without dev tools the logo is just an image', (tester) async {
    await pump(tester);
    final logo = tester.widget<GestureDetector>(
      find.byKey(const Key('login.logo')),
    );
    expect(logo.onLongPress, isNull);
  });
}
