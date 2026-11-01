# Website check record

Date: 2026-11-01 (IST). Branch `frontend/website`. Machine: Windows 11, Node 24.21.0, npm 11.19.0.
Browser: Chromium in the Claude desktop app's browser pane, against the Vite dev server (`npm run dev`).

## Commands run and results

| Command (in `apps/website/`) | Result |
|---|---|
| `npm install` (via `--registry=https://registry.npmmirror.com`, lockfile URLs rewritten to registry.npmjs.org; same tarballs and integrity hashes) | Installed. The npmjs registry served metadata at about 20 KB/s on this network, hence the mirror. `npm ci` from the committed lockfile was **not** re-run on a clean machine. |
| `npx tsc --noEmit` | Pass (0 errors) |
| `npx vitest run` | Pass: 1 file, 8 tests |
| `npm run build` | Pass. three.js is split into its own lazily loaded chunk (≈550 kB, ≈141 kB gzip); main JS ≈25 kB, CSS ≈33 kB |
| `npm run check` | Pass (typecheck + tests + build) |

What the tests cover: exact result labels; no Pass with any missing evidence or reference across all 384 demo input combinations; Incorrect Installation only with full evidence and a confirmed mismatch; contract invariants; every demo result labelled `fixture`; demo presets reproduce `contracts/fixtures/{pass,incorrect,unclear,pending}.json` exactly. They test the website's fixture demo only, **not** any detector.

## Browser checks (actually performed)

- Desktop 1280×800 and 1440×900 (emulated, final black-and-white build): the hero is centred, the drone is gloss black with white light and smoke, and the header turns solid on scroll. The assembly intro plays (body → arms → motors → propellers, each labelled as it lands), then the headline appears. Scroll captions move through airframe → body shell → arms → motors → propeller. Camera poses, focus highlight, separated arms and part labels follow the active caption.
- Exploded view: at ≈45% scroll progress the shell and arms are separated with the Body shell and Arms labels showing. At ≈97% all four groups are separated, all labels show, the caption reads "Every part the inspection depends on." and the meter is full. The spread was tightened after this capture.
- Explore plate: the tabs switch component, fly the camera to it and swap the card copy. The tool rail, turn bar and views respond. Viewer state reached `ready`.
- Keyboard: focus on the viewer, then ArrowRight×3 and `+`×2 rotated and zoomed it.
- Expanded view: Expand opens a modal dialog with focus on Close. Esc closes it, focus returns to Expand and the stage returns to the page.
- Fixture demo (scripted clicks): wrong type → Incorrect Installation. Blur → Unable to Verify (BLUR). The incorrect.json preset shows the shared fixture file. Reference off → Unable to Verify (REFERENCE_NOT_CONFIGURED).
- Mobile 375×812 (emulated, checked before the final palette and centred-hero change; not re-checked after): no horizontal overflow (`scrollWidth` = `innerWidth` = 385, including the pane's scrollbar). Hero and captions readable. The drone sits above the captions.
- Console: no errors on a clean reload. Earlier errors came from superseded hot-reload modules.

## Not checked / limitations

- `prefers-reduced-motion` was **not** emulated (the browser tool cannot toggle it). The code paths exist: no assembly, idle drift, scroll pose easing, grain, marquee or word reveal; poses snap; the turn becomes instant.
- No Firefox, Safari or real phone. No Lighthouse or frame-timing measurement; performance was judged visually on one machine.
- WebGL-failure fallback was not forced in the browser. The code path keeps the SVG poster and sets a status message.
- Screenshots were taken while the app's browser pane was hidden, so CSS transitions were throttled and some frames are mid-animation.
- The site is designed desktop-first, per the team's direction. Mobile was checked for overflow and readability only.

## Latest pass (scene redesign)

- Same commands re-run after the redesign: `npm run check` passes (tsc 0 errors, vitest 8/8, vite build).
- Desktop 1440×900: all seven scenes visited. The intro assembles, then copy appears. Taken apart separates with labels. The propeller close-up shows the resting-angle label. Results and the demo render, Explore renders after the CSS fix, and Project renders. No console errors. With the fixed canvas and snap sections, page height is 7 viewports (≈6375 px at 900 px tall).
- Not re-checked after the redesign: mobile layout, keyboard pass through every scene, reduced motion.

## Screenshots (captured)

- `screenshots/desktop-1440-hero-fog.jpg`: final intro with purple stage fog.
- `screenshots/desktop-1440-taken-apart-earlier-lighting.jpg`, `...-propeller-earlier-lighting.jpg`, `...-results-earlier-lighting.jpg`: same scenes, captured before the lighting was darkened.
