# Flatpak packaging

Target: submission to Flathub (not just a self-hosted `.flatpak` bundle), so
this has to satisfy Flathub's review bar — a reproducible, network-free
build, AppStream metadata, and minimal/justified sandbox permissions.

Everything here was authored on Windows, where none of the Flatpak tooling
can actually run — so the `build_flatpak` job in
`.github/workflows/release.yml` is the actual first test of this pipeline,
on every PR and tag push. It runs `flatpak-flutter` to vendor the Flutter SDK
and every `pubspec.lock` package as hashed sources, then builds
`com.bandpassrecords.dpm.yml` offline with `flatpak-builder` — the same shape
of build Flathub's own infrastructure will eventually run. `flatpak-flutter`'s
exact CLI/output conventions were taken from its README, not verified by
running it, so expect the first CI run to need a round of debugging from the
Actions log (the job is marked `continue-on-error` for exactly this reason —
it won't block the other platform builds while that happens).

## Files in this directory

| File | Purpose |
|---|---|
| `com.bandpassrecords.dpm.yml` | The Flatpak manifest — actually a *template* for `flatpak-flutter` (see above), not the final buildable manifest. |
| `com.bandpassrecords.dpm.desktop` | Desktop entry (app menu, launcher, taskbar). |
| `com.bandpassrecords.dpm.metainfo.xml` | AppStream metadata Flathub uses for the store listing. Has a `TODO` on the screenshots section — see below. |
| `icons/com.bandpassrecords.dpm_{128,256}.png` | Derived from `app_icon.png`. No scalable/SVG source exists in the repo; Flathub accepts raster-only, but a vector icon is preferred if one ever gets made. |

## Outstanding blockers before this can be submitted

### 1. Domain verification (dpm.bandpassrecords.com)

The app ID `com.bandpassrecords.dpm` is a domain-based reverse-DNS ID.
Flathub's website-verification method checks the *exact* subdomain you get by
reversing the ID component-for-component — `com.bandpassrecords.dpm` reversed
is `dpm.bandpassrecords.com`, **not** the bare `bandpassrecords.com` — before
it will publish the app (this happens *after* the PR is merged, via Flathub's
"manage app" verification flow — it doesn't block opening the submission PR,
but does block it going live). That subdomain is already the site you run for
this app, so this should be a straightforward upload rather than a new hosting
setup.

Upload `flatpak/org.flatpak.VerifiedApps.txt` (already created in this
directory) to:

```
https://dpm.bandpassrecords.com/.well-known/org.flatpak.VerifiedApps.txt
```

Then, on the Flathub developer portal for this app, choose "Website"
verification and point it at `dpm.bandpassrecords.com` — it checks for that
file.

### 2. Screenshots are 0-byte placeholders

`resources/screenshots/**/*.png` (see `resources/screenshots/README.md`) are
placeholder files, not real captures. The metainfo's `<screenshots>` block
currently points at `dashboard/dashboard-overview.png` on the `v2.6.1` tag —
Flathub's linter fetches that URL and will fail the submission on a broken
image. Capture real screenshots, replace the files in place, cut a new tag,
and update the tag in the screenshot URL (and in `<release>`/the manifest's
`git` source) to match.

### 3. Vendoring the Flutter SDK + pub packages — now automated in CI

Flathub builds are sandboxed with no network access, and `org.freedesktop.Sdk`
doesn't include Flutter — so the manifest needs every dependency pinned as a
hashed source up front: the Flutter SDK itself, plus every package in
`pubspec.lock`. This is what `build_flatpak` does in CI now (see above) via
[`flatpak-flutter`](https://github.com/TheAppgineer/flatpak-flutter) — nothing
to do by hand for a PR/tag build.

To reproduce the same thing locally (Linux/WSL2 only, e.g. to debug a CI
failure faster than round-tripping through Actions):

```bash
git clone --depth 1 https://github.com/TheAppgineer/flatpak-flutter.git /tmp/flatpak-flutter
pip install -r /tmp/flatpak-flutter/requirements.txt
cd flatpak
python3 /tmp/flatpak-flutter/flatpak-flutter.py com.bandpassrecords.dpm.yml
```

That rewrites the manifest in place with the Flutter SDK module wired in and
writes `pubspec-sources.json` alongside it — check `git diff` here before
committing anything, since this working copy's `git` source (pinned to the
`v2.6.1` tag) is what a real Flathub build needs; CI instead swaps that for a
`type: dir` source pointing at the checkout, so it can validate PRs before a
release tag exists. Don't commit the CI-only `type: dir` swap.

## Local build/test (Linux/WSL2 only)

```bash
sudo apt install flatpak flatpak-builder
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# The manifest has a `type: file` source for the OAuth credentials —
# flatpak-builder fetches the app from git inside the sandbox, so the
# secrets can't be injected into a checkout like the other CI jobs do:
./scripts/inject_oauth_config.sh -d "<desktop-id>" -s "<secret>" -a "<android-id>"
cp lib/config/oauth_config.dart flatpak/oauth_config.dart
# after running flatpak-flutter as above:
flatpak-builder --repo=repo --force-clean --sandbox --user \
  --install-deps-from=flathub build com.bandpassrecords.dpm.yml
flatpak-builder --run build com.bandpassrecords.dpm.yml daw_project_manager
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

1. **Get the submission bundle from CI, don't hand-assemble it.** Every
   `build_flatpak` run uploads a `flatpak-generated-sources` artifact
   containing exactly what needs to go into the Flathub repo:
   - `com.bandpassrecords.dpm.yml` — the *rewritten* manifest (Flutter SDK
     module wired in, `pubspec-sources.json` etc. appended) — not the
     template version in this directory.
   - `generated/` — the vendored modules/sources/patches that manifest
     references.
   - `oauth_config.dart` — generated fresh in that CI run from the repo's GitHub
     secrets. This is the only place this file exists as a downloadable
     artifact; it's not committed anywhere in this repo. Committing it into
     the public Flathub repo is intentional, not an oversight to be careful
     about — Google's OAuth documentation doesn't treat installed-app
     client credentials as confidential (every shipped binary embeds them
     regardless of who can read this artifact).

   Download it from a run **on the actual release tag** you're submitting
   (not a PR run) — that's what makes the manifest's `commit:` match a real,
   permanent release rather than a moving PR head. Note the CI substitution
   drops the `tag:` line and keeps only `commit:` (correct for building,
   just add `tag: vX.Y.Z` back in by hand for readability if you want it).

2. Fork [flathub/flathub](https://github.com/flathub/flathub) and use their
   "New app" request flow to get a repository created at
   `flathub/com.bandpassrecords.dpm`.

3. Push the three items from the artifact into that repo's root (so
   `oauth_config.dart` and `generated/` sit next to the manifest, matching the
   relative paths the manifest's sources use), and open the PR.

4. Their CI builds it and a human reviewer checks the `finish-args` — be
   ready to justify `--share=network` (Google Drive sync) and the D-Bus
   `--talk-name`s above if asked; the comments already in the manifest cover
   the reasoning for each.

Per-release maintenance of the Flathub manifest is nearly hands-off:

- The app source carries `x-checker-data`, so Flathub's
  flatpak-external-data-checker bot watches this repo for new `v*` tags and
  automatically opens a PR on the Flathub repo bumping `tag:`/`commit:` —
  you just merge it.
- `APP_VERSION` is derived at build time from `git describe` on the pinned
  checkout, so it always matches the tag with no manual edit.
- The one still-manual step: add a `<release>` entry to the metainfo for
  each version (Flathub surfaces these as the changelog).
