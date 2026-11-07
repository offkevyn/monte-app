import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Stands in for CoinGecko during the integration test, so the run does not
/// depend on the network, on the per minute limit or on an API key.
///
/// Only the transport is replaced: the real data source, mapper, repository
/// and encrypted database still do their work on the answers below.
class FakeCoinGeckoAdapter implements HttpClientAdapter {
  /// When true every call answers 500, like CoinGecko having a bad minute.
  bool failing = false;

  final paths = <String>[];

  static const coins = [
    ('bitcoin', 'btc', 'Bitcoin', 612345.67),
    ('ethereum', 'eth', 'Ethereum', 21456.78),
    ('tether', 'usdt', 'Tether', 5.42),
    ('solana', 'sol', 'Solana', 987.65),
    ('ripple', 'xrp', 'XRP', 12.34),
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    if (failing) return _json({'error': 'simulated'}, 500);
    final query = options.queryParameters;
    return switch (options.path) {
      '/coins/markets' => _json(_markets(query['ids'] as String?)),
      '/search/trending' => _json({
        'coins': [
          for (final coin in coins.reversed)
            {
              'item': {'id': coin.$1},
            },
        ],
      }),
      '/search' => _json({
        'coins': [
          for (final coin in coins)
            if (coin.$3.toLowerCase().contains(
              (query['query'] as String).toLowerCase(),
            ))
              {'id': coin.$1},
        ],
      }),
      final path when path.endsWith('/market_chart') => _json({
        'prices': [
          for (var hour = 0; hour < 24; hour++)
            [
              DateTime.utc(2026, 11, 6, hour).millisecondsSinceEpoch,
              600000 + hour * 500,
            ],
        ],
      }),
      _ => _json({'error': 'not found'}, 404),
    };
  }

  List<Map<String, Object?>> _markets(String? ids) {
    final wanted = ids?.split(',').toSet();
    return [
      for (final (index, coin) in coins.indexed)
        if (wanted == null || wanted.contains(coin.$1))
          {
            'id': coin.$1,
            'symbol': coin.$2,
            'name': coin.$3,
            // No image: the logo falls back to the initials, offline.
            'image': null,
            'current_price': coin.$4,
            'market_cap': coin.$4 * 1000000,
            'market_cap_rank': index + 1,
            'total_volume': coin.$4 * 10000,
            'high_24h': coin.$4 * 1.02,
            'low_24h': coin.$4 * 0.98,
            'price_change_24h': coin.$4 * 0.015,
            'price_change_percentage_24h': index.isEven ? 1.5 : -2.25,
            'last_updated': '2026-11-06T17:31:00.000Z',
          },
    ];
  }

  ResponseBody _json(Object body, [int status = 200]) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
