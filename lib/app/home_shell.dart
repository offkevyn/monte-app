import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../features/crypto/presentation/list/crypto_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/ledger/domain/repositories/ledger_repository.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/statement/presentation/statement_page.dart';

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

  /// Bumped when the dev scenario picker changes the simulated bank: every
  /// tab is built again, so its cubit loads under the new scenario.
  var _generation = 0;

  void _go(int tab) => setState(() {
    _tab = tab;
    _visited.add(tab);
  });

  Future<void> _resetData() async {
    await Modular.get<LedgerRepository>().clear();
    if (mounted) setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      key: ValueKey(_generation),
      index: _tab,
      children: [
        DashboardPage(
          onOpenStatement: () => _go(1),
          onOpenCrypto: () => _go(2),
        ),
        const StatementPage(),
        if (_visited.contains(2)) const CryptoPage() else const SizedBox(),
        ProfilePage(onDataReset: _resetData),
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
