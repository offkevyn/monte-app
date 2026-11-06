import '../../../../core/failures/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/network_failures.dart';
import '../../../../core/result/result.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/ledger_snapshot.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_page.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../datasources/ledger_remote_datasource.dart';
import '../local/ledger_local_datasource.dart';
import '../mappers/transaction_mapper.dart';

/// Offline-first ledger: every read comes from the encrypted local database,
/// and the server only refreshes that copy.
///
/// - Fresh enough (synced less than [freshFor] ago): answer from the
///   database without touching the network.
/// - Older, or pull to refresh: sync first. If the sync fails and there is a
///   local copy, answer with it marked as stale (offline banner). With no
///   local copy at all, the failure goes to the screen.
/// - After a failed sync, automatic retries wait [retryCooldown], so paging
///   through the statement offline does not hit the network on every page.
final class LedgerRepositoryImpl implements LedgerRepository {
  LedgerRepositoryImpl({
    required this._remote,
    required this._local,
    required this._clock,
    this.freshFor = const Duration(minutes: 5),
    this.retryCooldown = const Duration(seconds: 30),
  });

  final LedgerRemoteDataSource _remote;
  final LedgerLocalDataSource _local;
  final Clock _clock;
  final Duration freshFor;
  final Duration retryCooldown;

  Future<Result<void>>? _syncInFlight;
  Failure? _lastSyncFailure;
  DateTime? _lastSyncFailedAt;

  @override
  Future<Result<LedgerSnapshot>> loadSnapshot({
    bool forceRefresh = false,
  }) async {
    final ready = await _ensureLocalData(forceRefresh: forceRefresh);
    if (ready case Err(:final failure)) return Err(failure);
    return _readLocal(() async {
      final state = (await _local.readSyncState())!;
      return LedgerSnapshot(
        openingBalance: state.openingBalance,
        transactions: await _local.all(),
        freshness: _freshness(state),
      );
    });
  }

  @override
  Future<Result<TransactionPage>> getTransactions(
    TransactionQuery query,
  ) async {
    final ready = await _ensureLocalData();
    if (ready case Err(:final failure)) return Err(failure);
    return _readLocal(() async {
      final page = await _local.page(query);
      final state = (await _local.readSyncState())!;
      return TransactionPage(
        items: page.items,
        nextCursor: page.nextCursor,
        freshness: _freshness(state),
      );
    });
  }

  @override
  Future<Result<Transaction>> getTransaction(String id) async {
    final ready = await _ensureLocalData();
    if (ready case Err(:final failure)) return Err(failure);
    final found = await _readLocal(() => _local.byId(id));
    return switch (found) {
      Ok(value: final transaction?) => Ok(transaction),
      Ok() => const Err(NotFoundFailure()),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<void> clear() async {
    _lastSyncFailure = null;
    _lastSyncFailedAt = null;
    await _local.clear();
  }

  /// Makes sure there is local data to answer from, syncing when needed.
  Future<Result<void>> _ensureLocalData({bool forceRefresh = false}) async {
    final stateResult = await _readLocal(_local.readSyncState);
    if (stateResult case Err(:final failure)) return Err(failure);
    final state = stateResult.valueOrNull;
    final now = _clock.nowUtc();

    if (!forceRefresh && state != null) {
      final fresh = now.difference(state.syncedAt) < freshFor;
      final failedAt = _lastSyncFailedAt;
      final coolingDown =
          failedAt != null && now.difference(failedAt) < retryCooldown;
      if (fresh || coolingDown) return const Ok(null);
    }

    final synced = await _sync();
    if (synced case Err(:final failure)) {
      final mustReport =
          state == null ||
          failure is CancelledFailure ||
          failure is UnauthorizedFailure;
      return mustReport ? Err(failure) : const Ok(null);
    }
    return const Ok(null);
  }

  /// Concurrent callers share the same sync.
  Future<Result<void>> _sync() =>
      _syncInFlight ??= _runSync().whenComplete(() => _syncInFlight = null);

  Future<Result<void>> _runSync() async {
    final fetched = await guardRequest(_fetchEverything);
    switch (fetched) {
      case Err(:final failure):
        _lastSyncFailure = failure;
        _lastSyncFailedAt = _clock.nowUtc();
        return Err(failure);
      case Ok(:final value):
        final saved = await _readLocal(
          () => _local.replaceAll(
            openingBalance: value.opening,
            transactions: value.items,
            syncedAt: _clock.nowUtc(),
            skippedRecords: value.skipped,
          ),
        );
        if (saved case Err(:final failure)) return Err(failure);
        _lastSyncFailure = null;
        _lastSyncFailedAt = null;
        return const Ok(null);
    }
  }

  /// Account plus every page. Nothing is written until all pages arrived, so
  /// a sync that fails halfway leaves the previous copy intact.
  Future<({Money opening, List<Transaction> items, int skipped})>
  _fetchEverything() async {
    final account = await _remote.fetchAccount();
    final opening = TransactionMapper.openingBalance(account);
    final items = <Transaction>[];
    final seenCursors = <String>{};
    var skipped = 0;
    String? cursor;
    do {
      final page = await _remote.fetchSyncPage(cursor: cursor);
      final mapped = TransactionMapper.toEntities(page);
      items.addAll(mapped.items);
      skipped += mapped.skipped;
      cursor = page.nextCursor;
      // A server that keeps answering the same cursor would loop forever.
      if (cursor != null && !seenCursors.add(cursor)) {
        throw const FormatException('Server repeated a pagination cursor');
      }
    } while (cursor != null);
    return (opening: opening, items: items, skipped: skipped);
  }

  DataFreshness _freshness(LocalSyncState state) => DataFreshness(
    syncedAt: state.syncedAt,
    syncFailure: _lastSyncFailure,
    skippedRecords: state.skippedRecords,
  );

  /// Local database errors become [StorageFailure]; a row or cursor that
  /// does not parse becomes [InvalidDataFailure].
  Future<Result<T>> _readLocal<T>(Future<T> Function() read) async {
    try {
      return Ok(await read());
    } on FormatException catch (error) {
      return Err(InvalidDataFailure(error.message));
    } on ArgumentError catch (error) {
      return Err(InvalidDataFailure('${error.name}: ${error.message}'));
    } on Exception catch (error) {
      return Err(StorageFailure(error.runtimeType.toString()));
    }
  }
}
