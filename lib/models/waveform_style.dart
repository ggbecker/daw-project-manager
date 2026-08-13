/// How the audio preview waveform is drawn.
///
/// Device-local, like the theme — it describes this machine's display, not
/// anything about the user's projects, so it is neither synced to Drive nor
/// carried in a backup.
enum WaveformStyle {
  /// One bar per device pixel with an RMS body stepped inward through several
  /// tonal bands — closer to how a DAW or a desktop player draws it.
  detailed,

  /// A single filled envelope traced through the peak tips. The original
  /// rendering, kept for anyone who prefers the simpler shape.
  classic,
}
