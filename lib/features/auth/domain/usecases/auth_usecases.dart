import '../../../../core/failures/failure.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/user_data.dart';
import '../../../../core/time/clock.dart';
import '../entities/cpf.dart';
import '../entities/session.dart';
import '../repositories/auth_repository.dart';

/// Signs in with CPF and password.
final class SignIn {
  const SignIn(this._repository, {this._userData = const []});

  final AuthRepository _repository;
  final List<UserData> _userData;

  /// Rejects an empty password before calling the server: there is no
  /// reason to spend a login attempt on it.
  ///
  /// Another CPF signing in on this device must not see what the previous
  /// customer left saved: their data goes once the new login is accepted.
  Future<Result<Session>> call(Cpf cpf, String password) async {
    if (password.isEmpty) return const Err(InvalidCredentialsFailure());
    final previous = await _repository.lastCpf();
    final result = await _repository.signIn(cpf, password);
    if (result is Ok && previous != null && previous != cpf) {
      await clearUserData(_userData);
    }
    return result;
  }
}

/// Empties every store of the customer's data. One store failing does not
/// stop the others: the session is gone either way, and what is left is
/// encrypted with a key of the device.
Future<void> clearUserData(List<UserData> stores) async {
  for (final store in stores) {
    try {
      await store.clear();
    } on Exception {
      // Keep clearing the rest.
    }
  }
}

/// Where the app should go when it opens.
sealed class StartDestination {
  const StartDestination();
}

/// No valid session: show the login, prefilled with the last CPF.
final class GoToLogin extends StartDestination {
  const GoToLogin({this.lastCpf});

  final Cpf? lastCpf;
}

/// Valid session, but the customer must prove it is them (fingerprint)
/// before seeing the account.
final class UnlockWithBiometrics extends StartDestination {
  const UnlockWithBiometrics(this.session);

  final Session session;
}

/// Decides the first screen from the stored session.
///
/// A session alone is not enough to open the account: like a bank app, the
/// customer types the password again unless they turned the fingerprint on.
///
/// An expired session is a full sign out: the token and the saved data go.
final class ResolveStart {
  const ResolveStart(this._repository, this._clock, this._signOut);

  final AuthRepository _repository;
  final Clock _clock;
  final SignOut _signOut;

  Future<StartDestination> call({required bool biometricsEnabled}) async {
    final session = await _repository.storedSession();
    if (session == null || session.isExpiredAt(_clock.nowUtc())) {
      if (session != null) await _signOut();
      return GoToLogin(lastCpf: await _repository.lastCpf());
    }
    if (biometricsEnabled) return UnlockWithBiometrics(session);
    return GoToLogin(lastCpf: session.cpf);
  }
}

/// Leaves the account on this device: the session and every saved copy of
/// the customer's data. The same step for "Sair", an expired session and a
/// token the bank rejected.
final class SignOut {
  const SignOut(this._repository, {this._userData = const []});

  final AuthRepository _repository;
  final List<UserData> _userData;

  Future<void> call() async {
    await _repository.signOut();
    await clearUserData(_userData);
  }
}
