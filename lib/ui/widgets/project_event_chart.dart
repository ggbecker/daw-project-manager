import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/project_event.dart';
import '../../providers/providers.dart';

/// Horizontal timeline scatter-plot for a project's events.
///
/// X-axis = date, Y-axis = decorative only (all dots sit on a single line).
/// Dots are coloured by event type. Tap a dot to see its detail.
class ProjectEventChart extends ConsumerStatefulWidget {
  final List<ProjectEvent> events;
  const ProjectEventChart({required this.events, super.key});

  @override
  ConsumerState<ProjectEventChart> createState() => _ProjectEventChartState();
}

class _ProjectEventChartState extends ConsumerState<ProjectEventChart> {
  ProjectEvent? _selected;

  static const double _hPad = 16;
  static const double _dotR = 6.0;
  static const double _lineY = 44.0;
  static const double _staggerOffset = 14.0;

  // ── x position (centre of dot) ──────────────────────────────────────────
  double _xPos(
      ProjectEvent event, DateTime earliest, DateTime latest, double width) {
    final totalMs =
        latest.millisecondsSinceEpoch - earliest.millisecondsSinceEpoch;
    if (totalMs == 0) return width / 2;
    final eventMs = event.occurredAt.millisecondsSinceEpoch -
        earliest.millisecondsSinceEpoch;
    return _hPad + (eventMs / totalMs) * (width - _hPad * 2);
  }

  // ── vertical stagger so nearby dots don't fully overlap ─────────────────
  List<double> _yOffsets(
      List<ProjectEvent> events, DateTime earliest, DateTime latest, double w) {
    final xs = events
        .map((e) => _xPos(e, earliest, latest, w))
        .toList();
    final offsets = List.filled(events.length, 0.0);
    bool lastUp = false;
    for (int i = 1; i < events.length; i++) {
      if ((xs[i] - xs[i - 1]).abs() < _dotR * 2 + 4) {
        lastUp = !lastUp;
        offsets[i] = lastUp ? -_staggerOffset : _staggerOffset;
      } else {
        lastUp = false;
      }
    }
    return offsets;
  }

  // ── colours ─────────────────────────────────────────────────────────────
  Color _dotColor(ProjectEvent event) {
    switch (event.eventType) {
      case ProjectEvent.statusChange:
        try {
          final p = jsonDecode(event.payload ?? '{}') as Map<String, dynamic>;
          return _phaseColor(p['to'] as String? ?? '');
        } catch (_) {
          return Colors.purple;
        }
      case ProjectEvent.metadataEdit:
        return Colors.blueAccent;
      case ProjectEvent.todoCompleted:
        return Colors.green;
      case ProjectEvent.fileChanged:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _phaseColor(String phase) {
    switch (phase) {
      case 'Idea':
        return Colors.purple;
      case 'Composing':
        return Colors.blue;
      case 'Arranging':
        return Colors.teal;
      case 'Mixing':
        return Colors.orange;
      case 'Mastering':
        return Colors.deepOrange;
      case 'Finished':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _eventIcon(ProjectEvent event) {
    switch (event.eventType) {
      case ProjectEvent.statusChange:
        return Icons.swap_horiz;
      case ProjectEvent.metadataEdit:
        return Icons.edit_outlined;
      case ProjectEvent.todoCompleted:
        return Icons.check_circle_outline;
      case ProjectEvent.fileChanged:
        return Icons.folder_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  String _eventLabel(ProjectEvent event, AppLocalizations l10n) {
    try {
      final payload = event.payload != null
          ? jsonDecode(event.payload!) as Map<String, dynamic>
          : <String, dynamic>{};
      switch (event.eventType) {
        case ProjectEvent.statusChange:
          return l10n.statsEventPhaseChanged(
            payload['from'] as String? ?? '',
            payload['to'] as String? ?? '',
          );
        case ProjectEvent.metadataEdit:
          final fields =
              (payload['fields'] as List?)?.cast<String>().join(', ') ?? '';
          return l10n.statsEventMetadataUpdated(fields);
        case ProjectEvent.todoCompleted:
          return l10n
              .statsEventTodoCompleted(payload['todoText'] as String? ?? '');
        case ProjectEvent.fileChanged:
          return l10n.statsEventFileModified;
        default:
          return event.eventType;
      }
    } catch (_) {
      return event.eventType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Full locale-aware date+time for the detail card
    final dateTimeFmt = ref.watch(dateFormatProvider);
    // Short date-only for axis labels (e.g. "Jan 5" or "5 jan")
    final locale = ref.watch(localeProvider);
    final dateFmt = DateFormat.MMMd(locale.toString());
    final events = [...widget.events]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    if (events.isEmpty) return const SizedBox.shrink();

    final earliest = events.first.occurredAt;
    final latest = events.last.occurredAt;
    final hintColor = Theme.of(context).hintColor;
    final bodySmall = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Chart ───────────────────────────────────────────────────────
        SizedBox(
          height: 90,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final yOffsets = _yOffsets(events, earliest, latest, w);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Axis line
                  Positioned(
                    left: _hPad,
                    right: _hPad,
                    top: _lineY,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: hintColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  // End-caps
                  Positioned(
                    left: _hPad - 1,
                    top: _lineY - 4,
                    child: Container(
                        width: 2,
                        height: 10,
                        color: hintColor.withValues(alpha: 0.3)),
                  ),
                  Positioned(
                    right: _hPad - 1,
                    top: _lineY - 4,
                    child: Container(
                        width: 2,
                        height: 10,
                        color: hintColor.withValues(alpha: 0.3)),
                  ),
                  // Dots
                  for (int i = 0; i < events.length; i++)
                    Builder(builder: (context) {
                      final event = events[i];
                      final cx = _xPos(event, earliest, latest, w);
                      final cy = _lineY + yOffsets[i];
                      final isSelected = _selected?.id == event.id;
                      final color = _dotColor(event);
                      final r = isSelected ? _dotR + 2 : _dotR;
                      return Positioned(
                        left: cx - r,
                        top: cy - r,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() =>
                              _selected = isSelected ? null : event),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: r * 2,
                            height: r * 2,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      width: 2)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(
                                      alpha: isSelected ? 0.55 : 0.3),
                                  blurRadius: isSelected ? 8 : 3,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  // Date labels on the axis
                  Positioned(
                    left: _hPad,
                    top: _lineY + 8,
                    child: Text(
                      dateFmt.format(earliest),
                      style:
                          bodySmall?.copyWith(fontSize: 9, color: hintColor),
                    ),
                  ),
                  if (events.length > 1)
                    Positioned(
                      right: _hPad,
                      top: _lineY + 8,
                      child: Text(
                        dateFmt.format(latest),
                        style: bodySmall?.copyWith(
                            fontSize: 9, color: hintColor),
                      ),
                    ),
                ],
              );
            },
          ),
        ),

        // ── Selected event detail card ───────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _selected == null
              ? const SizedBox.shrink()
              : Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        _dotColor(_selected!).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _dotColor(_selected!)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_eventIcon(_selected!),
                          size: 14, color: _dotColor(_selected!)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _eventLabel(_selected!, l10n),
                          style: bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateTimeFmt.format(_selected!.occurredAt),
                        style: bodySmall?.copyWith(
                            fontSize: 9, color: hintColor),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
