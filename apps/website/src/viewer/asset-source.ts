// Chooses which drone asset the viewers show, from public/assets/manifest.json.
// Only an entry with role "drone-model" AND status "approved" replaces the
// illustrative schematic. Anything else (missing manifest, pending entry,
// load error) falls back to the schematic.

import { createSchematicDrone } from './schematic';
import type { DroneAsset } from './types';

interface ManifestEntry {
  id: string;
  role: string;
  status: 'approved' | 'pending' | 'excluded';
  path?: string;
  front_defined?: boolean;
}

let manifest: Promise<ManifestEntry[]> | null = null;

function loadManifest(): Promise<ManifestEntry[]> {
  manifest ??= fetch(new URL('assets/manifest.json', document.baseURI))
    .then((r) => (r.ok ? r.json() : { assets: [] }))
    .then((m: { assets?: ManifestEntry[] }) => m.assets ?? [])
    .catch(() => []);
  return manifest;
}

export async function resolveAsset(): Promise<DroneAsset> {
  const entries = await loadManifest();
  const approved = entries.find((e) => e.role === 'drone-model' && e.status === 'approved' && e.path);
  if (approved) {
    try {
      const { loadApprovedDrone } = await import('./gltf');
      return await loadApprovedDrone({
        id: approved.id,
        url: new URL(approved.path!, document.baseURI).href,
        frontDefined: !!approved.front_defined,
      });
    } catch (err) {
      console.warn('[viewer] approved model failed to load; using schematic', err);
    }
  }
  return createSchematicDrone();
}
