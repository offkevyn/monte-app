import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/async/cancel_signal.dart';
import '../../../../core/failures/failure.dart';
import '../../../../core/freshness/data_freshness.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/network_failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/dashboard_snapshot.dart';
import '../../domain/entities/date_span.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_page.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../datasources/ledger_remote_datasource.dart';
import '../dtos/transaction_dto.dart';
import '../local/ledger_local_datasource.dart';
import '../mappers/transaction_mapper.dart';

/// The server is the source of the data; the encrypted local database is
/// what the screens read and what is left when the network is not.
///
/// - Each screen asks the server only for what it shows: a page of 20, the
///   dashboard period, one transaction's details.
/// - Every answer is saved before it is returned, and the cache is pruned
///   (see [LedgerLocalDataSource.prune]).
/// - When the server fails, the saved copy is returned marked as stale.
///   Only a cancelled request, a rejected session and "nothing saved at
///   all" reach the screen as errors.
/// - The same request repeated within [minInterval] (switching tabs back
///   and forth, coming back to the app) is answered from the device; pull
///   to refresh always goes to the server.
final class LedgerRepositoryImpl implements LedgerRepository {
  LedgerRepositoryImpl({
    required this._remote,
    required this._local,
    required this._clock,
    this.minInterval = const Duration(seconds: 30),
  });

  final LedgerRemoteDataSource _remote;
  final LedgerLocalDataSource _local;
  final Clock _clock;
  final Duration minInterval;

  /// Last successful fetch per request, in memory: a cold start always
  /// fetches.
  final _fetchedAt = <String, DateTime>{};

  /// Concurrent refreshes of the same dashboard share one set of requests.
  final _inFlight = <String, Future<Result<DashboardSnapshot>>>{};

  static const _firstPageKey = 'statement/first';

  // ---- dashboard ----

  @override
  Future<Result<DashboardSnapshot?>> savedDashboard(DateSpan period) =>
      _guardLocal(() => _readDashboard(period));

  @override
  Future<Result<DashboardSnapshot>> refreshDashboard(
    DateSpan period, {
    bool force = false,
  }) async {
    final key = 'dashboard/$period';
    if (!force && _recentlyFetched(key)) {
      final saved = await savedDashboard(period);
      if (saved case Ok(value: final snapshot?)) return Ok(snapshot);
    }
    // A block body: returning the removed future from the callback would
    // make this future wait for itself.
    return _inFlight[key] ??= _refreshDashboard(period, key).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<Result<DashboardSnapshot>> _refreshDashboard(
    DateSpan period,
    String key,
  ) async {
    final fetched = await guardRequest(() => _fetchDashboard(period));
    switch (fetched) {
      case Err(:final failure):
        return _fallbackDashboard(period, failure);
      case Ok(:final value):
        final now = _clock.nowUtc();
        final saved = await _guardLocal(() async {
          await _local.saveDashboard(
            balance: value.balance,
            period: period,
            pendingDebits: value.pending,
            transactions: [...value.recent, ...value.inPeriod],
            syncedAt: now,
            skippedRecords: value.skipped,
          );
          await _local.prune();
        });
        if (saved case Err(:final failure)) return Err(failure);
        _fetchedAt[key] = now;
        return Ok(
          DashboardSnapshot(
            settledBalance: value.balance,
            pendingDebits: value.pending,
            recent: value.recent,
            period: period,
            periodTransactions: value.inPeriod,
            freshness: DataFreshness(
              syncedAt: now,
              skippedRecords: value.skipped,
            ),
          ),
        );
    }
  }

  /// Balance, pending debits, the newest page and the whole period, asked
  /// in parallel. Nothing is saved unless all of them arrived.
  Future<
    ({
      Money balance,
      List<Transaction> pending,
      List<Transaction> recent,
      List<Transaction> inPeriod,
      int skipped,
    })
  >
  _fetchDashboard(DateSpan period) async {
    final (account, pendingPage, recentDto, periodPage) = await _all((
      _remote.fetchAccount(),
      _fetchAll(
        TransactionFilter(
          types: const {TransactionType.expense},
          statuses: const {TransactionStatus.pending},
        ),
      ),
      _remote.fetchTransactions(TransactionQuery()),
      _fetchAll(TransactionFilter(period: period)),
    ));
    final balance = TransactionMapper.balance(account);
    final recentPage = TransactionMapper.toEntities(recentDto);
    return (
      balance: balance,
      pending: pendingPage.items,
      recent: recentPage.items,
      inPeriod: periodPage.items,
      skipped: pendingPage.skipped + recentPage.skipped + periodPage.skipped,
    );
  }

  /// Waits for the four requests; when any fails, rethrows the first error
  /// so `guardRequest` maps it like a single request.
  static Future<(A, B, C, D)> _all<A, B, C, D>(
    (Future<A>, Future<B>, Future<C>, Future<D>) requests,
  ) async {
    try {
      return await requests.wait;
    } on ParallelWaitError<
      (A?, B?, C?, D?),
      (AsyncError?, AsyncError?, AsyncError?, AsyncError?)
    > catch (error) {
      final (a, b, c, d) = error.errors;
      final first = (a ?? b ?? c ?? d)!;
      Error.throwWithStackTrace(first.error, first.stackTrace);
    }
  }

  /// Every page of [filter], in big pages.
  Future<({List<Transaction> items, int skipped})> _fetchAll(
    TransactionFilter filter,
  ) async {
    final items = <Transaction>[];
    final seenCursors = <String>{};
    var skipped = 0;
    String? cursor;
    do {
      final page = await _remote.fetchBulkPage(filter, cursor: cursor);
      final mapped = TransactionMapper.toEntities(page);
      items.addAll(mapped.items);
      skipped += mapped.skipped;
      cursor = page.nextCursor;
      // A server that keeps answering the same cursor would loop forever.
      if (cursor != null && !seenCursors.add(cursor)) {
        throw const FormatException('Server repeated a pagination cursor');
      }
    } while (cursor != null);
    return (items: items, skipped: skipped);
  }

  Future<Result<DashboardSnapshot>> _fallbackDashboard(
    DateSpan period,
    Failure failure,
  ) async {
    if (!_canFallBack(failure)) return Err(failure);
    final saved = await _guardLocal(
      () => _readDashboard(period, failure: failure),
    );
    return switch (saved) {
      Ok(value: final snapshot?) => Ok(snapshot),
      Ok() => Err(failure),
      Err(failure: final storage) => Err(storage),
    };
  }

  Future<DashboardSnapshot?> _readDashboard(
    DateSpan period, {
    Failure? failure,
  }) async {
    final state = await _local.readDashboardState();
    if (state == null) return null;
    final saved = state.period;
    // The period is only offered when the device has all of it.
    final covered =
        !period.first.isBefore(saved.first) && !period.last.isAfter(saved.last);
    final recent = await _local.page(TransactionQuery());
    return DashboardSnapshot(
      settledBalance: state.balance,
      pendingDebits: await _local.byIds(state.pendingIds),
      recent: recent.items,
      period: period,
      periodTransactions: covered ? await _local.inPeriod(period) : null,
      freshness: DataFreshness(
        syncedAt: state.syncedAt,
        syncFailure: failure,
        skippedRecords: state.skippedRecords,
      ),
    );
  }

  // ---- statement ----

  @override
  Future<Result<TransactionPage?>> savedFirstPage(TransactionFilter filter) =>
      _guardLocal(() async {
        if (await _local.isEmpty()) return null;
        return _devicePage(TransactionQuery(filter: filter));
      });

  @override
  Future<Result<TransactionPage>> getPage(
    TransactionQuery query, {
    bool force = false,
    CancelSignal? cancel,
  }) async {
    final firstUnfiltered = query.cursor == null && query.filter.isEmpty;
    if (firstUnfiltered && !force && _recentlyFetched(_firstPageKey)) {
      return _guardLocal(() => _devicePage(query));
    }

    final fetched = await guardRequest(
      () => _remote.fetchTransactions(query, cancelToken: _tokenFor(cancel)),
    );
    switch (fetched) {
      case Err(:final failure) when !_canFallBack(failure):
        return Err(failure);
      case Err(:final failure):
        return _guardLocal(() async {
          if (await _local.isEmpty()) throw failure;
          return _devicePage(query, failure: failure);
        });
      case Ok(:final value):
        final mapped = TransactionMapper.toEntities(value);
        final now = _clock.nowUtc();
        final saved = await _guardLocal(() async {
          await _local.saveSummaries(mapped.items);
          if (firstUnfiltered) {
            await _local.markStatementSynced(
              syncedAt: now,
              skippedRecords: mapped.skipped,
            );
            await _local.prune();
          }
        });
        if (saved case Err(:final failure)) return Err(failure);
        if (firstUnfiltered) _fetchedAt[_firstPageKey] = now;
        return Ok(
          TransactionPage(
            items: mapped.items,
            nextCursor: value.nextCursor,
            freshness: DataFreshness(
              syncedAt: now,
              skippedRecords: mapped.skipped,
            ),
          ),
        );
    }
  }

  /// A page read from the device. With a [failure] (the server could not
  /// answer), it is marked stale and as coming from the device.
  Future<TransactionPage> _devicePage(
    TransactionQuery query, {
    Failure? failure,
  }) async {
    final page = await _local.page(query);
    final mark = await _local.readStatementState();
    final dashboard = await _local.readDashboardState();
    final synced = [?mark?.syncedAt, ?dashboard?.syncedAt]..sort();
    return TransactionPage(
      items: page.items,
      nextCursor: page.nextCursor,
      freshness: DataFreshness(
        syncedAt: synced.isEmpty ? _clock.nowUtc() : synced.last,
        syncFailure: failure,
        skippedRecords: mark?.skippedRecords ?? 0,
      ),
      fromDevice: failure != null,
    );
  }

  @override
  Future<Result<int>> countTransactions(
    TransactionFilter filter, {
    CancelSignal? cancel,
  }) async {
    final fetched = await guardRequest(
      () => _remote.fetchTransactions(
        TransactionQuery(filter: filter, limit: 1),
        cancelToken: _tokenFor(cancel),
      ),
    );
    return switch (fetched) {
      Ok(value: TransactionPageDto(:final total?)) => Ok(total),
      Err(:final failure) when !_canFallBack(failure) => Err(failure),
      // No total from the server: count what is saved.
      _ => _guardLocal(() => _local.count(filter)),
    };
  }

  // ---- detail ----

  @override
  Future<Result<Transaction?>> savedTransaction(String id) =>
      _guardLocal(() => _local.byId(id));

  @override
  Future<Result<Transaction>> refreshTransaction(String id) async {
    final fetched = await guardRequest(
      () async =>
          TransactionMapper.toEntity(await _remote.fetchTransaction(id)),
    );
    switch (fetched) {
      case Err(:final failure):
        return Err(failure);
      case Ok(value: final transaction):
        final saved = await _guardLocal(
          () => _local.saveDetail(transaction, openedAt: _clock.nowUtc()),
        );
        if (saved case Err(:final failure)) return Err(failure);
        return Ok(transaction);
    }
  }

  @override
  void expireRecentFetches() => _fetchedAt.clear();

  @override
  Future<void> clear() async {
    _fetchedAt.clear();
    await _local.clear();
  }

  // ---- helpers ----

  bool _recentlyFetched(String key) {
    final at = _fetchedAt[key];
    return at != null && _clock.nowUtc().difference(at) < minInterval;
  }

  /// A cancelled request is not a failure to hide, and a rejected session
  /// must reach the screen instead of old data.
  static bool _canFallBack(Failure failure) =>
      failure is! CancelledFailure && failure is! UnauthorizedFailure;

  /// Bridges the domain's [CancelSignal] to Dio's [CancelToken].
  static CancelToken? _tokenFor(CancelSignal? signal) {
    if (signal == null) return null;
    final token = CancelToken();
    if (signal.isCancelled) {
      token.cancel();
    } else {
      signal.whenCancelled.then((_) => token.cancel());
    }
    return token;
  }

  /// Local database errors become [StorageFailure]; a row or cursor that
  /// does not parse becomes [InvalidDataFailure]. A [Failure] thrown inside
  /// [read] goes through as is.
  static Future<Result<T>> _guardLocal<T>(Future<T> Function() read) async {
    try {
      return Ok(await read());
    } on Failure catch (failure) {
      return Err(failure);
    } on FormatException catch (error) {
      return Err(InvalidDataFailure(error.message));
    } on ArgumentError catch (error) {
      return Err(InvalidDataFailure('${error.name}: ${error.message}'));
    } on Exception catch (error) {
      return Err(StorageFailure(error.runtimeType.toString()));
    }
  }
}
