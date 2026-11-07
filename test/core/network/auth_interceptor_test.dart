import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/network/api_client_factory.dart';
import 'package:monte/core/network/auth_interceptor.dart';
import 'package:monte/core/network/fake/fake_http_adapter.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';
import 'package:monte/core/network/retry_interceptor.dart';

void main() {
  late List<FakeRequest> seen;
  late int rejections;
  String? token;
  late int status;

  Dio build() {
    final adapter = FakeHttpAdapter(
      settings: FakeBackendSettings(),
      sleep: (_) async {},
      routes: [
        for (final path in ['/v1/account', '/v1/auth/login'])
          FakeRoute('GET', path, (request) {
            seen.add(request);
            return FakeResponse(status, {'ok': status == 200});
          }),
      ],
    );
    return ApiClientFactory.create(
      baseUrl: ApiClientFactory.fakeBankBaseUrl,
      adapter: adapter,
      retryPolicy: const RetryPolicy(jitter: 0),
      sleep: (_) async {},
      interceptors: [
        AuthInterceptor(token: () => token, onRejected: () => rejections++),
      ],
    );
  }

  setUp(() {
    seen = [];
    rejections = 0;
    token = 'monte_1_abc';
    status = 200;
  });

  String? authorization(FakeRequest request) =>
      request.headers['Authorization'] as String?;

  test('every request carries the session token', () async {
    await build().get<Object?>('/v1/account');
    expect(authorization(seen.single), 'Bearer monte_1_abc');
  });

  test('without a session (the login) no header is sent', () async {
    token = null;
    await build().get<Object?>('/v1/auth/login');
    expect(authorization(seen.single), isNull);
  });

  test('a 401 with the token reports the session as rejected', () async {
    status = 401;
    await expectLater(
      build().get<Object?>('/v1/account'),
      throwsA(isA<DioException>()),
    );
    expect(rejections, 1);
  });

  test(
    'a 401 without a token (wrong password) is not a lost session',
    () async {
      token = null;
      status = 401;
      await expectLater(
        build().get<Object?>('/v1/auth/login'),
        throwsA(isA<DioException>()),
      );
      expect(rejections, 0);
    },
  );

  test('other errors are not a lost session', () async {
    status = 404;
    await expectLater(
      build().get<Object?>('/v1/account'),
      throwsA(isA<DioException>()),
    );
    expect(rejections, 0);
  });
}
