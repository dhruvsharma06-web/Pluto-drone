Implementation commit: `f85212ce9ebc8b18138a07e59a1f4b91e73dfe38`. Final production build passed.

## Centered pill navigation and cleanup — 1 November 2026

User-authorized scoped refinement on frontend/website: centered transparent header with active-dot pills, original drone mark, purple Source CTA; rounded unnumbered Explore tabs/cards/tools; removed projected model text; simplified Project and footer. The 3D stage/viewer/cursor source files and scroll/animation timing remain unchanged. No React dependency or other-branch merge.

npm run check passes (TypeScript, 8 tests, production build); diff whitespace clean. Browser renders reviewed at 1440/768/390px using the installed Taste inspector. General design audit retains existing site-wide/reveal findings; no manual click-through or physical-device check claimed. Full changes, render critique and limits: docs/website/PILL_NAV.md. Source commit recorded in the follow-up below. Untracked Flutter files left untouched; no push/deployment.

# Person 2 (you): website UI with Claude: handoff

Branch: `frontend/website` (based on `78c704b`). Exact commit: see `git log -1 origin/frontend/website`; the commit that added this file is recorded in `docs/status/frontend-web.md`.

Owned paths: apps/website/, docs/website/, docs/status/frontend-web.md, docs/handoffs/frontend-web.md

Contract: v1.0.0 (read-only consumer of `contracts/verification-result.schema.json`, `contracts/reference.schema.json`, `contracts/fixtures/*.json`).

## Completed

Latest structure (supersedes the long-scroll description below where they differ): seven full-screen snap scenes over one persistent 3D stage (src/stage.ts), Apple-style dark theme with serif headlines, shader stage fog in deep purple, dip-to-black scene transitions. Content was cut to one screen per topic. A separate "Made to fly." scene (owner request) shows the drone lifting off with spinning propellers and blur discs, steered by mouse or arrow keys, with rotor downwash swirling the fog. It is labelled "Flight shown for illustration only" and states that inspection happens disarmed with motors stopped; it is never part of the inspection story; the APK line was removed from the hero at the owner's request (resources still state that downloads will be linked when released).


A responsive one-page overview in `apps/website/` (Vite 6 + TypeScript + three.js 0.170, no framework):

- **Opening**: full-screen, true-black cinematic stage. The schematic drone **assembles from its parts on load** (body → arms → motors → propellers, each labelled as it lands, camera dolly-in). Then an inspection HUD frame locks on with one scan sweep, and the headline reveals word by word.
- **Scroll story** (full-screen sticky stage with big captions scrolling over it): airframe → body shell → arms (separated) → motors → **the propeller** (close-up; one propeller settles at a new resting angle to show that resting angle is not an error). Normal scrolling. Each caption is plain HTML.
- **Exploded view** (scroll-scrubbed, after the ultraui `scroll-product-explode-assembly` pattern): a 340vh track with a sticky full-screen stage. Scroll progress separates the drone in stages (shell → arms → motors → propellers), labels each group as it clears, steps a caption, drifts the camera and fills a progress meter. Scrolling back reassembles it. Native scroll only.
- **Explore plate** (interaction model adapted from the Myth Atlas reference): component tabs with roving focus, a framed stage with blue corner brackets, a tool rail (zoom in/out, separate parts, low light, reset, expand), a turn bar (−90°, 360°, +90°, Top/Side/3/4), a large caption, and a notes card (eyebrow, big title, tags, lede, field notes with dotted leaders, close-up toggle) whose copy swaps with a staggered rise. Plus drag with inertia, double-click reset, keyboard (arrows, +/−, 0, T/S/P), expanded `<dialog>` (Esc/Close, focus returns, wheel and pinch zoom only there) and idle drift that pauses on interaction.
- **Look**: strictly black and white. The drone is gloss black with white light and white studio smoke, with no border or rings. Apple-style centred hero, big type everywhere (minimum 18 px), justified running text, results marquee band, word-reveal headings, scroll-driven reveals, solid-on-scroll header, story progress rail and scroll cue.
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
- Browser checks ran in Chromium (the desktop app's browser pane) only. No Safari/Firefox or real-phone run. Reduced motion was not emulated. See docs/website/CHECKS.md.
- Motor cans are drawn dark metal to fit the black-and-white direction; the team photos show brass-coloured motors. Schematic colours are not a claim about the hardware.
- No deployment (not authorised).

## Teammate preferences and decisions

- Optional question asked (photo use, visual direction). Photo use is not answered yet, so photos stay reference-only.
- Frontend owner's direction (2026-11-01, final): desktop-first; strictly black and white, true black, gloss-black drone like car paint with white lighting and white smoke, no border around the drone, professional and Apple-like; cinematic with lots of motion; no small text; justified text; minimal copy, more visuals; drone centred and as large as possible; parts assemble into the drone on load; scroll through parts ending on the propeller; adopt the Myth Atlas interaction style.
- Reference site idr-tech.vercel.app was inspected for scroll-led object storytelling; motionsites.ai was **not** inspected.
- Working name "Pluto Inspector" (from the app package `pluto_inspector`); easy to replace (`index.html` text). It does not establish the exact variant.

## Shared change proposals

1. **Correction code** (contract owners: app + ML): the demo uses `REINSTALL_IN_REFERENCE_ORIENTATION` for an orientation mismatch alongside the fixture code `REPLACE_WITH_REFERENCE_TYPE`. v1 allows any string, so nothing breaks. Proposal: agree a small list of correction codes (type, orientation, position swap) so app UI, ML and the website use the same codes and guidance text. Consumers: inspection_ui, website.
2. **resources/manifest.json** (app owner): when an approved website model or real screenshots exist, add entries mirroring `apps/website/public/assets/manifest.json` (id, version, sha256, source, rights, location).
3. **Website asset**: needs a rights-cleared GLB of the supplied drone and a documented front convention (research + ML via the verified reference). Contract in `docs/website/ASSET_BRIEF.md`.

## Receiving owner and next task

- App owner: merge `frontend/website` during final integration. It touches only owned paths. Provide APK URL and real screenshots when available.
- Research/ML: verified reference (front convention, motor IDs), measured results and dataset link. The website then replaces "pending" states with real links and numbers.
- Website next: real screenshots/metrics/links once supplied; approved model per the asset brief; optional photo use if approved.

## Navbar follow-up

Removed the visible Pluto Inspector wordmark text, retaining the original drone logo and its accessible back-to-top name. Moved the bold purple Source link into the centered pill-navigation list. Header background remains transparent. Only index.html/styles.css changed; no 3D, scroll or animation source changes. npm run build (TypeScript + Vite) and git diff --check pass. Local preview updates automatically; no push/deployment.

Navbar branding removed at user request: no drone mark or Pluto Inspector wordmark in the header. Remaining navigation pills, including Source, are centered directly with no empty logo column/row. Only navbar HTML/CSS changed.

Part-name restoration: restored Body shell, Arms, Motors and Propellers tags on their original 3D anchors after the user clarified these labels are wanted. Existing staged appearance, opening landing labels, projection and fade behavior reconnect through the unchanged stage code. Long resting-angle annotation remains removed. TypeScript/Vite build and git diff --check pass; no new visual capture claimed for this markup-only restoration.

Copy cleanup requested by user: removed only the Flight cursor/keyboard instruction and its separate illustration sentence. Kept the ground-first/disarmed/stopped line and other site-wide illustrative disclosures. Removed CSS-generated How it works numbers and their empty column; all four rows, borders, titles and descriptions remain. Flight controls, 3D and animation code unchanged. npm run build and git diff --check pass.

Initial-load label refinement: removed only the global stage onLanded label callback. Opening assembly still plays, but no part names appear on first load/refresh. Existing updateTags continues showing the four restored part labels only in the Taken apart scene. Its staged timing, anchors and animation remain unchanged. npm run build and git diff --check pass.

## Results simplification

Removed the exact phone-mockup caption “FIXTURE_1 — swap for the type the reference lists.” Kept Mockup labelling and its result diagram. Results now has a short heading and one-line meanings for the three exact outcomes. Preset buttons use plain labels (Pass, Incorrect, Unclear image, No reference) instead of filenames.

| Before | After | Why |
| --- | --- | --- |
| Visible contract explanation, file names and every evidence/fault input | Four sample choices; evidence/fault controls under “Adjust the example” | Easier to understand and less visual clutter |
| Always-visible fixture motor map, findings, reasons and JSON | Short status/summary, with “View example details” and nested “Technical data” | Keep full information available without overwhelming the first view |
| Long result explanations and raw provenance in the main panel | One concise explanation and persistent “Demo · Simulated results” | Preserve meaning and honesty with less copy |

The demo's evaluate/read/write/preset logic, stale-result clearing, real fixture payloads, correction guidance and exact status labels are retained. All controls remain in the form even when collapsed. Simulated-result labelling remains visible in both ready and updating states. Main details close when a new result replaces the old one. No engine/contract/3D/camera/scroll-animation changes.

Validation: npm run check passes (TypeScript, 8/8 existing fixture-rule tests, Vite build); git diff --check clean. Viewed direct #results desktop 1440px and phone 390px browser renders via the installed Taste inspector (ignored .preview/results-focus); normal scrolling renders also captured. Phone flows vertically, desktop fits the compact overview. General site audit retains the previously documented unrelated findings; no clean whole-site audit or manual browser click-through claimed. Impeccable and Emil guidance used for hierarchy, progressive disclosure and retaining native details behavior.

Result colours updated at user request: Pass green (#76D69B), Incorrect Installation red (#FF8C90), Unable to Verify yellow (#F1CC70). Labels and distinct outlined check/cross/question symbols retain meaning without relying solely on colour. Removed filled/glowing status badges; cards remain informational, not buttons. Shared semantic tokens also align the simulated output, motor rings and mockup status. Navigation, 3D and result logic unchanged. TypeScript/Vite build and git diff --check pass; direct desktop Results render reviewed.
