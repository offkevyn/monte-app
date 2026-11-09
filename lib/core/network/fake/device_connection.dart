import 'dart:async';
import 'dart:io';

/// Whether the phone can reach the internet, for the simulated bank only.
///
/// The simulated bank lives inside the app, so on its own it would keep
/// answering with the phone offline. Asking this first makes it fail like a
/// real server would, and the app falls back to what is saved. A real
/// backend does not need it: the request itself fails.
class DeviceConnection {
  DeviceConnection({
    Future<List<InternetAddress>> Function(String host)? lookup,
    DateTime Function()? now,
  }) : _lookup = lookup ?? InternetAddress.lookup,
       _now = now ?? DateTime.now;

  final Future<List<InternetAddress>> Function(String host) _lookup;
  final DateTime Function() _now;

  /// One answer serves the burst of requests a screen makes at once.
  static const _reuseFor = Duration(seconds: 5);
  static const _timeout = Duration(seconds: 3);

  bool? _last;
  DateTime? _checkedAt;
  Future<bool>? _pending;

  Future<bool> isOnline() {
    final checkedAt = _checkedAt;
    if (_last != null &&
        checkedAt != null &&
        _now().difference(checkedAt) < _reuseFor) {
      return Future.value(_last);
    }
    return _pending ??= _check().whenComplete(() => _pending = null);
  }

  Future<bool> _check() async {
    bool online;
    try {
      final found = await _lookup('api.coingecko.com').timeout(_timeout);
      online = found.isNotEmpty;
    } on Exception {
      online = false;
    }
    _last = online;
    _checkedAt = _now();
    return online;
  }
}
