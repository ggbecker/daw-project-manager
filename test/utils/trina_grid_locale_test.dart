import 'package:flutter_test/flutter_test.dart';
import 'package:trina_grid/trina_grid.dart';

import 'package:daw_project_manager/utils/trina_grid_locale.dart';

void main() {
  group('trinaGridLocaleTextForLanguageCode', () {
    const supportedAppLanguages = [
      'en',
      'pt',
      'es',
      'fr',
      'it',
      'de',
      'ru',
      'ja',
      'zh',
    ];

    test('returns a non-English translation for every supported non-English '
        'app language', () {
      // Regression guard: it's easy to add a new app locale (app_xx.arb)
      // without remembering that Trina Grid's own filter/column-menu chrome
      // needs a matching case here too, silently leaving that language on
      // English grid chrome.
      final defaultText = const TrinaGridLocaleText();
      for (final code in supportedAppLanguages) {
        if (code == 'en') continue;
        final text = trinaGridLocaleTextForLanguageCode(code);
        expect(
          text.filterContains,
          isNot(defaultText.filterContains),
          reason: 'Language "$code" is falling back to English grid chrome',
        );
      }
    });

    test('maps Portuguese to Trina Grid\'s Brazilian Portuguese text', () {
      final text = trinaGridLocaleTextForLanguageCode('pt');
      expect(text.filterContains, 'Contenha');
    });

    test('maps Italian to the locally written Italian text', () {
      final text = trinaGridLocaleTextForLanguageCode('it');
      expect(text.filterContains, 'Contiene');
      expect(text.resetFilter, 'Reimposta filtro');
    });

    test('falls back to English for an unsupported language code', () {
      final text = trinaGridLocaleTextForLanguageCode('xx');
      expect(text.filterContains, const TrinaGridLocaleText().filterContains);
    });
  });
}
