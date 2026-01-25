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
  String get cancel => 'Cancel';

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
  String get switchProfile => 'Switch';

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
  String get deepScanTooltip =>
      'Deep Scan extracts full metadata from project files:\n• BPM (Beats Per Minute)\n• Musical Key\n• DAW Version\nThis is slower but provides complete information.';

  @override
  String get deepScanConfirm =>
      'This will scan all projects and extract full metadata (BPM, Key, DAW Version). This may take a while. Continue?';

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
  String failedToOpenFile(String error) {
    return 'Failed to open file: $error';
  }

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
  String get previewSongRemoved => 'Preview song removed';

  @override
  String get previewSongAdded => 'Preview song added';

  @override
  String get previewSongFileNotFound => 'Preview song file not found';

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
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get support => 'Support';

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
}
