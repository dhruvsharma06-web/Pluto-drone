# Pluto Inspector website

Public overview site for the propeller installation verifier. Owner: `frontend/website`.
It explains and showcases the Android app. It performs **no** detection or verification.

Stack: Vite 6 + TypeScript + three.js (no framework). All dependencies and the lockfile live in this folder.

## Commands (run inside `apps/website/`)

```sh
npm ci            # reproducible install from package-lock.json
npm run dev       # local dev server on http://localhost:5173
npm run test      # vitest: fixture-demo rules vs contracts/fixtures and contract invariants
npm run typecheck # tsc --noEmit
npm run build     # typecheck + production build to dist/
npm run preview   # serve dist/ locally
npm run check     # typecheck + tests + build
```

The build uses a relative base (`./`), so `dist/` can be served from any static path. Nothing is deployed by this workstream.

## Structure

| Path | Purpose |
|---|---|
| `index.html` | All page content as semantic HTML (readable without JS or WebGL) and the SVG schematic poster |
| `src/main.ts` | Boot: entry reveal, section reveals, story, explore viewer, demo |
| `src/story.ts` | Scroll story: active step → viewer pose and labels. Normal scrolling only |
| `src/explore.ts` | Interactive viewer controls, keyboard, component info, expanded dialog |
| `src/viewer/types.ts` | Asset-independent `DroneAsset` / `Pose` interface |
| `src/viewer/viewer.ts` | three.js renderer, lighting presets, inertia, zoom, views, focus, lifecycle |
| `src/viewer/schematic.ts` | **Illustrative** procedural drone (no motor identities, identical propellers) |
| `src/viewer/gltf.ts` | Adapter for a future approved GLB (unused until the manifest approves one) |
| `src/viewer/asset-source.ts` | Picks the asset from `public/assets/manifest.json` |
| `src/viewer/mount.ts` | Progressive enhancement: poster → 3D, failure keeps the poster |
| `src/demo/` | Fixture demo of the contract's result rules + tests |
| `public/assets/manifest.json` | Website asset manifest |

The demo imports the shared fixtures from `../../contracts/fixtures/` (read-only).

See `docs/website/ASSET_BRIEF.md` to replace the schematic with an approved model, and `docs/website/CHECKS.md` for the check record.
