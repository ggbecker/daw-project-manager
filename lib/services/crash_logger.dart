import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../utils/app_paths.dart';
import '../utils/file_launcher.dart';
import '../utils/mobile_utils.dart';

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

  /// Whether [log] actually writes anything. Defaults to **off** — opt-in,
  /// not opt-out. Settings can turn this on via [setEnabled] — backed by a
  /// persisted device-local preference (`diagnosticLoggingEnabledProvider`
  /// in providers.dart). CrashLogger stays Riverpod-agnostic on purpose:
  /// [installGlobalHandlers] wires it into
  /// `FlutterError.onError`/`PlatformDispatcher.onError`, which can fire
  /// before any `ProviderScope` exists, so it can't read a provider itself
  /// — the provider pushes its loaded value in instead.
  static bool _enabled = false;

  static void setEnabled(bool enabled) => _enabled = enabled;

  static bool get isEnabled => _enabled;

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
  /// whatever error-reporting path called it. No-ops entirely when
  /// [isEnabled] is false.
  static Future<void> log(String source, Object error, [StackTrace? stack]) async {
    if (!_enabled) return;
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

  /// Gets [files] in front of the user: on desktop, always just opens their
  /// containing folder in the system file manager — native OS sharing turns
  /// out unusable on every desktop platform (Linux: share_plus has no
  /// file-sharing implementation there at all, `SharePlusLinuxPlugin.share`
  /// unconditionally throws `UnimplementedError` for any call that includes
  /// files; Windows: the `DataTransferManager` share flyout opens but fails
  /// inside its own UI — "Try that again, we couldn't show all the ways you
  /// could share" — for an unpackaged build, and can't be caught from Dart
  /// since share_plus's native Windows plugin reports success back to Dart
  /// the instant it *dispatches* the flyout, not once it resolves; macOS's
  /// share sheet works but there's no reason to keep the extra native-share
  /// code path alive on desktop just for one platform when "open the
  /// folder" is simpler and works everywhere). On mobile, where there's no
  /// equivalent to a file manager reveal, this still uses the native share
  /// sheet, falling back to opening the folder only if that's genuinely
  /// unavailable.
  /// Returns true if the OS share sheet was actually shown, false if it
  /// opened the folder instead. [files] must be non-empty.
  static Future<bool> shareOrRevealLogFiles(List<File> files) async {
    assert(files.isNotEmpty);
    ShareResultStatus? status;
    if (nativeFileShareSheetSupported(isMobile: MobileUtils.isMobile())) {
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
  /// this platform — true only on mobile (see [shareOrRevealLogFiles]'s doc
  /// comment for why desktop always skips straight to the folder-reveal
  /// fallback instead). Split out as a pure function — exposed for testing
  /// — since `MobileUtils.isMobile()` isn't a compile-time constant and
  /// can't be used as a default parameter value.
  @visibleForTesting
  static bool nativeFileShareSheetSupported({required bool isMobile}) => isMobile;

  /// Whether [shareOrRevealLogFiles] should fall back to the folder-reveal
  /// path, given the [ShareResultStatus] it got back (null if the share
  /// call was skipped or threw). Split out as a pure function — exposed for
  /// testing — because `Share.shareXFiles` itself hits a real platform
  /// channel and `FileLauncher.openFolder`'s fallback spawns a real OS
  /// process, neither of which should run during `flutter test`.
  @visibleForTesting
  static bool shareSheetUnavailable(ShareResultStatus? status) =>
      status == null || status == ShareResultStatus.unavailable;

  /// Deletes any diagnostic log files that currently exist on disk. Used by
  /// the Settings "Clear Diagnostic Log" action. Safe to call even when
  /// nothing exists yet — logging (if still enabled) simply recreates the
  /// file on the next entry, since [appendToFile] creates it if absent.
  static Future<void> clearLogs() async {
    final file = await logFile();
    if (await file.exists()) await file.delete();
    final native = await nativeLogFile();
    if (await native.exists()) await native.delete();
  }

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
