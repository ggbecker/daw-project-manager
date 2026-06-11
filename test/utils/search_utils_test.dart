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

    test('characters in order with gaps match', () {
      // 'chilvib' matches 'Chillout Vibes' (c-h-i-l-...-v-i-b)
      expect(fuzzyContains('chillout vibes', 'chilvib'), isTrue);
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
  });

  group('fuzzyMatchAll', () {
    test('empty query matches everything', () {
      expect(fuzzyMatchAll('Bass Track', ''), isTrue);
    });

    test('whitespace-only query matches everything', () {
      expect(fuzzyMatchAll('Bass Track', '   '), isTrue);
    });

    test('single word fuzzy-matches', () {
      expect(fuzzyMatchAll('BassTrack 2025', 'bass'), isTrue);
    });

    test('is case-insensitive', () {
      expect(fuzzyMatchAll('My Drum Loop', 'DRUM LOOP'), isTrue);
      expect(fuzzyMatchAll('MY DRUM LOOP', 'drum loop'), isTrue);
    });

    test('multi-word query requires every word to fuzzy-match', () {
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

    test('all words must independently fuzzy-match the same text', () {
      // "idea" → matches "Idea project"; "proj" → matches "Idea project"
      expect(fuzzyMatchAll('Idea project', 'idea proj'), isTrue);
      // "zzz" → no match
      expect(fuzzyMatchAll('Idea project', 'idea zzz'), isFalse);
    });

    test('extra whitespace between query words is handled', () {
      expect(fuzzyMatchAll('Bass Track', 'bass   track'), isTrue);
    });
  });
}
