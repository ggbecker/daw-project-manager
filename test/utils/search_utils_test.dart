import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/utils/search_utils.dart';

void main() {
  group('fuzzyContains', () {
    test('empty pattern always matches', () {
      expect(fuzzyContains('Hello World', ''), isTrue);
      expect(fuzzyContains('', ''), isTrue);
    });

    test('exact lowercase match returns true', () {
      expect(fuzzyContains('chillout vibes', 'chillout vibes'), isTrue);
    });

    test('plain substring match returns true', () {
      expect(fuzzyContains('chillout vibes', 'llout vi'), isTrue);
    });

    test('word-anchored chunks with gaps match', () {
      // 'chilvib' matches 'chillout vibes' as chil|lout + vib|es — each chunk
      // starts on a word's first character.
      expect(fuzzyContains('chillout vibes', 'chilvib'), isTrue);
    });

    test('characters may be skipped inside a single word', () {
      // 'chl' is c-h-l within 'chillout', anchored at its first character.
      expect(fuzzyContains('chillout vibes', 'chl'), isTrue);
    });

    test('characters out of order do not match', () {
      // 'bac' requires b before a in text, but text has a before b
      expect(fuzzyContains('abc', 'bac'), isFalse);
    });

    test('pattern longer than text returns false', () {
      expect(fuzzyContains('abc', 'abcde'), isFalse);
    });

    test('empty text with non-empty pattern returns false', () {
      expect(fuzzyContains('', 'abc'), isFalse);
    });

    test('returns false when pattern characters not present', () {
      expect(fuzzyContains('chillout vibes', 'xyz'), isFalse);
    });

    test('single matching character returns true', () {
      expect(fuzzyContains('bass', 'b'), isTrue);
    });

    test('single non-matching character returns false', () {
      expect(fuzzyContains('bass', 'z'), isFalse);
    });

    test('a chunk may not start mid-word', () {
      // 'hilvib': 'hil' is inside 'chillout' but does not start it, and the
      // whole pattern is not a substring either.
      expect(fuzzyContains('chillout vibes', 'hilvib'), isFalse);
    });

    test('a chunk must come from a later word than the previous one', () {
      // 'drumdrum' would need the single word 'drum' to supply both chunks.
      expect(fuzzyContains('drum loop', 'drumdrum'), isFalse);
      // …but two separate words can.
      expect(fuzzyContains('drum drums', 'drumdrum'), isTrue);
    });

    test('single-character chunks are rejected (no acronym matching)', () {
      // s-h-a-r-e-d as one letter per word is exactly the class of false
      // positive this matcher exists to prevent.
      expect(
        fuzzyContains('super happy awesome rock elephant dance', 'shared'),
        isFalse,
      );
    });

    test('separators other than whitespace start words', () {
      expect(fuzzyContains('bass_track-01 (final).als', 'batr'), isTrue);
      expect(fuzzyContains('bass_track-01 (final).als', 'baalsx'), isFalse);
    });

    test('very long query words still match as a plain substring', () {
      // Past the fuzzy fallback's length cap, substring matching must still
      // work rather than silently returning false.
      final long = 'a' * 40;
      expect(fuzzyContains('prefix $long suffix', long), isTrue);
      expect(fuzzyContains('prefix suffix', long), isFalse);
    });
  });

  group('regression: issue #102 false positives', () {
    const royksopp =
        '2026_022_01 - royksopp - what else is there (audio crawler remix).cpr';

    test('"shared" does not match an unrelated project filename', () {
      // Reported case: a pure subsequence test scavenged s-h-a-r-e-d out of
      // roykSopp / wHat / whAt / theRe / therE / auDio — six unrelated words.
      expect(fuzzyContains(royksopp, 'shared'), isFalse);
      expect(fuzzyMatchAll(royksopp, 'shared'), isFalse);
    });

    test('"shared" does not match a description containing only "sh"', () {
      expect(fuzzyContains('sh', 'shared'), isFalse);
      expect(fuzzyMatchAll('sh', 'shared'), isFalse);
      expect(fuzzyMatchAll('sh and other words here', 'shared'), isFalse);
    });

    test('longer queries narrow the results instead of widening them', () {
      // Under the old subsequence test, every one of these got *more* likely
      // to match as the query grew, because a long filename has more spare
      // letters to scavenge.
      expect(fuzzyMatchAll(royksopp, 'what'), isTrue);
      expect(fuzzyMatchAll(royksopp, 'whatever'), isFalse);
      expect(fuzzyMatchAll(royksopp, 'audio'), isTrue);
      expect(fuzzyMatchAll(royksopp, 'audiophile'), isFalse);
    });

    test('the documented good case still matches', () {
      expect(fuzzyContains('chillout vibes', 'chilvib'), isTrue);
      expect(fuzzyMatchAll('Chillout Vibes', 'chilvib'), isTrue);
    });

    test('a real word in the filename still matches', () {
      expect(fuzzyMatchAll(royksopp, 'crawler'), isTrue);
      expect(fuzzyMatchAll(royksopp, 'audio crawler'), isTrue);
      expect(fuzzyMatchAll(royksopp, 'royksopp remix'), isTrue);
    });
  });

  group('fuzzyMatchAll', () {
    test('empty query matches everything', () {
      expect(fuzzyMatchAll('Bass Track', ''), isTrue);
    });

    test('whitespace-only query matches everything', () {
      expect(fuzzyMatchAll('Bass Track', '   '), isTrue);
    });

    test('single word matches', () {
      expect(fuzzyMatchAll('BassTrack 2025', 'bass'), isTrue);
    });

    test('is case-insensitive', () {
      expect(fuzzyMatchAll('My Drum Loop', 'DRUM LOOP'), isTrue);
      expect(fuzzyMatchAll('MY DRUM LOOP', 'drum loop'), isTrue);
    });

    test('multi-word query requires every word to match', () {
      expect(fuzzyMatchAll('Chillout Vibes', 'chl vib'), isTrue);
    });

    test('word order in query does not matter', () {
      // Both "bass" and "track" must match independently
      expect(fuzzyMatchAll('Bass Track', 'track bass'), isTrue);
    });

    test('returns false when one word does not match', () {
      expect(fuzzyMatchAll('Bass Track', 'bass xyz'), isFalse);
    });

    test('returns false when text is empty and query is non-empty', () {
      expect(fuzzyMatchAll('', 'bass'), isFalse);
    });

    test('all words must independently match the same text', () {
      // "idea" → matches "Idea project"; "proj" → matches "Idea project"
      expect(fuzzyMatchAll('Idea project', 'idea proj'), isTrue);
      // "zzz" → no match
      expect(fuzzyMatchAll('Idea project', 'idea zzz'), isFalse);
    });

    test('extra whitespace between query words is handled', () {
      expect(fuzzyMatchAll('Bass Track', 'bass   track'), isTrue);
    });

    test('alternating queries across repeated calls each get correct results (single-entry cache correctness)', () {
      // fuzzyMatchAll caches the split of only the most recently seen query
      // string as a performance optimization. Filtering a list interleaves
      // many calls against the SAME query, but calling it with a different
      // query must never reuse a stale split from a previous call.
      for (var i = 0; i < 3; i++) {
        expect(fuzzyMatchAll('Bass Track', 'bass'), isTrue);
        expect(fuzzyMatchAll('Bass Track', 'drum'), isFalse);
        expect(fuzzyMatchAll('Drum Loop', 'drum'), isTrue);
        expect(fuzzyMatchAll('Drum Loop', 'bass'), isFalse);
      }
    });
  });

  group('fuzzyMatchAny', () {
    test('matches when any single field matches', () {
      expect(fuzzyMatchAny(['Bass Track', 'some notes'], 'bass'), isTrue);
      expect(fuzzyMatchAny(['Bass Track', 'some notes'], 'notes'), isTrue);
    });

    test('null and empty fields are skipped', () {
      expect(fuzzyMatchAny(['Bass Track', null, ''], 'bass'), isTrue);
      expect(fuzzyMatchAny([null, '', 'reverb tail'], 'reverb'), isTrue);
      expect(fuzzyMatchAny([null, ''], 'bass'), isFalse);
    });

    test('returns false when no field matches', () {
      expect(fuzzyMatchAny(['Bass Track', 'some notes'], 'xyz'), isFalse);
    });

    test('every query word must match the SAME field', () {
      // "bass" only appears in the title and "reverb" only in the notes —
      // matching them across two different fields would be a false positive.
      expect(
        fuzzyMatchAny(['Bass Track', 'add reverb'], 'bass reverb'),
        isFalse,
      );
      expect(
        fuzzyMatchAny(['Bass Track', 'bass needs reverb'], 'bass reverb'),
        isTrue,
      );
    });

    test('empty query matches even with no searchable fields', () {
      expect(fuzzyMatchAny([null, ''], ''), isTrue);
      expect(fuzzyMatchAny([], ''), isTrue);
      expect(fuzzyMatchAny([], 'bass'), isFalse);
    });
  });
}
