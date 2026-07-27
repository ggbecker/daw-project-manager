final RegExp _whitespace = RegExp(r'\s+');

// fuzzyMatchAll is called once per project per keystroke across several
// list filters — re-splitting the same query string on every call was
// measurably wasteful at list sizes in the thousands. The query is the same
// across an entire filter pass, so cache the split for the single most
// recent query rather than recomputing it per item.
String? _lastQuery;
List<String>? _lastQueryWords;

List<String> _wordsFor(String query) {
  final cached = _lastQueryWords;
  if (cached != null && _lastQuery == query) return cached;
  final words = query.toLowerCase().trim().split(_whitespace);
  _lastQuery = query;
  _lastQueryWords = words;
  return words;
}

/// Returns true if every character in [pattern] appears in [text] in order
/// (case-insensitive). This is a simple fuzzy-match used for search fields.
///
/// Examples:
///   fuzzyContains("Chillout Vibes", "chilvib") → true
///   fuzzyContains("Chillout Vibes", "xyz") → false
bool fuzzyContains(String text, String pattern) {
  final patternLength = pattern.length;
  if (patternLength == 0) return true;
  final textLength = text.length;
  int pi = 0;
  // codeUnitAt compares ints directly — text[i] would allocate a fresh
  // single-character String on every comparison, which adds up fast when
  // this runs per-character, per-word, per-project, per-keystroke.
  for (int i = 0; i < textLength && pi < patternLength; i++) {
    if (text.codeUnitAt(i) == pattern.codeUnitAt(pi)) pi++;
  }
  return pi == patternLength;
}

/// Splits [query] into words and returns true when every word fuzzy-matches [text].
bool fuzzyMatchAll(String text, String query) {
  final words = _wordsFor(query);
  final t = text.toLowerCase();
  return words.every((w) => fuzzyContains(t, w));
}
