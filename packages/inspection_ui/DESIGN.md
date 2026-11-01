---
name: Pluto Inspection
description: A clear inspection surface with evidence beside the result.
colors:
  action-blue: "#1259d9"
  camera-graphite: "#141719"
  ice-frame: "#f2f5f8"
  sheet: "#ffffff"
  ink: "#182026"
  secondary-ink: "#53606d"
  pass: "#17643f"
  mismatch: "#a8271f"
  uncertainty: "#775000"
typography:
  headline:
    fontFamily: Roboto
    fontSize: "28sp"
    fontWeight: 700
    lineHeight: 1.18
    letterSpacing: "-0.4sp"
  title:
    fontFamily: Roboto
    fontSize: "22sp"
    fontWeight: 700
    lineHeight: 1.2
  body:
    fontFamily: Roboto
    fontSize: "14sp"
    fontWeight: 400
rounded:
  working-surface: "16dp"
  controls: "12dp"
  annotation: "8dp"
spacing:
  related: "8dp"
  group: "16dp"
  section: "24dp"
components:
  button-primary:
    backgroundColor: "{colors.action-blue}"
    textColor: "{colors.sheet}"
    rounded: "{rounded.controls}"
    height: "54dp"
---
# Design System: Pluto Inspection
## Overview
**Creative North Star: "Evidence in view"**
The user's graphite-and-ice direction is expressed through Material 3 components. Opaque surfaces, readable text, a clear photo, and a precise next action provide the identity. The original rotor-aperture mark adds a small distinctive face.
**Key Characteristics:**
- Real image evidence paired with motor findings.
- Quiet native navigation, blue primary action, semantic result colours.
- System scaling and separate light/dark palettes.
## Colors
Primary blue identifies the action and mark. Neutral surfaces separate frame, work and camera. Status colours encode results with an icon and text. Dark-role values are defined in lib/src/theme.dart; no arbitrary invert.
**The Result Rule.** A brand colour never substitutes for a result label or creates an approval.
## Typography
Self-hosted Roboto regular/medium/bold, Apache 2.0; Material title/body/label roles. Long labels wrap. Text follows platform scaling. No decorative display or technical monospace voice.
## Layout
Equal 16dp margins below 360dp and 24dp otherwise; at most 1120dp content. One 24dp gutter in the expanded two-column inspection view. Rail at 900dp; bottom navigation on compact widths. Portrait evidence remains complete via contain-and-centre geometry.
## Elevation & Depth
Working surfaces use tone steps, no resting shadows or blur. Native feedback remains on its Material ancestor.
## Shapes
16dp canvas/sheet, 12dp controls and finding surfaces, 8dp annotations. Launcher background is square; Android applies its own icon mask.
## Components
Primary action is 54dp high; standard minimum native targets are 48dp. Segmented input selection, checkbox confirmation, native nav/rail and motor rows use Material behaviour. Pointer-only press scale .98 uses 100ms down / 140ms release with Cubic(.23,1,.32,1). Remove Animations disables that movement; keyboard activation never starts it. Results and frame overlays update immediately. Processing has a static hourglass alternative when animations are removed.
## Do's and Don'ts
- Do retain the simulated-results notice in every fixture view.
- Do attach annotations to the actual analyzed image and its identity.
- Do use the supplied reference's motor identities.
- Don't fabricate model/dataset metrics, confidence or flight-clearance claims.
- Don't replace Material Android controls with Cupertino controls.

User-requested visual update: default dark graphite scheme; authored material shading is confined to the illustrative drone scene. A processing-only scan sweep, direct viewpoint manipulation and evidence zoom are supported. Continuous motion never indicates a classification result; reduced motion uses static feedback. Inspect/Review state text changes immediately.
