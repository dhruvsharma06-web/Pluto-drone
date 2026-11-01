# Runtime validation — 1 November 2026

Current camera layout: [large capture view](LARGE_CAPTURE_VIEW.md), source `fe2e1dd`. 50 runtime + 17 UI + 1 mobile tests/checks pass (68); app/UI analysis clean, APK signature verified, installed/launched on Samsung. User chose to finish without the enlarged-preview screenshot; native layout percentage/appearance remains unverified. Current indexes supersede older artifact identities below.

Current replacement: [camera fix](CAMERA_FIX.md), source `ddc5f40`, 50 runtime + 15 UI + 1 mobile checks passed (66 total); analysis clean. Stable preview/manual shutter built, installed and user-tested on Samsung; user reported steady preview and successful photo capture. Current APK identity is in `apk.json`; prior hashes/tests below are historical.

Latest physical evidence: [device smoke report](DEVICE_SMOKE.md). The merged APK now installs and launches on Samsung SM-S731B / Android17 / API37 / arm64-v8a; startup safety gate observed. This supersedes prior no-ADB/no-install statements below. Full gallery/camera/lifecycle and detector validation remain pending.

## Latest combined frontend/runtime candidate

At the user's explicit request, `frontend/flutter` (`4c28f735d6a0ec0f1c07f8a3d04db9e413fdf55c`) was fetched and merged without conflicts into `app/runtime`: **`0f9c249faeb876f5e6d63d63f20959cf6c1096cc`**. No other role branch was merged and no push/publication was performed. This supersedes the original frontend-baseline and independent-branch statements below.

Actual post-merge checks: UI `flutter analyze` clean and **14 tests passed**; mobile analysis clean and **1 widget test passed**; runtime **46 tests passed**; contract checks passed. `flutter pub get --enforce-lockfile` succeeded for UI/mobile. Built release-mode arm64 APK: **17,969,237 bytes**, SHA-256 **`e290b046ad624ccd78bff6983f751d4ded8ba689aacb2056994208a6282943a2`**. `apksigner` verifies v2; `aapt` reports arm64-v8a only, API24 minimum/API36 target, CAMERA/ACCESS_NETWORK_STATE/app-scoped receiver permission. Actual merged APK metadata is in `apk.json`; previous artifact hashes below are historical.

Windows detects the USB-connected Samsung phone, but ADB still lists no devices. The user is fixing debugging setup while merge/build checks complete. No app installation, phone screenshot, camera/permission/lifecycle validation, Android version or on-device timing has been recorded. Full detector/reference remain absent; expected production status remains Unable to Verify. No design changes were made to the frontend during integration; its supplied layout/assets were preserved.

## Original runtime-only candidate evidence

Branch `app/runtime`. Runtime source commit: `e06f4362fc8eb73bbbbf0cb94ee31bebfc3b3ac4` (implementation `03166f6`, ignore correction `fbd43fc`, release packaging fixes `fa908db` / `e06f436`). Later documentation/index commits do not change runtime source. Host Windows; Flutter 3.47.9 stable / Dart 3.13.7; JDK 21.0.12. Temporary local SDKs/caches were installed, without committing their paths or binaries.

## Actual automated results

| Check | Result |
|---|---|
| `tools/.venv/Scripts/python.exe tools/check_contracts.py` | PASS: v1 schemas, 4 labelled fixtures, pending reference, 7 rejected unsafe mutations; also validates app-bundled reference |
| `flutter analyze` in `packages/inspection_runtime` | No issues found |
| `flutter test` in `packages/inspection_runtime` | 46 tests passed |
| `flutter analyze` in `apps/mobile` | No issues found |
| `flutter test` in `apps/mobile` | 1 widget test passed |
| `python -m py_compile tools/write_apk_manifest.py` | Passed |
| `git diff --check` | Passed; Git reports ordinary LF/CRLF conversion notices |
| `flutter build apk --release --target-platform android-arm64` | Built final release-mode APK with debug signing, 17,286,343 bytes (Flutter reports 16.5 MB); exact-source rebuild recorded in APK index |

Runtime tests exercise safety gating, acquired image with missing reference, cancelled picker, adapter failure, stale output after safety withdrawal/reference replacement/backgrounding, superseding input with bounded engine concurrency/pending-upload cap, camera denial, picker background/recovery, sampled-live abstention, late capture after stop, disposal, missing native channel, timeout latching, strict result/reference validation and 15 unsafe-result mutations. Synthetic colored JPEG fixtures cover EXIF orientations 1–8, dimensions and reflection/rotation corner checks; invalid/unsupported/oversized encoded input and still viewport letterbox/crop mapping are checked.

All test images, reference motor IDs and mock engine results are **synthetic test fixtures**, not predictions or supplied-drone evidence. Some synthetic test doubles deliberately use the `real` wire marker to exercise the production validator; this is explicitly labelled in test source and never exposed as a real demo. No accuracy/precision/recall/confidence probabilities were measured or claimed.

## Build findings and resolved issues

The shell initially had no accessible Flutter/Android SDK on PATH; official Flutter stable and Android command-line tools were installed in temporary local tooling. Android command-line tools SHA-256 was checked against the official download page: `90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a`. The first Gradle attempt failed because the new Android CLI parsed Flutter's automatic NDK installation incorrectly (`Package ndk not found` / `Package 28.2.13676358 not found`). Explicit installation of `ndk;28.2.13676358` resolved that failure. A later SDK XML-version warning was non-fatal. The initial EXIF test used a null matcher incorrectly; corrected to `isNull`, then all 46 passed. An ignore-file review restored pre-existing Android/generated/signing exclusions and removed the generated registrant from the final source tree.

## Not verified / remaining acceptance

- No physical Android device or emulator was used; the user will connect a phone later. Camera acquisition, permission revocation, process recreation, lifecycle, still/preview orientation and actual installation are **Unable to Verify** on hardware.
- No supplied drone, exact variant, reviewed reference motor map, real labelled dataset, trained model or Android vision core was available. The bundled reference remains pending. Native inference explicitly returns unavailable. No OpenCV/C++/FFI execution or detection quality is claimed.
- Sampled live input cannot claim continuously tracked verification. Verified live statuses are downgraded to `LIVE_TRACKING_UNAVAILABLE` pending a coordinated tracking/evidence protocol.
- `elapsed_ms` instruments capture-to-result-construction for live and bytes-ready-to-result-construction for upload. It excludes Flutter raster/display time and upload picker/file-read time. No full device end-to-end latency/FPS benchmark has been recorded.
- Frontend package remains baseline (pending labels, no dedicated stop button, no upload-image/fault rendering). New runtime data and preview injection are ready for the frontend handoff; its widgets were not changed here.
- Other workstream branches were not merged. No full final integration, real-detector APK, final resource bundle, shared artifact upload, store signing or deployment was performed. Follow `DEVICE_CHECKLIST.md` and coordinate the resource manifest/final PR only in the agreed integration window.

APK signature, package/API/ABI inspection and SHA-256 are recorded with the artifact in `apk.json` / `deliverables.json`; cryptographic/structural inspection is not physical-device validation.

Initial APK inspection revealed transitive microphone/storage permissions and non-arm64 plugin libraries despite the arm64 Flutter engine target. The final packaging change explicitly removes those unused media permissions and restricts all native libraries to arm64-v8a. The final artifact was rebuilt and reinspected after the change. `adb devices -l` returned an empty device list. Signing is Android Debug (APK Signature Scheme v2), with certificate SHA-256 `42b80b453863931b4570cb6a8b03524cedf0d7191cddd54780f2dfc518f31cf4`; this is a public certificate digest, not signing material.

Flutter 3.47 overwrote the custom ABI filter until `disable-abi-filtering=true` was set in the owned Gradle properties. Final `aapt dump badging`: package `org.plutoinspection.pluto_inspector` 0.1.0/code 1, min API24 / target API36, native-code **arm64-v8a only**; permissions CAMERA, ACCESS_NETWORK_STATE and the app-scoped DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION. `apksigner verify --verbose` passes v2. APK SHA-256: `789cec3c654e341567192f8675a969ca8ae417e52ff99a054da2e6949823761c`. APK index dirty flag is true because handoff/docs were being written; runtime/app/tool/workflow source paths matched the recorded commit at final build/index.
