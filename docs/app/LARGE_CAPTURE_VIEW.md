# Large camera capture view

Source `fe2e1dd8f624afea91bc30455db7f63f9386dff5`, `app/runtime`. The user requested a camera/Lens-style capture surface occupying about 60–70% of the phone while framing. The existing brand, safety gate and manual single-photo runtime are preserved.

| Before | After | Why |
| --- | --- | --- |
| Preview inside the scrolling inspection form | Dedicated Capture photo screen during an active camera session | Framing gets the main screen area |
| Shutter over the image | Full-width native shutter below the viewfinder | Easier thumb reach and unobscured image |
| Guide/findings/navigation beside capture task | Close and Android Back stop capture and return to inspection; findings return after capture | Focused camera task with a clear exit |

The camera/shutter stage targets 78% of portrait screen height. Its 72dp shutter/padding area leaves approximately 65–70% for the viewfinder on ordinary portrait phones; aspect-ratio letterboxing, safe areas, short windows and enlarged text can reduce the visible feed. The complete camera image is retained without deliberately cropping away propellers. Short/landscape windows flex the stage to preserve controls and instructions. Existing theme/native touch targets are retained. Demo provenance remains visible in fixture sessions. No shared v1 interface change.

## Actual checks and limits

- UI analysis clean; **17 checks passed**, including large portrait stage, Close return, short landscape/large text, Android Back and permission-dialog regression. Mobile analysis clean and **1 widget check passed**. Runtime **50 tests passed**; total **68** Flutter checks/tests.
- Built and installed on Samsung SM-S731B (Android17/API37, arm64-v8a); install Success and launch Status ok. APK v2 signature verifies. SHA-256 `a913f2f9921f1abc038bc112997471a192869da57b5b357d3bc053be64ea349a`, 17,969,297 bytes, debug-signed sideload.
- The first phone screenshot showed the already-captured photo review, not the framing view. A later observation showed safety reset/Start disabled. The user explicitly requested **finish without the screenshot** instead of reopening. Therefore the enlarged preview's actual phone appearance/percentage is **not visually verified**; unit layout checks and installation are verified. No claim of a large-view phone screenshot or complete device acceptance.
- Impeccable native adaptation/craft-floor and Emil interaction guidance informed the existing-style layout, reachable shutter and exit behavior. No new art direction, animations or external visual assets. Private camera/photo screenshots stay in ignored local build output and are not committed.

Full detector/reference and remaining permission/lifecycle/rotation acceptance remain pending. Earlier stable-preview/manual-capture phone confirmation applies to `ddc5f40`; see `CAMERA_FIX.md` for that historical evidence. `apk.json` / `deliverables.json` index this replacement.
