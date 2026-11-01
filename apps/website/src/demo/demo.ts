// Fixture demo UI. Every rendered result says evidence_source "fixture" and
// carries the fixture banner; nothing here touches an image or a detector.

import passFixture from '../../../../contracts/fixtures/pass.json';
import incorrectFixture from '../../../../contracts/fixtures/incorrect.json';
import unclearFixture from '../../../../contracts/fixtures/unclear.json';
import pendingFixture from '../../../../contracts/fixtures/pending.json';
import { CORRECTION_TEXT, REASON_TEXT, STATUS_LABEL, type MotorFinding, type VerificationResult } from './contract';
import { FIXTURE_PRESETS } from './presets';
import { evaluate, FIXTURE_MOTORS, type DemoInput, type Fault, type FixtureMotor } from './rules';

const FIXTURE_FILES: Record<string, VerificationResult> = {
  pass: passFixture as VerificationResult,
  incorrect: incorrectFixture as VerificationResult,
  unclear: unclearFixture as VerificationResult,
  pending: pendingFixture as VerificationResult,
};

/** Where each illustrative fixture position is drawn on the top-view sketch. */
const DRAW_AT: Record<string, [number, number]> = {
  FIXTURE_1: [126, 124],
  FIXTURE_2: [-126, 124],
  FIXTURE_3: [-126, -120],
  FIXTURE_4: [126, -120],
};

const GLYPH = { pass: '✓', incorrect_installation: '✕', unable_to_verify: '?' } as const;
const TONE = { pass: 'pass', incorrect_installation: 'fail', unable_to_verify: 'unable' } as const;
const FINDING_WORD: Record<MotorFinding['finding'], string> = {
  match: 'Matches reference',
  mismatch: 'Mismatch',
  unknown: 'Unknown',
};

const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]!);

function why(r: VerificationResult): string {
  const mism = r.motors.filter((m) => m.finding === 'mismatch').length;
  if (r.status === 'pass') return 'All required checks match the sample reference.';
  if (r.status === 'incorrect_installation')
    return `${mism === 1 ? 'One position differs' : `${mism} positions differ`} from the sample reference.`;
  if (r.reasons.includes('REFERENCE_NOT_CONFIGURED')) return 'A verified reference is needed to check the installation.';
  return mism
    ? 'Some findings are available, but a complete check is not possible.'
    : 'The image does not provide enough evidence for a complete check.';
}

function map(r: VerificationResult): string {
  const rings = r.motors
    .map((m) => {
      const at = DRAW_AT[m.motor_id];
      if (!at) return '';
      const [x, y] = at;
      const g = m.finding === 'match' ? '✓' : m.finding === 'mismatch' ? '✕' : '?';
      const ly = y > 0 ? y + 58 : y - 44;
      return `<circle class="mm-ring mm-${m.finding}" cx="${x}" cy="${y}" r="32"/>
        <text class="mm-glyph" x="${x}" y="${y + 8}">${g}</text>
        <text x="${x}" y="${ly}">${esc(m.motor_id)}</text>`;
    })
    .join('');
  return `<svg class="out__map" viewBox="-200 -200 400 400" role="img" aria-label="Illustrative position sketch">
      <use href="#drone-top" x="-180" y="-180" width="360" height="360"/>${rings}</svg>`;
}

function findings(r: VerificationResult): string {
  if (!r.motors.length) return '<p>No positions to check without a verified reference.</p>';
  return `<ul class="findings">${r.motors
    .map((m) => {
      const detail =
        m.finding === 'mismatch'
          ? `<p class="f-fix">Observed ${esc(m.observed_type ?? '?')} / ${esc(m.observed_orientation ?? '?')}, expected ${esc(
              m.expected_type ?? '?',
            )} / ${esc(m.expected_orientation ?? '?')}.</p>${
              m.correction_code ? `<p class="f-fix"><strong>Fix:</strong> ${esc(CORRECTION_TEXT[m.correction_code] ?? m.correction_code)}</p>` : ''
            }`
          : m.finding === 'unknown'
            ? '<p class="f-fix">Not visible well enough to check.</p>'
            : '';
      return `<li class="is-${m.finding}"><span class="f-id">${esc(m.motor_id)}</span><span class="f-state">${FINDING_WORD[m.finding]}</span>${detail}</li>`;
    })
    .join('')}</ul>`;
}

function render(out: HTMLElement, r: VerificationResult, source: string, animate: boolean) {
  const reasons = r.reasons.length
    ? `<ul class="reasons">${r.reasons
        .map((c) => `<li><span>${esc(REASON_TEXT[c] ?? c)}</span><code>${esc(c)}</code></li>`)
        .join('')}</ul>`
    : '';
  out.innerHTML = `<div class="out out--${TONE[r.status]}${animate ? ' is-entering' : ''}">
    <p class="out__source">Demo · Simulated results</p>
    <p class="out__verdict"><span class="glyph" aria-hidden="true">${GLYPH[r.status]}</span>${STATUS_LABEL[r.status]}</p>
    <p class="out__why">${why(r)}</p>
    <details class="out__details">
      <summary>View example details</summary>
      ${reasons}
      <div class="out__body">
        <div>${map(r)}<p class="out__mapnote">Illustrative positions · not a real motor map.</p></div>
        ${findings(r)}
      </div>
      <details><summary>Technical data</summary>
        <p class="out__mapnote">Fixture source: ${esc(source)}</p>
        <pre>${esc(JSON.stringify(r, null, 2))}</pre>
      </details>
    </details>
  </div>`;
}

export function initDemo(reducedMotion: boolean) {
  const form = document.querySelector<HTMLFormElement>('[data-demo-form]');
  const out = document.querySelector<HTMLElement>('[data-demo-out]');
  if (!form || !out) return;
  const presetButtons = [...document.querySelectorAll<HTMLButtonElement>('[data-preset]')];
  let n = 0;
  let timer = 0;

  const read = (): DemoInput => {
    const f = new FormData(form);
    return {
      referenceLoaded: f.has('referenceLoaded'),
      wholeDrone: f.has('wholeDrone'),
      inFocus: f.has('inFocus'),
      usableLight: f.has('usableLight'),
      allClassified: f.has('allClassified'),
      fault: (f.get('fault') as Fault) ?? 'none',
      faultMotor: (f.get('faultMotor') as FixtureMotor) ?? FIXTURE_MOTORS[0],
    };
  };

  const write = (input: DemoInput) => {
    for (const k of ['referenceLoaded', 'wholeDrone', 'inFocus', 'usableLight', 'allClassified'] as const) {
      (form.elements.namedItem(k) as HTMLInputElement).checked = input[k];
    }
    form.querySelectorAll<HTMLInputElement>('input[name="fault"]').forEach((r) => (r.checked = r.value === input.fault));
    (form.elements.namedItem('faultMotor') as HTMLSelectElement).value = input.faultMotor;
  };

  // New input always clears the previous result first, so a stale Pass never lingers.
  const show = (r: VerificationResult, source: string) => {
    clearTimeout(timer);
    if (reducedMotion) return render(out, r, source, false);
    out.innerHTML = '<div class="out out--cleared"><p class="out__source">Demo · Simulated results</p><p>Updating example…</p></div>';
    timer = window.setTimeout(() => render(out, r, source, true), 220);
  };

  form.addEventListener('change', () => {
    presetButtons.forEach((b) => b.setAttribute('aria-pressed', 'false'));
    n += 1;
    show(evaluate(read(), `demo-input-${n}`), 'rules applied to the toggles');
  });
  form.addEventListener('submit', (e) => e.preventDefault());

  presetButtons.forEach((b) => {
    b.setAttribute('aria-pressed', 'false');
    b.addEventListener('click', () => {
      const preset = FIXTURE_PRESETS.find((p) => p.id === b.dataset.preset);
      if (!preset) return;
      write(preset.input);
      presetButtons.forEach((x) => x.setAttribute('aria-pressed', String(x === b)));
      show(FIXTURE_FILES[preset.id], `contracts/fixtures/${preset.file}`);
    });
  });

  render(out, evaluate(read(), 'demo-input-0'), 'rules applied to the toggles', false);
}
