import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Camelot wheel visualiser.
///
/// Shows all 24 positions (12 × minor A-ring + 12 × major B-ring).
/// The [activeCode] position is fully lit; its [compatibleCodes] are
/// softly highlighted; everything else is dimmed.
class CamelotWheelWidget extends StatelessWidget {
  const CamelotWheelWidget({
    super.key,
    required this.activeCode,
    this.compatibleCodes = const [],
    this.size = 220,
  });

  final String activeCode;
  final List<String> compatibleCodes;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CamelotWheelPainter(
          activeCode: activeCode,
          compatibleCodes: compatibleCodes,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Static wheel data — positions 1-12, [minorLabel, majorLabel]
// ─────────────────────────────────────────────────────────────────────────────
const _keyLabels = [
  ['G♯m', 'B'],   // 1
  ['D♯m', 'F♯'],  // 2
  ['A♯m', 'C♯'],  // 3
  ['Fm',  'A♭'],  // 4
  ['Cm',  'E♭'],  // 5
  ['Gm',  'B♭'],  // 6
  ['Dm',  'F'],   // 7
  ['Am',  'C'],   // 8
  ['Em',  'G'],   // 9
  ['Bm',  'D'],   // 10
  ['F♯m', 'A'],   // 11
  ['C♯m', 'E'],   // 12
];

class _CamelotWheelPainter extends CustomPainter {
  _CamelotWheelPainter({
    required this.activeCode,
    required this.compatibleCodes,
    required this.isDark,
  });

  final String activeCode;
  final List<String> compatibleCodes;
  final bool isDark;

  // Geometry constants (as fraction of maxRadius)
  static const _holeRatio  = 0.17;
  static const _splitRatio = 0.50; // inner/outer ring boundary
  static const _outerRatio = 0.90;

  static const _totalSlices = 12;
  static const _fullAngle   = 2 * math.pi / _totalSlices;
  static const _gapFrac     = 0.07;                         // gap as fraction of full slice
  static const _gapAngle    = _fullAngle * _gapFrac;
  static const _sweepAngle  = _fullAngle - _gapAngle;
  // Position 1 at 12 o'clock; offset by half-gap so gap is centred on each boundary
  static const _startBase   = -math.pi / 2 + _gapAngle / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width  / 2;
    final cy     = size.height / 2;
    final center = Offset(cx, cy);
    final maxR   = cx; // widget is square

    final holeR  = maxR * _holeRatio;
    final splitR = maxR * _splitRatio;
    final outerR = maxR * _outerRatio;

    for (int i = 0; i < _totalSlices; i++) {
      final pos      = i + 1;
      final codeA    = '${pos}A';
      final codeB    = '${pos}B';
      final segStart = _startBase + i * _fullAngle;
      final midAngle = segStart + _sweepAngle / 2;
      final hue      = (i * 30.0) % 360;

      final isActiveA = activeCode == codeA;
      final isActiveB = activeCode == codeB;
      final isCompatA = compatibleCodes.contains(codeA);
      final isCompatB = compatibleCodes.contains(codeB);

      // ── Segments ──────────────────────────────────────────────────────────
      _drawSegment(canvas, center, holeR, splitR, segStart, hue,
          active: isActiveA, compat: isCompatA);
      _drawSegment(canvas, center, splitR, outerR, segStart, hue,
          active: isActiveB, compat: isCompatB);

      // ── Labels ────────────────────────────────────────────────────────────
      _drawLabel(canvas, center, holeR, splitR, midAngle, maxR,
          code: codeA, key: _keyLabels[i][0],
          lit: isActiveA || isCompatA, active: isActiveA);
      _drawLabel(canvas, center, splitR, outerR, midAngle, maxR,
          code: codeB, key: _keyLabels[i][1],
          lit: isActiveB || isCompatB, active: isActiveB);
    }

    // ── Ring separator arc (thin) ──────────────────────────────────────────
    canvas.drawCircle(
      center, splitR,
      Paint()
        ..color = (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Centre hole ───────────────────────────────────────────────────────
    canvas.drawCircle(
      center, holeR,
      Paint()..color = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
    );
    // Outer rim
    canvas.drawCircle(
      center, outerR + 1,
      Paint()
        ..color = (isDark ? Colors.black : Colors.white).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawSegment(
    Canvas canvas,
    Offset center,
    double innerR,
    double outerR,
    double startAngle,
    double hue, {
    required bool active,
    required bool compat,
  }) {
    final Color fill;
    if (active) {
      fill = HSLColor.fromAHSL(1, hue, 0.88, isDark ? 0.62 : 0.52).toColor();
    } else if (compat) {
      fill = HSLColor.fromAHSL(1, hue, 0.55, isDark ? 0.42 : 0.68).toColor();
    } else {
      fill = HSLColor.fromAHSL(1, hue, 0.18, isDark ? 0.26 : 0.80).toColor();
    }

    final path = Path()
      ..moveTo(
        center.dx + innerR * math.cos(startAngle),
        center.dy + innerR * math.sin(startAngle),
      )
      ..arcTo(Rect.fromCircle(center: center, radius: innerR),
          startAngle, _sweepAngle, false)
      ..lineTo(
        center.dx + outerR * math.cos(startAngle + _sweepAngle),
        center.dy + outerR * math.sin(startAngle + _sweepAngle),
      )
      ..arcTo(Rect.fromCircle(center: center, radius: outerR),
          startAngle + _sweepAngle, -_sweepAngle, false)
      ..close();

    canvas.drawPath(path, Paint()..color = fill);
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double innerR,
    double outerR,
    double midAngle,
    double maxR, {
    required String code,
    required String key,
    required bool lit,
    required bool active,
  }) {
    final midR   = (innerR + outerR) / 2;
    final lx     = center.dx + midR * math.cos(midAngle);
    final ly     = center.dy + midR * math.sin(midAngle);
    final height = outerR - innerR;

    // Tangential rotation so text follows the arc; flip bottom-half to stay readable.
    double rotation = midAngle + math.pi / 2;
    if (rotation >  math.pi / 2 + 0.001) rotation -= math.pi;
    if (rotation < -math.pi / 2 - 0.001) rotation += math.pi;

    final keySize  = (height * 0.30).clamp(6.5, 11.5);
    final codeSize = (height * 0.21).clamp(5.0,  9.0);
    final maxW     = height - 2;

    final keyColor  = lit
        ? (isDark ? Colors.white       : Colors.black87)
        : (isDark ? Colors.white38     : Colors.black26);
    final codeColor = lit
        ? (isDark ? Colors.white70     : Colors.black54)
        : (isDark ? Colors.white24     : Colors.black12);

    final keyPainter  = _makeTextPainter(key,  keySize,  active ? FontWeight.w700 : FontWeight.w500, keyColor,  maxW);
    final codePainter = _makeTextPainter(code, codeSize, FontWeight.w400, codeColor, maxW);

    final totalH = keyPainter.height + 1.5 + codePainter.height;

    canvas.save();
    canvas.translate(lx, ly);
    canvas.rotate(rotation);
    keyPainter.paint( canvas, Offset(-keyPainter.width  / 2, -totalH / 2));
    codePainter.paint(canvas, Offset(-codePainter.width / 2,  -totalH / 2 + keyPainter.height + 1.5));
    canvas.restore();
  }

  static TextPainter _makeTextPainter(
      String text, double fontSize, FontWeight weight, Color color, double maxWidth) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);
  }

  @override
  bool shouldRepaint(_CamelotWheelPainter old) =>
      old.activeCode != activeCode ||
      old.isDark != isDark ||
      old.compatibleCodes.length != compatibleCodes.length ||
      !_listEquals(old.compatibleCodes, compatibleCodes);

  static bool _listEquals(List<String> a, List<String> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
