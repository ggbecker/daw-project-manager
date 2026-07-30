import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/profile.dart';

Profile _makeProfile({
  String? artworkPath,
  List<String>? artworkPaths,
  String? pressKitPath,
  List<String>? pressKitPaths,
}) {
  return Profile(
    id: 'p1',
    name: 'Test Profile',
    createdAt: DateTime(2024, 1, 1),
    artworkPath: artworkPath,
    artworkPaths: artworkPaths,
    pressKitPath: pressKitPath,
    pressKitPaths: pressKitPaths,
  );
}

void main() {
  group('Profile.getAllArtworkPaths', () {
    test('combines the legacy singular artworkPath with the artworkPaths list', () {
      final profile = _makeProfile(artworkPath: '/legacy.png', artworkPaths: ['/a.png', '/b.png']);
      expect(profile.getAllArtworkPaths(), ['/legacy.png', '/a.png', '/b.png']);
    });

    test('returns just the list when there is no legacy path', () {
      final profile = _makeProfile(artworkPaths: ['/a.png']);
      expect(profile.getAllArtworkPaths(), ['/a.png']);
    });

    test('returns just the legacy path when there is no list', () {
      final profile = _makeProfile(artworkPath: '/legacy.png');
      expect(profile.getAllArtworkPaths(), ['/legacy.png']);
    });
  });

  group('Profile artwork migration off the legacy singular field', () {
    // Regression: profile_edit_page.dart's _addArtwork/_removeArtwork used to
    // fold getAllArtworkPaths() (legacy + list) into a new list and save it
    // via copyWith(artworkPaths: merged) alone. That left the legacy
    // artworkPath field untouched, so getAllArtworkPaths() kept re-adding it
    // on every future read — a removed artwork reappeared after navigating
    // away and back, and re-adding artwork could duplicate the legacy entry
    // into the list. The fix always pairs the merged-list write with
    // clearArtworkPath: true, permanently retiring the legacy field the
    // first time it's folded in.
    test('removing the legacy artwork via merge-then-clear does not resurrect it', () {
      var profile = _makeProfile(artworkPath: '/legacy.png', artworkPaths: ['/a.png']);

      // Simulate _removeArtwork('/legacy.png'): merge, remove, save back
      // with the legacy field cleared.
      final merged = List<String>.from(profile.getAllArtworkPaths())..remove('/legacy.png');
      profile = profile.copyWith(
        artworkPaths: merged.isEmpty ? null : merged,
        clearArtworkPath: true,
      );

      expect(profile.artworkPath, isNull);
      expect(profile.getAllArtworkPaths(), ['/a.png']);
    });

    test('without clearing the legacy field, a removed artwork would incorrectly reappear', () {
      // This documents the bug itself: merging and saving to artworkPaths
      // without clearing artworkPath leaves the legacy entry able to
      // resurface on the next getAllArtworkPaths() call.
      var profile = _makeProfile(artworkPath: '/legacy.png', artworkPaths: ['/a.png']);

      final merged = List<String>.from(profile.getAllArtworkPaths())..remove('/legacy.png');
      profile = profile.copyWith(artworkPaths: merged.isEmpty ? null : merged);

      expect(profile.getAllArtworkPaths(), contains('/legacy.png'));
    });

    test('adding artwork via merge-then-clear does not duplicate the legacy entry', () {
      var profile = _makeProfile(artworkPath: '/legacy.png');

      final merged = List<String>.from(profile.getAllArtworkPaths());
      if (!merged.contains('/new.png')) merged.add('/new.png');
      profile = profile.copyWith(artworkPaths: merged, clearArtworkPath: true);

      expect(profile.getAllArtworkPaths(), ['/legacy.png', '/new.png']);
    });
  });

  group('Profile.getAllPressKitPaths', () {
    test('combines the legacy singular pressKitPath with the pressKitPaths list', () {
      final profile = _makeProfile(pressKitPath: '/legacy.pdf', pressKitPaths: ['/a.pdf']);
      expect(profile.getAllPressKitPaths(), ['/legacy.pdf', '/a.pdf']);
    });

    test('removing the legacy press kit via merge-then-clear does not resurrect it', () {
      var profile = _makeProfile(pressKitPath: '/legacy.pdf', pressKitPaths: ['/a.pdf']);

      final merged = List<String>.from(profile.getAllPressKitPaths())..remove('/legacy.pdf');
      profile = profile.copyWith(
        pressKitPaths: merged.isEmpty ? null : merged,
        clearPressKitPath: true,
      );

      expect(profile.pressKitPath, isNull);
      expect(profile.getAllPressKitPaths(), ['/a.pdf']);
    });
  });
}
