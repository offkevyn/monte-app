import '../domain/entities/session.dart';

/// The session of the customer using the app right now, kept in memory
/// after login or fingerprint unlock. Screens read the name from here; the
/// token stays in the secure store.
final class CurrentSession {
  Session? _session;

  Session? get value => _session;

  bool get isSignedIn => _session != null;

  void start(Session session) => _session = session;

  void end() => _session = null;
}
