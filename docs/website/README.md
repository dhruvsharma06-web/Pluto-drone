# docs/website

Website preferences, asset contract and browser evidence for `apps/website/`.

- [ASSET_BRIEF.md](ASSET_BRIEF.md): what an approved drone model must provide, and how to swap it in.
- [CHECKS.md](CHECKS.md): build, test, browser, accessibility and performance checks actually run.
- [screenshots/](screenshots/): desktop and mobile captures from those checks.

Design decisions:

- Dark studio stage for the drone, light bench sections for reading, one safety-yellow accent (actions and highlights only).
- One type family: Archivo (variable, width axis for display sizes).
- The result colours are always paired with a glyph and the exact label (Pass ✓, Incorrect Installation ✕, Unable to Verify ? with a dashed ring), never colour alone.
- Motion: one entry reveal (stage light comes up, copy rises), section reveals once, story poses eased in the viewer. No scroll-jacking or propeller spinning. Everything is static under `prefers-reduced-motion`.
