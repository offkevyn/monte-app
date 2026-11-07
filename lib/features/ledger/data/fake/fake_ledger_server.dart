import 'dart:convert';

import '../../../../core/money/money.dart';
import '../../../../core/network/fake/fake_http_adapter.dart';
import '../../../../core/network/fake/fake_scenario.dart';
import '../../../../core/text/search_text.dart';
import '../../../../core/time/clock.dart';
import '../../domain/entities/transaction.dart';
import '../mappers/transaction_mapper.dart';
import 'fake_ledger_generator.dart';

/// Server side of the simulated bank: `/v1/account`, `/v1/transactions`
/// and `/v1/transactions/:id`. Filters and pages like a real API would,
/// validating its own input and answering 400 to bad parameters.
///
/// The list sends a summary of each transaction (what a row of the
/// statement shows) and the total of matches; the full record comes from
/// the detail endpoint, so each screen downloads only what it uses.
final class FakeLedgerServer {
  FakeLedgerServer({
    required this.settings,
    required this._clock,
    this.authorize,
  }) {
    settings.addDataListener(() => _data = null);
  }

  /// Checks the session token of each request; without it (tests of the
  /// ledger alone) every request is accepted.
  final bool Function(FakeRequest request)? authorize;

  static const maxLimit = 500;

  final FakeBackendSettings settings;
  final Clock _clock;
  FakeLedgerData? _data;

  FakeLedgerData get data => _data ??= FakeLedgerGenerator.generate(
    seed: settings.seed,
    count: settings.volume.transactionCount,
    nowUtc: _clock.nowUtc(),
  );

  /// Dev tool: a Pix lands on the account right now, as if someone sent
  /// it. The app sees it the next time it asks (tab, pull, coming back).
  Transaction receivePix({
    int cents = 5000,
    String from = 'Ana Beatriz Souza',
  }) {
    final now = _clock.nowUtc();
    final pix = Transaction(
      id: 'tx_pix_${now.microsecondsSinceEpoch}',
      description: 'Pix recebido',
      amount: Money.cents(cents),
      type: TransactionType.income,
      status: TransactionStatus.completed,
      occurredAt: now,
      method: PaymentMethod.pix,
      category: TransactionCategory.transfer,
      counterparty: from,
    );
    final current = data;
    _data = FakeLedgerData(
      openingBalance: current.openingBalance,
      transactions: [pix, ...current.transactions],
    );
    return pix;
  }

  List<FakeRoute> get routes => [
    FakeRoute('GET', '/v1/account', _guard(_account)),
    FakeRoute('GET', '/v1/transactions', _guard(_list)),
    FakeRoute('GET', '/v1/transactions/:id', _guard(_byId)),
  ];

  /// Every bank endpoint answers 401 to a request without a valid session.
  FakeHandler _guard(FakeHandler handler) => (request) {
    final check = authorize;
    if (check != null && !check(request)) {
      return FakeResponse.error(401, 'unauthorized');
    }
    return handler(request);
  };

  bool get _isEmpty => settings.scenario == FakeScenario.empty;

  /// The balance is the server's job: opening balance plus every settled
  /// movement. Pending debits are left to the app, which shows them as
  /// reserved.
  FakeResponse _account(FakeRequest request) {
    var balance = _isEmpty ? 0 : data.openingBalance.cents;
    if (!_isEmpty) {
      for (final t in data.transactions) {
        if (t.status == TransactionStatus.completed) {
          balance += t.signedAmount.cents;
        }
      }
    }
    return FakeResponse(200, {
      'balance_cents': balance,
      'currency': 'BRL',
      'as_of': _clock.nowUtc().toIso8601String(),
    });
  }

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
          _maybeCorrupt(_summary(transaction), start + index),
      ],
      'next_cursor': hasMore ? _encodeCursor(page.last) : null,
      'total': matching.length,
    });
  }

  Map<String, Object?> _json(Transaction transaction) =>
      TransactionMapper.fromEntity(transaction).toJson();

  /// What a statement row needs; the rest stays for the detail endpoint.
  Map<String, Object?> _summary(Transaction transaction) =>
      _json(transaction)..removeWhere((key, _) => _detailOnly.contains(key));

  static const _detailOnly = {'card_last4', 'message'};

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
