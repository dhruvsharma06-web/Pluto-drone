## Minimal rounded refinement — 1 November 2026

Visual-only refinement: separate pill-shaped input choices, shorter repeated helper copy, softer result/sheet corners, and motor details in the existing Where/Why/Correction sheet. Safety confirmation, exact result labels, fixture disclosures, error guidance and runtime logic are preserved. Existing colours/fonts/brand retained; no reference colours or business content copied. Motor sheets reopen on repeated taps and still close immediately when invalidated.

UI analysis clean; all 25 tests passed, plus the extended sheet reopening check. Responsive checks cover 320/390/768/1440px at 1.0x/1.5x. Updated local phone start/result renders inspected. ADB lists no connected device, so updated hardware testing/installation is pending. Impeccable and Emil guided hierarchy, touch targets and restrained feedback. APK/source provenance is recorded in docs/app/FLUTTER_ALIGNMENT.md.

## 1 November 2026 — release build installed and launched on Samsung device

Release APK built (`apps/mobile/build/app/outputs/flutter-apk/app-release.apk`, SHA-256 `892fc40b3398d7094f8e8b8ad66cab3e42659e223e8b4ea160e8f312410202cd`, 17.7 MB).
Installed to connected Samsung phone (`SM-S731B`, serial `RZGL60BDTJL`) via ADB streamed install, launched `org.plutoinspection.pluto_inspector/.MainActivity` (PID 21765 running).
All automated checks verified clean: 25 inspection_ui tests pass, 50 inspection_runtime tests pass, 1 mobile test passes, static analysis clean on all packages, contract validator passed.

## 1 November 2026 — website alignment on app/runtime

User explicitly selected app/runtime to preserve the stable camera and large capture screen. UI now follows black/white/purple with Inter/Playfair, labelled stage, shape-coded results and invalidation-safe motor sheets. Launcher text aligned by app owner. v1/runtime logic unchanged. No merge/push. Reconcile UI changes with frontend/flutter before coordinated integration; preserve runtime camera fixes.

UI analyze clean, 25 UI tests passed; mobile analyze clean, 1 widget check passed. Nineteen local renders reviewed across the requested width/text matrix. ADB had no connected device; native screenshots/retesting not performed. Full scope, source/artifact follow-up and limitations: [alignment report](../app/FLUTTER_ALIGNMENT.md). Entries below describe earlier builds.

# Person 3: Flutter application and integration: status

Branch: `app/runtime`

State: MERGED CANDIDATE INSTALLED/LAUNCHED ON PHONE; FULL DEVICE ACCEPTANCE AND REAL DETECTOR PENDING.

Current capture layout: `fe2e1dd8f624afea91bc30455db7f63f9386dff5`, dedicated large camera screen targeting ~65–70% portrait viewfinder after shutter space; full-width Take photo below, Close/Android Back return to inspection. 50 runtime + 17 UI + 1 mobile checks pass (68). App/UI analysis clean; rebuilt, signature-verified, installed/launched on Samsung. User explicitly chose finish without a preview screenshot; final native appearance/percentage remains unverified. See `docs/app/LARGE_CAPTURE_VIEW.md`. Prior milestone evidence follows.

Latest fix: `ddc5f409a511e91e15595a3af8ef15561bdc8586`. Replaced 750-ms automatic still loop with steady preview and explicit Take photo; fixed permission-dialog cancellation and final UI session flag. 50 runtime + 15 UI + 1 mobile checks pass, all analysis clean. Rebuilt/installed on Samsung; user confirmed “Preview steady; photo captured.” Accessibility showed a frozen image and Start available again. No private photo committed. See `docs/app/CAMERA_FIX.md`; full permission/lifecycle/rotation and real detector checks remain pending. Subsequent entries are earlier milestone evidence.

Latest physical smoke: USB debugging authorized; APK installed and launched successfully on Samsung SM-S731B, Android17/API37, arm64-v8a. Initial unchecked safety gate/disabled Start observed; no matching fatal errors in sampled app logs. User is trying gallery upload; captured upload screen has not yet shown selected photo/result. Camera and complete acquisition/lifecycle tests remain pending. See `docs/app/DEVICE_SMOKE.md`; no private photo committed.

Combined APK source commit: `0f9c249faeb876f5e6d63d63f20959cf6c1096cc`, merging latest `frontend/flutter` `4c28f735d6a0ec0f1c07f8a3d04db9e413fdf55c` at the user's explicit request. Earlier runtime implementation source: `e06f4362fc8eb73bbbbf0cb94ee31bebfc3b3ac4`.

Implemented: system image picker/recovery; sampled rear-camera stills and injected preview; safety/lifecycle cancellation; unique input IDs; bounded decode/inference and pending import; isolate JPEG/PNG EXIF normalization; still viewport geometry; reference validation; fail-closed native adapter/result guard; arm64 sideload packaging; CI and reproducible handoff/docs.

Actual post-merge checks: 46 runtime tests + 14 frontend checks + 1 mobile widget test passed; frontend/mobile analysis clean (runtime analysis previously clean); contract checker passed (4 labelled fixtures, 7 unsafe mutations, bundled pending reference); merged arm64 APK built with debug signing and verified signature/ABI/permissions. See `docs/app/VALIDATION.md` and `docs/app/apk.json`. Windows sees a connected Samsung phone; ADB still lists no devices, so installation/phone testing is pending debugging setup.

Blockers: real supplied-drone reference/variant, dataset/model, Android ML engine, ADB authorization/physical phone validation and remaining end-stage integration. Frontend is now merged. Production cannot verify installations; missing inputs/engine remain Unable to Verify. Live tracking is unimplemented and live verified statuses abstain. No latency/FPS/accuracy claim.

Latest user steering: merge latest frontend into current runtime branch (completed); phone is cabled and user is fixing USB-debugging setup. Conserve usage; no extra agents, unrelated redesign, cloud workaround, push or deployment. Other role branches remain independent. Supplied frontend design preserved; no design skill workflow needed for this merge/build-only work.

Next: ML/app agree the documented Android adapter proposal and proof; research/ML supply reviewed reference/resources; frontend consumes unchanged v1 controller/preview; user follows phone checklist. Leave ~90 minutes before each estimated round for coordinated final integration. Source changes are local commits on `app/runtime`.
