import 'package:flutter_modular/flutter_modular.dart';

import '../core/core_module.dart';
import 'welcome_page.dart';

/// Root module. Each feature (auth, dashboard, statement, crypto...) is
/// mounted here as a sub-module with its own path.
class AppModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void routes(RouteManager r) {
    // Temporary entry point, replaced by the splash in feat/auth.
    r.child(Modular.initialRoute, child: (_) => const WelcomePage());
  }
}
