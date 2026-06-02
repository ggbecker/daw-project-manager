import 'package:flutter/material.dart';

/// Pre-defined color palette offered in the phase color picker.
const List<Color> kPhaseColorPalette = [
  Color(0xFF4FC3F7), // light blue
  Color(0xFF1E88E5), // blue
  Color(0xFF26A69A), // teal
  Color(0xFF66BB6A), // green
  Color(0xFF9CCC65), // light green
  Color(0xFFFFCA28), // amber
  Color(0xFFFF7043), // deep orange
  Color(0xFFEF5350), // red
  Color(0xFFEC407A), // pink
  Color(0xFFBA68C8), // purple
  Color(0xFF7986CB), // indigo
  Color(0xFF26C6DA), // cyan
  Color(0xFFFF8A65), // salmon
  Color(0xFF7E57C2), // deep purple
  Color(0xFFD4E157), // lime
  Color(0xFF90A4AE), // blue grey
];

/// Fallback palette cycled for user-defined phases that have no stored color.
const List<Color> _fallbackPalette = [
  Color(0xFF4DB6AC),
  Color(0xFF4DD0E1),
  Color(0xFFFFD54F),
  Color(0xFFFF8A65),
  Color(0xFF7986CB),
  Color(0xFFA5D6A7),
  Color(0xFFF48FB1),
  Color(0xFFCE93D8),
];

/// Default color for [phase] when no user preference is stored.
Color defaultPhaseColor(String phase, List<String> phases) {
  switch (phase) {
    case 'Idea':
      return Colors.blue.shade300;
    case 'Arranging':
      return Colors.orange.shade300;
    case 'Mixing':
      return Colors.purple.shade300;
    case 'Mastering':
      return Colors.pink.shade300;
    case 'Finished':
      return Colors.green.shade300;
    default:
      final idx = phases.indexOf(phase);
      return idx >= 0
          ? _fallbackPalette[idx % _fallbackPalette.length]
          : Colors.grey.shade400;
  }
}

/// Returns [stored] color for [phase] if present, otherwise the default.
Color resolvePhaseColor(
  String phase,
  Map<String, Color> stored,
  List<String> phases,
) =>
    stored[phase] ?? defaultPhaseColor(phase, phases);

/// Converts a [Color] to a '#RRGGBB' hex string.
String colorToHex(Color c) {
  final r = (c.r * 255).round();
  final g = (c.g * 255).round();
  final b = (c.b * 255).round();
  return '#'
      '${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
}

/// Parses a '#RRGGBB' hex string back to a [Color].
Color hexToColor(String hex) => Color(int.parse('0xFF${hex.substring(1)}'));
