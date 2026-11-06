import 'package:dio/dio.dart';

import 'retry_interceptor.dart';

/// Builds the Dio used for an API: timeouts, JSON, and retry with backoff.
///
/// The same factory serves the simulated bank backend (with a fake
/// [adapter]) and CoinGecko (real network), so both go through the same
/// error handling.
abstract final class ApiClientFactory {
  /// `.invalid` is a reserved top level domain: if the fake adapter were
  /// ever missing, requests would fail instead of reaching a real host.
  static const fakeBankBaseUrl = 'https://api.monte.invalid';

  static Dio create({
    required String baseUrl,
    HttpClientAdapter? adapter,
    RetryPolicy retryPolicy = const RetryPolicy(),
    Map<String, String> headers = const {},
    List<Interceptor> interceptors = const [],
    Sleep? sleep,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {Headers.acceptHeader: Headers.jsonContentType, ...headers},
      ),
    );
    if (adapter != null) dio.httpClientAdapter = adapter;
    // Extra interceptors run before the retry, so a retried request goes
    // through them again.
    dio.interceptors
      ..addAll(interceptors)
      ..add(RetryInterceptor(dio, policy: retryPolicy, sleep: sleep));
    return dio;
  }
}
