# Flutter website alignment — app/runtime

Implemented from supplied FLUTTER_ALIGNMENT_PROMPT.md and DESIGN (1).md with the explicit user override: apply to app/runtime and preserve the working camera. No branches merged, rebased or pushed. Cached website styles/markup were read; its docs/website/DESIGN.md was absent, so the supplied document is the visual authority.

| Before | After | Why |
| --- | --- | --- |
| Blue/graphite and Roboto | Flat black/white/purple, Inter and Playfair | Match the website identity |
| Small type, repeated tips | 34sp heading, 17sp body, concise introduction/safety/action | Prioritize inspection |
| Colour-coded outline result icons | Circle/check, square/cross, dashed ring/question with labels | Distinguish results without colour |
| Static framing diagram | Labelled black schematic, violet rim/floor mist | Keep atmosphere separate from evidence |
| Inline motor guidance | Hairline rows plus invalidation-safe Where/Why/Correction sheets | Readable details that cannot remain stale |
| Single-colour evidence outline | Black outer/status-specific inner strokes and pinch zoom | Contrast on bright/dark photos |

Large capture view, manual shutter and permission-dialog fix are preserved. Android launcher text is Pluto Inspector; launcher artwork unchanged. Shared v1 types, runtime acquisition/engine and model/reference assets are untouched. Missing engine/reference remains Unable to Verify.

## Verification

Flutter 3.47.9 / Dart 3.13.7. UI analyze clean; 25 tests passed, including four widths at 1.0x/1.5x, safety/demo visibility, symbols, reduced motion/offscreen pause, stale-sheet dismissal and capture Close/Android Back. Mobile analyze clean; 1 integration widget check passed.

19 local Flutter renders reviewed: preparation/incorrect fixture at 320/390/768/1440px and 1.0x/1.5x; Pass, Unable to Verify and processing at 390px. No layout overflow detected. Large-text content scrolls; below-fold content is not squeezed. Ignored renders: packages/inspection_ui/build/alignment. These are fixture renders, not device screenshots. Review reduced the stage height so its caption fits normal-size phones.

Contrast on #050505: ink 18.07:1, muted 7.74:1, accent icons 4.45:1, large italic accent 3.63:1, error text 8.76:1. Native navigation retains Material ripple/focus. Outgoing results disappear immediately instead of animating stale evidence.

ADB reported no connected devices. No new APK installation, hardware camera retest or native screenshot claimed. Earlier device evidence applies only to its recorded build. No real inference, accuracy or performance validation. Final artifact provenance/checks are recorded below and in apk.json.

## Font provenance and skills

Downloaded 1 November 2026 from official Google Fonts:
- https://github.com/google/fonts/tree/main/ofl/inter — Inter[opsz,wght].ttf and OFL.txt.
- https://github.com/google/fonts/tree/main/ofl/playfairdisplay — PlayfairDisplay[wght].ttf, PlayfairDisplay-Italic[wght].ttf and OFL.txt.

Filenames simplified; font bytes unmodified. OFL notices accompany fonts and are bundled. No new runtime dependency. Impeccable guided native hierarchy/accessibility; Emil guided limited motion/feedback; Taste informed app composition, with the supplied palette/type/hairlines taking precedence. Browser-only inspectors were not used to claim native validation.

## Minimal rounded refinement — 1 November 2026

Visual-only refinement: separate pill-shaped input choices, shorter repeated helper copy, softer result/sheet corners, and motor details in the existing Where/Why/Correction sheet. Safety confirmation, exact result labels, fixture disclosures, error guidance and runtime logic are preserved. Existing colours/fonts/brand retained; no reference colours or business content copied. Motor sheets reopen on repeated taps and still close immediately when invalidated.

UI analysis clean; all 25 tests passed, plus the extended sheet reopening check. Responsive checks cover 320/390/768/1440px at 1.0x/1.5x. Updated local phone start/result renders inspected. ADB lists no connected device, so updated hardware testing/installation is pending. Impeccable and Emil guided hierarchy, touch targets and restrained feedback. APK/source provenance is recorded in docs/app/FLUTTER_ALIGNMENT.md.

Final APK built from clean source 67275ac59d4f31734111f8bfff55776ab6f18e66: 18427797 bytes; SHA256 f8e7adbbdefbeb4ac9a41890f78861cd833057f5f5b60576198bee76123c10d0. Android signature verified. APK path: apps/mobile/build/app/outputs/flutter-apk/app-release.apk. App-level fail-closed test passed (1/1). Phone disconnected; installation remains pending.
