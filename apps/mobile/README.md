# Android Flutter shell

App owner workspace. The shell injects the runtime controller and camera preview into the merged `inspection_ui` frontend. Gallery acquisition, sampled rear-camera stills, EXIF normalization, lifecycle cancellation and guarded engine output are implemented. The bundled reference is pending and the native engine is explicitly unavailable; this is not a working detector. The integrated frontend includes the safety journey, upload evidence view and Stop controls.

Tested toolchain: Flutter 3.47.9 / Dart 3.13.7. Release mode intentionally uses debug signing for hackathon sideload only, not store distribution. See [runtime build guide](../../docs/app/README.md), [adapter boundary](../../docs/app/ENGINE_ADAPTER.md) and [physical-device checklist](../../docs/app/DEVICE_CHECKLIST.md).

Gradle launchers are ignored generated files; Flutter's build generates them. If needed, copy only the cached launchers as described in the build guide. Preserve existing source/config rather than regenerating the project. No SDK paths or signing material are committed.
