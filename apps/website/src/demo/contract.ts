// Website-side mirror of contracts/verification-result.schema.json (v1.0.0).
// Read-only consumer: the shared schema is owned by the app owner.

export type Status = 'pass' | 'incorrect_installation' | 'unable_to_verify';
export type Finding = 'match' | 'mismatch' | 'unknown';

export interface MotorFinding {
  motor_id: string;
  bbox: [number, number, number, number] | null;
  observed_type: string | null;
  expected_type: string | null;
  observed_orientation: string | null;
  expected_orientation: string | null;
  finding: Finding;
  correction_code: string | null;
}

export interface VerificationResult {
  schema_version: '1.0.0';
  input_id: string;
  status: Status;
  evidence_source: 'real' | 'fixture';
  reference_version: string | null;
  engine_version: string | null;
  all_required_checks_observable: boolean;
  reasons: string[];
  motors: MotorFinding[];
  elapsed_ms: number | null;
}

/** The only three verification labels the product may show (R5). */
export const STATUS_LABEL: Record<Status, string> = {
  pass: 'Pass',
  incorrect_installation: 'Incorrect Installation',
  unable_to_verify: 'Unable to Verify',
};

/** Plain-language text for the stable reason codes listed in docs/CONTRACT.md. */
export const REASON_TEXT: Record<string, string> = {
  REFERENCE_NOT_CONFIGURED: 'No verified reference is loaded, so there is nothing to compare against.',
  ENGINE_UNAVAILABLE: 'The verification engine is not available on this device.',
  BLUR: 'The image is too blurred to read propeller details.',
  LOW_LIGHT: 'There is not enough light to read propeller details.',
  INCOMPLETE_DRONE: 'Part of the drone is outside the frame.',
  UNKNOWN_ORIENTATION: 'The image does not show how a propeller is seated.',
  AMBIGUOUS_CLASS: 'At least one propeller could not be told apart from the other type.',
  UNSUPPORTED_VIEW: 'The photo was taken from a view the check does not support.',
  NO_DRONE: 'No drone was found in the image.',
  SAFETY_NOT_CONFIRMED: 'The disarm procedure has not been confirmed.',
  CANCELLED: 'The check was cancelled.',
  INVALID_INPUT: 'The image could not be read.',
  ENGINE_ERROR: 'The verification engine reported an error.',
};

/**
 * Guidance for correction codes. REPLACE_WITH_REFERENCE_TYPE appears in the
 * shared fixtures; REINSTALL_IN_REFERENCE_ORIENTATION is a website demo code
 * proposed in docs/handoffs/frontend-web.md (correction_code is a free string in v1).
 */
export const CORRECTION_TEXT: Record<string, string> = {
  REPLACE_WITH_REFERENCE_TYPE: 'Swap this propeller for the type the verified reference lists for this motor.',
  REINSTALL_IN_REFERENCE_ORIENTATION: 'Remove this propeller and reinstall it the way the verified reference shows.',
};

/**
 * Key invariants from docs/CONTRACT.md. Returns a list of violations (empty = consistent).
 * This checks semantics of a result object; it says nothing about detector accuracy.
 */
export function contractViolations(r: VerificationResult): string[] {
  const v: string[] = [];
  const mismatches = r.motors.filter((m) => m.finding === 'mismatch').length;
  if (r.status === 'pass') {
    if (r.reference_version === null) v.push('pass without a reference');
    if (!r.all_required_checks_observable) v.push('pass without all checks observable');
    if (r.reasons.length > 0) v.push('pass with rejection reasons');
    if (r.motors.length === 0) v.push('pass with an empty motor set');
    if (r.motors.some((m) => m.finding !== 'match')) v.push('pass with a non-matching motor');
  }
  if (r.status === 'incorrect_installation') {
    if (!r.all_required_checks_observable) v.push('incorrect without sufficient evidence');
    if (mismatches === 0) v.push('incorrect without a confirmed mismatch');
  }
  if (r.reference_version === null && r.status !== 'unable_to_verify') {
    v.push('verdict without a reference');
  }
  return v;
}
