import 'package:dio/dio.dart';

/// Sends the session token on every bank request and reports when the bank
/// rejects it.
///
/// - `Authorization: Bearer <token>` is added only when there is a token
///   (the login itself goes without one).
/// - A 401 on a request that carried the token means the session is over
///   (expired, revoked): [onRejected] runs. A 401 without a token is the
///   login answering "wrong password" and is left to the login screen.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._token, required this._onRejected});

  final String? Function() _token;
  final void Function() _onRejected;

  static const _header = 'Authorization';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _token();
    if (token != null && token.isNotEmpty) {
      options.headers[_header] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.headers.containsKey(_header)) {
      _onRejected();
    }
    handler.next(err);
  }
}
