# Copy-ready AI handoff: Person 4: OpenCV, ML, dataset and training

You are assigned this workstream, not the whole team.
Branch: `ml/vision`.
Owned paths: vision/, ml/, datasets/, models/, reference/config/, docs/ml/, docs/status/ml.md, docs/handoffs/ml.md.

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
'
## Your assignment: integrate the ML teammate's EXISTING work

The ML teammate has already worked on model, dataset and training decisions. Preserve that work. This handoff is about repository structure and app integration only. Do NOT suggest a different model, dataset, baseline, training strategy or architecture for their ML method. Ask what already exists and how they prefer to organize it; adapt wrappers and paths around it with minimal disruption. Do not restart research/training or replace working notebooks/scripts because this is a new repository.

Your branch is ml/vision. Owned folders:
- vision/: reusable inference entry point and reference-comparison adapter, or a thin wrapper around the existing implementation.
- ml/: existing training/evaluation/export scripts or documented links to their current location.
- datasets/: metadata, annotation/split documentation and retrieval instructions for the teammate's existing dataset; large images may stay in agreed external storage.
- models/: model manifest/retrieval/version information; keep large weights outside Git as appropriate.
- reference/config/: encode the SUPPLIED verified configuration once it arrives. pending.json is intentionally unverified and must not approve an image.
- docs/ml/: explain the actual existing approach, environment, commands and limitations.
- docs/status/ml.md and docs/handoffs/ml.md: progress and integration handoff.

The app owner handles Flutter, Android dependencies, device acquisition, native packaging and lifecycle. Frontend owner renders results. Researcher supplies verified drone facts/configuration evidence. You expose existing inference to the agreed app boundary. Coordinate the callable adapter/runtime format with app owner; do not silently change the model or retrain to fit an assumed runtime. If an incompatibility exists, describe the precise issue and jointly choose a minimal adapter or compatible export, preserving original artifacts.

Read docs/CONTRACT.md and contracts/verification-result.schema.json. Input boundary is an identified upright/unmirrored image and the versioned supplied reference. Result identifies input, engine/reference versions, observability/reasons, per-motor findings and overall pass/incorrect_installation/unable_to_verify. Bounding boxes use normalized analyzed-image coordinates. Follow the schema, uncertainty semantics and missing-reference refusal. Do not assume the actual motor map from this skeleton's illustrative fixtures. Document preprocessing expected by the existing model so the Android adapter performs it consistently; do not alter that preprocessing casually.

Provide the app teammate: existing inference run command; actual function/CLI/API signature; accepted image/pixel format and preprocessing; output example mapped to v1; dependencies/environment; model/reference versions and hashes; artifact location/access; resource/device constraints already known; error/uncertainty behaviour; actual existing test results and untested cases. Supply a small permitted compatibility example from their existing material if available. Mark synthetic examples clearly. No new dataset/model selection advice is requested.

Preserve existing evidence and limitations. The project's required dataset documentation and evaluation report must describe what was actually used; do not fabricate missing labels or results. Any adaptation is verified against existing behaviour and recorded. Real supplied-drone/reference checks may remain pending until hardware arrives. Maintain your branch independently until final integration; hand the app owner exact commit, commands, required artifacts and unresolved compatibility issues.

Start now: inspect the teammate's existing files/preferences and repo contract, inventory what can be reused, then produce the smallest integration wrapper and handoff. Continue with structure/documentation if local existing artifacts have not yet been attached; do not guess their model or dataset.
