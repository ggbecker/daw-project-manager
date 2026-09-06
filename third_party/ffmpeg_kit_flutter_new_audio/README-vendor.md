# Vendored `ffmpeg_kit_flutter_new_audio`

This is a copy of `ffmpeg_kit_flutter_new_audio` 2.5.2 (pub.dev), pinned via
`dependency_overrides` in the app's `pubspec.yaml`, with the **desktop** native
layers stubbed to no-ops.

## Why

`AudioAnalysisService` only ever calls ffmpeg-kit **in-process on Android and
iOS** (`_usesInProcessFfmpeg`). Every desktop code path converts audio with
`afconvert` (macOS) or a `PATH`/bundled `ffmpeg` (Linux, Windows) instead — it
never touches this plugin.

The upstream desktop native layers, however, are expensive and CI-hostile:

| Platform | Upstream behaviour | Problem |
|----------|--------------------|---------|
| Linux    | `CMakeLists.txt` downloads a ~19 MB ffmpeg bundle from GitHub at **configure** time; requires `json-glib-1.0` dev headers | breaks the offline Flathub build and needs an extra apt package in `build_linux` |
| Windows  | `CMakeLists.txt` downloads a bundle + runs `editbin` to rebase the DLLs | build-time network + toolchain dependency for unused code |
| macOS    | podspec vendors 8 ffmpeg `.framework`s (downloaded by a `prepare_command`) | `Command CodeSign failed … code object is not signed at all` in CI |

## What was changed vs. upstream

Kept **byte-for-byte identical** to upstream: `lib/`, `android/`, `ios/`.

Stubbed:

- `linux/CMakeLists.txt` + `linux/ffmpeg_kit_flutter_plugin.cc` — build a
  do-nothing plugin that only defines
  `f_fmpeg_kit_flutter_plugin_register_with_registrar`. No download, no
  json-glib, no bundled `.so`. `linux/include/` left untouched (the generated
  registrant includes its header).
- `windows/CMakeLists.txt` + `windows/ffmpeg_kit_flutter_plugin_c_api.cpp` —
  no-op `FFmpegKitFlutterPluginRegisterWithRegistrar`. Removed
  `ffmpeg_kit_flutter_plugin.{h,cpp}` and `windows/src/`.
- `macos/ffmpeg_kit_flutter_new_audio.podspec` — dropped
  `ss.osx.vendored_frameworks` and `s.prepare_command`.
- `macos/.../FFmpegKitFlutterPlugin.m` — no-op class; registers the method /
  event channels but every call returns `FlutterMethodNotImplemented`. No
  `<ffmpegkit/…>` import.
- `macos/.../Package.swift` — dropped the remote `binaryTarget`s (SwiftPM is
  unused here; kept minimal in case it is ever enabled).
- `**/Frameworks/` and `example/` were excluded from the copy.

## Updating

If ffmpeg-kit needs a version bump for Android/iOS, re-copy `lib/`, `android/`,
`ios/` from the new pub.dev release and re-apply the desktop stubs above.
