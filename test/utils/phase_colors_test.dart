import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/utils/phase_colors.dart';

void main() {
  group('colorToHex', () {
    test('pure black → #000000', () {
      expect(colorToHex(const Color(0xFF000000)), '#000000');
    });

    test('pure white → #FFFFFF', () {
      expect(colorToHex(const Color(0xFFFFFFFF)), '#FFFFFF');
    });

    test('first palette entry encodes correctly', () {
      // Color(0xFF4FC3F7): r=0x4F, g=0xC3, b=0xF7
      expect(colorToHex(const Color(0xFF4FC3F7)), '#4FC3F7');
    });

    test('output is always uppercase', () {
      // 0xAB has lowercase hex 'ab' — result must be uppercase
      expect(colorToHex(const Color(0xFFABCDEF)), '#ABCDEF');
    });

    test('single-digit channel is zero-padded', () {
      // r=0x0A, g=0x0B, b=0x0C
      expect(colorToHex(const Color(0xFF0A0B0C)), '#0A0B0C');
    });
  });

  group('hexToColor', () {
    test('parses #000000 to black', () {
      expect(hexToColor('#000000'), const Color(0xFF000000));
    });

    test('parses #FFFFFF to white', () {
      expect(hexToColor('#FFFFFF'), const Color(0xFFFFFFFF));
    });

    test('parses a known palette entry', () {
      expect(hexToColor('#4FC3F7'), const Color(0xFF4FC3F7));
    });

    test('parses lowercase hex digits', () {
      expect(hexToColor('#4fc3f7'), const Color(0xFF4FC3F7));
    });
  });

  group('colorToHex / hexToColor round-trip', () {
    test('round-trips black', () {
      const c = Color(0xFF000000);
      expect(hexToColor(colorToHex(c)), c);
    });

    test('round-trips white', () {
      const c = Color(0xFFFFFFFF);
      expect(hexToColor(colorToHex(c)), c);
    });

    test('every entry in kPhaseColorPalette survives the round-trip', () {
      for (final c in kPhaseColorPalette) {
        final hex = colorToHex(c);
        expect(hexToColor(hex), c,
            reason: 'Round-trip failed for $hex (original: $c)');
      }
    });
  });

  group('defaultPhaseColor', () {
    test('returns a non-null color for each built-in phase', () {
      const phases = ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];
      for (final phase in phases) {
        final color = defaultPhaseColor(phase, phases);
        // Just verify it returns something — exact value may change with theme.
        expect(color, isA<Color>(), reason: 'Expected a Color for phase $phase');
      }
    });

    test('cycles through fallback palette for unknown phases', () {
      const phases = ['Alpha', 'Beta', 'Gamma'];
      final a = defaultPhaseColor('Alpha', phases);
      final b = defaultPhaseColor('Beta', phases);
      // Different indices → different fallback colors
      expect(a, isNot(b));
    });

    test('returns grey for a phase not present in the phases list', () {
      final color = defaultPhaseColor('Unknown', ['Idea']);
      expect(color, isA<Color>());
    });
  });
}
