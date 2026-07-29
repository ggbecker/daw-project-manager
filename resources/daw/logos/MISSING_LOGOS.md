# Missing DAW Logos

13 DAWs were added for file detection (see [scanner_service.dart](../../lib/services/scanner_service.dart)) without logo assets — none were sourced or generated, by design. This is the checklist for filling them in.

Once a PNG exists for a row below:
1. Drop it in this folder using the exact filename listed.
2. Add it to the landing page grid at `index.html` (`gh-pages` branch) — currently these DAWs only appear in the "+N more DAWs supported" expandable text list.
3. Add a matching entry to the `logoMap` in [lib/utils/daw_logo.dart](../../../lib/utils/daw_logo.dart) (`main` branch) so the in-app DAW logo (Dashboard table, Project Detail) picks it up — it currently returns `null` for these and falls back to no logo.

Suggested source: each DAW's own press/brand page, kept small (~256x256, transparent background, matching the style of the existing logos in this folder).

- [ ] `ardour.png` — Ardour
- [ ] `garageband.png` — GarageBand
- [ ] `renoise.png` — Renoise
- [ ] `lmms.png` — LMMS
- [ ] `audacity.png` — Audacity
- [ ] `qtractor.png` — Qtractor
- [ ] `rosegarden.png` — Rosegarden
- [ ] `reason.png` — Reason
- [ ] `digital-performer.png` — Digital Performer
- [ ] `adobe-audition.png` — Adobe Audition
- [ ] `samplitude-sequoia.png` — Samplitude / Sequoia
- [ ] `acid-pro.png` — ACID Pro
- [ ] `mixcraft.png` — Mixcraft
