import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/security/biometric_authenticator.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/entities/cpf.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../current_session.dart';

sealed class SplashState {
  const SplashState();
}

final class SplashChecking extends SplashState {
  const SplashChecking();
}

final class SplashGoToLogin extends SplashState {
  const SplashGoToLogin({this.lastCpf});

  final Cpf? lastCpf;
}

final class SplashGoHome extends SplashState {
  const SplashGoHome();
}

/// Decides the first screen while the splash animation plays.
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(
    this._resolveStart,
    this._preferences,
    this._biometrics,
    this._currentSession,
  ) : super(const SplashChecking());

  final ResolveStart _resolveStart;
  final AppPreferences _preferences;
  final BiometricAuthenticator _biometrics;
  final CurrentSession _currentSession;

  Future<void> start() async {
    final destination = await _resolveStart(
      biometricsEnabled: await _preferences.biometricsEnabled(),
    );
    switch (destination) {
      case GoToLogin(:final lastCpf):
        emit(SplashGoToLogin(lastCpf: lastCpf));
      case UnlockWithBiometrics(:final session):
        final confirmed = await _biometrics.authenticate(
          'Use sua digital para entrar no Monte',
        );
        if (confirmed) {
          _currentSession.start(session);
          emit(const SplashGoHome());
        } else {
          emit(SplashGoToLogin(lastCpf: session.cpf));
        }
    }
  }
}
