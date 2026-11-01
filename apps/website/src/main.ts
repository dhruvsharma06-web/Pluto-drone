import '@fontsource-variable/archivo/wdth.css';
import './styles.css';
import { initDemo } from './demo/demo';
import { mountExplore } from './explore';
import { initReveal } from './reveal';
import { mountStory } from './story';

const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

// Entry: the drone assembles first on a clean stage; the opening copy arrives
// once it has locked together (story.ts adds .is-loaded). Safety net so text
// never stays hidden if 3D is slow or unavailable.
const reveal = () => document.documentElement.classList.add('is-loaded');
window.setTimeout(reveal, reducedMotion ? 0 : 4800);
document.addEventListener('drone:assembled', reveal, { once: true });

initReveal();

// Header turns solid once the page scrolls.
const bar = document.querySelector<HTMLElement>('.bar');
const onScroll = () => bar?.classList.toggle('is-scrolled', window.scrollY > 40);
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();
initDemo(reducedMotion);
mountStory(reducedMotion);
mountExplore(reducedMotion);
