// Results showcase: the hovered, focused or tapped phone comes into focus and
// the caption below switches to match it.
export function initResults() {
  const stage = document.querySelector<HTMLElement>('[data-stage3]');
  if (!stage) return;
  const phones = [...stage.querySelectorAll<HTMLButtonElement>('[data-case]')];
  const infos = [...document.querySelectorAll<HTMLElement>('[data-info]')];
  const show = (key: string) => {
    for (const p of phones) {
      const on = p.dataset.case === key;
      p.classList.toggle('is-active', on);
      p.setAttribute('aria-pressed', String(on));
    }
    for (const i of infos) i.hidden = i.dataset.info !== key;
  };
  for (const p of phones) {
    const key = p.dataset.case ?? '';
    p.addEventListener('mouseenter', () => show(key));
    p.addEventListener('focus', () => show(key));
    p.addEventListener('click', () => show(key));
  }
}
