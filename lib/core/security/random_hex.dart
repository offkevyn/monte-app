import 'dart:math';

/// [bytes] random bytes as lower case hex (two characters per byte).
/// Pass `Random.secure()` for anything that protects data.
String randomHex(Random random, int bytes) => List.generate(
  bytes,
  (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();
