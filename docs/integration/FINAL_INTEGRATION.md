# Final integration — 2026-11-01

Branch `integration/final`. Merged: `app/runtime` (camera/acquisition/runtime, Android shell),
`frontend/flutter` (final `packages/inspection_ui`, taken wholesale on conflicts per the frontend
owner), `frontend/website` (at the commit available when merged — re-merge the friend's latest),
and the on-device engine below. `ml/vision` holds the training pipeline, notebook and labels.

## On-device verification engine (Android)

`apps/mobile/android/.../PropellerEngine.kt`, called through the existing
`org.plutoinspection/verification_v1` `verify` channel; output is validated by the existing
Dart guard (`validateEngineResult`).

1. Decode upright PNG from acquisition.
2. Quality gates (320 px grey): Laplacian variance < 60 → `IMAGE_BLURRY`; mean < 45 →
   `IMAGE_TOO_DARK`; mean > 235 → `IMAGE_OVEREXPOSED`. Calibrated on the real photos (sharp
   photos ≥ 134, blurred copies ≤ 12).
3. YOLO11s ONNX (`assets/models/propeller.onnx`, 640×640 letterbox, classes 0=cw 1=ccw),
   ONNX Runtime Android, class-agnostic NMS.
4. Exactly 4 confident propellers required (`NO_PROPELLERS_DETECTED`, `INCOMPLETE_DRONE_VIEW`,
   `AMBIGUOUS_DETECTIONS`, `LOW_CONFIDENCE_CLASSIFICATION`).
5. Top-down motor assignment: body long axis from PCA of dark body pixels; head = wider end;
   perspective check (opposite propeller spacings within 20%). Otherwise
   `UNSUPPORTED_VIEW_TOP_DOWN_REQUIRED`.
6. Compare with `apps/mobile/assets/reference.json` → pass / incorrect_installation, else
   unable_to_verify. Orientation is reported as `not_assessed` (not observable from one photo).

`vision/verify.py` on `ml/vision` is the desktop twin of this engine for testing.

## Reference

`assets/reference.json` (`pluto-guide-2026-11-01`, status verified by the project owner's
decision): front_left cw, front_right ccw, rear_left ccw, rear_right cw; head = wider body end.
Source: user-supplied annotated guide plus arm-mount evidence (screw arms carry CW, hook arms
carry CCW). This is a user-supplied reference, not an organizer-published configuration.

## Voice and Gemini

`apps/mobile/lib/assistant.dart`: every real result is spoken offline (flutter_tts) with
retake guidance for blur/darkness/incomplete/unsupported views. "Explain" sends only the result
summary (status, reasons, motor findings — no photo) to Gemini (`gemini-3.8-flash`, falling back to `gemini-flash-latest` and `gemini-flash-lite-latest` on 503). The key is a
build-time define and must never be committed:

    flutter build apk --release --target-platform android-arm64 --dart-define=GEMINI_API_KEY=<key>

Without a key, or offline, the built-in guidance is shown instead.

## Model files

The ONNX model is distributed with the APK and recorded (path, SHA-256, metrics) in
`docs/integration/model.json`; weights are not committed (repository rule on large binaries).

## Deployed backend

- GCP project `pluto-inspector-1101` (billing linked), Cloud Run service `pluto-explain-proxy`
  in `asia-south1`: https://pluto-explain-proxy-619853330643.asia-south1.run.app
- Public ingress; every `/explain` call must carry a Firebase ID token for project
  `pluto-inspector-1101` (verified server-side; missing/invalid tokens return 401).
- Gemini key in Secret Manager `gemini-api-key`, readable only by the Cloud Run service account.
- App build: `--dart-define=EXPLAIN_PROXY_URL=<url>`. The app uses the proxy once Firebase is
  configured (`android/app/google-services.json`); until then it falls back to the direct key.
