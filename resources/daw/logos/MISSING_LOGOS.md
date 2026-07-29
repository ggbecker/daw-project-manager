# Missing DAW Logos

13 DAWs were added for file detection (see [scanner_service.dart](../../lib/services/scanner_service.dart)) without logo assets — none were sourced or generated, by design. This is the checklist for filling them in.

All 13 are now done — sourced, converted to PNG, cropped/background-cleaned where needed, wired into `index.html` (`gh-pages` branch) and `logoMap` in [lib/utils/daw_logo.dart](../../../lib/utils/daw_logo.dart) (`main` branch).

- [x] `ardour.png` — Ardour
- [x] `garageband.png` — GarageBand
- [x] `renoise.png` — Renoise
- [x] `lmms.png` — LMMS
- [x] `audacity.png` — Audacity
- [x] `qtractor.png` — Qtractor
- [x] `rosegarden.png` — Rosegarden (KDE Breeze icon theme's app icon — a stylized rose, which is in fact the real mark; a first attempt had accidentally used a stock photo of an actual garden rose instead)
- [x] `reason.png` — Reason
- [x] `digital-performer.png` — Digital Performer
- [x] `adobe-audition.png` — Adobe Audition
- [x] `samplitude-sequoia.png` — Samplitude / Sequoia
- [x] `acid-pro.png` — ACID Pro
- [x] `mixcraft.png` — Mixcraft

If any of these ever need replacing: drop the new PNG in this folder using the same filename, and it'll be picked up automatically by both `index.html` (`gh-pages` branch) and `lib/utils/daw_logo.dart`'s `logoMap` (`main` branch) — no other wiring needed.
