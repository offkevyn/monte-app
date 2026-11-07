import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/money/money.dart';
import '../../../../core/text/search_text.dart';
import '../../../../core/time/local_calendar.dart';
import '../../../../core/time/local_date.dart';
import '../../domain/entities/date_span.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_page.dart';
import '../dtos/transaction_dto.dart';
import '../mappers/transaction_mapper.dart';
import 'ledger_database.dart';

/// What the last dashboard refresh saved.
final class SavedDashboardState {
  const SavedDashboardState({
    required this.balance,
    required this.period,
    required this.pendingIds,
    required this.syncedAt,
    required this.skippedRecords,
  });

  final Money balance;
  final DateSpan period;
  final List<String> pendingIds;
  final DateTime syncedAt;
  final int skippedRecords;
}

/// When something was last fetched, and how many records were unreadable.
final class SavedSyncMark {
  const SavedSyncMark({required this.syncedAt, required this.skippedRecords});

  final DateTime syncedAt;
  final int skippedRecords;
}

/// Reads and writes the encrypted local database. Everything the server
/// sends is written here first and the screens read from here: the single
/// source of truth the requirements ask for.
///
/// It is a cache, not a full copy: [prune] keeps the newest transactions,
/// the dashboard period, the pending debits and the details opened lately.
final class LedgerLocalDataSource {
  LedgerLocalDataSource(this._db, this._calendar);

  final LedgerDatabase _db;
  final LocalCalendar _calendar;

  static const _singleRowId = 1;

  /// Newest transactions kept for the statement offline.
  static const keepNewest = 200;

  /// Details opened lately, kept with their full data.
  static const keepOpened = 50;

  /// Saves list items. A row that already has its details keeps them: the
  /// list only refreshes the summary (a pending debit may have settled).
  Future<void> saveSummaries(Iterable<Transaction> transactions) =>
      _db.batch((batch) {
        for (final transaction in transactions) {
          batch.insert(
            _db.transactions,
            _toRow(transaction),
            onConflict: DoUpdate((_) => _summaryOnly(transaction)),
          );
        }
      });

  /// Saves a transaction that came from the detail endpoint.
  Future<void> saveDetail(
    Transaction transaction, {
    required DateTime openedAt,
  }) => _db
      .into(_db.transactions)
      .insertOnConflictUpdate(
        _toRow(transaction).copyWith(
          detailed: const Value(true),
          openedAtMicros: Value(openedAt.toUtc().microsecondsSinceEpoch),
        ),
      );

  /// Saves a dashboard refresh in one database transaction: readers see the
  /// old dashboard or the new one, never half of each.
  Future<void> saveDashboard({
    required Money balance,
    required DateSpan period,
    required List<Transaction> pendingDebits,
    required List<Transaction> transactions,
    required DateTime syncedAt,
    required int skippedRecords,
  }) => _db.transaction(() async {
    await saveSummaries([...pendingDebits, ...transactions]);
    await _db
        .into(_db.dashboardState)
        .insertOnConflictUpdate(
          DashboardStateCompanion.insert(
            id: const Value(_singleRowId),
            balanceCents: balance.cents,
            periodFirst: period.first.toString(),
            periodLast: period.last.toString(),
            pendingIds: jsonEncode([for (final t in pendingDebits) t.id]),
            syncedAtMicros: syncedAt.toUtc().microsecondsSinceEpoch,
            skippedRecords: Value(skippedRecords),
          ),
        );
  });

  Future<SavedDashboardState?> readDashboardState() async {
    final row = await (_db.select(
      _db.dashboardState,
    )..where((s) => s.id.equals(_singleRowId))).getSingleOrNull();
    if (row == null) return null;
    return SavedDashboardState(
      balance: Money.cents(row.balanceCents),
      period: DateSpan(_date(row.periodFirst), _date(row.periodLast)),
      pendingIds: [for (final id in jsonDecode(row.pendingIds) as List) '$id'],
      syncedAt: _instant(row.syncedAtMicros),
      skippedRecords: row.skippedRecords,
    );
  }

  Future<void> markStatementSynced({
    required DateTime syncedAt,
    required int skippedRecords,
  }) => _db
      .into(_db.statementState)
      .insertOnConflictUpdate(
        StatementStateCompanion.insert(
          id: const Value(_singleRowId),
          syncedAtMicros: syncedAt.toUtc().microsecondsSinceEpoch,
          skippedRecords: Value(skippedRecords),
        ),
      );

  Future<SavedSyncMark?> readStatementState() async {
    final row = await (_db.select(
      _db.statementState,
    )..where((s) => s.id.equals(_singleRowId))).getSingleOrNull();
    return row == null
        ? null
        : SavedSyncMark(
            syncedAt: _instant(row.syncedAtMicros),
            skippedRecords: row.skippedRecords,
          );
  }

  /// Every saved transaction that happened within [span], newest first.
  Future<List<Transaction>> inPeriod(DateSpan span) async {
    final range = _calendar.rangeOf(span.first, span.last);
    final rows =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    t.occurredAtMicros.isBiggerOrEqualValue(
                      range.start.microsecondsSinceEpoch,
                    ) &
                    t.occurredAtMicros.isSmallerThanValue(
                      range.end.microsecondsSinceEpoch,
                    ),
              )
              ..orderBy(_pagingOrder))
            .get();
    return rows.map(_toEntity).toList();
  }

  /// The saved transactions among [ids], newest first.
  Future<List<Transaction>> byIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows =
        await (_db.select(_db.transactions)
              ..where((t) => t.id.isIn(ids))
              ..orderBy(_pagingOrder))
            .get();
    return rows.map(_toEntity).toList();
  }

  Future<bool> isEmpty() async {
    final count = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)..addColumns([count]);
    return ((await query.getSingle()).read(count) ?? 0) == 0;
  }

  /// Same conditions as [page], counted in SQL.
  Future<int> count(TransactionFilter filter) async {
    final count = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([count])
      ..where(_conditions(_db.transactions, filter, null));
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<Transaction?> byId(String id) async {
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  /// One page of what is saved, with the filter applied in SQL. Keyset
  /// pagination: the cursor is the last item shown, and the next page
  /// starts strictly after it. The cursor has the same format as the
  /// server's, so a list can go on from the device when the network drops.
  ///
  /// Throws a [FormatException] for a cursor this app did not create.
  Future<({List<Transaction> items, String? nextCursor})> page(
    TransactionQuery query,
  ) async {
    final after = query.cursor == null ? null : _decodeCursor(query.cursor!);
    final select = _db.select(_db.transactions)
      ..where((t) => _conditions(t, query.filter, after))
      ..orderBy(_pagingOrder)
      // One extra row tells whether there is a next page.
      ..limit(query.limit + 1);

    final rows = await select.get();
    final hasMore = rows.length > query.limit;
    final items = rows.take(query.limit).map(_toEntity).toList();
    return (
      items: items,
      nextCursor: hasMore ? encodeCursor(items.last) : null,
    );
  }

  /// Drops what no screen needs anymore, so the cache does not grow with
  /// use: keeps the [keepNewest] newest, the dashboard period, the pending
  /// debits and the [keepOpened] details opened lately.
  Future<void> prune() => _db.transaction(() async {
    final state = await readDashboardState();
    final keep = <String>{
      ...?state?.pendingIds,
      ...await _ids(
        _db.select(_db.transactions)
          ..orderBy(_pagingOrder)
          ..limit(keepNewest),
      ),
      ...await _ids(
        _db.select(_db.transactions)
          ..where((t) => t.openedAtMicros.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.openedAtMicros)])
          ..limit(keepOpened),
      ),
    };
    final period = state == null
        ? null
        : _calendar.rangeOf(state.period.first, state.period.last);
    await (_db.delete(_db.transactions)..where((t) {
          final notKept = t.id.isNotIn(keep);
          if (period == null) return notKept;
          return notKept &
              (t.occurredAtMicros.isSmallerThanValue(
                    period.start.microsecondsSinceEpoch,
                  ) |
                  t.occurredAtMicros.isBiggerOrEqualValue(
                    period.end.microsecondsSinceEpoch,
                  ));
        }))
        .go();
  });

  /// Deletes everything (sign out).
  Future<void> clear() => _db.transaction(() async {
    for (final table in _db.allTables) {
      await _db.delete(table).go();
    }
  });

  Future<List<String>> _ids(
    SimpleSelectStatement<$TransactionsTable, TransactionRow> select,
  ) async => [for (final row in await select.get()) row.id];

  Expression<bool> _conditions(
    $TransactionsTable t,
    TransactionFilter filter,
    ({int micros, String id})? after,
  ) {
    final conditions = <Expression<bool>>[
      if (filter.types.isNotEmpty)
        t.direction.isIn(filter.types.map(_directionOf)),
      if (filter.statuses.isNotEmpty)
        t.status.isIn(filter.statuses.map((s) => s.name)),
    ];

    final period = filter.period;
    if (period != null) {
      final range = _calendar.rangeOf(period.first, period.last);
      conditions
        ..add(
          t.occurredAtMicros.isBiggerOrEqualValue(
            range.start.microsecondsSinceEpoch,
          ),
        )
        ..add(
          t.occurredAtMicros.isSmallerThanValue(
            range.end.microsecondsSinceEpoch,
          ),
        );
    }

    for (final word in SearchText.normalize(filter.query).split(' ')) {
      if (word.isEmpty) continue;
      conditions.add(
        t.searchText.like('%${_escapeLike(word)}%', escapeChar: r'\'),
      );
    }

    if (after != null) {
      conditions.add(
        t.occurredAtMicros.isSmallerThanValue(after.micros) |
            (t.occurredAtMicros.equals(after.micros) &
                t.id.isBiggerThanValue(after.id)),
      );
    }

    return conditions.isEmpty
        ? const Constant(true)
        : conditions.reduce((a, b) => a & b);
  }

  static List<OrderClauseGenerator<$TransactionsTable>> get _pagingOrder => [
    (t) => OrderingTerm.desc(t.occurredAtMicros),
    (t) => OrderingTerm.asc(t.id),
  ];

  /// `%` and `_` typed by the user are literal characters, not wildcards.
  static String _escapeLike(String word) =>
      word.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m.group(0)}');

  static String _directionOf(TransactionType type) => switch (type) {
    TransactionType.income => 'credit',
    TransactionType.expense => 'debit',
  };

  static LocalDate _date(String iso) {
    final parts = iso.split('-').map(int.parse).toList();
    return LocalDate(parts[0], parts[1], parts[2]);
  }

  static DateTime _instant(int micros) =>
      DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);

  static TransactionsCompanion _toRow(Transaction transaction) {
    final dto = TransactionMapper.fromEntity(transaction);
    return TransactionsCompanion.insert(
      id: dto.id,
      description: dto.description,
      amountCents: dto.amountCents,
      direction: dto.direction,
      status: dto.status,
      occurredAtMicros: dto.occurredAt.microsecondsSinceEpoch,
      paymentMethod: dto.paymentMethod,
      category: dto.category ?? 'other',
      counterparty: Value(dto.counterparty),
      searchText: SearchText.normalize(
        '${transaction.description} ${transaction.counterparty ?? ''}',
      ),
      cardLast4: Value(dto.cardLast4),
      message: Value(dto.message),
      detailed: Value(transaction.detailed),
    );
  }

  /// The columns a list item may update on a row that is already saved.
  static TransactionsCompanion _summaryOnly(Transaction transaction) {
    final row = _toRow(transaction);
    return TransactionsCompanion(
      description: row.description,
      amountCents: row.amountCents,
      direction: row.direction,
      status: row.status,
      occurredAtMicros: row.occurredAtMicros,
      paymentMethod: row.paymentMethod,
      category: row.category,
      counterparty: row.counterparty,
      searchText: row.searchText,
    );
  }

  /// Rows were validated when they came in, but they go through the same
  /// mapper again: a row written by an older app version is checked too.
  static Transaction _toEntity(TransactionRow row) =>
      TransactionMapper.toEntity(
        TransactionDto(
          id: row.id,
          description: row.description,
          amountCents: row.amountCents,
          direction: row.direction,
          status: row.status,
          occurredAt: _instant(row.occurredAtMicros),
          paymentMethod: row.paymentMethod,
          category: row.category,
          cardLast4: row.cardLast4,
          counterparty: row.counterparty,
          message: row.message,
        ),
        detailed: row.detailed,
      );

  /// Same format the server uses: `<occurred at micros>|<id>`, base64.
  static String encodeCursor(Transaction last) => base64Url.encode(
    utf8.encode('${last.occurredAt.microsecondsSinceEpoch}|${last.id}'),
  );

  static ({int micros, String id}) _decodeCursor(String cursor) {
    final parts = utf8.decode(base64Url.decode(cursor)).split('|');
    final micros = parts.length == 2 ? int.tryParse(parts[0]) : null;
    if (micros == null || parts[1].isEmpty) {
      throw FormatException('Invalid cursor', cursor);
    }
    return (micros: micros, id: parts[1]);
  }
}
