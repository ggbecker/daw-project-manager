import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../utils/app_paths.dart';
import '../utils/file_launcher.dart';

/// Captures uncaught Dart errors and app lifecycle transitions to a small
/// rotating log file on disk, so a crash that happens while the app is
/// backgrounded (and would otherwise just show a generic "something went
/// wrong" screen) leaves a trace the user can retrieve and share.
///
/// This only sees Dart-level exceptions — a native-level crash (the OS
/// killing the process) happens outside the Dart VM and can't be caught
/// here.
class CrashLogger {
  CrashLogger._();

  static const int maxLogBytes = 512 * 1024;

  static File? _cachedFile;

  static Future<File> _resolveFile() async {
    final cached = _cachedFile;
    if (cached != null) return cached;
    final dir = Directory(p.join(await getLocalAppDataPath(), 'logs'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'crash_log.txt'));
    _cachedFile = file;
    return file;
  }

  /// Formats one log entry. Pure function — exposed for testing.
  static String formatEntry(
    String source,
    Object error,
    StackTrace? stack,
    DateTime timestamp,
  ) {
    final buffer = StringBuffer()
      ..writeln('--- ${timestamp.toIso8601String()} [$source] ---')
      ..writeln(error.toString());
    if (stack != null) buffer.writeln(stack.toString());
    return buffer.toString();
  }

  /// Appends [entry] to [file], truncating first if the file has grown past
  /// [maxBytes] so the log can't grow unbounded on a device that's never
  /// force-quit. Exposed for testing against a temp file.
  static Future<void> appendToFile(
    File file,
    String entry, {
    int maxBytes = maxLogBytes,
  }) async {
    if (await file.exists() && await file.length() > maxBytes) {
      await file.writeAsString('', mode: FileMode.write);
    }
    await file.writeAsString(entry, mode: FileMode.append, flush: true);
  }

  /// Logs an error. Never throws — a failure here must not take down
  /// whatever error-reporting path called it.
  static Future<void> log(String source, Object error, [StackTrace? stack]) async {
    try {
      final file = await _resolveFile();
      await appendToFile(file, formatEntry(source, error, stack, DateTime.now()));
    } catch (_) {}
  }

  static Future<void> logLifecycle(AppLifecycleState state) =>
      log('lifecycle', 'App lifecycle state changed to ${state.name}');

  static Future<String> readLog() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return '';
      return await file.readAsString();
    } catch (_) {
      return '';
    }
  }

  static Future<File> logFile() => _resolveFile();

  /// The native (JVM-level) crash log written by MainActivity.kt on Android,
  /// for exceptions that never reach Dart at all. Empty/absent on other
  /// platforms and on Android installs that haven't crashed natively.
  static Future<File> nativeLogFile() async {
    final file = await _resolveFile();
    return File(p.join(p.dirname(file.path), 'native_crash_log.txt'));
  }

  /// All diagnostic log files that currently exist on disk, for sharing.
  static Future<List<File>> existingLogFiles() async {
    final files = [await logFile(), await nativeLogFile()];
    final existing = <File>[];
    for (final file in files) {
      if (await file.exists() && await file.length() > 0) existing.add(file);
    }
    return existing;
  }

  /// Shares [files] via the OS share sheet, falling back to just opening
  /// their containing folder in the system file manager when the share
  /// sheet isn't actually usable. Two known cases skip the native share
  /// attempt entirely (see [nativeFileShareSheetSupported]):
  /// - **Linux**: share_plus has no file-sharing implementation there at
  ///   all — `SharePlusLinuxPlugin.share` unconditionally throws
  ///   `UnimplementedError` for any call that includes files, every time.
  /// - **Windows**: the `DataTransferManager` share flyout does open for an
  ///   unpackaged build, but fails inside its own UI ("Try that again, we
  ///   couldn't show all the ways you could share") instead of cleanly
  ///   returning `ShareResultStatus.unavailable` — confirmed by hand, not
  ///   just inferred from `DragToShareButton`'s doc comment, which
  ///   undersold how broken this actually is. Since there's no reliable
  ///   signal to detect that failure from Dart, the native call is never
  ///   attempted on Windows at all.
  /// A thrown exception or `ShareResultStatus.unavailable` on any other
  /// platform falls back the same way, as a safety net.
  /// Returns true if the OS share sheet was actually shown, false if it
  /// fell back to opening the folder instead. [files] must be non-empty.
  static Future<bool> shareOrRevealLogFiles(List<File> files) async {
    assert(files.isNotEmpty);
    ShareResultStatus? status;
    if (nativeFileShareSheetSupported(isWindows: Platform.isWindows, isLinux: Platform.isLinux)) {
      try {
        status = (await Share.shareXFiles(files.map((f) => XFile(f.path)).toList())).status;
      } catch (_) {
        // Falls through to the folder-reveal fallback below.
      }
    }
    if (!shareSheetUnavailable(status)) return true;
    await FileLauncher.openFolder(p.dirname(files.first.path));
    return false;
  }

  /// Whether it's even worth attempting [Share.shareXFiles] for files on
  /// this platform — false for Linux and Windows (see
  /// [shareOrRevealLogFiles]'s doc comment for why both are unusable in
  /// practice). Split out as a pure function — exposed for testing — since
  /// `Platform.isWindows`/`Platform.isLinux` aren't compile-time constants
  /// and can't be used as default parameter values.
  @visibleForTesting
  static bool nativeFileShareSheetSupported({required bool isWindows, required bool isLinux}) =>
      !isWindows && !isLinux;

  /// Whether [shareOrRevealLogFiles] should fall back to the folder-reveal
  /// path, given the [ShareResultStatus] it got back (null if the share
  /// call was skipped or threw). Split out as a pure function — exposed for
  /// testing — because `Share.shareXFiles` itself hits a real platform
  /// channel and `FileLauncher.openFolder`'s fallback spawns a real OS
  /// process, neither of which should run during `flutter test`.
  @visibleForTesting
  static bool shareSheetUnavailable(ShareResultStatus? status) =>
      status == null || status == ShareResultStatus.unavailable;

  /// Installs global handlers so uncaught framework errors (build/layout/paint)
  /// and errors escaping the root zone are written to disk instead of only
  /// flashing on screen (or, in release mode, failing silently).
  static void installGlobalHandlers() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      unawaited(log('flutter', details.exceptionAsString(), details.stack));
      previousOnError?.call(details);
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      unawaited(log('platform', error, stack));
      return true;
    };
  }
}
