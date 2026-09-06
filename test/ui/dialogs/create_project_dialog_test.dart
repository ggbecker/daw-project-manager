import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/profile.dart';
import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/ui/dialogs/create_project_dialog.dart';

import '../../helpers/hive_test_helper.dart';

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

    test('prepends a date prefix when given one', () {
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
    });

    test('drops the "Artist - " part when the original artist is blank', () {
      final name = buildRemixFolderName(
        originalArtist: '',
        track: 'Teardrop',
        remixerNames: ['Audio Crawler'],
      );

      expect(name, 'Teardrop (Audio Crawler Remix)');
    });

    test('drops the " - Track" part when the track is blank', () {
      final name = buildRemixFolderName(
        originalArtist: 'Massive Attack',
        track: '',
        remixerNames: ['Audio Crawler'],
      );

      expect(name, 'Massive Attack (Audio Crawler Remix)');
    });

    test('returns empty when both artist and track are blank', () {
      final name = buildRemixFolderName(
        originalArtist: '',
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

  // Regression: the remix "original artist" field and the artist/collab
  // "artist name" field used to share one TextEditingController. So the
  // profile-name auto-fill leaked into "original artist" when switching to
  // remix, and — the reverse — an original artist typed under remix
  // overwrote the artist field (and was never restored to the profile name)
  // when switching back. They now have separate controllers.
  group('naming-scheme artist fields stay isolated', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await HiveTestHelper.setUp();
      await Hive.openBox<String>('settings');
    });
    tearDown(() async => HiveTestHelper.tearDown(tempDir));

    Future<AppLocalizations> pumpDialog(WidgetTester tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scanRootsProvider.overrideWithValue(const []),
            currentProfileProvider.overrideWith(
              (ref) => Stream.value(
                Profile(id: 'p1', name: 'DJ Me', createdAt: DateTime(2026)),
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context)!;
                return const Scaffold(body: CreateProjectDialog());
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return l10n;
    }

    String fieldText(WidgetTester tester, String label) {
      final field = find.widgetWithText(TextField, label);
      return tester.widget<TextField>(field).controller!.text;
    }

    testWidgets(
      'switching to remix and back keeps the profile name as the artist',
      (tester) async {
        final l10n = await pumpDialog(tester);

        // Default scheme is Artist — Track; the artist field is pre-filled
        // with the profile name.
        expect(
          fieldText(tester, l10n.createProjectArtistName),
          'DJ Me',
        );

        // Switch to Remix and type the ORIGINAL track's artist.
        await tester.tap(find.text(l10n.createProjectSchemeRemix));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, l10n.createProjectOriginalArtist),
          'Massive Attack',
        );
        await tester.pumpAndSettle();

        // Back to Artist — Track: the artist must be the profile name again,
        // NOT the original artist that was just typed under remix.
        await tester.tap(find.text(l10n.createProjectSchemeArtistTrack));
        await tester.pumpAndSettle();
        expect(
          fieldText(tester, l10n.createProjectArtistName),
          'DJ Me',
        );

        // And returning to Remix still has the original artist preserved.
        await tester.tap(find.text(l10n.createProjectSchemeRemix));
        await tester.pumpAndSettle();
        expect(
          fieldText(tester, l10n.createProjectOriginalArtist),
          'Massive Attack',
        );
      },
    );

    testWidgets('the remix original-artist field never starts as the profile name',
        (tester) async {
      final l10n = await pumpDialog(tester);

      await tester.tap(find.text(l10n.createProjectSchemeRemix));
      await tester.pumpAndSettle();

      expect(
        fieldText(tester, l10n.createProjectOriginalArtist),
        isEmpty,
      );
    });
  });
}
