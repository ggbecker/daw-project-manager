import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/quick_action.dart';

void main() {
  group('parseQuickAction', () {
    test('returns null for empty args (plain relaunch)', () {
      expect(parseQuickAction(const []), isNull);
    });

    test('returns null for an unrecognized argument', () {
      expect(parseQuickAction(const ['--something-else']), isNull);
    });

    test('parses --new-project', () {
      expect(parseQuickAction(const ['--new-project']), isA<NewProjectQuickAction>());
    });

    test('parses --scan-projects', () {
      expect(parseQuickAction(const ['--scan-projects']), isA<ScanProjectsQuickAction>());
    });

    test('parses --open-project=<id> and extracts the id', () {
      final action = parseQuickAction(const ['--open-project=abc-123']);
      expect(action, isA<OpenProjectQuickAction>());
      expect((action as OpenProjectQuickAction).projectId, 'abc-123');
    });

    test('only looks at the first argument', () {
      expect(
        parseQuickAction(const ['--new-project', '--scan-projects']),
        isA<NewProjectQuickAction>(),
      );
    });

    test('an empty project id after the prefix still parses (caller\'s job to validate)', () {
      final action = parseQuickAction(const ['--open-project=']);
      expect(action, isA<OpenProjectQuickAction>());
      expect((action as OpenProjectQuickAction).projectId, '');
    });
  });
}
