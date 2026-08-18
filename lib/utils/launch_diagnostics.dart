/// Diagnostics for the "Launch in DAW" pipeline.
///
/// The launch path had exactly one form of instrumentation — `kDebugMode
/// print` — which is compiled out of the release builds testers actually
/// run, so a "nothing happens when I click Open in DAW" report from
/// Windows 11 arrived with no evidence attached at all. This records each
/// step of an attempt instead, to two places:
///
/// * An always-on, bounded in-memory buffer ([report]), so the failure
///   snackbar can offer the tester a "Details" dialog to copy without them
///   having to have turned anything on beforehand.
/// * [sink], wired in `main.dart` to `CrashLogger.log`, which persists to
///   the diagnostic log file *if* the user enabled diagnostic logging in
///   Settings. Kept as an injected callback rather than a direct import so
///   this file stays free of `dart:io` — `file_launcher.dart` imports it
///   and has a web stub to keep clean.
///
/// Deliberately free of any `kDebugMode` guard: the whole point is that
/// these records exist in a release build.
library;

/// A cause the diagnostics were able to identify outright, as opposed to
/// evidence a human still has to read. Kept as an enum rather than a
/// message so the UI can localise it — see `launchFailureNoAssociation`.
enum LaunchFailureCause {
  /// Windows has no application registered for the project's file type, so
  /// there is nothing for the shell to open it with. The single most likely
  /// explanation for a "Failed to launch" with no other symptom: DAWs that
  /// install per-user, or that were installed before a Windows upgrade,
  /// routinely leave their own extension unclaimed.
  noFileAssociation,
}

/// Records the steps of "launch in DAW" attempts. All members are static —
/// there is one launch pipeline and one buffer for it.
class LaunchDiagnostics {
  LaunchDiagnostics._();

  /// How many entries the in-memory buffer keeps before dropping the
  /// oldest. A single attempt writes well under ten, so this holds many
  /// attempts' worth of history while staying trivially small.
  static const int maxEntries = 200;

  static final List<String> _entries = <String>[];

  /// Optional persistent destination for every recorded entry, set once at
  /// startup. Never called for the buffer's own bookkeeping.
  static void Function(String entry)? sink;

  /// A cause identified during this attempt, if any, and the detail that
  /// names it (for [LaunchFailureCause.noFileAssociation], the extension).
  /// The failure UI states this in the user's own language instead of
  /// leaving them to find `openCommand=null` in the log.
  static LaunchFailureCause? probableCause;
  static String? probableCauseDetail;

  /// Notes a cause and writes it into the log too, so a pasted report leads
  /// with the finding rather than burying it.
  static void recordCause(LaunchFailureCause cause, String detail) {
    probableCause = cause;
    probableCauseDetail = detail;
    record('DIAGNOSIS', {'cause': cause.name, 'detail': detail});
  }

  /// Formats one entry. Pure — exposed for testing.
  ///
  /// [fields] renders as `key=value` pairs; a null value renders as
  /// `key=null` rather than being dropped, since "we looked and there was
  /// nothing there" is itself a finding worth having in a bug report.
  static String formatEntry(
    DateTime timestamp,
    String step, [
    Map<String, Object?>? fields,
  ]) {
    final buffer = StringBuffer()
      ..write(timestamp.toIso8601String())
      ..write(' [launch] ')
      ..write(step);
    if (fields != null && fields.isNotEmpty) {
      for (final entry in fields.entries) {
        buffer.write(' ${entry.key}=${entry.value}');
      }
    }
    return buffer.toString();
  }

  /// Records [step] with optional [fields]. Never throws — a failure to log
  /// a launch must not break the launch.
  static void record(String step, [Map<String, Object?>? fields]) {
    final entry = formatEntry(DateTime.now(), step, fields);
    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    try {
      sink?.call(entry);
    } catch (_) {}
  }

  /// The buffered entries, oldest first.
  static List<String> get entries => List.unmodifiable(_entries);

  /// Every buffered entry as one block of text, for the "Details" dialog's
  /// copy button.
  static String get report => _entries.join('\n');

  /// Drops the buffer and any identified cause. Called at the start of each
  /// attempt so the dialog shows that attempt rather than an accumulated
  /// history the tester would have to read backwards — and so a cause found
  /// last time is never reported against this time.
  static void clear() {
    _entries.clear();
    probableCause = null;
    probableCauseDetail = null;
  }

  /// A one-line summary of the properties of [path] that are known to break
  /// launching on Windows, so a report says *why* a path is unusual instead
  /// of just quoting it (and quoting it is not always enough — a trailing
  /// space or a right-to-left mark is invisible in a pasted log).
  ///
  /// Pure — exposed for testing.
  static Map<String, Object?> describePath(String path) {
    final trimmed = path.trimRight();
    return {
      'length': path.length,
      // Windows' legacy MAX_PATH. Paths at or over it fail in APIs that
      // haven't opted into long-path support, which includes plenty of DAWs.
      'overMaxPath': path.length >= 260,
      'ext': _extensionOf(path),
      // '#' routes the launch through ShellExecuteW directly rather than
      // url_launcher — see windowsNeedsDirectShellExecute. '%' does not on
      // this version and is a known cause of failed launches here: it
      // survives Uri.file's encoding as '%25' and gets percent-decoded a
      // second time, so "My%20Track.cpr" is looked up as "My Track.cpr".
      'hasHash': path.contains('#'),
      'hasPercent': path.contains('%'),
      'nonAscii': path.runes.any((r) => r > 127),
      'unc': path.startsWith(r'\\'),
      'trailingSpaceOrDot': trimmed != path || path.endsWith('.'),
      'forwardSlashes': path.contains('/'),
    };
  }

  static String _extensionOf(String path) {
    final lastDot = path.lastIndexOf('.');
    final lastSeparator = path.lastIndexOf(RegExp(r'[/\\]'));
    if (lastDot <= lastSeparator + 1) return '';
    return path.substring(lastDot).toLowerCase();
  }

  /// Decodes a `ShellExecuteW` return value into something a bug report can
  /// be read from. Per the Win32 documentation any value greater than 32 is
  /// success; the codes at or below it are a mix of `ERROR_*` and `SE_ERR_*`
  /// constants that share numeric space.
  ///
  /// [kShellExecuteNoAssociation] (31) is the one to look for first on a
  /// "nothing happens" report: it means Windows has no application
  /// registered for the project's file type at all.
  ///
  /// Pure — exposed for testing.
  static String describeShellExecuteResult(int code) {
    if (code > 32) return 'success';
    switch (code) {
      case 0:
        return 'SE_ERR_OOM: out of memory or resources';
      case 2:
        return 'SE_ERR_FNF: file not found';
      case 3:
        return 'SE_ERR_PNF: path not found';
      case 5:
        return 'SE_ERR_ACCESSDENIED: access denied';
      case 8:
        return 'SE_ERR_OOM: out of memory';
      case 11:
        return 'ERROR_BAD_FORMAT: invalid executable';
      case 26:
        return 'SE_ERR_SHARE: sharing violation';
      case 27:
        return 'SE_ERR_ASSOCINCOMPLETE: file association is incomplete or invalid';
      case 28:
        return 'SE_ERR_DDETIMEOUT: DDE transaction timed out';
      case 29:
        return 'SE_ERR_DDEFAIL: DDE transaction failed';
      case 30:
        return 'SE_ERR_DDEBUSY: DDE transaction busy';
      case kShellExecuteNoAssociation:
        return 'SE_ERR_NOASSOC: no application is associated with this file type';
      case 32:
        return 'SE_ERR_DLLNOTFOUND: required DLL not found';
      default:
        return 'unknown failure code';
    }
  }

  /// `SE_ERR_NOASSOC` — no registered handler for the file type.
  static const int kShellExecuteNoAssociation = 31;
}
