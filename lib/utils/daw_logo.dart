/// Maps a project's [dawType] to its logo asset path under
/// `resources/daw/logos/`, or `null` if no matching logo exists.
String? getDawLogoPath(String? dawType) {
  if (dawType == null || dawType.isEmpty) return null;

  final dawLower = dawType.toLowerCase();
  const logoMap = {
    'ableton': 'ableton-live.png',
    'ableton live': 'ableton-live.png',
    'fl studio': 'fl-studio.png',
    'flstudio': 'fl-studio.png',
    'logic pro': 'logic-pro.png',
    'logic': 'logic-pro.png',
    'cubase': 'cubase.png',
    'studio one': 'studio-one.png',
    'studioone': 'studio-one.png',
    'reaper': 'reaper.png',
    'pro tools': 'pro-tools.png',
    'protools': 'pro-tools.png',
    'bitwig': 'bitwig-studio.png',
    'bitwig studio': 'bitwig-studio.png',
    'nuendo': 'nuendo.png',
    'maschine': 'maschine.png',
    'tracktion waveform': 'tracktion-waveform.png',
    'tracktion': 'tracktion-waveform.png',
    'waveform': 'tracktion-waveform.png',
    'cakewalk': 'cakewalk.png',
    'cakewalk sonar': 'cakewalk.png',
    'sonar': 'cakewalk.png',
    'luna': 'luna.png',
  };

  // Try exact match first
  if (logoMap.containsKey(dawLower)) {
    return 'resources/daw/logos/${logoMap[dawLower]}';
  }

  // Try partial match
  for (final entry in logoMap.entries) {
    if (dawLower.contains(entry.key) || entry.key.contains(dawLower)) {
      return 'resources/daw/logos/${entry.value}';
    }
  }

  return null;
}
