import 'package:flutter/material.dart';

import '../../utils/mobile_utils.dart';

/// A multi-line [TextFormField] with two ways to grow: an expand/collapse
/// toggle that jumps between [initialHeight] and [expandedHeight], and a
/// drag handle in the bottom-right corner for manual resizing. Used for
/// long free-text fields (project notes, release descriptions) where a
/// fixed `maxLines` is either too cramped or wastes space most of the time.
///
/// The drag handle relies on a pointer that can hover/precisely grab a 20x20
/// corner, which does not work with touch on mobile, so it is hidden there by
/// default ([enableDragResize] defaults to `!MobileUtils.isMobile()`). The
/// tap-based expand/collapse toggle remains available everywhere.
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

  /// Whether to show the bottom-right corner drag handle. Defaults to hidden
  /// on mobile, where a precise corner grab isn't practical with touch.
  final bool enableDragResize;

  /// Whether the field is read-only — used for text extracted from the DAW
  /// project file itself rather than typed by the user, while still keeping
  /// the same expand/collapse and drag-resize affordances as an editable field.
  final bool readOnly;

  ResizableTextField({
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
    this.readOnly = false,
    bool? enableDragResize,
  }) : enableDragResize = enableDragResize ?? !MobileUtils.isMobile();

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
            readOnly: widget.readOnly,
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
        if (widget.enableDragResize)
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

/// Two [ResizableTextField]-style boxes side by side sharing a single
/// height/expand state, for cases like the project description sitting next
/// to its read-only DAW-extracted notes — using two independent
/// [ResizableTextField]s there let one grow while the other stayed put,
/// which read as broken rather than as two separate boxes. There is exactly
/// one expand button and one drag grip for the pair, not one per field.
class SyncedResizableTextFieldPair extends StatefulWidget {
  final TextEditingController leftController;
  final FocusNode? leftFocusNode;
  final String leftLabelText;
  final bool leftReadOnly;
  final ValueChanged<String>? leftOnChanged;

  final TextEditingController rightController;
  final String rightLabelText;
  final bool rightReadOnly;

  final String expandTooltip;
  final String collapseTooltip;
  final double initialHeight;
  final double expandedHeight;
  final double minHeight;
  final double maxHeight;
  final bool enableDragResize;

  SyncedResizableTextFieldPair({
    super.key,
    required this.leftController,
    this.leftFocusNode,
    required this.leftLabelText,
    this.leftReadOnly = false,
    this.leftOnChanged,
    required this.rightController,
    required this.rightLabelText,
    this.rightReadOnly = false,
    required this.expandTooltip,
    required this.collapseTooltip,
    this.initialHeight = 130,
    this.expandedHeight = 400,
    this.minHeight = 100,
    this.maxHeight = 800,
    bool? enableDragResize,
  }) : enableDragResize = enableDragResize ?? !MobileUtils.isMobile();

  @override
  State<SyncedResizableTextFieldPair> createState() =>
      _SyncedResizableTextFieldPairState();
}

class _SyncedResizableTextFieldPairState
    extends State<SyncedResizableTextFieldPair> {
  late double _height = widget.initialHeight;
  bool _expanded = false;

  Widget _field({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String labelText,
    required bool readOnly,
    ValueChanged<String>? onChanged,
    required bool showControls,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      expands: true,
      minLines: null,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        labelText: labelText,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.fromLTRB(12, 20, showControls ? 32 : 12, 20),
        suffixIcon: showControls
            ? Align(
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
              )
            : null,
      ),
      keyboardType: TextInputType.multiline,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          key: const Key('syncedResizableTextFieldHeightBox'),
          height: _height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _field(
                  controller: widget.leftController,
                  focusNode: widget.leftFocusNode,
                  labelText: widget.leftLabelText,
                  readOnly: widget.leftReadOnly,
                  onChanged: widget.leftOnChanged,
                  showControls: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                  controller: widget.rightController,
                  labelText: widget.rightLabelText,
                  readOnly: widget.rightReadOnly,
                  showControls: true,
                ),
              ),
            ],
          ),
        ),
        if (widget.enableDragResize)
          Positioned(
            right: 2,
            bottom: 2,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              child: GestureDetector(
                key: const Key('syncedResizableTextFieldGrip'),
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
