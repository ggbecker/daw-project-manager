import 'package:flutter/material.dart';

/// The notes blocks shown in the music players: what the user typed, and what
/// was read out of the DAW project file.
///
/// A plain view widget on purpose — it takes strings rather than a
/// `MusicProject` and reads no providers, so the four combinations of
/// present/absent can be widget-tested without opening Hive.
///
/// The two are always rendered in the same order with distinct labels. They
/// come from different places and only one of them is editable, so leaving it
/// ambiguous which is which would be worse than not showing the DAW notes at
/// all.
class ProjectNotesSection extends StatelessWidget {
  const ProjectNotesSection({
    super.key,
    required this.userNotes,
    required this.dawNotes,
    required this.userNotesLabel,
    required this.dawNotesLabel,
    required this.expandLabel,
    required this.collapseLabel,
    this.labelStyle,
    this.textStyle,
    this.labelPadding = const EdgeInsets.fromLTRB(14, 12, 14, 4),
    this.textPadding = const EdgeInsets.fromLTRB(14, 0, 14, 8),
    this.collapsedLineLimit = 8,
  });

  /// Free text the user typed in the app (`MusicProject.notes`).
  final String? userNotes;

  /// Read-only notes extracted from the DAW project file itself
  /// (`MusicProject.projectNotes`) — REAPER's Notes tab, Cubase's Notepad.
  final String? dawNotes;

  final String userNotesLabel;
  final String dawNotesLabel;
  final String expandLabel;
  final String collapseLabel;

  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final EdgeInsets labelPadding;
  final EdgeInsets textPadding;

  /// DAW notes longer than this collapse behind a toggle. A whole session's
  /// production notes would otherwise push the tasks list off the pane.
  final int collapsedLineLimit;

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;

  /// Whether either field has anything to show — lets callers skip surrounding
  /// chrome (dividers, padding) without repeating the emptiness rules.
  static bool hasContent({String? userNotes, String? dawNotes}) =>
      _has(userNotes) || _has(dawNotes);

  @override
  Widget build(BuildContext context) {
    final showUser = _has(userNotes);
    final showDaw = _has(dawNotes);
    if (!showUser && !showDaw) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showUser) ...[
          Padding(
            padding: labelPadding,
            child: Text(userNotesLabel, style: labelStyle),
          ),
          Padding(
            padding: textPadding,
            child: Text(userNotes!, style: textStyle),
          ),
        ],
        if (showDaw) ...[
          Padding(
            padding: labelPadding,
            child: Text(dawNotesLabel, style: labelStyle),
          ),
          Padding(
            padding: textPadding,
            child: _CollapsibleText(
              text: dawNotes!,
              style: textStyle,
              lineLimit: collapsedLineLimit,
              expandLabel: expandLabel,
              collapseLabel: collapseLabel,
            ),
          ),
        ],
      ],
    );
  }
}

/// Shows [text], truncated to [lineLimit] lines with a toggle when it is
/// longer. Short text renders with no toggle at all.
class _CollapsibleText extends StatefulWidget {
  const _CollapsibleText({
    required this.text,
    required this.style,
    required this.lineLimit,
    required this.expandLabel,
    required this.collapseLabel,
  });

  final String text;
  final TextStyle? style;
  final int lineLimit;
  final String expandLabel;
  final String collapseLabel;

  @override
  State<_CollapsibleText> createState() => _CollapsibleTextState();
}

class _CollapsibleTextState extends State<_CollapsibleText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Counting newlines rather than measuring wrapped lines: it needs no
    // layout pass, and the case this exists for — a pasted session log — is
    // many short lines rather than one long paragraph.
    final overflows = '\n'.allMatches(widget.text).length >= widget.lineLimit;
    if (!overflows) {
      return Text(widget.text, style: widget.style);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _expanded ? null : widget.lineLimit,
          overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
        ),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              _expanded ? widget.collapseLabel : widget.expandLabel,
              style: (widget.style ?? const TextStyle()).copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
