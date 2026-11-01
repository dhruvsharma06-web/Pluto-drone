// Progressive enhancement for a stage: the static poster is in the HTML; the
// 3D viewer (and three.js) is loaded on demand and replaces it only once it
// has rendered. Any failure leaves the poster in place with a status message.

import type { DroneViewer, ViewerOptions, ViewerState } from './viewer';

const MESSAGE: Record<ViewerState, string> = {
  loading: 'Loading the 3D schematic. A static drawing is shown meanwhile.',
  ready: '3D schematic ready.',
  failed: '3D view unavailable in this browser. Showing the static schematic instead.',
  lost: 'The 3D view stopped responding. Showing the static schematic instead.',
};

export async function mountViewer(
  stage: HTMLElement,
  opts: Omit<ViewerOptions, 'container' | 'createAsset' | 'onState'>,
): Promise<DroneViewer | null> {
  const host = stage.querySelector<HTMLElement>('[data-canvas]')!;
  const status = stage.querySelector<HTMLElement>('[data-viewer-status]');
  const setState = (s: ViewerState, detail?: string) => {
    stage.dataset.state = s === 'loading' ? 'poster' : s;
    if (status) status.textContent = detail && s !== 'ready' ? `${detail} ${MESSAGE[s]}` : MESSAGE[s];
  };
  try {
    const [{ DroneViewer }, { resolveAsset }] = await Promise.all([import('./viewer'), import('./asset-source')]);
    const viewer = new DroneViewer({ ...opts, container: host, createAsset: resolveAsset, onState: setState });
    await viewer.init();
    return viewer;
  } catch (err) {
    console.warn('[viewer] falling back to static schematic:', err);
    setState('failed');
    return null;
  }
}
