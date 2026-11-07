import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Modular 6 also defines context.read/watch; the bloc ones are used here.
import 'package:flutter_modular/flutter_modular.dart'
    hide ModularWatchExtension;

import '../../../../app/routes.dart';
import '../../../../core/config/dev_tools.dart';
import '../../../../core/dev/scenario_picker.dart';
import '../../../../core/network/fake/fake_scenario.dart';
import '../../../../core/theme/monte_theme.dart';
import '../../../../core/ui/failure_message.dart';
import '../../../../core/ui/monte_logo.dart';
import '../../../../core/ui/under_construction.dart';
import '../../domain/entities/cpf.dart';
import '../cpf_input_formatter.dart';
import 'biometric_offer_sheet.dart';
import 'login_cubit.dart';

/// What the login receives when the app sends someone to it.
final class LoginArgs {
  const LoginArgs({this.lastCpf, this.sessionExpired = false});

  /// Prefills the CPF field.
  final Cpf? lastCpf;

  /// The bank rejected the session: the screen says so.
  final bool sessionExpired;
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key, this.args});

  final LoginArgs? args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => Modular.get<LoginCubit>()
      ..prefill(args?.lastCpf, sessionExpired: args?.sessionExpired ?? false),
    child: LoginView(
      onOpenDevTools: devToolsEnabled
          ? (context) =>
                showScenarioPicker(context, Modular.get<FakeBackendSettings>())
          : null,
    ),
  );
}

/// Public so widget tests can pump it with a cubit of their own.
class LoginView extends StatefulWidget {
  const LoginView({super.key, this.onSignedIn = _goHome, this.onOpenDevTools});

  /// What happens after a successful login. The route lives here instead of
  /// inside the view logic, so the view can be tested without the router.
  final VoidCallback onSignedIn;

  /// Long-pressing the logo opens the scenario picker; `null` (production
  /// builds) leaves the logo as a plain image.
  final void Function(BuildContext context)? onOpenDevTools;

  static void _goHome() => Modular.to.navigate(Routes.home);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _cpf = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _syncControllers(context.read<LoginCubit>().state);
  }

  @override
  void dispose() {
    _cpf.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// The cubit owns the values; controllers follow when it changes them
  /// (prefill, demo account, password cleared after an error).
  void _syncControllers(LoginState state) {
    if (_cpf.text != state.cpf) _cpf.text = state.cpf;
    if (_password.text != state.password) _password.text = state.password;
  }

  Future<void> _onStep(BuildContext context, LoginState state) async {
    switch (state.step) {
      case LoginStep.offeringBiometrics:
        await showBiometricOfferSheet(context, context.read<LoginCubit>());
      case LoginStep.done:
        widget.onSignedIn();
      case LoginStep.editing || LoginStep.submitting:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cubit = context.read<LoginCubit>();
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginCubit, LoginState>(
          listener: (_, state) => _syncControllers(state),
        ),
        BlocListener<LoginCubit, LoginState>(
          listenWhen: (a, b) => a.step != b.step,
          listener: _onStep,
        ),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: SafeArea(
            child: BlocBuilder<LoginCubit, LoginState>(
              builder: (context, state) => ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      key: const Key('login.logo'),
                      onLongPress: switch (widget.onOpenDevTools) {
                        final open? => () => open(context),
                        null => null,
                      },
                      child: const MonteLogo(size: 52),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Que bom te ver\npor aqui 👋',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entre com seu CPF e senha.',
                    style: text.bodyMedium?.copyWith(
                      color: context.monte.subtle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: state.failure == null
                        ? const SizedBox(width: double.infinity)
                        : _ServerError(failureMessage(state.failure!)),
                  ),
                  TextField(
                    key: const Key('login.cpf'),
                    controller: _cpf,
                    enabled: !state.isSubmitting,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [CpfInputFormatter()],
                    autofillHints: const [AutofillHints.username],
                    onChanged: cubit.cpfChanged,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    decoration: InputDecoration(
                      labelText: 'CPF',
                      hintText: '000.000.000-00',
                      errorText: state.cpfError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('login.password'),
                    controller: _password,
                    focusNode: _passwordFocus,
                    enabled: !state.isSubmitting,
                    obscureText: state.obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onChanged: cubit.passwordChanged,
                    onSubmitted: (_) => cubit.submit(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      errorText: state.passwordError,
                      suffixIcon: IconButton(
                        tooltip: state.obscurePassword
                            ? 'Mostrar senha'
                            : 'Esconder senha',
                        onPressed: cubit.togglePasswordVisibility,
                        icon: Icon(
                          state.obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          showUnderConstruction(context, 'O "Esqueci a senha"'),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('login.submit'),
                    onPressed: state.isSubmitting ? null : cubit.submit,
                    child: state.isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Entrando…'),
                            ],
                          )
                        : const Text('Entrar'),
                  ),
                  const SizedBox(height: 18),
                  _DemoAccountHint(onTap: cubit.fillDemoAccount),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Server answer (wrong password, locked, offline) above the form.
class _ServerError extends StatelessWidget {
  const _ServerError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final expense = context.monte.expense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        liveRegion: true,
        child: Container(
          key: const Key('login.serverError'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: expense.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, color: expense, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: expense, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The evaluators need a way in: tapping fills the demo account.
class _DemoAccountHint extends StatelessWidget {
  const _DemoAccountHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.monte.subtle);
    return Center(
      child: InkWell(
        key: const Key('login.demo'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text.rich(
            TextSpan(
              text: 'Conta de demonstração: ',
              children: [
                TextSpan(
                  text: CpfInputFormatter.format(LoginCubit.demoCpf),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' · senha '),
                const TextSpan(
                  text: LoginCubit.demoPassword,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '\nToque para preencher'),
              ],
            ),
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      ),
    );
  }
}
