import 'dart:async';

import '../core/session/session_expiry.dart';
import '../features/auth/domain/entities/cpf.dart';
import '../features/auth/domain/usecases/auth_usecases.dart';
import '../features/auth/presentation/current_session.dart';

/// Signs the customer out, everywhere, when the bank rejects the session.
///
/// The dashboard asks four things at once, so a rejected session arrives as
/// several 401s together: only the first one acts, and only while someone
/// is signed in (a 401 after leaving is just a late answer).
final class SessionExpiryHandler {
  SessionExpiryHandler({
    required this._expiry,
    required this._signOut,
    required this._session,
    required this._goToLogin,
  });

  final SessionExpiry _expiry;
  final SignOut _signOut;
  final CurrentSession _session;
  final void Function(Cpf? lastCpf) _goToLogin;

  StreamSubscription<void>? _subscription;
  var _ending = false;

  void start() => _subscription ??= _expiry.rejected.listen((_) => _end());

  Future<void> _end() async {
    final current = _session.value;
    if (current == null || _ending) return;
    _ending = true;
    try {
      _session.end();
      await _signOut();
      _goToLogin(current.cpf);
    } finally {
      _ending = false;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
