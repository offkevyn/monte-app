import 'dart:async';

/// Where the network reports that the bank rejected the session (HTTP 401
/// on a request that carried the token). The app listens once, at the top,
/// and signs the customer out; screens never handle it one by one.
final class SessionExpiry {
  final _rejected = StreamController<void>.broadcast();

  Stream<void> get rejected => _rejected.stream;

  void report() {
    if (!_rejected.isClosed) _rejected.add(null);
  }

  Future<void> dispose() => _rejected.close();
}
