/// Search rules for the statement: case and accent insensitive, every word
/// of the query must appear ("cafe pad" finds "Café da Padaria").
abstract final class SearchText {
  /// Longer input is cut, so a pasted paragraph cannot become a huge query.
  static const maxLength = 60;

  static const _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
    'ç': 'c', 'ñ': 'n',
  };

  static final _spaces = RegExp(r'\s+');

  /// Trims, collapses inner spaces and limits the length of user input.
  static String cleanQuery(String raw) {
    final collapsed = raw.trim().replaceAll(_spaces, ' ');
    return collapsed.length <= maxLength
        ? collapsed
        : collapsed.substring(0, maxLength).trimRight();
  }

  /// Lower case without accents, used on both sides of a comparison.
  static String normalize(String text) {
    final buffer = StringBuffer();
    for (final char in text.toLowerCase().split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  /// Whether every word of [query] appears somewhere in [text].
  static bool matches(String text, String query) {
    final haystack = normalize(text);
    return normalize(cleanQuery(query))
        .split(' ')
        .where((word) => word.isNotEmpty)
        .every(haystack.contains);
  }
}
