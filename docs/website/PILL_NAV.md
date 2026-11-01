# Pill navigation and page cleanup

Branch: frontend/website. Starting commit: 592577a. User requested a centered pill navigation and targeted cleanup while preserving the 3D background, camera shots, assembly/flight animation, cursor, scroll-snap and transitions. The checkout was already on the requested branch. Untracked Flutter example artifacts were left alone.

## Changes

| Before | After | Why |
| --- | --- | --- |
| Spread header with a solid blurred scroll backdrop | Centered section pills, transparent header at every scroll position | Keep navigation consistent with the requested presentation |
| Text-only wordmark and plain Source link | Original SVG quadrotor mark/favicon; bold purple Source pill | Give the navigation a project-specific identity |
| Numbered square component tabs | Unnumbered rounded tabs and rounded viewer/notes surfaces | Remove decorative indexing and soften the explorer |
| Projected component tags and large caption over the model | Tags removed; dynamic caption retained as screen-reader text; notes remain alongside | Keep the model clear without changing its camera or animations |
| Dense Project architecture paths and repeated footer copy | Short overview, validation pending, repository/contract/architecture links and concise safety footer | Keep essential project information findable |

The site remains Vite/TypeScript/three.js. The supplied React example was used as interaction direction; no React framework or React Bits dependency was added. Navigation retains real section anchors and mirrors the existing scene state for its active dot. At narrow widths the links wrap rather than clipping or hiding. Existing tab/keyboard/viewer/demo handlers are retained. Component counts in field notes remain factual content; decorative 00–04 indices are removed.

Source files src/stage.ts, src/viewer/** and src/splash-cursor.ts have no diff. Global background/model, lighting and scene transition rules are preserved. Only presentation spacing accommodates the taller compact header. The existing hero reveal timing remains unchanged.

## Actual checks

- npm ci installed the committed lockfile without dependency changes.
- npm run check: TypeScript passes; Vitest 8/8 passes; Vite production build passes.
- git diff --check: clean.
- Browser renders via installed Taste inspector: before at 1440/390px; after at 1440/768/390px. Opened all final fold/contact-sheet captures and reviewed navigation, Explore and Project. Local outputs are ignored under apps/website/.preview/.
- Mobile review led to wrapping navigation, stacking hero CTAs, and smaller close-up/field-note geometry.
- Built-in local browser access was disabled; the installed skill's browser inspector supplied render checks. No manual browser click-through, Safari, Firefox or physical-phone run is claimed.

The general Taste audit is NOT clean: baseline 16 FAIL/10 WARN at its two widths; final 16 FAIL/10 WARN at three widths. These include existing multi-line headlines, delayed reveal, code/fixture typography, purple/hairline identity, custom scene recognition and mobile tall-section reveal behavior. The newly introduced sideways nav row was fixed. This was a scoped refinement, not authorization to replace the requested background or animation system. The full audit JSON remains in the ignored preview folder. Do not present the passing build as a passing global design audit.

## Render critique

Scoped review: navigation hierarchy and source emphasis are clear; rounded explorer and compact Project read coherently against the existing cinematic background. The transparent fixed header can pass over content during intermediate scroll positions, as requested. The existing mobile scene observer/reveal behavior and delayed hero title are the main remaining whole-site usability limitations; preserving scroll/animation behavior leaves those unchanged. Subjective whole-page scores: design 7/10, usability 6/10, creativity 7/10, content 7/10 (weighted 6.7/10), not an automated test result. No direction draw or stock media was introduced: this is the user's pinned incumbent design with a new original SVG drone mark.

No deployment, external messages, push, merge or contract changes. Next receiver: frontend/website owner; review locally with npm run dev. App owner integrates only during the coordinated final window.

## Navbar follow-up

Removed the visible Pluto Inspector wordmark text, retaining the original drone logo and its accessible back-to-top name. Moved the bold purple Source link into the centered pill-navigation list. Header background remains transparent. Only index.html/styles.css changed; no 3D, scroll or animation source changes. npm run build (TypeScript + Vite) and git diff --check pass. Local preview updates automatically; no push/deployment.

Navbar branding removed at user request: no drone mark or Pluto Inspector wordmark in the header. Remaining navigation pills, including Source, are centered directly with no empty logo column/row. Only navbar HTML/CSS changed.

Part-name restoration: restored Body shell, Arms, Motors and Propellers tags on their original 3D anchors after the user clarified these labels are wanted. Existing staged appearance, opening landing labels, projection and fade behavior reconnect through the unchanged stage code. Long resting-angle annotation remains removed. TypeScript/Vite build and git diff --check pass; no new visual capture claimed for this markup-only restoration.

Copy cleanup requested by user: removed only the Flight cursor/keyboard instruction and its separate illustration sentence. Kept the ground-first/disarmed/stopped line and other site-wide illustrative disclosures. Removed CSS-generated How it works numbers and their empty column; all four rows, borders, titles and descriptions remain. Flight controls, 3D and animation code unchanged. npm run build and git diff --check pass.

Initial-load label refinement: removed only the global stage onLanded label callback. Opening assembly still plays, but no part names appear on first load/refresh. Existing updateTags continues showing the four restored part labels only in the Taken apart scene. Its staged timing, anchors and animation remain unchanged. npm run build and git diff --check pass.
