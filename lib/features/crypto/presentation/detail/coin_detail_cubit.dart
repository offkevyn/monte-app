import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/async/cancel_signal.dart';
import '../../../../core/failures/failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/market_data.dart';
import '../../domain/repositories/market_repository.dart';

enum CoinDetailStatus { loading, ready, failure }

final class CoinDetailState extends Equatable {
  const CoinDetailState({
    this.status = CoinDetailStatus.loading,
    this.quote,
    this.failure,
    this.range = ChartRange.day,
    this.chart,
    this.chartLoading = true,
    this.chartFailure,
    this.favorite = false,
  });

  final CoinDetailStatus status;
  final CoinQuote? quote;
  final Failure? failure;
  final ChartRange range;

  /// Chart of [range]; the previous one stays on screen while the next
  /// period loads, so the card does not jump.
  final CoinChart? chart;
  final bool chartLoading;
  final Failure? chartFailure;
  final bool favorite;

  CoinDetailState copyWith({
    CoinDetailStatus? status,
    CoinQuote? quote,
    Failure? Function()? failure,
    ChartRange? range,
    CoinChart? Function()? chart,
    bool? chartLoading,
    Failure? Function()? chartFailure,
    bool? favorite,
  }) => CoinDetailState(
    status: status ?? this.status,
    quote: quote ?? this.quote,
    failure: failure != null ? failure() : this.failure,
    range: range ?? this.range,
    chart: chart != null ? chart() : this.chart,
    chartLoading: chartLoading ?? this.chartLoading,
    chartFailure: chartFailure != null ? chartFailure() : this.chartFailure,
    favorite: favorite ?? this.favorite,
  );

  @override
  List<Object?> get props => [
    status,
    quote,
    failure,
    range,
    chart,
    chartLoading,
    chartFailure,
    favorite,
  ];
}

/// ViewModel of the coin detail: quote, chart by period and the star.
///
/// Picking another period cancels the request of the previous one, so
/// tapping 24h → 7d → 30d quickly costs one finished call and never shows
/// the 7d chart under the 30d button.
class CoinDetailCubit extends Cubit<CoinDetailState> {
  CoinDetailCubit(this._repository) : super(const CoinDetailState());

  final MarketRepository _repository;
  StreamSubscription<Set<String>>? _favorites;
  CancelSignal? _chartCancel;
  String _id = '';

  Future<void> load(String id) async {
    _id = id;
    await _favorites?.cancel();
    _favorites = _repository.watchFavoriteIds().listen((ids) {
      if (!isClosed) emit(state.copyWith(favorite: ids.contains(id)));
    });
    await Future.wait([_loadQuote(), _loadChart(state.range)]);
  }

  Future<void> refresh() =>
      Future.wait([_loadQuote(forceRefresh: true), _loadChart(state.range)]);

  Future<void> selectRange(ChartRange range) async {
    if (range == state.range && !state.chartLoading) return;
    emit(state.copyWith(range: range));
    await _loadChart(range);
  }

  Future<void> toggleFavorite() async {
    // The stream of favorites updates the star; only failures matter here.
    final result = await _repository.toggleFavorite(_id);
    if (result case Err(:final failure) when !isClosed) {
      emit(state.copyWith(failure: () => failure));
    }
  }

  Future<void> _loadQuote({bool forceRefresh = false}) async {
    final result = await _repository.getCoin(_id, forceRefresh: forceRefresh);
    if (isClosed) return;
    switch (result) {
      case Ok(:final value):
        emit(
          state.copyWith(
            status: CoinDetailStatus.ready,
            quote: value,
            failure: () => null,
          ),
        );
      case Err(:final failure):
        emit(
          state.copyWith(
            status: state.quote == null ? CoinDetailStatus.failure : null,
            failure: () => failure,
          ),
        );
    }
  }

  Future<void> _loadChart(ChartRange range) async {
    _chartCancel?.cancel();
    final cancel = _chartCancel = CancelSignal();
    emit(state.copyWith(chartLoading: true, chartFailure: () => null));
    final result = await _repository.getChart(_id, range, cancel: cancel);
    if (isClosed || cancel.isCancelled || range != state.range) return;
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(chart: () => value, chartLoading: false));
      case Err(failure: CancelledFailure()):
        return;
      case Err(:final failure):
        emit(state.copyWith(chartLoading: false, chartFailure: () => failure));
    }
  }

  @override
  Future<void> close() async {
    _chartCancel?.cancel();
    await _favorites?.cancel();
    return super.close();
  }
}
