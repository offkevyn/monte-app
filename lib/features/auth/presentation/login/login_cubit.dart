import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/failures/failure.dart';
import '../../../../core/result/result.dart';
import '../../../../core/security/biometric_authenticator.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/entities/cpf.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../cpf_input_formatter.dart';
import '../current_session.dart';

enum LoginStep {
  /// Filling the form (possibly after an error).
  editing,

  /// Waiting for the server.
  submitting,

  /// Signed in; asking once whether to use the fingerprint.
  offeringBiometrics,

  /// Signed in and nothing else to ask: go to the app.
  done,
}

final class LoginState extends Equatable {
  const LoginState({
    this.cpf = '',
    this.password = '',
    this.cpfError,
    this.passwordError,
    this.failure,
    this.step = LoginStep.editing,
    this.obscurePassword = true,
  });

  /// As typed, with the mask.
  final String cpf;
  final String password;

  /// Field messages, shown under each input.
  final String? cpfError;
  final String? passwordError;

  /// Server answer, shown in a card above the form.
  final Failure? failure;
  final LoginStep step;
  final bool obscurePassword;

  bool get isSubmitting => step == LoginStep.submitting;

  LoginState copyWith({
    String? cpf,
    String? password,
    String? Function()? cpfError,
    String? Function()? passwordError,
    Failure? Function()? failure,
    LoginStep? step,
    bool? obscurePassword,
  }) => LoginState(
    cpf: cpf ?? this.cpf,
    password: password ?? this.password,
    cpfError: cpfError != null ? cpfError() : this.cpfError,
    passwordError: passwordError != null ? passwordError() : this.passwordError,
    failure: failure != null ? failure() : this.failure,
    step: step ?? this.step,
    obscurePassword: obscurePassword ?? this.obscurePassword,
  );

  @override
  List<Object?> get props => [
    cpf,
    password,
    cpfError,
    passwordError,
    failure,
    step,
    obscurePassword,
  ];
}

/// ViewModel of the login screen.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(
    this._signIn,
    this._preferences,
    this._biometrics,
    this._currentSession,
  ) : super(const LoginState());

  final SignIn _signIn;
  final AppPreferences _preferences;
  final BiometricAuthenticator _biometrics;
  final CurrentSession _currentSession;

  static const invalidCpf = 'CPF inválido. Confere os números.';
  static const emptyPassword = 'Digite sua senha.';

  /// Fills the CPF of the last customer, when the app remembers one.
  void prefill(Cpf? lastCpf) {
    if (lastCpf != null) emit(state.copyWith(cpf: lastCpf.formatted));
  }

  /// Demo account shortcut, shown on the login screen.
  void fillDemoAccount() => emit(
    state.copyWith(
      cpf: CpfInputFormatter.format(demoCpf),
      password: demoPassword,
      cpfError: () => null,
      passwordError: () => null,
      failure: () => null,
    ),
  );

  static const demoCpf = '00000000191';
  static const demoPassword = 'monte123';

  void cpfChanged(String value) => emit(
    state.copyWith(cpf: value, cpfError: () => null, failure: () => null),
  );

  void passwordChanged(String value) => emit(
    state.copyWith(
      password: value,
      passwordError: () => null,
      failure: () => null,
    ),
  );

  void togglePasswordVisibility() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  Future<void> submit() async {
    if (state.isSubmitting) return;
    final cpf = Cpf.tryParse(state.cpf);
    final cpfError = cpf == null ? invalidCpf : null;
    final passwordError = state.password.isEmpty ? emptyPassword : null;
    if (cpf == null || passwordError != null) {
      emit(
        state.copyWith(
          cpfError: () => cpfError,
          passwordError: () => passwordError,
        ),
      );
      return;
    }

    emit(state.copyWith(step: LoginStep.submitting, failure: () => null));
    switch (await _signIn(cpf, state.password)) {
      case Err(:final failure):
        emit(
          state.copyWith(
            step: LoginStep.editing,
            failure: () => failure,
            // The password is cleared after a rejection, like real apps do.
            password: failure is InvalidCredentialsFailure ? '' : null,
          ),
        );
      case Ok(value: final session):
        _currentSession.start(session);
        final offer =
            !await _preferences.biometricsOfferShown() &&
            await _biometrics.isAvailable();
        emit(
          state.copyWith(
            password: '',
            step: offer ? LoginStep.offeringBiometrics : LoginStep.done,
          ),
        );
    }
  }

  /// "Usar digital": confirms once, then remembers the choice.
  Future<void> acceptBiometrics() async {
    final confirmed = await _biometrics.authenticate(
      'Confirme sua digital para ativar o acesso rápido',
    );
    await _preferences.setBiometricsEnabled(enabled: confirmed);
    await _preferences.markBiometricsOfferShown();
    emit(state.copyWith(step: LoginStep.done));
  }

  /// "Agora não": never asks again (it can be turned on in the profile).
  Future<void> declineBiometrics() async {
    await _preferences.markBiometricsOfferShown();
    emit(state.copyWith(step: LoginStep.done));
  }
}
