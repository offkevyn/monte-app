import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Modular 6 also defines context.read/watch; the bloc ones are used here.
import 'package:flutter_modular/flutter_modular.dart'
    hide ModularWatchExtension;

import '../../../app/routes.dart';
import '../../../core/config/dev_tools.dart';
import '../../../core/dev/scenario_picker.dart';
import '../../../core/network/fake/fake_scenario.dart';
import '../../../core/platform/link_opener.dart';
import '../../../core/theme/monte_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/ui/monte_logo.dart';
import '../../auth/presentation/current_session.dart';
import '../../ledger/data/fake/fake_ledger_server.dart';
import '../../ledger/domain/repositories/ledger_repository.dart';
import 'profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onDataReset});

  /// Called after the dev scenario picker changed something, so the signed
  /// in screens load again under the new scenario.
  /// Called after the dev picker changed the simulated bank, with whether
  /// the saved data must go (new volume = different transactions).
  final ValueChanged<bool> onDataReset;

  @override
  Widget build(BuildContext context) {
    final session = Modular.get<CurrentSession>().value;
    return BlocProvider(
      create: (_) => Modular.get<ProfileCubit>()..load(),
      child: ProfileView(
        customerName: session?.customerName ?? '',
        accountLabel: session?.accountLabel ?? '',
        theme: Modular.get<ThemeController>(),
        links: Modular.get<LinkOpener>(),
        devSettings: devToolsEnabled
            ? Modular.get<FakeBackendSettings>()
            : null,
        onDataReset: onDataReset,
        onSimulatePix: _simulatePix,
      ),
    );
  }
}

/// Dev tool: a Pix arrives at the fake bank in a few seconds, time to go
/// down the statement and leave the app, so coming back shows the "new
/// transaction" pill. The "fetched seconds ago" shortcut is dropped, as a
/// push notification would, so the next look goes to the server.
void _simulatePix() {
  Future<void>.delayed(ProfileView.pixDelay, () {
    Modular.get<FakeLedgerServer>().receivePix();
    Modular.get<LedgerRepository>().expireRecentFetches();
  });
}

/// Public so widget tests can pump it with a cubit of their own.
class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.customerName,
    required this.accountLabel,
    required this.theme,
    required this.links,
    this.devSettings,
    this.onDataReset,
    this.onSimulatePix,
    this.onSignedOut = _goToLogin,
  });

  static final github = Uri.parse('https://github.com/offkevyn');

  /// How long the simulated Pix takes to arrive.
  static const pixDelay = Duration(seconds: 10);

  final String customerName;
  final String accountLabel;
  final ThemeController theme;
  final LinkOpener links;

  /// Present only in dev builds: shows the scenario picker row.
  final FakeBackendSettings? devSettings;
  final ValueChanged<bool>? onDataReset;

  /// Makes a Pix arrive at the fake bank; shown next to the scenario
  /// picker, so only in dev builds.
  final VoidCallback? onSimulatePix;
  final VoidCallback onSignedOut;

  static void _goToLogin() => Modular.to.navigate(Routes.login);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Future<void> _openGithub() async {
    final opened = await widget.links.open(ProfileView.github);
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Não deu pra abrir o navegador. O perfil é '
            'github.com/offkevyn',
          ),
        ),
      );
  }

  Future<void> _openScenarios(FakeBackendSettings settings) async {
    final volume = settings.volume;
    final changed = await showScenarioPicker(context, settings);
    if (!mounted) return;
    setState(() {});
    // A new scenario keeps what is saved (so "Sem internet" shows the
    // offline screens with data); a new volume is another account.
    if (changed) widget.onDataReset?.call(settings.volume != volume);
  }

  Future<void> _signOut() async {
    final cubit = context.read<ProfileCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'O extrato guardado neste aparelho é apagado. Pra voltar, você '
          'entra de novo com CPF e senha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('profile.confirmSignOut'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.signOut();
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.monte;
    final devSettings = widget.devSettings;
    return SafeArea(
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          final cubit = context.read<ProfileCubit>();
          final noBiometrics = state.loaded && !state.biometricsAvailable;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Perfil',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors.chip,
                    foregroundColor: colors.brand,
                    child: Text(
                      _initials(widget.customerName),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(
                    widget.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(widget.accountLabel),
                ),
              ),
              const _Label('Segurança'),
              _Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const Key('profile.loginBiometrics'),
                      title: const Text('Entrar com digital'),
                      subtitle: noBiometrics
                          ? const Text(
                              'Cadastre uma digital no aparelho pra usar',
                            )
                          : null,
                      value: state.loginBiometrics,
                      onChanged: state.biometricsAvailable
                          ? (on) => cubit.setLoginBiometrics(enabled: on)
                          : null,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      key: const Key('profile.balanceBiometrics'),
                      title: const Text('Pedir digital pra mostrar o saldo'),
                      value: state.balanceBiometrics,
                      onChanged: state.biometricsAvailable
                          ? (on) => cubit.setBalanceBiometrics(enabled: on)
                          : null,
                    ),
                  ],
                ),
              ),
              const _Label('Aparência'),
              ValueListenableBuilder(
                valueListenable: widget.theme,
                builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                  key: const Key('profile.theme'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Claro'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Escuro'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_suggest_rounded),
                      label: Text('Sistema'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (picked) =>
                      widget.theme.set(picked.single),
                ),
              ),
              const _Label('Sobre'),
              _Card(
                child: Column(
                  children: [
                    ListTile(
                      key: const Key('profile.whyMonte'),
                      title: const Text('Por que "Monte"?'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showWhyMonte(context),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: const Text('Versão'),
                      trailing: Text(
                        [
                          state.version ?? '—',
                          if (devSettings != null) '(dev)',
                        ].join(' '),
                        style: text.bodyMedium?.copyWith(color: colors.subtle),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      key: const Key('profile.madeBy'),
                      title: const Text('Feito por'),
                      trailing: Text(
                        'offkevyn ›',
                        style: text.bodyMedium?.copyWith(
                          color: colors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: _openGithub,
                    ),
                  ],
                ),
              ),
              if (devSettings != null) ...[
                const _Label('Desenvolvimento'),
                _Card(
                  child: ListTile(
                    key: const Key('profile.devScenarios'),
                    leading: const Icon(Icons.science_outlined),
                    title: const Text('Cenário do servidor falso'),
                    subtitle: Text(
                      '${devSettings.scenario.label} · '
                      '${devSettings.volume.label} transações',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openScenarios(devSettings),
                  ),
                ),
                if (widget.onSimulatePix case final simulatePix?)
                  _Card(
                    child: ListTile(
                      key: const Key('profile.devPix'),
                      leading: const Icon(Icons.pix_rounded),
                      title: const Text('Simular Pix recebido'),
                      subtitle: const Text(
                        'R\$ 50,00 chegam no servidor falso em 10 s',
                      ),
                      onTap: () {
                        simulatePix();
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pix de R\$ 50,00 chega em 10 s. Role o '
                                'extrato pra baixo, minimize e volte.',
                              ),
                            ),
                          );
                      },
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  key: const Key('home.signOut'),
                  style: TextButton.styleFrom(foregroundColor: colors.expense),
                  onPressed: state.signingOut ? null : _signOut,
                  child: const Text(
                    'Sair da conta',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '';
    final first = words.first.characters.first;
    final last = words.length > 1 ? words.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  void _showWhyMonte(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _WhyMonteSheet(),
  );
}

class _WhyMonteSheet extends StatelessWidget {
  const _WhyMonteSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget item(String emoji, String title, String body) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(body, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: MonteLogo(size: 72)),
            const SizedBox(height: 16),
            Text(
              'Por que "Monte"?',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            item(
              '⛰',
              'Monte Belo',
              'A cidade do Sul de Minas onde nasceu a empresa que inspirou '
                  'este app. O nome é uma homenagem.',
            ),
            item(
              '📈',
              'Juntar um monte',
              'Em português, "um monte" é muito. A montanha do logo vira um '
                  'gráfico subindo: o seu dinheiro crescendo.',
            ),
            item(
              '🪙',
              'A moeda de ouro',
              'Minas Gerais tem esse nome por causa das minas de ouro. Por '
                  'isso o círculo amarelo no céu é uma moeda.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: context.monte.subtle, fontWeight: FontWeight.w700),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Card(margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias, child: child);
}
