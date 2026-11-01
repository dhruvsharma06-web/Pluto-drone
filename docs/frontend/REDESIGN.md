# Interactive frontend redesign

User requested a stronger, professional visual treatment with animations and motion graphics. The prior blue/graphite brand and logo are retained; the default view is now dark, with the complete light scheme still available through themeMode.

- Interactive original drone framing scene: metallic material shading, camera framing, pointer-tracked viewpoint tilt and eased return. It is explicitly illustrative, not a motor map. Propellers never spin.
- Processing-only scan sweep, including over analyzed images. Removed for reduced-motion preference (static scan indication). It is processing feedback, never detection output.
- Uploaded evidence supports coordinated image + annotation pinch zoom. Input IDs reset viewport state.
- Prepare / Inspect / Review wayfinding reflects safety/result state, not an invented approval metric.
- Status emblem settles at 180ms only on a status change, not on each camera frame; result text remains immediate. Existing stale-result/safety guards remain unchanged.
- Pointer feedback, native control focus and native navigation retained. Reduced motion removes viewpoint travel and continuous scanning. No new package or external asset dependency.

The supplied architecture reminder is preserved: UI consumes InspectionController / InspectionState / VerificationResult. Camera lifecycle, model/training and core detection stay outside the Flutter presentation package. Neither detection nor reference logic is embedded into motion graphics.

| Before | After | Why |
|---|---|---|
| Flat empty-camera outline | Interactive shaded framing scene | A product-specific focal point and useful framing interaction |
| Static photo | Image and annotations zoom together | Inspect blade details without breaking overlay coordinates |
| Indeterminate spinner only | Bounded scan sweep during processing | Make active work visible without implying a result |
| Repeated frame identity could restart result animation | Animate status changes only | Keep live-camera updates stable |

Rendered layout and interaction checks cover compact, tablet, expanded, dark and enlarged-text modes. Native device/refresh-rate validation remains pending; widget renders are not device screenshots. Private user photos remain excluded from public Git.

Final validation: flutter analyze reported no issues; all 16 UI/geometry/gesture/reduced-motion/layout/render checks passed. Reviewed updated compact preparation and expanded mismatch renders. No native-device performance claim.
