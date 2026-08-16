# Vendored `windows_taskbar` — local patches

Upstream: <https://github.com/alexmercerind/windows_taskbar> (MIT, `LICENSE`
kept alongside this file).

**Vendored from:** `master` @ `c1fe0c37171521af8b55bc8ce89734cfe13262c1`
(2026-03-24), which declares version `1.1.4`.

Only what we build is vendored — `lib/`, `windows/`, `pubspec.yaml`, `LICENSE`,
`README.md`, `CHANGELOG.md`. The upstream `example/` app is not included.

## Why this is vendored rather than pinned to a pub version

pub.dev has published nothing past **1.1.2 (2023-09-05)**. Everything below was
fixed on `master` afterwards but has never been released, so `pub` cannot give
us any of it.

Upstream [PR #23](https://github.com/alexmercerind/windows_taskbar/pull/23)
(merged 2026-03-23) fixed, on the exact code path our taskbar play/pause button
uses:

- **`HICON` leaked on every `SetThumbnailToolbar` call.** `ImageList_AddIcon`
  copies the icon, so the handle from `LoadImage` was the caller's to free and
  never was. That PR's description is worth reading — it independently describes
  our exact scenario: a music player toggling play/pause exhausts the ~10,000
  per-process USER handle limit, after which `LoadImage` and `ImageList_Create`
  start failing and the taskbar COM component throws "Invalid cursor handle".
- **`HIMAGELIST` leaked on every failure path.**
- **The same `HICON` leak in `SetOverlayIcon`** — which our work-session status
  badge drives, so it leaked independently of playback.
- **`thumb_buttons_added_` latching even when `ThumbBarAddButtons` failed**,
  which permanently downgraded every later call to `ThumbBarUpdateButtons` and
  made it fail forever.

Taking `master` gets all of that. It also adds `LOG_HRESULT`/`LOG_ERROR`
diagnostics, which is useful if #119 recurs.

## The one remaining local patch

### 1/1 — `THUMBBUTTON` array is uninitialized

```cpp
THUMBBUTTON thumb_buttons[kMaxThumbButtonCount];      // upstream, still
THUMBBUTTON thumb_buttons[kMaxThumbButtonCount] = {}; // local patch
```

Still present on upstream `master`. The array is always 7 entries and callers
rarely pass 7 buttons (we pass 1). The filler entries are written as hidden with
only `dwMask`, `dwFlags` and `iId` assigned, leaving `szTip` (a fixed 260-`WCHAR`
array **inside** the struct), `iBitmap` and `hIcon` as uninitialized stack
memory. The whole array is then marshalled into `explorer.exe`.

Microsoft's own sample zero-initializes it:
[`ThumbnailToolbar.cpp`](https://github.com/microsoft/Windows-classic-samples/blob/main/Samples/Win7Samples/winui/shell/appshellintegration/TaskbarThumbnailToolbar/ThumbnailToolbar.cpp)
— `THUMBBUTTON buttons[3] = {};`.

This is the leading suspect for issue #119 (Explorer crashing rather than our
app), though that remains unconfirmed — see the issue.

Find it in the source with `grep -n "LOCAL PATCH" windows/windows_taskbar.cc`.

## Status: staying vendored

Upstreaming patch 1/1 was considered and **deliberately deferred** (decided
2026-08-16). No patch has been sent to `alexmercerind/windows_taskbar`, and none
is awaiting review there — so don't wait on one, and don't assume this
directory is about to go away.

The reasoning for staying vendored rather than tracking upstream by git ref: a
git dependency cannot carry patch 1/1 at all, and a path dependency is pinned by
content in-repo, which the Flatpak build wants since it resolves packages
offline.

What that costs us, stated plainly so it isn't a surprise later: we own this
code now. No upstream fixes arrive automatically, `flutter pub outdated` and
Dependabot will not flag it, and `dependency_overrides` wins globally and
silently — if anything ever depends on `windows_taskbar` with a different
constraint, pub will not warn. It is Windows-only code and under ~1,000 lines,
so the blast radius is contained.

## What this did and did not fix

The leaks above were real and are worth having fixed. But they did **not** stop
the Explorer crash in #119: it recurred on a build carrying all of this, and the
crash dumps show the fault is inside Windows' own XAML taskbar
(`Taskbar.View.dll`), on a machine where that component has been crashing every
few days since well before this app went near it. See #119 for the evidence.

Do not read this directory as "the #119 fix". It is a set of correctness fixes
on the same code path.

## If we ever want to get rid of this directory

1. Send patch 1/1 upstream (not done — see above).
2. When a release lands on pub.dev containing both PR #23 and patch 1/1, bump
   the `windows_taskbar` constraint in the root `pubspec.yaml`, delete the
   `dependency_overrides` entry, and delete this directory.

Until then, re-vendoring means re-downloading `master` and re-applying the one
`LOCAL PATCH` block.
