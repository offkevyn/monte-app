import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/network/request_deduplicator.dart';

void main() {
  late RequestDeduplicator dedup;
  late int calls;
  late Completer<String> server;
  late CancelToken? lastToken;

  Future<String> request(CancelToken token) {
    calls++;
    lastToken = token;
    return server.future;
  }

  setUp(() {
    dedup = RequestDeduplicator();
    calls = 0;
    server = Completer<String>();
    lastToken = null;
  });

  test('same request at the same time hits the network once', () async {
    final a = dedup.run('/balance', request);
    final b = dedup.run('/balance', request);
    expect(dedup.inFlightCount, 1);

    server.complete('R\$ 10');

    expect(await a, 'R\$ 10');
    expect(await b, 'R\$ 10');
    expect(calls, 1);
    expect(dedup.inFlightCount, 0);
  });

  test('different keys are not merged', () async {
    final a = dedup.run('/a', request);
    final b = dedup.run('/b', request);
    expect(calls, 2);
    server.complete('x');
    await Future.wait([a, b]);
  });

  test('after it finishes, the next call goes to the network again', () async {
    server.complete('first');
    await dedup.run('/x', request);
    server = Completer<String>()..complete('second');
    expect(await dedup.run('/x', request), 'second');
    expect(calls, 2);
  });

  test('errors reach every caller', () async {
    final a = dedup.run('/x', request);
    final b = dedup.run('/x', request);
    server.completeError(StateError('500'));
    await expectLater(a, throwsStateError);
    await expectLater(b, throwsStateError);
  });

  test('one caller cancelling does not cancel the others', () async {
    final tokenA = CancelToken();
    final a = dedup.run('/x', request, cancelToken: tokenA);
    final b = dedup.run('/x', request, cancelToken: CancelToken());

    tokenA.cancel('left the screen');
    await expectLater(a, throwsA(isA<DioException>()));
    expect(lastToken!.isCancelled, isFalse);

    server.complete('still here');
    expect(await b, 'still here');
  });

  test('when every caller cancels, the network request is cancelled', () async {
    final tokenA = CancelToken();
    final tokenB = CancelToken();
    final a = dedup.run('/x', request, cancelToken: tokenA);
    final b = dedup.run('/x', request, cancelToken: tokenB);

    tokenA.cancel();
    tokenB.cancel();
    await expectLater(a, throwsA(isA<DioException>()));
    await expectLater(b, throwsA(isA<DioException>()));
    expect(lastToken!.isCancelled, isTrue);

    server.complete('too late');
  });

  test('a finished request is never cancelled afterwards', () async {
    final token = CancelToken();
    final a = dedup.run('/x', request, cancelToken: token);
    server.complete('done');
    await a;
    token.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(lastToken!.isCancelled, isFalse);
  });
}
