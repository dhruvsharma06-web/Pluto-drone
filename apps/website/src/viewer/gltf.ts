// Adapter for a future APPROVED model (see docs/website/ASSET_BRIEF.md).
// Not used until public/assets/manifest.json lists an approved GLB. Node names
// follow the brief; anything not named is shown as part of the whole model
// and never guessed into a component or a motor identity.

import * as THREE from 'three';
import type { DroneAsset, PartKind } from './types';

const PREFIX: Record<PartKind, string> = {
  body: 'part_body',
  arm: 'part_arm',
  motor: 'part_motor',
  propeller: 'part_prop',
};

export interface ApprovedModelEntry {
  id: string;
  url: string;
  frontDefined: boolean;
  /** Units in the file; the viewer normalises size either way. */
  units?: string;
}

const cache = new Map<string, Promise<THREE.Group>>();

export async function loadApprovedDrone(entry: ApprovedModelEntry): Promise<DroneAsset> {
  const { GLTFLoader } = await import('three/examples/jsm/loaders/GLTFLoader.js');
  if (!cache.has(entry.url)) cache.set(entry.url, new GLTFLoader().loadAsync(entry.url).then((g) => g.scene));
  const scene = (await cache.get(entry.url)!).clone(true);

  // Rest the model on y = 0 and centre it in x/z.
  const box = new THREE.Box3().setFromObject(scene);
  const c = box.getCenter(new THREE.Vector3());
  scene.position.set(-c.x, -box.min.y, -c.z);
  const root = new THREE.Group();
  root.add(scene);

  const parts = new Map<PartKind, THREE.Object3D[]>();
  const anchors = new Map<string, THREE.Object3D>();
  scene.traverse((o) => {
    for (const k of Object.keys(PREFIX) as PartKind[]) {
      if (o.name.startsWith(PREFIX[k])) parts.set(k, [...(parts.get(k) ?? []), o]);
    }
    if (o.name.startsWith('anchor_')) anchors.set(o.name.slice(7), o);
  });
  // Give each component group its own materials so focus highlighting stays per group.
  for (const objs of parts.values())
    for (const o of objs)
      o.traverse((m) => {
        const me = m as THREE.Mesh;
        if (me.isMesh) me.material = (me.material as THREE.Material).clone();
      });

  return {
    id: entry.id,
    kind: 'approved-model',
    root,
    parts,
    anchors,
    frontDefined: entry.frontDefined,
    // Exploded view and resting-angle motion stay off until the hierarchy is inspected.
    dispose() {
      root.traverse((o) => {
        const me = o as THREE.Mesh;
        if (me.isMesh) {
          me.geometry.dispose();
          (Array.isArray(me.material) ? me.material : [me.material]).forEach((m) => m.dispose());
        }
      });
    },
  };
}
