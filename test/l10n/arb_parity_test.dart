import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the CLAUDE.md non-negotiable that every UI string key added to
/// app_en.arb is replicated in all other locale ARBs. A missing key doesn't
/// fail the build — gen-l10n silently falls back — so without this test a
/// forgotten locale ships untranslated/missing strings unnoticed.
void main() {
  const locales = ['pt', 'es', 'fr', 'it', 'de', 'ru', 'ja', 'zh'];

  Set<String> keysOf(String locale) {
    final file = File('lib/l10n/app_$locale.arb');
    final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    // '@key' entries are metadata (descriptions/placeholders), '@@locale' is
    // the locale marker — neither needs replication.
    return map.keys.where((k) => !k.startsWith('@')).toSet();
  }

  group('ARB locale parity', () {
    final enKeys = keysOf('en');

    for (final locale in locales) {
      test('app_$locale.arb has exactly the keys of app_en.arb', () {
        final localeKeys = keysOf(locale);
        final missing = enKeys.difference(localeKeys).toList()..sort();
        final extra = localeKeys.difference(enKeys).toList()..sort();

        expect(missing, isEmpty,
            reason: 'app_$locale.arb is missing keys present in app_en.arb: '
                '$missing');
        expect(extra, isEmpty,
            reason: 'app_$locale.arb has keys absent from app_en.arb: $extra');
      });
    }
  });
}
