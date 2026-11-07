import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/platform/app_info.dart';
import '../../../core/security/biometric_authenticator.dart';
import '../../../core/storage/app_preferences.dart';
import '../../auth/domain/usecases/auth_usecases.dart';
import '../../auth/presentation/current_session.dart';
import '../../crypto/domain/repositories/market_repository.dart';
import '../../ledger/domain/repositories/ledger_repository.dart';

final class ProfileState extends Equatable {
  const ProfileState({
    this.loaded = false,
    this.biometricsAvailable = false,
    this.loginBiometrics = false,
    this.balanceBiometrics = false,
    this.version,
    this.signingOut = false,
  });

  final bool loaded;

  /// The device has a fingerprint (or face) enrolled. Without it both
  /// switches are disabled instead of failing when tapped.
  final bool biometricsAvailable;

  /// Open the app with the fingerprint instead of the password.
  final bool loginBiometrics;

  /// Ask for the fingerprint before showing a hidden balance.
  final bool balanceBiometrics;

  final String? version;
  final bool signingOut;

  ProfileState copyWith({
    bool? loaded,
    bool? biometricsAvailable,
    bool? loginBiometrics,
    bool? balanceBiometrics,
    String? version,
    bool? signingOut,
  }) => ProfileState(
    loaded: loaded ?? this.loaded,
    biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
    loginBiometrics: loginBiometrics ?? this.loginBiometrics,
    balanceBiometrics: balanceBiometrics ?? this.balanceBiometrics,
    version: version ?? this.version,
    signingOut: signingOut ?? this.signingOut,
  );

  @override
  List<Object?> get props => [
    loaded,
    biometricsAvailable,
    loginBiometrics,
    balanceBiometrics,
    version,
    signingOut,
  ];
}

/// Security switches and sign out. The theme lives in `ThemeController`,
/// shared with the dashboard button, so it is not repeated here.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required this._preferences,
    required this._biometrics,
    required this._appInfo,
    required this._signOut,
    required this._ledger,
    required this._market,
    required this._session,
  }) : super(const ProfileState());

  final AppPreferences _preferences;
  final BiometricAuthenticator _biometrics;
  final AppInfo _appInfo;
  final SignOut _signOut;
  final LedgerRepository _ledger;
  final MarketRepository _market;
  final CurrentSession _session;

  Future<void> load() async {
    final available = await _biometrics.isAvailable();
    final login = await _preferences.biometricsEnabled();
    final balance = await _preferences.balanceNeedsBiometrics();
    final version = await _appInfo.version();
    if (isClosed) return;
    emit(
      state.copyWith(
        loaded: true,
        biometricsAvailable: available,
        loginBiometrics: login,
        balanceBiometrics: balance,
        version: version,
      ),
    );
  }

  /// Turning it on confirms the fingerprint first, like the offer after the
  /// first login; turning it off only makes the app ask for the password.
  Future<void> setLoginBiometrics({required bool enabled}) async {
    if (enabled &&
        !await _biometrics.authenticate(
          'Confirme sua digital para entrar com ela',
        )) {
      return;
    }
    await _preferences.setBiometricsEnabled(enabled: enabled);
    // Choosing here counts as answering the offer: it is not shown again.
    await _preferences.markBiometricsOfferShown();
    if (!isClosed) emit(state.copyWith(loginBiometrics: enabled));
  }

  /// Both ways need the fingerprint: otherwise whoever holds the unlocked
  /// phone could simply switch the protection off.
  Future<void> setBalanceBiometrics({required bool enabled}) async {
    final confirmed = await _biometrics.authenticate(
      enabled
          ? 'Confirme sua digital para proteger o saldo'
          : 'Confirme que é você para tirar a proteção do saldo',
    );
    if (!confirmed) return;
    await _preferences.setBalanceNeedsBiometrics(enabled: enabled);
    if (!isClosed) emit(state.copyWith(balanceBiometrics: enabled));
  }

  /// Ends the session and wipes everything saved for this account: the
  /// token in the secure store and both local databases.
  Future<void> signOut() async {
    if (state.signingOut) return;
    emit(state.copyWith(signingOut: true));
    await _signOut();
    await _ledger.clear();
    await _market.clear();
    _session.end();
  }
}
