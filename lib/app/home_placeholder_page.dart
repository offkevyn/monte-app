import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../core/theme/monte_theme.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/auth/presentation/current_session.dart';
import 'routes.dart';

/// Temporary landing screen after login, replaced by the dashboard in the
/// next branch.
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  Future<void> _signOut() async {
    await Modular.get<SignOut>()();
    Modular.get<CurrentSession>().end();
    Modular.to.navigate(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final session = Modular.get<CurrentSession>().value;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${session?.firstName ?? 'cliente'} 👋',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                session?.accountLabel ?? '',
                style: text.bodyMedium?.copyWith(color: context.monte.subtle),
              ),
              const Spacer(),
              OutlinedButton(
                key: const Key('home.signOut'),
                onPressed: _signOut,
                child: const Text('Sair da conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
