import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/utils/daw_logo.dart';

void main() {
  group('getDawLogoPath', () {
    test('null or empty dawType returns null', () {
      expect(getDawLogoPath(null), isNull);
      expect(getDawLogoPath(''), isNull);
    });

    test('unrecognized dawType returns null', () {
      expect(getDawLogoPath('Some Unknown DAW'), isNull);
    });

    test('resolves every canonical DAW name produced by MetadataExtractor', () {
      const expected = {
        'Ableton Live': 'ableton-live.png',
        'Bitwig Studio': 'bitwig-studio.png',
        'Cubase': 'cubase.png',
        'FL Studio': 'fl-studio.png',
        'Logic Pro': 'logic-pro.png',
        'Maschine': 'maschine.png',
        'Nuendo': 'nuendo.png',
        'Pro Tools': 'pro-tools.png',
        'Reaper': 'reaper.png',
        'Studio One': 'studio-one.png',
        'Waveform': 'tracktion-waveform.png',
        'LUNA': 'luna.png',
        'MAGDA': 'magda.png',
        'Ardour': 'ardour.png',
        'GarageBand': 'garageband.png',
        'Renoise': 'renoise.png',
        'LMMS': 'lmms.png',
        'Audacity': 'audacity.png',
        'Qtractor': 'qtractor.png',
        'Reason': 'reason.png',
        'Digital Performer': 'digital-performer.png',
        'Adobe Audition': 'adobe-audition.png',
        'Samplitude / Sequoia': 'samplitude-sequoia.png',
        'ACID Pro': 'acid-pro.png',
        'Mixcraft': 'mixcraft.png',
      };

      for (final entry in expected.entries) {
        expect(
          getDawLogoPath(entry.key),
          'resources/daw/logos/${entry.value}',
          reason: 'DAW type "${entry.key}" should resolve to ${entry.value}',
        );
      }
    });

    test('matching is case-insensitive', () {
      expect(getDawLogoPath('ableton live'), 'resources/daw/logos/ableton-live.png');
      expect(getDawLogoPath('LUNA'.toLowerCase()), 'resources/daw/logos/luna.png');
    });

    test('Rosegarden has no logo asset yet and falls back to null', () {
      // Deliberately unmapped — the only image sourced for it turned out to
      // be a photo of an actual garden rose, not the software's logo. See
      // resources/daw/logos/MISSING_LOGOS.md.
      expect(getDawLogoPath('Rosegarden'), isNull);
    });
  });
}
