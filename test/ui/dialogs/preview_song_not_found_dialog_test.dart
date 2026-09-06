import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/dialogs/preview_song_not_found_dialog.dart';

/// Covers the missing-preview recovery dialog.
///
/// The dialog used to exist as three hand-copied duplicates, which is how
/// "Find automatically" ended up missing from two of them. These tests pin
/// the one shared version: every action is reachable, and each returns the
/// value its caller switches on.
void main() {
  /// Opens the dialog and leaves it up. [canAutoFind] is passed explicitly so
  /// these run identically on every host platform — the production default
  /// derives it from `MobileUtils.isMobile()`.
  Future<void> pumpAndOpen(
    WidgetTester tester, {
    bool canAutoFind = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPreviewSongNotFoundDialog(
                context,
                canAutoFind: canAutoFind,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<PreviewNotFoundAction?> tapAndRead(
    WidgetTester tester,
    String label,
  ) async {
    PreviewNotFoundAction? captured;
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await showPreviewSongNotFoundDialog(
                  context,
                  canAutoFind: true,
                );
                completed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    return captured;
  }

  testWidgets('offers all four recovery choices', (tester) async {
    await pumpAndOpen(tester);

    expect(find.text('Preview song file not found'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Remove preview song'), findsOneWidget);
    expect(find.text('Find automatically'), findsOneWidget);
    expect(find.text('Select New File'), findsOneWidget);
  });

  testWidgets('hides auto-find where mixdown scanning cannot run',
      (tester) async {
    // MixdownDetectorService bails out immediately on mobile, so the button
    // would only ever report "nothing found".
    await pumpAndOpen(tester, canAutoFind: false);

    expect(find.text('Find automatically'), findsNothing);
    expect(find.text('Remove preview song'), findsOneWidget);
    expect(find.text('Select New File'), findsOneWidget);
  });

  testWidgets('"Remove Preview Song" returns remove', (tester) async {
    expect(
      await tapAndRead(tester, 'Remove preview song'),
      PreviewNotFoundAction.remove,
    );
  });

  testWidgets('"Find automatically" returns autoFind', (tester) async {
    expect(
      await tapAndRead(tester, 'Find automatically'),
      PreviewNotFoundAction.autoFind,
    );
  });

  testWidgets('"Select New File" returns selectNew', (tester) async {
    expect(
      await tapAndRead(tester, 'Select New File'),
      PreviewNotFoundAction.selectNew,
    );
  });

  testWidgets('Cancel returns null so callers can treat it as "do nothing"',
      (tester) async {
    expect(await tapAndRead(tester, 'Cancel'), isNull);
  });

  test('previewAudioExtensions covers every format the player can open', () {
    // The file picker filters on this list; a format missing here is a file
    // the user physically cannot select as a replacement. AIFF (.aif/.aiff)
    // plays natively on macOS/iOS and via the desktop ffmpeg fallback, so it
    // must be selectable too.
    expect(
      previewAudioExtensions,
      containsAll(<String>['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'aif', 'aiff']),
    );
  });
}
