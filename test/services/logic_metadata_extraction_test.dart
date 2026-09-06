import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/metadata_extractor.dart';

/// Logic Pro `.logicx` projects are macOS package bundles. BPM and key live
/// in `Alternatives/000/MetaData.plist`, the app version in
/// `Resources/ProjectInformation.plist` — both Apple property lists, read via
/// `plutil` (Logic is macOS-only, so these run there).
///
/// Field names/shapes verified against real projects saved by Logic Pro
/// 12.3.1 in /Users/becker/Music/Logic.
void main() {
  const metaDataPlist = 'Alternatives/000/MetaData.plist';
  const projectInfoPlist = 'Resources/ProjectInformation.plist';

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('logicx_meta_test_');
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  /// Writes an XML plist (`plutil -convert json` reads XML and binary alike)
  /// at [relPath] inside a `<name>.logicx` bundle and returns the bundle path.
  Future<String> makeLogicProject(
    String name, {
    String? metaData,
    String? projectInfo,
  }) async {
    final bundle = Directory(p.join(tmp.path, '$name.logicx'));
    Future<void> write(String rel, String? body) async {
      if (body == null) return;
      final f = File(p.join(bundle.path, rel));
      await f.parent.create(recursive: true);
      await f.writeAsString(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
        '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
        '<plist version="1.0"><dict>$body</dict></plist>\n',
      );
    }

    await write(metaDataPlist, metaData);
    await write(projectInfoPlist, projectInfo);
    return bundle.path;
  }

  test('supportsFullExtraction is true for .logicx', () {
    expect(MetadataExtractor.supportsFullExtraction('/x/Song.logicx'), isTrue);
  });

  test('reads BPM, key and app version from a .logicx bundle', () async {
    final path = await makeLogicProject(
      'Song',
      metaData: '''
        <key>BeatsPerMinute</key><integer>128</integer>
        <key>SongKey</key><string>A</string>
        <key>SongGenderKey</key><string>minor</string>
      ''',
      projectInfo: '''
        <key>LastSavedFrom</key>
        <string>Logic Pro Creator Studio 12.3.1 (6682)</string>
      ''',
    );

    final m = await MetadataExtractor.extractMetadata(path);

    expect(m.dawType, 'Logic Pro');
    expect(m.bpm, 128);
    expect(m.key, 'A minor');
    expect(m.dawVersion, '12.3.1');
  }, testOn: 'mac-os');

  test('defaults SongGenderKey to major and reads a fractional BPM', () async {
    final path = await makeLogicProject(
      'Song',
      metaData: '''
        <key>BeatsPerMinute</key><real>90.5</real>
        <key>SongKey</key><string>C#</string>
        <key>SongGenderKey</key><string>major</string>
      ''',
    );

    final m = await MetadataExtractor.extractMetadata(path);

    expect(m.bpm, closeTo(90.5, 0.001));
    expect(m.key, 'C# major');
    expect(m.dawVersion, isNull); // no ProjectInformation.plist
  }, testOn: 'mac-os');

  test('an integer SongKey maps to a note name', () async {
    final path = await makeLogicProject(
      'Song',
      metaData: '''
        <key>BeatsPerMinute</key><integer>120</integer>
        <key>SongKey</key><integer>9</integer>
        <key>SongGenderKey</key><string>minor</string>
      ''',
    );

    final m = await MetadataExtractor.extractMetadata(path);
    expect(m.key, 'A minor'); // 0=C, 9=A
  }, testOn: 'mac-os');

  test('missing plists yield DAW type only, no throw', () async {
    final bundle = Directory(p.join(tmp.path, 'Empty.logicx'));
    await bundle.create(recursive: true);

    final m = await MetadataExtractor.extractMetadata(bundle.path);

    expect(m.dawType, 'Logic Pro');
    expect(m.bpm, isNull);
    expect(m.key, isNull);
    expect(m.dawVersion, isNull);
  }, testOn: 'mac-os');
}
