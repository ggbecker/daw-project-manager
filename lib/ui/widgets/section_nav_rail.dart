import 'package:flutter/material.dart';

/// One entry in a [SectionNavRail].
class SectionNavItem {
  final IconData icon;
  final String label;

  /// Draws a divider in the rail immediately above this item, so a flat list
  /// reads as a few loose categories without needing headers.
  final bool newGroup;

  const SectionNavItem({
    required this.icon,
    required this.label,
    this.newGroup = false,
  });
}

/// The left rail that picks which section of a page is showing.
///
/// Lifted out of the settings page so the project detail page can use the
/// same one rather than growing a second, subtly different copy — the two
/// pages solve the same problem (a long page with no way to jump around it)
/// and should not drift apart visually.
///
/// [searchController] is optional: the settings page flips its content pane
/// into cross-section search results, and pages with nothing to search simply
/// leave it out and get a rail with no search box.
class SectionNavRail extends StatelessWidget {
  final List<SectionNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final TextEditingController? searchController;
  final String? searchHint;

  const SectionNavRail({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onTap,
    this.searchController,
    this.searchHint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = searchController;
    // While a search is running nothing in the rail is "the current section":
    // the pane is showing results from all of them.
    final searching = controller != null && controller.text.trim().isNotEmpty;

    return Material(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          if (controller != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: searchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searching
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: controller.clear,
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = !searching && index == activeIndex;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (item.newGroup)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Divider(height: 1),
                      ),
                    InkWell(
                      onTap: () => onTap(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primaryContainer.withValues(alpha: 0.4)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color:
                                  selected ? cs.primary : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color:
                                      selected ? cs.primary : cs.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
