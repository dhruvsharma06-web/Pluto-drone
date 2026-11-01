# Frontend design and findings

Latest user direction supersedes the blue/graphite treatment: black and white authored UI and launcher branding, 32sp headings, 24sp product title and 18sp body/controls. Camera/photo evidence stays unfiltered. Removed tagline, progress strip, repeated tips and redundant safety copy. Detailed setup remains in Guide.

The original framing illustration responds directly to dragging, then settles. Propellers never spin. A scan line appears only during processing; reduced motion uses static feedback. Evidence and annotations zoom together. Exact status names and distinct icons communicate outcomes without colour.

## Model findings

PRISM_2.0_Demo.html supplied by the user is a behavior reference, not a source of validated drone predictions. Highlight mismatch/unknown boxes by default. A matching motor is boxed when selected from the list. Boxes use the model's normalized coordinates on the exact analyzed image, with dual black/white outlines and supplied motor IDs where space permits. Invalid/missing coordinates never produce guessed boxes.

Tap a box for a native, scrollable detail sheet with Where, Why and Correction. The same details appear in the findings list. Where shows the reference motor ID and image-relative position; it never infers drone-front mapping. Why compares supplied observed and expected type/orientation. Unknown findings stay unverified; absent explanations are stated honestly. Details close when their inspection changes, safety is revoked, the service errors or the app is backgrounded. Fixtures remain labelled in the sheet.

| Before | After | Why |
|---|---|---|
| Blue accents and shaded scene | Flat black/white geometry and branding | Follow the explicit visual brief |
| Small secondary copy and setup repetition | Larger text and fewer competing elements | Keep the inspection task clear |
| Status-only motor icons | Tappable issue boxes and Where/Why/Correction | Locate the affected part and explain the supplied finding |
| Image separate from viewing controls | Image and annotations zoom together | Preserve annotation coordinates while inspecting details |

Controller/core separation, v1 schema and safety/result guards remain unchanged. Rendering and interaction evidence is recorded in VALIDATION.md. No native-device performance or real inference claim. Private photographs remain excluded from public Git.
