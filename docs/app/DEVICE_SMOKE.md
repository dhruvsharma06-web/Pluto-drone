# Physical device smoke test — 1 November 2026

Latest replacement: [camera fix/device follow-up](CAMERA_FIX.md), source `ddc5f40`. User confirmed steady preview and successful capture after the manual-shutter fix. The observations below describe the preceding `0f9c249` APK and remain historical, including that candidate's unresolved upload/camera tests.

Device: Samsung **SM-S731B**, Android **17**, API **37**, ABI **arm64-v8a** (read through ADB). Device serial is intentionally not recorded.

Artifact: merged frontend/runtime source `0f9c249faeb876f5e6d63d63f20959cf6c1096cc`; version 0.1.0/code 1; APK SHA-256 `e290b046ad624ccd78bff6983f751d4ded8ba689aacb2056994208a6282943a2`. The APK matches the committed artifact index.

## Actual observations

- USB debugging authorized; phone visible to ADB.
- `adb -d install -r .../app-release.apk`: **Success**.
- `adb -d shell am start -W -n org.plutoinspection.pluto_inspector/.MainActivity`: **Status ok**, cold launch; app process and resumed activity confirmed. ADB TotalTime 931 ms / WaitTime 947 ms are startup observations, **not inference latency**.
- Foreground app screenshot captured locally at `apps/mobile/build/device-evidence/launch.png`: merged UI renders in dark mode; safety checkbox initially unchecked and Start live inspection disabled. No Pass result shown.
- Camera runtime permission initially **not granted**; no camera access was required for launch.
- App-scoped sampled logcat contained no matching fatal/Flutter unhandled-error lines during startup/upload-screen observations. This is not an exhaustive crash or lifecycle test.
- User switched to Upload image mode and confirmed the safety checkbox. The captured foreground upload screen still showed no selected image/result; a second explicit gallery-selection attempt is pending user feedback.

The screenshot `apps/mobile/build/device-evidence/upload-result.png` is a local screen observation, not proof of a successful upload. Screenshot filenames are capture labels. These local build artifacts are not committed or uploaded. Any later screenshot containing the user's photo remains private and must not enter Git.

## Not yet verified

Actual gallery acquisition/normalization/result display, live camera, permissions denial/revocation, stop/restart, process recreation, rotation, preview/still alignment and capture-to-display latency remain pending. No physical reference, engine/model, labelled dataset or detector accuracy is verified. The pending reference must continue to produce Unable to Verify. Installing and launching this candidate is a **partial device smoke test**, not complete Android acceptance.
