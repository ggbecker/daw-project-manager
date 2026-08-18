import 'dart:io';

import 'package:win32_registry/win32_registry.dart';

/// Reads, without changing anything, what Windows would actually do with a
/// given file extension.
///
/// "Launch in DAW" ultimately hands the project file to the shell and asks
/// it to open it with whatever is registered for that file type. When that
/// silently does nothing, the question that decides everything is whether
/// anything is registered at all — a fresh Windows 11 install with, say,
/// Cubase installed per-user, or a DAW installed after the last time
/// associations were written, can leave `.cpr` pointing at nothing. That is
/// invisible from the launch result alone: the shell reports the same
/// "didn't work" either way.
///
/// Every lookup here is a read of `HKCU`/`HKCR`. Nothing is written, so
/// running this on a tester's machine cannot change how their files open.
class WindowsFileAssociation {
  WindowsFileAssociation._();

  /// The per-user "always open with" choices, which take precedence over the
  /// machine-wide association for an extension.
  static const _fileExtsPath =
      r'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts';

  /// What Windows has registered for [extension] (given with its leading
  /// dot, e.g. `.cpr`), or null when not running on Windows.
  ///
  /// Resolution follows the same order the shell does: the user's explicit
  /// choice under `FileExts\[ext]\UserChoice` wins over the machine-wide
  /// default in `HKEY_CLASSES_ROOT\[ext]`.
  static Map<String, Object?>? describe(String extension) {
    if (!Platform.isWindows) return null;
    if (extension.isEmpty) {
      return {'ext': '(none)', 'note': 'path has no file extension'};
    }

    final userChoice = _readValue(
      RegistryHive.currentUser,
      '$_fileExtsPath\\$extension\\UserChoice',
      'ProgId',
    );
    final classDefault = _readValue(RegistryHive.classesRoot, extension, '');
    final progId = userChoice ?? classDefault;

    return {
      'ext': extension,
      'userChoiceProgId': userChoice,
      'classesRootProgId': classDefault,
      'openCommand': progId == null
          ? null
          : _readValue(
              RegistryHive.classesRoot,
              '$progId\\shell\\open\\command',
              '',
            ),
    };
  }

  /// Whether [described] — a map from [describe] — shows nothing registered
  /// to open the file type. True means the shell has no handler to hand the
  /// project to, which is enough on its own to explain a failed launch.
  ///
  /// Requires *every* route to have come back empty: a ProgId with no
  /// `shell\open\command` under it is broken rather than absent, and says
  /// something different about the machine, so it is not folded in here.
  ///
  /// Pure — exposed for testing.
  static bool hasNoHandler(Map<String, Object?> described) =>
      described['userChoiceProgId'] == null &&
      described['classesRootProgId'] == null &&
      described['openCommand'] == null;

  /// Reads a single string value, treating "the key or value isn't there"
  /// as null rather than as an error — an absent association is the normal,
  /// expected finding here, not an exceptional one.
  static String? _readValue(RegistryHive hive, String path, String valueName) {
    RegistryKey? key;
    try {
      key = Registry.openPath(hive, path: path);
      return key.getStringValue(valueName);
    } catch (_) {
      return null;
    } finally {
      try {
        key?.close();
      } catch (_) {}
    }
  }
}
