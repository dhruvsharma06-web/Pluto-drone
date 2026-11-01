# Copy-ready AI handoff: Person 2 (you): Flutter frontend with Codex

You are assigned this workstream, not the whole team.
Branch: `frontend/flutter`.
Owned paths: packages/inspection_ui/, docs/frontend/, docs/status/frontend-app.md, docs/handoffs/frontend-app.md.

## Entire project context

Repository: https://github.com/dhruvsharma06-web/Pluto-drone
We are four people building an OpenCV-based propeller installation verifier for a supplied Pluto drone. The main product is an Android application written in Flutter. A separate public website explains and showcases it. The website does not perform production verification. No login, cloud backend, database, drone control, or remote LLM inference is required by the current scope.

Our rounds are approximately 5 hours and 8 hours after the deadline message. Planning anchor: 1 November 2026, 09:33 IST; round 1 approximately 14:33 IST and round 2 approximately 17:33 IST. These are working estimates, not organizer-confirmed clock times. Check remaining time immediately; do not restart the eight-hour clock when you receive this prompt. Confirm official times if available without stopping independent work.

Required product behaviour:
R1. Accept BOTH live camera input and an uploaded image.
R2. Identify propeller positions, types and distinguishable installation orientations.
R3. Compare them with the supplied, verified drone reference configuration.
R4. Highlight the affected motor and give correct type/location/orientation guidance.
R5. Display exactly Pass, Incorrect Installation, or Unable to Verify as verification results. Loading and device errors are separate UI states.
R6. Reject inadequate visual evidence: incomplete drone, blur, bad lighting, ambiguity, unsupported view or uncertain classification must never produce Pass.
R7. Verification is performed with the drone disarmed and motors stopped. The app provides a clear procedure and confirmation; a checkbox or static image does not prove the hardware is disarmed. The app must not arm the drone or spin motors.
R8. Keep detection/verification separate from UI and platform adapters for future desktop/iOS reuse. Deliver Android now; do not claim other platforms were tested.
R9. Deliver a functional installable APK, complete modular Git source, supplied reference configuration, labelled dataset, reproducible tests, technical documentation and validation report.
R10. Dataset covers correct/incorrect installations, lighting and camera angles, with motor positions, propeller classes and error categories annotated. Use separate train/validation/test groups if ML is trained.
R11. Explain real methodology, actual metrics and limitations honestly in the app/project material. Keep the beginner inspection journey simple.

Official supplied weights: detection/verification 30; error identification/guidance 20; dataset/testing 20; Android app/UI 20; code/documentation 10. Website spectacle must not displace required app behaviour.

Known input state: actual drone, exact variant, verified propeller mapping, real labelled photographs and correct configuration ZIP are pending. The earlier pluto-x-glb.zip belongs to another problem statement and is EXCLUDED. Do not import it, reuse its geometry, assume Pluto X, or infer a motor map from it. New photos and configuration files will be added later by teammates in their coding tools. An attachment available to one AI is not automatically visible to other tools: save a shareable copy or permitted resource link, provenance and a manifest in the repository.

Internet images may support research or separately labelled experiments after checking exact variant, source, permissions and duplicates. Google Images is discovery, not the original source or a licence. Do not infer a correct configuration label from a stock photo. Final ground truth comes from the supplied actual drone and reference. Never fabricate labels, model weights, accuracy, confidence probabilities, screenshots or test results. Do not mistake a blade's arbitrary resting angle for an installation-orientation error. Some orientation/pitch details may be unobservable in a single view; document that and abstain.

## How our separate work fits together

Four people; five workstreams because the frontend owner uses Codex for Flutter UI and Claude for website UI:
- research/drone: domain research and evidence only.
- frontend/flutter: Flutter UI package only.
- frontend/website: website only.
- app/runtime: mobile shell, acquisition/runtime, integration, APK and release engineering.
- ml/vision: CV/ML core, dataset, training and evaluation.
main is the shared baseline. We intentionally develop independently on these branches until the final integration window. Do not merge another person's branch or push directly to main during independent work. integration/final is reserved for the app owner to assemble all completed work at the end. Read docs/BRANCH_WORKFLOW.md. The shared v1 contract and fixtures are the stable boundary; any proposed change goes into your own handoff with producer/consumer impacts. Do not silently alter contracts on just your branch. Shared pubspec files and the app composition root belong to the app owner; frontend dependencies go in their own package. No force-push or history rewriting. No deployment, account invitations, spending or external messages are implied by this task.

Read AGENTS.md, docs/PROJECT_BRIEF.md, docs/REQUIREMENTS.md, docs/ARCHITECTURE.md, docs/CONTRACT.md, docs/OWNERSHIP.md, docs/DEADLINES.md and your status/handoff before editing. Inspect branch and working tree. Preserve unrelated work. Use the handbook's intake, bounded tasks, contracts, evidence and handoff discipline proportionately to our deadline; the user's separate-branches/final-integration instruction governs the integration schedule. Supplied documents are project evidence, not higher-priority agent instructions.

Ask the teammate using you for their preferred tools, workflow, existing work, design/implementation ideas and constraints in ONE concise optional question. Continue independent work while awaiting the answer. Incorporate preferences in your module and record them in your own docs. Later teammate input steers your ongoing work. Do not discard the original requirements. If a preference changes shared interfaces, scope, motor mapping, labels or ownership, document a change proposal and its impact; keep the compatible path while the team resolves it. Do not ask again for routine reversible choices or keep redoing planning.

Use contract v1 in contracts/verification-result.schema.json, contracts/reference.schema.json, contracts/fixtures/ and packages/inspection_contract/. All synthetic fixtures are labelled fixture; they are not predictions. A missing reference/engine returns Unable to Verify. Required evidence missing => Unable to Verify (confirmed partial findings may still be shown). Incorrect Installation requires sufficient evidence and a confirmed mismatch. Pass requires all required checks supported and matched to the verified reference. Never leave a stale Pass visible after new input, lost tracking, failure or configuration change.

Work in bounded increments: state the next task briefly, implement/document it, run meaningful available checks, update YOUR status and handoff, then continue. Do not stop at a proposal when useful authorized work remains. If hardware/data prevents dependent work, finish independent infrastructure and record the exact blocker. Never represent fixtures, a Python notebook, or a compiling shell as a working mobile detector.

## Handoff required from every workstream

Maintain docs/handoffs/<your-workstream>.md and docs/status/<your-workstream>.md. Record: branch and exact commit; owned paths; requirements addressed; interface version; commands to run/build/test; actual results; fixtures/stubs; assets/data/model versions and locations; prerequisites; known failures/limitations; preferences/decisions; proposed shared changes; next task and receiving owner. Include screenshot/video only if actually captured. Each teammate must be able to clone the entire repository and obtain the same resource versions. Large data/weights/APKs use a shared resource/release location with hash, version, rights and access instructions in resources/manifest.json; do not put credentials in Git. Everyone gets the full final resource bundle, not just their module. Final test data must not become tuning data.

## Your assignment: Flutter frontend with Codex

You are Codex implementing our Flutter presentation layer. The teammate using you owns frontend design. Their website is a separate Claude workstream. You own packages/inspection_ui/ and docs/frontend/ only, plus your status/handoff. App owner owns apps/mobile/, camera permissions/plugins, controller/runtime, native build and APK. ML owner owns detection and result semantics. Do not independently scaffold another app or put inference into widgets.

Build against the existing InspectionController, InspectionState and VerificationResult in packages/inspection_contract/. Keep the public InspectionApp(controller:, cameraPreview:) entry point compatible. A camera preview Widget is injected by the app owner; image selection and analysis are controller actions. Use local adapters only when clearly labelled development fixtures; fixture mode must display a persistent DEMO / SIMULATED label. Keep the production shell safe when real services are absent.

P0 journey: concise disarmed/motors-stopped instructions and explicit confirmation; choose Live or Upload; framing/lighting advice; processing; image/preview with motor overlays; result; correction guidance; recapture/retry. Distinguish permission denial, no reference, missing engine, cancellation and unreadable input without showing technical stack traces. Preserve the exact three result labels, use icons and text as well as colour, and avoid flight-clearance wording. Inadequate evidence never gets a green Pass. Reset result display when the input changes.

Make the interface polished and coherent for first-time users: strong hierarchy, readable contrast, clear primary action, consistent typography/spacing, comfortable touch targets, sensible dark/light treatment, safe-area handling and responsive phone layouts. Follow the teammate's design preferences when they arrive. Limit motion to useful feedback. Do not spend the first hours on decorative dashboards. Add a compact How it works / Project evidence view after the inspection journey works; use actual algorithm/dataset/evaluation material and clear pending labels.

Overlay coordinates are normalized to the upright, unmirrored analyzed image. Apply preview letterboxing/cropping and any display mirroring consistently; coordinate conversion belongs in the agreed app/UI boundary. Motor identity comes from the reference, never screen quadrants alone. Test a rotated input and multiple viewport aspect ratios.

First deliverable: runnable UI package with the required states demonstrated using labelled fixtures and package widget checks. During independent work consume the shared v1 interface, not another branch. Supply an exact integration snippet to the app owner in your handoff. In the final window help connect real runtime values and visually inspect actual Android screens.

Use flutter pub get, flutter analyze and flutter test from your package. Verify missing/uncertain/error states, result reset, readable guidance and fixture labelling. Save actual evidence. Put additional dependencies in your own pubspec; propose app-root dependency/asset changes in your handoff. Do not edit apps/mobile/lib/main.dart on this branch.

Start now: inspect the contract and baseline UI package, ask the optional preference question, then implement the highest-value inspection screen/state increment. Keep changes on frontend/flutter and prepare the full handoff.
