import '@fontsource-variable/inter/opsz.css';
import '@fontsource-variable/playfair-display/wght.css';
import '@fontsource-variable/playfair-display/wght-italic.css';
import './styles.css';
import { initDemo } from './demo/demo';
import { mountExplore } from './explore';
import { mountSplashCursor } from './splash-cursor';
import { mountStage } from './stage';

const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

// Every load starts at the opening scene, so the assembly is what you see first.
if ('scrollRestoration' in history) history.scrollRestoration = 'manual';
if (!location.hash) window.scrollTo(0, 0);

// Entry: the drone assembles first on a clean stage; the opening copy arrives
// once it has locked together. Safety net so text never stays hidden.
const reveal = () => document.documentElement.classList.add('is-loaded');
window.setTimeout(reveal, reducedMotion ? 0 : 4800);
document.addEventListener('drone:assembled', reveal, { once: true });

// Mirror the existing scene state in the header without changing scroll behavior.
const navLinks = [...document.querySelectorAll<HTMLAnchorElement>('.pill-nav a')];
const syncNav = () => {
  const scene = document.documentElement.dataset.scene ?? 'hero';
  const target = scene === 'propeller' || scene === 'flight' ? 'apart' : scene;
  navLinks.forEach((link) => {
    if (link.hash === `#${target}`) link.setAttribute('aria-current', 'page');
    else link.removeAttribute('aria-current');
  });
};
new MutationObserver(syncNav).observe(document.documentElement, {
  attributes: true, attributeFilter: ['data-scene'],
});
syncNav();

// Stagger order for each scene's entering copy.
document.querySelectorAll('.scene').forEach((scene) =>
  scene.querySelectorAll<HTMLElement>('[data-in]').forEach((el, i) => el.style.setProperty('--d', String(i))),
);

initDemo(reducedMotion);
mountStage(reducedMotion);
mountExplore(reducedMotion);

// Fluid ink cursor in the site's purple palette (fine pointers only).
if (!reducedMotion && matchMedia('(hover: hover) and (pointer: fine)').matches) {
  mountSplashCursor({
    colors: ['#5a1fa8', '#8a5cd6', '#b79cf0'],
    intensity: 0.85,
    size: 0.9,
    swirl: 3,
    trail: 0.9,
    intro: false,
    quality: 'medium',
    zIndex: 20,
  });
}
