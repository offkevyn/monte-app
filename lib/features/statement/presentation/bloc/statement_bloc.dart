import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../../core/async/cancel_signal.dart';

import '../../../../core/failures/failure.dart';
import '../../../../core/freshness/data_freshness.dart';
import '../../../../core/result/result.dart';
import '../../../../core/time/local_calendar.dart';
import '../../../ledger/domain/entities/transaction.dart';
import '../../../ledger/domain/entities/transaction_filter.dart';
import '../../../ledger/domain/entities/transaction_page.dart';
import '../../../ledger/domain/services/day_grouping.dart';
import '../../../ledger/domain/usecases/get_statement_page.dart';

// ---------------------------------------------------------------- events

sealed class StatementEvent {
  const StatementEvent();
}

/// Screen opened.
final class StatementStarted extends StatementEvent {
  const StatementStarted();
}

/// Every keystroke in the search field. Debounced: only the last text
/// after a pause reaches the data layer.
final class StatementQueryChanged extends StatementEvent {
  const StatementQueryChanged(this.text);

  final String text;
}

/// Type, status or period changed in the sheet or by removing a chip. The
/// search text is kept.
final class StatementFilterChanged extends StatementEvent {
  const StatementFilterChanged(this.filter);

  final TransactionFilter filter;
}

/// Scrolled near the end.
final class StatementNextPageRequested extends StatementEvent {
  const StatementNextPageRequested();
}

/// The tab is on screen again (picked in the bar, or the app came back):
/// looks for news on the unfiltered list. The repository skips the network
/// when it fetched seconds ago.
final class StatementVisited extends StatementEvent {
  const StatementVisited();
}

/// Pull to refresh.
final class StatementRefreshed extends StatementEvent {
  const StatementRefreshed();
}

/// The single "load the first page" step behind started, search, filters
/// and refresh, so they all share one restartable queue: a newer request
/// always cancels the older one, whichever started it.
final class _FirstPageRequested extends StatementEvent {
  const _FirstPageRequested(this.filter, {this.forceRefresh = false});

  final TransactionFilter filter;
  final bool forceRefresh;
}

// ----------------------------------------------------------------- state

enum StatementStatus { initial, loading, ready, failure }

final class StatementState extends Equatable {
  StatementState({
    this.status = StatementStatus.initial,
    List<Transaction> items = const [],
    TransactionFilter? filter,
    this.nextCursor,
    this.reloading = false,
    this.loadingMore = false,
    this.failure,
    this.pageFailure,
    this.freshness,
    this.fromDevice = false,
    this.groups = const [],
  }) : items = List.unmodifiable(items),
       filter = filter ?? TransactionFilter.none;

  final StatementStatus status;

  /// Every page loaded so far, newest first.
  final List<Transaction> items;

  /// The same items grouped by the user's day, ready for the list.
  final List<DayGroup> groups;

  final TransactionFilter filter;
  final String? nextCursor;

  /// A new search or filter is loading while the old list stays on screen
  /// (thin progress bar instead of skeletons).
  final bool reloading;
  final bool loadingMore;

  /// First page failed and there is nothing to show.
  final Failure? failure;

  /// A next page failed; the list stays and the footer offers a retry.
  final Failure? pageFailure;
  final DataFreshness? freshness;

  /// The server could not be reached and the list comes from what is saved
  /// on the device, which may miss transactions.
  final bool fromDevice;

  bool get hasMore => nextCursor != null;

  bool get isEmpty => status == StatementStatus.ready && items.isEmpty;

  StatementState copyWith({
    StatementStatus? status,
    List<Transaction>? items,
    List<DayGroup>? groups,
    TransactionFilter? filter,
    String? Function()? nextCursor,
    bool? reloading,
    bool? loadingMore,
    Failure? Function()? failure,
    Failure? Function()? pageFailure,
    DataFreshness? freshness,
    bool? fromDevice,
  }) => StatementState(
    status: status ?? this.status,
    items: items ?? this.items,
    groups: groups ?? this.groups,
    filter: filter ?? this.filter,
    nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
    reloading: reloading ?? this.reloading,
    loadingMore: loadingMore ?? this.loadingMore,
    failure: failure != null ? failure() : this.failure,
    pageFailure: pageFailure != null ? pageFailure() : this.pageFailure,
    freshness: freshness ?? this.freshness,
    fromDevice: fromDevice ?? this.fromDevice,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    filter,
    nextCursor,
    reloading,
    loadingMore,
    failure,
    pageFailure,
    freshness,
    fromDevice,
  ];
}

// ------------------------------------------------------------------ bloc

/// ViewModel of the statement. A Bloc (not a Cubit) because of the event
/// transformers: debounce on search, restartable on first-page loads and
/// droppable on pagination.
class StatementBloc extends Bloc<StatementEvent, StatementState> {
  StatementBloc(
    this._getPage,
    this._calendar, {
    this.debounce = const Duration(milliseconds: 350),
    this.pageSize = TransactionQuery.defaultLimit,
  }) : super(StatementState()) {
    on<StatementStarted>((_, _) => _reload(state.filter));
    on<StatementQueryChanged>(
      _onQueryChanged,
      transformer: _debounceRestartable(debounce),
    );
    on<StatementFilterChanged>(
      (event, _) => _reload(event.filter.copyWith(query: state.filter.query)),
    );
    on<StatementVisited>((_, _) {
      if (state.status == StatementStatus.ready && state.filter.isEmpty) {
        _reload(state.filter);
      }
    });
    on<StatementRefreshed>((_, _) => _reload(state.filter, forceRefresh: true));
    on<_FirstPageRequested>(_onFirstPage, transformer: restartable());
    on<StatementNextPageRequested>(_onNextPage, transformer: droppable());
  }

  final GetStatementPage _getPage;
  final LocalCalendar _calendar;

  /// Cancels the first-page request a newer search or filter replaced.
  CancelSignal? _firstPageCancel;
  final Duration debounce;
  final int pageSize;

  static EventTransformer<E> _debounceRestartable<E>(Duration duration) =>
      (events, mapper) => events.debounce(duration).switchMap(mapper);

  void _reload(TransactionFilter filter, {bool forceRefresh = false}) =>
      add(_FirstPageRequested(filter, forceRefresh: forceRefresh));

  void _onQueryChanged(
    StatementQueryChanged event,
    Emitter<StatementState> emit,
  ) {
    final filter = state.filter.copyWith(query: event.text);
    if (filter.query == state.filter.query &&
        state.status != StatementStatus.initial) {
      return;
    }
    _reload(filter);
  }

  Future<void> _onFirstPage(
    _FirstPageRequested event,
    Emitter<StatementState> emit,
  ) async {
    _firstPageCancel?.cancel();
    final cancel = _firstPageCancel = CancelSignal();

    var hasList = state.status == StatementStatus.ready;
    if (!hasList) {
      // Show what is saved right away; the server answer replaces it.
      final saved = await _getPage.saved(event.filter);
      if (saved case Ok(value: final page?) when page.items.isNotEmpty) {
        hasList = true;
        emit(_withPage(state, page, filter: event.filter));
      }
    }
    emit(
      state.copyWith(
        filter: event.filter,
        status: hasList ? null : StatementStatus.loading,
        reloading: hasList,
        pageFailure: () => null,
      ),
    );

    final result = await _getPage(
      TransactionQuery(filter: event.filter, limit: pageSize),
      force: event.forceRefresh,
      cancel: cancel,
    );
    // `restartable` cancels this handler when a newer request arrives; any
    // emit after that point is ignored, so stale results never show.
    switch (result) {
      case Ok(value: final page):
        emit(_merge(page, event.filter).copyWith(reloading: false));
      case Err(failure: CancelledFailure()):
        emit(state.copyWith(reloading: false));
      case Err(:final failure):
        emit(
          state.copyWith(
            status: hasList ? null : StatementStatus.failure,
            failure: () => failure,
            reloading: false,
          ),
        );
    }
  }

  /// A fresh first page on top of the list already on screen. When its last
  /// item is in the list, the pages below are kept (the person may have
  /// scrolled down); otherwise too much changed and the list starts over.
  StatementState _merge(TransactionPage page, TransactionFilter filter) {
    final current = state.items;
    final sameList = state.filter == filter && !state.fromDevice;
    if (sameList && page.items.isNotEmpty && page.nextCursor != null) {
      final lastId = page.items.last.id;
      final at = current.indexWhere((t) => t.id == lastId);
      if (at != -1 && at < current.length - 1) {
        final items = [...page.items, ...current.skip(at + 1)];
        return state.copyWith(
          status: StatementStatus.ready,
          items: items,
          groups: DayGrouping.group(items, _calendar),
          freshness: page.freshness,
          fromDevice: page.fromDevice,
          failure: () => null,
        );
      }
    }
    return _withPage(state, page, filter: filter);
  }

  StatementState _withPage(
    StatementState from,
    TransactionPage page, {
    required TransactionFilter filter,
  }) => from.copyWith(
    status: StatementStatus.ready,
    filter: filter,
    items: page.items,
    groups: DayGrouping.group(page.items, _calendar),
    nextCursor: () => page.nextCursor,
    freshness: page.freshness,
    fromDevice: page.fromDevice,
    failure: () => null,
  );

  @override
  Future<void> close() {
    _firstPageCancel?.cancel();
    return super.close();
  }

  Future<void> _onNextPage(
    StatementNextPageRequested event,
    Emitter<StatementState> emit,
  ) async {
    final cursor = state.nextCursor;
    if (cursor == null ||
        state.status != StatementStatus.ready ||
        state.reloading) {
      return;
    }
    final filter = state.filter;
    emit(state.copyWith(loadingMore: true, pageFailure: () => null));
    final result = await _getPage(
      TransactionQuery(filter: filter, cursor: cursor, limit: pageSize),
    );
    // A new search may have replaced the list meanwhile: then this page
    // belongs to the old one and is dropped.
    if (state.filter != filter || state.nextCursor != cursor) return;
    switch (result) {
      case Ok(value: final page):
        final items = [...state.items, ...page.items];
        emit(
          state.copyWith(
            items: items,
            groups: DayGrouping.group(items, _calendar),
            nextCursor: () => page.nextCursor,
            freshness: page.freshness,
            fromDevice: state.fromDevice || page.fromDevice,
            loadingMore: false,
          ),
        );
      case Err(:final failure):
        emit(state.copyWith(loadingMore: false, pageFailure: () => failure));
    }
  }
}
