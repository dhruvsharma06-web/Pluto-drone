---
name: Pluto Inspection
colors:
  ink-dark: "#ffffff"
  ground-dark: "#050505"
  amethyst: "#3b0a6b"
  cyan: "#00e5ff"
  ink-light: "#000000"
  ground-light: "#ffffff"
typography:
  headline:
    fontFamily: Roboto
    fontSize: "32sp"
    fontWeight: 700
    lineHeight: 1.12
  title:
    fontFamily: Roboto
    fontSize: "24sp"
    fontWeight: 700
  body:
    fontFamily: Roboto
    fontSize: "18sp"
    fontWeight: 400
rounded:
  controls: "8dp"
  evidence: "16dp"
spacing:
  group: "16dp"
  section: "24dp"
---
# Design System: Pluto Inspection
## Overview
User-supplied palette reference: jet black #050505, royal amethyst #3B0A6B and electric cyan #00E5FF. Large readable text and minimal working copy remain. This supersedes the monochrome-only direction.
## Colors
Jet-black canvas, amethyst selected controls and primary actions, restrained cyan interaction accents. Directional amethyst/cyan studio light belongs to the illustrative framing stage; a faint amethyst wash grounds the page. Outcome names/icons retain white/black contrast. Preserve original camera/photo evidence without filtering it; photographic cues may be needed for detection.
## Typography
Self-hosted Roboto. Headings 32sp; product title 24sp; body/control text 18sp. Native text scaling remains enabled. No small decorative labels.
## Layout
One clear inspection heading, camera/photo selection, evidence, explicit safety confirmation and primary action. No tagline, progress strip, repeated tip list or duplicate disclaimer. Detailed setup guidance and project metadata live in their dedicated views. Compact views stack; expanded results show evidence and motor findings side by side.
## Elevation & Depth
Flat native controls, directional lighting in the illustrative stage and a restrained background wash. No blur layers or added continuous animation.
## Shapes
8dp controls, 16dp evidence frame. Avoid extra containers when spacing is sufficient.
## Components
Result status is conveyed by its exact name and distinct icon, never colour. Pointer feedback, direct viewpoint manipulation, processing scan and image zoom remain restrained. No propeller spinning. Reduced motion uses static feedback.
## Do's and Don'ts
- Do keep safety confirmation and actionable correction guidance.
- Do keep fixtures visibly labelled as simulated.
- Do preserve the reusable UI/controller/core boundary.
- Don't add tiny filler, taglines, fake metrics or effects over photographic evidence.

## Findings
Mismatch and unknown boxes use dual black/white outlines. Tap for a native scrollable Where/Why/Correction sheet; list uses the same content. Positions are relative to the analyzed image. No guessed boxes or causes. Detail sheets dismiss on inspection invalidation.
