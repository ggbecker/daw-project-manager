// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Gestionnaire de Projets DAW';

  @override
  String get projectDetails => 'Détails du Projet';

  @override
  String get back => 'Retour';

  @override
  String get save => 'Enregistrer';

  @override
  String get enable => 'Activer';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get launch => 'Ouvrir';

  @override
  String get view => 'Voir';

  @override
  String get openFolder => 'Ouvrir le Dossier';

  @override
  String get openInDaw => 'Lancer dans le DAW';

  @override
  String get extract => 'Extraire';

  @override
  String get extracting => 'Extraction…';

  @override
  String get extractingMetadata => 'Extraction des métadonnées...';

  @override
  String get deepScan => 'Scan Approfondi';

  @override
  String get rescan => 'Rescanner';

  @override
  String get scanning => 'Scan en cours…';

  @override
  String get projectName => 'Nom du Projet';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Tonalité (ex: C#m, F majeur)';

  @override
  String get notes => 'Notes';

  @override
  String get projectPhase => 'Phase du Projet';

  @override
  String get failedToLoad => 'Échec du chargement';

  @override
  String get fileMissing => 'Fichier manquant.';

  @override
  String launchingProject(String projectName) {
    return 'Ouverture de $projectName…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return 'Échec de l\'ouverture de $projectName';
  }

  @override
  String get clearLibrary => 'Vider la Bibliothèque';

  @override
  String get clearLibraryMessage =>
      'Cela supprimera tous les projets enregistrés et dossiers sources. Continuer?';

  @override
  String get clear => 'Vider';

  @override
  String get roots => 'Dossiers de Projets';

  @override
  String get pathsSettingsDangerZoneTitle => 'Bibliothèque';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Effacez tous les projets et dossiers de projets du profil actuel.';

  @override
  String get projectFoldersSectionTitle => 'Dossiers de projets';

  @override
  String get projectFoldersSectionSubtitle =>
      'Dossiers qui seront scannés pour trouver des projets DAW.';

  @override
  String get projectFoldersEmptyTitle =>
      'Aucun dossier de projets pour le moment';

  @override
  String get projectFoldersEmptySubtitle =>
      'Ajoutez au moins un dossier pour commencer à scanner les projets.';

  @override
  String get notScannedYet => 'Pas encore scanné';

  @override
  String lastScan(String date) {
    return 'Dernier scan : $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Dossiers exclus';

  @override
  String get excludedFoldersSectionSubtitle =>
      'Ces dossiers seront ignorés pendant le scan, même s\'ils se trouvent dans un dossier de projets.';

  @override
  String get addExcludedFolder => 'Ajouter exclu';

  @override
  String get selectExcludedFolder => 'Sélectionnez un dossier à exclure';

  @override
  String get excludedFoldersEmptyTitle => 'Aucun dossier exclu';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Optionnel : ajoutez des dossiers que vous ne voulez jamais scanner.';

  @override
  String get removeExcludedFolderTitle => 'Supprimer le dossier exclu ?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'Ce dossier ne sera plus exclu :\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'Ce dossier ne sera plus exclu.';

  @override
  String get desktopOnlyPathsSettings =>
      'Cette page est disponible uniquement dans l’application de bureau.';

  @override
  String get removeProjectFolderTitle => 'Supprimer le dossier de projets ?';

  @override
  String removeProjectFolderMessage(String path) {
    return 'Êtes-vous sûr de vouloir supprimer \"$path\" ? Cela supprimera aussi tous les projets de ce dossier qui ne sont pas dans des sorties.';
  }

  @override
  String get projects => 'Projets';

  @override
  String get hidden => 'masqués';

  @override
  String get profileManager => 'Gestionnaire de Profils';

  @override
  String get createNewProfile => 'Créer un Nouveau Profil';

  @override
  String get profileName => 'Nom du Profil';

  @override
  String get create => 'Créer';

  @override
  String get profiles => 'Profils';

  @override
  String get active => 'Actif';

  @override
  String get switchProfile => 'Changer';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get addFolder => 'Ajouter un Dossier';

  @override
  String get searchProjects => 'Rechercher des projets...';

  @override
  String get searchReleases => 'Rechercher des sorties...';

  @override
  String get searchPlaylists => 'Rechercher des playlists...';

  @override
  String get noReleasesFound => 'Aucune sortie trouvée';

  @override
  String get noPlaylistsFound => 'Aucune playlist trouvée';

  @override
  String get tryDifferentSearch => 'Essayez un terme de recherche différent';

  @override
  String get deepScanTooltip =>
      'Le Scan Approfondi extrait les métadonnées complètes des fichiers de projet:\n• BPM (Battements Par Minute)\n• Tonalité Musicale\n• Version du DAW\nC\'est plus lent mais fournit des informations complètes.';

  @override
  String get deepScanConfirm =>
      'Cela scannera tous les projets et extraira les métadonnées complètes (BPM, Tonalité, Version du DAW). Cela peut prendre un certain temps. Continuer?';

  @override
  String get metadataExtractedSuccessfully =>
      'Métadonnées extraites avec succès';

  @override
  String failedToExtractMetadata(String error) {
    return 'Échec de l\'extraction des métadonnées: $error';
  }

  @override
  String get saved => 'Enregistré';

  @override
  String get failedToLaunchDaw => 'Échec de l\'ouverture du DAW';

  @override
  String get releaseDetails => 'Détails de la Sortie';

  @override
  String get releaseNotFound => 'Sortie Non Trouvée';

  @override
  String get error => 'Erreur';

  @override
  String get loading => 'Chargement...';

  @override
  String get deleteProfile => 'Supprimer le Profil';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$profileName\"? Cela supprimera tous les projets, dossiers de projets et sorties de ce profil.';
  }

  @override
  String get editProfile => 'Modifier le Profil';

  @override
  String get changePhoto => 'Changer la Photo';

  @override
  String get remove => 'Supprimer';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$trackName\" de cette sortie ?';
  }

  @override
  String get saveName => 'Enregistrer le Nom';

  @override
  String get profilePhotoUpdated => 'Photo de profil mise à jour.';

  @override
  String get profilePhotoRemoved => 'Photo de profil supprimée.';

  @override
  String profileRenamed(String newName) {
    return 'Profil renommé en \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Profil \"$name\" créé avec succès';
  }

  @override
  String profileDeleted(String name) {
    return 'Profil \"$name\" supprimé';
  }

  @override
  String get pleaseEnterProfileName => 'Veuillez entrer un nom de profil';

  @override
  String failedToCreateProfile(String error) {
    return 'Échec de la création du profil: $error';
  }

  @override
  String get noProfilesFound => 'Aucun profil trouvé. Créez-en un ci-dessus.';

  @override
  String get clearLibraryTooltip =>
      'Vider la Bibliothèque (projets et dossiers de projets)';

  @override
  String lastModified(String date) {
    return 'Dernière modification: $date';
  }

  @override
  String get name => 'Nom';

  @override
  String get status => 'Statut';

  @override
  String get phase => 'Phase';

  @override
  String get filterByPhase => 'Filtrer par Phase';

  @override
  String get filters => 'Filtres';

  @override
  String get allPhases => 'Toutes les Phases';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => 'Dernière Modification';

  @override
  String get actions => 'Actions';

  @override
  String get hide => 'Masquer';

  @override
  String get unhide => 'Afficher';

  @override
  String get extractMetadata => 'Extraire les Métadonnées';

  @override
  String get createRelease => 'Créer une Sortie';

  @override
  String get clearSelection => 'Effacer la Sélection';

  @override
  String get selectAllProjects => 'Sélectionner tous les projets';

  @override
  String get switchingProfiles => 'Changement de profils...';

  @override
  String get scanningProjects => 'Scan des projets...';

  @override
  String get search => 'Rechercher';

  @override
  String get projectsTab => 'Projets';

  @override
  String get releasesTab => 'Sorties';

  @override
  String get showHidden => 'Afficher les Masqués';

  @override
  String get showAll => 'Afficher Tout';

  @override
  String get showOnlyHidden => 'Afficher Seulement les Masqués';

  @override
  String get deleteRootPath => 'Supprimer le dossier de projets';

  @override
  String deleteRootPathMessage(String path) {
    return 'Êtes-vous sûr de vouloir supprimer \"$path\"? Cela supprimera également tous les projets de ce dossier qui ne sont pas dans les sorties.';
  }

  @override
  String rootsCount(int count) {
    return 'Dossiers de Projets: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Projets: $count';
  }

  @override
  String get hiddenOnly => '(masqués uniquement)';

  @override
  String hiddenCount(int count) {
    return '($count masqués)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count projet$plural masqué$plural.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count projet$plural affiché$plural.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Échec du masquage des projets: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Échec de l\'affichage des projets: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Êtes-vous sûr de vouloir masquer \"$projectName\" ?';
  }

  @override
  String releaseCreated(String title) {
    return 'Sortie \"$title\" créée avec succès.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Échec de la création de la sortie: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Erreur lors de l\'ajout du dossier: $error';
  }

  @override
  String get noProjectsFoundInRoots =>
      'Aucun projet trouvé dans les dossiers de projets sélectionnés.';

  @override
  String get selectProjectsFolder => 'Sélectionnez un dossier de projets';

  @override
  String get enterReleaseTitle => 'Entrez le Titre de la Sortie';

  @override
  String get releaseTitle => 'Titre de la Sortie';

  @override
  String get enterReleaseTitleHint => 'Entrez le titre de la sortie';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Métadonnées extraites pour $count projet$plural. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count échoué$plural.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'Échec de l\'écriture du fichier BPM: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Échec de l\'écriture du fichier de tonalité: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Échec de l\'ouverture: $error';
  }

  @override
  String get libraryCleared => 'Bibliothèque vidée.';

  @override
  String scanType(String type) {
    return 'Scan $type';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type terminé: $count projet$plural ajouté$plural/mis à jour$plural.';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count projet$plural sélectionné$plural';
  }

  @override
  String openingFolder(String projectName) {
    return 'Ouverture du dossier pour $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Échec de l\'ouverture du dossier: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'Système d\'exploitation non pris en charge pour ouvrir le dossier.';

  @override
  String get noProjectsAvailable =>
      'Aucun projet disponible. Veuillez d\'abord ajouter des projets.';

  @override
  String get createNewRelease => 'Créer une Nouvelle Sortie';

  @override
  String get deleteRelease => 'Supprimer la Sortie';

  @override
  String deleteReleaseMessage(String title) {
    return 'Êtes-vous sûr de vouloir supprimer \"$title\"?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Sortie \"$title\" supprimée.';
  }

  @override
  String get selectTracks => 'Sélectionner les Pistes';

  @override
  String get continueButton => 'Continuer';

  @override
  String get noReleasesYet => 'Aucune sortie pour le moment';

  @override
  String get createFirstRelease =>
      'Créez votre première sortie en sélectionnant des pistes de vos projets';

  @override
  String releasesCount(int count) {
    return 'Sorties ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Erreur lors du chargement des sorties: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Pistes ($count)';
  }

  @override
  String get addTracks => 'Ajouter des Pistes';

  @override
  String get allProjectsAlreadyInRelease =>
      'Tous les projets sont déjà dans cette sortie.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'Ajouté$plural $count piste$plural à la sortie.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Fichiers de la Sortie ($count)';
  }

  @override
  String get addFiles => 'Ajouter des Fichiers';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'Ajouté$plural $count fichier$plural à la sortie.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Échec de l\'ajout des fichiers: $error';
  }

  @override
  String get noFilesToDownload => 'Aucun fichier à télécharger.';

  @override
  String zipFileSaved(String path) {
    return 'Fichier ZIP enregistré dans: $path';
  }

  @override
  String get creatingZipFile => 'Création du fichier ZIP...';

  @override
  String failedToCreateZip(String error) {
    return 'Échec de la création du ZIP: $error';
  }

  @override
  String get selectedFileDoesNotExist =>
      'Le fichier sélectionné n\'existe pas.';

  @override
  String get imageSavedSuccessfully => 'Image enregistrée avec succès!';

  @override
  String failedToSaveImage(String error) {
    return 'Échec de l\'enregistrement de l\'image: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Erreur lors du chargement de la sortie: $error';
  }

  @override
  String get errorLoadingProjects =>
      'Erreur lors du chargement des projets: null';

  @override
  String get releaseSaved => 'Sortie enregistrée.';

  @override
  String get releaseDate => 'Date de Sortie';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Échec de l\'enregistrement de la date de sortie: $error';
  }

  @override
  String get releaseDateSaved => 'Date de sortie enregistrée.';

  @override
  String get releaseDateCleared => 'Date de sortie effacée.';

  @override
  String get saveReleaseFilesZip => 'Enregistrer les fichiers ZIP de la sortie';

  @override
  String get failedToOpenFile => 'Échec de l\'ouverture du fichier';

  @override
  String failedToPlayAudio(String error) {
    return 'Échec de la lecture audio: $error';
  }

  @override
  String get renameFile => 'Renommer le Fichier';

  @override
  String get selectTracksToAdd => 'Sélectionner les Pistes à Ajouter';

  @override
  String get fileNameUpdated => 'Nom du fichier mis à jour.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Erreur lors de la mise à jour du nom du fichier: $error';
  }

  @override
  String get deleteFile => 'Supprimer le Fichier';

  @override
  String deleteFileMessage(String fileName) {
    return 'Êtes-vous sûr de vouloir supprimer \"$fileName\"?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'Fichier \"$fileName\" supprimé.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Échec de la suppression du fichier: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Impossible d\'ouvrir le dossier: $error';
  }

  @override
  String get artwork => 'Artwork';

  @override
  String get title => 'Titre';

  @override
  String get tracks => 'Pistes';

  @override
  String get description => 'Description';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Sélectionner les pistes à inclure dans la sortie ($count sélectionnée$plural)';
  }

  @override
  String get searchTracks => 'Rechercher des pistes';

  @override
  String get searchTracksHint => 'Rechercher par nom ou type de DAW';

  @override
  String get noTracksFound => 'Aucune piste trouvée';

  @override
  String get unknown => 'Inconnu';

  @override
  String get fileNotFound => 'Fichier non trouvé';

  @override
  String get fileName => 'Nom du Fichier';

  @override
  String get editTodo => 'Modifier la Tâche';

  @override
  String get todoText => 'Texte de la tâche';

  @override
  String get enterTodoText => 'Entrez le texte de la tâche';

  @override
  String get addNewTodo => 'Ajouter une nouvelle tâche';

  @override
  String get enterTodoItem => 'Entrez l\'élément de la tâche';

  @override
  String get todoList => 'Liste de Tâches';

  @override
  String get todoTemplates => 'Modèles de TODO';

  @override
  String get createTemplate => 'Créer un Modèle';

  @override
  String get editTemplate => 'Modifier le Modèle';

  @override
  String get deleteTemplate => 'Supprimer le Modèle';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer le modèle \"$name\" ?';
  }

  @override
  String get templateName => 'Nom du Modèle';

  @override
  String get templateNameHint => 'ex. Liste de Mixage';

  @override
  String get templateItems => 'Éléments du Modèle';

  @override
  String get templateItemsHint => 'Un élément par ligne';

  @override
  String get templateNameAndItemsRequired =>
      'Le nom et les éléments sont requis';

  @override
  String get templateItemsRequired => 'Au moins un élément est requis';

  @override
  String get templateCreated => 'Modèle créé';

  @override
  String get templateUpdated => 'Modèle mis à jour';

  @override
  String get templateDeleted => 'Modèle supprimé';

  @override
  String get noTemplatesYet => 'Pas encore de modèles';

  @override
  String get createFirstTemplate => 'Créez votre premier modèle TODO';

  @override
  String templateItemCount(int count) {
    return '$count élément(s)';
  }

  @override
  String get selectTemplate => 'Sélectionner un Modèle';

  @override
  String get importFromTemplate => 'Importer depuis un Modèle';

  @override
  String get manageTemplates => 'Gérer les Modèles';

  @override
  String get noTemplatesAvailable =>
      'Aucun modèle disponible. Créez-en un d\'abord.';

  @override
  String templateImported(String name, int count) {
    return 'Modèle \"$name\" importé ($count éléments)';
  }

  @override
  String get errorLoadingTemplates => 'Erreur de chargement des modèles';

  @override
  String get importTodos => 'Importer des Tâches depuis un Fichier';

  @override
  String get noTodosInFile => 'Aucune tâche trouvée dans le fichier';

  @override
  String todosImported(int count) {
    return '$count tâche(s) importée(s) avec succès';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Erreur lors de l\'importation: $error';
  }

  @override
  String get addToRelease => 'Ajouter à la Sortie';

  @override
  String get createNew => 'Créer Nouveau';

  @override
  String get addToExisting => 'Ajouter à l\'Existant';

  @override
  String get createAndAdd => 'Créer et Ajouter';

  @override
  String get selectRelease => 'Sélectionnez une sortie';

  @override
  String get noExistingReleasesFound => 'Aucune sortie existante trouvée.';

  @override
  String get addToSelectedRelease => 'Ajouter à la Sortie Sélectionnée';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Échec de l\'enregistrement de la photo de profil: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Échec de la suppression de la photo de profil: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Échec du renommage du profil: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Échec de la suppression du profil: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Erreur lors du chargement des profils: $error';
  }

  @override
  String get projectPhaseIdea => 'Idée';

  @override
  String get projectPhaseArranging => 'Arrangement';

  @override
  String get projectPhaseMixing => 'Mixage';

  @override
  String get projectPhaseMastering => 'Masterisation';

  @override
  String get projectPhaseFinished => 'Terminé';

  @override
  String get changeStatus => 'Changer la Phase';

  @override
  String get selectNewStatus => 'Sélectionnez la nouvelle phase:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Phase changée en \"$status\" pour $count projet$plural';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Phase changée en \"$status\" pour $successCount projet$successPlural, $failCount a échoué$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Échec du changement de phase: $error';
  }

  @override
  String get tooltipEditProfileName => 'Modifier le nom du profil';

  @override
  String get tooltipAddTodo => 'Ajouter une tâche';

  @override
  String get tooltipClearDate => 'Effacer la date';

  @override
  String get tooltipPickDate => 'Choisir la date';

  @override
  String get tooltipViewDetails => 'Voir les Détails';

  @override
  String get tooltipLaunchInDaw => 'Ouvrir dans le DAW';

  @override
  String get tooltipRemoveFromRelease => 'Retirer de la Sortie';

  @override
  String get profile => 'Profil';

  @override
  String get noDateSet => 'Aucune date définie';

  @override
  String get imageNotFound => 'Image introuvable';

  @override
  String get clickToBrowseArtwork => 'Cliquez pour parcourir l\'artwork';

  @override
  String get noFilesAddedYet =>
      'Aucun fichier ajouté pour le moment.\nCliquez sur \"Ajouter des Fichiers\" pour télécharger les fichiers de la sortie.';

  @override
  String get noTodosYet =>
      'Aucune tâche pour le moment. Ajoutez-en une ci-dessus.';

  @override
  String get done => 'Terminé';

  @override
  String get backupAndRestore => 'Sauvegarde et Restauration';

  @override
  String get exportBackup => 'Exporter la Sauvegarde';

  @override
  String get importBackup => 'Importer la Sauvegarde';

  @override
  String get backupExportedSuccessfully => 'Sauvegarde exportée avec succès';

  @override
  String failedToExportBackup(String error) {
    return 'Échec de l\'exportation de la sauvegarde : $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Sauvegarde importée avec succès : $projectsCount projets, $rootsCount dossiers de projets, $releasesCount sorties';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Échec de l\'importation de la sauvegarde : $error';
  }

  @override
  String get importBackupMessage =>
      'Choisissez comment importer la sauvegarde :';

  @override
  String get mergeWithCurrentProfile => 'Fusionner avec le profil actif actuel';

  @override
  String get replaceCurrentProfile =>
      'Remplacer entièrement le profil actuel (ATTENTION : Cela supprimera toutes les données du profil actuel)';

  @override
  String get createNewProfileForImport =>
      'Créer un nouveau profil pour ces données';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Sauvegarde importée dans le nouveau profil \"$profileName\" : $projectsCount projets, $rootsCount dossiers de projets, $releasesCount sorties';
  }

  @override
  String get noProfileSelected => 'Aucun profil sélectionné';

  @override
  String get exportBackupDialogTitle => 'Exporter la Sauvegarde';

  @override
  String get importBackupDialogTitle => 'Importer la Sauvegarde';

  @override
  String get invalidBackupFileFormat =>
      'Format de fichier de sauvegarde invalide : version manquante';

  @override
  String get profileNameRequiredForNewProfile =>
      'Le nom du profil est requis lors de la création d\'un nouveau profil';

  @override
  String get currentProfileRequired =>
      'Le profil actuel est requis pour le mode fusionner ou remplacer';

  @override
  String get previewSong => 'Chanson d\'Aperçu';

  @override
  String get noPreviewSongTitle => 'Pas de chanson d\'aperçu';

  @override
  String get noPreviewSongMessage =>
      'Ce projet n\'a pas de chanson d\'aperçu définie. Sélectionnez un fichier audio pour le charger et le lire.';

  @override
  String get noPreviewSongDragHint =>
      'Vous pouvez également glisser-déposer un fichier audio directement sur la ligne du projet dans le tableau.';

  @override
  String get previewSongRemoved => 'Chanson d\'aperçu supprimée';

  @override
  String get previewSongAdded => 'Chanson d\'aperçu ajoutée';

  @override
  String get previewSongFileNotFound =>
      'Fichier de chanson d\'aperçu introuvable';

  @override
  String get previewSongFileNotFoundMessage =>
      'Le fichier de chanson d\'aperçu est introuvable sur le disque. Voulez-vous sélectionner un nouveau fichier ou supprimer l\'entrée ?';

  @override
  String get selectNewFile => 'Sélectionner un nouveau fichier';

  @override
  String failedToPlayPreview(String error) {
    return 'Échec de la lecture de l\'aperçu : $error';
  }

  @override
  String get removePreviewSong => 'Supprimer la chanson d\'aperçu';

  @override
  String get removePreviewSongConfirm =>
      'Êtes-vous sûr de vouloir supprimer la chanson d\'aperçu ? Cette action ne peut pas être annulée.';

  @override
  String get noPreviewSongSelected => 'Aucune chanson d\'aperçu sélectionnée';

  @override
  String get changePreviewSong => 'Changer la Chanson d\'Aperçu';

  @override
  String get selectPreviewSong => 'Sélectionner une Chanson d\'Aperçu';

  @override
  String get dropAudioFileHere => 'Déposez le fichier audio ici';

  @override
  String projectAge(String age) {
    return 'Âge du projet: $age';
  }

  @override
  String createdDate(String date) {
    return 'créé $date';
  }

  @override
  String completedIn(String duration) {
    return 'Terminé en: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'terminé $date';
  }

  @override
  String get dateToday => 'aujourd\'hui';

  @override
  String get dateYesterday => 'hier';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count semaines',
      one: 'il y a 1 semaine',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count mois',
      one: 'il y a 1 mois',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count ans',
      one: 'il y a 1 an',
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
    return '$years an$yearPlural, $months mois';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years an$plural';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months mois, $days jour$dayPlural';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months mois';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days jour$plural';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours heure$plural';
  }

  @override
  String get ageJustNow => 'À l\'instant';

  @override
  String get ageLessThanHour => 'Moins d\'une heure';

  @override
  String get viewProfile => 'Voir le Profil';

  @override
  String get googleDriveSync => 'Synchronisation Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Synchronisez vos données avec Google Drive pour sauvegarder et restaurer entre les appareils.';

  @override
  String get manageGoogleDriveSync => 'Gérer la Synchronisation Google Drive';

  @override
  String get signInToGoogleDrive => 'Se connecter à Google Drive';

  @override
  String get syncNow => 'Synchroniser Maintenant';

  @override
  String get uploadBackup => 'Téléverser la Sauvegarde';

  @override
  String get downloadBackup => 'Télécharger la Sauvegarde';

  @override
  String get newerBackupAvailable =>
      'Nouvelle sauvegarde disponible dans le cloud';

  @override
  String get signOut => 'Se Déconnecter';

  @override
  String get downloadPreviewSongs => 'Télécharger les chansons d\'aperçu';

  @override
  String get downloadPreviewSongsExplanation =>
      'Si décoché, les chansons d\'aperçu seront ignorées (économise du temps et de l\'espace). Vous pouvez les télécharger plus tard si nécessaire.';

  @override
  String get replaceLocalData => 'Remplacer les Données Locales';

  @override
  String get downloadBackupConfirmation =>
      'Cela remplacera vos données locales par la sauvegarde de Google Drive.\n\nÊtes-vous sûr de vouloir continuer?';

  @override
  String get enterAuthorizationCode => 'Entrer le Code d\'Autorisation';

  @override
  String get authorizationCode => 'Code d\'Autorisation';

  @override
  String get pasteCodeFromBrowser => 'Collez le code du navigateur';

  @override
  String get sessionActive => 'Session active';

  @override
  String get signedIn => 'Connecté';

  @override
  String get creatingInitialBackup => 'Création de la sauvegarde initiale...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Connexion réussie et sauvegarde créée sur Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Connexion réussie et sauvegarde créée sur Google Drive!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Connexion réussie à Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Connexion réussie à Google Drive!';

  @override
  String get signInCancelledOrFailed =>
      'Connexion annulée ou échouée. Vérifiez la console pour plus de détails.';

  @override
  String get failedToLaunchBrowser => 'Échec du lancement du navigateur';

  @override
  String get signInCancelled => 'Connexion annulée';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Échec de l\'échange du code d\'autorisation';

  @override
  String errorSigningIn(String error) {
    return 'Erreur lors de la connexion: $error';
  }

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String get googleSignInError => 'Erreur de Connexion Google';

  @override
  String get developerConsoleNotSetUp =>
      'La console développeur n\'est pas correctement configurée. Veuillez vérifier votre configuration OAuth dans Google Cloud Console.';

  @override
  String get platformError => 'Erreur de Plateforme';

  @override
  String get signedOutFromGoogleDrive => 'Déconnecté de Google Drive';

  @override
  String errorSigningOut(String error) {
    return 'Erreur lors de la déconnexion: $error';
  }

  @override
  String get syncing => 'Synchronisation...';

  @override
  String get errorNoProfileSelected => 'Erreur: Aucun profil sélectionné';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Synchronisation terminée! Projets: +$projectsAdded ~$projectsUpdated, Sorties: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Erreur lors de la synchronisation: $error';
  }

  @override
  String get uploadingBackup => 'Téléversement de la sauvegarde...';

  @override
  String get backupUploadedSuccessfully => 'Sauvegarde téléversée avec succès!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Sauvegarde téléversée avec succès sur Google Drive!';

  @override
  String errorUploadingBackup(String error) {
    return 'Erreur lors du téléversement de la sauvegarde: $error';
  }

  @override
  String get downloadingBackup => 'Téléchargement de la sauvegarde...';

  @override
  String get checkingForBackup => 'Vérification de la sauvegarde...';

  @override
  String get backupUpToDate => 'La sauvegarde est à jour';

  @override
  String errorCheckingBackup(String error) {
    return 'Erreur lors de la vérification de la sauvegarde: $error';
  }

  @override
  String get download => 'Télécharger';

  @override
  String get remoteBackupIsNewer =>
      'La sauvegarde distante est plus récente que les données locales. Le téléversement l\'écrasera.';

  @override
  String get confirmUpload => 'Confirmer le téléversement';

  @override
  String get noBackupFileFound =>
      'Aucun fichier de sauvegarde trouvé dans Google Drive. Créez d\'abord une sauvegarde en synchronisant vos données.';

  @override
  String get noBackupFileFoundStatus =>
      'Aucun fichier de sauvegarde trouvé. Créez d\'abord une sauvegarde.';

  @override
  String get downloadCancelled => 'Téléchargement annulé';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Sauvegarde téléchargée! Projets: +$projectsAdded ~$projectsUpdated, Sorties: +$releasesAdded ~$releasesUpdated';
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
    return 'Sauvegarde téléchargée!\n\nProjets:\n  • $projectsAdded ajoutés\n  • $projectsUpdated mis à jour\n\nSorties:\n  • $releasesAdded ajoutées\n  • $releasesUpdated mises à jour\n\nPreview Songs:\n  • $previewSongsDownloaded téléchargées\n  • $previewSongsUpdated mises à jour';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Erreur lors du téléchargement de la sauvegarde: $error';
  }

  @override
  String signedInAs(String email) {
    return 'Connecté en tant que: $email';
  }

  @override
  String lastSync(String date) {
    return 'Dernière synchronisation: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Sauvegarde distante: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Dernier envoi: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Dernier téléchargement: $date';
  }

  @override
  String get checkForBackup => 'Vérifier la sauvegarde';

  @override
  String get notificationSettings => 'Paramètres de Notification';

  @override
  String get notificationsOnlyOnAndroid =>
      'Les notifications de délai ne sont disponibles que sur les appareils Android.';

  @override
  String get notificationPermissionRequired =>
      'Permission de Notification Requise';

  @override
  String get notificationPermissionDescription =>
      'Veuillez activer les notifications pour recevoir des rappels de délai.';

  @override
  String get notificationPermissionDenied =>
      'Permission de notification refusée. Veuillez l\'activer dans les paramètres.';

  @override
  String get notificationSettingsSaved =>
      'Paramètres de notification enregistrés avec succès';

  @override
  String get errorSavingSettings =>
      'Erreur lors de l\'enregistrement des paramètres';

  @override
  String get enableDeadlineNotifications =>
      'Activer les Notifications de Délai';

  @override
  String get receiveRemindersForDeadlines =>
      'Recevoir des rappels pour les délais de projet';

  @override
  String get notificationTime => 'Heure de Notification';

  @override
  String get timeToReceiveNotifications =>
      'Heure de la journée pour recevoir les notifications';

  @override
  String get reminderDays => 'Jours de Rappel';

  @override
  String get selectDaysBeforeDeadline =>
      'Sélectionnez combien de jours avant le délai vous souhaitez être notifié';

  @override
  String get notifyOnDeadlineDay => 'Notifier le Jour du Délai';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'Recevoir également une notification le jour même du délai';

  @override
  String get howItWorks => 'Comment Ça Marche';

  @override
  String get deadlineNotificationsHelp =>
      'Vous recevrez des notifications à l\'heure spécifiée les jours sélectionnés avant chaque délai de projet. Appuyez sur une notification pour ouvrir les détails du projet.';

  @override
  String get oneDay => '1 jour';

  @override
  String xDays(int count) {
    return '$count jours';
  }

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get support => 'Soutenir';

  @override
  String get supportTheProject => 'Soutenez le projet';

  @override
  String couldNotOpenBrowser(String url) {
    return 'Impossible d\'ouvrir le navigateur. Veuillez visiter: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Erreur lors de l\'ouverture du navigateur: $error';
  }

  @override
  String get generateTestingDatabase => 'Générer Base de Données de Test';

  @override
  String get generateTestingDatabaseMessage =>
      'Cela remplira la base de données avec des projets et des sorties d\'exemple pour les tests. Continuer?';

  @override
  String get testingDatabaseGenerated =>
      'Base de données de test générée avec succès!';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Échec de la génération de la base de données de test: $error';
  }

  @override
  String get playlists => 'Listes de Lecture';

  @override
  String get playlistsDesktopOnly =>
      'Les listes de lecture ne sont disponibles que sur Android.';

  @override
  String get noPlaylistsYet => 'Pas encore de listes';

  @override
  String get createFirstPlaylist =>
      'Appuyez sur + pour créer votre première liste';

  @override
  String playlistSongCount(int count) {
    return '$count morceaux';
  }

  @override
  String get createPlaylist => 'Créer une Liste';

  @override
  String get playlistName => 'Nom de la Liste';

  @override
  String get playlistNameHint => 'Ma Liste';

  @override
  String get playlistNameRequired => 'Nom de liste requis';

  @override
  String get editPlaylist => 'Modifier la Liste';

  @override
  String get stopPlaybackBeforeEditing =>
      'Veuillez arrêter la lecture avant de modifier la liste de lecture';

  @override
  String get selectPreviewSongs => 'Sélectionner les Aperçus';

  @override
  String get deletePlaylist => 'Supprimer la Liste';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ?';
  }

  @override
  String get playlistDeleted => 'Liste supprimée';

  @override
  String get errorDeletingPlaylist =>
      'Erreur lors de la suppression de la liste';

  @override
  String get playlistUpdated => 'Liste mise à jour';

  @override
  String get changeSong => 'Changer de Chanson';

  @override
  String get changeSongConfirm =>
      'Une chanson est en cours de lecture. Voulez-vous passer à cette chanson ?';

  @override
  String get changeSongButton => 'Changer';

  @override
  String playlistProgress(int current, int total) {
    return '$current sur $total';
  }

  @override
  String get noPreviewSongsInPlaylist =>
      'Aucun aperçu disponible dans cette liste';

  @override
  String get tapEditToAddSongs =>
      'Appuyez sur modifier pour ajouter des chansons à cette playlist';

  @override
  String get noProjectsAvailableForPlaylist =>
      'Aucun projet avec des chansons de prévisualisation disponibles à ajouter';

  @override
  String get noProjectsInDatabase =>
      'Aucun projet trouvé dans la base de données. Veuillez d\'abord synchroniser vos projets.';

  @override
  String get firstTimeSyncTitle =>
      'Il semble que ce soit votre première fois ici !';

  @override
  String get firstTimeSyncMessage =>
      'Synchronisons vos données depuis Google Drive pour commencer';

  @override
  String get syncWithGoogleDrive => 'Synchroniser avec Google Drive';

  @override
  String get errorLoadingPlaylists => 'Erreur de chargement des listes';

  @override
  String get playlistItems => 'Éléments de la Liste';

  @override
  String get addSongs => 'Ajouter des Morceaux';

  @override
  String get addAudioFiles => 'Ajouter des Fichiers Audio';

  @override
  String get selectAudioFiles => 'Sélectionner des Fichiers Audio';

  @override
  String get selectFromProjects => 'Sélectionner des Projets';

  @override
  String get add => 'Ajouter';

  @override
  String get fromProject => 'Du Projet';

  @override
  String get projectDeadline => 'Date Limite du Projet';

  @override
  String get noDeadlineSet => 'Aucune date limite';

  @override
  String get camelotCode => 'Code Camelot';

  @override
  String get deadline => 'Date Limite';

  @override
  String get dueToday => 'Échéance aujourd\'hui';

  @override
  String daysLate(int days) {
    return '${days}j en retard';
  }

  @override
  String daysLeft(int days) {
    return '${days}j restants';
  }

  @override
  String get hideFinished => 'Masquer Terminés';

  @override
  String get showOnlyDeadlines => 'Afficher échéance';

  @override
  String get filterByDeadline => 'Filtrer par Date Limite';

  @override
  String get allDeadlines => 'Toutes les Dates';

  @override
  String get hasDeadline => 'Avec Date Limite';

  @override
  String get overdue => 'En Retard';

  @override
  String get dueSoon => 'Bientôt Échu (7j)';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get noPreviewSong => 'Pas d\'aperçu';

  @override
  String get playPreview => 'Lire l\'Aperçu';

  @override
  String get uploadCancelled => 'Téléchargement annulé';

  @override
  String get backupUploadCancelledByUser =>
      'Téléchargement de sauvegarde annulé par l\'utilisateur';

  @override
  String get collectingData => 'Collecte des données...';

  @override
  String get uploadingPreviewSongs => 'Téléchargement des aperçus musicaux...';

  @override
  String get uploadingProfilePhotos => 'Téléchargement des photos de profil...';

  @override
  String get uploadingReleaseArtwork =>
      'Téléchargement des artwork de sortie...';

  @override
  String get uploadingDatabase => 'Téléchargement de la base de données...';

  @override
  String get completed => 'Terminé !';

  @override
  String get cancelling => 'Annulation...';

  @override
  String get uploadingBackupTitle => 'Téléchargement de la Sauvegarde';

  @override
  String get cancellingUpload => 'Annulation du téléchargement...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Veuillez patienter pendant l\'arrêt du téléchargement...';

  @override
  String get downloadingDatabase => 'Téléchargement de la base de données...';

  @override
  String get downloadingPreviewSongs =>
      'Téléchargement des chansons d\'aperçu...';

  @override
  String get downloadingProfilePhotos =>
      'Téléchargement des photos de profil...';

  @override
  String get downloadingReleaseArtwork =>
      'Téléchargement des artwork de sortie...';

  @override
  String get mergingData => 'Fusion des données...';

  @override
  String get downloadingBackupTitle => 'Téléchargement de la Sauvegarde';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'Fichier source introuvable sur cette machine';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'Fichier source introuvable sur cette machine — mode métadonnées uniquement. Vous pouvez toujours modifier et exporter les métadonnées.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Chanson d\'aperçu non disponible. Veuillez d\'abord télécharger la sauvegarde.';

  @override
  String get sharePreviewSong => 'Partager la chanson d\'aperçu';

  @override
  String get shareAsZip => 'Partager en ZIP';

  @override
  String get share => 'Partager';

  @override
  String get shareZip => 'Partager ZIP';

  @override
  String get saveCopy => 'Enregistrer une copie';

  @override
  String savedCopyTo(String path) {
    return 'Enregistré dans $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Échec du partage de la chanson d\'aperçu : $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Échec du partage de la chanson d\'aperçu en ZIP : $error';
  }

  @override
  String get biographySaved => 'Biographie enregistrée';

  @override
  String failedToSaveBiography(String error) {
    return 'Échec de l\'enregistrement de la biographie : $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'Fichier enregistré dans $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Échec du téléchargement du fichier : $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'Tous les fichiers enregistrés dans $filename';
  }

  @override
  String get artworkAdded => 'Artwork ajouté';

  @override
  String failedToAddArtwork(String error) {
    return 'Échec de l\'ajout de l\'artwork : $error';
  }

  @override
  String get artworkRemoved => 'Artwork supprimé';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Échec de la suppression de l\'artwork : $error';
  }

  @override
  String get pressKitFileAdded => 'Fichier de presse ajouté';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Échec de l\'ajout du fichier de presse : $error';
  }

  @override
  String get pressKitFileRemoved => 'Fichier de presse supprimé';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Échec de la suppression du fichier de presse : $error';
  }

  @override
  String get selectFilesToDownload => 'Sélectionner les Fichiers à Télécharger';

  @override
  String get biography => 'Biographie';

  @override
  String get biographyWillBeSaved => 'Sera enregistré sous biography.txt';

  @override
  String get artworkFiles => 'Fichiers Artwork';

  @override
  String get pressKitFiles => 'Fichiers de Presse';

  @override
  String get additionalAssets => 'Ressources Supplémentaires';

  @override
  String downloadNFiles(int count, String plural) {
    return 'Télécharger $count fichier$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count fichier$plural enregistré dans $filename';
  }

  @override
  String get addAsset => 'Ajouter une Ressource';

  @override
  String get assetNameLabel => 'Nom de la Ressource';

  @override
  String get assetNameHint => 'ex., Logo, Bannière, Photo';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName ajouté avec succès';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Échec de l\'ajout de la ressource : $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName supprimé';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Échec de la suppression de la ressource : $error';
  }

  @override
  String get profileNotFound => 'Profil introuvable';

  @override
  String get selectFiles => 'Sélectionner des Fichiers';

  @override
  String get downloadAll => 'Tout Télécharger';

  @override
  String get saveBiographyTooltip => 'Enregistrer la Biographie';

  @override
  String get enterBiographyHint => 'Entrez la biographie du profil...';

  @override
  String get addArtwork => 'Ajouter un Artwork';

  @override
  String get addFile => 'Ajouter un Fichier';

  @override
  String get openFile => 'Ouvrir le Fichier';

  @override
  String get menuView => 'Affichage';

  @override
  String get menuAbout => 'À propos de DAW Project Manager';

  @override
  String get menuDocumentation => 'Documentation';

  @override
  String get menuLanguage => 'Langue';

  @override
  String get menuWarnBeforeQuit => 'Avertir Avant de Quitter (Cmd+Q)';

  @override
  String get menuQuit => 'Quitter DAW Project Manager';

  @override
  String get menuWindow => 'Fenêtre';

  @override
  String get donate => 'Faire un Don';

  @override
  String get website => 'Site Web';

  @override
  String get switchToClassicDark => 'Passer à Classic Dark';

  @override
  String get switchToNeonDark => 'Passer à Neon Dark';

  @override
  String get switchToClassicTheme => 'Passer au Thème Classique';

  @override
  String get switchToNeonTheme => 'Passer au Thème Néon';

  @override
  String get menuTheme => 'Thème';

  @override
  String get appDescription =>
      'Un gestionnaire de projets pour les producteurs de musique et les concepteurs sonores.';

  @override
  String get neonDarkThemeName => 'Néon Sombre';

  @override
  String get classicDarkThemeName => 'Classique Sombre';

  @override
  String get statisticsTab => 'Statistiques';

  @override
  String get statsTotalProjects => 'Total des Projets';

  @override
  String get statsInProgress => 'En cours';

  @override
  String get statsFinished => 'Terminés';

  @override
  String get statsAvgCompletion => 'Achèvement moy.';

  @override
  String get statsPhaseDistribution => 'Projets par Phase';

  @override
  String get statsAvgTimePerPhase => 'Jours moy. par Phase';

  @override
  String get statsProductivity => 'Productivité';

  @override
  String get statsCreatedSeries => 'Créés';

  @override
  String get statsProjectHealth => 'Âge et Santé des Projets';

  @override
  String get statsCatalogInsights => 'Analyse du Catalogue';

  @override
  String get statsBpmDistribution => 'Distribution BPM';

  @override
  String get statsTopKeys => 'Tonalités principales';

  @override
  String get statsDawTypes => 'Types de DAW';

  @override
  String get statsProjectActivity => 'Activité des Projets';

  @override
  String get statsNoData => 'Pas encore de données';

  @override
  String get statsNoPhaseData =>
      'Les données de phases apparaîtront après des transitions de phase.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Dernière activité: il y a $days j';
  }

  @override
  String get statsLastActivityToday => 'Actif aujourd\'hui';

  @override
  String get statsNoEvents => 'Aucun événement enregistré';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Phase: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Mis à jour: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Terminé: $text';
  }

  @override
  String get statsEventFileModified => 'Fichier modifié sur disque';

  @override
  String get statsClearHistory => 'Effacer l\'historique';

  @override
  String get statsClearHistoryConfirm =>
      'Effacer tous les événements enregistrés pour ce projet?';

  @override
  String get statsSearchProjects => 'Rechercher des projets…';

  @override
  String statsEventCount(int count) {
    return '$count événements';
  }

  @override
  String get statsViewHistory => 'Statistiques du Projet';

  @override
  String get statsPhaseHistory => 'Historique des Phases';

  @override
  String get statsEventBreakdown => 'Détail des Événements';

  @override
  String statsDaysSoFar(int days) {
    return '${days}j jusqu\'ici';
  }

  @override
  String get statsNoProjectsFound => 'Aucun projet trouvé';

  @override
  String statsNotTouchedDays(int days) {
    return 'Inchangé depuis $days jours';
  }

  @override
  String get sortByLastModified => 'Dernière modification';

  @override
  String get sortByName => 'Nom';

  @override
  String get sortByPhase => 'Phase';

  @override
  String get sortByCreatedAt => 'Date d\'ajout';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get monoLabel => 'Mono';

  @override
  String get monoToggleTooltip => 'Basculer en lecture mono';

  @override
  String get monoRequiresWav => 'Le mixage mono nécessite un fichier WAV';

  @override
  String get monoUnsupportedFormat =>
      'Impossible de créer le mixage mono — format non pris en charge';

  @override
  String monoSwitchFailed(String error) {
    return 'Échec du passage en mono : $error';
  }

  @override
  String get analyzeLabel => 'Analyser';

  @override
  String get reAnalyzeLabel => 'Ré-analyser';

  @override
  String get analysisRequiresWav => 'L\'analyse nécessite un fichier WAV';

  @override
  String get noResultsForFilter => 'Aucun résultat pour le filtre actuel';

  @override
  String get noResultsForFilterHint =>
      'Essayez d\'ajuster votre recherche ou vos filtres.';

  @override
  String get noProjectsFound => 'Aucun projet trouvé';

  @override
  String get noProjectsFoundHint =>
      'Ajoutez un dossier racine dans les paramètres pour commencer.';

  @override
  String get queueTab => 'Tâches';

  @override
  String get queueSearchHint => 'Rechercher des tâches...';

  @override
  String get queueNoPendingTasks => 'Tout est à jour !';

  @override
  String get queueNoPendingTasksHint =>
      'Aucune tâche en attente dans vos projets.';

  @override
  String get queueNoMatchingTasks => 'Aucune tâche correspondante';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks tâches en attente dans $projects projets';
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
  String get renameProjectFileTitle => 'Renommer le fichier de projet';

  @override
  String get renameFileButtonLabel => 'Renommer le fichier';

  @override
  String get newFileNameLabel => 'Nouveau nom de fichier (sans extension)';

  @override
  String renameAlreadyExists(String name) {
    return 'Un fichier nommé \"$name\" existe déjà.';
  }

  @override
  String renameSuccess(String name) {
    return 'Renommé en \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Échec du renommage : $error';
  }

  @override
  String get nameCannotBeEmpty => 'Le nom ne peut pas être vide';

  @override
  String get nameInvalidCharacters => 'Le nom ne peut pas contenir / \\ :';

  @override
  String get alsoRenameContainingFolder => 'Renommer aussi le dossier parent';

  @override
  String get renameButton => 'Renommer';

  @override
  String get previewMixdownFolderTitle =>
      'Dossier de mixage de prévisualisation';

  @override
  String get previewMixdownFolderSubtitle =>
      'Nom du sous-dossier dans chaque dossier de projet à vérifier en premier lors de la détection automatique des morceaux de prévisualisation. Laisser vide pour utiliser les valeurs par défaut du DAW.';

  @override
  String get previewMixdownFolderHint => 'ex. Mixages';

  @override
  String dawInfoLabel(String daw) {
    return 'DAW : $daw';
  }

  @override
  String bpmInfoLabel(String bpm) {
    return 'BPM : $bpm';
  }

  @override
  String keyInfoLabel(String key) {
    return 'Tonalité : $key';
  }

  @override
  String get audioFileNotFound => 'Fichier audio introuvable';

  @override
  String errorPlayingAudio(String error) {
    return 'Erreur de lecture audio : $error';
  }

  @override
  String get notificationTestTitle =>
      'Tester les notifications pour vérifier le fuseau horaire et la planification :';

  @override
  String get notificationSendNow => 'Envoyer maintenant';

  @override
  String get notificationSchedule30s => 'Planifier +30s';

  @override
  String get notificationShowDebugInfo => 'Afficher les infos de débogage';

  @override
  String get notificationRescheduleAll => 'Replanifier tout';

  @override
  String get notificationTestSent => '✅ Notification de test envoyée !';

  @override
  String get notificationTestScheduled =>
      '✅ Notification de test planifiée dans 30 secondes ! Vérifiez les journaux.';

  @override
  String notificationTestError(String error) {
    return '❌ Erreur : $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Informations de débogage';

  @override
  String get autoDetected => 'Détecté automatiquement';

  @override
  String get matchedInDescription => 'Correspondance dans la description';

  @override
  String get relocateFolderDialogTitle => 'Déplacer le dossier';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chemins de projet mis à jour',
      one: '1 chemin de projet mis à jour',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Personnaliser les onglets';

  @override
  String get customizeTabsDescription =>
      'Choisissez les onglets a afficher dans la barre de navigation. L\'onglet Projets est toujours visible.';

  @override
  String get keyboardShortcuts => 'Raccourcis clavier';

  @override
  String get shortcutGroupGlobal => 'Global';

  @override
  String get shortcutGroupProjectsTable =>
      'Tableau des projets (le tableau doit être focalisé)';

  @override
  String get shortcutGroupReleasesTable =>
      'Tableau des sorties (le tableau doit être focalisé)';

  @override
  String get shortcutGroupNavigation => 'Navigation';

  @override
  String get shortcutFocusSearch => 'Focaliser la barre de recherche';

  @override
  String get shortcutRescan => 'Rescanner les dossiers de projets';

  @override
  String get shortcutFocusTable => 'Focaliser le tableau des projets';

  @override
  String get shortcutPlayPause => 'Lire / mettre en pause la chanson d\'aperçu';

  @override
  String get shortcutOpenInDaw => 'Ouvrir le projet dans le DAW';

  @override
  String get shortcutViewDetails => 'Voir les détails du projet';

  @override
  String get shortcutOpenFolder => 'Ouvrir le dossier du projet';

  @override
  String get shortcutNavigateRows => 'Naviguer dans les lignes';

  @override
  String get shortcutEditCell => 'Ouvrir les détails du projet';

  @override
  String get shortcutViewRelease => 'Voir les détails de la sortie';

  @override
  String get shortcutGoBack => 'Retour';

  @override
  String get shortcutGroupPreviewPlayer => 'Lecteur de prévisualisation';

  @override
  String get shortcutPlayerPlayPause => 'Lecture / pause';

  @override
  String get shortcutPlayerSeek5 => 'Avancer/Reculer de ±5 secondes';

  @override
  String get shortcutPlayerSeek30 => 'Avancer/Reculer de ±30 secondes';

  @override
  String get startupDialogTitle => 'Bienvenue dans DAW Project Manager';

  @override
  String get startupDialogSubtitle =>
      'Commencez en ajoutant un dossier de projets ou en restaurant une sauvegarde Google Drive.';

  @override
  String get startupAddFolderTitle => 'Ajouter un dossier de projets';

  @override
  String get startupAddFolderSubtitle =>
      'Sélectionnez un dossier contenant vos projets DAW.';

  @override
  String get startupGoogleDriveTitle =>
      'Synchroniser la sauvegarde Google Drive';

  @override
  String get startupGoogleDriveSubtitle =>
      'Restaurez vos projets depuis une sauvegarde Google Drive.';

  @override
  String get startupDontShowAgain => 'Ne plus afficher au démarrage';

  @override
  String get deleteAllData => 'Supprimer toutes les données';

  @override
  String get deleteAllDataSubtitle =>
      'Supprimer tous les profils, projets, sorties, playlists et paramètres de cet appareil.';

  @override
  String get deleteAllDataConfirm1Title => 'Supprimer toutes les données ?';

  @override
  String get deleteAllDataConfirm1Message =>
      'Cela supprimera définitivement tous les profils, projets, sorties, playlists et paramètres de cet appareil. Votre sauvegarde Google Drive (le cas échéant) ne sera pas affectée.';

  @override
  String get deleteAllDataConfirm2Title => 'Êtes-vous absolument sûr ?';

  @override
  String get deleteAllDataConfirm2Message =>
      'Cette action est irréversible. L\'application reviendra à son état initial.';

  @override
  String get deleteEverything => 'Tout supprimer';

  @override
  String get allDataDeleted => 'Toutes les données ont été supprimées.';

  @override
  String get newerExportFound => 'Export plus récent trouvé';

  @override
  String newerExportFoundMessage(String filename) {
    return 'Un fichier plus récent a été trouvé dans le même dossier :\n$filename\n\nRemplacer la chanson de prévisualisation ?';
  }

  @override
  String get replaceAndPlay => 'Remplacer et lire';

  @override
  String get keepCurrent => 'Garder l\'actuel';

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
    return 'Next backup: $time';
  }
}
