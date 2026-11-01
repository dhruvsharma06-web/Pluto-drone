import '@fontsource-variable/archivo/wdth.css';
import '@fontsource-variable/playfair-display/wght.css';
import '@fontsource-variable/playfair-display/wght-italic.css';
import './styles.css';
import { initDemo } from './demo/demo';
import { mountExplore } from './explore';
import { mountStage } from './stage';

const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

// Entry: the drone assembles first on a clean stage; the opening copy arrives
// once it has locked together. Safety net so text never stays hidden.
const reveal = () => document.documentElement.classList.add('is-loaded');
window.setTimeout(reveal, reducedMotion ? 0 : 4800);
document.addEventListener('drone:assembled', reveal, { once: true });

// Header turns solid once the page scrolls.
const bar = document.querySelector<HTMLElement>('.bar');
const onScroll = () => bar?.classList.toggle('is-scrolled', window.scrollY > 40);
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();

// Stagger order for each scene's entering copy.
document.querySelectorAll('.scene').forEach((scene) =>
  scene.querySelectorAll<HTMLElement>('[data-in]').forEach((el, i) => el.style.setProperty('--d', String(i))),
);

initDemo(reducedMotion);
mountStage(reducedMotion);
mountExplore(reducedMotion);
