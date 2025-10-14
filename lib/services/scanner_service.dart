import 'dart:io';

import 'package:path/path.dart' as p;

class ScannerService {
  static const supportedExtensions = {
    '.als', // Ableton
    '.cpr', // Cubase
    '.flp', // FL Studio
    '.logicx', // Logic Pro (bundle on macOS)
  };

  Stream<FileSystemEntity> scanDirectory(String rootPath) async* {
    final directory = Directory(rootPath);
    if (!await directory.exists()) return;

    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (supportedExtensions.contains(ext)) {
          yield entity;
        }
      } else if (entity is Directory) {
        // Logic Pro projects present as .logicx bundles (directories)
        if (entity.path.toLowerCase().endsWith('.logicx')) {
          yield entity;
        }
      }
    }
  }
}


