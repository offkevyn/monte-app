import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../core/theme/monte_theme.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/auth/presentation/current_session.dart';
import '../features/crypto/domain/repositories/market_repository.dart';
import '../features/crypto/presentation/list/crypto_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/ledger/domain/repositories/ledger_repository.dart';
import '../features/statement/presentation/statement_page.dart';
import 'routes.dart';

/// Signed-in area with the bottom bar. Tabs live in an IndexedStack, so each
/// keeps its state (scroll, filters) when the user switches and comes back.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _tab = 0;

  /// The crypto tab is only built on its first visit, so opening the app
  /// does not spend CoinGecko calls on a screen nobody looked at.
  final _visited = {0, 1, 3};

  void _go(int tab) => setState(() {
    _tab = tab;
    _visited.add(tab);
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _tab,
      children: [
        DashboardPage(
          onOpenStatement: () => _go(1),
          onOpenCrypto: () => _go(2),
        ),
        const StatementPage(),
        if (_visited.contains(2)) const CryptoPage() else const SizedBox(),
        const _ProfileTab(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: _go,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Extrato',
        ),
        NavigationDestination(
          icon: Icon(Icons.currency_bitcoin_rounded),
          label: 'Cripto',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    ),
  );
}

/// Temporary profile until the extras branch: who is signed in and the
/// sign out, which also wipes the local copy of the account.
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  Future<void> _signOut() async {
    await Modular.get<SignOut>()();
    await Modular.get<LedgerRepository>().clear();
    await Modular.get<MarketRepository>().clear();
    Modular.get<CurrentSession>().end();
    Modular.to.navigate(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final session = Modular.get<CurrentSession>().value;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session?.customerName ?? '',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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
    );
  }
}
