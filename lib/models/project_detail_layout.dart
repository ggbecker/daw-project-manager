/// How the project detail page arranges itself.
///
/// A device-local preference, like the theme and the waveform style — it
/// describes how this machine draws a page, not anything about the project —
/// so it is deliberately not synced or backed up.
enum ProjectDetailLayout {
  /// Everything in one scroll, in the order it has always been in.
  classic,

  /// A left rail picks one section — metadata, notes, preview song, tasks,
  /// work sessions — and only that section renders. Same idea as the settings
  /// page, for the same reason: the page is long enough that scrolling past
  /// four things to reach the fifth is the normal way to use it.
  ///
  /// Desktop only. A phone has no room for a rail, so mobile always gets
  /// [classic] regardless of what is stored here.
  sectioned,
}
