import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/fake/fake_scenario.dart';
import '../../../../core/time/clock.dart';

/// Lets the dev scenario picker bend the real CoinGecko connection, so the
/// presentation can show the 429 countdown or the offline banner on demand
/// instead of waiting for the real API to misbehave.
///
/// With the normal scenario (and in every test that does not set one) it
/// does nothing.
class SimulatedConditionsInterceptor extends Interceptor {
  SimulatedConditionsInterceptor(this._settings, this._clock);

  /// Longer than the retry interceptor waits on its own, so the screen
  /// shows the countdown.
  static const rateLimitWindow = Duration(seconds: 15);

  final FakeBackendSettings _settings;
  final Clock _clock;

  DateTime? _limitedUntil;
  var _limitServed = false;
  FakeScenario? _lastScenario;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final scenario = _settings.scenario;
    if (scenario != _lastScenario) {
      _lastScenario = scenario;
      _limitedUntil = null;
      _limitServed = false;
    }

    switch (scenario) {
      case FakeScenario.offline:
        return handler.reject(
          DioException.connectionError(
            requestOptions: options,
            reason: 'Simulated: no connection',
            error: const SocketException('Simulated: no connection'),
          ),
          true,
        );
      case FakeScenario.serverError:
        return handler.reject(_response(options, 500), true);
      case FakeScenario.rateLimited:
        final rejection = _rateLimit(options);
        if (rejection != null) return handler.reject(rejection, true);
      case FakeScenario.slow:
        await Future<void>.delayed(const Duration(seconds: 3));
      case FakeScenario.normal ||
          FakeScenario.empty ||
          FakeScenario.corruptedData ||
          FakeScenario.wrongPassword ||
          FakeScenario.sessionExpired:
        break;
    }
    handler.next(options);
  }

  /// The first call opens a window of [rateLimitWindow] answering 429 with
  /// the seconds left; after it, calls go through until the scenario is
  /// picked again.
  DioException? _rateLimit(RequestOptions options) {
    if (_limitServed) return null;
    final now = _clock.nowUtc();
    final until = _limitedUntil ??= now.add(rateLimitWindow);
    if (!now.isBefore(until)) {
      _limitServed = true;
      return null;
    }
    final seconds = (until.difference(now).inMilliseconds / 1000).ceil();
    return _response(
      options,
      HttpStatus.tooManyRequests,
      headers: {
        HttpHeaders.retryAfterHeader: ['$seconds'],
      },
    );
  }

  static DioException _response(
    RequestOptions options,
    int status, {
    Map<String, List<String>> headers = const {},
  }) => DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      headers: Headers.fromMap(headers),
      data: {'simulated': true},
    ),
  );
}
