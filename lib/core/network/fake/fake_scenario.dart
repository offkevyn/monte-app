/// What the simulated backend should do, chosen in the dev-only scenario
/// picker. Lets the presentation show every screen state on demand.
enum FakeScenario {
  /// Realistic data with small random latency.
  normal,

  /// Account with no transactions.
  empty,

  /// Every request answers HTTP 500 (retries happen, then the error screen).
  serverError,

  /// The first two calls of each endpoint answer 429 with `Retry-After`,
  /// then it recovers: shows the backoff working.
  rateLimited,

  /// Every request takes about 3 seconds (skeletons, cancellation).
  slow,

  /// No connection at all (offline banner, cached data).
  offline,

  /// Some records come broken (missing fields, wrong types).
  corruptedData,

  /// Login always rejects the password.
  wrongPassword,

  /// The bank rejects every token (HTTP 401), as when the session expired
  /// or was revoked on the server: the app signs out and asks for login.
  sessionExpired,
}

/// How many transactions the simulated account has.
enum FakeVolume {
  /// A brand new account: a few movements, to see short lists.
  tiny(3),
  small(50),
  medium(500),
  large(10000);

  const FakeVolume(this.transactionCount);

  final int transactionCount;
}

/// Mutable settings read by the fake backend on every request, so changing
/// the scenario takes effect on the next call without restarting the app.
final class FakeBackendSettings {
  FakeBackendSettings({
    this.scenario = FakeScenario.normal,
    this.volume = FakeVolume.medium,
    this.seed = 42,
  });

  FakeScenario scenario;
  FakeVolume volume;

  /// Same seed, same data: the demo and the tests are reproducible.
  int seed;

  final _listeners = <void Function()>[];

  /// Called when [volume] or [seed] change, so data can be regenerated.
  void addDataListener(void Function() listener) => _listeners.add(listener);

  void updateData({FakeVolume? volume, int? seed}) {
    this.volume = volume ?? this.volume;
    this.seed = seed ?? this.seed;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}
