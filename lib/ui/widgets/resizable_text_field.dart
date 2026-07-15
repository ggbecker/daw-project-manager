import 'package:flutter/material.dart';

/// A multi-line [TextFormField] with two ways to grow: an expand/collapse
/// toggle that jumps between [initialHeight] and [expandedHeight], and a
/// drag handle in the bottom-right corner for manual resizing. Used for
/// long free-text fields (project notes, release descriptions) where a
/// fixed `maxLines` is either too cramped or wastes space most of the time.
class ResizableTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String expandTooltip;
  final String collapseTooltip;
  final double initialHeight;
  final double expandedHeight;
  final double minHeight;
  final double maxHeight;
  final ValueChanged<String>? onChanged;

  const ResizableTextField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.labelText,
    required this.expandTooltip,
    required this.collapseTooltip,
    this.initialHeight = 130,
    this.expandedHeight = 400,
    this.minHeight = 100,
    this.maxHeight = 800,
    this.onChanged,
  });

  @override
  State<ResizableTextField> createState() => _ResizableTextFieldState();
}

class _ResizableTextFieldState extends State<ResizableTextField> {
  late double _height = widget.initialHeight;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          key: const Key('resizableTextFieldHeightBox'),
          height: _height,
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            expands: true,
            minLines: null,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              labelText: widget.labelText,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.fromLTRB(12, 20, 32, 20),
              suffixIcon: Align(
                alignment: Alignment.topRight,
                widthFactor: 1,
                heightFactor: 1,
                child: IconButton(
                  icon: Icon(_expanded ? Icons.close_fullscreen : Icons.open_in_full),
                  iconSize: 18,
                  tooltip: _expanded ? widget.collapseTooltip : widget.expandTooltip,
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                      _height = _expanded ? widget.expandedHeight : widget.initialHeight;
                    });
                  },
                ),
              ),
            ),
            keyboardType: TextInputType.multiline,
            onChanged: widget.onChanged,
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeUpLeftDownRight,
            child: GestureDetector(
              key: const Key('resizableTextFieldGrip'),
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                setState(() {
                  _height = (_height + details.delta.dy)
                      .clamp(widget.minHeight, widget.maxHeight);
                  _expanded = _height > widget.initialHeight;
                });
              },
              child: SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(
                  painter: _ResizeGripPainter(
                    color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.5) ??
                        Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the classic three-diagonal-line resize grip in the bottom-right
/// corner of a manually resizable text box.
class _ResizeGripPainter extends CustomPainter {
  final Color color;
  const _ResizeGripPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final offset in [4.0, 9.0, 14.0]) {
      canvas.drawLine(
        Offset(size.width - offset, size.height - 2),
        Offset(size.width - 2, size.height - offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ResizeGripPainter oldDelegate) =>
      oldDelegate.color != color;
}
