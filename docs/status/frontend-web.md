Implementation commit: `f85212ce9ebc8b18138a07e59a1f4b91e73dfe38`. Final production build passed.

## Centered pill navigation and cleanup — 1 November 2026

User-authorized scoped refinement on frontend/website: centered transparent header with active-dot pills, original drone mark, purple Source CTA; rounded unnumbered Explore tabs/cards/tools; removed projected model text; simplified Project and footer. The 3D stage/viewer/cursor source files and scroll/animation timing remain unchanged. No React dependency or other-branch merge.

npm run check passes (TypeScript, 8 tests, production build); diff whitespace clean. Browser renders reviewed at 1440/768/390px using the installed Taste inspector. General design audit retains existing site-wide/reveal findings; no manual click-through or physical-device check claimed. Full changes, render critique and limits: docs/website/PILL_NAV.md. Source commit recorded in the follow-up below. Untracked Flutter files left untouched; no push/deployment.

# Person 2 (you): website UI with Claude: status

Branch: `frontend/website` (local commits; see `git log`). Contract v1.0.0 (read-only).

State: **Overview website implemented and checked in the browser; not deployed; not pushed.**

Current: black-and-white cinematic site in `apps/website/` (Vite 6 + TypeScript + three.js 0.170):
- assembly intro, centred hero, story through the drone's parts ending on the propeller;
- explore plate with component tabs, tool rail and notes card;
- installation problems, six-step pipeline, three exact results, fixture demo of the contract rules;
- labelled app mockups, architecture, honest evidence and limitations, resources with real links or "Not available yet", and workstream roles.

Checks (2026-11-01, see docs/website/CHECKS.md): `npm run check` passes (tsc 0 errors, vitest 8/8, vite build). Browser checks were done on desktop at 1440×900 and 1280×800, and earlier on mobile at 375×812. Keyboard, expanded dialog and demo interactions were verified. Reduced motion was not emulated.

Blockers / pending inputs:
- Approved 3D model of the supplied drone and its front convention (research/ML) → docs/website/ASSET_BRIEF.md.
- Verified reference configuration (research/ML), APK link (app owner), dataset and validation report links (ML), real app screenshots (app/frontend-flutter), measured metrics (ML).
- Answer on publishing team photos (frontend owner).

Preferences: desktop-first; black and white; gloss-black drone with white light and smoke; big justified text; minimal copy; Apple-like polish (recorded in the handoff).

Next: push `frontend/website` when the owner approves; swap in real links, screenshots and metrics as teammates deliver them.

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
