// Scroll story: normal page scrolling; whichever caption crosses the reading
// band becomes active and the camera glides to that step's pose. No
// scroll-jacking, nothing to sit through — every caption is plain HTML text.

import { mountViewer } from './viewer/mount';
import type { PartKind, Pose } from './viewer/types';
import type { DroneViewer } from './viewer/viewer';

const POSES: Pose[] = [
  { az: 32, el: 22, dist: 0.74, target: null, explode: 0, focus: null }, // opening
  { az: -38, el: 52, dist: 0.74, target: null, explode: 0, focus: null }, // airframe
  { az: 62, el: 30, dist: 0.62, target: 'body', explode: 0, focus: 'body' }, // body shell
  { az: -62, el: 34, dist: 0.8, target: null, explode: 0.55, focus: 'arm' }, // arms
  { az: 18, el: 20, dist: 0.5, target: 'motor0', explode: 0, focus: 'motor' }, // motors
  { az: 44, el: 26, dist: 0.36, target: 'prop0', explode: 0, focus: 'propeller' }, // the propeller
];

export function mountStory(reducedMotion: boolean) {
  const stage = document.querySelector<HTMLElement>('[data-viewer="story"]');
  if (!stage) return;
  const steps = [...document.querySelectorAll<HTMLElement>('.story [data-step]')];
  const tags = [...stage.querySelectorAll<HTMLElement>('.tag')].map((el) => ({
    el,
    anchor: el.dataset.anchor!,
    land: el.dataset.land as PartKind | undefined,
    steps: (el.dataset.steps ?? '').split(',').filter(Boolean).map(Number),
  }));
  let viewer: DroneViewer | null = null;
  let active = 0;
  let assembled = false;

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

  // Re-trigger the HUD "lock on" animation.
  const acquire = () => {
    stage.classList.remove('is-acquiring');
    void stage.offsetWidth;
    stage.classList.add('is-acquiring');
  };

  const setActive = (i: number) => {
    const changed = i !== active;
    active = i;
    steps.forEach((s, k) => s.classList.toggle('is-active', k === i));
    for (const t of tags) if (!t.land) t.el.classList.toggle('is-on', !!viewer && assembled && t.steps.includes(i));
    if (!viewer) return;
    viewer.applyPose(POSES[i] ?? POSES[0]);
    // Last step: the propeller settles at another resting angle. Not spinning; motors are stopped.
    viewer.setRestingAngle(0, i === 5 ? 1.25 : 0);
    if (changed && assembled) acquire();
  };

  const narrow = matchMedia('(max-width: 959px)');
  let io: IntersectionObserver | null = null;
  const observe = () => {
    io?.disconnect();
    io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) if (e.isIntersecting) setActive(Number((e.target as HTMLElement).dataset.step));
      },
      { rootMargin: '-48% 0px -48% 0px' },
    );
    steps.forEach((s) => io!.observe(s));
  };
  observe();
  narrow.addEventListener('change', observe);
  steps[0]?.classList.add('is-active');

  mountViewer(stage, {
    interactive: false,
    reducedMotion,
    ground: 'dark',
    homeDist: POSES[0].dist,
    viewShiftY: narrow.matches ? 0.17 : 0.09,
    assemble: true,
    onFrame: placeTags,
    onLanded: (kind) => {
      // Name each part as it locks into place, then let the label go.
      const t = tags.find((x) => x.land === kind);
      if (!t || active !== 0) return;
      t.el.classList.add('is-on');
      window.setTimeout(() => t.el.classList.remove('is-on'), 1500);
    },
    onAssembled: () => {
      assembled = true;
      document.dispatchEvent(new Event('drone:assembled'));
      stage.classList.add('is-assembled');
      acquire();
      setActive(active);
    },
  }).then((v) => {
    viewer = v;
    if (v) setActive(active);
    else document.dispatchEvent(new Event('drone:assembled')); // no 3D: show the copy now
  });
}
