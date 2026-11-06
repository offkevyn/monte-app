import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/failures/failure.dart';
import '../../../core/result/result.dart';
import '../../../core/security/biometric_authenticator.dart';
import '../../../core/storage/app_preferences.dart';
import '../../ledger/domain/entities/date_span.dart';
import '../../ledger/domain/usecases/get_dashboard.dart';

enum DashboardStatus { loading, ready, failure }

final class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.loading,
    this.summary,
    this.failure,
    this.preset = PeriodPreset.thisMonth,
    this.balanceHidden = false,
    this.refreshing = false,
  });

  final DashboardStatus status;

  /// Last data shown. Kept while refreshing or changing the period, so the
  /// screen never blinks back to skeletons.
  final DashboardSummary? summary;

  /// Set when there is nothing to show at all (first load failed).
  final Failure? failure;
  final PeriodPreset preset;
  final bool balanceHidden;
  final bool refreshing;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSummary? summary,
    Failure? Function()? failure,
    PeriodPreset? preset,
    bool? balanceHidden,
    bool? refreshing,
  }) => DashboardState(
    status: status ?? this.status,
    summary: summary ?? this.summary,
    failure: failure != null ? failure() : this.failure,
    preset: preset ?? this.preset,
    balanceHidden: balanceHidden ?? this.balanceHidden,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [
    status,
    summary,
    failure,
    preset,
    balanceHidden,
    refreshing,
  ];
}

/// ViewModel of the dashboard. All numbers come from `GetDashboard`, which
/// computes them from the same local snapshot the statement reads.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._getDashboard, this._preferences, this._biometrics)
    : super(const DashboardState());

  final GetDashboard _getDashboard;
  final AppPreferences _preferences;
  final BiometricAuthenticator _biometrics;

  Future<void> load() async {
    emit(
      state.copyWith(
        balanceHidden: await _preferences.hideBalance(),
        status: state.summary == null ? DashboardStatus.loading : null,
      ),
    );
    await _fetch();
  }

  /// Pull to refresh: always asks the server.
  Future<void> refresh() async {
    if (state.refreshing) return;
    emit(state.copyWith(refreshing: true));
    await _fetch(forceRefresh: true);
  }

  Future<void> selectPeriod(PeriodPreset preset) async {
    if (preset == state.preset) return;
    emit(state.copyWith(preset: preset));
    await _fetch();
  }

  /// Eye button. Revealing may ask for the fingerprint, when the customer
  /// turned that on; hiding never does.
  Future<void> toggleBalance() async {
    final reveal = state.balanceHidden;
    if (reveal && await _preferences.balanceNeedsBiometrics()) {
      final confirmed = await _biometrics.authenticate(
        'Confirme que é você para mostrar o saldo',
      );
      if (!confirmed) return;
    }
    emit(state.copyWith(balanceHidden: !reveal));
    await _preferences.setHideBalance(hidden: !reveal);
  }

  Future<void> _fetch({bool forceRefresh = false}) async {
    final result = await _getDashboard(
      preset: state.preset,
      forceRefresh: forceRefresh,
    );
    if (isClosed) return;
    switch (result) {
      case Ok(value: final summary):
        emit(
          state.copyWith(
            status: DashboardStatus.ready,
            summary: summary,
            failure: () => null,
            refreshing: false,
          ),
        );
      case Err(failure: CancelledFailure()):
        emit(state.copyWith(refreshing: false));
      case Err(:final failure):
        // With data on screen, a failed refresh keeps it (the repository
        // already serves the local copy when it can). Without data, the
        // error screen takes over.
        emit(
          state.copyWith(
            status: state.summary == null ? DashboardStatus.failure : null,
            failure: () => failure,
            refreshing: false,
          ),
        );
    }
  }
}
