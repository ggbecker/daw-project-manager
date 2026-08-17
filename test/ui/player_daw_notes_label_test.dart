import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The DAW-extracted notes block is shown in three places — the project detail
/// page and both music players — and they must all call it the same thing.
/// The players used to have their own `playerDawNotes` key ("DAW FILE NOTES"),
/// which drifted from the detail page's wording; they now reuse the detail
/// page's `projectNotesFromDaw` string verbatim.
///
/// Asserted against the source because the label reaches the widget through a
/// plain `String` parameter, so `ProjectNotesSection`'s own widget tests cannot
/// see which l10n key the players chose. Opening either page for real needs
/// Hive and an audio player.
void main() {
  const players = [
    'lib/ui/music_player_page.dart',
    'lib/ui/mobile_player_page.dart',
  ];

  group('player DAW notes label', () {
    for (final path in players) {
      test('$path uses the detail page\'s projectNotesFromDaw string', () {
        final source = File(path).readAsStringSync();

        expect(
          source.contains('dawNotesLabel: l10n.projectNotesFromDaw'),
          isTrue,
          reason: 'the players must label DAW notes exactly as the project '
              'detail page does',
        );
      });
    }

    test('the retired player-specific key is gone from lib/', () {
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.arb'))
          .where((f) => f.readAsStringSync().contains('playerDawNotes'))
          .map((f) => f.path)
          .toList();

      expect(offenders, isEmpty);
    });
  });
}
