# Stable camera preview and manual capture

Source commit: `ddc5f409a511e91e15595a3af8ef15561bdc8586` on `app/runtime`. User explicitly requested repair of repeated live-view reopening and inability to take a photograph.

| Before | After | Why |
| --- | --- | --- |
| An automatic still every 750 ms alternated preview and analyzed image | Start opens preview; Take photo captures one still, closes the camera and freezes that image | The user can frame and deliberately capture without repeated surface changes |
| No shutter control | Native themed Take photo button injected with preview; minimum 48 dp target, disabled during capture | Explicit action and immediate feedback, with duplicate-capture protection |
| Inactive lifecycle event stopped startup | Permission-dialog inactivity hides old results but only actual backgrounding stops the camera | A camera permission prompt must not cancel initialization |
| UI could keep a live session flag after a final result/error | Final result/error clears that flag | Start/Stop controls match actual camera ownership |

The shared v1 controller interface is unchanged. The concrete runtime adds `captureLiveImage`, called only by the app-owned injected preview/shutter. The frontend change is a minimal lifecycle/final-state integration repair under the user's camera-fix request; no layout/brand redesign. Frontend owner should retain these lines when integrating further branch changes.

Native `CameraPreview` owns its portrait/landscape aspect ratio; the extra conflicting wrapper was removed. No animations were added to this frequent task. Impeccable hardening/craft-floor and Emil interaction guidance were applied; existing package PRODUCT.md/DESIGN.md guided the control. Taste was consulted for incumbent/component scope; no new art direction was introduced. Browser/CSS inspectors do not validate this Flutter camera surface.

## Actual verification

- Runtime analysis clean, **50 tests passed**. Regressions: preview does not capture/reopen after the old timer interval; repeated Start ignored; one manual capture; duplicate shutter ignored; late capture after Stop suppressed; failure permits explicit retry; background closes preview and never auto-restarts it.
- UI analysis clean, **15 checks passed**, including inactive permission prompt versus actual backgrounding. Mobile analysis clean, **1 widget test passed**. Contract checker passes. Total **66 tests/checks** across Flutter suites.
- Built arm64 release-mode APK; APK Signature Scheme v2 verifies; min API24 / target API36; only arm64-v8a native libraries. SHA-256 `6a17a03af06eee09680fadb54b516b3819ceaea0a01a08fe9aea4dfbf4f07c40`, 17,969,297 bytes. Debug-signed sideload identity retained.
- `adb install -r`: Success on Samsung SM-S731B, Android17/API37. App launched successfully. User tested the replacement and reported **“Preview steady; photo captured.”** App accessibility observation after the test showed **Full image — no crop** and **Start live inspection** available, consistent with a frozen capture and ended camera session. Sampled app log contained no matching fatal/Flutter unhandled errors.
- User confirmation establishes this device smoke outcome, not comprehensive camera acceptance. No new screenshot containing the user's photograph was committed or published. Denial/revocation, process recreation, long-running sessions, rotation, full display latency and other Android models remain unverified.

Real reference/ML engine remain absent. Verification still fails closed; existing conservative live-status guard is unchanged. No detector quality or real-time claim. See `apk.json` for the replacement artifact and `DEVICE_CHECKLIST.md` for remaining acceptance.

API consulted: [camera lifecycle/permissions](https://pub.dev/packages/camera) and [single-photo capture](https://pub.dev/documentation/camera/latest/camera/CameraController/takePicture.html).
