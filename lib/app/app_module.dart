import 'package:flutter_modular/flutter_modular.dart';

import '../core/core_module.dart';
import '../core/money/money_formatter.dart';
import '../core/network/api_client_factory.dart';
import '../core/network/auth_interceptor.dart';
import '../core/network/bank_api.dart';
import '../core/network/fake/device_connection.dart';
import '../core/network/fake/fake_http_adapter.dart';
import '../core/network/fake/fake_scenario.dart';
import '../core/platform/app_info.dart';
import '../core/security/biometric_authenticator.dart';
import '../core/session/session_expiry.dart';
import '../core/session/user_data.dart';
import '../core/storage/app_preferences.dart';
import '../core/storage/encrypted_database.dart';
import '../core/storage/secure_store.dart';
import '../core/time/clock.dart';
import '../core/time/local_calendar.dart';
import '../features/auth/data/auth_data.dart';
import '../features/auth/data/fake/fake_auth_server.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/auth/presentation/current_session.dart';
import '../features/auth/presentation/login/login_cubit.dart';
import '../features/auth/presentation/login/login_page.dart';
import '../features/auth/presentation/splash/splash_cubit.dart';
import '../features/auth/presentation/splash/splash_page.dart';
import '../features/crypto/crypto_module.dart';
import '../features/crypto/data/coingecko/coingecko_config.dart';
import '../features/crypto/data/coingecko/market_remote_datasource.dart';
import '../features/crypto/data/coingecko/simulated_conditions_interceptor.dart';
import '../features/crypto/data/local/market_database.dart';
import '../features/crypto/data/local/market_local_datasource.dart';
import '../features/crypto/data/market_repository_impl.dart';
import '../features/crypto/domain/repositories/market_repository.dart';
import '../features/crypto/domain/usecases/market_usecases.dart';
import '../features/crypto/presentation/crypto_formatter.dart';
import '../features/crypto/presentation/highlights/crypto_highlights_cubit.dart';
import '../features/crypto/presentation/list/crypto_list_cubit.dart';
import '../features/dashboard/presentation/dashboard_cubit.dart';
import '../features/ledger/data/datasources/ledger_remote_datasource.dart';
import '../features/ledger/data/fake/fake_ledger_server.dart';
import '../features/ledger/data/local/ledger_database.dart';
import '../features/ledger/data/local/ledger_local_datasource.dart';
import '../features/ledger/data/local/open_ledger_database.dart';
import '../features/ledger/data/repositories/ledger_repository_impl.dart';
import '../features/ledger/domain/repositories/ledger_repository.dart';
import '../features/ledger/domain/usecases/get_dashboard.dart';
import '../features/ledger/domain/usecases/get_statement_page.dart';
import '../features/profile/presentation/profile_cubit.dart';
import '../features/statement/presentation/bloc/statement_bloc.dart';
import '../features/statement/statement_module.dart';
import 'home_shell.dart';
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
          authorize: Modular.get<FakeAuthServer>().accepts,
        ),
      )
      ..addSingleton<DeviceConnection>(DeviceConnection.new)
      ..addSingleton<FakeHttpAdapter>(
        () => FakeHttpAdapter(
          settings: Modular.get<FakeBackendSettings>(),
          isDeviceOnline: Modular.get<DeviceConnection>().isOnline,
          routes: [
            ...Modular.get<FakeAuthServer>().routes,
            ...Modular.get<FakeLedgerServer>().routes,
          ],
        ),
      )
      // Every bank request carries the session token; a 401 on one of them
      // signs the customer out (SessionExpiryHandler, started by AppWidget).
      ..addSingleton<CurrentSession>(CurrentSession.new)
      ..addSingleton<SessionExpiry>(SessionExpiry.new)
      ..addSingleton<BankApi>(
        () => BankApi(
          ApiClientFactory.create(
            baseUrl: ApiClientFactory.fakeBankBaseUrl,
            adapter: Modular.get<FakeHttpAdapter>(),
            interceptors: [
              AuthInterceptor(
                token: () => Modular.get<CurrentSession>().value?.accessToken,
                onRejected: Modular.get<SessionExpiry>().report,
              ),
            ],
          ),
        ),
      )
      // Auth
      ..addLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          AuthRemoteDataSource(Modular.get<BankApi>().dio),
          SessionStore(Modular.get<SecureStore>()),
          Modular.get<Clock>(),
        ),
      )
      ..add<SignIn>(
        () => SignIn(Modular.get<AuthRepository>(), userData: _userData()),
      )
      ..add<SignOut>(
        () => SignOut(Modular.get<AuthRepository>(), userData: _userData()),
      )
      ..add<ResolveStart>(
        () => ResolveStart(
          Modular.get<AuthRepository>(),
          Modular.get<Clock>(),
          Modular.get<SignOut>(),
        ),
      )
      ..add<SplashCubit>(
        () => SplashCubit(
          Modular.get<ResolveStart>(),
          Modular.get<AppPreferences>(),
          Modular.get<BiometricAuthenticator>(),
          Modular.get<CurrentSession>(),
        ),
      )
      // Ledger: the server answers each screen with what it shows; one
      // encrypted database keeps those answers (single source of truth for
      // dashboard, statement and detail).
      ..addLazySingleton<LedgerDatabase>(
        () => openLedgerDatabase(Modular.get<DatabaseKeyProvider>()),
      )
      ..addLazySingleton<LedgerRepository>(
        () => LedgerRepositoryImpl(
          remote: DioLedgerRemoteDataSource(
            Modular.get<BankApi>().dio,
            Modular.get<LocalCalendar>(),
          ),
          local: LedgerLocalDataSource(
            Modular.get<LedgerDatabase>(),
            Modular.get<LocalCalendar>(),
          ),
          clock: Modular.get<Clock>(),
        ),
      )
      ..add<GetDashboard>(
        () => GetDashboard(
          Modular.get<LedgerRepository>(),
          Modular.get<Clock>(),
          Modular.get<LocalCalendar>(),
        ),
      )
      ..add<DashboardCubit>(
        () => DashboardCubit(
          Modular.get<GetDashboard>(),
          Modular.get<AppPreferences>(),
          Modular.get<BiometricAuthenticator>(),
        ),
      )
      // Statement
      ..add<GetStatementPage>(
        () => GetStatementPage(Modular.get<LedgerRepository>()),
      )
      ..add<CountTransactions>(
        () => CountTransactions(Modular.get<LedgerRepository>()),
      )
      ..add<StatementBloc>(
        () => StatementBloc(
          Modular.get<GetStatementPage>(),
          Modular.get<LocalCalendar>(),
        ),
      )
      // Crypto: real CoinGecko, saved in its own encrypted database.
      ..addLazySingleton<MarketDatabase>(
        () => openMarketDatabase(Modular.get<DatabaseKeyProvider>()),
      )
      ..addLazySingleton<MarketRepository>(
        () => MarketRepositoryImpl(
          remote: CoinGeckoRemoteDataSource(
            ApiClientFactory.create(
              baseUrl: CoinGeckoConfig.baseUrl,
              headers: CoinGeckoConfig.headers(),
              interceptors: [
                SimulatedConditionsInterceptor(
                  Modular.get<FakeBackendSettings>(),
                  Modular.get<Clock>(),
                ),
              ],
            ),
          ),
          local: MarketLocalDataSource(Modular.get<MarketDatabase>()),
          clock: Modular.get<Clock>(),
        ),
      )
      ..addSingleton<CryptoFormatter>(
        () => CryptoFormatter(Modular.get<MoneyFormatter>()),
      )
      ..add<LoadMarketTab>(
        () => LoadMarketTab(
          Modular.get<MarketRepository>(),
          Modular.get<Clock>(),
        ),
      )
      ..add<SearchCoins>(
        () =>
            SearchCoins(Modular.get<MarketRepository>(), Modular.get<Clock>()),
      )
      ..add<LoadHighlights>(
        () => LoadHighlights(Modular.get<MarketRepository>()),
      )
      ..add<CryptoListCubit>(
        () => CryptoListCubit(
          Modular.get<LoadMarketTab>(),
          Modular.get<SearchCoins>(),
          Modular.get<MarketRepository>(),
        ),
      )
      ..add<CryptoHighlightsCubit>(
        () => CryptoHighlightsCubit(Modular.get<LoadHighlights>()),
      )
      ..add<LoginCubit>(
        () => LoginCubit(
          Modular.get<SignIn>(),
          Modular.get<AppPreferences>(),
          Modular.get<BiometricAuthenticator>(),
          Modular.get<CurrentSession>(),
        ),
      )
      ..add<ProfileCubit>(
        () => ProfileCubit(
          preferences: Modular.get<AppPreferences>(),
          biometrics: Modular.get<BiometricAuthenticator>(),
          appInfo: Modular.get<AppInfo>(),
          signOut: Modular.get<SignOut>(),
          session: Modular.get<CurrentSession>(),
        ),
      );
  }

  /// Every store of the customer's data, emptied on sign out.
  static List<UserData> _userData() => [
    Modular.get<LedgerRepository>(),
    Modular.get<MarketRepository>(),
  ];

  @override
  void routes(RouteManager r) {
    r
      ..child(Routes.splash, child: (_) => const SplashPage())
      ..child(
        Routes.login,
        // Anything else (no arguments, a restored route) opens it blank.
        child: (_) => LoginPage(
          args: switch (r.args.data) {
            final LoginArgs args => args,
            _ => null,
          },
        ),
        transition: TransitionType.fadeIn,
      )
      ..child(
        Routes.home,
        child: (_) => const HomeShell(),
        transition: TransitionType.fadeIn,
      )
      ..module(Routes.statement, module: StatementModule())
      ..module(Routes.crypto, module: CryptoModule());
  }
}
