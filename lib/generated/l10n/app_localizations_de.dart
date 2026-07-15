// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'DAW Projektmanager';

  @override
  String get projectDetails => 'Projektdetails';

  @override
  String get back => 'Zurück';

  @override
  String get save => 'Speichern';

  @override
  String get enable => 'Aktivieren';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get customInterval => 'Benutzerdefiniert';

  @override
  String get close => 'Schließen';

  @override
  String get launch => 'Öffnen';

  @override
  String get view => 'Anzeigen';

  @override
  String get openFolder => 'Ordner öffnen';

  @override
  String get openInDaw => 'Im DAW starten';

  @override
  String get extract => 'Extrahieren';

  @override
  String get extracting => 'Extrahieren…';

  @override
  String get extractingMetadata => 'Metadaten werden extrahiert...';

  @override
  String get deepScan => 'Tiefenscan';

  @override
  String get rescan => 'Erneut scannen';

  @override
  String get refreshProject => 'Aktualisieren';

  @override
  String get scanning => 'Scannen…';

  @override
  String get projectName => 'Projektname';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tonart (z.B. C#m, F-Dur)';

  @override
  String get notes => 'Notizen';

  @override
  String get expandNotes => 'Erweitern';

  @override
  String get collapseNotes => 'Einklappen';

  @override
  String get projectPhase => 'Projektphase';

  @override
  String get failedToLoad => 'Laden fehlgeschlagen';

  @override
  String get fileMissing => 'Datei fehlt.';

  @override
  String launchingProject(String projectName) {
    return 'Öffne $projectName…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return 'Fehler beim Öffnen von $projectName';
  }

  @override
  String get clearLibrary => 'Bibliothek leeren';

  @override
  String get clearLibraryMessage =>
      'Dies entfernt alle gespeicherten Projekte und Quellordner. Fortfahren?';

  @override
  String get clear => 'Leeren';

  @override
  String get roots => 'Projektordner';

  @override
  String get pathsSettingsDangerZoneTitle => 'Bibliothek';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Alle Projekte und Projektordner des aktuellen Profils löschen.';

  @override
  String get projectFoldersSectionTitle => 'Projektordner';

  @override
  String get projectFoldersSectionSubtitle =>
      'Ordner, die nach DAW-Projekten durchsucht werden.';

  @override
  String get projectFoldersEmptyTitle => 'Noch keine Projektordner';

  @override
  String get projectFoldersEmptySubtitle =>
      'Fügen Sie mindestens einen Ordner hinzu, um mit dem Scannen zu beginnen.';

  @override
  String get notScannedYet => 'Noch nicht gescannt';

  @override
  String lastScan(String date) {
    return 'Letzter Scan: $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Ausgeschlossene Ordner';

  @override
  String get excludedFoldersSectionSubtitle =>
      'Diese Ordner werden beim Scannen übersprungen, auch wenn sie in einem Projektordner liegen.';

  @override
  String get addExcludedFolder => 'Ausgeschlossen hinzufügen';

  @override
  String get selectExcludedFolder => 'Ordner zum Ausschließen auswählen';

  @override
  String get excludedFoldersEmptyTitle => 'Keine ausgeschlossenen Ordner';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Optional: Ordner hinzufügen, die nie gescannt werden sollen.';

  @override
  String get removeExcludedFolderTitle => 'Ausgeschlossenen Ordner entfernen?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'Dieser Ordner wird nicht mehr ausgeschlossen:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'Dieser Ordner wird nicht mehr ausgeschlossen.';

  @override
  String get desktopOnlyPathsSettings =>
      'Diese Seite ist nur in der Desktop-App verfügbar.';

  @override
  String get removeProjectFolderTitle => 'Projektordner entfernen?';

  @override
  String removeProjectFolderMessage(String path) {
    return 'Möchten Sie \"$path\" wirklich entfernen? Dadurch werden auch alle Projekte aus diesem Ordner entfernt, die nicht in Veröffentlichungen sind.';
  }

  @override
  String get projects => 'Projekte';

  @override
  String get hidden => 'versteckt';

  @override
  String get profileManager => 'Profilverwaltung';

  @override
  String get createNewProfile => 'Neues Profil erstellen';

  @override
  String get profileName => 'Profilname';

  @override
  String get create => 'Erstellen';

  @override
  String get profiles => 'Profile';

  @override
  String get active => 'Aktiv';

  @override
  String get switchProfile => 'Wechseln';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get addFolder => 'Ordner hinzufügen';

  @override
  String get searchProjects => 'Projekte suchen...';

  @override
  String get searchReleases => 'Veröffentlichungen suchen...';

  @override
  String get searchPlaylists => 'Playlists suchen...';

  @override
  String get noReleasesFound => 'Keine Veröffentlichungen gefunden';

  @override
  String get noPlaylistsFound => 'Keine Playlists gefunden';

  @override
  String get tryDifferentSearch => 'Versuchen Sie einen anderen Suchbegriff';

  @override
  String get deepScanConfirm =>
      'Der Tiefenscan extrahiert vollständige Metadaten aus Projektdateien:\n• BPM (Schläge Pro Minute)\n• Tonart\n• DAW-Version\nDerzeit unterstützt: Ableton Live, Cubase und Bitwig Studio.\n\nDies ist langsamer als ein regulärer Scan und kann eine Weile dauern. Fortfahren?';

  @override
  String get deepScanOnlyUnscanned => 'Nur Projekte ohne Metadaten scannen';

  @override
  String get metadataExtractedSuccessfully =>
      'Metadaten erfolgreich extrahiert';

  @override
  String failedToExtractMetadata(String error) {
    return 'Metadatenextraktion fehlgeschlagen: $error';
  }

  @override
  String get saved => 'Gespeichert';

  @override
  String get failedToLaunchDaw => 'DAW konnte nicht geöffnet werden';

  @override
  String get releaseDetails => 'Veröffentlichungsdetails';

  @override
  String get releaseNotFound => 'Veröffentlichung nicht gefunden';

  @override
  String get error => 'Fehler';

  @override
  String get loading => 'Laden...';

  @override
  String get deleteProfile => 'Profil löschen';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Möchten Sie \"$profileName\" wirklich löschen? Dies löscht alle Projekte, Projektordner und Veröffentlichungen dieses Profils.';
  }

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get changePhoto => 'Foto ändern';

  @override
  String get remove => 'Entfernen';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Sind Sie sicher, dass Sie \"$trackName\" aus dieser Veröffentlichung entfernen möchten?';
  }

  @override
  String get saveName => 'Namen speichern';

  @override
  String get profilePhotoUpdated => 'Profilfoto aktualisiert.';

  @override
  String get profilePhotoRemoved => 'Profilfoto entfernt.';

  @override
  String profileRenamed(String newName) {
    return 'Profil umbenannt in \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Profil \"$name\" erfolgreich erstellt';
  }

  @override
  String profileDeleted(String name) {
    return 'Profil \"$name\" gelöscht';
  }

  @override
  String get pleaseEnterProfileName => 'Bitte geben Sie einen Profilnamen ein';

  @override
  String failedToCreateProfile(String error) {
    return 'Profil konnte nicht erstellt werden: $error';
  }

  @override
  String get noProfilesFound =>
      'Keine Profile gefunden. Erstellen Sie eines oben.';

  @override
  String get clearLibraryTooltip =>
      'Bibliothek leeren (Projekte und Projektordner)';

  @override
  String lastModified(String date) {
    return 'Zuletzt geändert: $date';
  }

  @override
  String get name => 'Name';

  @override
  String get status => 'Status';

  @override
  String get phase => 'Phase';

  @override
  String get filterByPhase => 'Nach Phase filtern';

  @override
  String get filters => 'Filter';

  @override
  String get allPhases => 'Alle Phasen';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => 'Zuletzt Geändert';

  @override
  String get actions => 'Aktionen';

  @override
  String get hide => 'Verstecken';

  @override
  String get unhide => 'Anzeigen';

  @override
  String get extractMetadata => 'Metadaten Extrahieren';

  @override
  String get createRelease => 'Veröffentlichung Erstellen';

  @override
  String get clearSelection => 'Auswahl Löschen';

  @override
  String get selectAllProjects => 'Alle Projekte auswählen';

  @override
  String get switchingProfiles => 'Profile wechseln...';

  @override
  String get scanningProjects => 'Projekte scannen...';

  @override
  String get search => 'Suchen';

  @override
  String get projectsTab => 'Projekte';

  @override
  String get releasesTab => 'Veröffentlichungen';

  @override
  String get showHidden => 'Versteckte Anzeigen';

  @override
  String get showAll => 'Alle Anzeigen';

  @override
  String get showOnlyHidden => 'Nur Versteckte Anzeigen';

  @override
  String get deleteRootPath => 'Projektordner entfernen';

  @override
  String deleteRootPathMessage(String path) {
    return 'Möchten Sie \"$path\" wirklich entfernen? Dies entfernt auch alle Projekte aus diesem Ordner, die nicht in Veröffentlichungen sind.';
  }

  @override
  String rootsCount(int count) {
    return 'Projektordner: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Projekte: $count';
  }

  @override
  String get hiddenOnly => '(nur versteckt)';

  @override
  String hiddenCount(int count) {
    return '($count versteckt)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count Projekt$plural versteckt.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count Projekt$plural angezeigt.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Projekte konnten nicht versteckt werden: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Projekte konnten nicht angezeigt werden: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Sind Sie sicher, dass Sie \"$projectName\" ausblenden möchten?';
  }

  @override
  String releaseCreated(String title) {
    return 'Veröffentlichung \"$title\" erfolgreich erstellt.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Veröffentlichung konnte nicht erstellt werden: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Fehler beim Hinzufügen des Ordners: $error';
  }

  @override
  String get folderAlreadyAdded => 'Dieser Ordner wurde bereits hinzugefügt.';

  @override
  String get noProjectsFoundInRoots =>
      'Keine Projekte in den ausgewählten Projektordnern gefunden.';

  @override
  String get selectProjectsFolder => 'Wählen Sie einen Projektordner';

  @override
  String get enterReleaseTitle => 'Veröffentlichungstitel Eingeben';

  @override
  String get releaseTitle => 'Veröffentlichungstitel';

  @override
  String get enterReleaseTitleHint => 'Veröffentlichungstitel eingeben';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Metadaten für $count Projekt$plural extrahiert. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count fehlgeschlagen.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'BPM-Datei konnte nicht geschrieben werden: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Tonart-Datei konnte nicht geschrieben werden: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Öffnen fehlgeschlagen: $error';
  }

  @override
  String get libraryCleared => 'Bibliothek geleert.';

  @override
  String scanType(String type) {
    return '$type Scan';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type abgeschlossen: $count Projekt$plural hinzugefügt/aktualisiert.';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count Projekt$plural ausgewählt';
  }

  @override
  String openingFolder(String projectName) {
    return 'Öffne Ordner für $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Ordner konnte nicht geöffnet werden: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'Betriebssystem wird zum Öffnen von Ordnern nicht unterstützt.';

  @override
  String get noProjectsAvailable =>
      'Keine Projekte verfügbar. Bitte fügen Sie zuerst Projekte hinzu.';

  @override
  String get createNewRelease => 'Neue Veröffentlichung Erstellen';

  @override
  String get deleteRelease => 'Veröffentlichung Löschen';

  @override
  String deleteReleaseMessage(String title) {
    return 'Möchten Sie \"$title\" wirklich löschen?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Veröffentlichung \"$title\" gelöscht.';
  }

  @override
  String get selectTracks => 'Titel Auswählen';

  @override
  String get continueButton => 'Fortfahren';

  @override
  String get noReleasesYet => 'Noch keine Veröffentlichungen';

  @override
  String get createFirstRelease =>
      'Erstellen Sie Ihre erste Veröffentlichung, indem Sie Titel aus Ihren Projekten auswählen';

  @override
  String releasesCount(int count) {
    return 'Veröffentlichungen ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Fehler beim Laden der Veröffentlichungen: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Titel ($count)';
  }

  @override
  String get addTracks => 'Titel Hinzufügen';

  @override
  String get allProjectsAlreadyInRelease =>
      'Alle Projekte sind bereits in dieser Veröffentlichung.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return '$count Titel$plural zur Veröffentlichung hinzugefügt.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Veröffentlichungsdateien ($count)';
  }

  @override
  String get addFiles => 'Dateien Hinzufügen';

  @override
  String addedFilesToRelease(int count, String plural) {
    return '$count Datei$plural zur Veröffentlichung hinzugefügt.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Dateien konnten nicht hinzugefügt werden: $error';
  }

  @override
  String get noFilesToDownload => 'Keine Dateien zum Herunterladen.';

  @override
  String zipFileSaved(String path) {
    return 'ZIP-Datei gespeichert in: $path';
  }

  @override
  String get creatingZipFile => 'ZIP-Datei wird erstellt...';

  @override
  String failedToCreateZip(String error) {
    return 'ZIP konnte nicht erstellt werden: $error';
  }

  @override
  String get selectedFileDoesNotExist => 'Ausgewählte Datei existiert nicht.';

  @override
  String get imageSavedSuccessfully => 'Bild erfolgreich gespeichert!';

  @override
  String failedToSaveImage(String error) {
    return 'Bild konnte nicht gespeichert werden: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Fehler beim Laden der Veröffentlichung: $error';
  }

  @override
  String get errorLoadingProjects => 'Fehler beim Laden der Projekte: null';

  @override
  String get releaseSaved => 'Veröffentlichung gespeichert.';

  @override
  String get releaseDate => 'Veröffentlichungsdatum';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Veröffentlichungsdatum konnte nicht gespeichert werden: $error';
  }

  @override
  String get releaseDateSaved => 'Veröffentlichungsdatum gespeichert.';

  @override
  String get releaseDateCleared => 'Veröffentlichungsdatum gelöscht.';

  @override
  String get saveReleaseFilesZip => 'Veröffentlichungsdateien ZIP speichern';

  @override
  String get failedToOpenFile => 'Datei konnte nicht geöffnet werden';

  @override
  String failedToPlayAudio(String error) {
    return 'Audio konnte nicht abgespielt werden: $error';
  }

  @override
  String get renameFile => 'Datei Umbenennen';

  @override
  String get selectTracksToAdd => 'Titel zum Hinzufügen Auswählen';

  @override
  String get fileNameUpdated => 'Dateiname aktualisiert.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Fehler beim Aktualisieren des Dateinamens: $error';
  }

  @override
  String get deleteFile => 'Datei Löschen';

  @override
  String deleteFileMessage(String fileName) {
    return 'Möchten Sie \"$fileName\" wirklich löschen?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'Datei \"$fileName\" gelöscht.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Datei konnte nicht gelöscht werden: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Ordner konnte nicht geöffnet werden: $error';
  }

  @override
  String get artwork => 'Cover';

  @override
  String get title => 'Titel';

  @override
  String get tracks => 'Titel';

  @override
  String get description => 'Beschreibung';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Titel zum Einbeziehen in die Veröffentlichung auswählen ($count ausgewählt)';
  }

  @override
  String get searchTracks => 'Titel suchen';

  @override
  String get searchTracksHint => 'Suche nach Name oder DAW-Typ';

  @override
  String get noTracksFound => 'Keine Titel gefunden';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get fileNotFound => 'Datei nicht gefunden';

  @override
  String get fileName => 'Dateiname';

  @override
  String get editTodo => 'Aufgabe Bearbeiten';

  @override
  String get todoText => 'Aufgabentext';

  @override
  String get enterTodoText => 'Aufgabentext eingeben';

  @override
  String get addNewTodo => 'Neue Aufgabe hinzufügen';

  @override
  String get enterTodoItem => 'Aufgabenelement eingeben';

  @override
  String get todoList => 'Aufgabenliste';

  @override
  String get todoTemplates => 'TODO-Vorlagen';

  @override
  String get createTemplate => 'Vorlage Erstellen';

  @override
  String get editTemplate => 'Vorlage Bearbeiten';

  @override
  String get deleteTemplate => 'Vorlage Löschen';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Möchten Sie die Vorlage \"$name\" wirklich löschen?';
  }

  @override
  String get templateName => 'Vorlagenname';

  @override
  String get templateNameHint => 'z.B. Mixing-Checkliste';

  @override
  String get templateItems => 'Vorlagenelemente';

  @override
  String get templateItemsHint => 'Ein Element pro Zeile';

  @override
  String get templateNameAndItemsRequired =>
      'Vorlagenname und Elemente sind erforderlich';

  @override
  String get templateItemsRequired => 'Mindestens ein Element ist erforderlich';

  @override
  String get templateCreated => 'Vorlage erstellt';

  @override
  String get templateUpdated => 'Vorlage aktualisiert';

  @override
  String get templateDeleted => 'Vorlage gelöscht';

  @override
  String get noTemplatesYet => 'Noch keine Vorlagen';

  @override
  String get createFirstTemplate => 'Erstellen Sie Ihre erste TODO-Vorlage';

  @override
  String templateItemCount(int count) {
    return '$count Element(e)';
  }

  @override
  String get selectTemplate => 'Vorlage Auswählen';

  @override
  String get importFromTemplate => 'Aus Vorlage Importieren';

  @override
  String get manageTemplates => 'Vorlagen Verwalten';

  @override
  String get noTemplatesAvailable =>
      'Keine Vorlagen verfügbar. Erstellen Sie zuerst eine.';

  @override
  String templateImported(String name, int count) {
    return 'Vorlage \"$name\" importiert ($count Elemente)';
  }

  @override
  String get errorLoadingTemplates => 'Fehler beim Laden der Vorlagen';

  @override
  String get importTodos => 'Aufgaben aus Datei importieren';

  @override
  String get noTodosInFile => 'Keine Aufgaben in Datei gefunden';

  @override
  String todosImported(int count) {
    return '$count Aufgabe(n) erfolgreich importiert';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Fehler beim Importieren: $error';
  }

  @override
  String get addToRelease => 'Zur Veröffentlichung Hinzufügen';

  @override
  String get createNew => 'Neu Erstellen';

  @override
  String get addToExisting => 'Zu Existierender Hinzufügen';

  @override
  String get createAndAdd => 'Erstellen und Hinzufügen';

  @override
  String get selectRelease => 'Wählen Sie eine Veröffentlichung';

  @override
  String get noExistingReleasesFound =>
      'Keine bestehenden Veröffentlichungen gefunden.';

  @override
  String get addToSelectedRelease =>
      'Zur Ausgewählten Veröffentlichung Hinzufügen';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Profilfoto konnte nicht gespeichert werden: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Profilfoto konnte nicht entfernt werden: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Profil konnte nicht umbenannt werden: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Profil konnte nicht gelöscht werden: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Fehler beim Laden der Profile: $error';
  }

  @override
  String get projectPhaseIdea => 'Idee';

  @override
  String get projectPhaseArranging => 'Arrangement';

  @override
  String get projectPhaseMixing => 'Mischen';

  @override
  String get projectPhaseMastering => 'Mastering';

  @override
  String get projectPhaseFinished => 'Fertig';

  @override
  String get changeStatus => 'Phase Ändern';

  @override
  String get selectNewStatus => 'Neue Phase auswählen:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Phase für $count Projekt$plural auf \"$status\" geändert';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Phase für $successCount Projekt$successPlural auf \"$status\" geändert, $failCount fehlgeschlagen$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Fehler beim Ändern der Phase: $error';
  }

  @override
  String get tooltipEditProfileName => 'Profilname bearbeiten';

  @override
  String get tooltipAddTodo => 'Aufgabe hinzufügen';

  @override
  String get tooltipClearDate => 'Datum löschen';

  @override
  String get tooltipPickDate => 'Datum auswählen';

  @override
  String get tooltipViewDetails => 'Details Anzeigen';

  @override
  String get tooltipLaunchInDaw => 'Im DAW öffnen';

  @override
  String get tooltipRemoveFromRelease => 'Aus Veröffentlichung Entfernen';

  @override
  String get profile => 'Profil';

  @override
  String get noDateSet => 'Kein Datum festgelegt';

  @override
  String get imageNotFound => 'Bild nicht gefunden';

  @override
  String get clickToBrowseArtwork => 'Klicken Sie, um Artwork zu durchsuchen';

  @override
  String get dropImageHere => 'Drop image here';

  @override
  String get removeArtwork => 'Remove Artwork';

  @override
  String get removeArtworkConfirm =>
      'Remove this artwork? The image file will be deleted.';

  @override
  String get noFilesAddedYet =>
      'Noch keine Dateien hinzugefügt.\nKlicken Sie auf \"Dateien Hinzufügen\", um Veröffentlichungsdateien hochzuladen.';

  @override
  String get noTodosYet => 'Noch keine Aufgaben. Fügen Sie oben eine hinzu.';

  @override
  String get done => 'Erledigt';

  @override
  String get backupAndRestore => 'Sicherung und Wiederherstellung';

  @override
  String get exportBackup => 'Sicherung Exportieren';

  @override
  String get importBackup => 'Sicherung Importieren';

  @override
  String get backupExportedSuccessfully => 'Sicherung erfolgreich exportiert';

  @override
  String failedToExportBackup(String error) {
    return 'Fehler beim Exportieren der Sicherung: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Sicherung erfolgreich importiert: $projectsCount Projekte, $rootsCount Projektordner, $releasesCount Veröffentlichungen';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Fehler beim Importieren der Sicherung: $error';
  }

  @override
  String get importBackupMessage =>
      'Wählen Sie, wie die Sicherung importiert werden soll:';

  @override
  String get mergeWithCurrentProfile =>
      'Mit dem aktuellen aktiven Profil zusammenführen';

  @override
  String get replaceCurrentProfile =>
      'Das aktuelle Profil vollständig ersetzen (WARNUNG: Dies löscht alle Daten des aktuellen Profils)';

  @override
  String get createNewProfileForImport =>
      'Ein neues Profil für diese Daten erstellen';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Sicherung in neues Profil \"$profileName\" importiert: $projectsCount Projekte, $rootsCount Projektordner, $releasesCount Veröffentlichungen';
  }

  @override
  String get noProfileSelected => 'Kein Profil ausgewählt';

  @override
  String get exportBackupDialogTitle => 'Sicherung Exportieren';

  @override
  String get importBackupDialogTitle => 'Sicherung Importieren';

  @override
  String get invalidBackupFileFormat =>
      'Ungültiges Sicherungsdateiformat: Version fehlt';

  @override
  String get profileNameRequiredForNewProfile =>
      'Der Profilname ist beim Erstellen eines neuen Profils erforderlich';

  @override
  String get currentProfileRequired =>
      'Das aktuelle Profil ist für den Modus Zusammenführen oder Ersetzen erforderlich';

  @override
  String get previewSong => 'Vorschau-Song';

  @override
  String get noPreviewSongTitle => 'Kein Vorschau-Song';

  @override
  String get noPreviewSongMessage =>
      'Für dieses Projekt ist kein Vorschau-Song festgelegt. Wähle eine Audiodatei aus, um sie zu laden und abzuspielen.';

  @override
  String get noPreviewSongDragHint =>
      'Du kannst auch eine Audiodatei direkt auf die Projektzeile in der Tabelle ziehen.';

  @override
  String get previewSongRemoved => 'Vorschau-Song entfernt';

  @override
  String get previewSongAdded => 'Vorschau-Song hinzugefügt';

  @override
  String get previewSongFileNotFound => 'Vorschau-Song-Datei nicht gefunden';

  @override
  String get previewSongFileNotFoundMessage =>
      'Die Vorschau-Songdatei wurde nicht auf dem Laufwerk gefunden. Möchten Sie eine neue Datei auswählen oder den Eintrag entfernen?';

  @override
  String get selectNewFile => 'Neue Datei auswählen';

  @override
  String failedToPlayPreview(String error) {
    return 'Wiedergabe der Vorschau fehlgeschlagen: $error';
  }

  @override
  String get removePreviewSong => 'Vorschau-Song entfernen';

  @override
  String get removePreviewSongConfirm =>
      'Sind Sie sicher, dass Sie den Vorschau-Song entfernen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get noPreviewSongSelected => 'Kein Vorschau-Song ausgewählt';

  @override
  String get changePreviewSong => 'Vorschau-Song ändern';

  @override
  String get selectPreviewSong => 'Vorschau-Song auswählen';

  @override
  String get dropAudioFileHere => 'Audio-Datei hier ablegen';

  @override
  String projectAge(String age) {
    return 'Projektalter: $age';
  }

  @override
  String createdDate(String date) {
    return 'erstellt $date';
  }

  @override
  String completedIn(String duration) {
    return 'Abgeschlossen in: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'fertiggestellt $date';
  }

  @override
  String get dateToday => 'heute';

  @override
  String get dateYesterday => 'gestern';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Wochen',
      one: 'vor 1 Woche',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Monaten',
      one: 'vor 1 Monat',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Jahren',
      one: 'vor 1 Jahr',
    );
    return '$_temp0';
  }

  @override
  String ageYearsMonths(
    int years,
    String yearPlural,
    int months,
    String monthPlural,
  ) {
    return '$years Jahr$yearPlural, $months Monat$monthPlural';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years Jahr$plural';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months Monat$monthPlural, $days Tag$dayPlural';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months Monat$plural';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days Tag$plural';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours Stunde$plural';
  }

  @override
  String get ageJustNow => 'Gerade eben';

  @override
  String get ageLessThanHour => 'Weniger als eine Stunde';

  @override
  String get viewProfile => 'Profil anzeigen';

  @override
  String get googleDriveSync => 'Google Drive Synchronisierung';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Synchronisieren Sie Ihre Daten mit Google Drive, um sie zwischen Geräten zu sichern und wiederherzustellen.';

  @override
  String get manageGoogleDriveSync => 'Google Drive Synchronisierung verwalten';

  @override
  String get signInToGoogleDrive => 'Bei Google Drive anmelden';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get uploadBackup => 'Backup hochladen';

  @override
  String get downloadBackup => 'Backup herunterladen';

  @override
  String get newerBackupAvailable => 'Neues Backup in der Cloud verfügbar';

  @override
  String get restoreProjectFromDrive => 'Aus Drive wiederherstellen';

  @override
  String get restoringProjectFromDrive => 'Aus Drive wiederherstellen...';

  @override
  String get projectRestoredFromDrive => 'Projekt aus Drive wiederhergestellt';

  @override
  String get projectNotFoundInBackup =>
      'Dieses Projekt wurde nicht im Drive-Backup gefunden';

  @override
  String get signInToGoogleDriveFirst =>
      'Bitte zuerst bei Google Drive anmelden (Drive-Sync-Einstellungen öffnen)';

  @override
  String get signOut => 'Abmelden';

  @override
  String get downloadPreviewSongs => 'Vorschau-Songs herunterladen';

  @override
  String get downloadPreviewSongsExplanation =>
      'Wenn deaktiviert, werden Vorschau-Songs übersprungen (spart Zeit und Speicherplatz). Sie können sie später bei Bedarf herunterladen.';

  @override
  String get replaceLocalData => 'Lokale Daten ersetzen';

  @override
  String get downloadBackupConfirmation =>
      'Dies ersetzt Ihre lokalen Daten durch das Backup von Google Drive.\n\nMöchten Sie wirklich fortfahren?';

  @override
  String get enterAuthorizationCode => 'Autorisierungscode eingeben';

  @override
  String get authorizationCode => 'Autorisierungscode';

  @override
  String get pasteCodeFromBrowser => 'Code aus dem Browser einfügen';

  @override
  String get sessionActive => 'Sitzung aktiv';

  @override
  String get signedIn => 'Angemeldet';

  @override
  String get creatingInitialBackup => 'Erstelle erstes Backup...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Erfolgreich angemeldet und in Google Drive gesichert';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Erfolgreich angemeldet und in Google Drive gesichert!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Erfolgreich bei Google Drive angemeldet';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Erfolgreich bei Google Drive angemeldet!';

  @override
  String get signInCancelledOrFailed =>
      'Anmeldung abgebrochen oder fehlgeschlagen. Details in der Konsole prüfen.';

  @override
  String get failedToLaunchBrowser => 'Browser konnte nicht gestartet werden';

  @override
  String get signInCancelled => 'Anmeldung abgebrochen';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Autorisierungscode konnte nicht ausgetauscht werden';

  @override
  String errorSigningIn(String error) {
    return 'Fehler bei der Anmeldung: $error';
  }

  @override
  String get unknownError => 'Unbekannter Fehler';

  @override
  String get googleSignInError => 'Google-Anmeldefehler';

  @override
  String get developerConsoleNotSetUp =>
      'Entwicklerkonsole ist nicht korrekt eingerichtet. Bitte überprüfen Sie Ihre OAuth-Konfiguration in der Google Cloud Console.';

  @override
  String get platformError => 'Plattformfehler';

  @override
  String get signedOutFromGoogleDrive => 'Von Google Drive abgemeldet';

  @override
  String errorSigningOut(String error) {
    return 'Fehler beim Abmelden: $error';
  }

  @override
  String get syncing => 'Synchronisiere...';

  @override
  String get errorNoProfileSelected => 'Fehler: Kein Profil ausgewählt';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Synchronisierung abgeschlossen! Projekte: +$projectsAdded ~$projectsUpdated, Veröffentlichungen: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Fehler bei der Synchronisierung: $error';
  }

  @override
  String get uploadingBackup => 'Backup wird hochgeladen...';

  @override
  String get backupUploadedSuccessfully => 'Backup erfolgreich hochgeladen!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Backup erfolgreich zu Google Drive hochgeladen!';

  @override
  String errorUploadingBackup(String error) {
    return 'Fehler beim Hochladen des Backups: $error';
  }

  @override
  String get downloadingBackup => 'Backup wird heruntergeladen...';

  @override
  String get checkingForBackup => 'Backup wird überprüft...';

  @override
  String get backupUpToDate => 'Backup ist aktuell';

  @override
  String errorCheckingBackup(String error) {
    return 'Fehler beim Überprüfen des Backups: $error';
  }

  @override
  String get download => 'Herunterladen';

  @override
  String get remoteBackupIsNewer =>
      'Remote-Backup ist neuer als lokale Daten. Hochladen überschreibt es.';

  @override
  String get confirmUpload => 'Upload bestätigen';

  @override
  String get noBackupFileFound =>
      'Keine Backup-Datei in Google Drive gefunden. Erstellen Sie zuerst ein Backup durch Synchronisierung Ihrer Daten.';

  @override
  String get noBackupFileFoundStatus =>
      'Keine Backup-Datei gefunden. Erstellen Sie zuerst ein Backup.';

  @override
  String get downloadCancelled => 'Download abgebrochen';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Backup heruntergeladen! Projekte: +$projectsAdded ~$projectsUpdated, Veröffentlichungen: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String backupDownloadedDetailed(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
    int previewSongsDownloaded,
    int previewSongsUpdated,
  ) {
    return 'Backup heruntergeladen!\n\nProjekte:\n  • $projectsAdded hinzugefügt\n  • $projectsUpdated aktualisiert\n\nVeröffentlichungen:\n  • $releasesAdded hinzugefügt\n  • $releasesUpdated aktualisiert\n\nPreview Songs:\n  • $previewSongsDownloaded heruntergeladen\n  • $previewSongsUpdated aktualisiert';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Fehler beim Herunterladen des Backups: $error';
  }

  @override
  String signedInAs(String email) {
    return 'Angemeldet als: $email';
  }

  @override
  String lastSync(String date) {
    return 'Letzte Synchronisierung: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Remote-Backup: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Letzter Upload: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Letzter Download: $date';
  }

  @override
  String get checkForBackup => 'Nach Backup suchen';

  @override
  String get notificationSettings => 'Benachrichtigungseinstellungen';

  @override
  String get notificationsOnlyOnAndroid =>
      'Deadline-Benachrichtigungen sind nur auf Android-Geräten verfügbar.';

  @override
  String get notificationPermissionRequired =>
      'Benachrichtigungsberechtigung erforderlich';

  @override
  String get notificationPermissionDescription =>
      'Bitte aktivieren Sie Benachrichtigungen, um Deadline-Erinnerungen zu erhalten.';

  @override
  String get notificationPermissionDenied =>
      'Benachrichtigungsberechtigung verweigert. Bitte aktivieren Sie sie in den Einstellungen.';

  @override
  String get notificationSettingsSaved =>
      'Benachrichtigungseinstellungen erfolgreich gespeichert';

  @override
  String get errorSavingSettings => 'Fehler beim Speichern der Einstellungen';

  @override
  String get enableDeadlineNotifications =>
      'Deadline-Benachrichtigungen aktivieren';

  @override
  String get receiveRemindersForDeadlines =>
      'Erinnerungen für Projekt-Deadlines erhalten';

  @override
  String get notificationTime => 'Benachrichtigungszeit';

  @override
  String get timeToReceiveNotifications =>
      'Tageszeit zum Empfangen von Benachrichtigungen';

  @override
  String get reminderDays => 'Erinnerungstage';

  @override
  String get selectDaysBeforeDeadline =>
      'Wählen Sie aus, wie viele Tage vor der Deadline Sie benachrichtigt werden möchten';

  @override
  String get notifyOnDeadlineDay => 'Am Deadline-Tag benachrichtigen';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'Auch am Deadline-Tag selbst eine Benachrichtigung erhalten';

  @override
  String get howItWorks => 'Wie es funktioniert';

  @override
  String get deadlineNotificationsHelp =>
      'Sie erhalten Benachrichtigungen zur angegebenen Zeit an den ausgewählten Tagen vor jeder Projekt-Deadline. Tippen Sie auf eine Benachrichtigung, um die Projektdetails zu öffnen.';

  @override
  String get oneDay => '1 Tag';

  @override
  String xDays(int count) {
    return '$count Tage';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get theme => 'Design';

  @override
  String get support => 'Unterstützen';

  @override
  String get shareDiagnosticLog => 'Diagnoseprotokoll teilen';

  @override
  String get shareDiagnosticLogEmpty => 'Noch kein Diagnoseprotokoll vorhanden';

  @override
  String get supportTheProject => 'Unterstütze das Projekt';

  @override
  String couldNotOpenBrowser(String url) {
    return 'Browser konnte nicht geöffnet werden. Bitte besuchen Sie: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Fehler beim Öffnen des Browsers: $error';
  }

  @override
  String get generateTestingDatabase => 'Testdatenbank generieren';

  @override
  String get generateTestingDatabaseMessage =>
      'Dies wird die Datenbank mit Beispielprojekten und Veröffentlichungen für Tests füllen. Fortfahren?';

  @override
  String get testingDatabaseGenerated => 'Testdatenbank erfolgreich generiert!';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Fehler beim Generieren der Testdatenbank: $error';
  }

  @override
  String get playlists => 'Playlists';

  @override
  String get playlistsDesktopOnly =>
      'Playlists sind nur auf Android verfügbar.';

  @override
  String get noPlaylistsYet => 'Noch keine Playlists';

  @override
  String get createFirstPlaylist =>
      'Tippe auf + um deine erste Playlist zu erstellen';

  @override
  String playlistSongCount(int count) {
    return '$count Lieder';
  }

  @override
  String get createPlaylist => 'Playlist erstellen';

  @override
  String get playlistName => 'Playlist-Name';

  @override
  String get playlistNameHint => 'Meine Playlist';

  @override
  String get playlistNameRequired => 'Playlist-Name ist erforderlich';

  @override
  String get editPlaylist => 'Playlist bearbeiten';

  @override
  String get stopPlaybackBeforeEditing =>
      'Bitte stoppen Sie die Wiedergabe, bevor Sie die Playlist bearbeiten';

  @override
  String get selectPreviewSongs => 'Vorschaulieder auswählen';

  @override
  String get deletePlaylist => 'Playlist löschen';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Möchtest du wirklich \"$name\" löschen?';
  }

  @override
  String get playlistDeleted => 'Playlist gelöscht';

  @override
  String get errorDeletingPlaylist => 'Fehler beim Löschen der Playlist';

  @override
  String get playlistUpdated => 'Wiedergabeliste aktualisiert';

  @override
  String get changeSong => 'Song wechseln';

  @override
  String get changeSongConfirm =>
      'Ein Song wird gerade abgespielt. Möchten Sie zu diesem Song wechseln?';

  @override
  String get changeSongButton => 'Wechseln';

  @override
  String playlistProgress(int current, int total) {
    return '$current von $total';
  }

  @override
  String get noPreviewSongsInPlaylist =>
      'Keine Vorschaulieder in dieser Playlist verfügbar';

  @override
  String get tapEditToAddSongs =>
      'Tippen Sie auf Bearbeiten, um Songs zu dieser Playlist hinzuzufügen';

  @override
  String get noProjectsAvailableForPlaylist =>
      'Keine Projekte mit Vorschau-Songs zum Hinzufügen verfügbar';

  @override
  String get noProjectsInDatabase =>
      'Keine Projekte in der Datenbank gefunden. Bitte synchronisieren Sie zuerst Ihre Projekte.';

  @override
  String get firstTimeSyncTitle =>
      'Es scheint, dass Sie zum ersten Mal hier sind!';

  @override
  String get firstTimeSyncMessage =>
      'Lassen Sie uns Ihre Daten von Google Drive synchronisieren, um zu beginnen';

  @override
  String get syncWithGoogleDrive => 'Mit Google Drive synchronisieren';

  @override
  String get errorLoadingPlaylists => 'Fehler beim Laden der Playlists';

  @override
  String get playlistItems => 'Playlist-Elemente';

  @override
  String get addSongs => 'Lieder hinzufügen';

  @override
  String get addAudioFiles => 'Audiodateien hinzufügen';

  @override
  String get selectAudioFiles => 'Audiodateien auswählen';

  @override
  String get selectFromProjects => 'Aus Projekten auswählen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get fromProject => 'Vom Projekt';

  @override
  String get projectDeadline => 'Projektfrist';

  @override
  String get noDeadlineSet => 'Keine Frist gesetzt';

  @override
  String get camelotCode => 'Camelot-Code';

  @override
  String get deadline => 'Frist';

  @override
  String get dueToday => 'Heute fällig';

  @override
  String daysLate(int days) {
    return '${days}T verspätet';
  }

  @override
  String daysLeft(int days) {
    return '${days}T übrig';
  }

  @override
  String get hideFinished => 'Fertige ausblenden';

  @override
  String get showOnlyDeadlines => 'Frist anzeigen';

  @override
  String get filterByDeadline => 'Nach Frist filtern';

  @override
  String get allDeadlines => 'Alle Fristen';

  @override
  String get hasDeadline => 'Mit Frist';

  @override
  String get overdue => 'Überfällig';

  @override
  String get dueSoon => 'Bald fällig (7T)';

  @override
  String get today => 'Heute';

  @override
  String get noPreviewSong => 'Keine Vorschau';

  @override
  String get playPreview => 'Vorschau abspielen';

  @override
  String get uploadCancelled => 'Upload abgebrochen';

  @override
  String get backupUploadCancelledByUser =>
      'Backup-Upload vom Benutzer abgebrochen';

  @override
  String get collectingData => 'Daten werden gesammelt...';

  @override
  String get uploadingPreviewSongs => 'Vorschaulieder werden hochgeladen...';

  @override
  String get uploadingProfilePhotos => 'Profilfotos werden hochgeladen...';

  @override
  String get uploadingReleaseArtwork => 'Release-Artwork wird hochgeladen...';

  @override
  String get uploadingDatabase => 'Datenbank wird hochgeladen...';

  @override
  String get completed => 'Abgeschlossen!';

  @override
  String get cancelling => 'Wird abgebrochen...';

  @override
  String get uploadingBackupTitle => 'Backup wird hochgeladen';

  @override
  String get cancellingUpload => 'Upload wird abgebrochen...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Bitte warten Sie, während der Upload gestoppt wird...';

  @override
  String get downloadingDatabase => 'Datenbank wird heruntergeladen...';

  @override
  String get downloadingPreviewSongs =>
      'Vorschaulieder werden heruntergeladen...';

  @override
  String get downloadingProfilePhotos =>
      'Profilfotos werden heruntergeladen...';

  @override
  String get downloadingReleaseArtwork =>
      'Release-Artwork wird heruntergeladen...';

  @override
  String get mergingData => 'Daten werden zusammengeführt...';

  @override
  String get downloadingBackupTitle => 'Backup wird heruntergeladen';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'Quelldatei nicht auf diesem Gerät gefunden';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'Quelldatei nicht auf diesem Gerät gefunden — nur Metadaten-Modus. Sie können Metadaten weiterhin bearbeiten und exportieren.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Vorschaulied nicht verfügbar. Bitte zuerst Backup herunterladen.';

  @override
  String get sharePreviewSong => 'Vorschaulied teilen';

  @override
  String get shareAsZip => 'Als ZIP teilen';

  @override
  String get share => 'Teilen';

  @override
  String get convertingAudioForSharing => 'Audio wird zum Teilen vorbereitet…';

  @override
  String get shareSheetUnavailable =>
      'Das System-Freigabemenü ist hier nicht verfügbar — nutze stattdessen den \"Zum Teilen ziehen\"-Chip in der Song-Vorschau, um die Datei auf eine andere App zu ziehen.';

  @override
  String get dragToShare => 'Zum Teilen ziehen';

  @override
  String get dragToShareTooltip =>
      'Ziehe dies auf das Fenster einer anderen App (z. B. WhatsApp), um die Datei direkt zu teilen — nützlich, wenn der Teilen-Button kein Freigabemenü öffnet.';

  @override
  String get mp3ConversionFailed =>
      'Audio-Konvertierung ist auf diesem System nicht verfügbar — die Originaldatei wird geteilt, die manche Apps wie WhatsApp ablehnen könnten.';

  @override
  String get shareZip => 'ZIP teilen';

  @override
  String get saveCopy => 'Kopie speichern';

  @override
  String savedCopyTo(String path) {
    return 'Gespeichert in $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Vorschaulied konnte nicht geteilt werden: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Vorschaulied konnte nicht als ZIP geteilt werden: $error';
  }

  @override
  String get biographySaved => 'Biografie gespeichert';

  @override
  String failedToSaveBiography(String error) {
    return 'Biografie konnte nicht gespeichert werden: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'Datei gespeichert unter $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Datei konnte nicht heruntergeladen werden: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'Alle Dateien gespeichert unter $filename';
  }

  @override
  String get artworkAdded => 'Artwork hinzugefügt';

  @override
  String failedToAddArtwork(String error) {
    return 'Artwork konnte nicht hinzugefügt werden: $error';
  }

  @override
  String get artworkRemoved => 'Artwork entfernt';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Artwork konnte nicht entfernt werden: $error';
  }

  @override
  String get pressKitFileAdded => 'Pressemappe-Datei hinzugefügt';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Pressemappe-Datei konnte nicht hinzugefügt werden: $error';
  }

  @override
  String get pressKitFileRemoved => 'Pressemappe-Datei entfernt';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Pressemappe-Datei konnte nicht entfernt werden: $error';
  }

  @override
  String get selectFilesToDownload => 'Dateien zum Herunterladen auswählen';

  @override
  String get biography => 'Biografie';

  @override
  String get biographyWillBeSaved => 'Wird als biography.txt gespeichert';

  @override
  String get artworkFiles => 'Artwork-Dateien';

  @override
  String get pressKitFiles => 'Pressemappe-Dateien';

  @override
  String get additionalAssets => 'Zusätzliche Assets';

  @override
  String downloadNFiles(int count, String plural) {
    return '$count Datei$plural herunterladen';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count Datei$plural gespeichert unter $filename';
  }

  @override
  String get addAsset => 'Asset hinzufügen';

  @override
  String get assetNameLabel => 'Asset-Name';

  @override
  String get assetNameHint => 'z.B. Logo, Banner, Foto';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName erfolgreich hinzugefügt';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Asset konnte nicht hinzugefügt werden: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName entfernt';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Asset konnte nicht entfernt werden: $error';
  }

  @override
  String get profileNotFound => 'Profil nicht gefunden';

  @override
  String get selectFiles => 'Dateien auswählen';

  @override
  String get downloadAll => 'Alle herunterladen';

  @override
  String get saveBiographyTooltip => 'Biografie speichern';

  @override
  String get enterBiographyHint => 'Profilbiografie eingeben...';

  @override
  String get addArtwork => 'Artwork hinzufügen';

  @override
  String get addFile => 'Datei hinzufügen';

  @override
  String get openFile => 'Datei öffnen';

  @override
  String get menuView => 'Ansicht';

  @override
  String get menuAbout => 'Über DAW Project Manager';

  @override
  String get menuDocumentation => 'Dokumentation';

  @override
  String get menuLanguage => 'Sprache';

  @override
  String get menuWarnBeforeQuit => 'Vor dem Beenden warnen (⌘+Q)';

  @override
  String get menuQuit => 'DAW Project Manager beenden';

  @override
  String get quitConfirmTitle => 'DAW Project Manager beenden?';

  @override
  String get quitConfirmMessage => 'Möchtest du wirklich beenden?';

  @override
  String get quit => 'Beenden';

  @override
  String get trayNoticeTitle => 'Läuft weiter im Hintergrund';

  @override
  String get trayNoticeBody =>
      'DAW Project Manager wurde in die Taskleiste minimiert. Über das Taskleistensymbol kannst du die App wieder öffnen oder beenden.';

  @override
  String get trayShowWindow => 'DAW Project Manager anzeigen';

  @override
  String trayLastBackup(String when) {
    return 'Letztes Backup: $when';
  }

  @override
  String get trayNeverBackedUp => 'Noch kein Backup erstellt';

  @override
  String get trayBackupNow => 'Jetzt sichern';

  @override
  String get trayPauseSession => 'Sitzung pausieren';

  @override
  String get trayResumeSession => 'Sitzung fortsetzen';

  @override
  String get closeToTray => 'In die Ablage schließen';

  @override
  String get closeToTrayDescription =>
      'Beim Schließen des Fensters im Hintergrund weiterlaufen (Symbol in der Ablage), damit automatisches Backup und Benachrichtigungen weiter funktionieren';

  @override
  String get menuWindow => 'Fenster';

  @override
  String get donate => 'Spenden';

  @override
  String get website => 'Website';

  @override
  String get switchToClassicDark => 'Zu Classic Dark wechseln';

  @override
  String get switchToNeonDark => 'Zu Neon Dark wechseln';

  @override
  String get switchToClassicTheme => 'Zu Classic-Theme wechseln';

  @override
  String get switchToNeonTheme => 'Zu Neon-Theme wechseln';

  @override
  String get switchToStudioLight => 'Switch to Studio Light';

  @override
  String get menuTheme => 'Design';

  @override
  String get appDescription =>
      'Ein Projektmanager für Musikproduzenten und Sounddesigner.';

  @override
  String get neonDarkThemeName => 'Neon Dunkel';

  @override
  String get classicDarkThemeName => 'Klassisch Dunkel';

  @override
  String get studioLightThemeName => 'Studio Light';

  @override
  String get statisticsTab => 'Statistiken';

  @override
  String get statsTotalProjects => 'Projekte gesamt';

  @override
  String get statsInProgress => 'In Bearbeitung';

  @override
  String get statsFinished => 'Abgeschlossen';

  @override
  String get statsAvgCompletion => 'Ø Abschlusszeit';

  @override
  String get statsPhaseDistribution => 'Projekte je Phase';

  @override
  String get statsAvgTimePerPhase => 'Ø Tage je Phase';

  @override
  String get statsProductivity => 'Produktivität';

  @override
  String get statsCreatedSeries => 'Erstellt';

  @override
  String get statsProjectHealth => 'Projektalter & Status';

  @override
  String get statsCatalogInsights => 'Katalog-Analyse';

  @override
  String get statsBpmDistribution => 'BPM-Verteilung';

  @override
  String get statsTopKeys => 'Häufige Tonarten';

  @override
  String get statsDawTypes => 'DAW-Typen';

  @override
  String get statsProjectActivity => 'Projektaktivität';

  @override
  String get statsSingleProjectActivity => 'Projektaktivität';

  @override
  String get statsNoData => 'Noch keine Daten';

  @override
  String get statsNoPhaseData =>
      'Phasendaten erscheinen, wenn Projekte die Phase wechseln.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Letzte Aktivität: vor $days Tagen';
  }

  @override
  String get statsLastActivityToday => 'Heute aktiv';

  @override
  String get statsNoEvents => 'Noch keine Ereignisse';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Phase: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Aktualisiert: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Erledigt: $text';
  }

  @override
  String get statsEventFileModified => 'Datei auf Datenträger geändert';

  @override
  String get statsClearHistory => 'Verlauf löschen';

  @override
  String get statsClearHistoryConfirm =>
      'Alle aufgezeichneten Ereignisse für dieses Projekt löschen?';

  @override
  String get statsSearchProjects => 'Projekte suchen…';

  @override
  String statsEventCount(int count) {
    return '$count Ereignisse';
  }

  @override
  String get statsViewHistory => 'Projektstatistiken';

  @override
  String get statsPhaseHistory => 'Phasenverlauf';

  @override
  String get statsEventBreakdown => 'Ereignisübersicht';

  @override
  String statsDaysSoFar(int days) {
    return 'Bisher ${days}T';
  }

  @override
  String get statsNoProjectsFound => 'Keine Projekte gefunden';

  @override
  String statsNotTouchedDays(int days) {
    return 'Seit $days Tagen unverändert';
  }

  @override
  String get sortByLastModified => 'Zuletzt geändert';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByPhase => 'Phase';

  @override
  String get sortByCreatedAt => 'Hinzugefügt am';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get monoLabel => 'Mono';

  @override
  String get monoToggleTooltip => 'Mono-Wiedergabe umschalten';

  @override
  String get monoRequiresWav => 'Mono-Mischung erfordert eine WAV-Datei';

  @override
  String get monoUnsupportedFormat =>
      'Mono-Mischung konnte nicht erstellt werden — nicht unterstütztes Format';

  @override
  String monoSwitchFailed(String error) {
    return 'Mono-Umschaltung fehlgeschlagen: $error';
  }

  @override
  String get analyzeLabel => 'Analysieren';

  @override
  String get reAnalyzeLabel => 'Erneut analysieren';

  @override
  String get analysisRequiresWav => 'Analyse erfordert eine WAV-Datei';

  @override
  String get noResultsForFilter => 'Keine Ergebnisse für den aktuellen Filter';

  @override
  String get noResultsForFilterHint =>
      'Versuche, die Suche oder Filter anzupassen.';

  @override
  String get noProjectsFound => 'Keine Projekte gefunden';

  @override
  String get noProjectsFoundHint =>
      'Füge einen Stammordner in den Einstellungen hinzu, um zu beginnen.';

  @override
  String get queueTab => 'Aufgaben';

  @override
  String get queueSearchHint => 'Aufgaben suchen...';

  @override
  String get queueNoPendingTasks => 'Alles erledigt!';

  @override
  String get queueNoPendingTasksHint =>
      'Keine ausstehenden Aufgaben in deinen Projekten.';

  @override
  String get queueNoMatchingTasks => 'Keine passenden Aufgaben';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks ausstehende Aufgaben in $projects Projekten';
  }

  @override
  String appTitleWithVersion(String version) {
    return 'DAW Project Manager v$version';
  }

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get renameProjectFileTitle => 'Projektdatei umbenennen';

  @override
  String get renameFileButtonLabel => 'Datei umbenennen';

  @override
  String get newFileNameLabel => 'Neuer Dateiname (ohne Erweiterung)';

  @override
  String renameAlreadyExists(String name) {
    return 'Eine Datei namens \"$name\" existiert bereits.';
  }

  @override
  String renameSuccess(String name) {
    return 'Umbenannt in \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Umbenennen fehlgeschlagen: $error';
  }

  @override
  String get nameCannotBeEmpty => 'Name darf nicht leer sein';

  @override
  String get nameInvalidCharacters => 'Name darf / \\ : nicht enthalten';

  @override
  String get alsoRenameContainingFolder =>
      'Auch übergeordneten Ordner umbenennen';

  @override
  String get renameButton => 'Umbenennen';

  @override
  String get previewMixdownFolderTitle => 'Vorschau-Mixdown-Ordner';

  @override
  String get previewMixdownFolderSubtitle =>
      'Unterordnernamen in jedem Projektordner, die zuerst bei der automatischen Erkennung von Vorschau-Songs geprüft werden, in dieser Reihenfolge. Leer lassen für DAW-Standardwerte.';

  @override
  String get previewMixdownFolderHint => 'z.B. Mixdowns';

  @override
  String get mixdownFoldersInfoTooltip => 'Wie das funktioniert';

  @override
  String get mixdownFoldersInfoDialogTitle =>
      'Wie die Vorschau-Erkennung funktioniert';

  @override
  String get mixdownFoldersInfoDialogBody =>
      'Wenn für ein Projekt kein manuell ausgewählter Vorschau-Song vorhanden ist, sucht die App nach der zuletzt geänderten Audiodatei, um sie als Vorschau zu verwenden. Zuerst werden Ihre benutzerdefinierten Ordner unten in der angegebenen Reihenfolge geprüft, danach eine Liste von Standardordnernamen basierend auf der DAW des Projekts.';

  @override
  String get mixdownFoldersDawDefaultsHeading => 'Standardordner pro DAW';

  @override
  String get mixdownFoldersOtherDawLabel => 'Andere / unbekannte DAW';

  @override
  String get addMixdownFolder => 'Hinzufügen';

  @override
  String get noCustomMixdownFolders =>
      'Keine benutzerdefinierten Ordner hinzugefügt — DAW-Standardwerte werden verwendet.';

  @override
  String dawInfoLabel(String daw) {
    return 'DAW: $daw';
  }

  @override
  String bpmInfoLabel(String bpm) {
    return 'BPM: $bpm';
  }

  @override
  String keyInfoLabel(String key) {
    return 'Tonart: $key';
  }

  @override
  String get audioFileNotFound => 'Audiodatei nicht gefunden';

  @override
  String errorPlayingAudio(String error) {
    return 'Fehler beim Abspielen: $error';
  }

  @override
  String get notificationTestTitle =>
      'Benachrichtigungen testen (Zeitzone und Planung):';

  @override
  String get notificationSendNow => 'Jetzt senden';

  @override
  String get notificationSchedule30s => 'In 30s planen';

  @override
  String get notificationShowDebugInfo => 'Debug-Info anzeigen';

  @override
  String get notificationRescheduleAll => 'Alle neu planen';

  @override
  String get notificationTestSent => '✅ Test-Benachrichtigung gesendet!';

  @override
  String get notificationTestScheduled =>
      '✅ Test-Benachrichtigung in 30 Sekunden geplant! Konsole prüfen.';

  @override
  String notificationTestError(String error) {
    return '❌ Fehler: $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Debug-Informationen';

  @override
  String get autoDetected => 'Automatisch erkannt';

  @override
  String get matchedInDescription => 'In Beschreibung gefunden';

  @override
  String get relocateFolderDialogTitle => 'Ordner verschieben';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Projektpfade aktualisiert',
      one: '1 Projektpfad aktualisiert',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Tabs anpassen';

  @override
  String get customizeTabsDescription =>
      'Waehle, welche Tabs in der Navigationsleiste angezeigt werden sollen. Der Tab Projekte ist immer sichtbar.';

  @override
  String get keyboardShortcuts => 'Tastenkürzel';

  @override
  String get shortcutGroupGlobal => 'Global';

  @override
  String get shortcutGroupProjectsTable =>
      'Projekttabelle (Tabelle muss fokussiert sein)';

  @override
  String get shortcutGroupReleasesTable =>
      'Releases-Tabelle (Tabelle muss fokussiert sein)';

  @override
  String get shortcutGroupNavigation => 'Navigation';

  @override
  String get shortcutFocusSearch => 'Suchleiste fokussieren';

  @override
  String get shortcutRescan => 'Projektordner neu scannen';

  @override
  String get shortcutFocusTable => 'Projekttabelle fokussieren';

  @override
  String get shortcutPlayPause => 'Vorschau abspielen / pausieren';

  @override
  String get shortcutOpenInDaw => 'Projekt in DAW öffnen';

  @override
  String get shortcutViewDetails => 'Projektdetails anzeigen';

  @override
  String get shortcutOpenFolder => 'Projektordner öffnen';

  @override
  String get shortcutNavigateRows => 'Zeilen navigieren';

  @override
  String get shortcutEditCell => 'Projektdetails öffnen';

  @override
  String get shortcutViewRelease => 'Release-Details anzeigen';

  @override
  String get shortcutGoBack => 'Zurück';

  @override
  String get shortcutGroupProjectsTableStandardMode => 'Standardmodus';

  @override
  String get shortcutGroupProjectsTableSessionMode => 'Sitzungsmodus';

  @override
  String get shortcutToggleSession => 'Sitzung starten / beenden';

  @override
  String get shortcutGroupPreviewPlayer => 'Vorschau-Player';

  @override
  String get shortcutPlayerPlayPause => 'Abspielen / Pause';

  @override
  String get shortcutPlayerSeek5 => '±5 Sekunden springen';

  @override
  String get shortcutPlayerSeek30 => '±30 Sekunden springen';

  @override
  String get startupDialogTitle => 'Willkommen beim DAW Project Manager';

  @override
  String get startupDialogSubtitle =>
      'Füge einen Projektordner hinzu oder stelle ein Google Drive-Backup wieder her.';

  @override
  String get startupAddFolderTitle => 'Projektordner hinzufügen';

  @override
  String get startupAddFolderSubtitle =>
      'Wähle einen Ordner mit deinen DAW-Projekten aus.';

  @override
  String get startupGoogleDriveTitle => 'Google Drive-Backup synchronisieren';

  @override
  String get startupGoogleDriveSubtitle =>
      'Projekte aus einem Google Drive-Backup wiederherstellen.';

  @override
  String get startupDontShowAgain => 'Beim Start nicht mehr anzeigen';

  @override
  String get deleteAllData => 'Alle Daten löschen';

  @override
  String get deleteAllDataSubtitle =>
      'Alle Profile, Projekte, Releases, Playlists und Einstellungen von diesem Gerät entfernen.';

  @override
  String get deleteAllDataConfirm1Title => 'Alle Daten löschen?';

  @override
  String get deleteAllDataConfirm1Message =>
      'Dadurch werden alle Profile, Projekte, Releases, Playlists und Einstellungen dauerhaft von diesem Gerät gelöscht. Dein Google Drive-Backup (falls vorhanden) bleibt erhalten.';

  @override
  String get deleteAllDataConfirm2Title => 'Bist du absolut sicher?';

  @override
  String get deleteAllDataConfirm2Message =>
      'Diese Aktion kann nicht rückgängig gemacht werden. Die App kehrt in den Ausgangszustand zurück.';

  @override
  String get deleteEverything => 'Alles löschen';

  @override
  String get allDataDeleted => 'Alle Daten wurden gelöscht.';

  @override
  String get newerExportFound => 'Neuerer Export gefunden';

  @override
  String newerExportFoundMessage(String filename) {
    return 'Im selben Ordner wurde eine neuere Datei gefunden:\n$filename\n\nVorschausong ersetzen?';
  }

  @override
  String get replaceAndPlay => 'Ersetzen & Abspielen';

  @override
  String get keepCurrent => 'Aktuelle behalten';

  @override
  String get autoBackup => 'Auto Backup';

  @override
  String get autoBackupDescription =>
      'Automatically upload a backup to Google Drive at the selected interval.';

  @override
  String get autoBackupInterval => 'Backup interval';

  @override
  String get autoBackupOff => 'Off';

  @override
  String get autoBackupEvery30Min => 'Every 30 minutes';

  @override
  String get autoBackupHourly => 'Every hour';

  @override
  String get autoBackupEvery6Hours => 'Every 6 hours';

  @override
  String get autoBackupDaily => 'Daily';

  @override
  String autoBackupNextBackup(String time) {
    return 'Nächstes Backup: $time';
  }

  @override
  String get playerTitle => 'Musikplayer';

  @override
  String get playerToggleQueue => 'Warteschlange umschalten';

  @override
  String get playerSearchHint => 'Tracks suchen…';

  @override
  String playerTrackCount(int count) {
    return '$count Tracks';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs =>
      'Keine Vorschaulieder gefunden.\nÖffne ein Projekt und lege ein Vorschaustück fest.';

  @override
  String playerNoTracksMatch(String query) {
    return 'Keine Tracks passen zu\n\"$query\"';
  }

  @override
  String get playerDoubleClickToPlay =>
      'Doppelklick auf einen Track zum Abspielen';

  @override
  String get playerSingleClickToPreview =>
      'Einfachklick zur Vorschau in der Leiste unten';

  @override
  String get playerQueueTitle => 'Warteschlange';

  @override
  String get playerClearQueue => 'Warteschlange leeren';

  @override
  String get playerQueueEmptyHint =>
      'Doppelklick zum Starten,\noder Tracks hierher ziehen.';

  @override
  String get playerPrev => 'Vorheriger';

  @override
  String get playerNext => 'Nächster';

  @override
  String get playerGoToProject => 'Zum Projekt';

  @override
  String get playerAddToQueue => 'Zur Warteschlange hinzufügen';

  @override
  String get playerRemoveFromQueue => 'Aus Warteschlange entfernen';

  @override
  String get playerDismissDetail => 'Detail ausblenden';

  @override
  String get playerNotes => 'NOTIZEN';

  @override
  String get playerTasks => 'AUFGABEN';

  @override
  String get playerNoTasks => 'Noch keine Aufgaben.';

  @override
  String get playerAddTaskHint => 'Aufgabe hinzufügen…';

  @override
  String playerCompletedTasks(int count) {
    return '$count abgeschlossen';
  }

  @override
  String get playerPreviousTrack => 'Vorheriger Titel';

  @override
  String get playerNextTrack => 'Nächster Titel';

  @override
  String get playerOpenProject => 'Projekt öffnen';

  @override
  String get playerRepeatAll => 'Alle wiederholen';

  @override
  String get playerShuffle => 'Zufällig';

  @override
  String get volumeMute => 'Stummschalten';

  @override
  String get volumeUnmute => 'Stummschaltung aufheben';

  @override
  String totalWorkTime(String time) {
    return 'Gesamtarbeitszeit: $time';
  }

  @override
  String sessionTime(String time) {
    return 'Sitzung: $time';
  }

  @override
  String headerAgeOld(String age) {
    return '$age alt';
  }

  @override
  String headerEdited(String when) {
    return 'bearbeitet $when';
  }

  @override
  String headerWorked(String time) {
    return '$time gearbeitet';
  }

  @override
  String get sessionHistory => 'Sitzungsverlauf';

  @override
  String get noSessionsYet => 'Noch keine Sitzungen aufgezeichnet';

  @override
  String get removeSessionTitle => 'Sitzung entfernen?';

  @override
  String get editSessionTitle => 'Sitzungsdauer bearbeiten';

  @override
  String get editSessionHours => 'Stunden';

  @override
  String get editSessionInvalid => 'Dauer muss mindestens 1 Minute betragen';

  @override
  String get sessionTableDate => 'Datum';

  @override
  String get sessionTableTime => 'Uhrzeit';

  @override
  String get sessionTableDuration => 'Dauer';

  @override
  String get sessionTableTotal => 'Gesamt';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sitzungen',
      one: '1 Sitzung',
    );
    return '$_temp0';
  }

  @override
  String get sessionByPhase => 'Arbeit nach Phase';

  @override
  String get tabPosition => 'Tab-Position';

  @override
  String get tabPositionTop => 'Oben';

  @override
  String get tabPositionLeft => 'Links';

  @override
  String updateAvailableMessage(String version) {
    return 'Version $version verfügbar';
  }

  @override
  String get dismiss => 'Schließen';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get checkForUpdatesDescription =>
      'Benachrichtigt werden, wenn eine neue Version verfügbar ist.';

  @override
  String get checkNow => 'Jetzt prüfen';

  @override
  String updateAvailable(String version) {
    return 'Update verfügbar: v$version';
  }

  @override
  String get upToDate => 'App ist aktuell';

  @override
  String get updateAvailableTitle => 'Update verfügbar';

  @override
  String updateAvailableVersion(String version) {
    return 'Version $version ist bereit.';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'Sie verwenden v$version.';
  }

  @override
  String get viewUpdateDetails => 'Details anzeigen';

  @override
  String get getOnMicrosoftStore => 'Im Microsoft Store erhalten';

  @override
  String get downloadFromGitHub => 'Von GitHub herunterladen';

  @override
  String get updateWindowsInstructions =>
      'Öffne den Microsoft Store und aktualisiere DAW Project Manager, oder klicke unten.';

  @override
  String get updateMacInstructions =>
      'Lade die neueste Version von GitHub herunter und ersetze die aktuelle App.';

  @override
  String get resetOnboarding => 'Einrichtung zurücksetzen';

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei DAW Project Manager';

  @override
  String get onboardingWelcomeBody =>
      'Verwalte alle deine Musikprojekte an einem Ort.';

  @override
  String get onboardingLanguageTitle => 'Sprache wählen';

  @override
  String get onboardingThemeTitle => 'Design wählen';

  @override
  String get onboardingFoldersTitle => 'Projektordner hinzufügen';

  @override
  String get onboardingFoldersBody =>
      'Füge den Stammordner hinzu, in dem deine DAW-Projekte gespeichert sind.';

  @override
  String get onboardingDriveTitle => 'Google Drive-Synchronisierung';

  @override
  String get onboardingDriveBody =>
      'Sichere und synchronisiere Projektmetadaten mit Google Drive.';

  @override
  String get onboardingUpdatesTitle => 'Update-Prüfungen';

  @override
  String get onboardingUpdatesBody =>
      'Benachrichtigt werden, wenn eine neue Version verfügbar ist.';

  @override
  String get onboardingDoneTitle => 'Alles bereit!';

  @override
  String get onboardingDoneBody => 'Beginne, deine Projekte zu erkunden.';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingBack => 'Zurück';

  @override
  String get onboardingGetStarted => 'Loslegen';

  @override
  String get dawSession => 'DAW-Sitzung';

  @override
  String get clearDawSession => 'Sitzung beenden';

  @override
  String get stop => 'Stop';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get workTimerSection => 'Arbeitssitzungs-Erinnerungen';

  @override
  String get workTimerSectionDesc =>
      'Benachrichtigt werden, während Sie an einem abonnierten Projekt arbeiten';

  @override
  String get workTimerEnabled => 'Arbeitssitzungs-Erinnerungen aktivieren';

  @override
  String get workTimerIntervalLabel => 'Benachrichtigen alle';

  @override
  String get minutes => 'Minuten';

  @override
  String workTimerNotifBody(String time) {
    return 'Du arbeitest seit $time';
  }

  @override
  String get general => 'Allgemein';

  @override
  String get expand => 'Erweitern';

  @override
  String get collapse => 'Einklappen';

  @override
  String get lastModifiedColors => 'Farben des Änderungsdatums';

  @override
  String get lastModifiedColorsDescription =>
      'Färbt das Änderungsdatum basierend auf Alter und Status. Grün = Fertig. Ältere Daten verblassen von Gelb zu Rot — stärkeres Rot bedeutet, dass das Projekt länger nicht bearbeitet wurde.';

  @override
  String get sessionMode => 'Sitzungsmodus';

  @override
  String get sessionModeDescription =>
      'Projekt abonnieren vor dem Start, um Arbeitszeit zu verfolgen und über die Symbolleiste zu verwalten';

  @override
  String get startSession => 'Sitzung starten';

  @override
  String get endSession => 'Sitzung beenden';

  @override
  String get switchSession => 'Sitzung wechseln';

  @override
  String get switchSessionBody => 'Aktuelle Sitzung beenden und neue starten?';

  @override
  String switchSessionCurrent(String project) {
    return 'Aktuell: $project';
  }

  @override
  String switchSessionNew(String project) {
    return 'Neu: $project';
  }

  @override
  String get sessionDuration => 'Sitzungsdauer';

  @override
  String get scanModeLabel => 'Scanmodus:';

  @override
  String get scanModeSectionTitle => 'Scanmodus';

  @override
  String get scanModeSectionDescription =>
      'Steuert, wie Projekte in jedem Ordner in der Tabelle angezeigt werden — als einfache Liste oder nach Unterordner gruppiert.';

  @override
  String get scanModeFlat => 'Einfach';

  @override
  String get scanModeSmartFolder => 'Intelligenter Ordner';

  @override
  String get scanModeFlatDescription =>
      'Zeigt alle Projekte als einfache Liste. Simpel und schnell.';

  @override
  String get scanModeSmartFolderDescription =>
      'Gruppiert Projekte nach Ordner, wenn ein Ordner mehr als ein Projekt enthält.';

  @override
  String get skip => 'Überspringen';

  @override
  String get suggestionsLabel => 'Vorschläge';

  @override
  String get suggestionsRefresh => 'Aktualisieren';

  @override
  String get suggestionsEmptyState =>
      'Momentan keine Vorschläge. Tippe auf Aktualisieren, um ausgeblendete Elemente zurückzusetzen.';

  @override
  String get showSuggestions => 'Vorschläge anzeigen';

  @override
  String get showSuggestionsDescription =>
      'Zeigt intelligente Vorschläge in der Symbolleiste an, wenn keine Sitzung läuft';

  @override
  String get onboardingSuggestionsTitle => 'Smarte Vorschläge';

  @override
  String get onboardingSuggestionsBody =>
      'Erhalte personalisierte Projektempfehlungen in der Symbolleiste während du arbeitest';

  @override
  String get onboardingSessionModeTitle => 'Sitzungsmodus';

  @override
  String get onboardingSessionModeBody =>
      'Starte fokussierte Arbeitssitzungen und verfolge automatisch die für jedes Projekt aufgewendete Zeit';

  @override
  String get suggestionsFeatureDeadlines =>
      'Fristenhinweise für bevorstehende Projekte';

  @override
  String get suggestionsFeatureResume =>
      'Zuletzt bearbeitetes Projekt fortsetzen';

  @override
  String get suggestionsFeatureRecentlyModified =>
      'Zuletzt geänderte Tracks fortsetzen';

  @override
  String get suggestionsEnableToggle => 'Smarte Vorschläge aktivieren';

  @override
  String get canBeChangedInSettings =>
      'Kann später in den Einstellungen geändert werden';

  @override
  String get next => 'Weiter';

  @override
  String get createProject => 'Erstellen';

  @override
  String get createProjectTooltip => 'Neuen Projektordner erstellen';

  @override
  String get createProjectSelectFolder => 'Speicherort wählen';

  @override
  String get createProjectSelectFolderHint =>
      'Wählen Sie den Projektordner für das neue Projekt';

  @override
  String get createProjectNameTitle => 'Projekt benennen';

  @override
  String get createProjectNameHint =>
      'Wählen Sie ein Benennungsschema für den neuen Projektordner';

  @override
  String get createProjectSchemeArtistTrack => 'Künstler — Track';

  @override
  String get createProjectSchemeCollab => 'Kollaboration';

  @override
  String get createProjectSchemeDate => 'Datum — Track';

  @override
  String get createProjectSchemeCustom => 'Benutzerdefiniert';

  @override
  String get createProjectArtistName => 'Künstlername';

  @override
  String get createProjectTrackName => 'Track-Name';

  @override
  String get createProjectCustomName => 'Ordnername';

  @override
  String get createProjectAddArtist => 'Künstler hinzufügen';

  @override
  String get createProjectSelectDaw => 'In DAW öffnen';

  @override
  String get createProjectSelectDawHint =>
      'Wählen Sie die DAW für dieses Projekt';

  @override
  String get createProjectDetectDaws => 'Installierte DAWs erkennen';

  @override
  String get createProjectSkipDaw => 'Nur Ordner erstellen';

  @override
  String get createProjectNoDawsFound =>
      'Keine DAWs gefunden. Der Ordner wird trotzdem erstellt.';

  @override
  String get createProjectCreateOnly => 'Ordner erstellen';

  @override
  String get createProjectCreateAndOpen => 'Erstellen & Öffnen';

  @override
  String get createProjectFolderExists =>
      'Ein Ordner mit diesem Namen existiert bereits';

  @override
  String get createProjectInvalidChars =>
      'Ordnername enthält ungültige Zeichen';

  @override
  String get createProjectError => 'Ordner konnte nicht erstellt werden';

  @override
  String get createProjectIncludeDate => 'Datumspräfix hinzufügen';

  @override
  String get createProjectCreatedTitle => 'Ordner erstellt';

  @override
  String get createProjectCreatedMessage => 'Ihr Projektordner wurde erstellt:';

  @override
  String get createProjectCopyName => 'Ordnernamen kopieren';

  @override
  String get createProjectNameCopied => 'Ordnername kopiert';

  @override
  String get createProjectTrackSession => 'Sitzung ab jetzt verfolgen';

  @override
  String get pendingFolderSessionTitle => 'Arbeitssitzung erkannt';

  @override
  String pendingFolderSessionBody(String projectName, String duration) {
    return 'Sie haben $duration an \"$projectName\" gearbeitet.';
  }

  @override
  String get pendingFolderSessionContinue => 'Sitzung fortsetzen';

  @override
  String get pendingFolderSessionEndRecord => 'Beenden & aufzeichnen';

  @override
  String get activeSessionSwitchTitle => 'Sitzung bereits aktiv';

  @override
  String activeSessionSwitchBody(String current, String next) {
    return 'Eine Sitzung läuft für \"$current\". Zu \"$next\" wechseln und die aktuelle Sitzung speichern?';
  }

  @override
  String get activeSessionSwitch => 'Wechseln';

  @override
  String get pendingProjectWaiting => 'Warte auf Projektdatei…';

  @override
  String get pendingProjectDelete => 'Leeren Ordner löschen';

  @override
  String get pendingProjectDeleteTitle => 'Ordner löschen?';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return '\"$folderName\" und seinen Inhalt löschen?';
  }

  @override
  String get pendingProjectDismiss => 'Diesen Ordner nicht mehr verfolgen';

  @override
  String get pendingProjectDismissTitle => 'Tracking stoppen?';

  @override
  String get pendingProjectDismissKeep => 'Ordner behalten';

  @override
  String get pendingProjectDismissDelete => 'Löschen & Schließen';

  @override
  String get pendingProjectDeleteNotEmptyTitle => 'Ordner ist nicht leer';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return '\"$folderName\" enthält Dateien. Alles dauerhaft löschen?';
  }

  @override
  String get pendingProjectRefresh => 'Nach Projektdatei suchen';

  @override
  String get pendingProjectNotFound => 'Noch keine Projektdatei gefunden';

  @override
  String get phases => 'Phasen';

  @override
  String get phasesSubtitle =>
      'Projektphasen hinzufügen, entfernen und neu anordnen';

  @override
  String get resetToDefaults => 'Auf Standard zurücksetzen';

  @override
  String get addPhase => 'Phase hinzufügen';

  @override
  String get phaseNameHint => 'Phasenname';

  @override
  String get phaseDuplicateError =>
      'Eine Phase mit diesem Namen existiert bereits';

  @override
  String deletePhaseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Projekte verwenden diese Phase',
      one: '1 Projekt verwendet diese Phase',
    );
    return '$_temp0';
  }

  @override
  String get selectPhaseColor => 'Farbe auswählen';

  @override
  String get markAsFinished => 'Als abgeschlossene Phase markieren';

  @override
  String resetPhasesWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Projekte verwenden Phasen, die nicht mehr existieren.',
      one: '1 Projekt verwendet eine Phase, die nicht mehr existiert.',
    );
    return '$_temp0';
  }

  @override
  String get resetPhasesWarningNote =>
      'Diese Projekte behalten ihren aktuellen Status, erscheinen aber nicht in Phasenfiltern. Du kannst diese Phasen jederzeit wieder hinzufügen.';

  @override
  String get camelotGenerateButton => 'Mix generieren';

  @override
  String get camelotDialogTitle => 'Camelot-Mix';

  @override
  String get camelotDialogDescription =>
      'Ordnet deine Tracks nach harmonischer Kompatibilität anhand des Camelot-Rads. BPM-Nähe wird als Auswahlkriterium verwendet.';

  @override
  String camelotEligibleTracks(int count) {
    return '$count Tracks geeignet (Tonart gesetzt)';
  }

  @override
  String camelotSkippedTracks(int count) {
    return '$count werden übersprungen (keine Tonart)';
  }

  @override
  String get camelotNoEligibleTracks =>
      'Kein Track hat eine Tonart gesetzt. Öffne ein Projekt und setze die Tonart.';

  @override
  String get camelotGenerate => 'Generieren';

  @override
  String camelotQueueGenerated(int count) {
    return 'Warteschlange mit $count harmonisch sortierten Tracks gefüllt';
  }

  @override
  String get camelotWheelGuideTooltip => 'Camelot-Rad Anleitung';

  @override
  String get camelotWheelGuideTitle => 'Camelot-Rad Anleitung';

  @override
  String get camelotGuideRingsTitle => 'Die Ringe';

  @override
  String get camelotGuideRingsBody =>
      'Innenring (A)  →  Molltonarten\nAußenring (B)  →  Durtonarten';

  @override
  String get camelotGuideNumbersTitle => 'Zahlen 1–12';

  @override
  String get camelotGuideNumbersBody =>
      'Positionen im Uhrzeigersinn angeordnet. Jede Zahl steht für eine harmonische Nachbarschaft — Nachbarn teilen starke tonale Beziehungen.';

  @override
  String get camelotGuideColoursTitle => 'Farblegende';

  @override
  String get camelotGuideColoursBody =>
      '● Hell  →  Tonart deines Songs\n● Weich beleuchtet  →  kompatibel für Mixing\n● Gedimmt  →  für flüssiges Mixing vermeiden';

  @override
  String get camelotGuideTransitionsTitle => 'Kompatible Übergänge';

  @override
  String get camelotGuideTransitionsBody =>
      '8A → 8B  (gleiche Zahl, Ring wechseln)\n  Relative Dur/Moll — nahezu nahtlos.\n\n8A → 7A oder 9A  (±1, gleicher Ring)\n  Benachbarter Ton — sanfte, dezente Änderung.\n\n8A → 1A oder 3A  (±7, gleicher Ring)\n  Energie-Boost oder -Drop — dramatischerer Wechsel.';

  @override
  String get playerMixSuggestions => 'MIX-VORSCHLÄGE';

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get noPreviewSongsAvailable => 'No preview songs available';

  @override
  String get upNext => 'Als Nächstes';

  @override
  String get playbackModeNormal => 'Normal';

  @override
  String get playbackModeRepeat => 'Repeat';

  @override
  String get playbackModeShuffle => 'Shuffle';
}
