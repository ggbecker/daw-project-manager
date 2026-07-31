# CLAUDE.md — DAW Project Manager

Instructions for AI assistants working on this codebase.

---

## Non-negotiables

### Tests are part of every task
- Every bug fix must include a regression test that would have caught the bug.
- Every new feature must include tests covering its logic in full.
- Run `flutter test` before every commit — only commit if all tests pass.
- If logic is too deep in the widget tree to unit test, write the closest possible test (model/service/repository level) and note explicitly what cannot be automated.

### Always use AppLocalizations for UI strings
- Never hardcode user-visible text in widget trees.
- Any label, tooltip, snackbar message, dialog text, or button label must have a key in `lib/l10n/app_en.arb` and be referenced via `AppLocalizations.of(context)!.someKey`.
- Add the key to all locale ARB files, then run `flutter gen-l10n`.
- The app ships in 9 languages — hardcoded strings silently break all non-English users.
- `app_pt.arb` is Brazilian Portuguese only — there is a single Portuguese locale for this app, and it targets Brazil. Never introduce European Portuguese spelling or vocabulary (e.g. "ficheiro", "deteção"/"detetar", "descarregar", "ecrã", "utilizador", "está a fazer"-style progressive) — use the Brazilian equivalent instead (e.g. "arquivo", "detecção"/"detectar", "baixar", "tela", "usuário", "está fazendo"). When adding or editing a `pt` string, match the vocabulary already established in the rest of `app_pt.arb`.

### New model fields must be evaluated for Drive sync AND local backup
- When adding a field to `MusicProject` (or any synced model), decide: is this user-generated data or a device-local preference?
- **User data** (metadata, timers, todos, paths) → add to `_serializeProject` AND `_deserializeProject` in `lib/services/google_drive_sync_service.dart`. If skipped, the field is silently lost on every Drive restore.
- **Device-local settings** (theme, layout, update checks) → do NOT sync. `AppSettings` fields are generally device-local.
- Also check `lib/services/backup_service.dart` (local file export/import) for the same question, for any *global* (non-per-profile) data — `TodoTemplate`, `ProjectTemplate`, `TemplateRoot`, custom mixdown folder names, phase settings. This is Linux's only backup path (see below), so a field skipped here is a field Linux users can never back up at all, not just "won't survive a Drive restore."

### Google Drive sync is not offered on Linux
- `GoogleDriveSyncService.isSupported` is `false` on Linux, `true` everywhere else. Every UI entry point to `GoogleDriveSyncPage` (dashboard, profile page, startup dialog, tray menu) is gated on it — don't add a new one without the same gate.
- Why: the desktop OAuth flow requires a client secret (confirmed against a live Google sign-in attempt — PKCE alone isn't accepted for this app's "Desktop app" OAuth client type; see the long comment on `_desktopClientSecret` in `google_drive_sync_service.dart`). Flathub's build sandbox has no secret-injection mechanism, so shipping the secret there would mean committing it in the open in the public Flathub submission repo. Not offering the feature was chosen over that.
- Linux/Flatpak builds compile `lib/config/oauth_config.dart` from the committed template's placeholder text directly (no real values, no GitHub secrets involved) — see `flatpak/README.md`.

---

## Architecture

### State management — Riverpod
- All providers live in `lib/providers/providers.dart`.
- Main data flow: `repositoryProvider` → `allProjectsStreamProvider` → `projectsProvider` (filtered/sorted) → UI.
- Search state is per-tab: `projectsSearchProvider`, `releasesSearchProvider`, `queueSearchProvider`, etc.

### Local persistence — Hive CE
- Models with `@HiveType` / `@HiveField` and a `part` directive (e.g. `Release`, `TodoTemplate`) use code-generated adapters — run `dart run build_runner build --delete-conflicting-outputs` after changing them.
- `MusicProject` and other models have manually written `TypeAdapter`s inline in their model file — `build_runner` skips these intentionally.
- Adapters are registered in `ProjectRepository` with `isAdapterRegistered` guards to prevent double-registration.

### Platform detection
- Use `MobileUtils.isMobile()` (from `lib/utils/mobile_utils.dart`) for mobile vs desktop checks — not `Platform.isAndroid` or `Platform.isIOS` directly.
- Desktop = macOS + Windows + Linux. Mobile = Android + iOS.
- Primary development and test target is **macOS**.
- Linux is otherwise a full desktop target, with one deliberate feature gap: Google Drive sync (see `GoogleDriveSyncService.isSupported` above).

### Themes
- Two active themes: `AppThemeType.neonDark` and `AppThemeType.classicDark`.
- `AppThemeType.studioLight` exists in the enum but is hidden from the UI until it is ready — do not expose it in menus or the theme switcher cycle.

---

## Common tasks

### Adding a new DAW
1. Add the file extension (with comment) to `ScannerService.supportedExtensions` in `lib/services/scanner_service.dart`.
2. Map the extension to a display name in `MetadataExtractor` (`lib/services/metadata_extractor.dart`).
3. Optionally add a logo asset and register it in the logo map in `dashboard_page.dart`.
4. Update the supported DAWs table in `README.md`.

### Adding a new UI string
1. Add the key + English value to `lib/l10n/app_en.arb`.
2. Add the same key to every other `app_<locale>.arb` file (use the English value as a placeholder if translation is pending).
3. Run `flutter gen-l10n` — generated code lands in `lib/generated/l10n/`.
4. Reference via `AppLocalizations.of(context)!.yourKey` — never import the generated file directly; it is re-exported from the package.

### Adding a new MusicProject field
1. Add a `@HiveField(N)` with the next available index.
2. Add a default value in the `MusicProjectAdapter.read()` for backwards compatibility with existing boxes.
3. Add the field to `copyWith()`.
4. Decide sync scope (see Non-negotiables above) and update `_serializeProject` / `_deserializeProject` if needed.
5. Update `TestFactories.makeProject()` in `test/helpers/test_factories.dart` to expose the field for tests.

---

## Key file locations

| What | Where |
|------|-------|
| Data models | `lib/models/` |
| Riverpod providers | `lib/providers/providers.dart` |
| Hive repository | `lib/repository/project_repository.dart` |
| File scanner | `lib/services/scanner_service.dart` |
| Metadata extractor (BPM, key, DAW version) | `lib/services/metadata_extractor.dart` |
| Google Drive sync (not available on Linux) | `lib/services/google_drive_sync_service.dart` |
| Local backup/restore (Linux's only backup path) | `lib/services/backup_service.dart` |
| Settings hub — single scrollable page, left nav jumps to section | `lib/ui/settings_page.dart` |
| Main dashboard | `lib/ui/dashboard_page.dart` |
| Project detail / editor | `lib/ui/project_detail_page.dart` |
| Localization strings (source of truth) | `lib/l10n/app_en.arb` |
| Theme definitions | `lib/ui/theme/` |
| Platform helpers | `lib/utils/mobile_utils.dart` |
| Test factories | `test/helpers/test_factories.dart` |
| OAuth client config (not versioned) | `lib/config/oauth_config.dart` |

---

## Codegen commands

```bash
# After changing Hive models with @HiveType / @HiveField
dart run build_runner build --delete-conflicting-outputs

# After adding or editing localization strings
flutter gen-l10n
```
