import 'package:dio/dio.dart';

import '../../../../core/network/request_deduplicator.dart';
import '../../../../core/time/local_calendar.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_page.dart';
import '../dtos/transaction_dto.dart';

/// Talks to the bank API. Throws on failure (Dio errors, parsing errors);
/// the repository wraps calls with `guardRequest` to turn them into
/// `Result`.
abstract interface class LedgerRemoteDataSource {
  Future<AccountDto> fetchAccount({CancelToken? cancelToken});

  Future<TransactionPageDto> fetchTransactions(
    TransactionQuery query, {
    CancelToken? cancelToken,
  });

  Future<TransactionDto> fetchTransaction(
    String id, {
    CancelToken? cancelToken,
  });
}

final class DioLedgerRemoteDataSource implements LedgerRemoteDataSource {
  DioLedgerRemoteDataSource(
    this._dio,
    this._calendar, {
    RequestDeduplicator? deduplicator,
  }) : _dedup = deduplicator ?? RequestDeduplicator();

  final Dio _dio;
  final LocalCalendar _calendar;
  final RequestDeduplicator _dedup;

  @override
  Future<AccountDto> fetchAccount({CancelToken? cancelToken}) async =>
      AccountDto.fromJson(await _get('/v1/account', cancelToken: cancelToken));

  @override
  Future<TransactionPageDto> fetchTransactions(
    TransactionQuery query, {
    CancelToken? cancelToken,
  }) async => TransactionPageDto.fromJson(
    await _get(
      '/v1/transactions',
      query: encodeQuery(query, _calendar),
      cancelToken: cancelToken,
    ),
  );

  @override
  Future<TransactionDto> fetchTransaction(
    String id, {
    CancelToken? cancelToken,
  }) async => TransactionDto.fromJson(
    await _get(
      '/v1/transactions/${Uri.encodeComponent(id)}',
      cancelToken: cancelToken,
    ),
  );

  Future<Object?> _get(
    String path, {
    Map<String, String> query = const {},
    CancelToken? cancelToken,
  }) {
    final key = Uri(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
    return _dedup.run(
      key,
      (token) async => (await _dio.get<Object?>(
        path,
        queryParameters: query,
        cancelToken: token,
      )).data,
      cancelToken: cancelToken,
    );
  }

  /// Statement filters as query parameters. The period goes as UTC instants
  /// computed from the user's calendar (`from` included, `to` excluded), so
  /// the server never has to guess the user's time zone.
  static Map<String, String> encodeQuery(
    TransactionQuery query,
    LocalCalendar calendar,
  ) {
    final filter = query.filter;
    final period = filter.period;
    final range = period == null
        ? null
        : calendar.rangeOf(period.first, period.last);
    return {
      'limit': '${query.limit}',
      'cursor': ?query.cursor,
      if (filter.types.isNotEmpty)
        'type': (filter.types.map(_typeName).toList()..sort()).join(','),
      if (filter.statuses.isNotEmpty)
        'status': (filter.statuses.map((s) => s.name).toList()..sort()).join(
          ',',
        ),
      if (range != null) ...{
        'from': range.start.toIso8601String(),
        'to': range.end.toIso8601String(),
      },
      if (filter.query.isNotEmpty) 'q': filter.query,
    };
  }

  static String _typeName(TransactionType type) => switch (type) {
    TransactionType.income => 'credit',
    TransactionType.expense => 'debit',
  };
}
