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

/// Smallest number of query characters a single fuzzy chunk may consume.
///
/// Allowing 1-character chunks turns the fallback into acronym matching
/// ("shared" → **S**uper **H**appy **A**wesome **R**ock **E**lephant **D**ance),
/// which is the same class of false positive this matcher exists to avoid.
const int _minFuzzyChunk = 2;

/// Longest query word the fuzzy fallback will consider.
///
/// The fallback tracks reachable query positions in an int bitmask; capping at
/// 30 keeps every shift inside the 32-bit range dart2js gives bitwise `int`
/// operations. Longer words still match via the plain substring path.
const int _maxFuzzyPattern = 30;

/// True when [c] is a word character for matching purposes: ASCII
/// alphanumerics plus everything non-ASCII (accented letters, CJK, …), so that
/// separators are the usual space, `-`, `_`, `(`, `.` and friends.
bool _isWordChar(int c) =>
    (c >= 0x61 && c <= 0x7a) || // a-z
    (c >= 0x30 && c <= 0x39) || // 0-9
    (c >= 0x41 && c <= 0x5a) || // A-Z
    c > 0x7f;

/// Returns true when [pattern] matches [text].
///
/// Both arguments are expected to already be lower-case — [fuzzyMatchAll]
/// handles that for its callers.
///
/// A plain substring hit is the primary match. Only when that fails does a
/// constrained fuzzy fallback run: [pattern] must be splittable into chunks of
/// at least [_minFuzzyChunk] characters, where each chunk starts on the first
/// character of a word in [text], stays inside that single word, and the chunks
/// consume distinct words left to right. Characters may be skipped *within* a
/// word, never across one.
///
/// Examples:
///   fuzzyContains("chillout vibes", "chilvib") → true  (chil|lout vib|es)
///   fuzzyContains("chillout vibes", "chl")     → true  (c-h-l inside one word)
///   fuzzyContains("chillout vibes", "xyz")     → false
///   fuzzyContains("what else is there", "shared") → false
///
/// That last case is the bug this replaced: a plain subsequence test with
/// unlimited gaps happily scavenged s-h-a-r-e-d out of six unrelated words, so
/// typing *more* of a query made false positives *more* likely instead of less.
bool fuzzyContains(String text, String pattern) {
  if (pattern.isEmpty) return true;
  if (text.contains(pattern)) return true;
  return _wordAnchoredMatch(text, pattern);
}

/// The constrained fuzzy fallback described on [fuzzyContains].
///
/// Walks [text] one word at a time, carrying a bitmask of the query positions
/// reachable so far (bit `p` set == `pattern[0..p)` has been consumed). Each
/// word can extend any reachable position by one chunk, so a word is never
/// reused for two chunks. No allocation on the hot path.
bool _wordAnchoredMatch(String text, String pattern) {
  final patternLength = pattern.length;
  if (patternLength < _minFuzzyChunk || patternLength > _maxFuzzyPattern) {
    return false;
  }
  final textLength = text.length;
  final done = 1 << patternLength;
  int reachable = 1; // Nothing consumed yet.

  int i = 0;
  while (i < textLength) {
    // codeUnitAt compares ints directly — text[i] would allocate a fresh
    // single-character String on every comparison, which adds up fast when
    // this runs per-character, per-word, per-project, per-keystroke.
    if (!_isWordChar(text.codeUnitAt(i))) {
      i++;
      continue;
    }
    final wordStart = i;
    int wordEnd = i + 1;
    while (wordEnd < textLength && _isWordChar(text.codeUnitAt(wordEnd))) {
      wordEnd++;
    }
    i = wordEnd;

    int next = reachable; // A word may also simply be skipped.
    for (int p = 0; p < patternLength; p++) {
      if (reachable & (1 << p) == 0) continue;
      // The chunk must be anchored to the start of the word.
      if (text.codeUnitAt(wordStart) != pattern.codeUnitAt(p)) continue;
      // Greedy left-to-right subsequence matching consumes the maximum number
      // of query characters this word can supply, and every shorter prefix of
      // that run is reachable too (just stop the chunk early).
      int consumed = 0;
      for (int j = wordStart; j < wordEnd && p + consumed < patternLength; j++) {
        if (text.codeUnitAt(j) == pattern.codeUnitAt(p + consumed)) consumed++;
      }
      for (int c = _minFuzzyChunk; c <= consumed; c++) {
        next |= 1 << (p + c);
      }
    }
    reachable = next;
    if (reachable & done != 0) return true;
  }
  return false;
}

/// Splits [query] into words and returns true when every word matches [text].
bool fuzzyMatchAll(String text, String query) {
  final words = _wordsFor(query);
  final t = text.toLowerCase();
  return words.every((w) => fuzzyContains(t, w));
}

/// Returns true when [query] matches at least one of [texts].
///
/// Every word of [query] has to match the *same* entry — a query only matches
/// if some single searched field satisfies all of it. Null and empty entries
/// are skipped, so call sites can pass optional fields directly.
bool fuzzyMatchAny(Iterable<String?> texts, String query) {
  var sawText = false;
  for (final text in texts) {
    if (text == null || text.isEmpty) continue;
    sawText = true;
    if (fuzzyMatchAll(text, query)) return true;
  }
  // An all-empty candidate list still matches an empty query, matching
  // fuzzyMatchAll's "empty query matches everything" contract.
  return !sawText && _wordsFor(query).every((w) => w.isEmpty);
}
