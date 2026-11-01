// One persistent full-screen 3D stage behind seven snap-scrolled scenes.
// Each scene sets a camera shot, framing and lighting focus; scene changes
// play a full-screen veil transition and stagger the scene's copy in.
// Native scrolling with CSS scroll-snap — nothing is hijacked.

import { mountViewer } from './viewer/mount';
import type { PartKind, Pose } from './viewer/types';
import type { DroneViewer } from './viewer/viewer';

interface Shot {
  pose: Pose;
  /** Model position in frame: fractions of width/height (+x right, +y up). */
  shift: [number, number];
  /** Staged explode target for this scene (0 assembled, 1 apart). */
  apart: number;
  /** Propeller resting angle offset (radians). */
  rest: number;
  /** Flight illustration (1) — only in its own labelled scene, never during inspection. */
  flight?: number;
}

const SHOTS: Record<string, Shot> = {
  hero: { pose: { az: 34, el: 20, dist: 0.92, target: null, explode: 0, focus: null }, shift: [0.25, 0.04], apart: 0, rest: 0 },
  apart: { pose: { az: 28, el: 30, dist: 1.45, target: null, explode: 0, focus: null }, shift: [0, 0.08], apart: 1, rest: 0 },
  propeller: { pose: { az: 46, el: 24, dist: 0.42, target: 'prop0', explode: 0, focus: 'propeller' }, shift: [0.33, -0.02], apart: 0, rest: 1.25 },
  flight: { pose: { az: 22, el: 12, dist: 1.25, target: null, explode: 0, focus: null }, shift: [0, -0.04], apart: 0, rest: 0, flight: 1 },
  how: { pose: { az: 120, el: 14, dist: 1.5, target: null, explode: 0, focus: null }, shift: [0.1, 0.26], apart: 0, rest: 0 },
  results: { pose: { az: 0, el: 88, dist: 1.05, target: null, explode: 0, focus: null }, shift: [0, 0], apart: 0, rest: 0 },
  explore: { pose: { az: 32, el: 26, dist: 0.8, target: null, explode: 0, focus: null }, shift: [0, 0], apart: 0, rest: 0 },
  project: { pose: { az: -40, el: 36, dist: 1.3, target: null, explode: 0, focus: null }, shift: [0.3, 0.3], apart: 0, rest: 0 },
};

/** Explode stage at which each part's label appears in the "Taken apart" scene. */
const LAND_AT: Record<PartKind, number> = { body: 0.15, arm: 0.35, motor: 0.55, propeller: 0.75 };

export function mountStage(reducedMotion: boolean) {
  const stage = document.querySelector<HTMLElement>('[data-viewer="global"]');
  if (!stage) return;
  const root = document.documentElement;
  const scenes = [...document.querySelectorAll<HTMLElement>('[data-scene]')].filter((el) => el.tagName === 'SECTION');
  const dots = [...document.querySelectorAll<HTMLAnchorElement>('[data-dots] a')];
  const veil = document.querySelector<HTMLElement>('.veil');
  const tags = [...stage.querySelectorAll<HTMLElement>('.tag')].map((el) => ({
    el,
    anchor: el.dataset.anchor!,
    scene: el.dataset.scene!,
    land: el.dataset.land as PartKind | undefined,
  }));
  let viewer: DroneViewer | null = null;
  let active = '';
  let assembled = false;
  let apart = 0;
  let apartTween = 0;

  const placeTags = () => {
    if (!viewer) return;
    const w = stage.clientWidth;
    for (const t of tags) {
      if (!t.el.classList.contains('is-on')) continue;
      const p = viewer.project(t.anchor);
      if (!p || !p.visible) continue;
      const x = Math.min(Math.max(p.x + 18, 12), w - t.el.offsetWidth - 12);
      t.el.style.transform = `translate(${x.toFixed(1)}px, ${(p.y - t.el.offsetHeight / 2).toFixed(1)}px)`;
    }
  };

  const updateTags = () => {
    for (const t of tags) {
      const inScene = !!viewer && assembled && t.scene === active;
      const on = t.land ? inScene && apart >= LAND_AT[t.land] : inScene;
      t.el.classList.toggle('is-on', on);
    }
  };

  // Staged explode is tweened over time on entering/leaving "Taken apart".
  const tweenApart = (to: number) => {
    cancelAnimationFrame(apartTween);
    if (!viewer) return;
    const from = apart;
    const dur = to > from ? 2200 : 900;
    const t0 = performance.now();
    const step = (now: number) => {
      const k = reducedMotion ? 1 : Math.min(1, (now - t0) / dur);
      apart = from + (to - from) * k;
      viewer!.setStaged(apart);
      updateTags();
      if (k < 1) apartTween = requestAnimationFrame(step);
    };
    apartTween = requestAnimationFrame(step);
  };

  const shoot = () => {
    const shot = SHOTS[active] ?? SHOTS.hero;
    if (!viewer || !assembled) return;
    viewer.applyPose(shot.pose);
    viewer.setShift(window.innerWidth < 960 ? 0 : shot.shift[0], shot.shift[1]);
    viewer.setRestingAngle(0, shot.rest);
    viewer.setFlight(shot.flight ?? 0);
    if (!shot.flight) viewer.setSteer(0, 0);
    tweenApart(shot.apart);
    updateTags();
  };

  const activate = (id: string) => {
    if (id === active) return;
    const first = !active;
    active = id;
    root.dataset.scene = id;
    scenes.forEach((s) => s.classList.toggle('is-active', s.dataset.scene === id));
    dots.forEach((d) => (d.getAttribute('href') === `#${id}` ? d.setAttribute('aria-current', 'step') : d.removeAttribute('aria-current')));
    if (!first && veil && !reducedMotion) {
      veil.classList.remove('is-sweeping');
      void veil.offsetWidth;
      veil.classList.add('is-sweeping');
    }
    shoot();
  };

  // The active scene is the one covering most of the viewport. Measuring
  // viewport coverage (not the scene's own visible share) keeps scenes taller
  // than the screen from never activating.
  const cover = new Map<Element, number>();
  const io = new IntersectionObserver(
    (entries) => {
      for (const e of entries) cover.set(e.target, e.intersectionRect.height);
      let best: Element | null = null;
      let most = 0;
      cover.forEach((h, el) => { if (h > most) { most = h; best = el; } });
      if (best && most > window.innerHeight * 0.4) activate((best as HTMLElement).dataset.scene!);
    },
    { threshold: Array.from({ length: 21 }, (_, i) => i / 20) },
  );
  scenes.forEach((s) => io.observe(s));
  activate('hero');

  window.addEventListener('resize', shoot);

  // Flight scene: steer the drone with the mouse, or with the arrow keys.
  let kx = 0;
  let ky = 0;
  // Reticle cursor: the dot sits on the pointer, the ring glides after it.
  const reticle = document.querySelector<HTMLElement>('.reticle');
  const dot = reticle?.querySelector<HTMLElement>('.reticle__dot');
  const aim = { x: innerWidth / 2, y: innerHeight / 2, rx: innerWidth / 2, ry: innerHeight / 2 };
  let reticleRaf = 0;
  const glide = () => {
    reticleRaf = 0;
    if (!reticle || active !== 'flight') return;
    const k = reducedMotion ? 1 : 0.18;
    aim.rx += (aim.x - aim.rx) * k;
    aim.ry += (aim.y - aim.ry) * k;
    reticle.style.transform = `translate(${aim.rx.toFixed(1)}px, ${aim.ry.toFixed(1)}px)`;
    if (dot) dot.style.transform = `translate(${(aim.x - aim.rx + 32).toFixed(1)}px, ${(aim.y - aim.ry + 32).toFixed(1)}px)`;
    if (Math.abs(aim.x - aim.rx) + Math.abs(aim.y - aim.ry) > 0.3) reticleRaf = requestAnimationFrame(glide);
  };
  window.addEventListener('pointermove', (e) => {
    if (active !== 'flight' || !viewer || e.pointerType === 'touch') return;
    aim.x = e.clientX;
    aim.y = e.clientY;
    reticle?.classList.add('is-live');
    if (!reticleRaf) reticleRaf = requestAnimationFrame(glide);
    viewer.setSteer((e.clientX / window.innerWidth) * 2 - 1, 1 - (e.clientY / window.innerHeight) * 2 - 0.2);
  });
  window.addEventListener('pointerdown', () => reticle?.classList.add('is-down'));
  window.addEventListener('pointerup', () => reticle?.classList.remove('is-down'));
  window.addEventListener('keydown', (e) => {
    if (active !== 'flight' || !viewer) return;
    const step = 0.25;
    if (e.key === 'ArrowLeft') kx -= step;
    else if (e.key === 'ArrowRight') kx += step;
    else if (e.key === 'ArrowUp' && e.shiftKey) ky += step;
    else if (e.key === 'ArrowDown' && e.shiftKey) ky -= step;
    else return;
    e.preventDefault();
    kx = Math.max(-1, Math.min(1, kx));
    ky = Math.max(-1, Math.min(1, ky));
    viewer.setSteer(kx, ky);
  });

  mountViewer(stage, {
    interactive: false,
    reducedMotion,
    ground: 'dark',
    homeDist: SHOTS.hero.pose.dist,
    viewShiftY: 0.02,
    assemble: true,
    onFrame: placeTags,
    onAssembled: () => {
      assembled = true;
      document.dispatchEvent(new Event('drone:assembled'));
      shoot();
    },
  }).then((v) => {
    viewer = v;
    if (v) shoot();
    else document.dispatchEvent(new Event('drone:assembled')); // no 3D: show the copy now
  });
}
