// Fixture demo of the result rules in docs/CONTRACT.md.
// This is NOT a detector: it never looks at an image. It turns hand-set,
// made-up evidence toggles into a contract-shaped result so visitors can see
// how Pass / Incorrect Installation / Unable to Verify are decided.

import type { MotorFinding, VerificationResult } from './contract';

/** Illustrative identities copied from contracts/fixtures. Not a real motor map. */
export const FIXTURE_MOTORS = ['FIXTURE_1', 'FIXTURE_2', 'FIXTURE_3', 'FIXTURE_4'] as const;
export type FixtureMotor = (typeof FIXTURE_MOTORS)[number];

export type Fault = 'none' | 'type' | 'orientation';

export interface DemoInput {
  referenceLoaded: boolean;
  wholeDrone: boolean;
  inFocus: boolean;
  usableLight: boolean;
  allClassified: boolean;
  fault: Fault;
  faultMotor: FixtureMotor;
}

export const DEFAULT_INPUT: DemoInput = {
  referenceLoaded: true,
  wholeDrone: true,
  inFocus: true,
  usableLight: true,
  allClassified: true,
  fault: 'none',
  faultMotor: 'FIXTURE_1',
};

/** Motor hidden by the "part of the drone out of frame" toggle (illustrative). */
const OUT_OF_FRAME: FixtureMotor = 'FIXTURE_4';
/** Motor left unclassified by the "not every propeller classified" toggle (illustrative). */
const AMBIGUOUS: FixtureMotor = 'FIXTURE_2';

const TYPE = 'fixture_type';
const ORIENT = 'fixture_orientation';

function motor(id: string, finding: MotorFinding['finding'], fault: Fault): MotorFinding {
  return {
    motor_id: id,
    bbox: null,
    observed_type: fault === 'type' ? 'fixture_other_type' : TYPE,
    expected_type: TYPE,
    observed_orientation: fault === 'orientation' ? 'fixture_inverted' : ORIENT,
    expected_orientation: ORIENT,
    finding,
    correction_code:
      finding === 'mismatch'
        ? fault === 'type'
          ? 'REPLACE_WITH_REFERENCE_TYPE'
          : 'REINSTALL_IN_REFERENCE_ORIENTATION'
        : null,
  };
}

export function evaluate(input: DemoInput, inputId: string): VerificationResult {
  const base = {
    schema_version: '1.0.0' as const,
    input_id: inputId,
    evidence_source: 'fixture' as const,
    engine_version: 'fixture-only',
    elapsed_ms: null,
  };

  // No verified reference: nothing to compare against, so no verdict.
  if (!input.referenceLoaded) {
    return {
      ...base,
      status: 'unable_to_verify',
      reference_version: null,
      all_required_checks_observable: false,
      reasons: ['REFERENCE_NOT_CONFIGURED'],
      motors: [],
    };
  }

  const reasons: string[] = [];
  if (!input.wholeDrone) reasons.push('INCOMPLETE_DRONE');
  if (!input.inFocus) reasons.push('BLUR');
  if (!input.usableLight) reasons.push('LOW_LIGHT');
  if (!input.allClassified) reasons.push('AMBIGUOUS_CLASS');

  // Blur and low light degrade the whole image: nothing can be confirmed.
  const imageReadable = input.inFocus && input.usableLight;

  const motors = FIXTURE_MOTORS.map((id) => {
    const hidden =
      !imageReadable ||
      (!input.wholeDrone && id === OUT_OF_FRAME) ||
      (!input.allClassified && id === AMBIGUOUS);
    if (hidden) return motor(id, 'unknown', 'none');
    if (input.fault !== 'none' && id === input.faultMotor) return motor(id, 'mismatch', input.fault);
    return motor(id, 'match', 'none');
  });

  const observable = reasons.length === 0;
  const hasMismatch = motors.some((m) => m.finding === 'mismatch');
  const status: VerificationResult['status'] = !observable
    ? 'unable_to_verify' // confirmed partial findings may still be listed
    : hasMismatch
      ? 'incorrect_installation'
      : 'pass';

  return {
    ...base,
    status,
    reference_version: 'fixture-reference-v1',
    all_required_checks_observable: observable,
    reasons,
    motors,
  };
}
