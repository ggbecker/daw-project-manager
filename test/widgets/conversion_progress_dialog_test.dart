import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/ui/widgets/conversion_progress_dialog.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required Future<File?> Function(String) convert,
    required void Function(Future<File?> result) onStarted,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => onStarted(
                convertForSharingWithProgress(context, '/x/song.wav',
                    convert: convert),
              ),
              child: const Text('start'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('start'));
    await tester.pump();
  }

  group('convertForSharingWithProgress', () {
    testWidgets('shows a blocking progress dialog while converting',
        (tester) async {
      final completer = Completer<File?>();
      await pumpHost(tester,
          convert: (_) => completer.future, onStarted: (_) {});

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Preparing audio for sharing…'), findsOneWidget);

      completer.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('pops the dialog and returns the file on success',
        (tester) async {
      final completer = Completer<File?>();
      late Future<File?> result;
      await pumpHost(tester,
          convert: (_) => completer.future, onStarted: (r) => result = r);

      completer.complete(File('/x/song.mp3'));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect((await result)?.path, File('/x/song.mp3').path);
    });

    testWidgets('pops the dialog and returns null when conversion fails',
        (tester) async {
      final completer = Completer<File?>();
      late Future<File?> result;
      await pumpHost(tester,
          convert: (_) => completer.future, onStarted: (r) => result = r);

      completer.complete(null);
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(await result, isNull);
    });

    testWidgets('pops the dialog even when the converter throws',
        (tester) async {
      // The expectation must attach to the future the moment it's created,
      // otherwise the error counts as unhandled before we can await it.
      late Future<void> expectation;
      await pumpHost(tester,
          convert: (_) async => throw Exception('boom'),
          onStarted: (r) => expectation = expectLater(r, throwsException));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      await expectation;
    });
  });
}
