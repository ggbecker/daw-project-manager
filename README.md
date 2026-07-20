# DAW Project Manager

Cross-platform app for organizing and tracking music production projects. Scan your drives, manage metadata, track todos, group releases, and sync everything via Google Drive.

Supports **macOS**, **Windows**, **Android**, and **iOS**. Primary development target is macOS desktop.

---

## Supported DAWs

| DAW | Extension(s) |
|-----|-------------|
| Ableton Live | `.als`, `.alp` |
| Bitwig Studio | `.bwproject` |
| Cakewalk / Sonar | `.cwp`, `.wrk`, `.bun` |
| Cubase | `.cpr` |
| FL Studio | `.flp` |
| Logic Pro | `.logicx` |
| MAGDA | `.mgd` |
| Maschine | `.maschine`, `.maschine2` |
| Nuendo | `.npr` |
| Pro Tools | `.ptx`, `.pts` |
| Reaper | `.rpp` |
| Studio One | `.song` |
| Tracktion Waveform | `.tracktionedit`, `.tracktion` |
| Universal Audio LUNA | `.luna` |

---

## Getting Started

### Prerequisites

- **Flutter 3.41.9** (stable) — [install](https://docs.flutter.dev/get-started/install)
- Platform tooling:
  - **macOS / iOS** — Xcode (latest)
  - **Windows** — Visual Studio with the "Desktop development with C++" workload
  - **Android** — Android Studio (latest)

### Install and generate

```bash
git clone <repo-url>
cd daw_project_manager

flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
flutter run -d macos       # macOS
flutter run -d windows     # Windows
flutter run -d <device-id> # Android or iOS — list with: flutter devices
```

### Google Drive sync (optional)

Drive sync requires OAuth credentials injected into `lib/config/secrets.dart` (not versioned).

**Quickest way — use the setup script:**

```bash
# macOS / Linux
./scripts/setup_local_secret.sh

# Windows
.\scripts\setup_local_secret.ps1
```

The script prompts for your Google Cloud OAuth credentials (`DESKTOP_CLIENT_ID`, `DESKTOP_CLIENT_SECRET`, `ANDROID_WEB_CLIENT_ID`) and writes the file for you. Without it the app runs normally; only Drive features won't authenticate.

---

## Project Structure

```
lib/
├── models/        Hive data models (MusicProject, Release, …)
├── providers/     Riverpod providers and state
├── repository/    Hive box management and data access
├── services/      Scanner, metadata extractor, Drive sync, notifications
├── ui/            Pages: dashboard, project detail, releases, queue, stats
└── utils/         Search, platform helpers, file launcher
```

---

## Common Commands

| Task | Command |
|------|---------|
| Run all tests | `flutter test` |
| Regenerate Hive adapters | `dart run build_runner build --delete-conflicting-outputs` |
| Regenerate localization | `flutter gen-l10n` |
| Add a UI string | Edit `lib/l10n/app_en.arb`, run `flutter gen-l10n` |

---

## Releasing

Push a version tag to trigger the CI release workflow:

```bash
git tag v1.2.3
git push origin v1.2.3
```

CI outputs: macOS `.dmg`, Windows `.msix`, Android `.apk` and `.aab`.

Required GitHub secrets: `DESKTOP_CLIENT_ID`, `DESKTOP_CLIENT_SECRET`, `ANDROID_WEB_CLIENT_ID`.
