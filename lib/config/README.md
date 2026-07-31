# OAuth Client Configuration

This directory contains the app's Google OAuth client config: a desktop
client ID, a desktop client secret, and an Android web client ID.

The client secret genuinely is required — this was tried and reverted. A
PKCE-only (RFC 7636), secretless desktop flow was implemented and tested
against a live Google sign-in; Google's token endpoint rejected it with
`"error": "invalid_request", "error_description": "client_secret is missing."`.
Google's docs list `client_secret` as "not applicable" only for Android/iOS/
Chrome-app OAuth client types — not "Desktop app", which is what this app is
registered as — and PKCE doesn't change that for this client type. See
`lib/services/google_drive_sync_service.dart`'s `_exchangeDesktopCode` and
`GoogleDriveSyncService.isSupported` for the full account of this.

**Linux is the one exception**: Google Drive sync isn't offered there at
all (`GoogleDriveSyncService.isSupported` is `false` on Linux), specifically
*because* of the client secret requirement above — Flathub's build sandbox
has no way to keep a secret out of the public submission repo, and shipping
it that broadly wasn't acceptable. So Linux/Flatpak builds don't need any
real values here at all; see `flatpak/README.md`.

## Files

- `oauth_config.dart.template` - Template file (versioned, safe to commit)
- `oauth_config.dart` - Generated file (NOT versioned locally)

## Local Development

1. Copy the template file:
   ```bash
   cp lib/config/oauth_config.dart.template lib/config/oauth_config.dart
   ```

2. Edit `lib/config/oauth_config.dart` and replace the `{{DESKTOP_CLIENT_ID}}`/`{{DESKTOP_CLIENT_SECRET}}`/`{{ANDROID_WEB_CLIENT_ID}}` placeholders with your actual values.

   **OR** use the injection script:
   ```bash
   # PowerShell (Windows)
   .\scripts\inject_oauth_config.ps1 -DesktopClientId "id" -DesktopClientSecret "secret" -AndroidWebClientId "id"

   # Bash (Linux/Mac)
   ./scripts/inject_oauth_config.sh -d "id" -s "secret" -a "id"
   ```

## CI/CD (GitHub Actions)

Windows, macOS, and Android builds inject real values from GitHub Actions secrets:
- Secret names: `DESKTOP_CLIENT_ID`, `DESKTOP_CLIENT_SECRET`, `ANDROID_WEB_CLIENT_ID`
- The build workflow injects them using the scripts above

The Linux (`build_linux`) and Flatpak (`build_flatpak`) CI jobs don't use any
of this — they copy `oauth_config.dart.template` straight to `oauth_config.dart`
with no substitution, since Drive sync is compiled in (it's a plain import,
not conditional on platform) but never reachable through the UI there.

## Notes

- The values are obfuscated using base64 encoding (basic obfuscation, not encryption) and decoded at runtime — this softens a casual source scan, it is not meant to defend against a determined attacker (per Google's own guidance, installed-app credentials aren't confidential in that sense anyway).
- Never commit `oauth_config.dart` to version control from local development.
- The template file is safe to commit — and on Linux/Flatpak, its literal placeholder text ends up as the compiled-in value, which is fine precisely because that code path is unreachable there.
