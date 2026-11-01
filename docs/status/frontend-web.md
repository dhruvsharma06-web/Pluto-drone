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
