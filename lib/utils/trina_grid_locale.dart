import 'package:flutter/widgets.dart';
import 'package:trina_grid/trina_grid.dart';

/// Trina Grid's own column-menu, filter-popup, date/time-picker and
/// pagination chrome ships hardcoded English text unless a
/// [TrinaGridLocaleText] is supplied. This maps the app's active locale to
/// the closest one Trina Grid ships (or to a locally written one, for a
/// language Trina Grid doesn't cover) so that grid chrome matches the rest
/// of the translated UI.
TrinaGridLocaleText trinaGridLocaleTextFor(BuildContext context) {
  return trinaGridLocaleTextForLanguageCode(
    Localizations.localeOf(context).languageCode,
  );
}

@visibleForTesting
TrinaGridLocaleText trinaGridLocaleTextForLanguageCode(String languageCode) {
  switch (languageCode) {
    case 'pt':
      return const TrinaGridLocaleText.brazilianPortuguese();
    case 'es':
      return const TrinaGridLocaleText.spanish();
    case 'fr':
      return const TrinaGridLocaleText.french();
    case 'de':
      return const TrinaGridLocaleText.german();
    case 'ja':
      return const TrinaGridLocaleText.japanese();
    case 'ru':
      return const TrinaGridLocaleText.russian();
    case 'zh':
      return const TrinaGridLocaleText.china();
    case 'it':
      return _italian;
    default:
      return const TrinaGridLocaleText();
  }
}

// Trina Grid doesn't ship an Italian translation, so it's written here
// following the same field set as the package's other locale constructors.
const _italian = TrinaGridLocaleText(
  // Column menu
  unfreezeColumn: 'Sblocca',
  freezeColumnToStart: 'Blocca all\'inizio',
  freezeColumnToEnd: 'Blocca alla fine',
  autoFitColumn: 'Adatta automaticamente',
  hideColumn: 'Nascondi colonna',
  setColumns: 'Imposta colonne',
  setFilter: 'Imposta filtro',
  resetFilter: 'Reimposta filtro',
  // SetColumns popup
  setColumnsTitle: 'Titolo colonna',
  // Filter popup
  filterColumn: 'Colonna',
  filterType: 'Tipo',
  filterValue: 'Valore',
  filterAllColumns: 'Tutte le colonne',
  filterContains: 'Contiene',
  filterEquals: 'Uguale a',
  filterStartsWith: 'Inizia con',
  filterEndsWith: 'Finisce con',
  filterGreaterThan: 'Maggiore di',
  filterGreaterThanOrEqualTo: 'Maggiore o uguale a',
  filterLessThan: 'Minore di',
  filterLessThanOrEqualTo: 'Minore o uguale a',
  // Date popup
  sunday: 'Do',
  monday: 'Lu',
  tuesday: 'Ma',
  wednesday: 'Me',
  thursday: 'Gi',
  friday: 'Ve',
  saturday: 'Sa',
  // Time column popup
  hour: 'Ora',
  minute: 'Minuto',
  // Common
  loadingText: 'Caricamento',
  selectSearchHint: 'Cerca...',
  multiLineFilterHint: 'Filtro',
  multiLineFilterEditTitle: 'Modifica filtro',
  multiLineFilterOkButton: 'Ok',
  // Pagination
  paginationGoToPageTitle: 'Vai alla pagina',
  paginationGoToPageLabel: 'Numero di pagina',
  paginationCancelButton: 'Annulla',
  paginationGoButton: 'Vai',
  paginationInvalidPageNumberMessage: 'Inserisci un numero di pagina valido',
  paginationGoToPageTooltip: 'Vai alla pagina',
  // Time picker
  timePickerHourLabel: 'Ora',
  timePickerMinuteLabel: 'Minuto',
  timePickerInvalidHourMessage: 'L\'ora deve essere compresa tra 0 e 23',
  timePickerInvalidMinuteMessage:
      'Il minuto deve essere compreso tra 0 e 59',
  timePickerMinTimeMessage: 'L\'orario minimo è',
  timePickerMaxTimeMessage: 'L\'orario massimo è',
  timePickerInvalidValueMessage: 'Valore non valido',
);
