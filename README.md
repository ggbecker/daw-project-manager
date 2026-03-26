# DAW Project Manager

A cross-platform app built with Flutter for organizing and tracking music production projects across multiple DAWs. Scan your drives, manage metadata, track tasks, group projects into releases, and keep your creative workflow under control.

**Primary target:** macOS desktop. Also supports Windows, Android, and iOS (with some features limited to desktop).

---

## Features

### Projects
- Scan one or more root directories and detect project files automatically
- Two-phase scanning: fast initial scan (DAW type + path), optional deep scan for full metadata (BPM, key, DAW version)
- Edit project metadata: display name, BPM, musical key, phase/status, notes, custom tags
- Per-project todo lists with templates
- Preview song playback with seek controls (←/→ = ±5s, Ctrl+←/→ = ±30s)
- Quick actions: open in DAW, open folder, play preview, view details
- Hide/unhide projects without deleting them
- Keyboard shortcuts in the project table (P/O/D/F for preview/open/details/folder)
- Fuzzy search across all projects

### Releases
- Group projects into releases with title, description, artwork, and release date
- Attach files to releases (stems, mixes, exports)
- Keyboard shortcut (Enter / D) to open release details

### Tasks (Queue)
- Cross-project view of all unfinished todo items
- Grouped by project with phase indicator and pending count badge
- Check off tasks directly from the queue without navigating to each project
- Fuzzy search across project names and task text

### Profiles
- Multiple user profiles, each with its own scan roots and project data
- Profile photo support
- Switch profiles from the toolbar

### Statistics
- Charts and summaries of your project library (phases, DAWs, activity)
- Searchable project stats

### Playlists *(Android/iOS only)*
- Create playlists from projects that have preview songs
- Playback in sequence with a built-in audio player

### Other
- Google Drive sync (backup/restore)
- Deadline tracking with notifications (Android)
- 9 UI languages: English, Portuguese, Spanish, French, Italian, German, Russian, Japanese, Chinese

---

## Supported DAWs

| DAW | Extension |
|-----|-----------|
| Ableton Live | `.als` |
| Bitwig Studio | `.bwproject` |
| Cubase | `.cpr` |
| FL Studio | `.flp` |
| Logic Pro | `.logicx` |
| Maschine / Maschine 2 | `.maschine`, `.maschine2` |
| Nuendo | `.npr` |
| Pro Tools | `.ptx` |
| Reaper | `.rpp` |
| Studio One | `.song` |

---

## Development Guide

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.41.3 (stable) |
| Dart | 3.11.1 |
| Xcode | Latest (for macOS/iOS builds) |
| Android Studio | Latest (for Android builds) |

Install Flutter: https://docs.flutter.dev/get-started/install

### Setup

```bash
# Clone the repo
git clone <repo-url>
cd daw-project-manager

# Install dependencies
flutter pub get

# Generate code (Hive adapters + l10n)
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

> **Google Drive credentials** — the app expects OAuth secrets injected at build time via `scripts/inject_secret.ps1`. For local development without Drive sync you can skip this; Drive features will simply not authenticate.

### Running

```bash
# macOS (primary target)
flutter run -d macos

# Android
flutter run -d <device-id>

# Windows
flutter run -d windows
```

### Project Structure

```
lib/
├── main.dart                  # App entry point, theme, global shortcuts
├── models/                    # Hive data models (MusicProject, Release, etc.)
├── providers/                 # Riverpod providers and state
├── repository/                # Hive box management and data access
├── services/
│   ├── scanner_service.dart       # File system scanning
│   ├── metadata_extractor.dart    # DAW file parsing (BPM, key, version)
│   ├── google_drive_sync_service.dart
│   ├── deadline_notification_service.dart
│   └── playlist_audio_service.dart
├── ui/
│   ├── dashboard_page.dart        # Main screen (projects table + tabs)
│   ├── project_detail_page.dart   # Project editor, metadata, todos, player
│   ├── releases_tab_page.dart     # Releases table
│   ├── queue_page.dart            # Cross-project pending tasks view
│   ├── statistics_page.dart       # Charts and library stats
│   ├── playlists_page.dart        # Playlist player (mobile only)
│   ├── profile_manager_page.dart  # Profile management
│   └── ...
└── utils/
    ├── search_utils.dart          # Fuzzy search (fuzzyMatchAll)
    ├── mobile_utils.dart          # Platform detection helpers
    └── file_launcher.dart         # Cross-platform file/app launching
```

### State Management

The app uses **Riverpod** throughout.

- All providers live in `lib/providers/providers.dart`
- Main data flow: `repositoryProvider` → `allProjectsStreamProvider` → `projectsProvider` (filtered/sorted) → UI
- Search state is kept in per-tab notifiers: `projectsSearchProvider`, `releasesSearchProvider`, `queueSearchProvider`, etc.

### Data Persistence

**Hive CE** (community edition drop-in for Hive 2.x) is used for all local storage.

- Models with code-generated adapters have a `.g.dart` file and a `part` directive (`Release`, `TodoTemplate`)
- All other models have manually written `TypeAdapter`s inline in their model file — `build_runner` skips them intentionally
- Adapters are registered in `ProjectRepository` with `isAdapterRegistered` guards to avoid double-registration
- The generated `hive_registrar.g.dart` extension registers all code-generated adapters on startup

After adding or changing a model field, re-run codegen:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Localization

Strings live in `lib/l10n/app_<locale>.arb`. The source of truth is `app_en.arb`.

After adding or editing strings:

```bash
flutter gen-l10n
```

Generated code lands in `lib/generated/l10n/`. Import `AppLocalizations` from there — never edit generated files directly.

### Adding a New DAW

1. Add the file extension to `ScannerService.supportedExtensions` in `lib/services/scanner_service.dart`
2. Map the extension to a display name in `MetadataExtractor` (`lib/services/metadata_extractor.dart`)
3. Optionally add a logo asset and register it in the logo map in `dashboard_page.dart`

### CI / CD

The GitHub Actions workflow (`.github/workflows/release.yml`) runs three jobs:

| Job | Trigger | Output |
|-----|---------|--------|
| `test_pr_build` | Pull request → `main` | Build check on Windows |
| `release_build_upload` | Push to `main` or version tag | macOS `.dmg` + Windows `.msix` as release assets |
| `build-android` | Push to `main` or version tag | Android `.apk` |

To cut a release, push a version tag:

```bash
git tag v1.2.3
git push origin v1.2.3
```

Required GitHub secrets: `DESKTOP_CLIENT_ID`, `DESKTOP_CLIENT_SECRET`, `ANDROID_WEB_CLIENT_ID` (Google OAuth for Drive sync).
