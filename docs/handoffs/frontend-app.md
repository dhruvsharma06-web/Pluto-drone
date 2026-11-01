# Flutter frontend handoff

Branch: frontend/flutter. Base: 78c704b0618d0e0a91b562e410ee098b64564584. UI implementation commit: 089932cae790a566aa87888f68dc50af78d72100. The subsequent handoff/icon-resource commit is the branch head. Primary owned paths (plus the user-requested Android launcher resource extension): packages/inspection_ui/, docs/frontend/, this handoff and frontend status. R1/R4/R5/R6/R7/R8/R11 UI coverage; contract v1.0.0 unchanged.

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

Final analysis: no issues. Final UI suite: 14 checks passed. Current tests cover safety blocking, immediate removal of old Pass, inconsistent/missing evidence refusal, controller failure recovery, fixture provenance labelling, mode changes, normalized portrait/rotated geometry, invalid boxes, responsive widths and enlarged dark text. Final results recorded in docs/frontend/VALIDATION.md.

## Resources and limitations

Original logo SVG + white variant, 1024 launcher, transparent foreground, density PNGs and adaptive XML under assets/brand/; Roboto licence included. Public preview uses an original illustrative diagram, not a drone photograph or dataset ground truth. Team photos remain local and are excluded from Git. See docs/frontend/ASSET_PROVENANCE.md.

No real camera, picker, ML inference, dataset evaluation or verified motor map is implemented here. Preview actions/scenarios are synthetic and visibly labelled. A device was initially visible to ADB but disconnected before native verification. Do not claim screenshots came from Android hardware or that the preview is the final APK.

Next receiver: app owner. Merge only in the agreed final integration window, connect actual controller/core and test installed APK/device lifecycle. ML owner supplies real reference/engine outputs; no model/data choice was changed. Shared change proposals: none required; app owner may expand stable error codes for more specific permission/device failures.
