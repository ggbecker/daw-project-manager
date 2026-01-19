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

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

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
  /// **'Switch'**
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

  /// No description provided for @noReleasesFound.
  ///
  /// In en, this message translates to:
  /// **'No releases found'**
  String get noReleasesFound;

  /// No description provided for @deepScanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Deep Scan extracts full metadata from project files:\n• BPM (Beats Per Minute)\n• Musical Key\n• DAW Version\nThis is slower but provides complete information.'**
  String get deepScanTooltip;

  /// No description provided for @deepScanConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will scan all projects and extract full metadata (BPM, Key, DAW Version). This may take a while. Continue?'**
  String get deepScanConfirm;

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

  /// No description provided for @errorLoadingProjects.
  ///
  /// In en, this message translates to:
  /// **'Error loading projects: {error}'**
  String errorLoadingProjects(String error);

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

  /// No description provided for @failedToOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to open file: {error}'**
  String failedToOpenFile(String error);

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
  /// **'Click to browse artwork'**
  String get clickToBrowseArtwork;

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
  /// **'{count} days ago'**
  String dateDaysAgo(int count);

  /// No description provided for @dateWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} week{plural} ago'**
  String dateWeeksAgo(int count, String plural);

  /// No description provided for @dateMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} month{plural} ago'**
  String dateMonthsAgo(int count, String plural);

  /// No description provided for @dateYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} year{plural} ago'**
  String dateYearsAgo(int count, String plural);

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
