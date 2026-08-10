/// Strips date stamps that DAWs and export scripts bake into project and
/// mixdown file names — Cubase in particular names sessions
/// `2026-08-02 - Massive Attack - Teardrop`, which pushes the actual title
/// out of view in the dashboard's name column and lands verbatim in the
/// filename of anything shared to a messaging app.
///
/// Pure string work: no I/O, no Flutter, no DateTime construction. The parsed
/// date is deliberately *not* returned — nothing in the app displays it, so
/// producing it would only invite a caller to start showing it again.
library;

/// Separator characters a date token may be joined to the rest of the name
/// with. A match must be adjacent to one of these, which is what keeps the
/// `2026` inside `Track 2026 Mix` from being eaten.
const String _sep = r'[\s._-]';

/// `YYYY` constrained to 1990–2099. Two-digit years are deliberately absent:
/// `01-02-2026` is a date, but `01 - Intro` is a track number, and no amount
/// of validation separates those two reliably.
const String _year = r'(?:199\d|20\d\d)';
const String _month = r'(?:0[1-9]|1[0-2])';
const String _day = r'(?:0[1-9]|[12]\d|3[01])';

/// Optional clock time trailing the date, as produced by export scripts:
/// ` 14-30`, `_14-30-55`, `.143055`. Always preceded by a separator.
const String _time =
    '(?:$_sep' r'(?:[01]\d|2[0-3])[._-]?[0-5]\d(?:[._-]?[0-5]\d)?)?';

/// The three orderings seen in the wild. The inner capture group pins the
/// component separator to a single consistent character, so `2026-08.02`
/// (mixed) doesn't match while `2026-08-02`, `2026 08 02` and `20260802` do.
const String _dateBody =
    '(?:'
    '$_year($_sep?)$_month' r'\1' '$_day' // 2026-08-02 / 2026_08_02 / 20260802
    '|'
    '$_day($_sep)$_month' r'\2' '$_year' // 02-08-2026
    '|'
    '$_month($_sep)$_day' r'\3' '$_year' // 08-02-2026
    ')';

/// Date (+ optional time) at the very start, followed by a separator and at
/// least one more character — a name that is *only* a date isn't stripped.
final RegExp _leading = RegExp('^$_dateBody$_time$_sep+(?=.)');

/// Date (+ optional time) at the very end, preceded by a separator and at
/// least one preceding character.
final RegExp _trailing = RegExp('(?<=.)$_sep+$_dateBody$_time\$');

/// Separators left dangling once a date token is removed — e.g. the ` - ` in
/// `2026-08-02 - Teardrop` is only partly consumed by [_leading]. Only ever
/// applied to a string a date was actually removed from, so a name that
/// legitimately starts or ends with a dash keeps it.
final RegExp _danglingSeparators = RegExp('^$_sep+|$_sep+\$');

/// Returns [name] with a leading or trailing date stamp removed.
///
/// Returns [name] unchanged (not even trimmed) when no confident match is
/// found, and also when stripping would leave nothing behind — a project
/// literally named `2026-08-02` keeps its name rather than going blank.
String stripNameDate(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return name;

  // Leading first: a name can carry both (`2026-08-02 - Mix - 2026-08-02`),
  // and removing the leading one never invalidates the trailing match.
  var result = trimmed.replaceFirst(_leading, '');
  result = result.replaceFirst(_trailing, '');
  if (result == trimmed) return name;

  result = result.replaceAll(_danglingSeparators, '');
  return result.isEmpty ? name : result;
}

/// Whether [name] carries a date stamp [stripNameDate] would remove.
bool hasNameDate(String name) => stripNameDate(name) != name;

/// [stripNameDate] applied to a file name's base, preserving its extension.
///
/// `2026-08-02 - Teardrop.wav` → `Teardrop.wav`. Used for share filenames,
/// where the extension decides whether the receiving app will even open the
/// attachment.
String stripNameDateKeepingExtension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  // No dot, a leading dot only (`.hidden`), or a trailing dot: nothing that
  // behaves like an extension, so treat the whole string as the base.
  if (dot <= 0 || dot == fileName.length - 1) return stripNameDate(fileName);

  final base = fileName.substring(0, dot);
  return '${stripNameDate(base)}${fileName.substring(dot)}';
}
