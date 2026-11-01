# Person 2 (you): website UI with Claude: handoff

Branch: `frontend/website` (based on `78c704b`). Exact commit: see `git log -1 origin/frontend/website`; the commit that added this file is recorded in `docs/status/frontend-web.md`.

Owned paths: apps/website/, docs/website/, docs/status/frontend-web.md, docs/handoffs/frontend-web.md

Contract: v1.0.0 (read-only consumer of `contracts/verification-result.schema.json`, `contracts/reference.schema.json`, `contracts/fixtures/*.json`).

## Completed

A responsive one-page overview in `apps/website/` (Vite 6 + TypeScript + three.js 0.170, no framework):

- **Opening + scroll story** (sticky 3D stage): whole drone → arms/motors (parts separate) → propeller close-up → "right type, right place, right way up?" (top view; one propeller settles at a new resting angle to show that resting angle is not an error). Normal scrolling. Each step is plain HTML text; the viewer eases to the step's pose.
- **Interactive viewer**: drag with inertia, touch drag, zoom buttons (×1.35), close-up, reset, Perspective/Top/Side views, a smooth 360° turn, component focus (body/arms/motors/propellers, synced text, `aria-pressed` + check mark, not colour only), separated-parts toggle, bench/low-light presets, keyboard (arrows, +/−, 0, T/S/P), expanded `<dialog>` (Esc/Close, focus returns, wheel and pinch zoom only there), fading drag hint, idle drift that pauses on interaction and resumes after ~1.8 s.
- **Progressive enhancement**: an SVG poster is always in the HTML; three.js loads on demand and replaces it only after the first frame. If WebGL is missing, loading fails or the context is lost, the poster stays and a status message is set. Rendering pauses offscreen and in hidden tabs; resources are released on dispose. DPR is capped at 2 (1.5 on small screens).
- **Asset-independent scene interface** (`src/viewer/types.ts`), an **illustrative procedural schematic** (`schematic.ts`), and an adapter for a future approved GLB (`gltf.ts`), selected via `public/assets/manifest.json`.
- **Content**: installation problems with drawings, the six-step pipeline split into Safety / Acquisition / Vision core / App screen, the three results with exact labels, labelled phone **mockups**, an architecture stack with real package paths, honest evidence (no metrics; requirement evidence table; known limits), resources with real links or "Not available yet", workstream roles (no names), and a footer.
- **Fixture demo** of the contract's result rules: evidence toggles and an injected fault produce a contract-shaped result (`evidence_source: fixture`) with reasons, an illustrative position sketch, per-motor findings, guidance and the JSON. Presets load the actual shared fixture files. New input clears the previous result first.
- Tests (`npm test`): exact labels, no Pass with any missing evidence across all 384 toggle combinations, Incorrect only with full evidence and a mismatch, contract invariants, fixture labelling, and demo presets reproducing `contracts/fixtures/*.json` exactly.

## Run/build/test and actual results

See `docs/status/frontend-web.md` and `docs/website/CHECKS.md` for exact commands and results.

## Assets/data/model/reference versions

- 3D: `schematic-v1` (procedural, illustrative). No approved model. `pluto-x-glb.zip` excluded and never touched.
- Poster: inline SVG `#drone-top` (illustrative).
- Team photos of the supplied drone (WhatsApp ZIP, 22 JPEGs, 2026-11-01) were used **only** as a visual reference for proportions. They are not committed or published.
- Reference: none verified. The site links `reference/config/pending.json` as a placeholder.
- Fonts: Archivo variable via `@fontsource-variable/archivo` (SIL OFL 1.1), bundled locally.

## Fixtures, mocks, placeholders

- Demo results: fixture only, IDs `FIXTURE_1..4`, types `fixture_type` / `fixture_other_type`, orientation `fixture_orientation` / `fixture_inverted`. Positions on the sketch are drawn for illustration only.
- Phone screens: labelled "Mockup" drawings, not captured app screens.
- APK, dataset and validation report: "Not available yet" (no fake links).
- Team: workstream roles only.

## Known limitations

- The schematic is not the supplied drone's geometry; there is no front view until a front convention exists.
- The demo shows contract semantics, not detection quality.
- Browser checks ran in Chromium (the desktop app's browser pane) only. No Safari/Firefox or real-phone run.
- No deployment (not authorised).

## Teammate preferences and decisions

- Optional question asked: may the site show cropped/downsized team photos, and is a light vs dark direction preferred? Pending an answer: photos stay reference-only.
- Direction chosen: dark studio stage for the drone, light "bench" sections for reading, safety-yellow single accent, one type family (Archivo with width axis). Reference site idr-tech.vercel.app was inspected for scroll-led object storytelling; motionsites.ai was **not** inspected.
- Working name "Pluto Inspector" (from the app package `pluto_inspector`); easy to replace (`index.html` text). It does not establish the exact variant.

## Shared change proposals

1. **Correction code** (contract owners: app + ML): the demo uses `REINSTALL_IN_REFERENCE_ORIENTATION` for an orientation mismatch alongside the fixture code `REPLACE_WITH_REFERENCE_TYPE`. v1 allows any string, so nothing breaks. Proposal: agree a small list of correction codes (type, orientation, position swap) so app UI, ML and the website use the same codes and guidance text. Consumers: inspection_ui, website.
2. **resources/manifest.json** (app owner): when an approved website model or real screenshots exist, add entries mirroring `apps/website/public/assets/manifest.json` (id, version, sha256, source, rights, location).
3. **Website asset**: needs a rights-cleared GLB of the supplied drone and a documented front convention (research + ML via the verified reference). Contract in `docs/website/ASSET_BRIEF.md`.

## Receiving owner and next task

- App owner: merge `frontend/website` during final integration. It touches only owned paths. Provide APK URL and real screenshots when available.
- Research/ML: verified reference (front convention, motor IDs), measured results and dataset link. The website then replaces "pending" states with real links and numbers.
- Website next: real screenshots/metrics/links once supplied; approved model per the asset brief; optional photo use if approved.
