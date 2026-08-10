# Bundled tools

## ffmpeg.exe

Windows-only, used by `AudioAnalysisService.convertForSharing` to convert
WAV/AIFF/FLAC preview songs to MP3 before sharing (WhatsApp and some other
messaging apps reject those formats as a direct audio attachment). Bundled
so end users never need to install anything themselves — see
`AudioAnalysisService._bundledFfmpegPath` for how it's resolved at runtime.

**This is not a Flutter asset.** It is installed into `<bundle>/tools/` by an
`install(FILES ...)` rule at the bottom of `windows/CMakeLists.txt`. Listing
it under `flutter: assets:` in `pubspec.yaml` is what it used to do, and that
shipped this 97 MB Windows executable inside the Android APK, the macOS
`.app` and the Linux tarball/Flatpak — Flutter's asset list has no
per-platform filter. Every other platform has its own encoder (ffmpeg-kit on
Android/iOS, `afconvert` on macOS, `ffmpeg` on `PATH` on Linux), so please
don't add it back to the asset list.

- Source: https://www.gyan.dev/ffmpeg/builds/ (the build linked from
  ffmpeg.org's own Windows download page) — `ffmpeg-release-essentials.zip`.
- Version at time of bundling: 8.1.2.
- License: GPLv3 — see `FFMPEG_LICENSE.txt` in this folder. Invoked as a
  separate subprocess (`Process.run`), not linked into the app binary.

To update: download a newer essentials build from the URL above and
replace `ffmpeg.exe` (and `FFMPEG_LICENSE.txt` if it changed) — no other
code changes needed.

`FFMPEG_LICENSE.txt` is installed alongside the binary, so the GPLv3 text
ships with the copy of ffmpeg it applies to.
