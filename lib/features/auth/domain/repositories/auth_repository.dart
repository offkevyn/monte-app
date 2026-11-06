import '../../../../core/result/result.dart';
import '../entities/cpf.dart';
import '../entities/session.dart';

abstract interface class AuthRepository {
  /// Checks the credentials with the server and stores the session.
  Future<Result<Session>> signIn(Cpf cpf, String password);

  /// The stored session, if any (it may be expired; the caller decides).
  Future<Session?> storedSession();

  /// CPF of the last customer who signed in, to prefill the login.
  Future<Cpf?> lastCpf();

  /// Forgets the session (the last CPF is kept for convenience).
  Future<void> signOut();
}
