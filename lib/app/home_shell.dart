import 'dart:async';

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

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  var _tab = 0;

  /// Which tab came (back) on screen: picked in the bar, or the app
  /// returned to the foreground on it. Dashboard and statement use it to
  /// look for news, such as a Pix that just arrived.
  final _visits = StreamController<int>.broadcast();

  Stream<void> _visitsOf(int tab) => _visits.stream.where((t) => t == tab);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _visits.add(_tab);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visits.close();
    super.dispose();
  }

  /// The crypto tab is only built on its first visit, so opening the app
  /// does not spend CoinGecko calls on a screen nobody looked at.
  final _visited = {0, 1, 3};

  /// Bumped when the dev scenario picker changes the simulated bank: every
  /// tab is built again, so its cubit loads under the new scenario.
  var _generation = 0;

  void _go(int tab) {
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
    _visits.add(tab);
  }

  Future<void> _resetData(bool clearSaved) async {
    final ledger = Modular.get<LedgerRepository>()..expireRecentFetches();
    if (clearSaved) await ledger.clear();
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
          visits: _visitsOf(0),
        ),
        StatementPage(visits: _visitsOf(1)),
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
