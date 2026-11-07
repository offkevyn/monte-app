import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../core/session/session_expiry.dart';
import '../core/theme/monte_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/auth/presentation/current_session.dart';
import '../features/auth/presentation/login/login_page.dart';
import 'routes.dart';
import 'session_expiry_handler.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  static const locale = Locale('pt', 'BR');

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  final _theme = Modular.get<ThemeController>();

  /// A session the bank rejects, on any screen, ends here: full sign out
  /// and the login, saying why.
  late final _expiry = SessionExpiryHandler(
    expiry: Modular.get<SessionExpiry>(),
    signOut: Modular.get<SignOut>(),
    session: Modular.get<CurrentSession>(),
    goToLogin: (cpf) => Modular.to.navigate(
      Routes.login,
      arguments: LoginArgs(lastCpf: cpf, sessionExpired: true),
    ),
  );

  @override
  void initState() {
    super.initState();
    _theme.load();
    _expiry.start();
  }

  @override
  void dispose() {
    _expiry.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _theme,
    builder: (context, mode, _) => MaterialApp.router(
      title: 'Monte',
      debugShowCheckedModeBanner: false,
      theme: MonteTheme.light,
      darkTheme: MonteTheme.dark,
      themeMode: mode,
      locale: AppWidget.locale,
      supportedLocales: const [AppWidget.locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: Modular.routerConfig,
    ),
  );
}
