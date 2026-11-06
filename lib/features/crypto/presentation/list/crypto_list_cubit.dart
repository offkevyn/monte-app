import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/async/cancel_signal.dart';
import '../../../../core/failures/failure.dart';
import '../../../../core/freshness/data_freshness.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/coin.dart';
import '../../domain/entities/market_data.dart';
import '../../domain/repositories/market_repository.dart';
import '../../domain/usecases/market_usecases.dart';

enum CryptoListStatus { loading, ready, failure }

final class CryptoListState extends Equatable {
  const CryptoListState({
    this.tab = MarketTab.mostTraded,
    this.query = '',
    this.status = CryptoListStatus.loading,
    this.coins = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.refreshing = false,
    this.freshness,
    this.failure,
    this.pageFailure,
  });

  final MarketTab tab;

  /// Search being shown; empty means the tab list is shown.
  final String query;
  final CryptoListStatus status;
  final List<Coin> coins;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final bool refreshing;
  final DataFreshness? freshness;

  /// Why there is nothing to show (first load failed).
  final Failure? failure;

  /// Why the next page did not come (the list stays, with a retry button).
  final Failure? pageFailure;

  bool get searching => query.isNotEmpty;

  CryptoListState copyWith({
    MarketTab? tab,
    String? query,
    CryptoListStatus? status,
    List<Coin>? coins,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    bool? refreshing,
    DataFreshness? Function()? freshness,
    Failure? Function()? failure,
    Failure? Function()? pageFailure,
  }) => CryptoListState(
    tab: tab ?? this.tab,
    query: query ?? this.query,
    status: status ?? this.status,
    coins: coins ?? this.coins,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    refreshing: refreshing ?? this.refreshing,
    freshness: freshness != null ? freshness() : this.freshness,
    failure: failure != null ? failure() : this.failure,
    pageFailure: pageFailure != null ? pageFailure() : this.pageFailure,
  );

  @override
  List<Object?> get props => [
    tab,
    query,
    status,
    coins,
    page,
    hasMore,
    loadingMore,
    refreshing,
    freshness,
    failure,
    pageFailure,
  ];
}

/// ViewModel of the crypto list: tabs, paging and the search.
///
/// The search waits [debounce] after the last letter, and a newer search
/// cancels the older request: on a plan with a limit of calls per minute,
/// typing "bitcoin" must cost one call, not seven.
class CryptoListCubit extends Cubit<CryptoListState> {
  CryptoListCubit(
    this._loadTab,
    this._search,
    MarketRepository repository, {
    this.debounce = const Duration(milliseconds: 350),
  }) : super(const CryptoListState()) {
    _favorites = repository.watchFavoriteIds().skip(1).listen((_) {
      if (state.tab == MarketTab.favorites && !state.searching) {
        unawaited(_loadFirstPage());
      }
    });
  }

  final LoadMarketTab _loadTab;
  final SearchCoins _search;
  final Duration debounce;

  late final StreamSubscription<Set<String>> _favorites;
  Timer? _debounceTimer;
  CancelSignal? _searchCancel;

  /// Increases on every first-page request; an answer that comes back with
  /// an older number is out of date and is dropped.
  var _generation = 0;

  Future<void> load() => _loadFirstPage();

  Future<void> selectTab(MarketTab tab) async {
    if (tab == state.tab && !state.searching) return;
    emit(state.copyWith(tab: tab));
    if (!state.searching) await _loadFirstPage(showLoading: true);
  }

  /// Called on every keystroke.
  void queryChanged(String text) {
    _debounceTimer?.cancel();
    final query = SearchCoins.normalize(text);
    final isSearch = query.length >= SearchCoins.minLength;
    if (!isSearch) {
      _searchCancel?.cancel();
      if (state.searching) {
        emit(state.copyWith(query: ''));
        unawaited(_loadFirstPage(showLoading: true));
      }
      return;
    }
    if (query == state.query) return;
    _debounceTimer = Timer(debounce, () {
      emit(state.copyWith(query: query));
      unawaited(_loadFirstPage(showLoading: true));
    });
  }

  /// Pull to refresh, and the automatic retry after a 429 countdown.
  Future<void> refresh() async {
    if (state.refreshing) return;
    emit(state.copyWith(refreshing: true));
    await _loadFirstPage(forceRefresh: true);
  }

  Future<void> loadMore() async {
    if (state.status != CryptoListStatus.ready ||
        state.searching ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    final generation = _generation;
    final next = state.page + 1;
    emit(state.copyWith(loadingMore: true, pageFailure: () => null));
    final result = await _loadTab(state.tab, page: next);
    if (isClosed || generation != _generation) return;
    switch (result) {
      case Ok(:final value):
        // The ranking moves between pages; a coin already shown is not
        // repeated.
        final shown = {for (final coin in state.coins) coin.id};
        emit(
          state.copyWith(
            coins: [
              ...state.coins,
              ...value.coins.where((coin) => shown.add(coin.id)),
            ],
            page: next,
            hasMore: value.hasMore,
            loadingMore: false,
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(loadingMore: false, pageFailure: () => failure));
    }
  }

  Future<void> _loadFirstPage({
    bool forceRefresh = false,
    bool showLoading = false,
  }) async {
    final generation = ++_generation;
    _searchCancel?.cancel();
    if (showLoading || state.coins.isEmpty) {
      emit(
        state.copyWith(
          status: CryptoListStatus.loading,
          coins: const [],
          page: 1,
          hasMore: false,
          pageFailure: () => null,
        ),
      );
    }

    final Result<MarketList> result;
    if (state.searching) {
      final cancel = _searchCancel = CancelSignal();
      result = await _search(state.query, cancel: cancel);
    } else {
      result = await _loadTab(state.tab, forceRefresh: forceRefresh);
    }
    if (isClosed || generation != _generation) return;

    switch (result) {
      case Ok(:final value):
        emit(
          state.copyWith(
            status: CryptoListStatus.ready,
            coins: value.coins,
            page: 1,
            hasMore: value.hasMore,
            refreshing: false,
            freshness: () => value.freshness,
            failure: () => null,
            pageFailure: () => null,
          ),
        );
      case Err(failure: CancelledFailure()):
        emit(state.copyWith(refreshing: false));
      case Err(:final failure):
        // With coins on screen a failed refresh keeps them; without, the
        // error screen takes over.
        emit(
          state.copyWith(
            status: state.coins.isEmpty ? CryptoListStatus.failure : null,
            failure: () => failure,
            refreshing: false,
          ),
        );
    }
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    _searchCancel?.cancel();
    await _favorites.cancel();
    return super.close();
  }
}
