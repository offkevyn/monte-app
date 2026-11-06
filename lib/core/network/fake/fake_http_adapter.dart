import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../retry_interceptor.dart';
import 'fake_scenario.dart';

/// A request as the fake server sees it.
final class FakeRequest {
  const FakeRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.pathParams,
    required this.headers,
    this.body,
  });

  final String method;
  final String path;
  final Map<String, String> query;
  final Map<String, String> pathParams;
  final Map<String, Object?> headers;
  final Object? body;
}

final class FakeResponse {
  const FakeResponse(this.statusCode, this.body, {this.headers = const {}});

  factory FakeResponse.error(int statusCode, String code) =>
      FakeResponse(statusCode, {'error': code});

  final int statusCode;
  final Object? body;
  final Map<String, String> headers;
}

typedef FakeHandler = FakeResponse Function(FakeRequest request);

/// One endpoint: `GET /v1/transactions/:id`.
final class FakeRoute {
  FakeRoute(this.method, String pattern, this.handler)
    : _names = RegExp(':([a-zA-Z]+)')
          .allMatches(pattern)
          .map((m) => m.group(1)!)
          .toList(),
      _regex = RegExp(
        '^${pattern.replaceAllMapped(RegExp(':[a-zA-Z]+'), (_) => '([^/]+)')}\$',
      );

  final String method;
  final FakeHandler handler;
  final List<String> _names;
  final RegExp _regex;

  Map<String, String>? match(String method, String path) {
    if (method != this.method) return null;
    final found = _regex.firstMatch(path);
    if (found == null) return null;
    return {
      for (var i = 0; i < _names.length; i++)
        _names[i]: Uri.decodeComponent(found.group(i + 1)!),
    };
  }
}

/// Simulated backend plugged into Dio as its transport.
///
/// Dio's interceptors (retry, 429, error mapping) run exactly as they would
/// against a real server; only the network itself is replaced. Latency and
/// failures follow [FakeBackendSettings.scenario].
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter({
    required this.settings,
    required List<FakeRoute> routes,
    Random? random,
    Sleep? sleep,
  }) : _routes = List.of(routes),
       _random = random ?? Random(7),
       _sleep = sleep ?? Future<void>.delayed;

  final FakeBackendSettings settings;
  final List<FakeRoute> _routes;
  final Random _random;
  final Sleep _sleep;

  /// 429 answers already given per path in the rate limited scenario.
  final _rateLimitHits = <String, int>{};

  /// Requests that reached the "server", for tests and the dev panel.
  int requestCount = 0;

  void addRoutes(Iterable<FakeRoute> routes) => _routes.addAll(routes);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final scenario = settings.scenario;
    await _sleep(_latency(scenario));

    if (scenario == FakeScenario.offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Simulated offline',
        error: const SocketException('Simulated offline'),
      );
    }

    requestCount++;
    final path = options.uri.path;
    final response = switch (scenario) {
      FakeScenario.serverError => FakeResponse.error(500, 'internal_error'),
      FakeScenario.rateLimited when _shouldRateLimit(path) =>
        const FakeResponse(
          429,
          {'error': 'rate_limited'},
          headers: {HttpHeaders.retryAfterHeader: '1'},
        ),
      _ => _route(options, path),
    };
    return _toBody(response);
  }

  bool _shouldRateLimit(String path) {
    final hits = _rateLimitHits[path] ?? 0;
    if (hits >= 2) {
      _rateLimitHits.remove(path);
      return false;
    }
    _rateLimitHits[path] = hits + 1;
    return true;
  }

  FakeResponse _route(RequestOptions options, String path) {
    final method = options.method.toUpperCase();
    for (final route in _routes) {
      final params = route.match(method, path);
      if (params == null) continue;
      return route.handler(
        FakeRequest(
          method: method,
          path: path,
          query: options.uri.queryParameters,
          pathParams: params,
          headers: options.headers,
          body: options.data,
        ),
      );
    }
    return FakeResponse.error(404, 'route_not_found');
  }

  Duration _latency(FakeScenario scenario) => scenario == FakeScenario.slow
      ? Duration(milliseconds: 2800 + _random.nextInt(400))
      : Duration(milliseconds: 150 + _random.nextInt(350));

  ResponseBody _toBody(FakeResponse response) => ResponseBody.fromString(
    jsonEncode(response.body),
    response.statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      for (final entry in response.headers.entries) entry.key: [entry.value],
    },
  );

  @override
  void close({bool force = false}) {}
}
