# Person 3: Flutter application and integration: handoff

Branch: `app/runtime`

Owned paths: apps/mobile/, packages/inspection_runtime/, tools/, .github/workflows/, docs/app/, docs/status/app.md, docs/handoffs/app.md

Contract: v1.0.0

Latest device update: the indexed merged APK installed and launched successfully on Samsung SM-S731B, Android17/API37, arm64-v8a. Startup safety checkbox unchecked/Start disabled; camera permission initially ungranted. App-scoped sampled logs showed no matching fatal errors. User-assisted gallery selection is ongoing; no successful upload result or camera acceptance recorded yet. `docs/app/DEVICE_SMOKE.md` supersedes prior no-device statements below. Local screenshots stay in ignored build output; private photos must not enter Git.

## Completed and commit
Combined APK source: `0f9c249faeb876f5e6d63d63f20959cf6c1096cc`, merging latest frontend `4c28f735d6a0ec0f1c07f8a3d04db9e413fdf55c` into `app/runtime` without conflicts at the user's explicit request (overriding the independent-development timing for this one branch). Original runtime: `e06f4362fc8eb73bbbbf0cb94ee31bebfc3b3ac4`. Subsequent docs/index/CI commit contains this handoff. No other role branches merged; no push, deployment or external message performed.

Implemented real local acquisition infrastructure: gallery selection and interrupted-picker recovery; rear camera preview and sequential still sampling; no microphone capture; lifecycle shutdown; fresh safety confirmation after background; one decode/engine operation with at most one pending upload; cancellation/generation/input-ID guards; isolated JPEG/PNG normalization including EXIF reflection; same-still bounding-box geometry; strict pending/verified reference parser; guarded v1 native-output adapter; explicit Android unavailable handler; arm64/API24+ debug-signed release packaging; CI and APK-index tooling.

Requirements addressed in infrastructure: R1, R5, R6, R7, R8, R9, R11. R1/R9 hardware acceptance remains pending, and no real R2–R4 detection is claimed. Frontend screens/branding are integrated; the ML core/reference are absent.

## Run/build/test and actual results
Use `docs/app/README.md` for exact prerequisites/commands. Flutter 3.47.9 / Dart 3.13.7, JDK21, API36, Build Tools36.0.0, NDK28.2.13676358. Run contract checker; then `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test` separately in runtime and mobile. Runtime: 46 tests passed; mobile: 1 widget test passed; analysis clean. `flutter build apk --release --target-platform android-arm64` built the sideload APK. Signature/package/ABI/hash evidence is in `docs/app/VALIDATION.md` and `docs/app/apk.json`. No phone/emulator was tested; device list empty. No FPS, full capture-to-display latency or accuracy measured.

Post-merge: UI/mobile lockfile resolution and analysis passed; UI 14 checks, runtime 46 tests and mobile 1 widget test passed (61 total). Rebuilt merged APK is 17,969,237 bytes, SHA-256 `e290b046ad624ccd78bff6983f751d4ded8ba689aacb2056994208a6282943a2`. Signature v2, arm64-only and intended permissions verified. Windows USB sees a Samsung phone; ADB lists none. User is fixing debugging setup before installation and actual hardware checks. CI now includes the integrated UI suite.

## Assets/data/model/reference versions
`apps/mobile/assets/reference.json`: v1 schema, reference_version `pending`, no motor mapping, app-owned pending bundle. Engine unavailable; no detector weights or real data included. No excluded old ZIP/assets imported. App/runtime dependencies pinned in lockfiles. Local APK and resource gaps indexed in `docs/app/deliverables.json`; no shared release uploaded. At final integration coordinate the root `resources/manifest.json` with source/rights/version/hash/access for all real resources; it was not silently edited here.

## Fixtures, blockers and limitations
Runtime unit tests and contract fixtures are synthetic test evidence only. Some guard tests deliberately simulate a real wire marker under explicitly labelled test doubles; never use these as demo predictions. No detector is bundled. A missing or pending reference never invokes inference; missing channel/engine, timeouts, invalid outputs and incomplete evidence abstain. No physical drone/variant/config/model/dataset is verified. Sampled live input lacks tracking, so verified live statuses are downgraded to Unable to Verify. HEIC/animated/oversized inputs are unsupported. Rear-camera EXIF/preview crop and phone permissions/lifecycle need physical validation. The baseline frontend still says pending, lacks a Stop button and does not yet render uploaded-image findings; withdrawing safety stops live meanwhile. Android Debug signing is for hackathon sideload only; no keys committed or store-readiness claim.

The frontend-baseline limitation above describes the original candidate only: the merged frontend now supplies safety flow, Stop controls and upload findings. Validate its first camera-permission prompt, missing-engine state and lifecycle behavior with the real runtime on the phone. No supplied frontend widgets were modified during merge.

## Teammate preferences and decisions
One optional environment/preference question was asked. User: no connected device now, will do it later. Budget preference: conserve five-hour usage; focused infrastructure work, no extra agents or unrelated redesign. Relevant skill catalog inspected; no design skill applied to runtime/native work. Shared controller/engine signatures and schema files remain unchanged. Documentation is sufficient to continue device checks and adapter coordination later.

Latest steering supersedes device timing: phone is now cabled; user is fixing debugging authorization while the requested frontend merge/build is completed. Other branch integrations remain deferred. No shared API/schema changes were needed for frontend integration.

## Shared change proposals
App-local proposed native channel `org.plutoinspection/verification_v1`, `verify` request (encoded upright PNG + image metadata + full versioned reference), returning a strict v1 map. No consumer has agreed yet; details in `docs/app/ENGINE_ADAPTER.md`. ML must agree preprocessing, binary/model/ABI, observability/tracking, initialization/cancellation and resource-release semantics and supply a real Android proof. Proposed reason `LIVE_TRACKING_UNAVAILABLE` uses v1's open reason strings; frontend/ML review pending. No shared type/schema changes were made.

## Receiving owner and next task
ML/app: prove compatible Android inference and failure path before replacing the explicit unavailable handler. Research/ML: supply exact reviewed reference, real labelled data/resources and methodology/metrics. Frontend: render state.image/findings, inject preview, wire Stop and update baseline labels using unchanged v1 API. User/app: install the indexed APK on an arm64/API24+ phone and execute `docs/app/DEVICE_CHECKLIST.md`; record actual findings/screenshots and latency. App owner: at the agreed final window assemble branches into `integration/final`, validate the exact combined APK, finish deliverable/resource index, then open a reviewed PR. Do not promote to main or publish automatically.
