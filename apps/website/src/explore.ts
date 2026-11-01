// Interactive inspection viewer: drag with inertia, zoom, views, 360° turn,
// component focus, separated parts, lighting presets, keyboard and an
// expanded dialog. All information also exists as text outside the canvas.

import { mountViewer } from './viewer/mount';
import { PART_LABEL, type PartKind } from './viewer/types';
import type { DroneViewer, ViewName } from './viewer/viewer';

const PART_TEXT: Record<PartKind | '', string> = {
  '': 'A body shell with four arms in an X. The app inspects the four arm tips, where the motors and propellers are.',
  body: 'The central shell. It is not checked itself, but it helps the app find the drone and, once the verified reference defines a front, which way the drone faces.',
  arm: 'Four thin arms in an X. If an arm is hidden or cut off by the frame, its motor cannot be checked — a reason for Unable to Verify.',
  motor:
    'Each arm ends in a motor seated in a pod that doubles as a foot. Every motor is one inspection point; which motor is which comes from the verified reference, not from this drawing.',
  propeller:
    'One two-blade propeller per motor. The check compares each one’s type and visible orientation with the reference. All four are drawn identically here: the schematic does not know the real types.',
};

const LOW_LIGHT_NOTE =
  'Low light preset. In a real check, an image this dark should end in Unable to Verify rather than a guess.';

export function mountExplore(reducedMotion: boolean) {
  const section = document.querySelector<HTMLElement>('#explore');
  const stage = section?.querySelector<HTMLElement>('[data-viewer="explore"]');
  if (!section || !stage) return;
  const host = stage.querySelector<HTMLElement>('[data-canvas]')!;
  const hint = stage.querySelector<HTMLElement>('[data-hint]');
  const note = stage.querySelector<HTMLElement>('.stage__note')!;
  const baseNote = note.textContent ?? '';
  const info = section.querySelector<HTMLElement>('[data-part-info]')!;
  const infoTitle = info.querySelector<HTMLElement>('[data-part-title]')!;
  const infoText = info.querySelector<HTMLElement>('[data-part-text]')!;
  const chips = [...section.querySelectorAll<HTMLButtonElement>('[data-part]')];
  const dialog = section.querySelector<HTMLDialogElement>('[data-expanded]')!;
  const slot = dialog.querySelector<HTMLElement>('[data-expanded-slot]')!;
  const btn = (act: string) => stage.querySelector<HTMLButtonElement>(`[data-act="${act}"]`)!;
  let viewer: DroneViewer | null = null;
  let lowLight = false;

  if (reducedMotion) btn('turn').disabled = true;

  // Component selection (works before the 3D view loads: the text still changes).
  const selectPart = (kind: PartKind | '') => {
    chips.forEach((c) => c.setAttribute('aria-pressed', String(c.dataset.part === kind)));
    infoTitle.textContent = kind ? PART_LABEL[kind] : 'Whole drone';
    infoText.textContent = PART_TEXT[kind];
    info.classList.remove('is-swapping');
    void info.offsetWidth;
    info.classList.add('is-swapping');
    viewer?.focus(kind || null);
  };
  chips.forEach((c) => c.addEventListener('click', () => selectPart((c.dataset.part ?? '') as PartKind | '')));

  // Toolbar.
  stage.querySelectorAll<HTMLButtonElement>('[data-view]').forEach((b) =>
    b.addEventListener('click', () => viewer?.setView(b.dataset.view as ViewName)),
  );
  btn('zoom-in').addEventListener('click', () => viewer?.zoomBy(1.35));
  btn('zoom-out').addEventListener('click', () => viewer?.zoomBy(1 / 1.35));
  btn('close-up').addEventListener('click', () => viewer?.closeUp());
  btn('turn').addEventListener('click', () => viewer?.turn360());
  btn('reset').addEventListener('click', () => {
    viewer?.reset();
    btn('explode').setAttribute('aria-pressed', 'false');
    selectPart('');
  });
  btn('explode').addEventListener('click', (e) => {
    if (!viewer) return;
    const on = !viewer.exploded;
    viewer.explode(on ? 1 : 0);
    (e.currentTarget as HTMLElement).setAttribute('aria-pressed', String(on));
  });
  btn('light').addEventListener('click', (e) => {
    lowLight = !lowLight;
    viewer?.setLighting(lowLight ? 'low' : 'bench');
    (e.currentTarget as HTMLElement).setAttribute('aria-pressed', String(lowLight));
    note.textContent = lowLight ? LOW_LIGHT_NOTE : baseNote;
  });

  // Keyboard equivalents on the focusable viewer.
  host.addEventListener('keydown', (e) => {
    if (!viewer || e.altKey || e.ctrlKey || e.metaKey) return;
    const k = e.key;
    const map: Record<string, () => void> = {
      ArrowLeft: () => viewer!.rotateBy(-15),
      ArrowRight: () => viewer!.rotateBy(15),
      ArrowUp: () => viewer!.rotateBy(0, -10),
      ArrowDown: () => viewer!.rotateBy(0, 10),
      '+': () => viewer!.zoomBy(1.35),
      '=': () => viewer!.zoomBy(1.35),
      '-': () => viewer!.zoomBy(1 / 1.35),
      '0': () => btn('reset').click(),
      t: () => viewer!.setView('top'),
      s: () => viewer!.setView('side'),
      p: () => viewer!.setView('perspective'),
    };
    const f = map[k] ?? map[k.toLowerCase()];
    if (f) {
      e.preventDefault();
      f();
    }
  });

  // Expanded view: move the whole stage into a modal dialog and back.
  const home = document.createComment('explore-stage');
  stage.before(home);
  btn('expand').addEventListener('click', () => {
    if (dialog.open) return;
    slot.append(stage);
    dialog.showModal();
    btn('expand').hidden = true;
    if (viewer) viewer.wheelZoom = viewer.pinchZoom = true;
    dialog.querySelector<HTMLButtonElement>('[data-act="collapse"]')!.focus();
  });
  dialog.querySelector('[data-act="collapse"]')!.addEventListener('click', () => dialog.close());
  dialog.addEventListener('close', () => {
    home.after(stage);
    btn('expand').hidden = false;
    if (viewer) viewer.wheelZoom = viewer.pinchZoom = false;
    btn('expand').focus();
  });

  // Load three.js only when the section approaches the viewport.
  const io = new IntersectionObserver(
    (entries) => {
      if (!entries.some((e) => e.isIntersecting)) return;
      io.disconnect();
      mountViewer(stage, {
        interactive: true,
        reducedMotion,
        ground: 'dark',
        homeDist: 0.78,
        onInteract: () => hint?.classList.add('is-done'),
      }).then((v) => {
        viewer = v;
        if (!v) return;
        const selected = chips.find((c) => c.getAttribute('aria-pressed') === 'true')?.dataset.part as PartKind | '';
        if (selected) v.focus(selected);
        if (lowLight) v.setLighting('low');
      });
    },
    { rootMargin: '600px 0px' },
  );
  io.observe(stage);
}
