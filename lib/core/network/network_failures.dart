import 'dart:io';

import 'package:dio/dio.dart';

import '../failures/failure.dart';
import '../result/result.dart';

/// Runs a request and turns every known way it can fail into a [Failure].
///
/// Parsing problems (a field with the wrong type, an unknown status) become
/// [InvalidDataFailure] instead of crashing the app: the response is treated
/// as untrusted input.
///
/// [mapError] lets a feature read error bodies it knows about (e.g. the
/// login's attempts left); returning `null` falls back to the generic
/// mapping.
Future<Result<T>> guardRequest<T>(
  Future<T> Function() request, {
  Failure? Function(DioException error)? mapError,
}) async {
  try {
    return Ok(await request());
  } on DioException catch (error) {
    return Err(mapError?.call(error) ?? failureFromDio(error));
  } on FormatException catch (error) {
    return Err(InvalidDataFailure(error.message));
  } on ArgumentError catch (error) {
    return Err(InvalidDataFailure('${error.name}: ${error.message}'));
  } on TypeError catch (error) {
    return Err(InvalidDataFailure(error.toString()));
  }
}

/// Maps a Dio error to the failure the rest of the app understands.
Failure failureFromDio(DioException error, {DateTime? now}) =>
    switch (error.type) {
      DioExceptionType.cancel => const CancelledFailure(),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const TimeoutFailure(),
      DioExceptionType.connectionError => const NoConnectionFailure(),
      DioExceptionType.badResponse => _fromStatus(error.response, now),
      DioExceptionType.badCertificate => const ServerFailure(),
      DioExceptionType.unknown =>
        error.error is SocketException
            ? const NoConnectionFailure()
            : UnexpectedFailure(error.error ?? error, error.stackTrace),
    };

Failure _fromStatus(Response<Object?>? response, DateTime? now) {
  final status = response?.statusCode;
  return switch (status) {
    401 => const UnauthorizedFailure(),
    404 => const NotFoundFailure(),
    429 => RateLimitedFailure(
      retryAfter: parseRetryAfter(
        response?.headers.value(HttpHeaders.retryAfterHeader),
        now: now,
      ),
    ),
    _ => ServerFailure(statusCode: status),
  };
}

/// Reads a `Retry-After` header, which may be a number of seconds (`"30"`)
/// or an HTTP date. Returns `null` when absent or unreadable.
Duration? parseRetryAfter(String? value, {DateTime? now}) {
  if (value == null || value.trim().isEmpty) return null;
  final seconds = int.tryParse(value.trim());
  if (seconds != null) return seconds < 0 ? null : Duration(seconds: seconds);
  try {
    final date = HttpDate.parse(value.trim());
    final wait = date.difference((now ?? DateTime.now()).toUtc());
    return wait.isNegative ? Duration.zero : wait;
  } on HttpException {
    return null;
  }
}
