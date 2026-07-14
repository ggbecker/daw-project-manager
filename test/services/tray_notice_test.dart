import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:daw_project_manager/services/tray_notice.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;

  setUp(() async {
    tempDir = await HiveTestHelper.setUp();
    box = await Hive.openBox<String>('settings');
  });

  tearDown(() async {
    await HiveTestHelper.tearDown(tempDir);
  });

  group('TrayNotice.claimFirstHide', () {
    test('returns true on the very first call', () async {
      expect(await TrayNotice.claimFirstHide(box: box), isTrue);
    });

    test('returns false on every subsequent call', () async {
      await TrayNotice.claimFirstHide(box: box);

      expect(await TrayNotice.claimFirstHide(box: box), isFalse);
      expect(await TrayNotice.claimFirstHide(box: box), isFalse);
    });

    test('the claim persists across box close/reopen (app restart)', () async {
      await TrayNotice.claimFirstHide(box: box);
      await box.close();

      final reopened = await Hive.openBox<String>('settings');
      expect(await TrayNotice.claimFirstHide(box: reopened), isFalse);
    });
  });
}
