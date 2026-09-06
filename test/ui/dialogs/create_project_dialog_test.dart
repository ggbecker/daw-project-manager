import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/dialogs/create_project_dialog.dart';

void main() {
  group('buildRemixFolderName', () {
    // Backs the "Remix" naming scheme in the create-project wizard: the
    // profile pre-fills the first remixer slot, and the final name follows
    // the pattern seen in real Cubase/Nuendo project libraries, e.g.
    // "Massive Attack - Teardrop (Audio Crawler Remix)" or, for a collab
    // remix, "Armin Van Buuren - Shivers (Audio Crawler vs M4rs Remix)".

    test('builds "Artist - Track (Remixer Remix)" with a single remixer', () {
      final name = buildRemixFolderName(
        originalArtist: 'Massive Attack',
        track: 'Teardrop',
        remixerNames: ['Audio Crawler'],
      );

      expect(name, 'Massive Attack - Teardrop (Audio Crawler Remix)');
    });

    test('joins multiple remixers with " vs "', () {
      final name = buildRemixFolderName(
        originalArtist: 'Armin Van Buuren',
        track: 'Shivers',
        remixerNames: ['Audio Crawler', 'M4rs'],
      );

      expect(name, 'Armin Van Buuren - Shivers (Audio Crawler vs M4rs Remix)');
    });

    test('ignores blank remixer slots (e.g. an added-but-unfilled field)', () {
      final name = buildRemixFolderName(
        originalArtist: 'Massive Attack',
        track: 'Teardrop',
        remixerNames: ['Audio Crawler', '   ', ''],
      );

      expect(name, 'Massive Attack - Teardrop (Audio Crawler Remix)');
    });

    test('omits the suffix entirely when there are no remixers yet', () {
      final name = buildRemixFolderName(
        originalArtist: 'Massive Attack',
        track: 'Teardrop',
        remixerNames: [],
      );

      expect(name, 'Massive Attack - Teardrop');
    });

    test(
      'prepends the date prefix before the artist, not inside the suffix',
      () {
        final name = buildRemixFolderName(
          originalArtist: 'Massive Attack',
          track: 'Teardrop',
          remixerNames: ['Audio Crawler'],
          datePrefix: '2026-08-02 - ',
        );

        expect(
          name,
          '2026-08-02 - Massive Attack - Teardrop (Audio Crawler Remix)',
        );
      },
    );

    test('falls back to just the track when the original artist is blank', () {
      final name = buildRemixFolderName(
        originalArtist: '',
        track: 'Teardrop',
        remixerNames: ['Audio Crawler'],
      );

      expect(name, 'Teardrop (Audio Crawler Remix)');
    });

    test('falls back to just the artist when the track is blank', () {
      final name = buildRemixFolderName(
        originalArtist: 'Massive Attack',
        track: '',
        remixerNames: ['Audio Crawler'],
      );

      expect(name, 'Massive Attack (Audio Crawler Remix)');
    });

    test('is empty when both artist and track are blank', () {
      final name = buildRemixFolderName(
        originalArtist: '  ',
        track: '',
        remixerNames: ['Audio Crawler'],
      );

      expect(name, isEmpty);
    });

    test('trims whitespace from artist, track, and remixer names', () {
      final name = buildRemixFolderName(
        originalArtist: '  Massive Attack  ',
        track: '  Teardrop  ',
        remixerNames: ['  Audio Crawler  '],
      );

      expect(name, 'Massive Attack - Teardrop (Audio Crawler Remix)');
    });
  });

  group('primaryArtistWhenSwitchingToRemix', () {
    // The primary-artist field is auto-filled with the profile name in the
    // artist/collab schemes. Under remix it means the *original* track's
    // artist, so switching to remix must not carry that auto-fill over —
    // otherwise a new remix is silently credited to the person remixing it.
    test('drops a carried-over profile-name auto-fill', () {
      expect(primaryArtistWhenSwitchingToRemix('Audio Crawler', 'Audio Crawler'),
          isEmpty);
    });

    test('ignores surrounding whitespace when matching the profile name', () {
      expect(
          primaryArtistWhenSwitchingToRemix('  Audio Crawler ', 'Audio Crawler'),
          isEmpty);
    });

    test('keeps a real original-artist the user typed', () {
      expect(
          primaryArtistWhenSwitchingToRemix('Massive Attack', 'Audio Crawler'),
          'Massive Attack');
    });

    test('leaves an already-empty field empty', () {
      expect(primaryArtistWhenSwitchingToRemix('', 'Audio Crawler'), isEmpty);
    });

    test('no-ops when there is no profile name', () {
      expect(primaryArtistWhenSwitchingToRemix('Audio Crawler', null),
          'Audio Crawler');
    });
  });
}
