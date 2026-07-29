# Flatpak packaging

Target: submission to Flathub (not just a self-hosted `.flatpak` bundle), so
this has to satisfy Flathub's review bar — a reproducible, network-free
build, AppStream metadata, and minimal/justified sandbox permissions.

Everything here was authored on Windows, where none of the Flatpak tooling
can actually run. **Nothing in this directory has been build-tested yet.**
The steps below have to happen on Linux (a real machine or WSL2) before this
is submission-ready.

## Files in this directory

| File | Purpose |
|---|---|
| `com.bandpassrecords.dpm.yml` | The Flatpak manifest. Has two `# --- BEGIN generated ---` placeholders that need real content — see below. |
| `com.bandpassrecords.dpm.desktop` | Desktop entry (app menu, launcher, taskbar). |
| `com.bandpassrecords.dpm.metainfo.xml` | AppStream metadata Flathub uses for the store listing. Has a `TODO` on the screenshots section — see below. |
| `icons/com.bandpassrecords.dpm_{128,256}.png` | Derived from `app_icon.png`. No scalable/SVG source exists in the repo; Flathub accepts raster-only, but a vector icon is preferred if one ever gets made. |

## Outstanding blockers before this can be submitted

### 1. Domain verification (bandpassrecords.com)

The app ID `com.bandpassrecords.dpm` is a domain-based reverse-DNS ID, so
Flathub requires proving ownership of `bandpassrecords.com` before it will
publish the app (this happens *after* the PR is merged, via Flathub's "manage
app" verification flow — it doesn't block opening the submission PR, but
does block it going live).

Upload `flatpak/org.flatpak.VerifiedApps.txt` (already created in this
directory) to:

```
https://bandpassrecords.com/.well-known/org.flatpak.VerifiedApps.txt
```

Then, on the Flathub developer portal for this app, choose "Website"
verification and point it at `bandpassrecords.com` — it checks for that file.

### 2. Screenshots are 0-byte placeholders

`resources/screenshots/**/*.png` (see `resources/screenshots/README.md`) are
placeholder files, not real captures. The metainfo's `<screenshots>` block
currently points at `dashboard/dashboard-overview.png` on the `v2.6.1` tag —
Flathub's linter fetches that URL and will fail the submission on a broken
image. Capture real screenshots, replace the files in place, cut a new tag,
and update the tag in the screenshot URL (and in `<release>`/the manifest's
`git` source) to match.

### 3. Generate the two vendored-source files

Flathub builds are sandboxed with no network access, and `org.freedesktop.Sdk`
doesn't include Flutter — so the manifest needs every dependency pinned as a
hashed source up front: the Flutter SDK itself, plus every package in
`pubspec.lock`. Hand-writing that is impractical; use
[`flatpak-flutter`](https://github.com/TheAppgineer/flatpak-flutter), which
generates it from your `pubspec.lock` automatically. On a Linux machine (or
WSL2) with Python 3 and `flatpak`/`flatpak-builder` installed:

```bash
git clone https://github.com/TheAppgineer/flatpak-flutter.git
cd flatpak-flutter
# Check that project's README for the current invocation — flags have
# changed across versions. As of this writing it's driven by pointing it
# at the target repo/manifest and it emits flutter-sdk.json plus a pub
# package sources file next to it.
python3 flatpak-flutter.py --help
```

Drop the generated `flutter-sdk.json` and pubspec-sources file into this
directory, then uncomment/merge them into `com.bandpassrecords.dpm.yml` at
the two `# --- BEGIN generated ---` markers. The app module's
`build-options.append-path` may need adjusting to match wherever the
generated Flutter SDK module actually installs its `flutter` binary — check
the module the tool generates rather than trusting the placeholder path in
the manifest as-is.

## Local build/test (once the above is done, on Linux)

```bash
flatpak install flathub org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08
flatpak-builder --user --install build-dir flatpak/com.bandpassrecords.dpm.yml
flatpak run com.bandpassrecords.dpm
```

Things that can only be verified this way (not from Windows, not by reading
the code):

- **System tray icon** (`tray_manager`) — appindicator support inside a
  Flatpak sandbox is inconsistent across desktop environments; confirm it at
  least degrades gracefully where there's no `StatusNotifierWatcher` running.
- **Secure storage** (`flutter_secure_storage`) — needs a Secret Service
  provider (e.g. `gnome-keyring`) reachable through
  `--talk-name=org.freedesktop.secrets`; confirm Google Drive sign-in tokens
  actually persist across a restart.
- **Notifications** — confirm deadline reminders actually show up via
  `org.freedesktop.Notifications`.
- **Drag-and-drop** (`desktop_drop`) — there's no mature portal for DnD yet;
  worth confirming dropping a project folder onto the window still works
  sandboxed.

## Submitting to Flathub

Once it builds and runs locally: fork
[flathub/flathub](https://github.com/flathub/flathub), create a new
repository named `com.bandpassrecords.dpm` under the Flathub org (via their
"New app" request flow), push this manifest (with the generated sources
merged in) there, and open the PR. Their CI will build it and a human
reviewer will check the `finish-args` — be ready to justify `--share=network`
(Google Drive sync) and the D-Bus `--talk-name`s above if asked.
