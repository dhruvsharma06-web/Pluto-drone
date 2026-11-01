// Specimen-plate explorer: component tabs, a framed stage with a tool rail and
// turn control, and a notes card whose copy swaps with a staggered rise.
// Interaction model adapted from the Myth Atlas reference (drag with inertia,
// zoom, turns, expand, light presets); the content is ours and every fact is
// either visible in the team photos or explicitly deferred to the verified reference.

import { mountViewer } from './viewer/mount';
import type { PartKind, Pose } from './viewer/types';
import type { DroneViewer, ViewName } from './viewer/viewer';

interface Component {
  id: PartKind | 'all';
  name: string;
  sub: string;
  pose: Pose;
  tags: string[];
  lede: string;
  notes: [string, string][];
  caption: string;
  closeup: string;
}

const COMPONENTS: Component[] = [
  {
    id: 'all',
    name: 'Whole drone',
    sub: 'Airframe',
    pose: { az: 32, el: 26, dist: 0.8, target: null, explode: 0, focus: null },
    tags: ['Quadcopter', 'X frame', 'Schematic'],
    lede: 'A body shell and four thin arms in an X. Every check the app makes happens at the four arm tips.',
    notes: [
      ['Arms', '4'],
      ['Motors', '4, one per arm'],
      ['Propellers', '4, two blades each'],
      ['Geometry here', 'Illustrative'],
    ],
    caption: 'Four arms, four motors, four propellers. One question at each tip.',
    closeup: 'Zoom in on the arm tips, where the checks happen.',
  },
  {
    id: 'body',
    name: 'Body shell',
    sub: 'Locates the drone',
    pose: { az: 64, el: 30, dist: 0.62, target: 'body', explode: 0, focus: 'body' },
    tags: ['Not checked', 'Orientation cue'],
    lede: 'The shell is not inspected itself. It tells the app where the drone is and, once the verified reference defines a front, which way the drone faces.',
    notes: [
      ['Inspected', 'No'],
      ['Front direction', 'From verified reference'],
      ['Status', 'Reference pending'],
    ],
    caption: 'It tells the app where the drone is. Not what is wrong with it.',
    closeup: 'Look closely at the shell outline the app uses to find the drone.',
  },
  {
    id: 'arm',
    name: 'Arms',
    sub: 'Carry the motors',
    pose: { az: -58, el: 38, dist: 0.82, target: null, explode: 0.55, focus: 'arm' },
    tags: ['Must be visible', 'Framing'],
    lede: 'Four thin arms in an X. If an arm is hidden or cut off by the frame, its motor cannot be checked — that ends in Unable to Verify, never a guess.',
    notes: [
      ['Count', '4'],
      ['Layout', 'X'],
      ['Arm out of frame', 'Unable to Verify'],
    ],
    caption: 'Hide one arm, and the whole check stops short of a Pass.',
    closeup: 'See where each arm meets its motor pod.',
  },
  {
    id: 'motor',
    name: 'Motors',
    sub: 'Inspection points',
    pose: { az: 18, el: 22, dist: 0.52, target: 'motor0', explode: 0, focus: 'motor' },
    tags: ['4 inspection points', 'Reference IDs'],
    lede: 'Each arm ends in a motor seated in a pod that doubles as a foot. Which motor is which comes only from the verified reference — never from a drawing or a corner of the screen.',
    notes: [
      ['Count', '4'],
      ['Pod', 'Doubles as a foot'],
      ['Motor identity', 'From verified reference'],
      ['During inspection', 'Disarmed, stopped'],
    ],
    caption: 'Four inspection points. Their names come from the reference.',
    closeup: 'Close in on one motor pod and its motor.',
  },
  {
    id: 'propeller',
    name: 'Propellers',
    sub: 'The question',
    pose: { az: 44, el: 26, dist: 0.4, target: 'prop0', explode: 0, focus: 'propeller' },
    tags: ['Type', 'Position', 'Visible orientation'],
    lede: 'Right type, right motor, right way up? The app compares each propeller with the verified reference. All four are drawn the same here because the schematic does not know the real types.',
    notes: [
      ['Count', '4, one per motor'],
      ['Blades', '2 each'],
      ['Compared', 'Type and visible orientation'],
      ['Resting angle', 'Never an error'],
    ],
    caption: 'Where a blade comes to rest is never an error.',
    closeup: 'Get close to the hub, where orientation shows.',
  },
];

const LOW_LIGHT_CAPTION = 'Low light. An image this dark should end in Unable to Verify, not a guess.';

export function mountExplore(reducedMotion: boolean) {
  const section = document.querySelector<HTMLElement>('#explore');
  const stage = section?.querySelector<HTMLElement>('[data-viewer="explore"]');
  if (!section || !stage) return;
  const host = stage.querySelector<HTMLElement>('[data-canvas]')!;
  const hint = stage.querySelector<HTMLElement>('[data-hint]');
  const caption = stage.querySelector<HTMLElement>('[data-caption]')!;
  const tabsEl = section.querySelector<HTMLElement>('[data-tabs]')!;
  const detail = section.querySelector<HTMLElement>('[data-detail]')!;
  const dialog = section.querySelector<HTMLDialogElement>('[data-expanded]')!;
  const slot = dialog.querySelector<HTMLElement>('[data-expanded-slot]')!;
  const btn = (act: string) => stage.querySelector<HTMLButtonElement>(`[data-act="${act}"]`)!;
  let viewer: DroneViewer | null = null;
  let current = 0;
  let lowLight = false;
  let closeUp = false;
  let swapTimer = 0;

  // ---- tabs ----
  const tabs = COMPONENTS.map((c, i) => {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'tab';
    b.id = `tab-${c.id}`;
    b.setAttribute('role', 'tab');
    b.innerHTML = `<b>${c.name}</b><i>${c.sub}</i>`;
    b.addEventListener('click', () => select(i));
    b.addEventListener('keydown', (e) => {
      const d = e.key === 'ArrowRight' ? 1 : e.key === 'ArrowLeft' ? -1 : 0;
      if (!d) return;
      e.preventDefault();
      const n = (i + d + COMPONENTS.length) % COMPONENTS.length;
      select(n);
      tabs[n].focus();
    });
    tabsEl.append(b);
    return b;
  });

  // ---- card ----
  const paint = (c: Component, instant: boolean) => {
    const fill = () => {
      detail.classList.remove('leaving');
      detail.innerHTML = `
        <h3 style="--i:1">${c.name}<em>${c.sub}</em></h3>
        <p class="tags" style="--i:2">${c.tags.map((t) => `<span>${t}</span>`).join('')}</p>
        <p class="lede" style="--i:3">${c.lede}</p>
        <h4 style="--i:4">Field notes</h4>
        <dl class="traits" style="--i:5">${c.notes.map(([k, v]) => `<div><dt>${k}</dt><dd>${v}</dd></div>`).join('')}</dl>
        <div class="closeup-wrap" style="--i:6">
          <button type="button" class="closeup" aria-pressed="${closeUp}">
            <span class="closeup__lens" aria-hidden="true"></span>
            <span><b>Close-up</b><small>${c.closeup}</small></span>
            <svg class="ico" aria-hidden="true"><use href="#i-chev" /></svg>
          </button>
        </div>`;
      detail.querySelector<HTMLButtonElement>('.closeup')!.addEventListener('click', toggleCloseUp);
      if (!lowLight) caption.textContent = c.caption;
      section.querySelector('.card')!.scrollTop = 0;
    };
    clearTimeout(swapTimer);
    if (instant || reducedMotion) return fill();
    detail.classList.add('leaving');
    swapTimer = window.setTimeout(fill, 200);
  };

  const select = (i: number, instant = false) => {
    if (i === current && !instant) return;
    current = i;
    tabs.forEach((t, k) => {
      t.setAttribute('aria-selected', String(k === i));
      t.tabIndex = k === i ? 0 : -1;
    });
    closeUp = false;
    btn('explode').setAttribute('aria-pressed', String(COMPONENTS[i].pose.explode > 0.5));
    paint(COMPONENTS[i], instant);
    viewer?.flyTo(COMPONENTS[i].pose);
  };

  const toggleCloseUp = () => {
    closeUp = !closeUp;
    if (closeUp) viewer?.closeUp();
    else viewer?.zoomBy(1 / 2.6);
    detail.querySelector('.closeup')?.setAttribute('aria-pressed', String(closeUp));
  };

  // ---- tools ----
  btn('zoom-in').addEventListener('click', () => viewer?.zoomBy(1.35));
  btn('zoom-out').addEventListener('click', () => viewer?.zoomBy(1 / 1.35));
  btn('turn').addEventListener('click', () => viewer?.turn360());
  btn('turn-left').addEventListener('click', () => viewer?.turnBy(-90));
  btn('turn-right').addEventListener('click', () => viewer?.turnBy(90));
  stage.querySelectorAll<HTMLButtonElement>('[data-view]').forEach((b) =>
    b.addEventListener('click', () => viewer?.setView(b.dataset.view as ViewName)),
  );
  const reset = () => {
    closeUp = false;
    viewer?.flyTo(COMPONENTS[current].pose);
    detail.querySelector('.closeup')?.setAttribute('aria-pressed', 'false');
    btn('explode').setAttribute('aria-pressed', String(COMPONENTS[current].pose.explode > 0.5));
  };
  btn('reset').addEventListener('click', reset);
  host.addEventListener('dblclick', reset);
  btn('explode').addEventListener('click', (e) => {
    if (!viewer) return;
    const on = !viewer.exploded;
    viewer.explode(on ? 1 : 0);
    (e.currentTarget as HTMLElement).setAttribute('aria-pressed', String(on));
  });
  btn('light').addEventListener('click', (e) => {
    lowLight = !lowLight;
    viewer?.setLighting(lowLight ? 'low' : 'bench');
    const b = e.currentTarget as HTMLElement;
    b.setAttribute('aria-pressed', String(lowLight));
    b.setAttribute('aria-label', lowLight ? 'Switch to bench light' : 'Switch to low light');
    caption.textContent = lowLight ? LOW_LIGHT_CAPTION : COMPONENTS[current].caption;
  });

  host.addEventListener('keydown', (e) => {
    if (!viewer || e.altKey || e.ctrlKey || e.metaKey) return;
    const map: Record<string, () => void> = {
      ArrowLeft: () => viewer!.rotateBy(-15),
      ArrowRight: () => viewer!.rotateBy(15),
      ArrowUp: () => viewer!.rotateBy(0, -10),
      ArrowDown: () => viewer!.rotateBy(0, 10),
      '+': () => viewer!.zoomBy(1.2),
      '=': () => viewer!.zoomBy(1.2),
      '-': () => viewer!.zoomBy(1 / 1.2),
      '0': reset,
      t: () => viewer!.setView('top'),
      s: () => viewer!.setView('side'),
      p: () => viewer!.setView('perspective'),
    };
    const f = map[e.key] ?? map[e.key.toLowerCase()];
    if (f) {
      e.preventDefault();
      f();
    }
  });

  // ---- expanded view ----
  const home = document.createComment('explore-stage');
  stage.before(home);
  btn('expand').addEventListener('click', () => {
    if (dialog.open) return dialog.close();
    slot.append(stage);
    dialog.showModal();
    btn('expand').setAttribute('aria-label', 'Close expanded viewer');
    if (viewer) viewer.wheelZoom = viewer.pinchZoom = true;
    dialog.querySelector<HTMLButtonElement>('[data-act="collapse"]')!.focus();
  });
  dialog.querySelector('[data-act="collapse"]')!.addEventListener('click', () => dialog.close());
  dialog.addEventListener('close', () => {
    home.after(stage);
    btn('expand').setAttribute('aria-label', 'Expand viewer');
    if (viewer) viewer.wheelZoom = viewer.pinchZoom = false;
    btn('expand').focus();
  });

  select(0, true);

  // three.js loads when the section approaches the viewport, or shortly after
  // the opening has played, whichever comes first.
  let mounted = false;
  const mount = () => {
    if (mounted) return;
    mounted = true;
    io.disconnect();
    mountViewer(stage, {
      interactive: true,
      reducedMotion,
      ground: 'dark',
      homeDist: COMPONENTS[0].pose.dist,
      onInteract: () => hint?.classList.add('is-done'),
    }).then((v) => {
      viewer = v;
      if (!v) return;
      v.flyTo(COMPONENTS[current].pose);
      if (lowLight) v.setLighting('low');
    });
  };
  const io = new IntersectionObserver((entries) => entries.some((e) => e.isIntersecting) && mount(), {
    rootMargin: '600px 0px',
  });
  io.observe(stage);
  window.setTimeout(mount, 6000);
}
