import 'dart:async';

import 'package:dio/dio.dart';

/// Shares one in-flight request among callers that ask for the same thing
/// at the same time (double tap on refresh, two widgets loading the same
/// data). Only one call reaches the network.
///
/// Each caller may still cancel with its own [CancelToken]: it stops
/// waiting right away, and the shared request is only cancelled when every
/// caller has given up.
final class RequestDeduplicator {
  final _inFlight = <String, _SharedRequest<Object?>>{};

  /// Number of distinct requests currently running, for tests and debugging.
  int get inFlightCount => _inFlight.length;

  Future<T> run<T>(
    String key,
    Future<T> Function(CancelToken token) request, {
    CancelToken? cancelToken,
  }) {
    final shared = _inFlight.putIfAbsent(key, () {
      final created = _SharedRequest<Object?>();
      created.future = request(created.token).whenComplete(() {
        created.completed = true;
        if (identical(_inFlight[key], created)) _inFlight.remove(key);
      });
      return created;
    });
    return shared.subscribe(cancelToken).then((value) => value as T);
  }
}

final class _SharedRequest<T> {
  final token = CancelToken();
  late final Future<T> future;
  var completed = false;
  var _subscribers = 0;

  Future<T> subscribe(CancelToken? callerToken) {
    _subscribers++;
    if (callerToken == null) {
      return future.whenComplete(_leave);
    }

    final completer = Completer<T>();
    var left = false;
    void leaveOnce() {
      if (left) return;
      left = true;
      _leave();
    }

    future
        .then(
          (value) {
            if (!completer.isCompleted) completer.complete(value);
          },
          onError: (Object error, StackTrace stack) {
            if (!completer.isCompleted) completer.completeError(error, stack);
          },
        )
        .whenComplete(leaveOnce);

    unawaited(
      callerToken.whenCancel.then((cancelError) {
        if (completer.isCompleted) return;
        completer.completeError(cancelError);
        leaveOnce();
      }),
    );
    return completer.future;
  }

  void _leave() {
    _subscribers--;
    if (_subscribers <= 0 && !completed && !token.isCancelled) {
      token.cancel('all callers cancelled');
    }
  }
}
