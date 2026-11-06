/// Defensive reads from decoded JSON. Every response is untrusted input: a
/// missing field or a wrong type becomes a [FormatException] naming the
/// field, never a null that blows up three screens later.
extension type const JsonReader(Map<String, Object?> json) {
  /// Accepts anything that decoded as a JSON object.
  static JsonReader of(Object? value, [String context = 'body']) {
    if (value is Map<String, Object?>) return JsonReader(value);
    if (value is Map) return JsonReader(value.cast<String, Object?>());
    throw FormatException('Expected a JSON object in $context');
  }

  String string(String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Field "$key" must be a non-empty string');
  }

  String? optionalString(String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value;
    throw FormatException('Field "$key" must be a string');
  }

  /// Integers only: `12.5` or `"1250"` for a cents field is a data error,
  /// not something to round or guess.
  int integer(String key) {
    final value = json[key];
    if (value is int) return value;
    throw FormatException('Field "$key" must be an integer');
  }

  List<Object?> list(String key) {
    final value = json[key];
    if (value is List) return value;
    throw FormatException('Field "$key" must be a list');
  }

  /// A timestamp with an explicit offset (`Z` or `-03:00`). A date without
  /// one is ambiguous (whose midnight?), so it is rejected.
  DateTime instant(String key) {
    final raw = string(key);
    if (!_hasOffset.hasMatch(raw)) {
      throw FormatException('Field "$key" has no time zone', raw);
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('Field "$key" is not a date', raw);
    }
    return parsed.toUtc();
  }

  static final _hasOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');
}
