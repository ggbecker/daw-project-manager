// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DAW Project Manager';

  @override
  String get projectDetails => 'Project Details';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get enable => 'Enable';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get customInterval => 'Custom';

  @override
  String get close => 'Close';

  @override
  String get launch => 'Launch';

  @override
  String get view => 'View';

  @override
  String get openFolder => 'Open Folder';

  @override
  String get openInDaw => 'Launch in DAW';

  @override
  String get extract => 'Extract';

  @override
  String get extracting => 'Extracting…';

  @override
  String get extractingMetadata => 'Extracting metadata...';

  @override
  String get deepScan => 'Deep Scan';

  @override
  String get rescan => 'Rescan';

  @override
  String get refreshProject => 'Refresh';

  @override
  String get scanning => 'Scanning…';

  @override
  String get projectName => 'Project Name';

  @override
  String get bpm => 'BPM';

  @override
  String get key => 'Key (e.g., C#m, F major)';

  @override
  String get notes => 'Notes';

  @override
  String get projectPhase => 'Project Phase';

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String get fileMissing => 'File missing.';

  @override
  String launchingProject(String projectName) {
    return 'Launching $projectName…';
  }

  @override
  String failedToLaunchProject(String projectName) {
    return 'Failed to launch $projectName';
  }

  @override
  String get clearLibrary => 'Clear Library';

  @override
  String get clearLibraryMessage =>
      'This will remove all saved projects and source folders. Continue?';

  @override
  String get clear => 'Clear';

  @override
  String get roots => 'Project Folders';

  @override
  String get pathsSettingsDangerZoneTitle => 'Library';

  @override
  String get pathsSettingsDangerZoneSubtitle =>
      'Clear all projects and project folders for the current profile.';

  @override
  String get projectFoldersSectionTitle => 'Project folders';

  @override
  String get projectFoldersSectionSubtitle =>
      'Folders that will be scanned for DAW projects.';

  @override
  String get projectFoldersEmptyTitle => 'No project folders yet';

  @override
  String get projectFoldersEmptySubtitle =>
      'Add at least one folder to start scanning for projects.';

  @override
  String get notScannedYet => 'Not scanned yet';

  @override
  String lastScan(String date) {
    return 'Last scan: $date';
  }

  @override
  String get excludedFoldersSectionTitle => 'Excluded folders';

  @override
  String get excludedFoldersSectionSubtitle =>
      'These folders will be skipped during scanning, even if they are inside a project folder.';

  @override
  String get addExcludedFolder => 'Add excluded';

  @override
  String get selectExcludedFolder => 'Select a folder to exclude';

  @override
  String get excludedFoldersEmptyTitle => 'No excluded folders';

  @override
  String get excludedFoldersEmptySubtitle =>
      'Optional: add folders you never want to scan.';

  @override
  String get removeExcludedFolderTitle => 'Remove excluded folder?';

  @override
  String removeExcludedFolderMessage(String path) {
    return 'This folder will no longer be excluded:\n\n$path';
  }

  @override
  String get removeExcludedFolderMessageNoPath =>
      'This folder will no longer be excluded.';

  @override
  String get desktopOnlyPathsSettings =>
      'This page is available only on the desktop app.';

  @override
  String get removeProjectFolderTitle => 'Remove project folder?';

  @override
  String removeProjectFolderMessage(String path) {
    return 'Are you sure you want to remove \"$path\"? This will also remove all projects from this folder that are not in releases.';
  }

  @override
  String get projects => 'Projects';

  @override
  String get hidden => 'hidden';

  @override
  String get profileManager => 'Profile Manager';

  @override
  String get createNewProfile => 'Create New Profile';

  @override
  String get profileName => 'Profile Name';

  @override
  String get create => 'Create';

  @override
  String get profiles => 'Profiles';

  @override
  String get active => 'Active';

  @override
  String get switchProfile => 'Switch Profile';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get addFolder => 'Add Folder';

  @override
  String get searchProjects => 'Search projects...';

  @override
  String get searchReleases => 'Search releases...';

  @override
  String get searchPlaylists => 'Search playlists...';

  @override
  String get noReleasesFound => 'No releases found';

  @override
  String get noPlaylistsFound => 'No playlists found';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get deepScanConfirm =>
      'Deep Scan extracts full metadata from project files:\n• BPM (Beats Per Minute)\n• Musical Key\n• DAW Version\nCurrently supported: Ableton Live and Cubase.\n\nThis is slower than a regular scan and may take a while. Continue?';

  @override
  String get deepScanOnlyUnscanned => 'Only scan projects without metadata';

  @override
  String get metadataExtractedSuccessfully => 'Metadata extracted successfully';

  @override
  String failedToExtractMetadata(String error) {
    return 'Failed to extract metadata: $error';
  }

  @override
  String get saved => 'Saved';

  @override
  String get failedToLaunchDaw => 'Failed to launch DAW';

  @override
  String get releaseDetails => 'Release Details';

  @override
  String get releaseNotFound => 'Release Not Found';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get deleteProfile => 'Delete Profile';

  @override
  String deleteProfileMessage(String profileName) {
    return 'Are you sure you want to delete \"$profileName\"? This will delete all projects, project folders, and releases for this profile.';
  }

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get remove => 'Remove';

  @override
  String removeTrackFromReleaseMessage(String trackName) {
    return 'Are you sure you want to remove \"$trackName\" from this release?';
  }

  @override
  String get saveName => 'Save Name';

  @override
  String get profilePhotoUpdated => 'Profile photo updated.';

  @override
  String get profilePhotoRemoved => 'Profile photo removed.';

  @override
  String profileRenamed(String newName) {
    return 'Profile renamed to \"$newName\"';
  }

  @override
  String profileCreated(String name) {
    return 'Profile \"$name\" created successfully';
  }

  @override
  String profileDeleted(String name) {
    return 'Profile \"$name\" deleted';
  }

  @override
  String get pleaseEnterProfileName => 'Please enter a profile name';

  @override
  String failedToCreateProfile(String error) {
    return 'Failed to create profile: $error';
  }

  @override
  String get noProfilesFound => 'No profiles found. Create one above.';

  @override
  String get clearLibraryTooltip =>
      'Clear Library (projects & project folders)';

  @override
  String lastModified(String date) {
    return 'Last modified: $date';
  }

  @override
  String get name => 'Name';

  @override
  String get status => 'Status';

  @override
  String get phase => 'Phase';

  @override
  String get filterByPhase => 'Filter by Phase';

  @override
  String get filters => 'Filters';

  @override
  String get allPhases => 'All Phases';

  @override
  String get daw => 'DAW';

  @override
  String get lastModifiedColumn => 'Last Modified';

  @override
  String get actions => 'Actions';

  @override
  String get hide => 'Hide';

  @override
  String get unhide => 'Unhide';

  @override
  String get extractMetadata => 'Extract Metadata';

  @override
  String get createRelease => 'Create Release';

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get selectAllProjects => 'Select all projects';

  @override
  String get switchingProfiles => 'Switching Profiles...';

  @override
  String get scanningProjects => 'Scanning projects...';

  @override
  String get search => 'Search';

  @override
  String get projectsTab => 'Projects';

  @override
  String get releasesTab => 'Releases';

  @override
  String get showHidden => 'Show Hidden';

  @override
  String get showAll => 'Show All';

  @override
  String get showOnlyHidden => 'Show Only Hidden';

  @override
  String get deleteRootPath => 'Remove project folder';

  @override
  String deleteRootPathMessage(String path) {
    return 'Are you sure you want to remove \"$path\"? This will also remove all projects from this folder that are not in releases.';
  }

  @override
  String rootsCount(int count) {
    return 'Project Folders: $count';
  }

  @override
  String projectsCount(int count) {
    return 'Projects: $count';
  }

  @override
  String get hiddenOnly => '(hidden only)';

  @override
  String hiddenCount(int count) {
    return '($count hidden)';
  }

  @override
  String projectsHidden(int count, String plural) {
    return '$count project$plural hidden.';
  }

  @override
  String projectsUnhidden(int count, String plural) {
    return '$count project$plural unhidden.';
  }

  @override
  String failedToHideProjects(String error) {
    return 'Failed to hide projects: $error';
  }

  @override
  String failedToUnhideProjects(String error) {
    return 'Failed to unhide projects: $error';
  }

  @override
  String hideProjectMessage(String projectName) {
    return 'Are you sure you want to hide \"$projectName\"?';
  }

  @override
  String releaseCreated(String title) {
    return 'Release \"$title\" created successfully.';
  }

  @override
  String failedToCreateRelease(String error) {
    return 'Failed to create release: $error';
  }

  @override
  String errorAddingFolder(String error) {
    return 'Error adding folder: $error';
  }

  @override
  String get noProjectsFoundInRoots =>
      'No projects found in selected project folders.';

  @override
  String get selectProjectsFolder => 'Select a projects folder';

  @override
  String get enterReleaseTitle => 'Enter Release Title';

  @override
  String get releaseTitle => 'Release Title';

  @override
  String get enterReleaseTitleHint => 'Enter release title';

  @override
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  ) {
    return 'Extracted metadata for $count project$plural. $failures';
  }

  @override
  String extractionFailures(int count, Object plural) {
    return '$count failed.';
  }

  @override
  String failedToWriteBpmFile(String error) {
    return 'Failed to write BPM file: $error';
  }

  @override
  String failedToWriteKeyFile(String error) {
    return 'Failed to write key file: $error';
  }

  @override
  String failedToLaunch(String error) {
    return 'Failed to launch: $error';
  }

  @override
  String get libraryCleared => 'Library cleared.';

  @override
  String scanType(String type) {
    return '$type scan';
  }

  @override
  String scanComplete(String type, int count, String plural) {
    return '$type complete: $count project$plural added/updated.';
  }

  @override
  String projectsSelected(int count, String plural) {
    return '$count project$plural selected';
  }

  @override
  String openingFolder(String projectName) {
    return 'Opening folder for $projectName…';
  }

  @override
  String failedToOpenFolder(String error) {
    return 'Failed to open folder: $error';
  }

  @override
  String get osNotSupportedForOpeningFolder =>
      'OS not supported for opening folder.';

  @override
  String get noProjectsAvailable =>
      'No projects available. Please add projects first.';

  @override
  String get createNewRelease => 'Create New Release';

  @override
  String get deleteRelease => 'Delete Release';

  @override
  String deleteReleaseMessage(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String releaseDeleted(String title) {
    return 'Release \"$title\" deleted.';
  }

  @override
  String get selectTracks => 'Select Tracks';

  @override
  String get continueButton => 'Continue';

  @override
  String get noReleasesYet => 'No releases yet';

  @override
  String get createFirstRelease =>
      'Create your first release by selecting tracks from your projects';

  @override
  String releasesCount(int count) {
    return 'Releases ($count)';
  }

  @override
  String errorLoadingReleases(String error) {
    return 'Error loading releases: $error';
  }

  @override
  String tracksCount(int count) {
    return 'Tracks ($count)';
  }

  @override
  String get addTracks => 'Add Tracks';

  @override
  String get allProjectsAlreadyInRelease =>
      'All projects are already in this release.';

  @override
  String addedTracksToRelease(int count, String plural) {
    return 'Added $count track$plural to release.';
  }

  @override
  String releaseFilesCount(int count) {
    return 'Release Files ($count)';
  }

  @override
  String get addFiles => 'Add Files';

  @override
  String addedFilesToRelease(int count, String plural) {
    return 'Added $count file$plural to release.';
  }

  @override
  String failedToAddFiles(String error) {
    return 'Failed to add files: $error';
  }

  @override
  String get noFilesToDownload => 'No files to download.';

  @override
  String zipFileSaved(String path) {
    return 'ZIP file saved to: $path';
  }

  @override
  String get creatingZipFile => 'Creating ZIP file...';

  @override
  String failedToCreateZip(String error) {
    return 'Failed to create ZIP: $error';
  }

  @override
  String get selectedFileDoesNotExist => 'Selected file does not exist.';

  @override
  String get imageSavedSuccessfully => 'Image saved successfully!';

  @override
  String failedToSaveImage(String error) {
    return 'Failed to save image: $error';
  }

  @override
  String errorLoadingRelease(String error) {
    return 'Error loading release: $error';
  }

  @override
  String get errorLoadingProjects => 'Error loading projects';

  @override
  String get releaseSaved => 'Release saved.';

  @override
  String get releaseDate => 'Release Date';

  @override
  String failedToSaveReleaseDate(String error) {
    return 'Failed to save release date: $error';
  }

  @override
  String get releaseDateSaved => 'Release date saved.';

  @override
  String get releaseDateCleared => 'Release date cleared.';

  @override
  String get saveReleaseFilesZip => 'Save release files ZIP';

  @override
  String get failedToOpenFile => 'Failed to open file';

  @override
  String failedToPlayAudio(String error) {
    return 'Failed to play audio: $error';
  }

  @override
  String get renameFile => 'Rename File';

  @override
  String get selectTracksToAdd => 'Select Tracks to Add';

  @override
  String get fileNameUpdated => 'File name updated.';

  @override
  String errorUpdatingFileName(String error) {
    return 'Error updating file name: $error';
  }

  @override
  String get deleteFile => 'Delete File';

  @override
  String deleteFileMessage(String fileName) {
    return 'Are you sure you want to delete \"$fileName\"?';
  }

  @override
  String fileDeleted(String fileName) {
    return 'File \"$fileName\" deleted.';
  }

  @override
  String failedToDeleteFile(String error) {
    return 'Failed to delete file: $error';
  }

  @override
  String couldNotOpenFolder(String error) {
    return 'Could not open folder: $error';
  }

  @override
  String get artwork => 'Artwork';

  @override
  String get title => 'Title';

  @override
  String get tracks => 'Tracks';

  @override
  String get description => 'Description';

  @override
  String selectTracksToInclude(int count, Object plural) {
    return 'Select tracks to include in the release ($count selected)';
  }

  @override
  String get searchTracks => 'Search tracks';

  @override
  String get searchTracksHint => 'Search by name or DAW type';

  @override
  String get noTracksFound => 'No tracks found';

  @override
  String get unknown => 'Unknown';

  @override
  String get fileNotFound => 'File not found';

  @override
  String get fileName => 'File Name';

  @override
  String get editTodo => 'Edit Todo';

  @override
  String get todoText => 'Todo text';

  @override
  String get enterTodoText => 'Enter todo text';

  @override
  String get addNewTodo => 'Add new todo';

  @override
  String get enterTodoItem => 'Enter todo item';

  @override
  String get todoList => 'TODO List';

  @override
  String get todoTemplates => 'TODO Templates';

  @override
  String get createTemplate => 'Create Template';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Are you sure you want to delete template \"$name\"?';
  }

  @override
  String get templateName => 'Template Name';

  @override
  String get templateNameHint => 'e.g., Mixing Checklist';

  @override
  String get templateItems => 'Template Items';

  @override
  String get templateItemsHint => 'One item per line';

  @override
  String get templateNameAndItemsRequired =>
      'Template name and items are required';

  @override
  String get templateItemsRequired => 'At least one item is required';

  @override
  String get templateCreated => 'Template created';

  @override
  String get templateUpdated => 'Template updated';

  @override
  String get templateDeleted => 'Template deleted';

  @override
  String get noTemplatesYet => 'No templates yet';

  @override
  String get createFirstTemplate => 'Create your first TODO template';

  @override
  String templateItemCount(int count) {
    return '$count item(s)';
  }

  @override
  String get selectTemplate => 'Select Template';

  @override
  String get importFromTemplate => 'Import from Template';

  @override
  String get manageTemplates => 'Manage Templates';

  @override
  String get noTemplatesAvailable =>
      'No templates available. Create one first.';

  @override
  String templateImported(String name, int count) {
    return 'Template \"$name\" imported ($count items)';
  }

  @override
  String get errorLoadingTemplates => 'Error loading templates';

  @override
  String get importTodos => 'Import Todos from File';

  @override
  String get noTodosInFile => 'No todos found in file';

  @override
  String todosImported(int count) {
    return '$count todo(s) imported successfully';
  }

  @override
  String errorImportingTodos(String error) {
    return 'Error importing todos: $error';
  }

  @override
  String get addToRelease => 'Add to Release';

  @override
  String get createNew => 'Create New';

  @override
  String get addToExisting => 'Add to Existing';

  @override
  String get createAndAdd => 'Create and Add';

  @override
  String get selectRelease => 'Select a release';

  @override
  String get noExistingReleasesFound => 'No existing releases found.';

  @override
  String get addToSelectedRelease => 'Add to Selected Release';

  @override
  String failedToSaveProfilePhoto(String error) {
    return 'Failed to save profile photo: $error';
  }

  @override
  String failedToRemoveProfilePhoto(String error) {
    return 'Failed to remove profile photo: $error';
  }

  @override
  String failedToRenameProfile(String error) {
    return 'Failed to rename profile: $error';
  }

  @override
  String failedToDeleteProfile(String error) {
    return 'Failed to delete profile: $error';
  }

  @override
  String errorLoadingProfiles(String error) {
    return 'Error loading profiles: $error';
  }

  @override
  String get projectPhaseIdea => 'Idea';

  @override
  String get projectPhaseArranging => 'Arranging';

  @override
  String get projectPhaseMixing => 'Mixing';

  @override
  String get projectPhaseMastering => 'Mastering';

  @override
  String get projectPhaseFinished => 'Finished';

  @override
  String get changeStatus => 'Change Phase';

  @override
  String get selectNewStatus => 'Select new phase:';

  @override
  String statusChangedForProjects(int count, String plural, String status) {
    return 'Phase changed to \"$status\" for $count project$plural';
  }

  @override
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  ) {
    return 'Phase changed to \"$status\" for $successCount project$successPlural, $failCount failed$failPlural';
  }

  @override
  String failedToChangeStatus(String error) {
    return 'Failed to change phase: $error';
  }

  @override
  String get tooltipEditProfileName => 'Edit profile name';

  @override
  String get tooltipAddTodo => 'Add todo';

  @override
  String get tooltipClearDate => 'Clear date';

  @override
  String get tooltipPickDate => 'Pick date';

  @override
  String get tooltipViewDetails => 'View Details';

  @override
  String get tooltipLaunchInDaw => 'Launch in DAW';

  @override
  String get tooltipRemoveFromRelease => 'Remove from Release';

  @override
  String get profile => 'Profile';

  @override
  String get noDateSet => 'No date set';

  @override
  String get imageNotFound => 'Image not found';

  @override
  String get clickToBrowseArtwork => 'Click to browse artwork';

  @override
  String get noFilesAddedYet =>
      'No files added yet.\nClick \"Add Files\" to upload release files.';

  @override
  String get noTodosYet => 'No todos yet. Add one above.';

  @override
  String get done => 'Done';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get backupExportedSuccessfully => 'Backup exported successfully';

  @override
  String failedToExportBackup(String error) {
    return 'Failed to export backup: $error';
  }

  @override
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup imported successfully: $projectsCount projects, $rootsCount project folders, $releasesCount releases';
  }

  @override
  String failedToImportBackup(String error) {
    return 'Failed to import backup: $error';
  }

  @override
  String get importBackupMessage => 'Choose how to import the backup:';

  @override
  String get mergeWithCurrentProfile => 'Merge with current active profile';

  @override
  String get replaceCurrentProfile =>
      'Replace entirely the current profile (WARNING: This will delete all current profile data)';

  @override
  String get createNewProfileForImport => 'Create a new profile for this data';

  @override
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  ) {
    return 'Backup imported to new profile \"$profileName\": $projectsCount projects, $rootsCount project folders, $releasesCount releases';
  }

  @override
  String get noProfileSelected => 'No profile selected';

  @override
  String get exportBackupDialogTitle => 'Export Backup';

  @override
  String get importBackupDialogTitle => 'Import Backup';

  @override
  String get invalidBackupFileFormat =>
      'Invalid backup file format: missing version';

  @override
  String get profileNameRequiredForNewProfile =>
      'Profile name is required when creating a new profile';

  @override
  String get currentProfileRequired =>
      'Current profile is required for merge or replace mode';

  @override
  String get previewSong => 'Preview Song';

  @override
  String get noPreviewSongTitle => 'No Preview Song';

  @override
  String get noPreviewSongMessage =>
      'This project has no preview song set. Select an audio file to load and play it.';

  @override
  String get noPreviewSongDragHint =>
      'You can also drag and drop an audio file directly onto the project row in the table.';

  @override
  String get previewSongRemoved => 'Preview song removed';

  @override
  String get previewSongAdded => 'Preview song added';

  @override
  String get previewSongFileNotFound => 'Preview song file not found';

  @override
  String get previewSongFileNotFoundMessage =>
      'The preview song file could not be found on disk. Would you like to select a new file or remove the entry?';

  @override
  String get selectNewFile => 'Select New File';

  @override
  String failedToPlayPreview(String error) {
    return 'Failed to play preview: $error';
  }

  @override
  String get removePreviewSong => 'Remove preview song';

  @override
  String get removePreviewSongConfirm =>
      'Are you sure you want to remove the preview song? This action cannot be undone.';

  @override
  String get noPreviewSongSelected => 'No preview song selected';

  @override
  String get changePreviewSong => 'Change Preview Song';

  @override
  String get selectPreviewSong => 'Select Preview Song';

  @override
  String get dropAudioFileHere => 'Drop audio file here';

  @override
  String projectAge(String age) {
    return 'Project age: $age';
  }

  @override
  String createdDate(String date) {
    return 'created $date';
  }

  @override
  String completedIn(String duration) {
    return 'Completed in: $duration';
  }

  @override
  String finishedDate(String date) {
    return 'finished $date';
  }

  @override
  String get dateToday => 'today';

  @override
  String get dateYesterday => 'yesterday';

  @override
  String dateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String dateWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String dateMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String dateYearsAgo(int count, Object plural) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
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
    return '$years year$yearPlural, $months month$monthPlural';
  }

  @override
  String ageYears(int years, String plural) {
    return '$years year$plural';
  }

  @override
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  ) {
    return '$months month$monthPlural, $days day$dayPlural';
  }

  @override
  String ageMonths(int months, String plural) {
    return '$months month$plural';
  }

  @override
  String ageDays(int days, String plural) {
    return '$days day$plural';
  }

  @override
  String ageHours(int hours, String plural) {
    return '$hours hour$plural';
  }

  @override
  String get ageJustNow => 'Just now';

  @override
  String get ageLessThanHour => 'Less than an hour';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get googleDriveSync => 'Google Drive Sync';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get googleDriveSyncDescription =>
      'Sync your data with Google Drive to backup and restore across devices.';

  @override
  String get manageGoogleDriveSync => 'Manage Google Drive Sync';

  @override
  String get signInToGoogleDrive => 'Sign in to Google Drive';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get uploadBackup => 'Upload Backup';

  @override
  String get downloadBackup => 'Download Backup';

  @override
  String get newerBackupAvailable => 'New backup available on cloud';

  @override
  String get signOut => 'Sign Out';

  @override
  String get downloadPreviewSongs => 'Download preview songs';

  @override
  String get downloadPreviewSongsExplanation =>
      'If unchecked, preview songs will be skipped (saves time and storage). You can download them later if needed.';

  @override
  String get replaceLocalData => 'Replace Local Data';

  @override
  String get downloadBackupConfirmation =>
      'This will replace your local data with the backup from Google Drive.\n\nAre you sure you want to continue?';

  @override
  String get enterAuthorizationCode => 'Enter Authorization Code';

  @override
  String get authorizationCode => 'Authorization Code';

  @override
  String get pasteCodeFromBrowser => 'Paste the code from the browser';

  @override
  String get sessionActive => 'Session active';

  @override
  String get signedIn => 'Signed in';

  @override
  String get creatingInitialBackup => 'Creating initial backup...';

  @override
  String get successfullySignedInAndBackedUp =>
      'Successfully signed in and backed up to Google Drive';

  @override
  String get successfullySignedInAndBackedUpMessage =>
      'Successfully signed in and backed up to Google Drive!';

  @override
  String get successfullySignedInToGoogleDrive =>
      'Successfully signed in to Google Drive';

  @override
  String get successfullySignedInToGoogleDriveMessage =>
      'Successfully signed in to Google Drive!';

  @override
  String get signInCancelledOrFailed =>
      'Sign in cancelled or failed. Check console for details.';

  @override
  String get failedToLaunchBrowser => 'Failed to launch browser';

  @override
  String get signInCancelled => 'Sign in cancelled';

  @override
  String get failedToExchangeAuthorizationCode =>
      'Failed to exchange authorization code';

  @override
  String errorSigningIn(String error) {
    return 'Error signing in: $error';
  }

  @override
  String get unknownError => 'Unknown error';

  @override
  String get googleSignInError => 'Google Sign-In Error';

  @override
  String get developerConsoleNotSetUp =>
      'Developer console is not set up correctly. Please check your OAuth configuration in Google Cloud Console.';

  @override
  String get platformError => 'Platform Error';

  @override
  String get signedOutFromGoogleDrive => 'Signed out from Google Drive';

  @override
  String errorSigningOut(String error) {
    return 'Error signing out: $error';
  }

  @override
  String get syncing => 'Syncing...';

  @override
  String get errorNoProfileSelected => 'Error: No profile selected';

  @override
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Sync completed! Projects: +$projectsAdded ~$projectsUpdated, Releases: +$releasesAdded ~$releasesUpdated';
  }

  @override
  String errorSyncing(String error) {
    return 'Error syncing: $error';
  }

  @override
  String get uploadingBackup => 'Uploading backup...';

  @override
  String get backupUploadedSuccessfully => 'Backup uploaded successfully!';

  @override
  String get backupUploadedSuccessfullyMessage =>
      'Backup uploaded successfully to Google Drive!';

  @override
  String errorUploadingBackup(String error) {
    return 'Error uploading backup: $error';
  }

  @override
  String get downloadingBackup => 'Downloading backup...';

  @override
  String get checkingForBackup => 'Checking for backup...';

  @override
  String get backupUpToDate => 'Backup is up to date';

  @override
  String errorCheckingBackup(String error) {
    return 'Error checking backup: $error';
  }

  @override
  String get download => 'Download';

  @override
  String get remoteBackupIsNewer =>
      'Remote backup is newer than local data. Uploading will overwrite it.';

  @override
  String get confirmUpload => 'Confirm Upload';

  @override
  String get noBackupFileFound =>
      'No backup file found in Google Drive. Create a backup first by syncing your data.';

  @override
  String get noBackupFileFoundStatus =>
      'No backup file found. Create a backup first.';

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  ) {
    return 'Backup downloaded! Projects: +$projectsAdded ~$projectsUpdated, Releases: +$releasesAdded ~$releasesUpdated';
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
    return 'Backup downloaded!\n\nProjects:\n  • $projectsAdded added\n  • $projectsUpdated updated\n\nReleases:\n  • $releasesAdded added\n  • $releasesUpdated updated\n\nPreview Songs:\n  • $previewSongsDownloaded downloaded\n  • $previewSongsUpdated updated';
  }

  @override
  String errorDownloadingBackup(String error) {
    return 'Error downloading backup: $error';
  }

  @override
  String signedInAs(String email) {
    return 'Signed in as: $email';
  }

  @override
  String lastSync(String date) {
    return 'Last sync: $date';
  }

  @override
  String remoteBackupTime(String date) {
    return 'Remote backup: $date';
  }

  @override
  String lastUploadTime(String date) {
    return 'Last upload: $date';
  }

  @override
  String lastDownloadTime(String date) {
    return 'Last download: $date';
  }

  @override
  String get checkForBackup => 'Check for Backup';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notificationsOnlyOnAndroid =>
      'Deadline notifications are only available on Android devices.';

  @override
  String get notificationPermissionRequired =>
      'Notification Permission Required';

  @override
  String get notificationPermissionDescription =>
      'Please enable notifications to receive deadline reminders.';

  @override
  String get notificationPermissionDenied =>
      'Notification permission denied. Please enable it in settings.';

  @override
  String get notificationSettingsSaved =>
      'Notification settings saved successfully';

  @override
  String get errorSavingSettings => 'Error saving settings';

  @override
  String get enableDeadlineNotifications => 'Enable Deadline Notifications';

  @override
  String get receiveRemindersForDeadlines =>
      'Receive reminders for project deadlines';

  @override
  String get notificationTime => 'Notification Time';

  @override
  String get timeToReceiveNotifications =>
      'Time of day to receive notifications';

  @override
  String get reminderDays => 'Reminder Days';

  @override
  String get selectDaysBeforeDeadline =>
      'Select how many days before the deadline you want to be notified';

  @override
  String get notifyOnDeadlineDay => 'Notify on Deadline Day';

  @override
  String get receiveNotificationOnDeadlineDay =>
      'Also receive a notification on the deadline day itself';

  @override
  String get howItWorks => 'How It Works';

  @override
  String get deadlineNotificationsHelp =>
      'You will receive notifications at the specified time on the selected days before each project deadline. Tap a notification to open the project details.';

  @override
  String get oneDay => '1 day';

  @override
  String xDays(int count) {
    return '$count days';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get support => 'Support';

  @override
  String get supportTheProject => 'Support the project';

  @override
  String couldNotOpenBrowser(String url) {
    return 'Could not open browser. Please visit: $url';
  }

  @override
  String errorOpeningBrowser(String error) {
    return 'Error opening browser: $error';
  }

  @override
  String get generateTestingDatabase => 'Generate Testing Database';

  @override
  String get generateTestingDatabaseMessage =>
      'This will populate the database with sample projects and releases for testing. Continue?';

  @override
  String get testingDatabaseGenerated =>
      'Testing database generated successfully!';

  @override
  String failedToGenerateTestingDatabase(String error) {
    return 'Failed to generate testing database: $error';
  }

  @override
  String get playlists => 'Playlists';

  @override
  String get playlistsDesktopOnly => 'Playlists are only available on Android.';

  @override
  String get noPlaylistsYet => 'No playlists yet';

  @override
  String get createFirstPlaylist =>
      'Tap the + button to create your first playlist';

  @override
  String playlistSongCount(int count) {
    return '$count songs';
  }

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get playlistName => 'Playlist Name';

  @override
  String get playlistNameHint => 'My Playlist';

  @override
  String get playlistNameRequired => 'Playlist name is required';

  @override
  String get editPlaylist => 'Edit Playlist';

  @override
  String get stopPlaybackBeforeEditing =>
      'Please stop playback before editing the playlist';

  @override
  String get selectPreviewSongs => 'Select Preview Songs';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get playlistDeleted => 'Playlist deleted';

  @override
  String get errorDeletingPlaylist => 'Error deleting playlist';

  @override
  String get playlistUpdated => 'Playlist updated';

  @override
  String get changeSong => 'Change Song';

  @override
  String get changeSongConfirm =>
      'A song is currently playing. Do you want to switch to this song?';

  @override
  String get changeSongButton => 'Change';

  @override
  String playlistProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get noPreviewSongsInPlaylist =>
      'No preview songs available in this playlist';

  @override
  String get tapEditToAddSongs => 'Tap edit to add songs to this playlist';

  @override
  String get noProjectsAvailableForPlaylist =>
      'No projects with preview songs available to add';

  @override
  String get noProjectsInDatabase =>
      'No projects found in database. Please sync your projects first.';

  @override
  String get firstTimeSyncTitle => 'It seems it\'s your first time here!';

  @override
  String get firstTimeSyncMessage =>
      'Let\'s sync your data from Google Drive to get started';

  @override
  String get syncWithGoogleDrive => 'Sync with Google Drive';

  @override
  String get errorLoadingPlaylists => 'Error loading playlists';

  @override
  String get playlistItems => 'Playlist Items';

  @override
  String get addSongs => 'Add Songs';

  @override
  String get addAudioFiles => 'Add Audio Files';

  @override
  String get selectAudioFiles => 'Select Audio Files';

  @override
  String get selectFromProjects => 'Select from Projects';

  @override
  String get add => 'Add';

  @override
  String get fromProject => 'From Project';

  @override
  String get projectDeadline => 'Project Deadline';

  @override
  String get noDeadlineSet => 'No deadline set';

  @override
  String get camelotCode => 'Camelot Code';

  @override
  String get deadline => 'Deadline';

  @override
  String get dueToday => 'Due today';

  @override
  String daysLate(int days) {
    return '${days}d late';
  }

  @override
  String daysLeft(int days) {
    return '${days}d left';
  }

  @override
  String get hideFinished => 'Hide Finished';

  @override
  String get showOnlyDeadlines => 'Show Deadline';

  @override
  String get filterByDeadline => 'Filter by Deadline';

  @override
  String get allDeadlines => 'All Deadlines';

  @override
  String get hasDeadline => 'Has Deadline';

  @override
  String get overdue => 'Overdue';

  @override
  String get dueSoon => 'Due Soon (7d)';

  @override
  String get today => 'Today';

  @override
  String get noPreviewSong => 'No preview song';

  @override
  String get playPreview => 'Play Preview';

  @override
  String get uploadCancelled => 'Upload cancelled';

  @override
  String get backupUploadCancelledByUser => 'Backup upload cancelled by user';

  @override
  String get collectingData => 'Collecting data...';

  @override
  String get uploadingPreviewSongs => 'Uploading preview songs...';

  @override
  String get uploadingProfilePhotos => 'Uploading profile photos...';

  @override
  String get uploadingReleaseArtwork => 'Uploading release artwork...';

  @override
  String get uploadingDatabase => 'Uploading database...';

  @override
  String get completed => 'Completed!';

  @override
  String get cancelling => 'Cancelling...';

  @override
  String get uploadingBackupTitle => 'Uploading Backup';

  @override
  String get cancellingUpload => 'Cancelling upload...';

  @override
  String get pleaseWaitCancellingUpload =>
      'Please wait while we stop the upload...';

  @override
  String get downloadingDatabase => 'Downloading database...';

  @override
  String get downloadingPreviewSongs => 'Downloading preview songs...';

  @override
  String get downloadingProfilePhotos => 'Downloading profile photos...';

  @override
  String get downloadingReleaseArtwork => 'Downloading release artwork...';

  @override
  String get mergingData => 'Merging data...';

  @override
  String get downloadingBackupTitle => 'Downloading Backup';

  @override
  String get sourceFileNotFoundOnThisMachine =>
      'Source file not found on this machine';

  @override
  String get sourceFileNotFoundMetadataOnly =>
      'Source file not found on this machine — metadata-only mode. You can still edit and export metadata.';

  @override
  String get previewSongNotAvailableDownloadFirst =>
      'Preview song not available. Please download backup first.';

  @override
  String get sharePreviewSong => 'Share preview song';

  @override
  String get shareAsZip => 'Share as ZIP';

  @override
  String get share => 'Share';

  @override
  String get shareZip => 'Share ZIP';

  @override
  String get saveCopy => 'Save a copy';

  @override
  String savedCopyTo(String path) {
    return 'Saved to $path';
  }

  @override
  String failedToSharePreviewSong(String error) {
    return 'Failed to share preview song: $error';
  }

  @override
  String failedToSharePreviewSongAsZip(String error) {
    return 'Failed to share preview song as ZIP: $error';
  }

  @override
  String get biographySaved => 'Biography saved';

  @override
  String failedToSaveBiography(String error) {
    return 'Failed to save biography: $error';
  }

  @override
  String fileSavedTo(String filename) {
    return 'File saved to $filename';
  }

  @override
  String failedToDownloadFile(String error) {
    return 'Failed to download file: $error';
  }

  @override
  String allFilesSavedTo(String filename) {
    return 'All files saved to $filename';
  }

  @override
  String get artworkAdded => 'Artwork added';

  @override
  String failedToAddArtwork(String error) {
    return 'Failed to add artwork: $error';
  }

  @override
  String get artworkRemoved => 'Artwork removed';

  @override
  String failedToRemoveArtwork(String error) {
    return 'Failed to remove artwork: $error';
  }

  @override
  String get pressKitFileAdded => 'Press kit file added';

  @override
  String failedToAddPressKitFile(String error) {
    return 'Failed to add press kit file: $error';
  }

  @override
  String get pressKitFileRemoved => 'Press kit file removed';

  @override
  String failedToRemovePressKitFile(String error) {
    return 'Failed to remove press kit file: $error';
  }

  @override
  String get selectFilesToDownload => 'Select Files to Download';

  @override
  String get biography => 'Biography';

  @override
  String get biographyWillBeSaved => 'Will be saved as biography.txt';

  @override
  String get artworkFiles => 'Artwork Files';

  @override
  String get pressKitFiles => 'Press Kit Files';

  @override
  String get additionalAssets => 'Additional Assets';

  @override
  String downloadNFiles(int count, String plural) {
    return 'Download $count file$plural';
  }

  @override
  String nFilesSavedTo(int count, String plural, String filename) {
    return '$count file$plural saved to $filename';
  }

  @override
  String get addAsset => 'Add Asset';

  @override
  String get assetNameLabel => 'Asset Name';

  @override
  String get assetNameHint => 'e.g., Logo, Banner, Photo';

  @override
  String assetAddedSuccessfully(String assetName) {
    return '$assetName added successfully';
  }

  @override
  String failedToAddAsset(String error) {
    return 'Failed to add asset: $error';
  }

  @override
  String assetRemoved(String assetName) {
    return '$assetName removed';
  }

  @override
  String failedToRemoveAsset(String error) {
    return 'Failed to remove asset: $error';
  }

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get selectFiles => 'Select Files';

  @override
  String get downloadAll => 'Download All';

  @override
  String get saveBiographyTooltip => 'Save Biography';

  @override
  String get enterBiographyHint => 'Enter profile biography...';

  @override
  String get addArtwork => 'Add Artwork';

  @override
  String get addFile => 'Add File';

  @override
  String get openFile => 'Open File';

  @override
  String get menuView => 'View';

  @override
  String get menuAbout => 'About DAW Project Manager';

  @override
  String get menuDocumentation => 'Documentation';

  @override
  String get menuLanguage => 'Language';

  @override
  String get menuWarnBeforeQuit => 'Warn Before Quitting (Cmd+Q)';

  @override
  String get menuQuit => 'Quit DAW Project Manager';

  @override
  String get menuWindow => 'Window';

  @override
  String get donate => 'Donate';

  @override
  String get website => 'Website';

  @override
  String get switchToClassicDark => 'Switch to Classic Dark';

  @override
  String get switchToNeonDark => 'Switch to Neon Dark';

  @override
  String get switchToClassicTheme => 'Switch to Classic Theme';

  @override
  String get switchToNeonTheme => 'Switch to Neon Theme';

  @override
  String get menuTheme => 'Theme';

  @override
  String get appDescription =>
      'A project manager for music producers and sound designers.';

  @override
  String get neonDarkThemeName => 'Neon Dark';

  @override
  String get classicDarkThemeName => 'Classic Dark';

  @override
  String get statisticsTab => 'Statistics';

  @override
  String get statsTotalProjects => 'Total Projects';

  @override
  String get statsInProgress => 'In Progress';

  @override
  String get statsFinished => 'Finished';

  @override
  String get statsAvgCompletion => 'Avg. Completion';

  @override
  String get statsPhaseDistribution => 'Projects by Phase';

  @override
  String get statsAvgTimePerPhase => 'Avg. Days per Phase';

  @override
  String get statsProductivity => 'Productivity';

  @override
  String get statsCreatedSeries => 'Created';

  @override
  String get statsProjectHealth => 'Project Age & Health';

  @override
  String get statsCatalogInsights => 'Catalog Insights';

  @override
  String get statsBpmDistribution => 'BPM Distribution';

  @override
  String get statsTopKeys => 'Top Musical Keys';

  @override
  String get statsDawTypes => 'DAW Types';

  @override
  String get statsProjectActivity => 'Project Activity';

  @override
  String get statsNoData => 'No data yet';

  @override
  String get statsNoPhaseData =>
      'Phase data will appear after projects move between phases.';

  @override
  String statsLastActivityDaysAgo(int days) {
    return 'Last activity: $days days ago';
  }

  @override
  String get statsLastActivityToday => 'Active today';

  @override
  String get statsNoEvents => 'No events recorded yet';

  @override
  String statsEventPhaseChanged(String from, String to) {
    return 'Phase: $from → $to';
  }

  @override
  String statsEventMetadataUpdated(String fields) {
    return 'Updated: $fields';
  }

  @override
  String statsEventTodoCompleted(String text) {
    return 'Completed: $text';
  }

  @override
  String get statsEventFileModified => 'File modified on disk';

  @override
  String get statsClearHistory => 'Clear history';

  @override
  String get statsClearHistoryConfirm =>
      'Clear all recorded events for this project?';

  @override
  String get statsSearchProjects => 'Search projects…';

  @override
  String statsEventCount(int count) {
    return '$count events';
  }

  @override
  String get statsViewHistory => 'Project Statistics';

  @override
  String get statsPhaseHistory => 'Phase History';

  @override
  String get statsEventBreakdown => 'Event Breakdown';

  @override
  String statsDaysSoFar(int days) {
    return '${days}d so far';
  }

  @override
  String get statsNoProjectsFound => 'No projects found';

  @override
  String statsNotTouchedDays(int days) {
    return 'Not touched in $days days';
  }

  @override
  String get sortByLastModified => 'Last modified';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByPhase => 'Phase';

  @override
  String get sortByCreatedAt => 'Date added';

  @override
  String get sortByBpm => 'BPM';

  @override
  String get monoLabel => 'Mono';

  @override
  String get monoToggleTooltip => 'Toggle mono playback';

  @override
  String get monoRequiresWav => 'Mono mixing requires a WAV file';

  @override
  String get monoUnsupportedFormat =>
      'Could not create mono mix — unsupported format';

  @override
  String monoSwitchFailed(String error) {
    return 'Mono switch failed: $error';
  }

  @override
  String get analyzeLabel => 'Analyze';

  @override
  String get reAnalyzeLabel => 'Re-analyze';

  @override
  String get analysisRequiresWav => 'Analysis requires a WAV file';

  @override
  String get noResultsForFilter => 'No results for current filter';

  @override
  String get noResultsForFilterHint =>
      'Try adjusting your search or filters to find projects.';

  @override
  String get noProjectsFound => 'No projects found';

  @override
  String get noProjectsFoundHint =>
      'Add a scan root folder in settings to get started.';

  @override
  String get queueTab => 'Tasks';

  @override
  String get queueSearchHint => 'Search tasks...';

  @override
  String get queueNoPendingTasks => 'All caught up!';

  @override
  String get queueNoPendingTasksHint =>
      'No pending tasks across your projects.';

  @override
  String get queueNoMatchingTasks => 'No matching tasks';

  @override
  String queuePendingSummary(int tasks, int projects) {
    return '$tasks pending tasks in $projects projects';
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
  String get renameProjectFileTitle => 'Rename Project File';

  @override
  String get renameFileButtonLabel => 'Rename File';

  @override
  String get newFileNameLabel => 'New file name (without extension)';

  @override
  String renameAlreadyExists(String name) {
    return 'A file named \"$name\" already exists.';
  }

  @override
  String renameSuccess(String name) {
    return 'Renamed to \"$name\"';
  }

  @override
  String renameFailed(String error) {
    return 'Failed to rename: $error';
  }

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get nameInvalidCharacters => 'Name cannot contain / \\ :';

  @override
  String get alsoRenameContainingFolder => 'Also rename containing folder';

  @override
  String get renameButton => 'Rename';

  @override
  String get previewMixdownFolderTitle => 'Preview Mixdown Folder';

  @override
  String get previewMixdownFolderSubtitle =>
      'Subfolder name inside each project folder to check first when auto-detecting preview songs. Leave empty to use DAW defaults.';

  @override
  String get previewMixdownFolderHint => 'e.g. Mixdowns';

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
    return 'Key: $key';
  }

  @override
  String get audioFileNotFound => 'Audio file not found';

  @override
  String errorPlayingAudio(String error) {
    return 'Error playing audio: $error';
  }

  @override
  String get notificationTestTitle =>
      'Test notifications to verify timezone and scheduling:';

  @override
  String get notificationSendNow => 'Send Now';

  @override
  String get notificationSchedule30s => 'Schedule +30s';

  @override
  String get notificationShowDebugInfo => 'Show Debug Info';

  @override
  String get notificationRescheduleAll => 'Re-schedule All';

  @override
  String get notificationTestSent => '✅ Test notification sent!';

  @override
  String get notificationTestScheduled =>
      '✅ Test notification scheduled for 30 seconds! Check console logs.';

  @override
  String notificationTestError(String error) {
    return '❌ Error: $error';
  }

  @override
  String get notificationDebugTitle => '🐛 Debug Information';

  @override
  String get autoDetected => 'Auto-detected';

  @override
  String get matchedInDescription => 'Matched in description';

  @override
  String get relocateFolderDialogTitle => 'Relocate Folder';

  @override
  String relocateFolderSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count project paths updated',
      one: '1 project path updated',
    );
    return '$_temp0';
  }

  @override
  String get customizeTabs => 'Customize Tabs';

  @override
  String get customizeTabsDescription =>
      'Choose which tabs to show in the navigation bar. The Projects tab is always visible.';

  @override
  String get keyboardShortcuts => 'Keyboard Shortcuts';

  @override
  String get shortcutGroupGlobal => 'Global';

  @override
  String get shortcutGroupProjectsTable =>
      'Projects Table (table must be focused)';

  @override
  String get shortcutGroupReleasesTable =>
      'Releases Table (table must be focused)';

  @override
  String get shortcutGroupNavigation => 'Navigation';

  @override
  String get shortcutFocusSearch => 'Focus search bar';

  @override
  String get shortcutRescan => 'Rescan project folders';

  @override
  String get shortcutFocusTable => 'Focus projects table';

  @override
  String get shortcutPlayPause => 'Play / pause preview song';

  @override
  String get shortcutOpenInDaw => 'Open project in DAW';

  @override
  String get shortcutViewDetails => 'View project details';

  @override
  String get shortcutOpenFolder => 'Open project folder';

  @override
  String get shortcutNavigateRows => 'Navigate rows';

  @override
  String get shortcutEditCell => 'Open project details';

  @override
  String get shortcutViewRelease => 'View release details';

  @override
  String get shortcutGoBack => 'Go back';

  @override
  String get shortcutGroupProjectsTableStandardMode => 'Standard mode';

  @override
  String get shortcutGroupProjectsTableSessionMode => 'Session mode';

  @override
  String get shortcutToggleSession => 'Start / End session';

  @override
  String get shortcutGroupPreviewPlayer => 'Preview Player';

  @override
  String get shortcutPlayerPlayPause => 'Play / pause';

  @override
  String get shortcutPlayerSeek5 => 'Seek ±5 seconds';

  @override
  String get shortcutPlayerSeek30 => 'Seek ±30 seconds';

  @override
  String get startupDialogTitle => 'Welcome to DAW Project Manager';

  @override
  String get startupDialogSubtitle =>
      'Get started by adding your project folder or restoring a backup from Google Drive.';

  @override
  String get startupAddFolderTitle => 'Add Project Folder';

  @override
  String get startupAddFolderSubtitle =>
      'Select a folder containing your DAW projects.';

  @override
  String get startupGoogleDriveTitle => 'Sync Google Drive Backup';

  @override
  String get startupGoogleDriveSubtitle =>
      'Restore your projects from a Google Drive backup.';

  @override
  String get startupDontShowAgain => 'Don\'t show this on startup';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteAllDataSubtitle =>
      'Remove all profiles, projects, releases, playlists, and settings from this device.';

  @override
  String get deleteAllDataConfirm1Title => 'Delete All Data?';

  @override
  String get deleteAllDataConfirm1Message =>
      'This will permanently erase all profiles, projects, releases, playlists, and settings from this device. Your Google Drive backup (if any) will not be affected.';

  @override
  String get deleteAllDataConfirm2Title => 'Are you absolutely sure?';

  @override
  String get deleteAllDataConfirm2Message =>
      'This action cannot be undone. The app will return to its initial state.';

  @override
  String get deleteEverything => 'Delete Everything';

  @override
  String get allDataDeleted => 'All data has been deleted.';

  @override
  String get newerExportFound => 'Newer Export Found';

  @override
  String newerExportFoundMessage(String filename) {
    return 'A newer file was found in the same folder:\n$filename\n\nReplace the preview song?';
  }

  @override
  String get replaceAndPlay => 'Replace & Play';

  @override
  String get keepCurrent => 'Keep Current';

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

  @override
  String get playerTitle => 'Music Player';

  @override
  String get playerToggleQueue => 'Toggle queue';

  @override
  String get playerSearchHint => 'Search tracks…';

  @override
  String playerTrackCount(int count) {
    return '$count tracks';
  }

  @override
  String playerTrackCountFiltered(int filtered, int total) {
    return '$filtered/$total';
  }

  @override
  String get playerNoPreviewSongs =>
      'No preview songs found.\nOpen a project and set a preview song.';

  @override
  String playerNoTracksMatch(String query) {
    return 'No tracks match\n\"$query\"';
  }

  @override
  String get playerDoubleClickToPlay => 'Double-click a track to start playing';

  @override
  String get playerSingleClickToPreview =>
      'Single-click to preview in the player bar below';

  @override
  String get playerQueueTitle => 'Queue';

  @override
  String get playerClearQueue => 'Clear queue';

  @override
  String get playerQueueEmptyHint =>
      'Double-click a track to start,\nor drag tracks here to queue.';

  @override
  String get playerPrev => 'Previous';

  @override
  String get playerNext => 'Next';

  @override
  String get playerGoToProject => 'Go to project';

  @override
  String get playerAddToQueue => 'Add to queue';

  @override
  String get playerRemoveFromQueue => 'Remove from queue';

  @override
  String get playerDismissDetail => 'Dismiss detail';

  @override
  String get playerNotes => 'NOTES';

  @override
  String get playerTasks => 'TASKS';

  @override
  String get playerNoTasks => 'No tasks yet.';

  @override
  String get playerAddTaskHint => 'Add a task…';

  @override
  String playerCompletedTasks(int count) {
    return '$count completed';
  }

  @override
  String get playerPreviousTrack => 'Previous track';

  @override
  String get playerNextTrack => 'Next track';

  @override
  String get playerOpenProject => 'Open project';

  @override
  String get volumeMute => 'Mute';

  @override
  String get volumeUnmute => 'Unmute';

  @override
  String totalWorkTime(String time) {
    return 'Total work: $time';
  }

  @override
  String sessionTime(String time) {
    return 'Session: $time';
  }

  @override
  String get sessionHistory => 'Session History';

  @override
  String get noSessionsYet => 'No sessions recorded yet';

  @override
  String get tabPosition => 'Tab position';

  @override
  String get tabPositionTop => 'Top';

  @override
  String get tabPositionLeft => 'Left';

  @override
  String updateAvailableMessage(String version) {
    return 'Version $version is available';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkForUpdatesDescription =>
      'Get notified when a new version of the app is available.';

  @override
  String get checkNow => 'Check now';

  @override
  String updateAvailable(String version) {
    return 'Update available: v$version';
  }

  @override
  String get upToDate => 'App is up to date';

  @override
  String get updateAvailableTitle => 'Update Available';

  @override
  String updateAvailableVersion(String version) {
    return 'A new version $version is ready.';
  }

  @override
  String updateCurrentVersion(String version) {
    return 'You are running v$version.';
  }

  @override
  String get viewUpdateDetails => 'View Details';

  @override
  String get getOnMicrosoftStore => 'Get on Microsoft Store';

  @override
  String get downloadFromGitHub => 'Download from GitHub';

  @override
  String get updateWindowsInstructions =>
      'Open the Microsoft Store and update DAW Project Manager, or click the button below.';

  @override
  String get updateMacInstructions =>
      'Download the latest release from GitHub and replace the current app.';

  @override
  String get resetOnboarding => 'Reset onboarding';

  @override
  String get onboardingWelcomeTitle => 'Welcome to DAW Project Manager';

  @override
  String get onboardingWelcomeBody =>
      'Organize all your music projects across every DAW in one place.';

  @override
  String get onboardingLanguageTitle => 'Choose Your Language';

  @override
  String get onboardingThemeTitle => 'Choose a Theme';

  @override
  String get onboardingFoldersTitle => 'Add Project Folders';

  @override
  String get onboardingFoldersBody =>
      'Add the root folder where your DAW projects are stored.';

  @override
  String get onboardingDriveTitle => 'Google Drive Sync';

  @override
  String get onboardingDriveBody =>
      'Optionally back up and sync project metadata to Google Drive.';

  @override
  String get onboardingUpdatesTitle => 'Update Checks';

  @override
  String get onboardingUpdatesBody =>
      'Get notified when a new version is available.';

  @override
  String get onboardingDoneTitle => 'You\'re All Set!';

  @override
  String get onboardingDoneBody => 'Start exploring your projects.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get dawSession => 'DAW Session';

  @override
  String get clearDawSession => 'Clear session';

  @override
  String get stop => 'Stop';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get workTimerSection => 'Work Session Reminders';

  @override
  String get workTimerSectionDesc =>
      'Get notified while working on a subscribed project';

  @override
  String get workTimerEnabled => 'Enable work session reminders';

  @override
  String get workTimerIntervalLabel => 'Notify every';

  @override
  String get minutes => 'minutes';

  @override
  String workTimerNotifBody(String time) {
    return 'You have been working for $time';
  }

  @override
  String get general => 'General';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get lastModifiedColors => 'Last Modified date colors';

  @override
  String get lastModifiedColorsDescription =>
      'Colors the Last Modified date based on age and status. Green = Finished. Older dates fade from yellow to red — stronger red means the project hasn\'t been touched in longer.';

  @override
  String get sessionMode => 'Session mode';

  @override
  String get sessionModeDescription =>
      'Subscribe to a project before launching, to track work time and manage it from the toolbar';

  @override
  String get startSession => 'Start Session';

  @override
  String get endSession => 'End session';

  @override
  String get switchSession => 'Switch session';

  @override
  String get switchSessionBody =>
      'Stop the current session and start a new one?';

  @override
  String switchSessionCurrent(String project) {
    return 'Current: $project';
  }

  @override
  String switchSessionNew(String project) {
    return 'New: $project';
  }

  @override
  String get sessionDuration => 'Session time';

  @override
  String get scanModeLabel => 'Scan mode:';

  @override
  String get scanModeSectionTitle => 'Scan Mode';

  @override
  String get scanModeSectionDescription =>
      'Controls how projects in each folder are displayed in the table — as a plain flat list or grouped by subfolder.';

  @override
  String get scanModeFlat => 'Flat';

  @override
  String get scanModeSmartFolder => 'Smart Folder';

  @override
  String get scanModeFlatDescription =>
      'Shows every project as a flat list. Simple and fast.';

  @override
  String get scanModeSmartFolderDescription =>
      'Groups projects by folder when a folder contains more than one project.';

  @override
  String get skip => 'Skip';

  @override
  String get suggestionsLabel => 'Suggestions';

  @override
  String get suggestionsRefresh => 'Refresh';

  @override
  String get suggestionsEmptyState =>
      'No suggestions right now. Tap Refresh to reset dismissed items.';

  @override
  String get showSuggestions => 'Show suggestions';

  @override
  String get showSuggestionsDescription =>
      'Show smart suggestions in the toolbar when no session is running';

  @override
  String get onboardingSuggestionsTitle => 'Smart Suggestions';

  @override
  String get onboardingSuggestionsBody =>
      'Get personalized project recommendations in the toolbar while you work';

  @override
  String get suggestionsFeatureDeadlines =>
      'Deadline reminders for upcoming projects';

  @override
  String get suggestionsFeatureResume =>
      'Resume the last project you worked on';

  @override
  String get suggestionsFeatureRecentlyModified =>
      'Continue recently modified tracks';

  @override
  String get suggestionsEnableToggle => 'Enable smart suggestions';

  @override
  String get canBeChangedInSettings => 'Can be changed later in Settings';

  @override
  String get next => 'Next';

  @override
  String get createProject => 'Create';

  @override
  String get createProjectTooltip => 'Create a new project folder';

  @override
  String get createProjectSelectFolder => 'Choose Location';

  @override
  String get createProjectSelectFolderHint =>
      'Select which project folder to create the new project in';

  @override
  String get createProjectNameTitle => 'Name Your Project';

  @override
  String get createProjectNameHint =>
      'Choose a naming scheme for the new project folder';

  @override
  String get createProjectSchemeArtistTrack => 'Artist — Track';

  @override
  String get createProjectSchemeCollab => 'Collab';

  @override
  String get createProjectSchemeDate => 'Date — Track';

  @override
  String get createProjectSchemeCustom => 'Custom';

  @override
  String get createProjectArtistName => 'Artist Name';

  @override
  String get createProjectTrackName => 'Track Name';

  @override
  String get createProjectCustomName => 'Folder Name';

  @override
  String get createProjectAddArtist => 'Add artist';

  @override
  String get createProjectSelectDaw => 'Open in DAW';

  @override
  String get createProjectSelectDawHint =>
      'Choose which DAW to open to start working on this project';

  @override
  String get createProjectDetectDaws => 'Detect Installed DAWs';

  @override
  String get createProjectSkipDaw => 'Just create the folder';

  @override
  String get createProjectNoDawsFound =>
      'No DAWs were found on this system. The folder will still be created.';

  @override
  String get createProjectCreateOnly => 'Create Folder';

  @override
  String get createProjectCreateAndOpen => 'Create & Open';

  @override
  String get createProjectFolderExists =>
      'A folder with this name already exists';

  @override
  String get createProjectInvalidChars =>
      'Folder name contains invalid characters';

  @override
  String get createProjectError => 'Failed to create folder';

  @override
  String get pendingProjectWaiting => 'Waiting for project file…';

  @override
  String get pendingProjectDelete => 'Delete empty folder';

  @override
  String get pendingProjectDeleteTitle => 'Delete Folder?';

  @override
  String pendingProjectDeleteBody(String folderName) {
    return 'Delete \"$folderName\" and its contents?';
  }

  @override
  String get pendingProjectDismiss => 'Stop tracking this folder';

  @override
  String get pendingProjectDeleteNotEmptyTitle => 'Folder is not empty';

  @override
  String pendingProjectDeleteNotEmptyBody(String folderName) {
    return '\"$folderName\" contains files. Delete everything permanently?';
  }

  @override
  String get pendingProjectRefresh => 'Check for project file';

  @override
  String get pendingProjectNotFound => 'No project file found yet';
}
