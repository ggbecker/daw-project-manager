import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/name_date_parser.dart';

void main() {
  group('stripNameDate — leading dates', () {
    test('strips the Cubase "YYYY-MM-DD - Title" shape', () {
      expect(
        stripNameDate('2026-08-02 - Massive Attack - Teardrop'),
        'Massive Attack - Teardrop',
      );
    });

    test('strips underscore-, dot- and space-separated variants', () {
      expect(stripNameDate('2026_08_02_Teardrop'), 'Teardrop');
      expect(stripNameDate('2026.08.02.Teardrop'), 'Teardrop');
      expect(stripNameDate('2026 08 02 Teardrop'), 'Teardrop');
    });

    test('strips a compact YYYYMMDD stamp', () {
      expect(stripNameDate('20260802 - Teardrop'), 'Teardrop');
      expect(stripNameDate('20260802_Teardrop'), 'Teardrop');
    });

    test('strips day-first and month-first orderings', () {
      expect(stripNameDate('02-08-2026 - Teardrop'), 'Teardrop');
      expect(stripNameDate('08-02-2026 - Teardrop'), 'Teardrop');
      expect(stripNameDate('31.12.2026 Teardrop'), 'Teardrop');
    });

    test('strips a date followed by a time stamp', () {
      expect(stripNameDate('2026-08-02 14-30 - Teardrop'), 'Teardrop');
      expect(stripNameDate('2026-08-02_14-30-55_Teardrop'), 'Teardrop');
      expect(stripNameDate('20260802 143055 Teardrop'), 'Teardrop');
    });
  });

  group('stripNameDate — trailing dates', () {
    test('strips a trailing date', () {
      expect(stripNameDate('Teardrop - 2026-08-02'), 'Teardrop');
      expect(stripNameDate('Teardrop_20260802'), 'Teardrop');
      expect(stripNameDate('Teardrop 02-08-2026'), 'Teardrop');
    });

    test('strips a trailing date with a time stamp', () {
      expect(stripNameDate('Teardrop_2026-08-02_14-30-55'), 'Teardrop');
    });

    test('strips both a leading and a trailing date', () {
      expect(stripNameDate('2026-08-02 - Teardrop - 2026-08-03'), 'Teardrop');
    });
  });

  group('stripNameDate — names that must survive untouched', () {
    // Each of these is a real-looking project name that a sloppier pattern
    // would mangle. Regressions here are silent data-looking bugs, so the
    // list is deliberately long.
    const untouched = [
      '2step',
      '2step Garage Bounce',
      '01 - Intro',
      '03 Interlude',
      'Mix 2',
      'Take 3',
      'Track 2026 Mix', // bare year, not a date
      '2026', // bare year alone
      'Teardrop', // no numbers at all
      'Bounce 128bpm',
      'Session 2026-13-02', // month 13 — not a real date
      'Session 2026-08-32', // day 32 — not a real date
      'Session 1989-08-02', // before the 1990 floor
      '2026-08.02 - Mixed separators',
      '99-08-02 - Two digit year',
      'Remix v2.0.1',
    ];

    for (final name in untouched) {
      test('leaves "$name" alone', () {
        expect(stripNameDate(name), name);
        expect(hasNameDate(name), isFalse);
      });
    }
  });

  group('stripNameDate — degenerate input', () {
    test('a name that is only a date is kept as-is', () {
      expect(stripNameDate('2026-08-02'), '2026-08-02');
      expect(stripNameDate('20260802'), '20260802');
    });

    test('empty and whitespace-only names are returned unchanged', () {
      expect(stripNameDate(''), '');
      expect(stripNameDate('   '), '   ');
    });

    test('surrounding whitespace is trimmed only when a date is stripped', () {
      expect(stripNameDate('  2026-08-02 - Teardrop  '), 'Teardrop');
      expect(stripNameDate('  Teardrop  '), '  Teardrop  ');
    });

    test('a name that legitimately starts with a dash keeps it', () {
      expect(stripNameDate('- Teardrop -'), '- Teardrop -');
    });
  });

  group('hasNameDate', () {
    test('is true only when something would be removed', () {
      expect(hasNameDate('2026-08-02 - Teardrop'), isTrue);
      expect(hasNameDate('Teardrop'), isFalse);
      expect(hasNameDate('2026-08-02'), isFalse); // kept as-is, so no change
    });
  });

  group('stripNameDateKeepingExtension', () {
    test('preserves the extension while stripping the date', () {
      expect(
        stripNameDateKeepingExtension('2026-08-02 - Teardrop.wav'),
        'Teardrop.wav',
      );
      expect(
        stripNameDateKeepingExtension('Teardrop_20260802.mp3'),
        'Teardrop.mp3',
      );
    });

    test('does not treat the extension dot as a date separator', () {
      // Without extension-awareness the trailing `.wav` would be part of the
      // string the trailing-date pattern scans.
      expect(
        stripNameDateKeepingExtension('Teardrop 2026-08-02.wav'),
        'Teardrop.wav',
      );
    });

    test('handles names with no usable extension', () {
      expect(stripNameDateKeepingExtension('2026-08-02 - Teardrop'), 'Teardrop');
      expect(stripNameDateKeepingExtension('.hidden'), '.hidden');
      expect(stripNameDateKeepingExtension('trailing.'), 'trailing.');
    });

    test('leaves a dateless filename completely alone', () {
      expect(stripNameDateKeepingExtension('Teardrop.wav'), 'Teardrop.wav');
    });
  });
}
