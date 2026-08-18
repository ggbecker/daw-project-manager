import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/windows_file_association.dart';

// The registry contents of the machine running the tests are not something a
// test can assert on — whether '.cpr' is registered here says nothing about
// whether it's registered on a tester's machine, and that variability is the
// entire reason this lookup exists. What is pinned instead is the contract
// the diagnostics rely on: it answers on Windows, stays out of the way
// elsewhere, and never throws on a missing key.
void main() {
  group('WindowsFileAssociation.describe', () {
    test('returns null off Windows', () {
      expect(WindowsFileAssociation.describe('.cpr'), isNull);
    }, testOn: 'mac-os || linux');

    test('reports the extension it was asked about', () {
      expect(WindowsFileAssociation.describe('.cpr')?['ext'], '.cpr');
    }, testOn: 'windows');

    test('reports every key even when nothing is registered', () {
      // A made-up extension nothing can plausibly own: the lookup must come
      // back with nulls rather than throwing or returning a partial map,
      // since "nothing registered" is the finding we most want reported.
      final described = WindowsFileAssociation.describe('.dawpmtestnope');
      expect(described, isNotNull);
      expect(described!.keys,
          containsAll(['ext', 'userChoiceProgId', 'classesRootProgId', 'openCommand']));
      expect(described['userChoiceProgId'], isNull);
      expect(described['classesRootProgId'], isNull);
      expect(described['openCommand'], isNull);
    }, testOn: 'windows');

    test('notes when the path had no extension at all', () {
      final described = WindowsFileAssociation.describe('');
      expect(described?['ext'], '(none)');
    }, testOn: 'windows');
  });

  group('hasNoHandler', () {
    test('is true when nothing is registered by any route', () {
      // The '.rpp with no DAW registered' case: this is what turns into the
      // plain-language message on the failure snackbar.
      expect(
        WindowsFileAssociation.hasNoHandler({
          'ext': '.rpp',
          'userChoiceProgId': null,
          'classesRootProgId': null,
          'openCommand': null,
        }),
        isTrue,
      );
    });

    test('is false when the user has explicitly chosen an app', () {
      expect(
        WindowsFileAssociation.hasNoHandler({
          'ext': '.rpp',
          'userChoiceProgId': 'REAPER.ProjectFile',
          'classesRootProgId': null,
          'openCommand': r'"C:\Program Files\REAPER\reaper.exe" "%1"',
        }),
        isFalse,
      );
    });

    test('is false when only the machine-wide association exists', () {
      expect(
        WindowsFileAssociation.hasNoHandler({
          'ext': '.rpp',
          'userChoiceProgId': null,
          'classesRootProgId': 'REAPER.ProjectFile',
          'openCommand': r'"C:\Program Files\REAPER\reaper.exe" "%1"',
        }),
        isFalse,
      );
    });

    test('is false for a ProgId whose open command is missing', () {
      // Registered but broken is a different diagnosis from unregistered,
      // and must not be reported as "nothing is associated".
      expect(
        WindowsFileAssociation.hasNoHandler({
          'ext': '.rpp',
          'userChoiceProgId': null,
          'classesRootProgId': 'REAPER.ProjectFile',
          'openCommand': null,
        }),
        isFalse,
      );
    });
  });
}
