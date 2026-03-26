/// Returns true if every character in [pattern] appears in [text] in order
/// (case-insensitive). This is a simple fuzzy-match used for search fields.
///
/// Examples:
///   fuzzyContains("Chillout Vibes", "chilvib") → true
///   fuzzyContains("Chillout Vibes", "xyz") → false
bool fuzzyContains(String text, String pattern) {
  if (pattern.isEmpty) return true;
  int pi = 0;
  for (int i = 0; i < text.length && pi < pattern.length; i++) {
    if (text[i] == pattern[pi]) pi++;
  }
  return pi == pattern.length;
}

/// Splits [query] into words and returns true when every word fuzzy-matches [text].
bool fuzzyMatchAll(String text, String query) {
  final words = query.toLowerCase().trim().split(RegExp(r'\s+'));
  final t = text.toLowerCase();
  return words.every((w) => fuzzyContains(t, w));
}
