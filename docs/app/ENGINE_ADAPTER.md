# Android engine handoff — v1

This branch implements acquisition and a guarded adapter boundary. **No OpenCV detector, model or verified motor mapping is installed.** The shared engine/controller schemas remain v1.0.0. This transport is an app-local proposal for ML coordination, not a silently changed shared contract.

## Callable path

`main.dart` → `RuntimeApplication` → `RuntimeInspectionController` → `GuardedVerificationEngine` → `org.plutoinspection/verification_v1`, method `verify`.

The StandardMethodCodec request is a map with `schema_version`, `input_id`, `bytes` (Uint8List, encoded PNG), `width`, `height`, `source` (`upload` or `live`) and `reference` (complete v1 reference map). The response is a **map** matching `contracts/verification-result.schema.json`, not a JSON string. `input_id` and `reference_version` must echo the request. Production rejects `evidence_source: fixture`. Tests use explicitly documented synthetic doubles to exercise the real-output guard; these are never demo predictions.

Android's handler runs on a serial background task queue. It currently returns platform error `ENGINE_UNAVAILABLE`. Missing channel, missing/pending reference, exceptions, malformed/contradictory responses, unknown motor IDs and incomplete verified results all fail closed. A timed-out adapter latches unavailable for that instance because a Dart timeout does not cancel native work. Reinitialization must wait for/release native work safely; do not restart timed-out inference blindly.

## Image and geometry

- Gallery: Android's system picker; no broad storage permission. Recover interrupted picks with `retrieveLostData` and require fresh safety confirmation.
- Camera: rear camera only, microphone disabled. Start opens a stable preview; the app-owned Take photo shutter calls `captureLiveImage` once, closes the camera and analyzes the frozen still. No timer/autocapture loop. No raw YUV/BGRA data is passed as encoded JPEG; **no continuous tracking or real-time claim**.
- Supported encoded input: single-frame JPEG/PNG, at most 20 MiB and 16,000,000 pixels. Unsupported formats including HEIC/GIF, damaged data and larger inputs abstain. No inference resizing is hidden in acquisition.
- Decode, EXIF rotation/reflection (all eight orientations), EXIF metadata removal and PNG encoding run in a Dart isolate. Width/height describe the upright, unmirrored analysis bitmap. Rear-camera device behavior still needs physical validation. Mirrored EXIF is corrected; an undocumented mirrored source with no metadata cannot be inferred.
- Bounding boxes remain normalized `[x,y,width,height]` in **that exact analyzed still**. `UprightImageGeometry` maps boxes to a centered `BoxFit.contain` or cropped viewport. Use it over `state.image`, not over a later preview frame. Preview and capture crop/calibration alignment is unverified; no live overlays are claimed.

## Controller semantics for frontend

Shared methods and `InspectionApp(controller:, cameraPreview:)` are unchanged. The shell injects a plugin-owned preview widget; UI needs no camera dependency. New input, stop, safety withdrawal, lifecycle backgrounding, engine replacement and disposal invalidate old work immediately. One decode/engine job plus at most one pending upload is allowed; repeated pending requests are ignored. Each input gets a unique ID. Errors in acquisition/permissions use `InspectionPhase.error`, not a fourth verification status. Invalid image evidence uses Unable to Verify.

Live sampling always abstains from verified status until a tracking/observability protocol is agreed. Proposed reason `LIVE_TRACKING_UNAVAILABLE` is an app-local stable string, allowed by v1; producer/consumer review is pending. `elapsed_ms` is measured to result construction: live begins before camera capture/file read; upload begins after selected bytes become available and after any queue wait. Upload excludes picker interaction and file read. Neither value includes Flutter raster/display latency; full device capture-to-visible-result measurement is still required. No FPS or device latency is claimed.

Frontend `4c28f73` is now merged into `app/runtime` at the user's explicit request. It renders `state.image`/findings, consumes the injected preview and wires Stop to `stopLive`. Integrated UI tests pass; verify permission-prompt/lifecycle behavior on the connected phone once ADB is authorized. Keep synthetic demos persistently labelled fixture. Layout remains frontend-owned.

## ML proof required before final integration

ML/app owners must agree binary/model format and licensing; an Android ABI/API level; initialization, cancellation/timeout and release semantics; OpenCV preprocessing including color order/resize; whole-drone observability/rejection checks; supported views; exact reviewed reference identity; a real and a rejection fixture; and a native failure path. Python-only execution is insufficient. C++/FFI is still a candidate, with no OpenCV Android feasibility claim on this branch. No cross-owner branch was merged or external message sent.

Replace the unavailable handler only after an actual Android proof. Validate output with the runtime guard and contract checker. Package the reviewed reference in `apps/mobile/assets/reference.json`, with provenance/version/hash recorded in the coordinated resource manifest. Do not convert synthetic fixture labels to physical ground truth.

Sources consulted: [Flutter camera lifecycle/permissions](https://pub.dev/packages/camera), [image picker recovery](https://pub.dev/packages/image_picker), [image orientation](https://pub.dev/documentation/image/latest/image/bakeOrientation.html), [Flutter background platform channels](https://docs.flutter.dev/platform-integration/platform-channels). Resolved versions are in the committed lockfiles.
