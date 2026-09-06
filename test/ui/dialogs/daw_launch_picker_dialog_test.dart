import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/dialogs/daw_launch_picker_dialog.dart';

import '../../helpers/test_factories.dart';

/// The "which DAW location?" picker shown when a DAW type has several
/// configured overrides that all resolve.
void main() {
  Future<String?> pumpAndPick(
    WidgetTester tester, {
    required List<String> paths,
    String? tapPath,
  }) async {
    String? result;
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDawLaunchPickerDialog(
                  context,
                  dawType: 'Ableton Live',
                  project: TestFactories.makeProject(id: 'p1'),
                  paths: paths,
                );
                done = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    if (tapPath != null) {
      await tester.tap(find.text(tapPath));
    } else {
      await tester.tap(find.text('Cancel'));
    }
    await tester.pumpAndSettle();
    expect(done, isTrue);
    return result;
  }

  testWidgets('lists every path and returns the tapped one', (tester) async {
    final picked = await pumpAndPick(
      tester,
      paths: const ['/Applications/Live 11.app', '/Applications/Live 12.app'],
      tapPath: '/Applications/Live 12.app',
    );
    expect(picked, '/Applications/Live 12.app');
  });

  testWidgets('returns null on Cancel', (tester) async {
    final picked = await pumpAndPick(
      tester,
      paths: const ['/Applications/Live 11.app', '/Applications/Live 12.app'],
    );
    expect(picked, isNull);
  });
}
