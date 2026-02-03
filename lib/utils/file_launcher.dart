import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utilities for launching files and folders in the system file manager
class FileLauncher {
  /// Open a folder in the system file manager
  static Future<bool> openFolder(String folderPath) async {
    try {
      if (kDebugMode) print('[FileLauncher] Opening folder: $folderPath');
      
      // Ensure the folder exists
      if (!await Directory(folderPath).exists()) {
        if (kDebugMode) print('[FileLauncher] ERROR: Folder does not exist');
        return false;
      }
      
      // Use url_launcher with file:// URI
      final uri = Uri.file(folderPath);
      
      if (kDebugMode) print('[FileLauncher] Launching URI: $uri');
      
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (kDebugMode) print('[FileLauncher] Launch result: $launched');
      return launched;
    } catch (e) {
      if (kDebugMode) print('[FileLauncher] ERROR opening folder: $e');
      return false;
    }
  }
  
  /// Open a file with the default system application
  static Future<bool> openFile(String filePath) async {
    try {
      if (kDebugMode) print('[FileLauncher] Opening file: $filePath');
      
      // Ensure the file exists
      if (!await File(filePath).exists()) {
        if (kDebugMode) print('[FileLauncher] ERROR: File does not exist');
        return false;
      }
      
      // Use url_launcher with file:// URI
      final uri = Uri.file(filePath);
      
      if (kDebugMode) print('[FileLauncher] Launching URI: $uri');
      
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (kDebugMode) print('[FileLauncher] Launch result: $launched');
      return launched;
    } catch (e) {
      if (kDebugMode) print('[FileLauncher] ERROR opening file: $e');
      return false;
    }
  }
  
  /// Launch a project file (DAW project, audio file, etc.)
  static Future<bool> launchProject(String projectPath) async {
    return await openFile(projectPath);
  }
}
