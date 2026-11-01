# Shared contract v1.0.0

App owner coordinates changes; frontend and ML consumers must agree. Independent branches keep this baseline until final integration; propose changes in own handoff.

## UI/application boundary

`InspectionApp(controller: InspectionController, cameraPreview: Widget?)` is the Flutter presentation entry point. Controller exposes `Stream<InspectionState> states`, synchronous `current`, `setSafetyConfirmed(bool)`, `selectImage()`, `startLive()`, `stopLive()`, `dispose()`. UI owns rendering, runtime owns acquisition/processing. State contains phase, safetyConfirmed, message, optional image bytes and optional VerificationResult. Camera preview is injected, not a camera-plugin dependency in UI. Additive changes must retain compatibility or be coordinated.

## Core boundary

`VerificationEngine.verify(InspectionImage image)` returns `Future<VerificationResult>`. Engine implementation is initialized with versioned reference/runtime resources by app owner; no reference is guessed from input. Image contains unique ID, encoded JPEG/PNG bytes, upright unmirrored width/height, and source `live` or `upload`. Cancellation/stale suppression is runtime responsibility; engine resources are released by its owner.

Result serialization: `contracts/verification-result.schema.json`. Required fields: schema_version, input_id, status, evidence_source, reference_version (nullable), engine_version (nullable), all_required_checks_observable, reasons, motors, elapsed_ms (nullable). Status values: pass, incorrect_installation, unable_to_verify. Evidence source: real or fixture. UI labels: Pass, Incorrect Installation, Unable to Verify. Reasons are stable codes, not exception dumps; known examples REFERENCE_NOT_CONFIGURED, ENGINE_UNAVAILABLE, BLUR, LOW_LIGHT, INCOMPLETE_DRONE, UNKNOWN_ORIENTATION, AMBIGUOUS_CLASS, UNSUPPORTED_VIEW, NO_DRONE, SAFETY_NOT_CONFIRMED, CANCELLED, INVALID_INPUT, ENGINE_ERROR.

Motor finding fields: motor_id, bbox (nullable [x,y,width,height], normalized analyzed image coordinates), observed_type/expected_type (nullable), observed_orientation/expected_orientation (nullable), finding (match/mismatch/unknown), correction_code (nullable). Motor ID comes from reference; fixture IDs are illustrative and MUST NOT become the actual motor mapping. Omitted confidence is deliberate; add only with defined semantics and evidence, not made-up probabilities.

Pass: real verified reference, all required checks observable, nonempty complete motor set matching reference, all findings match, no rejection reasons. Incorrect: sufficient required evidence and at least one mismatch. Otherwise Unable to Verify; any confirmed partial fault can appear in motors without claiming complete verification. Fixture outputs may simulate valid states but must remain persistently labelled fixture in every demo. No old result after input/reference/engine change or tracking loss. Whole-drone evidence/observability is an engine obligation, not inferred from number of boxes alone.

Reference serialization: contracts/reference.schema.json. pending status is valid for development but contains no motor mapping and cannot verify. Verified status requires source_evidence, front_convention, supported_views and one unique motor entry per required position; exact labels come from physical supplied reference. All motor IDs/types/installation orientations are configuration values, not default quadcopter assumptions. Contract checker checks structure and key invariants; it cannot establish physical ground truth or model accuracy.
