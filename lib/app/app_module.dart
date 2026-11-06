import 'package:flutter_modular/flutter_modular.dart';

import '../core/core_module.dart';
import '../core/network/api_client_factory.dart';
import '../core/network/bank_api.dart';
import '../core/network/fake/fake_http_adapter.dart';
import '../core/network/fake/fake_scenario.dart';
import '../core/security/biometric_authenticator.dart';
import '../core/storage/app_preferences.dart';
import '../core/storage/secure_store.dart';
import '../core/time/clock.dart';
import '../features/auth/data/auth_data.dart';
import '../features/auth/data/fake/fake_auth_server.dart';
import '../features/auth/domain/entities/cpf.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/auth/presentation/current_session.dart';
import '../features/auth/presentation/login/login_cubit.dart';
import '../features/auth/presentation/login/login_page.dart';
import '../features/auth/presentation/splash/splash_cubit.dart';
import '../features/auth/presentation/splash/splash_page.dart';
import '../features/ledger/data/fake/fake_ledger_server.dart';
import 'home_placeholder_page.dart';
import 'routes.dart';

/// Composition root: wires the simulated bank, the auth feature and the
/// routes. Feature modules (dashboard, statement, crypto) mount here.
class AppModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(Injector i) {
    i
      // Simulated bank: one adapter answering every fake endpoint.
      ..addSingleton<FakeAuthServer>(
        () => FakeAuthServer(
          settings: Modular.get<FakeBackendSettings>(),
          clock: Modular.get<Clock>(),
        ),
      )
      ..addSingleton<FakeLedgerServer>(
        () => FakeLedgerServer(
          settings: Modular.get<FakeBackendSettings>(),
          clock: Modular.get<Clock>(),
        ),
      )
      ..addSingleton<FakeHttpAdapter>(
        () => FakeHttpAdapter(
          settings: Modular.get<FakeBackendSettings>(),
          routes: [
            ...Modular.get<FakeAuthServer>().routes,
            ...Modular.get<FakeLedgerServer>().routes,
          ],
        ),
      )
      ..addSingleton<BankApi>(
        () => BankApi(
          ApiClientFactory.create(
            baseUrl: ApiClientFactory.fakeBankBaseUrl,
            adapter: Modular.get<FakeHttpAdapter>(),
          ),
        ),
      )
      // Auth
      ..addSingleton<CurrentSession>(CurrentSession.new)
      ..addLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          AuthRemoteDataSource(Modular.get<BankApi>().dio),
          SessionStore(Modular.get<SecureStore>()),
          Modular.get<Clock>(),
        ),
      )
      ..add<SignIn>(() => SignIn(Modular.get<AuthRepository>()))
      ..add<SignOut>(() => SignOut(Modular.get<AuthRepository>()))
      ..add<ResolveStart>(
        () => ResolveStart(Modular.get<AuthRepository>(), Modular.get<Clock>()),
      )
      ..add<SplashCubit>(
        () => SplashCubit(
          Modular.get<ResolveStart>(),
          Modular.get<AppPreferences>(),
          Modular.get<BiometricAuthenticator>(),
          Modular.get<CurrentSession>(),
        ),
      )
      ..add<LoginCubit>(
        () => LoginCubit(
          Modular.get<SignIn>(),
          Modular.get<AppPreferences>(),
          Modular.get<BiometricAuthenticator>(),
          Modular.get<CurrentSession>(),
        ),
      );
  }

  @override
  void routes(RouteManager r) {
    r
      ..child(Routes.splash, child: (_) => const SplashPage())
      ..child(
        Routes.login,
        child: (_) => LoginPage(lastCpf: r.args.data as Cpf?),
        transition: TransitionType.fadeIn,
      )
      ..child(
        Routes.home,
        child: (_) => const HomePlaceholderPage(),
        transition: TransitionType.fadeIn,
      );
  }
}
