import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import 'network_failures.dart';

/// When and how long to wait before trying a request again.
final class RetryPolicy {
  const RetryPolicy({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 400),
    this.maxDelay = const Duration(seconds: 8),
    this.maxRetryAfter = const Duration(seconds: 10),
    this.jitter = 0.3,
  });

  /// Retries after the first attempt (so up to 4 requests in total).
  final int maxRetries;

  /// Wait before the first retry; doubles on each following one.
  final Duration baseDelay;
  final Duration maxDelay;

  /// If the server asks to wait longer than this (429 `Retry-After`), the
  /// app stops retrying and tells the user instead of freezing the screen.
  final Duration maxRetryAfter;

  /// Random spread (0.3 = up to 30% more), so many phones that failed at the
  /// same moment do not all retry at the same instant.
  final double jitter;

  /// Exponential backoff: base, 2x base, 4x base... capped at [maxDelay].
  Duration backoff(int retry, Random random) {
    final exponential = baseDelay * pow(2, retry).toInt();
    final capped = exponential > maxDelay ? maxDelay : exponential;
    return capped * (1 + random.nextDouble() * jitter);
  }
}

typedef Sleep = Future<void> Function(Duration duration);

/// Retries idempotent requests (GET) that failed for a temporary reason:
/// no connection, timeout, 5xx, or 429. Each retry goes through the whole
/// Dio pipeline again, so it behaves the same against the real API and the
/// simulated backend.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.policy = const RetryPolicy(),
    Random? random,
    Sleep? sleep,
  }) : _random = random ?? Random(),
       _sleep = sleep ?? Future<void>.delayed;

  static const attemptKey = 'retry_attempt';

  final Dio _dio;
  final RetryPolicy policy;
  final Random _random;
  final Sleep _sleep;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[attemptKey] as int?) ?? 0;
    final wait = _waitBeforeRetry(err, attempt);
    if (wait == null) return handler.next(err);

    await _sleep(wait);
    if (options.cancelToken?.isCancelled ?? false) return handler.next(err);

    options.extra[attemptKey] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<Object?>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// `null` means: do not retry, pass the error on.
  Duration? _waitBeforeRetry(DioException err, int attempt) {
    if (attempt >= policy.maxRetries) return null;
    if (err.requestOptions.method.toUpperCase() != 'GET') return null;

    final status = err.response?.statusCode;
    if (status == HttpStatus.tooManyRequests) {
      final retryAfter = parseRetryAfter(
        err.response?.headers.value(HttpHeaders.retryAfterHeader),
      );
      if (retryAfter == null) return policy.backoff(attempt, _random);
      return retryAfter <= policy.maxRetryAfter ? retryAfter : null;
    }

    final temporary = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse => status != null && status >= 500,
      _ => false,
    };
    return temporary ? policy.backoff(attempt, _random) : null;
  }
}
