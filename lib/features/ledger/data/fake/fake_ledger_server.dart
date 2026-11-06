import 'dart:convert';

import '../../../../core/network/fake/fake_http_adapter.dart';
import '../../../../core/network/fake/fake_scenario.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/services/search_text.dart';
import '../mappers/transaction_mapper.dart';
import 'fake_ledger_generator.dart';

/// Server side of the simulated bank: `/v1/account` and
/// `/v1/transactions`. Filters and pages like a real API would, validating
/// its own input and answering 400 to bad parameters.
final class FakeLedgerServer {
  FakeLedgerServer({required this.settings, required this._clock}) {
    settings.addDataListener(() => _data = null);
  }

  static const maxLimit = 500;

  final FakeBackendSettings settings;
  final Clock _clock;
  FakeLedgerData? _data;

  FakeLedgerData get data => _data ??= FakeLedgerGenerator.generate(
    seed: settings.seed,
    count: settings.volume.transactionCount,
    nowUtc: _clock.nowUtc(),
  );

  List<FakeRoute> get routes => [
    FakeRoute('GET', '/v1/account', _account),
    FakeRoute('GET', '/v1/transactions', _list),
    FakeRoute('GET', '/v1/transactions/:id', _byId),
  ];

  bool get _isEmpty => settings.scenario == FakeScenario.empty;

  FakeResponse _account(FakeRequest request) => FakeResponse(200, {
    'opening_balance_cents': _isEmpty ? 0 : data.openingBalance.cents,
    'currency': 'BRL',
  });

  FakeResponse _byId(FakeRequest request) {
    final id = request.pathParams['id'];
    if (_isEmpty) return FakeResponse.error(404, 'not_found');
    for (final transaction in data.transactions) {
      if (transaction.id == id) return FakeResponse(200, _json(transaction));
    }
    return FakeResponse.error(404, 'not_found');
  }

  FakeResponse _list(FakeRequest request) {
    final query = request.query;
    final limit = int.tryParse(query['limit'] ?? '20');
    if (limit == null || limit < 1 || limit > maxLimit) {
      return FakeResponse.error(400, 'invalid_limit');
    }

    final from = _instant(query['from']);
    final to = _instant(query['to']);
    if ((query.containsKey('from') && from == null) ||
        (query.containsKey('to') && to == null)) {
      return FakeResponse.error(400, 'invalid_period');
    }

    final types = _set(query['type']);
    final statuses = _set(query['status']);
    final search = query['q'] ?? '';

    final matching = _isEmpty
        ? const <Transaction>[]
        : data.transactions.where((t) {
            final direction = t.isIncome ? 'credit' : 'debit';
            if (types.isNotEmpty && !types.contains(direction)) return false;
            if (statuses.isNotEmpty && !statuses.contains(t.status.name)) {
              return false;
            }
            if (from != null && t.occurredAt.isBefore(from)) return false;
            if (to != null && !t.occurredAt.isBefore(to)) return false;
            if (search.isNotEmpty &&
                !SearchText.matches(
                  '${t.description} ${t.counterparty ?? ''}',
                  search,
                )) {
              return false;
            }
            return true;
          }).toList();

    var start = 0;
    final cursor = query['cursor'];
    if (cursor != null) {
      final position = _decodeCursor(cursor);
      if (position == null) return FakeResponse.error(400, 'invalid_cursor');
      // First item that comes after the cursor in paging order.
      start = matching.indexWhere(
        (t) =>
            t.occurredAt.isBefore(position.at) ||
            (t.occurredAt == position.at && t.id.compareTo(position.id) > 0),
      );
      if (start == -1) start = matching.length;
    }

    final page = matching.skip(start).take(limit).toList();
    final hasMore = start + page.length < matching.length;
    return FakeResponse(200, {
      'data': [
        for (final (index, transaction) in page.indexed)
          _maybeCorrupt(_json(transaction), start + index),
      ],
      'next_cursor': hasMore ? _encodeCursor(page.last) : null,
    });
  }

  Map<String, Object?> _json(Transaction transaction) =>
      TransactionMapper.fromEntity(transaction).toJson();

  /// In the corrupted data scenario every 7th record arrives broken, in one
  /// of the ways real APIs break.
  Map<String, Object?> _maybeCorrupt(Map<String, Object?> json, int index) {
    if (settings.scenario != FakeScenario.corruptedData || index % 7 != 3) {
      return json;
    }
    return switch ((index ~/ 7) % 4) {
      0 => {...json}..remove('amount_cents'),
      1 => {...json, 'amount_cents': '129,90'},
      2 => {...json, 'status': 'processing'},
      _ => {...json, 'occurred_at': '2026-11-05 14:32:00'},
    };
  }

  static String _encodeCursor(Transaction last) => base64Url.encode(
    utf8.encode('${last.occurredAt.microsecondsSinceEpoch}|${last.id}'),
  );

  static ({DateTime at, String id})? _decodeCursor(String cursor) {
    try {
      final parts = utf8.decode(base64Url.decode(cursor)).split('|');
      if (parts.length != 2) return null;
      final micros = int.tryParse(parts[0]);
      if (micros == null || parts[1].isEmpty) return null;
      return (
        at: DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true),
        id: parts[1],
      );
    } on FormatException {
      return null;
    }
  }

  static DateTime? _instant(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw)?.toUtc();

  static Set<String> _set(String? raw) => raw == null || raw.isEmpty
      ? const {}
      : raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
}
