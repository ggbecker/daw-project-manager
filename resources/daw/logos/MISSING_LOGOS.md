# Missing DAW Logos

13 DAWs were added for file detection (see [scanner_service.dart](../../lib/services/scanner_service.dart)) without logo assets — none were sourced or generated, by design. This is the checklist for filling them in.

12 of 13 are done — sourced, converted to PNG, cropped/background-cleaned where needed, wired into `index.html` (`gh-pages` branch) and `logoMap` in [lib/utils/daw_logo.dart](../../../lib/utils/daw_logo.dart) (`main` branch).

Once a replacement PNG exists for the row still open below:
1. Drop it in this folder using the exact filename listed.
2. Add it to the landing page grid at `index.html` (`gh-pages` branch).
3. Add a matching entry to the `logoMap` in [lib/utils/daw_logo.dart](../../../lib/utils/daw_logo.dart) (`main` branch) so the in-app DAW logo (Dashboard table, Project Detail) picks it up — it currently returns `null` for it and falls back to no logo.

Suggested source: each DAW's own press/brand page, kept small (~256x256, transparent background, matching the style of the existing logos in this folder).

- [x] `ardour.png` — Ardour
- [x] `garageband.png` — GarageBand
- [x] `renoise.png` — Renoise
- [x] `lmms.png` — LMMS
- [x] `audacity.png` — Audacity
- [x] `qtractor.png` — Qtractor
- [ ] `rosegarden.png` — Rosegarden — **the supplied image was a photo of an actual garden rose, not the software's logo** (the real Rosegarden mark is a green compass/wheel icon). Skipped rather than using it; needs a proper source.
- [x] `reason.png` — Reason
- [x] `digital-performer.png` — Digital Performer
- [x] `adobe-audition.png` — Adobe Audition
- [x] `samplitude-sequoia.png` — Samplitude / Sequoia
- [x] `acid-pro.png` — ACID Pro
- [x] `mixcraft.png` — Mixcraft
