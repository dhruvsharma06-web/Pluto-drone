# App/runtime candidate

Workstream `app/runtime`; shared contract v1.0.0. Latest `frontend/flutter` (`4c28f73`) merged at the user's explicit request into `app/runtime` as `0f9c249`. UI widgets remain frontend-owned. This is integrated UI, local acquisition and safety infrastructure, **not a functioning propeller detector**. Real reference, Android inference, real dataset, phone validation and remaining end-stage branch integration are still required.

## Reproduce

Use Flutter **3.47.9** / Dart **3.13.7**, JDK 21, Android platform 36, Build Tools 36.0.0 and NDK 28.2.13676358. The generated wrapper uses Gradle 9.3.1 / Android Gradle Plugin 9.1.0. Flutter/SDK caches and `local.properties` are machine-local and ignored; no SDK path or signing key is committed. Add your Flutter `bin` to PATH and set `ANDROID_HOME`/`JAVA_HOME` for your own installation.

```powershell
# From repository root
python -m venv tools/.venv
tools/.venv/Scripts/python.exe -m pip install -r tools/requirements.txt
tools/.venv/Scripts/python.exe tools/check_contracts.py
cd packages/inspection_runtime
flutter pub get --enforce-lockfile
flutter analyze
flutter test
cd ../../apps/mobile
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
```

APK: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`. This release-mode build uses the generated **debug certificate for hackathon sideloading**, not a store identity. No motor/control code, login, cloud service or network inference is introduced. Current build target is arm64-v8a/API 24+; **no physical device is validated**.

Flutter generates ignored Gradle launchers when building. If absent, run `flutter precache --android`, then copy `gradlew`, `gradlew.bat` and `gradle/wrapper/gradle-wrapper.jar` from your Flutter SDK's `bin/cache/artifacts/gradle_wrapper/` to the corresponding `apps/mobile/android/` locations. Preserve the committed wrapper properties and all existing app files; do not regenerate the full project.

If the new Android CLI reports `Package ndk not found` while Flutter tries automatic installation, explicitly install the required package with the downloaded command-line tools: `sdkmanager --sdk_root=<your-sdk> "ndk;28.2.13676358"`, then retry. Local build dependencies must be downloaded; the repository does not bundle SDK/NDK binaries.

## Boundaries and delivery

- [Engine/acquisition/frontend handoff](ENGINE_ADAPTER.md): transport, PNG/EXIF, backpressure, geometry, proposed reason and remaining ML proof.
- [Validation report](VALIDATION.md): actual commands and results, with verification limits.
- [Phone checklist](DEVICE_CHECKLIST.md): install, permissions, lifecycle, latency and supplied-drone acceptance.
- [Deliverable index](deliverables.json): source, APK metadata and still-missing data/model/reference resources. A locally built APK is not a shared download until an authorized resource location is established.

To index an APK from repository root after building a known source commit:

```powershell
python tools/write_apk_manifest.py apps/mobile/build/app/outputs/flutter-apk/app-release.apk --output docs/app/apk.json
```

The index script records the current HEAD and dirty state; run it immediately after a build from that exact source. It does not prove the APK came from HEAD, sign anything, upload a release, or certify device behavior. Final integration must add the agreed externally shared resource metadata/hash to `resources/manifest.json` with all owners' versions.

## Camera fix and current phone evidence

Latest source `ddc5f40` replaces automatic camera sampling with a stable preview and explicit Take photo shutter. It is installed on the Samsung phone; the user confirmed a steady preview and successful capture. All 66 Flutter tests/checks pass with clean analysis. Full report and current artifact identity: [camera fix](CAMERA_FIX.md). A physical camera smoke test does not validate the missing detector.

## Honest demo now

Explain disarm/stopped-motor procedure → confirm → choose a supported upload or start sampled camera input → show **Unable to Verify** due to pending reference/engine → stop/withdraw confirmation/background and show cleared results. The merged frontend includes upload evidence rendering, safety flow and Stop controls. Do not show a synthetic Pass as production output. After the exact real drone/reference and Android engine arrive, use the device checklist for correct/incorrect/unclear examples and record evidence on the exact final APK.

The user explicitly authorized the frontend Flutter merge into `app/runtime`; other role branches remain independent. Planning estimates remain first round 14:33 IST / second 17:33 IST on 1 November 2026; official times are unconfirmed. Target remaining integration windows approximately 13:03 / 16:03 IST or earlier with agreed handoffs. No push, deployment or publication was performed by this work.
