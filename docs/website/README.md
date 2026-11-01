# docs/website

Website preferences, asset contract and browser evidence for `apps/website/`.

- [ASSET_BRIEF.md](ASSET_BRIEF.md): what an approved drone model must provide, and how to swap it in.
- [CHECKS.md](CHECKS.md): build, test, browser, accessibility and performance checks actually run.
- [screenshots/](screenshots/): desktop and mobile captures from those checks.

Design decisions (current, 2026-11-01):

- Apple-style dark theme, strictly black, white and purple (owner request: no other colours anywhere, including result states). Playfair Display for headlines only, Inter for all interface and body text, sentence case throughout (no tracked all-caps).
- Seven full-screen scenes with CSS scroll-snap (desktop): Intro, Taken apart, The propeller, How it works, Results with fixture demo, Explore, Project. One persistent 3D canvas behind them moves the drone to a new shot per scene, with a soft dip-to-black transition and staggered blur-rise copy on every scene change.
- Lighting and atmosphere: a gloss-black schematic drone, a gliding white key light, slow-breathing violet rim lights, and shader-based stage fog. The fog is domain-warped noise in a deep purple (#2B0B55): it hugs the floor, billows upward and evolves slowly, like smoke-machine haze.
- The opening assembles the drone from its parts before the headline appears. "Taken apart" separates it in stages with part labels.
- Results are told apart by glyph and shape (white ✓ circle, purple ✕ square, grey dashed ? ring) and their exact labels.
- Cursors: a site-wide custom cursor (black core, purple ring, white centre; larger ring over links/buttons) and a fluid "ink" trail (`src/splash-cursor.ts`, a plain-TypeScript port of the SplashCursor component the frontend owner supplied; WebGL2 stable-fluids, purple palette, click bursts, off for reduced motion and touch). Licence of the original component should be confirmed by the owner.
- Load sequence: black is painted inline before CSS arrives; the static drawing appears only if 3D fails; reloads start at the top, so a load always goes black → parts flying in.
- Flight scene uses a custom reticle cursor (purple rotating dashed ring with a black core, glides after the pointer); the fog reads as soft mist that climbs from the floor.
