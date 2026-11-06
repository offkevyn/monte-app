import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Dio transport that answers from a script, in order, and records every
/// request. Each step is either a response or an error to throw.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(List<ScriptStep> steps) : _steps = List.of(steps);

  final List<ScriptStep> _steps;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_steps.isEmpty) throw StateError('No scripted step left');
    final step = _steps.removeAt(0);
    if (step.delay > Duration.zero) await Future<void>.delayed(step.delay);
    final error = step.error;
    if (error != null) throw error(options);
    return ResponseBody.fromString(
      jsonEncode(step.body),
      step.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final entry in step.headers.entries) entry.key: [entry.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class ScriptStep {
  const ScriptStep.ok([
    this.body = const {'ok': true},
    this.delay = Duration.zero,
  ]) : status = 200,
       headers = const {},
       error = null;

  const ScriptStep.status(this.status, {this.headers = const {}})
    : body = const {'error': 'scripted'},
      delay = Duration.zero,
      error = null;

  ScriptStep.connectionError()
    : status = 0,
      body = null,
      headers = const {},
      delay = Duration.zero,
      error = ((options) => DioException.connectionError(
        requestOptions: options,
        reason: 'scripted offline',
      ));

  ScriptStep.timeout()
    : status = 0,
      body = null,
      headers = const {},
      delay = Duration.zero,
      error = ((options) => DioException.receiveTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: options,
      ));

  final int status;
  final Object? body;
  final Map<String, String> headers;
  final Duration delay;
  final DioException Function(RequestOptions options)? error;
}
