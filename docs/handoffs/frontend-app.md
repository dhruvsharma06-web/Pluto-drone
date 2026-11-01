# Flutter frontend handoff

Branch: frontend/flutter. Primary owned paths (plus the user-requested Android launcher resource extension): packages/inspection_ui/, docs/frontend/, this handoff and frontend status. R1/R4/R5/R6/R7/R8/R11 UI coverage; contract v1.0.0 unchanged.

## Integration

Existing composition remains valid:

```dart
InspectionApp(controller: appController, cameraPreview: cameraPreview)
```

Caller disposes controller. Supply fresh state/result identities, current upright image bytes and exact normalized boxes. UI prefers the analyzed image over external preview when image bytes exist. No overlays are guessed onto a bare camera preview. Ensure the engine validates full expected-motor coverage; the UI guard cannot independently prove that from v1. Sample motor identities/types in preview are deliberately fictional.

At final integration app owner runs: python packages/inspection_ui/tool/install_app_icon.py . Preview launcher already branded; production launcher copies are packaged but Only Android launcher resources in apps/mobile are updated, as explicitly requested; runtime code is untouched.

Optional args: themeMode, demoMode, developmentControls. Production uses demoMode false with no developmentControls. Fixture evidence always shows a simulated-results notice. No pubspec/composition-root change outside this package is needed; run flutter pub get after merge to refresh local path dependencies.

## Run / verify

From packages/inspection_ui: flutter pub get; flutter analyze; flutter test.
From its example: flutter pub get; flutter run.
Native screenshot follow-up: set PLUTO_SCREENSHOTS to your output folder; flutter drive --driver=test_driver/integration_test.dart --target=integration_test/inspection_smoke_test.dart -d YOUR_DEVICE_ID.
For widget PNGs: flutter test --dart-define=SCREENSHOT_DIR=ABSOLUTE_OUTPUT_FOLDER.

Final analysis: no issues. Current UI suite: see docs/frontend/VALIDATION.md. Current tests cover safety blocking, immediate removal of old Pass, inconsistent/missing evidence refusal, controller failure recovery, fixture provenance labelling, mode changes, normalized portrait/rotated geometry, invalid boxes, responsive widths and enlarged dark text. Final results recorded in docs/frontend/VALIDATION.md.

## Resources and limitations

Original logo SVG + white variant, 1024 launcher, transparent foreground, density PNGs and adaptive XML under assets/brand/; Roboto licence included. Public preview uses an original illustrative diagram, not a drone photograph or dataset ground truth. Team photos remain local and are excluded from Git. See docs/frontend/ASSET_PROVENANCE.md.

No real camera, picker, ML inference, dataset evaluation or verified motor map is implemented here. Preview actions/scenarios are synthetic and visibly labelled. A device was initially visible to ADB but disconnected before native verification. Do not claim screenshots came from Android hardware or that the preview is the final APK.

Next receiver: app owner. Merge only in the agreed final integration window, connect actual controller/core and test installed APK/device lifecycle. ML owner supplies real reference/engine outputs; no model/data choice was changed. Shared change proposals: none required; app owner may expand stable error codes for more specific permission/device failures.

Visual redesign: interactive original framing scene, processing scan graphics, evidence pinch zoom, status-change feedback. Contract v1 and detection separation unchanged. Validation updated in docs/frontend/REDESIGN.md.

Latest user direction: true black/white authored UI and launcher branding, 32sp headings / 24sp title / 18sp controls and body. Removed tagline, setup-tip repetition, progress strip, decorative source captions and duplicate safety subtitle. Detailed instructions remain under Guide. Evidence photographs remain unfiltered. Controller/core separation and result/safety rules unchanged.

## Findings integration (PRISM behavior reference)

Supply motor_id, normalized bbox, finding and observed/expected type/orientation through the existing v1 motor maps. The UI highlights mismatch/unknown boxes, opens Where/Why/Correction on tap, and repeats the same explanation in the list. Positions are explicitly image-relative, not an inferred physical motor map. Missing coordinates produce no box. New inspection/state invalidation dismisses old detail sheets.

The v1 schema has no per-motor narrative-reason field. Current Why text is derived only from observed/expected differences; a mismatch without a supplied distinction says its specific reason was not supplied. Do not inject unscoped overall reasons into a particular motor. If the ML producer needs richer per-motor explanations (for example visible absence versus occlusion), coordinate an optional schema extension with app and UI consumers before emitting new fields. No shared schema changes were made here and no model/dataset choices were prescribed.

Final latest validation: analysis clean; all 18 UI checks passed. See docs/frontend/VALIDATION.md.
