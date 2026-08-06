import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/ui/settings_page.dart';

// Only the pure logic extracted from settings_page.dart is tested here —
// the rest of the page (a very large StatefulWidget wired to Riverpod/Hive)
// isn't practically unit- or widget-testable in isolation; see other
// settings-adjacent tests (e.g. project_repository_test.dart's "scan root
// display names" group) for coverage of the data layer this UI reads from.
void main() {
  group('looksLikeFlatpakPortalPath', () {
    test('matches a document-portal path', () {
      expect(
        looksLikeFlatpakPortalPath('/run/user/1000/doc/98127/projects'),
        isTrue,
      );
    }, testOn: 'linux');

    test('matches regardless of the numeric doc id length', () {
      expect(looksLikeFlatpakPortalPath('/run/user/1/doc/1/x'), isTrue);
    }, testOn: 'linux');

    test('does not match a normal home-directory path', () {
      expect(
        looksLikeFlatpakPortalPath('/home/becker/Documents/lmms/projects'),
        isFalse,
      );
    }, testOn: 'linux');

    test('does not match a Flatpak app-data path (not a doc-portal path)', () {
      expect(
        looksLikeFlatpakPortalPath(
          '/home/becker/.var/app/com.bandpassrecords.dpm/data',
        ),
        isFalse,
      );
    }, testOn: 'linux');

    test('is always false on non-Linux platforms, even for a matching shape', () {
      expect(
        looksLikeFlatpakPortalPath('/run/user/1000/doc/98127/projects'),
        isFalse,
      );
    }, testOn: 'windows || mac-os');
  });
}
