// Exploded view driven by scroll: a tall track with a sticky full-screen
// stage. Scroll progress through the track (0..1) separates the drone in
// stages — shell, arms, motors, propellers — and labels each group as it
// clears. Native scrolling only; scrolling back reassembles it.

import { mountViewer } from './viewer/mount';
import type { DroneViewer } from './viewer/viewer';

const LINES: [number, string][] = [
  [0, 'Scroll to separate every part. Scroll back to put it together.'],
  [0.12, 'The body shell lifts away.'],
  [0.32, 'Four arms, in an X.'],
  [0.52, 'Four motors, one per arm.'],
  [0.72, 'Four propellers — the parts the check is about.'],
  [0.95, 'Every part the inspection depends on.'],
];

export function mountExploded(reducedMotion: boolean) {
  const section = document.querySelector<HTMLElement>('#exploded');
  const stage = section?.querySelector<HTMLElement>('[data-viewer="exploded"]');
  if (!section || !stage) return;
  const track = section.querySelector<HTMLElement>('.exploded__track')!;
  const line = section.querySelector<HTMLElement>('[data-exploded-line]')!;
  const meter = section.querySelector<HTMLElement>('[data-exploded-meter]')!;
  const tags = [...stage.querySelectorAll<HTMLElement>('.tag')].map((el) => ({
    el,
    anchor: el.dataset.anchor!,
    at: Number(el.dataset.at),
  }));
  let viewer: DroneViewer | null = null;
  let progress = 0;
  let lineIndex = -1;
  let raf = 0;

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

  const update = () => {
    raf = 0;
    const r = track.getBoundingClientRect();
    const span = r.height - window.innerHeight;
    progress = Math.min(1, Math.max(0, -r.top / Math.max(1, span)));
    meter.style.transform = `scaleX(${progress.toFixed(4)})`;
    for (const t of tags) t.el.classList.toggle('is-on', !!viewer && progress >= t.at);
    let i = 0;
    LINES.forEach(([at], k) => progress >= at && (i = k));
    if (i !== lineIndex) {
      lineIndex = i;
      line.textContent = LINES[i][1];
      line.classList.remove('is-swap');
      void line.offsetWidth;
      line.classList.add('is-swap');
    }
    if (!viewer) return;
    viewer.setStaged(progress);
    // The camera drifts round and slightly up as the parts separate.
    viewer.applyPose({ az: 24 + progress * 70, el: 22 + progress * 16, dist: 1.0 + progress * 0.32, target: null, explode: 0, focus: null });
  };
  const onScroll = () => {
    if (!raf) raf = requestAnimationFrame(update);
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', onScroll);
  update();

  let mounted = false;
  const mount = () => {
    if (mounted) return;
    mounted = true;
    io.disconnect();
    mountViewer(stage, {
      interactive: false,
      reducedMotion,
      ground: 'dark',
      homeDist: 0.95,
      onFrame: placeTags,
    }).then((v) => {
      viewer = v;
      update();
    });
  };
  const io = new IntersectionObserver((entries) => entries.some((e) => e.isIntersecting) && mount(), {
    rootMargin: '800px 0px',
  });
  io.observe(section);
  window.setTimeout(mount, 7000);
}
