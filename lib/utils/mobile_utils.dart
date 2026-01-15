import 'dart:io';
import 'package:flutter/material.dart';

/// Utility class to help with mobile-specific UI adaptations
class MobileUtils {
  /// Check if the app is running on a mobile platform (Android or iOS)
  static bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check if the app is running on Android
  static bool isAndroid() {
    return Platform.isAndroid;
  }

  /// Check if the app is running on iOS
  static bool isIOS() {
    return Platform.isIOS;
  }

  /// Check if the app is running on desktop (Windows, macOS, or Linux)
  static bool isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile()) {
      return const EdgeInsets.all(12.0);
    }
    return const EdgeInsets.all(16.0);
  }

  /// Get responsive horizontal padding
  static double getResponsiveHorizontalPadding(BuildContext context) {
    if (isMobile()) {
      return 12.0;
    }
    return 16.0;
  }

  /// Check if screen is small (mobile)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if screen is medium (tablet)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// Check if screen is large (desktop)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }
}

