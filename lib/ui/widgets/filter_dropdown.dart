import 'package:flutter/material.dart';

/// A small "icon + dropdown" filter control (used for Phase/DAW/Key filter
/// bars) whose hover highlight covers the icon and the dropdown as a single
/// unit. Plain [DropdownButton] only shows its built-in hover highlight
/// around the text/arrow — the leading icon sits outside that highlight,
/// which reads as a rendering glitch once you notice it. This wraps both in
/// one [MouseRegion]-driven background and suppresses the DropdownButton's
/// own internal hover/splash/focus colors so there's no mismatched second
/// highlight underneath.
class FilterDropdown<T> extends StatefulWidget {
  final IconData icon;
  final T? value;
  final String hintText;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const FilterDropdown({
    super.key,
    required this.icon,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  @override
  State<FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<FilterDropdown<T>> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.textTheme.bodyMedium?.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _hovering ? theme.hoverColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Theme(
              data: theme.copyWith(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                focusColor: Colors.transparent,
              ),
              child: DropdownButton<T>(
                value: widget.value,
                hint: Text(
                  widget.hintText,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                underline: const SizedBox.shrink(),
                style: TextStyle(fontSize: 12, color: iconColor),
                icon: const SizedBox.shrink(),
                items: widget.items,
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
