# Bootstrap validation

Checked locally on 1 November 2026 with Flutter 3.47.1 / Dart 3.13.1:

- Flutter dependency resolution: succeeded.
- `flutter analyze` in apps/mobile: no issues found.
- `flutter test` in apps/mobile: pending-state safety widget test passed.
- `python tools/check_contracts.py`: schemas, four labelled fixtures, pending reference and seven rejected unsafe mutations passed.

These validate the scaffold and compatibility examples only. Camera, real model inference, hardware/reference ground truth, dataset quality, Android APK build/install and website rendering remain unimplemented or unverified. No detection accuracy or real-time claim is made. The GitHub workflow runs contract checks only; its execution status is separate from these local results.
