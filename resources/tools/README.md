# Bundled tools

## ffmpeg.exe

Windows-only, used by `AudioAnalysisService.convertForSharing` to convert
WAV/AIFF/FLAC preview songs to MP3 before sharing (WhatsApp and some other
messaging apps reject those formats as a direct audio attachment). Bundled
so end users never need to install anything themselves — see
`AudioAnalysisService._bundledFfmpegPath` for how it's resolved at runtime.

- Source: https://www.gyan.dev/ffmpeg/builds/ (the build linked from
  ffmpeg.org's own Windows download page) — `ffmpeg-release-essentials.zip`.
- Version at time of bundling: 8.1.2.
- License: GPLv3 — see `FFMPEG_LICENSE.txt` in this folder. Invoked as a
  separate subprocess (`Process.run`), not linked into the app binary.

To update: download a newer essentials build from the URL above and
replace `ffmpeg.exe` (and `FFMPEG_LICENSE.txt` if it changed) — no other
code changes needed.
