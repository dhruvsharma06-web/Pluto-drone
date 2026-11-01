import { DEFAULT_INPUT, type DemoInput } from './rules';

/** Demo inputs that reproduce each shared file in contracts/fixtures/ (checked by rules.test.ts). */
export const FIXTURE_PRESETS: { id: 'pass' | 'incorrect' | 'unclear' | 'pending'; file: string; input: DemoInput }[] = [
  { id: 'pass', file: 'pass.json', input: { ...DEFAULT_INPUT } },
  { id: 'incorrect', file: 'incorrect.json', input: { ...DEFAULT_INPUT, fault: 'type', faultMotor: 'FIXTURE_1' } },
  { id: 'unclear', file: 'unclear.json', input: { ...DEFAULT_INPUT, inFocus: false } },
  { id: 'pending', file: 'pending.json', input: { ...DEFAULT_INPUT, referenceLoaded: false } },
];
