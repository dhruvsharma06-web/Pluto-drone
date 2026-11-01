# docs/website

Website preferences, asset contract and browser evidence for `apps/website/`.

- [ASSET_BRIEF.md](ASSET_BRIEF.md): what an approved drone model must provide, and how to swap it in.
- [CHECKS.md](CHECKS.md): build, test, browser, accessibility and performance checks actually run.
- [screenshots/](screenshots/): desktop and mobile captures from those checks.

Design decisions:

- Strictly black and white: true-black grounds, white type, white light only. The drone is gloss black (car-paint finish: near-black base, full clearcoat), lit by white key/rim light with soft white studio smoke. No frame or rings around the drone. Direction set by the frontend owner on 2026-11-01: cinematic, Apple-grade, big justified text, minimal copy, desktop-first.
- Opening: the drone assembles from its parts on load, then the centred headline arrives. The key light glides so reflections sweep the gloss. Scroll captions move through airframe → body shell → arms → motors → propeller, with a right-edge progress rail.
- Motion layer: word-reveal headings, blur-rise captions, scroll-driven lift-in for sections and grey-to-white lead text (CSS `animation-timeline: view()`, progressive enhancement), a header that turns solid with a blur on scroll, a results marquee band, and a card swap with staggered rise.
- The result states are told apart by glyph and shape (✓ solid, ✕ square, ? dashed ring) and their exact labels, not by colour.
- Explore section adapts the interaction model of the Myth Atlas reference (tabs, framed stage, tool rail, turn bar, notes card with staggered swap, expand, light preset) to our drone. None of its assets, copy or palette are used.
- One type family: Archivo (variable, width axis for display sizes).
- The result colours are always paired with a glyph and the exact label (Pass ✓, Incorrect Installation ✕, Unable to Verify ? with a dashed ring), never colour alone.
- Motion: one entry reveal (stage light comes up, copy rises), section reveals once, story poses eased in the viewer. No scroll-jacking or propeller spinning. Everything is static under `prefers-reduced-motion`.
