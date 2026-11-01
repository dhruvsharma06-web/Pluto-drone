import { describe, expect, it } from 'vitest';
import passFixture from '../../../../contracts/fixtures/pass.json';
import incorrectFixture from '../../../../contracts/fixtures/incorrect.json';
import unclearFixture from '../../../../contracts/fixtures/unclear.json';
import pendingFixture from '../../../../contracts/fixtures/pending.json';
import { contractViolations, STATUS_LABEL, type VerificationResult } from './contract';
import { DEFAULT_INPUT, evaluate, FIXTURE_MOTORS, type DemoInput, type Fault } from './rules';
import { FIXTURE_PRESETS } from './presets';

const fixtures: Record<string, VerificationResult> = {
  pass: passFixture as VerificationResult,
  incorrect: incorrectFixture as VerificationResult,
  unclear: unclearFixture as VerificationResult,
  pending: pendingFixture as VerificationResult,
};

function allInputs(): DemoInput[] {
  const out: DemoInput[] = [];
  const bools = [true, false];
  const faults: Fault[] = ['none', 'type', 'orientation'];
  for (const referenceLoaded of bools)
    for (const wholeDrone of bools)
      for (const inFocus of bools)
        for (const usableLight of bools)
          for (const allClassified of bools)
            for (const fault of faults)
              for (const faultMotor of FIXTURE_MOTORS)
                out.push({ referenceLoaded, wholeDrone, inFocus, usableLight, allClassified, fault, faultMotor });
  return out;
}

describe('result labels', () => {
  it('uses exactly the three product labels', () => {
    expect(Object.values(STATUS_LABEL)).toEqual(['Pass', 'Incorrect Installation', 'Unable to Verify']);
  });
});

describe('fixture demo rules', () => {
  const inputs = allInputs();

  it('never produces Pass when any evidence or the reference is missing (R6)', () => {
    for (const input of inputs) {
      const r = evaluate(input, 't');
      const evidenceComplete =
        input.referenceLoaded && input.wholeDrone && input.inFocus && input.usableLight && input.allClassified;
      if (!evidenceComplete) expect(r.status, JSON.stringify(input)).not.toBe('pass');
    }
  });

  it('only reports Incorrect Installation with full evidence and a confirmed mismatch', () => {
    for (const input of inputs) {
      const r = evaluate(input, 't');
      if (r.status === 'incorrect_installation') {
        expect(r.all_required_checks_observable).toBe(true);
        expect(r.motors.some((m) => m.finding === 'mismatch')).toBe(true);
      }
    }
  });

  it('satisfies the contract invariants for every combination', () => {
    for (const input of inputs) {
      expect(contractViolations(evaluate(input, 't')), JSON.stringify(input)).toEqual([]);
    }
  });

  it('always labels output as fixture evidence', () => {
    for (const input of inputs) expect(evaluate(input, 't').evidence_source).toBe('fixture');
  });

  it('passes the clean default input', () => {
    expect(evaluate(DEFAULT_INPUT, 't').status).toBe('pass');
  });
});

describe('shared contract fixtures', () => {
  it('are all labelled fixture and internally consistent', () => {
    for (const f of Object.values(fixtures)) {
      expect(f.evidence_source).toBe('fixture');
      expect(contractViolations(f)).toEqual([]);
    }
  });

  it('are reproduced exactly by the demo presets', () => {
    for (const preset of FIXTURE_PRESETS) {
      const fixture = fixtures[preset.id];
      expect(evaluate(preset.input, fixture.input_id)).toEqual(fixture);
    }
  });
});
