import 'package:flutter/material.dart';

import '../../models/project_marker.dart';
import '../../utils/playback_todo_utils.dart';

/// The list of timeline markers and regions read out of a DAW project file.
///
/// A session that holds several songs is one row everywhere else in the app;
/// this is the table of contents for it. Tapping an entry jumps the preview
/// player to that position, which is the whole point of indexing them — so
/// when there is nothing to jump in ([onTap] null) the rows stay visible but
/// inert, with [disabledTooltip] explaining why.
///
/// A plain view widget on purpose: it takes a list of markers and label
/// builders rather than a `MusicProject` or a `Ref`, so every state here can
/// be widget-tested without opening Hive or standing up providers.
class ProjectMarkersSection extends StatefulWidget {
  const ProjectMarkersSection({
    super.key,
    required this.markers,
    required this.title,
    required this.unnamedMarkerLabel,
    required this.unnamedRegionLabel,
    required this.showAllLabel,
    required this.collapseLabel,
    this.onTap,
    this.jumpTooltip,
    this.disabledTooltip,
    this.collapsedCount = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final List<ProjectMarker> markers;

  /// Section heading, e.g. "MARKERS".
  final String title;

  /// Fallbacks for entries the user never named. Built here rather than
  /// stored, so an unnamed marker reads in the app's language instead of
  /// whatever locale happened to be active when the file was scanned.
  final String Function(int index) unnamedMarkerLabel;
  final String Function(int index) unnamedRegionLabel;

  final String showAllLabel;
  final String collapseLabel;

  /// Jump the player to this marker. Null disables the rows.
  final void Function(ProjectMarker marker)? onTap;

  final String? jumpTooltip;
  final String? disabledTooltip;

  /// How many rows to show before the list folds behind a toggle. A film or
  /// podcast session can carry hundreds; unfolded they would bury everything
  /// below them on the page.
  final int collapsedCount;

  final EdgeInsets padding;

  @override
  State<ProjectMarkersSection> createState() => _ProjectMarkersSectionState();
}

class _ProjectMarkersSectionState extends State<ProjectMarkersSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.markers.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final overflows = widget.markers.length > widget.collapsedCount;
    final visible = (overflows && !_expanded)
        ? widget.markers.take(widget.collapsedCount).toList()
        : widget.markers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: widget.padding.copyWith(top: 12, bottom: 6),
          child: Row(
            children: [
              Icon(
                Icons.bookmarks_outlined,
                size: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 6),
              Text(
                widget.title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              // Just the number — no string to translate.
              Text(
                '${widget.markers.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        for (final marker in visible)
          _MarkerRow(
            marker: marker,
            label: _labelFor(marker),
            onTap: widget.onTap,
            tooltip: widget.onTap == null
                ? widget.disabledTooltip
                : widget.jumpTooltip,
            padding: widget.padding,
          ),
        if (overflows)
          Padding(
            padding: widget.padding,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  _expanded ? widget.collapseLabel : widget.showAllLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _labelFor(ProjectMarker marker) {
    if (marker.name.isNotEmpty) return marker.name;
    return marker.isRegion
        ? widget.unnamedRegionLabel(marker.index)
        : widget.unnamedMarkerLabel(marker.index);
  }
}

class _MarkerRow extends StatelessWidget {
  const _MarkerRow({
    required this.marker,
    required this.label,
    required this.onTap,
    required this.tooltip,
    required this.padding,
  });

  final ProjectMarker marker;
  final String label;
  final void Function(ProjectMarker marker)? onTap;
  final String? tooltip;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final length = marker.length;

    final row = Padding(
      padding: padding.copyWith(top: 5, bottom: 5),
      child: Row(
        children: [
          Icon(
            marker.isRegion ? Icons.linear_scale : Icons.label_outline,
            size: 15,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          // Fixed-width figures so the timecodes line up into a column the
          // eye can scan, instead of jittering with the digits.
          Text(
            formatPlaybackTimestamp(marker.position),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: enabled
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (length != null) ...[
            const SizedBox(width: 8),
            Text(
              formatPlaybackTimestamp(length),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );

    final tappable = InkWell(
      onTap: enabled ? () => onTap!(marker) : null,
      child: row,
    );

    return tooltip == null
        ? tappable
        : Tooltip(message: tooltip!, child: tappable);
  }
}
