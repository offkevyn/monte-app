import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../core/theme/monte_theme.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  static const locale = Locale('pt', 'BR');

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Monte',
    debugShowCheckedModeBanner: false,
    theme: MonteTheme.light,
    darkTheme: MonteTheme.dark,
    locale: locale,
    supportedLocales: const [locale],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: Modular.routerConfig,
  );
}
