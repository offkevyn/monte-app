import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/money/money.dart';
import '../../../../core/time/local_calendar.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_page.dart';
import '../../domain/services/search_text.dart';
import '../dtos/transaction_dto.dart';
import '../mappers/transaction_mapper.dart';
import 'ledger_database.dart';

/// What the last successful sync stored.
final class LocalSyncState {
  const LocalSyncState({
    required this.openingBalance,
    required this.syncedAt,
    required this.skippedRecords,
  });

  final Money openingBalance;
  final DateTime syncedAt;
  final int skippedRecords;
}

/// Reads and writes the encrypted local database. The statement, the
/// dashboard and the detail screen all read from here: the single source
/// of truth the requirements ask for.
final class LedgerLocalDataSource {
  LedgerLocalDataSource(this._db, this._calendar);

  final LedgerDatabase _db;
  final LocalCalendar _calendar;

  static const _syncRowId = 1;

  Future<LocalSyncState?> readSyncState() async {
    final row = await (_db.select(
      _db.syncState,
    )..where((s) => s.id.equals(_syncRowId))).getSingleOrNull();
    if (row == null) return null;
    return LocalSyncState(
      openingBalance: Money.cents(row.openingBalanceCents),
      syncedAt: DateTime.fromMicrosecondsSinceEpoch(
        row.syncedAtMicros,
        isUtc: true,
      ),
      skippedRecords: row.skippedRecords,
    );
  }

  /// Swaps the whole local copy in one database transaction: readers see
  /// either the old data or the new data, never half of each.
  Future<void> replaceAll({
    required Money openingBalance,
    required List<Transaction> transactions,
    required DateTime syncedAt,
    required int skippedRecords,
  }) => _db.transaction(() async {
    await _db.delete(_db.transactions).go();
    await _db.batch(
      (batch) => batch.insertAll(_db.transactions, transactions.map(_toRow)),
    );
    await _db
        .into(_db.syncState)
        .insertOnConflictUpdate(
          SyncStateCompanion.insert(
            id: const Value(_syncRowId),
            openingBalanceCents: openingBalance.cents,
            syncedAtMicros: syncedAt.toUtc().microsecondsSinceEpoch,
            skippedRecords: Value(skippedRecords),
          ),
        );
  });

  /// Every transaction, newest first.
  Future<List<Transaction>> all() async {
    final rows = await (_db.select(
      _db.transactions,
    )..orderBy(_pagingOrder)).get();
    return rows.map(_toEntity).toList();
  }

  Future<Transaction?> byId(String id) async {
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  /// One page with the filter applied in SQL. Keyset pagination: the cursor
  /// is the last item shown, and the next page starts strictly after it.
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
      nextCursor: hasMore ? _encodeCursor(items.last) : null,
    );
  }

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
      cardLast4: Value(dto.cardLast4),
      counterparty: Value(dto.counterparty),
      message: Value(dto.message),
      searchText: SearchText.normalize(
        '${transaction.description} ${transaction.counterparty ?? ''}',
      ),
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
          occurredAt: DateTime.fromMicrosecondsSinceEpoch(
            row.occurredAtMicros,
            isUtc: true,
          ),
          paymentMethod: row.paymentMethod,
          category: row.category,
          cardLast4: row.cardLast4,
          counterparty: row.counterparty,
          message: row.message,
        ),
      );

  static String _encodeCursor(Transaction last) => base64Url.encode(
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
