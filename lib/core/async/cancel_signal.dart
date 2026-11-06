import 'dart:async';

/// Lets a screen give up on work it no longer needs (the user typed another
/// letter, or picked another chart period) without the domain knowing about
/// the HTTP library. The data layer turns it into the client's own cancel.
final class CancelSignal {
  final _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  /// Completes once, when [cancel] is called.
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}
