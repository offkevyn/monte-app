import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/network/fake/device_connection.dart';
import 'package:monte/core/network/fake/fake_http_adapter.dart';
import 'package:monte/core/network/fake/fake_scenario.dart';

void main() {
  group('DeviceConnection', () {
    late int lookups;
    late DateTime now;

    DeviceConnection connection(Future<List<InternetAddress>> Function() f) =>
        DeviceConnection(
          lookup: (_) {
            lookups++;
            return f();
          },
          now: () => now,
        );

    setUp(() {
      lookups = 0;
      now = DateTime(2026, 11, 9, 12);
    });

    test('online when the host resolves', () async {
      final c = connection(() async => [InternetAddress.loopbackIPv4]);
      expect(await c.isOnline(), isTrue);
    });

    test('offline when the lookup fails', () async {
      final c = connection(
        () async => throw const SocketException('Failed host lookup'),
      );
      expect(await c.isOnline(), isFalse);
    });

    test('one check serves a burst, a new one after a few seconds', () async {
      final c = connection(() async => [InternetAddress.loopbackIPv4]);
      await Future.wait([c.isOnline(), c.isOnline(), c.isOnline()]);
      await c.isOnline();
      expect(lookups, 1);

      now = now.add(const Duration(seconds: 6));
      await c.isOnline();
      expect(lookups, 2);
    });
  });

  group('simulated bank with the phone offline', () {
    Dio dio({required bool online}) =>
        Dio(BaseOptions(baseUrl: 'https://bank.test'))
          ..httpClientAdapter = FakeHttpAdapter(
            settings: FakeBackendSettings(),
            sleep: (_) async {},
            isDeviceOnline: () async => online,
            routes: [
              FakeRoute(
                'GET',
                '/v1/account',
                (_) => const FakeResponse(200, {'ok': true}),
              ),
            ],
          );

    test('fails like a server out of reach', () async {
      await expectLater(
        dio(online: false).get<Object>('/v1/account'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
    });

    test('answers normally when online', () async {
      final response = await dio(online: true).get<Object>('/v1/account');
      expect(response.statusCode, 200);
    });
  });
}
