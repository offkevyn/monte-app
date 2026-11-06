import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/network/api_client_factory.dart';
import 'package:monte/core/network/retry_interceptor.dart';

import '../../helpers/scripted_adapter.dart';

void main() {
  late List<Duration> waits;

  // No jitter, so the expected waits are exact.
  const policy = RetryPolicy(jitter: 0);

  Dio dioWith(ScriptedAdapter adapter, {RetryPolicy retryPolicy = policy}) =>
      ApiClientFactory.create(
        baseUrl: 'https://api.test',
        adapter: adapter,
        retryPolicy: retryPolicy,
        sleep: (d) async => waits.add(d),
      );

  setUp(() => waits = []);

  test('retries a 503 with exponential backoff, then succeeds', () async {
    final adapter = ScriptedAdapter([
      const ScriptStep.status(503),
      const ScriptStep.status(503),
      const ScriptStep.ok({'value': 1}),
    ]);

    final response = await dioWith(adapter).get<Object?>('/balance');

    expect(response.data, {'value': 1});
    expect(adapter.requests, hasLength(3));
    expect(waits, [
      const Duration(milliseconds: 400),
      const Duration(milliseconds: 800),
    ]);
  });

  test('gives up after maxRetries and surfaces the last error', () async {
    final adapter = ScriptedAdapter([
      for (var i = 0; i < 4; i++) ScriptStep.connectionError(),
    ]);

    await expectLater(
      dioWith(adapter).get<Object?>('/balance'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );
    expect(adapter.requests, hasLength(4)); // 1 try + 3 retries
    expect(waits, hasLength(3));
  });

  test('retries timeouts too', () async {
    final adapter = ScriptedAdapter([
      ScriptStep.timeout(),
      const ScriptStep.ok(),
    ]);
    await dioWith(adapter).get<Object?>('/x');
    expect(adapter.requests, hasLength(2));
  });

  test('does not retry client errors', () async {
    final adapter = ScriptedAdapter([const ScriptStep.status(404)]);
    await expectLater(
      dioWith(adapter).get<Object?>('/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
    expect(waits, isEmpty);
  });

  test('never retries a POST (not idempotent)', () async {
    final adapter = ScriptedAdapter([const ScriptStep.status(503)]);
    await expectLater(
      dioWith(adapter).post<Object?>('/login'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('429 waits what the server asks in Retry-After', () async {
    final adapter = ScriptedAdapter([
      const ScriptStep.status(429, headers: {'retry-after': '2'}),
      const ScriptStep.ok(),
    ]);
    await dioWith(adapter).get<Object?>('/x');
    expect(waits, [const Duration(seconds: 2)]);
  });

  test('429 without Retry-After falls back to backoff', () async {
    final adapter = ScriptedAdapter([
      const ScriptStep.status(429),
      const ScriptStep.ok(),
    ]);
    await dioWith(adapter).get<Object?>('/x');
    expect(waits, [const Duration(milliseconds: 400)]);
  });

  test('429 asking for too long a wait is not retried', () async {
    final adapter = ScriptedAdapter([
      const ScriptStep.status(429, headers: {'retry-after': '120'}),
    ]);
    await expectLater(
      dioWith(adapter).get<Object?>('/x'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          429,
        ),
      ),
    );
    expect(waits, isEmpty);
  });

  test('a request cancelled while waiting is not retried', () async {
    final token = CancelToken();
    final adapter = ScriptedAdapter([const ScriptStep.status(503)]);
    final dio = ApiClientFactory.create(
      baseUrl: 'https://api.test',
      adapter: adapter,
      retryPolicy: policy,
      sleep: (_) async => token.cancel('user typed again'),
    );

    await expectLater(
      dio.get<Object?>('/x', cancelToken: token),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
  });

  group('RetryPolicy.backoff', () {
    test('doubles each time and stops at maxDelay', () {
      final random = Random(1);
      const p = RetryPolicy(jitter: 0, maxDelay: Duration(seconds: 2));
      expect(p.backoff(0, random), const Duration(milliseconds: 400));
      expect(p.backoff(1, random), const Duration(milliseconds: 800));
      expect(p.backoff(2, random), const Duration(milliseconds: 1600));
      expect(p.backoff(3, random), const Duration(seconds: 2));
      expect(p.backoff(10, random), const Duration(seconds: 2));
    });

    test('jitter only adds, up to the configured fraction', () {
      final random = Random(1);
      const p = RetryPolicy();
      for (var i = 0; i < 50; i++) {
        final wait = p.backoff(0, random);
        expect(wait, greaterThanOrEqualTo(const Duration(milliseconds: 400)));
        expect(wait, lessThanOrEqualTo(const Duration(milliseconds: 520)));
      }
    });
  });
}
