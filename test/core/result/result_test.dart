import 'package:flutter_test/flutter_test.dart';
import 'package:monte/core/failures/failure.dart';
import 'package:monte/core/result/result.dart';

void main() {
  group('Result', () {
    const ok = Ok<int>(42);
    const err = Err<int>(NoConnectionFailure());

    test('exposes the value only on success', () {
      expect(ok.isOk, isTrue);
      expect(ok.valueOrNull, 42);
      expect(ok.failureOrNull, isNull);

      expect(err.isErr, isTrue);
      expect(err.valueOrNull, isNull);
      expect(err.failureOrNull, const NoConnectionFailure());
    });

    test('map transforms success and keeps the failure', () {
      expect(ok.map((v) => v * 2), const Ok<int>(84));
      expect(err.map((v) => v * 2), const Err<int>(NoConnectionFailure()));
    });

    test('then runs the next step only on success', () async {
      var calls = 0;
      Future<Result<String>> next(int v) async {
        calls++;
        return Ok('value $v');
      }

      expect(await ok.then(next), const Ok('value 42'));
      expect(await err.then(next), const Err<String>(NoConnectionFailure()));
      expect(calls, 1);
    });

    test('can be handled with an exhaustive switch', () {
      String describe(Result<int> result) => switch (result) {
        Ok(:final value) => 'ok $value',
        Err(:final failure) => 'err $failure',
      };

      expect(describe(ok), 'ok 42');
      expect(describe(err), 'err NoConnectionFailure()');
    });

    test('compares by value', () {
      expect(const Ok(1), const Ok(1));
      expect(const Ok(1), isNot(const Ok(2)));
      expect(
        const Err<int>(ServerFailure(statusCode: 500)),
        const Err<int>(ServerFailure(statusCode: 500)),
      );
      expect(
        const Err<int>(ServerFailure(statusCode: 500)),
        isNot(const Err<int>(ServerFailure(statusCode: 503))),
      );
    });
  });
}
