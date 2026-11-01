// Section reveals: fade and rise once, staggered among siblings; big headings
// reveal word by word. Content is visible by default without JS (styles key
// off the .js class), and screen readers still get the plain text.

function splitWords(el: HTMLElement) {
  const text = el.textContent ?? '';
  el.setAttribute('aria-label', text.trim());
  el.textContent = '';
  text
    .trim()
    .split(/\s+/)
    .forEach((word, i, all) => {
      const outer = document.createElement('span');
      outer.className = 'w';
      outer.setAttribute('aria-hidden', 'true');
      const inner = document.createElement('span');
      inner.textContent = word;
      inner.style.setProperty('--w', String(i));
      outer.append(inner);
      el.append(outer);
      if (i < all.length - 1) el.append(' ');
    });
}

export function initReveal() {
  const words = [...document.querySelectorAll<HTMLElement>('[data-words]')];
  words.forEach(splitWords);
  const items = [...document.querySelectorAll<HTMLElement>('[data-reveal]')];
  items.forEach((el) => {
    const siblings = el.parentElement ? [...el.parentElement.children].filter((c) => c.hasAttribute('data-reveal')) : [el];
    el.style.setProperty('--i', String(Math.min(siblings.indexOf(el), 5)));
  });
  const targets = [...items, ...words];
  if (!('IntersectionObserver' in window)) {
    targets.forEach((el) => el.classList.add('is-in'));
    return;
  }
  const io = new IntersectionObserver(
    (entries) => {
      for (const e of entries) {
        if (!e.isIntersecting) continue;
        e.target.classList.add('is-in');
        io.unobserve(e.target);
      }
    },
    { rootMargin: '0px 0px -8% 0px' },
  );
  targets.forEach((el) => io.observe(el));
}
