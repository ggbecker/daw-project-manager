import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'DAW Project Manager'**
  String get appTitle;

  /// No description provided for @projectDetails.
  ///
  /// In en, this message translates to:
  /// **'Project Details'**
  String get projectDetails;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @customInterval.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customInterval;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @launch.
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get launch;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @openInDaw.
  ///
  /// In en, this message translates to:
  /// **'Launch in DAW'**
  String get openInDaw;

  /// No description provided for @extract.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get extract;

  /// No description provided for @extracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting…'**
  String get extracting;

  /// No description provided for @extractingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Extracting metadata...'**
  String get extractingMetadata;

  /// No description provided for @deepScan.
  ///
  /// In en, this message translates to:
  /// **'Deep Scan'**
  String get deepScan;

  /// No description provided for @rescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get rescan;

  /// No description provided for @refreshProject.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshProject;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @bpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get bpm;

  /// No description provided for @key.
  ///
  /// In en, this message translates to:
  /// **'Key (e.g., C#m, F major)'**
  String get key;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @projectPhase.
  ///
  /// In en, this message translates to:
  /// **'Project Phase'**
  String get projectPhase;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @fileMissing.
  ///
  /// In en, this message translates to:
  /// **'File missing.'**
  String get fileMissing;

  /// No description provided for @launchingProject.
  ///
  /// In en, this message translates to:
  /// **'Launching {projectName}…'**
  String launchingProject(String projectName);

  /// No description provided for @failedToLaunchProject.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch {projectName}'**
  String failedToLaunchProject(String projectName);

  /// No description provided for @clearLibrary.
  ///
  /// In en, this message translates to:
  /// **'Clear Library'**
  String get clearLibrary;

  /// No description provided for @clearLibraryMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove all saved projects and source folders. Continue?'**
  String get clearLibraryMessage;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @roots.
  ///
  /// In en, this message translates to:
  /// **'Project Folders'**
  String get roots;

  /// No description provided for @pathsSettingsDangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get pathsSettingsDangerZoneTitle;

  /// No description provided for @pathsSettingsDangerZoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all projects and project folders for the current profile.'**
  String get pathsSettingsDangerZoneSubtitle;

  /// No description provided for @projectFoldersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Project folders'**
  String get projectFoldersSectionTitle;

  /// No description provided for @projectFoldersSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Folders that will be scanned for DAW projects.'**
  String get projectFoldersSectionSubtitle;

  /// No description provided for @projectFoldersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No project folders yet'**
  String get projectFoldersEmptyTitle;

  /// No description provided for @projectFoldersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add at least one folder to start scanning for projects.'**
  String get projectFoldersEmptySubtitle;

  /// No description provided for @notScannedYet.
  ///
  /// In en, this message translates to:
  /// **'Not scanned yet'**
  String get notScannedYet;

  /// No description provided for @lastScan.
  ///
  /// In en, this message translates to:
  /// **'Last scan: {date}'**
  String lastScan(String date);

  /// No description provided for @excludedFoldersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Excluded folders'**
  String get excludedFoldersSectionTitle;

  /// No description provided for @excludedFoldersSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These folders will be skipped during scanning, even if they are inside a project folder.'**
  String get excludedFoldersSectionSubtitle;

  /// No description provided for @addExcludedFolder.
  ///
  /// In en, this message translates to:
  /// **'Add excluded'**
  String get addExcludedFolder;

  /// No description provided for @selectExcludedFolder.
  ///
  /// In en, this message translates to:
  /// **'Select a folder to exclude'**
  String get selectExcludedFolder;

  /// No description provided for @excludedFoldersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No excluded folders'**
  String get excludedFoldersEmptyTitle;

  /// No description provided for @excludedFoldersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional: add folders you never want to scan.'**
  String get excludedFoldersEmptySubtitle;

  /// No description provided for @removeExcludedFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove excluded folder?'**
  String get removeExcludedFolderTitle;

  /// No description provided for @removeExcludedFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'This folder will no longer be excluded:\n\n{path}'**
  String removeExcludedFolderMessage(String path);

  /// No description provided for @removeExcludedFolderMessageNoPath.
  ///
  /// In en, this message translates to:
  /// **'This folder will no longer be excluded.'**
  String get removeExcludedFolderMessageNoPath;

  /// No description provided for @desktopOnlyPathsSettings.
  ///
  /// In en, this message translates to:
  /// **'This page is available only on the desktop app.'**
  String get desktopOnlyPathsSettings;

  /// No description provided for @removeProjectFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove project folder?'**
  String get removeProjectFolderTitle;

  /// No description provided for @removeProjectFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{path}\"? This will also remove all projects from this folder that are not in releases.'**
  String removeProjectFolderMessage(String path);

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'hidden'**
  String get hidden;

  /// No description provided for @profileManager.
  ///
  /// In en, this message translates to:
  /// **'Profile Manager'**
  String get profileManager;

  /// No description provided for @createNewProfile.
  ///
  /// In en, this message translates to:
  /// **'Create New Profile'**
  String get createNewProfile;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get profileName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @switchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch Profile'**
  String get switchProfile;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get addFolder;

  /// No description provided for @searchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects...'**
  String get searchProjects;

  /// No description provided for @searchReleases.
  ///
  /// In en, this message translates to:
  /// **'Search releases...'**
  String get searchReleases;

  /// No description provided for @searchPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Search playlists...'**
  String get searchPlaylists;

  /// No description provided for @noReleasesFound.
  ///
  /// In en, this message translates to:
  /// **'No releases found'**
  String get noReleasesFound;

  /// No description provided for @noPlaylistsFound.
  ///
  /// In en, this message translates to:
  /// **'No playlists found'**
  String get noPlaylistsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @deepScanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deep Scan extracts full metadata from project files:\n• BPM (Beats Per Minute)\n• Musical Key\n• DAW Version\nCurrently supported: Ableton Live, Cubase and Bitwig Studio.\n\nThis is slower than a regular scan and may take a while. Continue?'**
  String get deepScanConfirm;

  /// No description provided for @deepScanOnlyUnscanned.
  ///
  /// In en, this message translates to:
  /// **'Only scan projects without metadata'**
  String get deepScanOnlyUnscanned;

  /// No description provided for @metadataExtractedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Metadata extracted successfully'**
  String get metadataExtractedSuccessfully;

  /// No description provided for @failedToExtractMetadata.
  ///
  /// In en, this message translates to:
  /// **'Failed to extract metadata: {error}'**
  String failedToExtractMetadata(String error);

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @failedToLaunchDaw.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch DAW'**
  String get failedToLaunchDaw;

  /// No description provided for @releaseDetails.
  ///
  /// In en, this message translates to:
  /// **'Release Details'**
  String get releaseDetails;

  /// No description provided for @releaseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Release Not Found'**
  String get releaseNotFound;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get deleteProfile;

  /// No description provided for @deleteProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{profileName}\"? This will delete all projects, project folders, and releases for this profile.'**
  String deleteProfileMessage(String profileName);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Confirmation message when removing a track from a release
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{trackName}\" from this release?'**
  String removeTrackFromReleaseMessage(String trackName);

  /// No description provided for @saveName.
  ///
  /// In en, this message translates to:
  /// **'Save Name'**
  String get saveName;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get profilePhotoUpdated;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed.'**
  String get profilePhotoRemoved;

  /// No description provided for @profileRenamed.
  ///
  /// In en, this message translates to:
  /// **'Profile renamed to \"{newName}\"'**
  String profileRenamed(String newName);

  /// No description provided for @profileCreated.
  ///
  /// In en, this message translates to:
  /// **'Profile \"{name}\" created successfully'**
  String profileCreated(String name);

  /// No description provided for @profileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Profile \"{name}\" deleted'**
  String profileDeleted(String name);

  /// No description provided for @pleaseEnterProfileName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a profile name'**
  String get pleaseEnterProfileName;

  /// No description provided for @failedToCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to create profile: {error}'**
  String failedToCreateProfile(String error);

  /// No description provided for @noProfilesFound.
  ///
  /// In en, this message translates to:
  /// **'No profiles found. Create one above.'**
  String get noProfilesFound;

  /// No description provided for @clearLibraryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear Library (projects & project folders)'**
  String get clearLibraryTooltip;

  /// No description provided for @lastModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified: {date}'**
  String lastModified(String date);

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phase;

  /// No description provided for @filterByPhase.
  ///
  /// In en, this message translates to:
  /// **'Filter by Phase'**
  String get filterByPhase;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @allPhases.
  ///
  /// In en, this message translates to:
  /// **'All Phases'**
  String get allPhases;

  /// No description provided for @daw.
  ///
  /// In en, this message translates to:
  /// **'DAW'**
  String get daw;

  /// No description provided for @lastModifiedColumn.
  ///
  /// In en, this message translates to:
  /// **'Last Modified'**
  String get lastModifiedColumn;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @unhide.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get unhide;

  /// No description provided for @extractMetadata.
  ///
  /// In en, this message translates to:
  /// **'Extract Metadata'**
  String get extractMetadata;

  /// No description provided for @createRelease.
  ///
  /// In en, this message translates to:
  /// **'Create Release'**
  String get createRelease;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @selectAllProjects.
  ///
  /// In en, this message translates to:
  /// **'Select all projects'**
  String get selectAllProjects;

  /// No description provided for @switchingProfiles.
  ///
  /// In en, this message translates to:
  /// **'Switching Profiles...'**
  String get switchingProfiles;

  /// No description provided for @scanningProjects.
  ///
  /// In en, this message translates to:
  /// **'Scanning projects...'**
  String get scanningProjects;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @projectsTab.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTab;

  /// No description provided for @releasesTab.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get releasesTab;

  /// No description provided for @showHidden.
  ///
  /// In en, this message translates to:
  /// **'Show Hidden'**
  String get showHidden;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @showOnlyHidden.
  ///
  /// In en, this message translates to:
  /// **'Show Only Hidden'**
  String get showOnlyHidden;

  /// No description provided for @deleteRootPath.
  ///
  /// In en, this message translates to:
  /// **'Remove project folder'**
  String get deleteRootPath;

  /// No description provided for @deleteRootPathMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{path}\"? This will also remove all projects from this folder that are not in releases.'**
  String deleteRootPathMessage(String path);

  /// No description provided for @rootsCount.
  ///
  /// In en, this message translates to:
  /// **'Project Folders: {count}'**
  String rootsCount(int count);

  /// No description provided for @projectsCount.
  ///
  /// In en, this message translates to:
  /// **'Projects: {count}'**
  String projectsCount(int count);

  /// No description provided for @hiddenOnly.
  ///
  /// In en, this message translates to:
  /// **'(hidden only)'**
  String get hiddenOnly;

  /// No description provided for @hiddenCount.
  ///
  /// In en, this message translates to:
  /// **'({count} hidden)'**
  String hiddenCount(int count);

  /// No description provided for @projectsHidden.
  ///
  /// In en, this message translates to:
  /// **'{count} project{plural} hidden.'**
  String projectsHidden(int count, String plural);

  /// No description provided for @projectsUnhidden.
  ///
  /// In en, this message translates to:
  /// **'{count} project{plural} unhidden.'**
  String projectsUnhidden(int count, String plural);

  /// No description provided for @failedToHideProjects.
  ///
  /// In en, this message translates to:
  /// **'Failed to hide projects: {error}'**
  String failedToHideProjects(String error);

  /// No description provided for @failedToUnhideProjects.
  ///
  /// In en, this message translates to:
  /// **'Failed to unhide projects: {error}'**
  String failedToUnhideProjects(String error);

  /// Confirmation message when hiding a project
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to hide \"{projectName}\"?'**
  String hideProjectMessage(String projectName);

  /// No description provided for @releaseCreated.
  ///
  /// In en, this message translates to:
  /// **'Release \"{title}\" created successfully.'**
  String releaseCreated(String title);

  /// No description provided for @failedToCreateRelease.
  ///
  /// In en, this message translates to:
  /// **'Failed to create release: {error}'**
  String failedToCreateRelease(String error);

  /// No description provided for @errorAddingFolder.
  ///
  /// In en, this message translates to:
  /// **'Error adding folder: {error}'**
  String errorAddingFolder(String error);

  /// No description provided for @folderAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This folder has already been added.'**
  String get folderAlreadyAdded;

  /// No description provided for @noProjectsFoundInRoots.
  ///
  /// In en, this message translates to:
  /// **'No projects found in selected project folders.'**
  String get noProjectsFoundInRoots;

  /// No description provided for @selectProjectsFolder.
  ///
  /// In en, this message translates to:
  /// **'Select a projects folder'**
  String get selectProjectsFolder;

  /// No description provided for @enterReleaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Release Title'**
  String get enterReleaseTitle;

  /// No description provided for @releaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Release Title'**
  String get releaseTitle;

  /// No description provided for @enterReleaseTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter release title'**
  String get enterReleaseTitleHint;

  /// No description provided for @metadataExtractedForProjects.
  ///
  /// In en, this message translates to:
  /// **'Extracted metadata for {count} project{plural}. {failures}'**
  String metadataExtractedForProjects(
    int count,
    String plural,
    String failures,
  );

  /// No description provided for @extractionFailures.
  ///
  /// In en, this message translates to:
  /// **'{count} failed.'**
  String extractionFailures(int count, Object plural);

  /// No description provided for @failedToWriteBpmFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to write BPM file: {error}'**
  String failedToWriteBpmFile(String error);

  /// No description provided for @failedToWriteKeyFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to write key file: {error}'**
  String failedToWriteKeyFile(String error);

  /// No description provided for @failedToLaunch.
  ///
  /// In en, this message translates to:
  /// **'Failed to launch: {error}'**
  String failedToLaunch(String error);

  /// No description provided for @libraryCleared.
  ///
  /// In en, this message translates to:
  /// **'Library cleared.'**
  String get libraryCleared;

  /// No description provided for @scanType.
  ///
  /// In en, this message translates to:
  /// **'{type} scan'**
  String scanType(String type);

  /// No description provided for @scanComplete.
  ///
  /// In en, this message translates to:
  /// **'{type} complete: {count} project{plural} added/updated.'**
  String scanComplete(String type, int count, String plural);

  /// No description provided for @projectsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} project{plural} selected'**
  String projectsSelected(int count, String plural);

  /// No description provided for @openingFolder.
  ///
  /// In en, this message translates to:
  /// **'Opening folder for {projectName}…'**
  String openingFolder(String projectName);

  /// No description provided for @failedToOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder: {error}'**
  String failedToOpenFolder(String error);

  /// No description provided for @osNotSupportedForOpeningFolder.
  ///
  /// In en, this message translates to:
  /// **'OS not supported for opening folder.'**
  String get osNotSupportedForOpeningFolder;

  /// No description provided for @noProjectsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No projects available. Please add projects first.'**
  String get noProjectsAvailable;

  /// No description provided for @createNewRelease.
  ///
  /// In en, this message translates to:
  /// **'Create New Release'**
  String get createNewRelease;

  /// No description provided for @deleteRelease.
  ///
  /// In en, this message translates to:
  /// **'Delete Release'**
  String get deleteRelease;

  /// No description provided for @deleteReleaseMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteReleaseMessage(String title);

  /// No description provided for @releaseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Release \"{title}\" deleted.'**
  String releaseDeleted(String title);

  /// No description provided for @selectTracks.
  ///
  /// In en, this message translates to:
  /// **'Select Tracks'**
  String get selectTracks;

  /// Button to continue with authorization code
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @noReleasesYet.
  ///
  /// In en, this message translates to:
  /// **'No releases yet'**
  String get noReleasesYet;

  /// No description provided for @createFirstRelease.
  ///
  /// In en, this message translates to:
  /// **'Create your first release by selecting tracks from your projects'**
  String get createFirstRelease;

  /// No description provided for @releasesCount.
  ///
  /// In en, this message translates to:
  /// **'Releases ({count})'**
  String releasesCount(int count);

  /// No description provided for @errorLoadingReleases.
  ///
  /// In en, this message translates to:
  /// **'Error loading releases: {error}'**
  String errorLoadingReleases(String error);

  /// No description provided for @tracksCount.
  ///
  /// In en, this message translates to:
  /// **'Tracks ({count})'**
  String tracksCount(int count);

  /// No description provided for @addTracks.
  ///
  /// In en, this message translates to:
  /// **'Add Tracks'**
  String get addTracks;

  /// No description provided for @allProjectsAlreadyInRelease.
  ///
  /// In en, this message translates to:
  /// **'All projects are already in this release.'**
  String get allProjectsAlreadyInRelease;

  /// No description provided for @addedTracksToRelease.
  ///
  /// In en, this message translates to:
  /// **'Added {count} track{plural} to release.'**
  String addedTracksToRelease(int count, String plural);

  /// No description provided for @releaseFilesCount.
  ///
  /// In en, this message translates to:
  /// **'Release Files ({count})'**
  String releaseFilesCount(int count);

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add Files'**
  String get addFiles;

  /// No description provided for @addedFilesToRelease.
  ///
  /// In en, this message translates to:
  /// **'Added {count} file{plural} to release.'**
  String addedFilesToRelease(int count, String plural);

  /// No description provided for @failedToAddFiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to add files: {error}'**
  String failedToAddFiles(String error);

  /// No description provided for @noFilesToDownload.
  ///
  /// In en, this message translates to:
  /// **'No files to download.'**
  String get noFilesToDownload;

  /// No description provided for @zipFileSaved.
  ///
  /// In en, this message translates to:
  /// **'ZIP file saved to: {path}'**
  String zipFileSaved(String path);

  /// No description provided for @creatingZipFile.
  ///
  /// In en, this message translates to:
  /// **'Creating ZIP file...'**
  String get creatingZipFile;

  /// No description provided for @failedToCreateZip.
  ///
  /// In en, this message translates to:
  /// **'Failed to create ZIP: {error}'**
  String failedToCreateZip(String error);

  /// No description provided for @selectedFileDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'Selected file does not exist.'**
  String get selectedFileDoesNotExist;

  /// No description provided for @imageSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image saved successfully!'**
  String get imageSavedSuccessfully;

  /// No description provided for @failedToSaveImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to save image: {error}'**
  String failedToSaveImage(String error);

  /// No description provided for @errorLoadingRelease.
  ///
  /// In en, this message translates to:
  /// **'Error loading release: {error}'**
  String errorLoadingRelease(String error);

  /// Error message when projects fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading projects'**
  String get errorLoadingProjects;

  /// No description provided for @releaseSaved.
  ///
  /// In en, this message translates to:
  /// **'Release saved.'**
  String get releaseSaved;

  /// No description provided for @releaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get releaseDate;

  /// No description provided for @failedToSaveReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Failed to save release date: {error}'**
  String failedToSaveReleaseDate(String error);

  /// No description provided for @releaseDateSaved.
  ///
  /// In en, this message translates to:
  /// **'Release date saved.'**
  String get releaseDateSaved;

  /// No description provided for @releaseDateCleared.
  ///
  /// In en, this message translates to:
  /// **'Release date cleared.'**
  String get releaseDateCleared;

  /// No description provided for @saveReleaseFilesZip.
  ///
  /// In en, this message translates to:
  /// **'Save release files ZIP'**
  String get saveReleaseFilesZip;

  /// Error message when opening a file fails
  ///
  /// In en, this message translates to:
  /// **'Failed to open file'**
  String get failedToOpenFile;

  /// No description provided for @failedToPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to play audio: {error}'**
  String failedToPlayAudio(String error);

  /// No description provided for @renameFile.
  ///
  /// In en, this message translates to:
  /// **'Rename File'**
  String get renameFile;

  /// No description provided for @selectTracksToAdd.
  ///
  /// In en, this message translates to:
  /// **'Select Tracks to Add'**
  String get selectTracksToAdd;

  /// No description provided for @fileNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'File name updated.'**
  String get fileNameUpdated;

  /// No description provided for @errorUpdatingFileName.
  ///
  /// In en, this message translates to:
  /// **'Error updating file name: {error}'**
  String errorUpdatingFileName(String error);

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// No description provided for @deleteFileMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{fileName}\"?'**
  String deleteFileMessage(String fileName);

  /// No description provided for @fileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File \"{fileName}\" deleted.'**
  String fileDeleted(String fileName);

  /// No description provided for @failedToDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete file: {error}'**
  String failedToDeleteFile(String error);

  /// No description provided for @couldNotOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Could not open folder: {error}'**
  String couldNotOpenFolder(String error);

  /// No description provided for @artwork.
  ///
  /// In en, this message translates to:
  /// **'Artwork'**
  String get artwork;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @tracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracks;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @selectTracksToInclude.
  ///
  /// In en, this message translates to:
  /// **'Select tracks to include in the release ({count} selected)'**
  String selectTracksToInclude(int count, Object plural);

  /// No description provided for @searchTracks.
  ///
  /// In en, this message translates to:
  /// **'Search tracks'**
  String get searchTracks;

  /// No description provided for @searchTracksHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or DAW type'**
  String get searchTracksHint;

  /// No description provided for @noTracksFound.
  ///
  /// In en, this message translates to:
  /// **'No tracks found'**
  String get noTracksFound;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @editTodo.
  ///
  /// In en, this message translates to:
  /// **'Edit Todo'**
  String get editTodo;

  /// No description provided for @todoText.
  ///
  /// In en, this message translates to:
  /// **'Todo text'**
  String get todoText;

  /// No description provided for @enterTodoText.
  ///
  /// In en, this message translates to:
  /// **'Enter todo text'**
  String get enterTodoText;

  /// No description provided for @addNewTodo.
  ///
  /// In en, this message translates to:
  /// **'Add new todo'**
  String get addNewTodo;

  /// No description provided for @enterTodoItem.
  ///
  /// In en, this message translates to:
  /// **'Enter todo item'**
  String get enterTodoItem;

  /// No description provided for @todoList.
  ///
  /// In en, this message translates to:
  /// **'TODO List'**
  String get todoList;

  /// No description provided for @todoTemplates.
  ///
  /// In en, this message translates to:
  /// **'TODO Templates'**
  String get todoTemplates;

  /// No description provided for @createTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get createTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get editTemplate;

  /// No description provided for @deleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get deleteTemplate;

  /// No description provided for @deleteTemplateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete template \"{name}\"?'**
  String deleteTemplateConfirm(String name);

  /// No description provided for @templateName.
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get templateName;

  /// No description provided for @templateNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Mixing Checklist'**
  String get templateNameHint;

  /// No description provided for @templateItems.
  ///
  /// In en, this message translates to:
  /// **'Template Items'**
  String get templateItems;

  /// No description provided for @templateItemsHint.
  ///
  /// In en, this message translates to:
  /// **'One item per line'**
  String get templateItemsHint;

  /// No description provided for @templateNameAndItemsRequired.
  ///
  /// In en, this message translates to:
  /// **'Template name and items are required'**
  String get templateNameAndItemsRequired;

  /// No description provided for @templateItemsRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one item is required'**
  String get templateItemsRequired;

  /// No description provided for @templateCreated.
  ///
  /// In en, this message translates to:
  /// **'Template created'**
  String get templateCreated;

  /// No description provided for @templateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Template updated'**
  String get templateUpdated;

  /// No description provided for @templateDeleted.
  ///
  /// In en, this message translates to:
  /// **'Template deleted'**
  String get templateDeleted;

  /// No description provided for @noTemplatesYet.
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get noTemplatesYet;

  /// No description provided for @createFirstTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create your first TODO template'**
  String get createFirstTemplate;

  /// No description provided for @templateItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s)'**
  String templateItemCount(int count);

  /// No description provided for @selectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select Template'**
  String get selectTemplate;

  /// No description provided for @importFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'Import from Template'**
  String get importFromTemplate;

  /// No description provided for @manageTemplates.
  ///
  /// In en, this message translates to:
  /// **'Manage Templates'**
  String get manageTemplates;

  /// No description provided for @noTemplatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No templates available. Create one first.'**
  String get noTemplatesAvailable;

  /// No description provided for @templateImported.
  ///
  /// In en, this message translates to:
  /// **'Template \"{name}\" imported ({count} items)'**
  String templateImported(String name, int count);

  /// No description provided for @errorLoadingTemplates.
  ///
  /// In en, this message translates to:
  /// **'Error loading templates'**
  String get errorLoadingTemplates;

  /// No description provided for @importTodos.
  ///
  /// In en, this message translates to:
  /// **'Import Todos from File'**
  String get importTodos;

  /// No description provided for @noTodosInFile.
  ///
  /// In en, this message translates to:
  /// **'No todos found in file'**
  String get noTodosInFile;

  /// No description provided for @todosImported.
  ///
  /// In en, this message translates to:
  /// **'{count} todo(s) imported successfully'**
  String todosImported(int count);

  /// No description provided for @errorImportingTodos.
  ///
  /// In en, this message translates to:
  /// **'Error importing todos: {error}'**
  String errorImportingTodos(String error);

  /// No description provided for @addToRelease.
  ///
  /// In en, this message translates to:
  /// **'Add to Release'**
  String get addToRelease;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// No description provided for @addToExisting.
  ///
  /// In en, this message translates to:
  /// **'Add to Existing'**
  String get addToExisting;

  /// No description provided for @createAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Create and Add'**
  String get createAndAdd;

  /// No description provided for @selectRelease.
  ///
  /// In en, this message translates to:
  /// **'Select a release'**
  String get selectRelease;

  /// No description provided for @noExistingReleasesFound.
  ///
  /// In en, this message translates to:
  /// **'No existing releases found.'**
  String get noExistingReleasesFound;

  /// No description provided for @addToSelectedRelease.
  ///
  /// In en, this message translates to:
  /// **'Add to Selected Release'**
  String get addToSelectedRelease;

  /// No description provided for @failedToSaveProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile photo: {error}'**
  String failedToSaveProfilePhoto(String error);

  /// No description provided for @failedToRemoveProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove profile photo: {error}'**
  String failedToRemoveProfilePhoto(String error);

  /// No description provided for @failedToRenameProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename profile: {error}'**
  String failedToRenameProfile(String error);

  /// No description provided for @failedToDeleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete profile: {error}'**
  String failedToDeleteProfile(String error);

  /// No description provided for @errorLoadingProfiles.
  ///
  /// In en, this message translates to:
  /// **'Error loading profiles: {error}'**
  String errorLoadingProfiles(String error);

  /// No description provided for @projectPhaseIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get projectPhaseIdea;

  /// No description provided for @projectPhaseArranging.
  ///
  /// In en, this message translates to:
  /// **'Arranging'**
  String get projectPhaseArranging;

  /// No description provided for @projectPhaseMixing.
  ///
  /// In en, this message translates to:
  /// **'Mixing'**
  String get projectPhaseMixing;

  /// No description provided for @projectPhaseMastering.
  ///
  /// In en, this message translates to:
  /// **'Mastering'**
  String get projectPhaseMastering;

  /// No description provided for @projectPhaseFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get projectPhaseFinished;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Phase'**
  String get changeStatus;

  /// No description provided for @selectNewStatus.
  ///
  /// In en, this message translates to:
  /// **'Select new phase:'**
  String get selectNewStatus;

  /// Success message when status is changed for multiple projects
  ///
  /// In en, this message translates to:
  /// **'Phase changed to \"{status}\" for {count} project{plural}'**
  String statusChangedForProjects(int count, String plural, String status);

  /// Message when status change partially fails
  ///
  /// In en, this message translates to:
  /// **'Phase changed to \"{status}\" for {successCount} project{successPlural}, {failCount} failed{failPlural}'**
  String statusChangedForProjectsWithErrors(
    int successCount,
    String successPlural,
    int failCount,
    String failPlural,
    String status,
  );

  /// Error message when status change fails
  ///
  /// In en, this message translates to:
  /// **'Failed to change phase: {error}'**
  String failedToChangeStatus(String error);

  /// No description provided for @tooltipEditProfileName.
  ///
  /// In en, this message translates to:
  /// **'Edit profile name'**
  String get tooltipEditProfileName;

  /// No description provided for @tooltipAddTodo.
  ///
  /// In en, this message translates to:
  /// **'Add todo'**
  String get tooltipAddTodo;

  /// No description provided for @tooltipClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get tooltipClearDate;

  /// No description provided for @tooltipPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get tooltipPickDate;

  /// No description provided for @tooltipViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get tooltipViewDetails;

  /// No description provided for @tooltipLaunchInDaw.
  ///
  /// In en, this message translates to:
  /// **'Launch in DAW'**
  String get tooltipLaunchInDaw;

  /// No description provided for @tooltipRemoveFromRelease.
  ///
  /// In en, this message translates to:
  /// **'Remove from Release'**
  String get tooltipRemoveFromRelease;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @noDateSet.
  ///
  /// In en, this message translates to:
  /// **'No date set'**
  String get noDateSet;

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get imageNotFound;

  /// No description provided for @clickToBrowseArtwork.
  ///
  /// In en, this message translates to:
  /// **'Click to browse or drop an image'**
  String get clickToBrowseArtwork;

  /// Hint shown when dragging an image onto the artwork drop zone
  ///
  /// In en, this message translates to:
  /// **'Drop image here'**
  String get dropImageHere;

  /// Label for the remove artwork button and menu item
  ///
  /// In en, this message translates to:
  /// **'Remove Artwork'**
  String get removeArtwork;

  /// Confirmation message when removing artwork
  ///
  /// In en, this message translates to:
  /// **'Remove this artwork? The image file will be deleted.'**
  String get removeArtworkConfirm;

  /// No description provided for @noFilesAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No files added yet.\nClick \"Add Files\" to upload release files.'**
  String get noFilesAddedYet;

  /// No description provided for @noTodosYet.
  ///
  /// In en, this message translates to:
  /// **'No todos yet. Add one above.'**
  String get noTodosYet;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @backupExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully'**
  String get backupExportedSuccessfully;

  /// Error message when backup export fails
  ///
  /// In en, this message translates to:
  /// **'Failed to export backup: {error}'**
  String failedToExportBackup(String error);

  /// Success message after importing backup
  ///
  /// In en, this message translates to:
  /// **'Backup imported successfully: {projectsCount} projects, {rootsCount} project folders, {releasesCount} releases'**
  String backupImportedSuccessfully(
    int projectsCount,
    int rootsCount,
    int releasesCount,
  );

  /// Error message when backup import fails
  ///
  /// In en, this message translates to:
  /// **'Failed to import backup: {error}'**
  String failedToImportBackup(String error);

  /// No description provided for @importBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose how to import the backup:'**
  String get importBackupMessage;

  /// No description provided for @mergeWithCurrentProfile.
  ///
  /// In en, this message translates to:
  /// **'Merge with current active profile'**
  String get mergeWithCurrentProfile;

  /// No description provided for @replaceCurrentProfile.
  ///
  /// In en, this message translates to:
  /// **'Replace entirely the current profile (WARNING: This will delete all current profile data)'**
  String get replaceCurrentProfile;

  /// No description provided for @createNewProfileForImport.
  ///
  /// In en, this message translates to:
  /// **'Create a new profile for this data'**
  String get createNewProfileForImport;

  /// Success message after importing backup to a new profile
  ///
  /// In en, this message translates to:
  /// **'Backup imported to new profile \"{profileName}\": {projectsCount} projects, {rootsCount} project folders, {releasesCount} releases'**
  String backupImportedToNewProfile(
    String profileName,
    int projectsCount,
    int rootsCount,
    int releasesCount,
  );

  /// No description provided for @noProfileSelected.
  ///
  /// In en, this message translates to:
  /// **'No profile selected'**
  String get noProfileSelected;

  /// No description provided for @exportBackupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackupDialogTitle;

  /// No description provided for @importBackupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackupDialogTitle;

  /// No description provided for @invalidBackupFileFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file format: missing version'**
  String get invalidBackupFileFormat;

  /// No description provided for @profileNameRequiredForNewProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile name is required when creating a new profile'**
  String get profileNameRequiredForNewProfile;

  /// No description provided for @currentProfileRequired.
  ///
  /// In en, this message translates to:
  /// **'Current profile is required for merge or replace mode'**
  String get currentProfileRequired;

  /// No description provided for @previewSong.
  ///
  /// In en, this message translates to:
  /// **'Preview Song'**
  String get previewSong;

  /// No description provided for @noPreviewSongTitle.
  ///
  /// In en, this message translates to:
  /// **'No Preview Song'**
  String get noPreviewSongTitle;

  /// No description provided for @noPreviewSongMessage.
  ///
  /// In en, this message translates to:
  /// **'This project has no preview song set. Select an audio file to load and play it.'**
  String get noPreviewSongMessage;

  /// No description provided for @noPreviewSongDragHint.
  ///
  /// In en, this message translates to:
  /// **'You can also drag and drop an audio file directly onto the project row in the table.'**
  String get noPreviewSongDragHint;

  /// No description provided for @previewSongRemoved.
  ///
  /// In en, this message translates to:
  /// **'Preview song removed'**
  String get previewSongRemoved;

  /// No description provided for @previewSongAdded.
  ///
  /// In en, this message translates to:
  /// **'Preview song added'**
  String get previewSongAdded;

  /// No description provided for @previewSongFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Preview song file not found'**
  String get previewSongFileNotFound;

  /// No description provided for @previewSongFileNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The preview song file could not be found on disk. Would you like to select a new file or remove the entry?'**
  String get previewSongFileNotFoundMessage;

  /// No description provided for @selectNewFile.
  ///
  /// In en, this message translates to:
  /// **'Select New File'**
  String get selectNewFile;

  /// No description provided for @failedToPlayPreview.
  ///
  /// In en, this message translates to:
  /// **'Failed to play preview: {error}'**
  String failedToPlayPreview(String error);

  /// No description provided for @removePreviewSong.
  ///
  /// In en, this message translates to:
  /// **'Remove preview song'**
  String get removePreviewSong;

  /// No description provided for @removePreviewSongConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the preview song? This action cannot be undone.'**
  String get removePreviewSongConfirm;

  /// No description provided for @noPreviewSongSelected.
  ///
  /// In en, this message translates to:
  /// **'No preview song selected'**
  String get noPreviewSongSelected;

  /// No description provided for @changePreviewSong.
  ///
  /// In en, this message translates to:
  /// **'Change Preview Song'**
  String get changePreviewSong;

  /// No description provided for @selectPreviewSong.
  ///
  /// In en, this message translates to:
  /// **'Select Preview Song'**
  String get selectPreviewSong;

  /// No description provided for @dropAudioFileHere.
  ///
  /// In en, this message translates to:
  /// **'Drop audio file here'**
  String get dropAudioFileHere;

  /// No description provided for @projectAge.
  ///
  /// In en, this message translates to:
  /// **'Project age: {age}'**
  String projectAge(String age);

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'created {date}'**
  String createdDate(String date);

  /// No description provided for @completedIn.
  ///
  /// In en, this message translates to:
  /// **'Completed in: {duration}'**
  String completedIn(String duration);

  /// No description provided for @finishedDate.
  ///
  /// In en, this message translates to:
  /// **'finished {date}'**
  String finishedDate(String date);

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get dateYesterday;

  /// No description provided for @dateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String dateDaysAgo(int count);

  /// No description provided for @dateWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String dateWeeksAgo(int count);

  /// No description provided for @dateMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String dateMonthsAgo(int count);

  /// No description provided for @dateYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String dateYearsAgo(int count, Object plural);

  /// No description provided for @ageYearsMonths.
  ///
  /// In en, this message translates to:
  /// **'{years} year{yearPlural}, {months} month{monthPlural}'**
  String ageYearsMonths(
    int years,
    String yearPlural,
    int months,
    String monthPlural,
  );

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{years} year{plural}'**
  String ageYears(int years, String plural);

  /// No description provided for @ageMonthsDays.
  ///
  /// In en, this message translates to:
  /// **'{months} month{monthPlural}, {days} day{dayPlural}'**
  String ageMonthsDays(
    int months,
    String monthPlural,
    int days,
    String dayPlural,
  );

  /// No description provided for @ageMonths.
  ///
  /// In en, this message translates to:
  /// **'{months} month{plural}'**
  String ageMonths(int months, String plural);

  /// No description provided for @ageDays.
  ///
  /// In en, this message translates to:
  /// **'{days} day{plural}'**
  String ageDays(int days, String plural);

  /// No description provided for @ageHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hour{plural}'**
  String ageHours(int hours, String plural);

  /// No description provided for @ageJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get ageJustNow;

  /// No description provided for @ageLessThanHour.
  ///
  /// In en, this message translates to:
  /// **'Less than an hour'**
  String get ageLessThanHour;

  /// Button to view profile details
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// Title for Google Drive sync section
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync'**
  String get googleDriveSync;

  /// Short label for the Google Drive navigation button
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// Description text for Google Drive sync feature
  ///
  /// In en, this message translates to:
  /// **'Sync your data with Google Drive to backup and restore across devices.'**
  String get googleDriveSyncDescription;

  /// Button to open Google Drive sync management page
  ///
  /// In en, this message translates to:
  /// **'Manage Google Drive Sync'**
  String get manageGoogleDriveSync;

  /// Button to sign in to Google Drive
  ///
  /// In en, this message translates to:
  /// **'Sign in to Google Drive'**
  String get signInToGoogleDrive;

  /// Button to sync data with Google Drive
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// Button to upload backup to Google Drive
  ///
  /// In en, this message translates to:
  /// **'Upload Backup'**
  String get uploadBackup;

  /// Button to download backup from Google Drive
  ///
  /// In en, this message translates to:
  /// **'Download Backup'**
  String get downloadBackup;

  /// No description provided for @newerBackupAvailable.
  ///
  /// In en, this message translates to:
  /// **'New backup available on cloud'**
  String get newerBackupAvailable;

  /// Context menu option to restore a single project from Google Drive backup
  ///
  /// In en, this message translates to:
  /// **'Restore from Drive'**
  String get restoreProjectFromDrive;

  /// Progress message shown while restoring a single project from Drive
  ///
  /// In en, this message translates to:
  /// **'Restoring from Drive...'**
  String get restoringProjectFromDrive;

  /// Success message shown after restoring a project from Drive
  ///
  /// In en, this message translates to:
  /// **'Project restored from Drive'**
  String get projectRestoredFromDrive;

  /// Error shown when the project doesn't exist in the remote backup
  ///
  /// In en, this message translates to:
  /// **'This project was not found in the Drive backup'**
  String get projectNotFoundInBackup;

  /// Error shown when trying to restore from Drive but not authenticated
  ///
  /// In en, this message translates to:
  /// **'Please sign in to Google Drive first (open Drive Sync settings)'**
  String get signInToGoogleDriveFirst;

  /// Button to sign out from Google Drive
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Checkbox label for downloading preview songs
  ///
  /// In en, this message translates to:
  /// **'Download preview songs'**
  String get downloadPreviewSongs;

  /// Explanation text for preview songs download option
  ///
  /// In en, this message translates to:
  /// **'If unchecked, preview songs will be skipped (saves time and storage). You can download them later if needed.'**
  String get downloadPreviewSongsExplanation;

  /// Button to confirm replacing local data with backup
  ///
  /// In en, this message translates to:
  /// **'Replace Local Data'**
  String get replaceLocalData;

  /// Confirmation message for downloading backup
  ///
  /// In en, this message translates to:
  /// **'This will replace your local data with the backup from Google Drive.\n\nAre you sure you want to continue?'**
  String get downloadBackupConfirmation;

  /// Dialog title for entering authorization code
  ///
  /// In en, this message translates to:
  /// **'Enter Authorization Code'**
  String get enterAuthorizationCode;

  /// Label for authorization code input field
  ///
  /// In en, this message translates to:
  /// **'Authorization Code'**
  String get authorizationCode;

  /// Hint text for authorization code input field
  ///
  /// In en, this message translates to:
  /// **'Paste the code from the browser'**
  String get pasteCodeFromBrowser;

  /// Status message when Google Drive session is active
  ///
  /// In en, this message translates to:
  /// **'Session active'**
  String get sessionActive;

  /// Status message when signed in to Google Drive
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// Status message when creating initial backup
  ///
  /// In en, this message translates to:
  /// **'Creating initial backup...'**
  String get creatingInitialBackup;

  /// Success message when signed in and backed up
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in and backed up to Google Drive'**
  String get successfullySignedInAndBackedUp;

  /// Snackbar message when signed in and backed up
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in and backed up to Google Drive!'**
  String get successfullySignedInAndBackedUpMessage;

  /// Success message when signed in
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in to Google Drive'**
  String get successfullySignedInToGoogleDrive;

  /// Snackbar message when signed in
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in to Google Drive!'**
  String get successfullySignedInToGoogleDriveMessage;

  /// Error message when sign in is cancelled or failed
  ///
  /// In en, this message translates to:
  /// **'Sign in cancelled or failed. Check console for details.'**
  String get signInCancelledOrFailed;

  /// Error message when browser launch fails
  ///
  /// In en, this message translates to:
  /// **'Failed to launch browser'**
  String get failedToLaunchBrowser;

  /// Status message when sign in is cancelled
  ///
  /// In en, this message translates to:
  /// **'Sign in cancelled'**
  String get signInCancelled;

  /// Error message when authorization code exchange fails
  ///
  /// In en, this message translates to:
  /// **'Failed to exchange authorization code'**
  String get failedToExchangeAuthorizationCode;

  /// No description provided for @errorSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Error signing in: {error}'**
  String errorSigningIn(String error);

  /// Generic unknown error message
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// Error title for Google Sign-In errors
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In Error'**
  String get googleSignInError;

  /// Error message for OAuth configuration issues
  ///
  /// In en, this message translates to:
  /// **'Developer console is not set up correctly. Please check your OAuth configuration in Google Cloud Console.'**
  String get developerConsoleNotSetUp;

  /// Error title for platform errors
  ///
  /// In en, this message translates to:
  /// **'Platform Error'**
  String get platformError;

  /// Status message when signed out
  ///
  /// In en, this message translates to:
  /// **'Signed out from Google Drive'**
  String get signedOutFromGoogleDrive;

  /// No description provided for @errorSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Error signing out: {error}'**
  String errorSigningOut(String error);

  /// Status message when syncing
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// Error message when no profile is selected
  ///
  /// In en, this message translates to:
  /// **'Error: No profile selected'**
  String get errorNoProfileSelected;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync completed! Projects: +{projectsAdded} ~{projectsUpdated}, Releases: +{releasesAdded} ~{releasesUpdated}'**
  String syncCompleted(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  );

  /// No description provided for @errorSyncing.
  ///
  /// In en, this message translates to:
  /// **'Error syncing: {error}'**
  String errorSyncing(String error);

  /// Status message when uploading backup
  ///
  /// In en, this message translates to:
  /// **'Uploading backup...'**
  String get uploadingBackup;

  /// Status message when backup is uploaded
  ///
  /// In en, this message translates to:
  /// **'Backup uploaded successfully!'**
  String get backupUploadedSuccessfully;

  /// Snackbar message when backup is uploaded
  ///
  /// In en, this message translates to:
  /// **'Backup uploaded successfully to Google Drive!'**
  String get backupUploadedSuccessfullyMessage;

  /// No description provided for @errorUploadingBackup.
  ///
  /// In en, this message translates to:
  /// **'Error uploading backup: {error}'**
  String errorUploadingBackup(String error);

  /// Status message when downloading backup
  ///
  /// In en, this message translates to:
  /// **'Downloading backup...'**
  String get downloadingBackup;

  /// Status message when checking for backup
  ///
  /// In en, this message translates to:
  /// **'Checking for backup...'**
  String get checkingForBackup;

  /// Message when backup is current
  ///
  /// In en, this message translates to:
  /// **'Backup is up to date'**
  String get backupUpToDate;

  /// No description provided for @errorCheckingBackup.
  ///
  /// In en, this message translates to:
  /// **'Error checking backup: {error}'**
  String errorCheckingBackup(String error);

  /// Download button label
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Warning when remote backup is newer
  ///
  /// In en, this message translates to:
  /// **'Remote backup is newer than local data. Uploading will overwrite it.'**
  String get remoteBackupIsNewer;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Upload'**
  String get confirmUpload;

  /// Message when no backup file is found
  ///
  /// In en, this message translates to:
  /// **'No backup file found in Google Drive. Create a backup first by syncing your data.'**
  String get noBackupFileFound;

  /// Status message when no backup file is found
  ///
  /// In en, this message translates to:
  /// **'No backup file found. Create a backup first.'**
  String get noBackupFileFoundStatus;

  /// Status message when download is cancelled
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get downloadCancelled;

  /// No description provided for @backupDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Backup downloaded! Projects: +{projectsAdded} ~{projectsUpdated}, Releases: +{releasesAdded} ~{releasesUpdated}'**
  String backupDownloaded(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
  );

  /// No description provided for @backupDownloadedDetailed.
  ///
  /// In en, this message translates to:
  /// **'Backup downloaded!\n\nProjects:\n  • {projectsAdded} added\n  • {projectsUpdated} updated\n\nReleases:\n  • {releasesAdded} added\n  • {releasesUpdated} updated\n\nPreview Songs:\n  • {previewSongsDownloaded} downloaded\n  • {previewSongsUpdated} updated'**
  String backupDownloadedDetailed(
    int projectsAdded,
    int projectsUpdated,
    int releasesAdded,
    int releasesUpdated,
    int previewSongsDownloaded,
    int previewSongsUpdated,
  );

  /// No description provided for @errorDownloadingBackup.
  ///
  /// In en, this message translates to:
  /// **'Error downloading backup: {error}'**
  String errorDownloadingBackup(String error);

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as: {email}'**
  String signedInAs(String email);

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {date}'**
  String lastSync(String date);

  /// No description provided for @remoteBackupTime.
  ///
  /// In en, this message translates to:
  /// **'Remote backup: {date}'**
  String remoteBackupTime(String date);

  /// No description provided for @lastUploadTime.
  ///
  /// In en, this message translates to:
  /// **'Last upload: {date}'**
  String lastUploadTime(String date);

  /// No description provided for @lastDownloadTime.
  ///
  /// In en, this message translates to:
  /// **'Last download: {date}'**
  String lastDownloadTime(String date);

  /// Button to check if newer backup is available
  ///
  /// In en, this message translates to:
  /// **'Check for Backup'**
  String get checkForBackup;

  /// Title for notification settings page
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Message shown on non-Android platforms
  ///
  /// In en, this message translates to:
  /// **'Deadline notifications are only available on Android devices.'**
  String get notificationsOnlyOnAndroid;

  /// Title for permission request card
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Required'**
  String get notificationPermissionRequired;

  /// Description for permission request
  ///
  /// In en, this message translates to:
  /// **'Please enable notifications to receive deadline reminders.'**
  String get notificationPermissionDescription;

  /// Error message when permission is denied
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied. Please enable it in settings.'**
  String get notificationPermissionDenied;

  /// Success message after saving settings
  ///
  /// In en, this message translates to:
  /// **'Notification settings saved successfully'**
  String get notificationSettingsSaved;

  /// Error message when saving fails
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get errorSavingSettings;

  /// Toggle to enable/disable notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Deadline Notifications'**
  String get enableDeadlineNotifications;

  /// Description for enable toggle
  ///
  /// In en, this message translates to:
  /// **'Receive reminders for project deadlines'**
  String get receiveRemindersForDeadlines;

  /// Title for time picker
  ///
  /// In en, this message translates to:
  /// **'Notification Time'**
  String get notificationTime;

  /// Description for time picker
  ///
  /// In en, this message translates to:
  /// **'Time of day to receive notifications'**
  String get timeToReceiveNotifications;

  /// Title for reminder days section
  ///
  /// In en, this message translates to:
  /// **'Reminder Days'**
  String get reminderDays;

  /// Description for reminder days
  ///
  /// In en, this message translates to:
  /// **'Select how many days before the deadline you want to be notified'**
  String get selectDaysBeforeDeadline;

  /// Toggle for deadline day notification
  ///
  /// In en, this message translates to:
  /// **'Notify on Deadline Day'**
  String get notifyOnDeadlineDay;

  /// Description for deadline day toggle
  ///
  /// In en, this message translates to:
  /// **'Also receive a notification on the deadline day itself'**
  String get receiveNotificationOnDeadlineDay;

  /// Title for help section
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// Help text explaining notifications
  ///
  /// In en, this message translates to:
  /// **'You will receive notifications at the specified time on the selected days before each project deadline. Tap a notification to open the project details.'**
  String get deadlineNotificationsHelp;

  /// One day label for reminder chips
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get oneDay;

  /// Multiple days label for reminder chips
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String xDays(int count);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportTheProject.
  ///
  /// In en, this message translates to:
  /// **'Support the project'**
  String get supportTheProject;

  /// No description provided for @couldNotOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Could not open browser. Please visit: {url}'**
  String couldNotOpenBrowser(String url);

  /// No description provided for @errorOpeningBrowser.
  ///
  /// In en, this message translates to:
  /// **'Error opening browser: {error}'**
  String errorOpeningBrowser(String error);

  /// No description provided for @generateTestingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Generate Testing Database'**
  String get generateTestingDatabase;

  /// No description provided for @generateTestingDatabaseMessage.
  ///
  /// In en, this message translates to:
  /// **'This will populate the database with sample projects and releases for testing. Continue?'**
  String get generateTestingDatabaseMessage;

  /// No description provided for @testingDatabaseGenerated.
  ///
  /// In en, this message translates to:
  /// **'Testing database generated successfully!'**
  String get testingDatabaseGenerated;

  /// No description provided for @failedToGenerateTestingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate testing database: {error}'**
  String failedToGenerateTestingDatabase(String error);

  /// Playlists tab title
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// Message shown on desktop when trying to access playlists
  ///
  /// In en, this message translates to:
  /// **'Playlists are only available on Android.'**
  String get playlistsDesktopOnly;

  /// Message when there are no playlists
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylistsYet;

  /// Hint text for creating first playlist
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to create your first playlist'**
  String get createFirstPlaylist;

  /// Number of songs in playlist
  ///
  /// In en, this message translates to:
  /// **'{count} songs'**
  String playlistSongCount(int count);

  /// Dialog title for creating a playlist
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylist;

  /// Label for playlist name field
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistName;

  /// Placeholder for playlist name input
  ///
  /// In en, this message translates to:
  /// **'My Playlist'**
  String get playlistNameHint;

  /// Error message when playlist name is empty
  ///
  /// In en, this message translates to:
  /// **'Playlist name is required'**
  String get playlistNameRequired;

  /// Dialog title for editing a playlist
  ///
  /// In en, this message translates to:
  /// **'Edit Playlist'**
  String get editPlaylist;

  /// Message shown when trying to edit playlist while music is playing
  ///
  /// In en, this message translates to:
  /// **'Please stop playback before editing the playlist'**
  String get stopPlaybackBeforeEditing;

  /// Label for selecting preview songs in playlist
  ///
  /// In en, this message translates to:
  /// **'Select Preview Songs'**
  String get selectPreviewSongs;

  /// Dialog title for deleting a playlist
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// Confirmation message for deleting a playlist
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deletePlaylistConfirm(String name);

  /// Success message after deleting a playlist
  ///
  /// In en, this message translates to:
  /// **'Playlist deleted'**
  String get playlistDeleted;

  /// Error message when playlist deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting playlist'**
  String get errorDeletingPlaylist;

  /// No description provided for @playlistUpdated.
  ///
  /// In en, this message translates to:
  /// **'Playlist updated'**
  String get playlistUpdated;

  /// No description provided for @changeSong.
  ///
  /// In en, this message translates to:
  /// **'Change Song'**
  String get changeSong;

  /// No description provided for @changeSongConfirm.
  ///
  /// In en, this message translates to:
  /// **'A song is currently playing. Do you want to switch to this song?'**
  String get changeSongConfirm;

  /// No description provided for @changeSongButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeSongButton;

  /// Current position in playlist
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String playlistProgress(int current, int total);

  /// Message when playlist has no valid preview songs
  ///
  /// In en, this message translates to:
  /// **'No preview songs available in this playlist'**
  String get noPreviewSongsInPlaylist;

  /// Hint message to edit empty playlist
  ///
  /// In en, this message translates to:
  /// **'Tap edit to add songs to this playlist'**
  String get tapEditToAddSongs;

  /// Error message when trying to add songs but no projects available
  ///
  /// In en, this message translates to:
  /// **'No projects with preview songs available to add'**
  String get noProjectsAvailableForPlaylist;

  /// Error message when there are no projects at all in the database
  ///
  /// In en, this message translates to:
  /// **'No projects found in database. Please sync your projects first.'**
  String get noProjectsInDatabase;

  /// Title for first-time sync message on mobile
  ///
  /// In en, this message translates to:
  /// **'It seems it\'s your first time here!'**
  String get firstTimeSyncTitle;

  /// Message explaining to sync data from Google Drive
  ///
  /// In en, this message translates to:
  /// **'Let\'s sync your data from Google Drive to get started'**
  String get firstTimeSyncMessage;

  /// Button text to sync with Google Drive
  ///
  /// In en, this message translates to:
  /// **'Sync with Google Drive'**
  String get syncWithGoogleDrive;

  /// Error message when playlists fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading playlists'**
  String get errorLoadingPlaylists;

  /// Label for playlist items section
  ///
  /// In en, this message translates to:
  /// **'Playlist Items'**
  String get playlistItems;

  /// Button to add songs to playlist
  ///
  /// In en, this message translates to:
  /// **'Add Songs'**
  String get addSongs;

  /// Button to add audio files directly
  ///
  /// In en, this message translates to:
  /// **'Add Audio Files'**
  String get addAudioFiles;

  /// Dialog title for selecting audio files
  ///
  /// In en, this message translates to:
  /// **'Select Audio Files'**
  String get selectAudioFiles;

  /// Label for selecting from existing projects
  ///
  /// In en, this message translates to:
  /// **'Select from Projects'**
  String get selectFromProjects;

  /// Button to add selected items
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Label indicating item is from a project
  ///
  /// In en, this message translates to:
  /// **'From Project'**
  String get fromProject;

  /// Label for project deadline field
  ///
  /// In en, this message translates to:
  /// **'Project Deadline'**
  String get projectDeadline;

  /// Message when no deadline is set for a project
  ///
  /// In en, this message translates to:
  /// **'No deadline set'**
  String get noDeadlineSet;

  /// Label for Camelot Wheel notation
  ///
  /// In en, this message translates to:
  /// **'Camelot Code'**
  String get camelotCode;

  /// Label for deadline column
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// Status text when deadline is today
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// Status text when deadline is overdue
  ///
  /// In en, this message translates to:
  /// **'{days}d late'**
  String daysLate(int days);

  /// Status text for days remaining until deadline
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String daysLeft(int days);

  /// Checkbox label to hide finished projects
  ///
  /// In en, this message translates to:
  /// **'Hide Finished'**
  String get hideFinished;

  /// No description provided for @showOnlyDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Show Deadline'**
  String get showOnlyDeadlines;

  /// Dropdown hint for deadline filter
  ///
  /// In en, this message translates to:
  /// **'Filter by Deadline'**
  String get filterByDeadline;

  /// Show all projects regardless of deadline
  ///
  /// In en, this message translates to:
  /// **'All Deadlines'**
  String get allDeadlines;

  /// Show only projects with deadlines
  ///
  /// In en, this message translates to:
  /// **'Has Deadline'**
  String get hasDeadline;

  /// Show only overdue projects
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// Show projects due within 7 days
  ///
  /// In en, this message translates to:
  /// **'Due Soon (7d)'**
  String get dueSoon;

  /// Short text for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Tooltip when project has no preview song
  ///
  /// In en, this message translates to:
  /// **'No preview song'**
  String get noPreviewSong;

  /// Tooltip for play preview button
  ///
  /// In en, this message translates to:
  /// **'Play Preview'**
  String get playPreview;

  /// Status message when backup upload is cancelled
  ///
  /// In en, this message translates to:
  /// **'Upload cancelled'**
  String get uploadCancelled;

  /// Message shown when user cancels backup upload
  ///
  /// In en, this message translates to:
  /// **'Backup upload cancelled by user'**
  String get backupUploadCancelledByUser;

  /// Status message when collecting data for backup
  ///
  /// In en, this message translates to:
  /// **'Collecting data...'**
  String get collectingData;

  /// Status message when uploading preview song files
  ///
  /// In en, this message translates to:
  /// **'Uploading preview songs...'**
  String get uploadingPreviewSongs;

  /// Status message when uploading profile photo files
  ///
  /// In en, this message translates to:
  /// **'Uploading profile photos...'**
  String get uploadingProfilePhotos;

  /// Status message when uploading release artwork files
  ///
  /// In en, this message translates to:
  /// **'Uploading release artwork...'**
  String get uploadingReleaseArtwork;

  /// Status message when uploading database file
  ///
  /// In en, this message translates to:
  /// **'Uploading database...'**
  String get uploadingDatabase;

  /// Status message when operation is completed
  ///
  /// In en, this message translates to:
  /// **'Completed!'**
  String get completed;

  /// Status message when cancelling an operation
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get cancelling;

  /// Title for backup upload progress dialog
  ///
  /// In en, this message translates to:
  /// **'Uploading Backup'**
  String get uploadingBackupTitle;

  /// Status message during upload cancellation
  ///
  /// In en, this message translates to:
  /// **'Cancelling upload...'**
  String get cancellingUpload;

  /// Message shown while stopping upload operation
  ///
  /// In en, this message translates to:
  /// **'Please wait while we stop the upload...'**
  String get pleaseWaitCancellingUpload;

  /// Status message when downloading database file
  ///
  /// In en, this message translates to:
  /// **'Downloading database...'**
  String get downloadingDatabase;

  /// Status message when downloading preview song files
  ///
  /// In en, this message translates to:
  /// **'Downloading preview songs...'**
  String get downloadingPreviewSongs;

  /// Status message when downloading profile photo files
  ///
  /// In en, this message translates to:
  /// **'Downloading profile photos...'**
  String get downloadingProfilePhotos;

  /// Status message when downloading release artwork files
  ///
  /// In en, this message translates to:
  /// **'Downloading release artwork...'**
  String get downloadingReleaseArtwork;

  /// Status message when merging downloaded data
  ///
  /// In en, this message translates to:
  /// **'Merging data...'**
  String get mergingData;

  /// Title for backup download progress dialog
  ///
  /// In en, this message translates to:
  /// **'Downloading Backup'**
  String get downloadingBackupTitle;

  /// Tooltip shown when the project source file does not exist on the current machine
  ///
  /// In en, this message translates to:
  /// **'Source file not found on this machine'**
  String get sourceFileNotFoundOnThisMachine;

  /// Banner shown in project detail when the source file is missing; user can still edit metadata
  ///
  /// In en, this message translates to:
  /// **'Source file not found on this machine — metadata-only mode. You can still edit and export metadata.'**
  String get sourceFileNotFoundMetadataOnly;

  /// Message shown when preview song is not available locally and needs to be downloaded
  ///
  /// In en, this message translates to:
  /// **'Preview song not available. Please download backup first.'**
  String get previewSongNotAvailableDownloadFirst;

  /// Tooltip for the share preview song button
  ///
  /// In en, this message translates to:
  /// **'Share preview song'**
  String get sharePreviewSong;

  /// Tooltip for the share as ZIP button
  ///
  /// In en, this message translates to:
  /// **'Share as ZIP'**
  String get shareAsZip;

  /// Label for the share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Label for the share as ZIP button
  ///
  /// In en, this message translates to:
  /// **'Share ZIP'**
  String get shareZip;

  /// Desktop save a copy: saveCopy
  ///
  /// In en, this message translates to:
  /// **'Save a copy'**
  String get saveCopy;

  /// Desktop save a copy: savedCopyTo
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String savedCopyTo(String path);

  /// Error message when sharing preview song fails
  ///
  /// In en, this message translates to:
  /// **'Failed to share preview song: {error}'**
  String failedToSharePreviewSong(String error);

  /// Error message when sharing preview song as ZIP fails
  ///
  /// In en, this message translates to:
  /// **'Failed to share preview song as ZIP: {error}'**
  String failedToSharePreviewSongAsZip(String error);

  /// Success message when biography is saved
  ///
  /// In en, this message translates to:
  /// **'Biography saved'**
  String get biographySaved;

  /// Error message when saving biography fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save biography: {error}'**
  String failedToSaveBiography(String error);

  /// Success message when a file is saved
  ///
  /// In en, this message translates to:
  /// **'File saved to {filename}'**
  String fileSavedTo(String filename);

  /// Error message when downloading a file fails
  ///
  /// In en, this message translates to:
  /// **'Failed to download file: {error}'**
  String failedToDownloadFile(String error);

  /// Success message when all files are saved to a zip
  ///
  /// In en, this message translates to:
  /// **'All files saved to {filename}'**
  String allFilesSavedTo(String filename);

  /// Success message when artwork is added
  ///
  /// In en, this message translates to:
  /// **'Artwork added'**
  String get artworkAdded;

  /// Error message when adding artwork fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add artwork: {error}'**
  String failedToAddArtwork(String error);

  /// Success message when artwork is removed
  ///
  /// In en, this message translates to:
  /// **'Artwork removed'**
  String get artworkRemoved;

  /// Error message when removing artwork fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove artwork: {error}'**
  String failedToRemoveArtwork(String error);

  /// Success message when a press kit file is added
  ///
  /// In en, this message translates to:
  /// **'Press kit file added'**
  String get pressKitFileAdded;

  /// Error message when adding press kit file fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add press kit file: {error}'**
  String failedToAddPressKitFile(String error);

  /// Success message when a press kit file is removed
  ///
  /// In en, this message translates to:
  /// **'Press kit file removed'**
  String get pressKitFileRemoved;

  /// Error message when removing press kit file fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove press kit file: {error}'**
  String failedToRemovePressKitFile(String error);

  /// Title for the dialog to select files for download
  ///
  /// In en, this message translates to:
  /// **'Select Files to Download'**
  String get selectFilesToDownload;

  /// Label for the biography field
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get biography;

  /// Subtitle explaining how the biography file will be saved
  ///
  /// In en, this message translates to:
  /// **'Will be saved as biography.txt'**
  String get biographyWillBeSaved;

  /// Section header for artwork files
  ///
  /// In en, this message translates to:
  /// **'Artwork Files'**
  String get artworkFiles;

  /// Section header for press kit files
  ///
  /// In en, this message translates to:
  /// **'Press Kit Files'**
  String get pressKitFiles;

  /// Section header for additional assets
  ///
  /// In en, this message translates to:
  /// **'Additional Assets'**
  String get additionalAssets;

  /// Button label to download N files
  ///
  /// In en, this message translates to:
  /// **'Download {count} file{plural}'**
  String downloadNFiles(int count, String plural);

  /// Success message when N files are saved
  ///
  /// In en, this message translates to:
  /// **'{count} file{plural} saved to {filename}'**
  String nFilesSavedTo(int count, String plural, String filename);

  /// Dialog title and button label for adding an asset
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get addAsset;

  /// Label for asset name input field
  ///
  /// In en, this message translates to:
  /// **'Asset Name'**
  String get assetNameLabel;

  /// Hint text for asset name input field
  ///
  /// In en, this message translates to:
  /// **'e.g., Logo, Banner, Photo'**
  String get assetNameHint;

  /// Success message when an asset is added
  ///
  /// In en, this message translates to:
  /// **'{assetName} added successfully'**
  String assetAddedSuccessfully(String assetName);

  /// Error message when adding an asset fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add asset: {error}'**
  String failedToAddAsset(String error);

  /// Success message when an asset is removed
  ///
  /// In en, this message translates to:
  /// **'{assetName} removed'**
  String assetRemoved(String assetName);

  /// Error message when removing an asset fails
  ///
  /// In en, this message translates to:
  /// **'Failed to remove asset: {error}'**
  String failedToRemoveAsset(String error);

  /// Message when a profile cannot be found
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// Button label to select files
  ///
  /// In en, this message translates to:
  /// **'Select Files'**
  String get selectFiles;

  /// Button label to download all files
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get downloadAll;

  /// Tooltip for the save biography button
  ///
  /// In en, this message translates to:
  /// **'Save Biography'**
  String get saveBiographyTooltip;

  /// Hint text for biography input field
  ///
  /// In en, this message translates to:
  /// **'Enter profile biography...'**
  String get enterBiographyHint;

  /// Button label to add artwork
  ///
  /// In en, this message translates to:
  /// **'Add Artwork'**
  String get addArtwork;

  /// Button label to add a press kit file
  ///
  /// In en, this message translates to:
  /// **'Add File'**
  String get addFile;

  /// Tooltip for the open file button
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// macOS menu bar View menu label
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// macOS menu item for About dialog
  ///
  /// In en, this message translates to:
  /// **'About DAW Project Manager'**
  String get menuAbout;

  /// macOS menu item that opens the online documentation
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get menuDocumentation;

  /// macOS menu item for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get menuLanguage;

  /// macOS menu item to toggle quit warning
  ///
  /// In en, this message translates to:
  /// **'Warn Before Quitting (⌘+Q)'**
  String get menuWarnBeforeQuit;

  /// macOS menu item to quit the app
  ///
  /// In en, this message translates to:
  /// **'Quit DAW Project Manager'**
  String get menuQuit;

  /// macOS menu bar Window menu label
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get menuWindow;

  /// Button label for the donate button in the About dialog
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donate;

  /// Button label for the website button in the About dialog
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Theme switcher label to switch to classic dark theme
  ///
  /// In en, this message translates to:
  /// **'Switch to Classic Dark'**
  String get switchToClassicDark;

  /// Theme switcher label to switch to neon dark theme
  ///
  /// In en, this message translates to:
  /// **'Switch to Neon Dark'**
  String get switchToNeonDark;

  /// Tooltip to switch to classic theme
  ///
  /// In en, this message translates to:
  /// **'Switch to Classic Theme'**
  String get switchToClassicTheme;

  /// Tooltip to switch to neon theme
  ///
  /// In en, this message translates to:
  /// **'Switch to Neon Theme'**
  String get switchToNeonTheme;

  /// Tooltip to switch to studio light theme
  ///
  /// In en, this message translates to:
  /// **'Switch to Studio Light'**
  String get switchToStudioLight;

  /// macOS menu item for theme switching
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get menuTheme;

  /// Short description of the app shown in the About dialog
  ///
  /// In en, this message translates to:
  /// **'A project manager for music producers and sound designers.'**
  String get appDescription;

  /// Display name for the Neon Dark theme
  ///
  /// In en, this message translates to:
  /// **'Neon Dark'**
  String get neonDarkThemeName;

  /// Display name for the Classic Dark theme
  ///
  /// In en, this message translates to:
  /// **'Classic Dark'**
  String get classicDarkThemeName;

  /// Display name for the Studio Light theme
  ///
  /// In en, this message translates to:
  /// **'Studio Light'**
  String get studioLightThemeName;

  /// No description provided for @statisticsTab.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTab;

  /// No description provided for @statsTotalProjects.
  ///
  /// In en, this message translates to:
  /// **'Total Projects'**
  String get statsTotalProjects;

  /// No description provided for @statsInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statsInProgress;

  /// No description provided for @statsFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get statsFinished;

  /// No description provided for @statsAvgCompletion.
  ///
  /// In en, this message translates to:
  /// **'Avg. Completion'**
  String get statsAvgCompletion;

  /// No description provided for @statsPhaseDistribution.
  ///
  /// In en, this message translates to:
  /// **'Projects by Phase'**
  String get statsPhaseDistribution;

  /// No description provided for @statsAvgTimePerPhase.
  ///
  /// In en, this message translates to:
  /// **'Avg. Days per Phase'**
  String get statsAvgTimePerPhase;

  /// No description provided for @statsProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get statsProductivity;

  /// No description provided for @statsCreatedSeries.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get statsCreatedSeries;

  /// No description provided for @statsProjectHealth.
  ///
  /// In en, this message translates to:
  /// **'Project Age & Health'**
  String get statsProjectHealth;

  /// No description provided for @statsCatalogInsights.
  ///
  /// In en, this message translates to:
  /// **'Catalog Insights'**
  String get statsCatalogInsights;

  /// No description provided for @statsBpmDistribution.
  ///
  /// In en, this message translates to:
  /// **'BPM Distribution'**
  String get statsBpmDistribution;

  /// No description provided for @statsTopKeys.
  ///
  /// In en, this message translates to:
  /// **'Top Musical Keys'**
  String get statsTopKeys;

  /// No description provided for @statsDawTypes.
  ///
  /// In en, this message translates to:
  /// **'DAW Types'**
  String get statsDawTypes;

  /// No description provided for @statsProjectActivity.
  ///
  /// In en, this message translates to:
  /// **'Project Activity'**
  String get statsProjectActivity;

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get statsNoData;

  /// No description provided for @statsNoPhaseData.
  ///
  /// In en, this message translates to:
  /// **'Phase data will appear after projects move between phases.'**
  String get statsNoPhaseData;

  /// No description provided for @statsLastActivityDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Last activity: {days} days ago'**
  String statsLastActivityDaysAgo(int days);

  /// No description provided for @statsLastActivityToday.
  ///
  /// In en, this message translates to:
  /// **'Active today'**
  String get statsLastActivityToday;

  /// No description provided for @statsNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events recorded yet'**
  String get statsNoEvents;

  /// No description provided for @statsEventPhaseChanged.
  ///
  /// In en, this message translates to:
  /// **'Phase: {from} → {to}'**
  String statsEventPhaseChanged(String from, String to);

  /// No description provided for @statsEventMetadataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated: {fields}'**
  String statsEventMetadataUpdated(String fields);

  /// No description provided for @statsEventTodoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed: {text}'**
  String statsEventTodoCompleted(String text);

  /// No description provided for @statsEventFileModified.
  ///
  /// In en, this message translates to:
  /// **'File modified on disk'**
  String get statsEventFileModified;

  /// No description provided for @statsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get statsClearHistory;

  /// No description provided for @statsClearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all recorded events for this project?'**
  String get statsClearHistoryConfirm;

  /// No description provided for @statsSearchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects…'**
  String get statsSearchProjects;

  /// No description provided for @statsEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String statsEventCount(int count);

  /// Button/page title for per-project statistics
  ///
  /// In en, this message translates to:
  /// **'Project Statistics'**
  String get statsViewHistory;

  /// Section title: phase history
  ///
  /// In en, this message translates to:
  /// **'Phase History'**
  String get statsPhaseHistory;

  /// Section title: event breakdown
  ///
  /// In en, this message translates to:
  /// **'Event Breakdown'**
  String get statsEventBreakdown;

  /// Current phase duration indicator
  ///
  /// In en, this message translates to:
  /// **'{days}d so far'**
  String statsDaysSoFar(int days);

  /// No description provided for @statsNoProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get statsNoProjectsFound;

  /// No description provided for @statsNotTouchedDays.
  ///
  /// In en, this message translates to:
  /// **'Not touched in {days} days'**
  String statsNotTouchedDays(int days);

  /// No description provided for @sortByLastModified.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get sortByLastModified;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByPhase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get sortByPhase;

  /// No description provided for @sortByCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get sortByCreatedAt;

  /// No description provided for @sortByBpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get sortByBpm;

  /// No description provided for @monoLabel.
  ///
  /// In en, this message translates to:
  /// **'Mono'**
  String get monoLabel;

  /// No description provided for @monoToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle mono playback'**
  String get monoToggleTooltip;

  /// No description provided for @monoRequiresWav.
  ///
  /// In en, this message translates to:
  /// **'Mono mixing requires a WAV file'**
  String get monoRequiresWav;

  /// No description provided for @monoUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Could not create mono mix — unsupported format'**
  String get monoUnsupportedFormat;

  /// No description provided for @monoSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Mono switch failed: {error}'**
  String monoSwitchFailed(String error);

  /// No description provided for @analyzeLabel.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyzeLabel;

  /// No description provided for @reAnalyzeLabel.
  ///
  /// In en, this message translates to:
  /// **'Re-analyze'**
  String get reAnalyzeLabel;

  /// No description provided for @analysisRequiresWav.
  ///
  /// In en, this message translates to:
  /// **'Analysis requires a WAV file'**
  String get analysisRequiresWav;

  /// No description provided for @noResultsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No results for current filter'**
  String get noResultsForFilter;

  /// No description provided for @noResultsForFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters to find projects.'**
  String get noResultsForFilterHint;

  /// No description provided for @noProjectsFound.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get noProjectsFound;

  /// No description provided for @noProjectsFoundHint.
  ///
  /// In en, this message translates to:
  /// **'Add a scan root folder in settings to get started.'**
  String get noProjectsFoundHint;

  /// No description provided for @queueTab.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get queueTab;

  /// No description provided for @queueSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get queueSearchHint;

  /// No description provided for @queueNoPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get queueNoPendingTasks;

  /// No description provided for @queueNoPendingTasksHint.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks across your projects.'**
  String get queueNoPendingTasksHint;

  /// No description provided for @queueNoMatchingTasks.
  ///
  /// In en, this message translates to:
  /// **'No matching tasks'**
  String get queueNoMatchingTasks;

  /// No description provided for @queuePendingSummary.
  ///
  /// In en, this message translates to:
  /// **'{tasks} pending tasks in {projects} projects'**
  String queuePendingSummary(int tasks, int projects);

  /// No description provided for @appTitleWithVersion.
  ///
  /// In en, this message translates to:
  /// **'DAW Project Manager v{version}'**
  String appTitleWithVersion(String version);

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @renameProjectFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Project File'**
  String get renameProjectFileTitle;

  /// No description provided for @renameFileButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rename File'**
  String get renameFileButtonLabel;

  /// No description provided for @newFileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'New file name (without extension)'**
  String get newFileNameLabel;

  /// No description provided for @renameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A file named \"{name}\" already exists.'**
  String renameAlreadyExists(String name);

  /// No description provided for @renameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"{name}\"'**
  String renameSuccess(String name);

  /// No description provided for @renameFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename: {error}'**
  String renameFailed(String error);

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @nameInvalidCharacters.
  ///
  /// In en, this message translates to:
  /// **'Name cannot contain / \\ :'**
  String get nameInvalidCharacters;

  /// No description provided for @alsoRenameContainingFolder.
  ///
  /// In en, this message translates to:
  /// **'Also rename containing folder'**
  String get alsoRenameContainingFolder;

  /// No description provided for @renameButton.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameButton;

  /// No description provided for @previewMixdownFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview Mixdown Folder'**
  String get previewMixdownFolderTitle;

  /// No description provided for @previewMixdownFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subfolder name inside each project folder to check first when auto-detecting preview songs. Leave empty to use DAW defaults.'**
  String get previewMixdownFolderSubtitle;

  /// No description provided for @previewMixdownFolderHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mixdowns'**
  String get previewMixdownFolderHint;

  /// No description provided for @dawInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'DAW: {daw}'**
  String dawInfoLabel(String daw);

  /// No description provided for @bpmInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'BPM: {bpm}'**
  String bpmInfoLabel(String bpm);

  /// No description provided for @keyInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Key: {key}'**
  String keyInfoLabel(String key);

  /// No description provided for @audioFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Audio file not found'**
  String get audioFileNotFound;

  /// No description provided for @errorPlayingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error playing audio: {error}'**
  String errorPlayingAudio(String error);

  /// No description provided for @notificationTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test notifications to verify timezone and scheduling:'**
  String get notificationTestTitle;

  /// No description provided for @notificationSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send Now'**
  String get notificationSendNow;

  /// No description provided for @notificationSchedule30s.
  ///
  /// In en, this message translates to:
  /// **'Schedule +30s'**
  String get notificationSchedule30s;

  /// No description provided for @notificationShowDebugInfo.
  ///
  /// In en, this message translates to:
  /// **'Show Debug Info'**
  String get notificationShowDebugInfo;

  /// No description provided for @notificationRescheduleAll.
  ///
  /// In en, this message translates to:
  /// **'Re-schedule All'**
  String get notificationRescheduleAll;

  /// No description provided for @notificationTestSent.
  ///
  /// In en, this message translates to:
  /// **'✅ Test notification sent!'**
  String get notificationTestSent;

  /// No description provided for @notificationTestScheduled.
  ///
  /// In en, this message translates to:
  /// **'✅ Test notification scheduled for 30 seconds! Check console logs.'**
  String get notificationTestScheduled;

  /// No description provided for @notificationTestError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String notificationTestError(String error);

  /// No description provided for @notificationDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'🐛 Debug Information'**
  String get notificationDebugTitle;

  /// No description provided for @autoDetected.
  ///
  /// In en, this message translates to:
  /// **'Auto-detected'**
  String get autoDetected;

  /// No description provided for @matchedInDescription.
  ///
  /// In en, this message translates to:
  /// **'Matched in description'**
  String get matchedInDescription;

  /// No description provided for @relocateFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Relocate Folder'**
  String get relocateFolderDialogTitle;

  /// No description provided for @relocateFolderSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 project path updated} other{{count} project paths updated}}'**
  String relocateFolderSuccess(int count);

  /// No description provided for @customizeTabs.
  ///
  /// In en, this message translates to:
  /// **'Customize Tabs'**
  String get customizeTabs;

  /// No description provided for @customizeTabsDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose which tabs to show in the navigation bar. The Projects tab is always visible.'**
  String get customizeTabsDescription;

  /// No description provided for @keyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get keyboardShortcuts;

  /// No description provided for @shortcutGroupGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get shortcutGroupGlobal;

  /// No description provided for @shortcutGroupProjectsTable.
  ///
  /// In en, this message translates to:
  /// **'Projects Table (table must be focused)'**
  String get shortcutGroupProjectsTable;

  /// No description provided for @shortcutGroupReleasesTable.
  ///
  /// In en, this message translates to:
  /// **'Releases Table (table must be focused)'**
  String get shortcutGroupReleasesTable;

  /// No description provided for @shortcutGroupNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get shortcutGroupNavigation;

  /// No description provided for @shortcutFocusSearch.
  ///
  /// In en, this message translates to:
  /// **'Focus search bar'**
  String get shortcutFocusSearch;

  /// No description provided for @shortcutRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan project folders'**
  String get shortcutRescan;

  /// No description provided for @shortcutFocusTable.
  ///
  /// In en, this message translates to:
  /// **'Focus projects table'**
  String get shortcutFocusTable;

  /// No description provided for @shortcutPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play / pause preview song'**
  String get shortcutPlayPause;

  /// No description provided for @shortcutOpenInDaw.
  ///
  /// In en, this message translates to:
  /// **'Open project in DAW'**
  String get shortcutOpenInDaw;

  /// No description provided for @shortcutViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View project details'**
  String get shortcutViewDetails;

  /// No description provided for @shortcutOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Open project folder'**
  String get shortcutOpenFolder;

  /// No description provided for @shortcutNavigateRows.
  ///
  /// In en, this message translates to:
  /// **'Navigate rows'**
  String get shortcutNavigateRows;

  /// No description provided for @shortcutEditCell.
  ///
  /// In en, this message translates to:
  /// **'Open project details'**
  String get shortcutEditCell;

  /// No description provided for @shortcutViewRelease.
  ///
  /// In en, this message translates to:
  /// **'View release details'**
  String get shortcutViewRelease;

  /// No description provided for @shortcutGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get shortcutGoBack;

  /// No description provided for @shortcutGroupProjectsTableStandardMode.
  ///
  /// In en, this message translates to:
  /// **'Standard mode'**
  String get shortcutGroupProjectsTableStandardMode;

  /// No description provided for @shortcutGroupProjectsTableSessionMode.
  ///
  /// In en, this message translates to:
  /// **'Session mode'**
  String get shortcutGroupProjectsTableSessionMode;

  /// No description provided for @shortcutToggleSession.
  ///
  /// In en, this message translates to:
  /// **'Start / End session'**
  String get shortcutToggleSession;

  /// No description provided for @shortcutGroupPreviewPlayer.
  ///
  /// In en, this message translates to:
  /// **'Preview Player'**
  String get shortcutGroupPreviewPlayer;

  /// No description provided for @shortcutPlayerPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play / pause'**
  String get shortcutPlayerPlayPause;

  /// No description provided for @shortcutPlayerSeek5.
  ///
  /// In en, this message translates to:
  /// **'Seek ±5 seconds'**
  String get shortcutPlayerSeek5;

  /// No description provided for @shortcutPlayerSeek30.
  ///
  /// In en, this message translates to:
  /// **'Seek ±30 seconds'**
  String get shortcutPlayerSeek30;

  /// No description provided for @startupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to DAW Project Manager'**
  String get startupDialogTitle;

  /// No description provided for @startupDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get started by adding your project folder or restoring a backup from Google Drive.'**
  String get startupDialogSubtitle;

  /// No description provided for @startupAddFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Project Folder'**
  String get startupAddFolderTitle;

  /// No description provided for @startupAddFolderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a folder containing your DAW projects.'**
  String get startupAddFolderSubtitle;

  /// No description provided for @startupGoogleDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Google Drive Backup'**
  String get startupGoogleDriveTitle;

  /// No description provided for @startupGoogleDriveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore your projects from a Google Drive backup.'**
  String get startupGoogleDriveSubtitle;

  /// No description provided for @startupDontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show this on startup'**
  String get startupDontShowAgain;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all profiles, projects, releases, playlists, and settings from this device.'**
  String get deleteAllDataSubtitle;

  /// No description provided for @deleteAllDataConfirm1Title.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data?'**
  String get deleteAllDataConfirm1Title;

  /// No description provided for @deleteAllDataConfirm1Message.
  ///
  /// In en, this message translates to:
  /// **'This will permanently erase all profiles, projects, releases, playlists, and settings from this device. Your Google Drive backup (if any) will not be affected.'**
  String get deleteAllDataConfirm1Message;

  /// No description provided for @deleteAllDataConfirm2Title.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get deleteAllDataConfirm2Title;

  /// No description provided for @deleteAllDataConfirm2Message.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The app will return to its initial state.'**
  String get deleteAllDataConfirm2Message;

  /// No description provided for @deleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get deleteEverything;

  /// No description provided for @allDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data has been deleted.'**
  String get allDataDeleted;

  /// No description provided for @newerExportFound.
  ///
  /// In en, this message translates to:
  /// **'Newer Export Found'**
  String get newerExportFound;

  /// No description provided for @newerExportFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'A newer file was found in the same folder:\n{filename}\n\nReplace the preview song?'**
  String newerExportFoundMessage(String filename);

  /// No description provided for @replaceAndPlay.
  ///
  /// In en, this message translates to:
  /// **'Replace & Play'**
  String get replaceAndPlay;

  /// No description provided for @keepCurrent.
  ///
  /// In en, this message translates to:
  /// **'Keep Current'**
  String get keepCurrent;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get autoBackup;

  /// No description provided for @autoBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically upload a backup to Google Drive at the selected interval.'**
  String get autoBackupDescription;

  /// No description provided for @autoBackupInterval.
  ///
  /// In en, this message translates to:
  /// **'Backup interval'**
  String get autoBackupInterval;

  /// No description provided for @autoBackupOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get autoBackupOff;

  /// No description provided for @autoBackupEvery30Min.
  ///
  /// In en, this message translates to:
  /// **'Every 30 minutes'**
  String get autoBackupEvery30Min;

  /// No description provided for @autoBackupHourly.
  ///
  /// In en, this message translates to:
  /// **'Every hour'**
  String get autoBackupHourly;

  /// No description provided for @autoBackupEvery6Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 6 hours'**
  String get autoBackupEvery6Hours;

  /// No description provided for @autoBackupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get autoBackupDaily;

  /// No description provided for @autoBackupNextBackup.
  ///
  /// In en, this message translates to:
  /// **'Next backup: {time}'**
  String autoBackupNextBackup(String time);

  /// No description provided for @playerTitle.
  ///
  /// In en, this message translates to:
  /// **'Music Player'**
  String get playerTitle;

  /// No description provided for @playerToggleQueue.
  ///
  /// In en, this message translates to:
  /// **'Toggle queue'**
  String get playerToggleQueue;

  /// No description provided for @playerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tracks…'**
  String get playerSearchHint;

  /// No description provided for @playerTrackCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String playerTrackCount(int count);

  /// No description provided for @playerTrackCountFiltered.
  ///
  /// In en, this message translates to:
  /// **'{filtered}/{total}'**
  String playerTrackCountFiltered(int filtered, int total);

  /// No description provided for @playerNoPreviewSongs.
  ///
  /// In en, this message translates to:
  /// **'No preview songs found.\nOpen a project and set a preview song.'**
  String get playerNoPreviewSongs;

  /// No description provided for @playerNoTracksMatch.
  ///
  /// In en, this message translates to:
  /// **'No tracks match\n\"{query}\"'**
  String playerNoTracksMatch(String query);

  /// No description provided for @playerDoubleClickToPlay.
  ///
  /// In en, this message translates to:
  /// **'Double-click a track to start playing'**
  String get playerDoubleClickToPlay;

  /// No description provided for @playerSingleClickToPreview.
  ///
  /// In en, this message translates to:
  /// **'Single-click to preview in the player bar below'**
  String get playerSingleClickToPreview;

  /// No description provided for @playerQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get playerQueueTitle;

  /// No description provided for @playerClearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue'**
  String get playerClearQueue;

  /// No description provided for @playerQueueEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Double-click a track to start,\nor drag tracks here to queue.'**
  String get playerQueueEmptyHint;

  /// No description provided for @playerPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get playerPrev;

  /// No description provided for @playerNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get playerNext;

  /// No description provided for @playerGoToProject.
  ///
  /// In en, this message translates to:
  /// **'Go to project'**
  String get playerGoToProject;

  /// No description provided for @playerAddToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get playerAddToQueue;

  /// No description provided for @playerRemoveFromQueue.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get playerRemoveFromQueue;

  /// No description provided for @playerDismissDetail.
  ///
  /// In en, this message translates to:
  /// **'Dismiss detail'**
  String get playerDismissDetail;

  /// No description provided for @playerNotes.
  ///
  /// In en, this message translates to:
  /// **'NOTES'**
  String get playerNotes;

  /// No description provided for @playerTasks.
  ///
  /// In en, this message translates to:
  /// **'TASKS'**
  String get playerTasks;

  /// No description provided for @playerNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet.'**
  String get playerNoTasks;

  /// No description provided for @playerAddTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Add a task…'**
  String get playerAddTaskHint;

  /// No description provided for @playerCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String playerCompletedTasks(int count);

  /// No description provided for @playerPreviousTrack.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get playerPreviousTrack;

  /// No description provided for @playerNextTrack.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get playerNextTrack;

  /// No description provided for @playerOpenProject.
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get playerOpenProject;

  /// No description provided for @playerRepeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get playerRepeatAll;

  /// No description provided for @playerShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get playerShuffle;

  /// No description provided for @volumeMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get volumeMute;

  /// No description provided for @volumeUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get volumeUnmute;

  /// No description provided for @totalWorkTime.
  ///
  /// In en, this message translates to:
  /// **'Total work: {time}'**
  String totalWorkTime(String time);

  /// No description provided for @sessionTime.
  ///
  /// In en, this message translates to:
  /// **'Session: {time}'**
  String sessionTime(String time);

  /// No description provided for @sessionHistory.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistory;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions recorded yet'**
  String get noSessionsYet;

  /// No description provided for @removeSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove session?'**
  String get removeSessionTitle;

  /// No description provided for @sessionTableDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sessionTableDate;

  /// No description provided for @sessionTableTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get sessionTableTime;

  /// No description provided for @sessionTableDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sessionTableDuration;

  /// No description provided for @sessionTableTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get sessionTableTotal;

  /// No description provided for @sessionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String sessionCount(int count);

  /// No description provided for @sessionByPhase.
  ///
  /// In en, this message translates to:
  /// **'Work by Phase'**
  String get sessionByPhase;

  /// No description provided for @tabPosition.
  ///
  /// In en, this message translates to:
  /// **'Tab position'**
  String get tabPosition;

  /// No description provided for @tabPositionTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get tabPositionTop;

  /// No description provided for @tabPositionLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get tabPositionLeft;

  /// No description provided for @updateAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateAvailableMessage(String version);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkForUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a new version of the app is available.'**
  String get checkForUpdatesDescription;

  /// No description provided for @checkNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkNow;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: v{version}'**
  String updateAvailable(String version);

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'App is up to date'**
  String get upToDate;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableVersion.
  ///
  /// In en, this message translates to:
  /// **'A new version {version} is ready.'**
  String updateAvailableVersion(String version);

  /// No description provided for @updateCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'You are running v{version}.'**
  String updateCurrentVersion(String version);

  /// No description provided for @viewUpdateDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewUpdateDetails;

  /// No description provided for @getOnMicrosoftStore.
  ///
  /// In en, this message translates to:
  /// **'Get on Microsoft Store'**
  String get getOnMicrosoftStore;

  /// No description provided for @downloadFromGitHub.
  ///
  /// In en, this message translates to:
  /// **'Download from GitHub'**
  String get downloadFromGitHub;

  /// No description provided for @updateWindowsInstructions.
  ///
  /// In en, this message translates to:
  /// **'Open the Microsoft Store and update DAW Project Manager, or click the button below.'**
  String get updateWindowsInstructions;

  /// No description provided for @updateMacInstructions.
  ///
  /// In en, this message translates to:
  /// **'Download the latest release from GitHub and replace the current app.'**
  String get updateMacInstructions;

  /// No description provided for @resetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Reset onboarding'**
  String get resetOnboarding;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to DAW Project Manager'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Organize all your music projects across every DAW in one place.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Theme'**
  String get onboardingThemeTitle;

  /// No description provided for @onboardingFoldersTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Project Folders'**
  String get onboardingFoldersTitle;

  /// No description provided for @onboardingFoldersBody.
  ///
  /// In en, this message translates to:
  /// **'Add the root folder where your DAW projects are stored.'**
  String get onboardingFoldersBody;

  /// No description provided for @onboardingDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Sync'**
  String get onboardingDriveTitle;

  /// No description provided for @onboardingDriveBody.
  ///
  /// In en, this message translates to:
  /// **'Optionally back up and sync project metadata to Google Drive.'**
  String get onboardingDriveBody;

  /// No description provided for @onboardingUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Checks'**
  String get onboardingUpdatesTitle;

  /// No description provided for @onboardingUpdatesBody.
  ///
  /// In en, this message translates to:
  /// **'Get notified when a new version is available.'**
  String get onboardingUpdatesBody;

  /// No description provided for @onboardingDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get onboardingDoneTitle;

  /// No description provided for @onboardingDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Start exploring your projects.'**
  String get onboardingDoneBody;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @dawSession.
  ///
  /// In en, this message translates to:
  /// **'DAW Session'**
  String get dawSession;

  /// No description provided for @clearDawSession.
  ///
  /// In en, this message translates to:
  /// **'Clear session'**
  String get clearDawSession;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @workTimerSection.
  ///
  /// In en, this message translates to:
  /// **'Work Session Reminders'**
  String get workTimerSection;

  /// No description provided for @workTimerSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified while working on a subscribed project'**
  String get workTimerSectionDesc;

  /// No description provided for @workTimerEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enable work session reminders'**
  String get workTimerEnabled;

  /// No description provided for @workTimerIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Notify every'**
  String get workTimerIntervalLabel;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @workTimerNotifBody.
  ///
  /// In en, this message translates to:
  /// **'You have been working for {time}'**
  String workTimerNotifBody(String time);

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @lastModifiedColors.
  ///
  /// In en, this message translates to:
  /// **'Last Modified date colors'**
  String get lastModifiedColors;

  /// No description provided for @lastModifiedColorsDescription.
  ///
  /// In en, this message translates to:
  /// **'Colors the Last Modified date based on age and status. Green = Finished. Older dates fade from yellow to red — stronger red means the project hasn\'t been touched in longer.'**
  String get lastModifiedColorsDescription;

  /// No description provided for @sessionMode.
  ///
  /// In en, this message translates to:
  /// **'Session mode'**
  String get sessionMode;

  /// No description provided for @sessionModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to a project before launching, to track work time and manage it from the toolbar'**
  String get sessionModeDescription;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get endSession;

  /// No description provided for @switchSession.
  ///
  /// In en, this message translates to:
  /// **'Switch session'**
  String get switchSession;

  /// No description provided for @switchSessionBody.
  ///
  /// In en, this message translates to:
  /// **'Stop the current session and start a new one?'**
  String get switchSessionBody;

  /// No description provided for @switchSessionCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {project}'**
  String switchSessionCurrent(String project);

  /// No description provided for @switchSessionNew.
  ///
  /// In en, this message translates to:
  /// **'New: {project}'**
  String switchSessionNew(String project);

  /// No description provided for @sessionDuration.
  ///
  /// In en, this message translates to:
  /// **'Session time'**
  String get sessionDuration;

  /// No description provided for @scanModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan mode:'**
  String get scanModeLabel;

  /// No description provided for @scanModeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Mode'**
  String get scanModeSectionTitle;

  /// No description provided for @scanModeSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Controls how projects in each folder are displayed in the table — as a plain flat list or grouped by subfolder.'**
  String get scanModeSectionDescription;

  /// No description provided for @scanModeFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get scanModeFlat;

  /// No description provided for @scanModeSmartFolder.
  ///
  /// In en, this message translates to:
  /// **'Smart Folder'**
  String get scanModeSmartFolder;

  /// No description provided for @scanModeFlatDescription.
  ///
  /// In en, this message translates to:
  /// **'Shows every project as a flat list. Simple and fast.'**
  String get scanModeFlatDescription;

  /// No description provided for @scanModeSmartFolderDescription.
  ///
  /// In en, this message translates to:
  /// **'Groups projects by folder when a folder contains more than one project.'**
  String get scanModeSmartFolderDescription;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @suggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestionsLabel;

  /// No description provided for @suggestionsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get suggestionsRefresh;

  /// No description provided for @suggestionsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No suggestions right now. Tap Refresh to reset dismissed items.'**
  String get suggestionsEmptyState;

  /// No description provided for @showSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Show suggestions'**
  String get showSuggestions;

  /// No description provided for @showSuggestionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Show smart suggestions in the toolbar when no session is running'**
  String get showSuggestionsDescription;

  /// No description provided for @onboardingSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Suggestions'**
  String get onboardingSuggestionsTitle;

  /// No description provided for @onboardingSuggestionsBody.
  ///
  /// In en, this message translates to:
  /// **'Get personalized project recommendations in the toolbar while you work'**
  String get onboardingSuggestionsBody;

  /// No description provided for @onboardingSessionModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Mode'**
  String get onboardingSessionModeTitle;

  /// No description provided for @onboardingSessionModeBody.
  ///
  /// In en, this message translates to:
  /// **'Start focused work sessions and automatically track time spent on each project'**
  String get onboardingSessionModeBody;

  /// No description provided for @suggestionsFeatureDeadlines.
  ///
  /// In en, this message translates to:
  /// **'Deadline reminders for upcoming projects'**
  String get suggestionsFeatureDeadlines;

  /// No description provided for @suggestionsFeatureResume.
  ///
  /// In en, this message translates to:
  /// **'Resume the last project you worked on'**
  String get suggestionsFeatureResume;

  /// No description provided for @suggestionsFeatureRecentlyModified.
  ///
  /// In en, this message translates to:
  /// **'Continue recently modified tracks'**
  String get suggestionsFeatureRecentlyModified;

  /// No description provided for @suggestionsEnableToggle.
  ///
  /// In en, this message translates to:
  /// **'Enable smart suggestions'**
  String get suggestionsEnableToggle;

  /// No description provided for @canBeChangedInSettings.
  ///
  /// In en, this message translates to:
  /// **'Can be changed later in Settings'**
  String get canBeChangedInSettings;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createProject;

  /// No description provided for @createProjectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create a new project folder'**
  String get createProjectTooltip;

  /// No description provided for @createProjectSelectFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Location'**
  String get createProjectSelectFolder;

  /// No description provided for @createProjectSelectFolderHint.
  ///
  /// In en, this message translates to:
  /// **'Select which project folder to create the new project in'**
  String get createProjectSelectFolderHint;

  /// No description provided for @createProjectNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name Your Project'**
  String get createProjectNameTitle;

  /// No description provided for @createProjectNameHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a naming scheme for the new project folder'**
  String get createProjectNameHint;

  /// No description provided for @createProjectSchemeArtistTrack.
  ///
  /// In en, this message translates to:
  /// **'Artist — Track'**
  String get createProjectSchemeArtistTrack;

  /// No description provided for @createProjectSchemeCollab.
  ///
  /// In en, this message translates to:
  /// **'Collab'**
  String get createProjectSchemeCollab;

  /// No description provided for @createProjectSchemeDate.
  ///
  /// In en, this message translates to:
  /// **'Date — Track'**
  String get createProjectSchemeDate;

  /// No description provided for @createProjectSchemeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get createProjectSchemeCustom;

  /// No description provided for @createProjectArtistName.
  ///
  /// In en, this message translates to:
  /// **'Artist Name'**
  String get createProjectArtistName;

  /// No description provided for @createProjectTrackName.
  ///
  /// In en, this message translates to:
  /// **'Track Name'**
  String get createProjectTrackName;

  /// No description provided for @createProjectCustomName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get createProjectCustomName;

  /// No description provided for @createProjectAddArtist.
  ///
  /// In en, this message translates to:
  /// **'Add artist'**
  String get createProjectAddArtist;

  /// No description provided for @createProjectSelectDaw.
  ///
  /// In en, this message translates to:
  /// **'Open in DAW'**
  String get createProjectSelectDaw;

  /// No description provided for @createProjectSelectDawHint.
  ///
  /// In en, this message translates to:
  /// **'Choose which DAW to open to start working on this project'**
  String get createProjectSelectDawHint;

  /// No description provided for @createProjectDetectDaws.
  ///
  /// In en, this message translates to:
  /// **'Detect Installed DAWs'**
  String get createProjectDetectDaws;

  /// No description provided for @createProjectSkipDaw.
  ///
  /// In en, this message translates to:
  /// **'Just create the folder'**
  String get createProjectSkipDaw;

  /// No description provided for @createProjectNoDawsFound.
  ///
  /// In en, this message translates to:
  /// **'No DAWs were found on this system. The folder will still be created.'**
  String get createProjectNoDawsFound;

  /// No description provided for @createProjectCreateOnly.
  ///
  /// In en, this message translates to:
  /// **'Create Folder'**
  String get createProjectCreateOnly;

  /// No description provided for @createProjectCreateAndOpen.
  ///
  /// In en, this message translates to:
  /// **'Create & Open'**
  String get createProjectCreateAndOpen;

  /// No description provided for @createProjectFolderExists.
  ///
  /// In en, this message translates to:
  /// **'A folder with this name already exists'**
  String get createProjectFolderExists;

  /// No description provided for @createProjectInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Folder name contains invalid characters'**
  String get createProjectInvalidChars;

  /// No description provided for @createProjectError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create folder'**
  String get createProjectError;

  /// No description provided for @createProjectIncludeDate.
  ///
  /// In en, this message translates to:
  /// **'Include date prefix'**
  String get createProjectIncludeDate;

  /// No description provided for @createProjectCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder Created'**
  String get createProjectCreatedTitle;

  /// No description provided for @createProjectCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your project folder has been created:'**
  String get createProjectCreatedMessage;

  /// No description provided for @createProjectCopyName.
  ///
  /// In en, this message translates to:
  /// **'Copy Folder Name'**
  String get createProjectCopyName;

  /// No description provided for @createProjectNameCopied.
  ///
  /// In en, this message translates to:
  /// **'Folder name copied'**
  String get createProjectNameCopied;

  /// No description provided for @createProjectTrackSession.
  ///
  /// In en, this message translates to:
  /// **'Track session from now'**
  String get createProjectTrackSession;

  /// No description provided for @pendingFolderSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Work Session Detected'**
  String get pendingFolderSessionTitle;

  /// No description provided for @pendingFolderSessionBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve worked on \"{projectName}\" for {duration}.'**
  String pendingFolderSessionBody(String projectName, String duration);

  /// No description provided for @pendingFolderSessionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue Session'**
  String get pendingFolderSessionContinue;

  /// No description provided for @pendingFolderSessionEndRecord.
  ///
  /// In en, this message translates to:
  /// **'End & Record'**
  String get pendingFolderSessionEndRecord;

  /// No description provided for @activeSessionSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Already Active'**
  String get activeSessionSwitchTitle;

  /// No description provided for @activeSessionSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'A session is running for \"{current}\". Switch to \"{next}\" and save the current session?'**
  String activeSessionSwitchBody(String current, String next);

  /// No description provided for @activeSessionSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get activeSessionSwitch;

  /// No description provided for @pendingProjectWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for project file…'**
  String get pendingProjectWaiting;

  /// No description provided for @pendingProjectDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete empty folder'**
  String get pendingProjectDelete;

  /// No description provided for @pendingProjectDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Folder?'**
  String get pendingProjectDeleteTitle;

  /// No description provided for @pendingProjectDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{folderName}\" and its contents?'**
  String pendingProjectDeleteBody(String folderName);

  /// No description provided for @pendingProjectDismiss.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking this folder'**
  String get pendingProjectDismiss;

  /// No description provided for @pendingProjectDismissTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop Tracking?'**
  String get pendingProjectDismissTitle;

  /// No description provided for @pendingProjectDismissKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep Folder'**
  String get pendingProjectDismissKeep;

  /// No description provided for @pendingProjectDismissDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete & Dismiss'**
  String get pendingProjectDismissDelete;

  /// No description provided for @pendingProjectDeleteNotEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Folder is not empty'**
  String get pendingProjectDeleteNotEmptyTitle;

  /// No description provided for @pendingProjectDeleteNotEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'\"{folderName}\" contains files. Delete everything permanently?'**
  String pendingProjectDeleteNotEmptyBody(String folderName);

  /// No description provided for @pendingProjectRefresh.
  ///
  /// In en, this message translates to:
  /// **'Check for project file'**
  String get pendingProjectRefresh;

  /// No description provided for @pendingProjectNotFound.
  ///
  /// In en, this message translates to:
  /// **'No project file found yet'**
  String get pendingProjectNotFound;

  /// No description provided for @phases.
  ///
  /// In en, this message translates to:
  /// **'Phases'**
  String get phases;

  /// No description provided for @phasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, remove, and reorder project phases'**
  String get phasesSubtitle;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetToDefaults;

  /// No description provided for @addPhase.
  ///
  /// In en, this message translates to:
  /// **'Add phase'**
  String get addPhase;

  /// No description provided for @phaseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Phase name'**
  String get phaseNameHint;

  /// No description provided for @phaseDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'A phase with that name already exists'**
  String get phaseDuplicateError;

  /// No description provided for @deletePhaseWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 project uses this phase} other{{count} projects use this phase}}'**
  String deletePhaseWarning(int count);

  /// No description provided for @selectPhaseColor.
  ///
  /// In en, this message translates to:
  /// **'Select color'**
  String get selectPhaseColor;

  /// No description provided for @markAsFinished.
  ///
  /// In en, this message translates to:
  /// **'Mark as finished phase'**
  String get markAsFinished;

  /// No description provided for @resetPhasesWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 project uses a phase that will no longer exist.} other{{count} projects use phases that will no longer exist.}}'**
  String resetPhasesWarning(int count);

  /// No description provided for @resetPhasesWarningNote.
  ///
  /// In en, this message translates to:
  /// **'Those projects will keep their current status but won\'t appear in phase filters. You can always re-add those phases later.'**
  String get resetPhasesWarningNote;

  /// No description provided for @camelotGenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Mix'**
  String get camelotGenerateButton;

  /// No description provided for @camelotDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Camelot Mix'**
  String get camelotDialogTitle;

  /// No description provided for @camelotDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Orders your tracks by harmonic key compatibility using the Camelot wheel. BPM proximity is used as a tiebreaker within compatible keys.'**
  String get camelotDialogDescription;

  /// No description provided for @camelotEligibleTracks.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks eligible (key set)'**
  String camelotEligibleTracks(int count);

  /// No description provided for @camelotSkippedTracks.
  ///
  /// In en, this message translates to:
  /// **'{count} will be skipped (no key set)'**
  String camelotSkippedTracks(int count);

  /// No description provided for @camelotNoEligibleTracks.
  ///
  /// In en, this message translates to:
  /// **'No tracks have a musical key set. Open a project and set its key to use this feature.'**
  String get camelotNoEligibleTracks;

  /// No description provided for @camelotGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get camelotGenerate;

  /// No description provided for @camelotQueueGenerated.
  ///
  /// In en, this message translates to:
  /// **'Queue filled with {count} harmonically ordered tracks'**
  String camelotQueueGenerated(int count);

  /// No description provided for @camelotWheelGuideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Camelot wheel guide'**
  String get camelotWheelGuideTooltip;

  /// No description provided for @camelotWheelGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Camelot Wheel Guide'**
  String get camelotWheelGuideTitle;

  /// No description provided for @camelotGuideRingsTitle.
  ///
  /// In en, this message translates to:
  /// **'The Rings'**
  String get camelotGuideRingsTitle;

  /// No description provided for @camelotGuideRingsBody.
  ///
  /// In en, this message translates to:
  /// **'Inner ring (A)  →  minor keys\nOuter ring (B)  →  major keys'**
  String get camelotGuideRingsBody;

  /// No description provided for @camelotGuideNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Numbers 1–12'**
  String get camelotGuideNumbersTitle;

  /// No description provided for @camelotGuideNumbersBody.
  ///
  /// In en, this message translates to:
  /// **'Positions arranged clockwise. Each number represents a harmonic neighbourhood — neighbours share strong tonal relationships.'**
  String get camelotGuideNumbersBody;

  /// No description provided for @camelotGuideColoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Colour Guide'**
  String get camelotGuideColoursTitle;

  /// No description provided for @camelotGuideColoursBody.
  ///
  /// In en, this message translates to:
  /// **'● Bright  →  your song\'s key\n● Softly lit  →  compatible for mixing\n● Dimmed  →  avoid for smooth mixing'**
  String get camelotGuideColoursBody;

  /// No description provided for @camelotGuideTransitionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Compatible Transitions'**
  String get camelotGuideTransitionsTitle;

  /// No description provided for @camelotGuideTransitionsBody.
  ///
  /// In en, this message translates to:
  /// **'8A → 8B  (same number, switch ring)\n  Relative major / minor — virtually seamless.\n\n8A → 7A or 9A  (±1, same ring)\n  Adjacent key — smooth, subtle change.\n\n8A → 1A or 3A  (±7, same ring)\n  Energy boost or drop — more dramatic shift.'**
  String get camelotGuideTransitionsBody;

  /// No description provided for @playerMixSuggestions.
  ///
  /// In en, this message translates to:
  /// **'MIX SUGGESTIONS'**
  String get playerMixSuggestions;

  /// Title for the mobile player page
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// No description provided for @noPreviewSongsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No preview songs available'**
  String get noPreviewSongsAvailable;

  /// Queue panel title - tracks coming up next
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get upNext;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
