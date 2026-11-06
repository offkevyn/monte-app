import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/network/network_failures.dart';
import 'package:monte/core/result/result.dart';

void main() {
  final options = RequestOptions(path: '/x');

  DioException withStatus(int status, {Map<String, List<String>>? headers}) =>
      DioException.badResponse(
        statusCode: status,
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: status,
          headers: Headers.fromMap(headers ?? const {}),
        ),
      );

  group('failureFromDio', () {
    test('maps each kind of transport problem', () {
      expect(
        failureFromDio(
          DioException.requestCancelled(
            requestOptions: options,
            reason: 'newer search',
          ),
        ),
        const CancelledFailure(),
      );
      expect(
        failureFromDio(
          DioException.connectionTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: options,
          ),
        ),
        const TimeoutFailure(),
      );
      expect(
        failureFromDio(
          DioException.receiveTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: options,
          ),
        ),
        const TimeoutFailure(),
      );
      expect(
        failureFromDio(
          DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          ),
        ),
        const NoConnectionFailure(),
      );
      expect(
        failureFromDio(DioException.badCertificate(requestOptions: options)),
        const ServerFailure(),
      );
    });

    test('unknown errors: socket means offline, the rest is unexpected', () {
      expect(
        failureFromDio(
          DioException(
            requestOptions: options,
            error: const SocketException('down'),
          ),
        ),
        const NoConnectionFailure(),
      );
      expect(
        failureFromDio(DioException(requestOptions: options, error: 'weird')),
        isA<UnexpectedFailure>(),
      );
    });

    test('maps HTTP statuses', () {
      expect(failureFromDio(withStatus(401)), const UnauthorizedFailure());
      expect(failureFromDio(withStatus(404)), const NotFoundFailure());
      expect(
        failureFromDio(withStatus(503)),
        const ServerFailure(statusCode: 503),
      );
      expect(
        failureFromDio(withStatus(400)),
        const ServerFailure(statusCode: 400),
      );
    });

    test('429 carries the Retry-After wait', () {
      expect(
        failureFromDio(
          withStatus(
            429,
            headers: {
              'retry-after': ['30'],
            },
          ),
        ),
        const RateLimitedFailure(retryAfter: Duration(seconds: 30)),
      );
      expect(failureFromDio(withStatus(429)), const RateLimitedFailure());
    });
  });

  group('parseRetryAfter', () {
    final now = DateTime.utc(2026, 11, 5, 12);

    test('reads seconds', () {
      expect(parseRetryAfter('5'), const Duration(seconds: 5));
      expect(parseRetryAfter(' 0 '), Duration.zero);
    });

    test('reads an HTTP date relative to now', () {
      expect(
        parseRetryAfter('Thu, 05 Nov 2026 12:00:45 GMT', now: now),
        const Duration(seconds: 45),
      );
      expect(
        parseRetryAfter('Thu, 05 Nov 2026 11:00:00 GMT', now: now),
        Duration.zero,
      );
    });

    test('ignores missing or unreadable values', () {
      expect(parseRetryAfter(null), isNull);
      expect(parseRetryAfter(''), isNull);
      expect(parseRetryAfter('-3'), isNull);
      expect(parseRetryAfter('soon'), isNull);
    });
  });

  group('guardRequest', () {
    test('wraps success', () async {
      expect(await guardRequest(() async => 1), const Ok(1));
    });

    test('turns transport and parsing errors into failures', () async {
      expect(
        await guardRequest<int>(
          () => throw DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          ),
        ),
        const Err<int>(NoConnectionFailure()),
      );
      expect(
        await guardRequest<int>(() => throw const FormatException('bad json')),
        const Err<int>(InvalidDataFailure('bad json')),
      );
      expect(
        (await guardRequest<int>(() => throw ArgumentError.value(-1, 'amount')))
            .failureOrNull,
        isA<InvalidDataFailure>(),
      );
      expect(
        (await guardRequest<int>(() async {
          const Object value = 'not a number';
          return value as int;
        })).failureOrNull,
        isA<InvalidDataFailure>(),
      );
    });
  });
}
