import 'package:flutter/material.dart';
import '../../services/audio_analysis_service.dart';

/// Renders a min/max envelope waveform with playback progress coloring.
/// Tap or drag anywhere to seek (calls [onSeek] with a 0–1 position).
///
/// [height] can be a fixed pixel value or null to fill the available height
/// from the parent (use inside an [Expanded] or constrained box).
class WaveformWidget extends StatelessWidget {
  final WaveformPeaks? peaks;
  final double progress; // 0..1
  final ValueChanged<double>? onSeek;
  final Color? playedColor;
  final Color? unplayedColor;
  /// Fixed height in pixels. Pass null to fill the parent's available height.
  final double? height;

  const WaveformWidget({
    super.key,
    required this.peaks,
    required this.progress,
    this.onSeek,
    this.playedColor,
    this.unplayedColor,
    this.height = 64,
  });

  void _handleSeek(double dx, double width) {
    onSeek?.call((dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final played = playedColor ?? Theme.of(context).colorScheme.primary;
    final unplayed = unplayedColor ?? played.withValues(alpha: 0.3);

    if (peaks == null) {
      // No peaks yet — show a seekable thin progress bar so the user can
      // still seek while the waveform is being extracted in the background.
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = height ?? constraints.maxHeight;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: onSeek != null ? (d) => _handleSeek(d.localPosition.dx, w) : null,
            onHorizontalDragUpdate: onSeek != null ? (d) => _handleSeek(d.localPosition.dx, w) : null,
            child: SizedBox(
              height: h,
              child: Center(
                child: SizedBox(
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1.5),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: unplayed,
                      color: played,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = height ?? constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handleSeek(d.localPosition.dx, w),
          onHorizontalDragUpdate: (d) => _handleSeek(d.localPosition.dx, w),
          child: SizedBox(
            height: h,
            width: w,
            child: CustomPaint(
              painter: _WaveformPainter(
                peaks: peaks!,
                progress: progress,
                playedColor: played,
                unplayedColor: unplayed,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final WaveformPeaks peaks;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  const _WaveformPainter({
    required this.peaks,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  Path _buildPath(Size size) {
    final count = peaks.frameCount;
    if (count == 0) return Path();
    final middle = size.height / 2;
    final dx = size.width / count;

    final path = Path();
    path.moveTo(0, middle);
    for (int i = 0; i < count; i++) {
      path.lineTo(dx * i, middle - middle * peaks.maxValues[i]);
    }
    path.lineTo(size.width, middle);
    for (int i = count - 1; i >= 0; i--) {
      path.lineTo(dx * i, middle - middle * peaks.minValues[i]);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = unplayedColor;

    canvas.drawPath(path, paint);

    if (progress > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
      canvas.drawPath(path, paint..color = playedColor);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.peaks != peaks ||
      old.progress != progress ||
      old.playedColor != playedColor ||
      old.unplayedColor != unplayedColor;
}
