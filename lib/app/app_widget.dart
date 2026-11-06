import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../core/theme/monte_theme.dart';
import '../core/theme/theme_controller.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  static const locale = Locale('pt', 'BR');

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  final _theme = Modular.get<ThemeController>();

  @override
  void initState() {
    super.initState();
    _theme.load();
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
