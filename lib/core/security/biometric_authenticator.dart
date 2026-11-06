import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// Fingerprint / face check, behind an interface so screens and tests do
/// not depend on the platform plugin.
abstract interface class BiometricAuthenticator {
  /// The device has biometrics enrolled (or a screen lock to fall back to).
  Future<bool> isAvailable();

  /// Shows the system prompt. `false` when the user cancels or fails;
  /// never throws.
  Future<bool> authenticate(String reason);
}

final class LocalBiometricAuthenticator implements BiometricAuthenticator {
  LocalBiometricAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Confirme que é você',
            cancelButton: 'Usar senha',
          ),
        ],
        persistAcrossBackgrounding: true,
      );
    } on Exception {
      // Lockout, no hardware, cancelled by the system: the caller falls
      // back to the password, so every failure is just "not confirmed".
      return false;
    }
  }
}
