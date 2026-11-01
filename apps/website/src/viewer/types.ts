// Asset-independent scene interface. The viewer only talks to a DroneAsset;
// the illustrative schematic and a future approved GLB both implement it.
// See docs/website/ASSET_BRIEF.md for the contract a real asset must meet.

import type { Object3D } from 'three';

/** Component groups the site can talk about. Motor identities are NOT part of this. */
export type PartKind = 'body' | 'arm' | 'motor' | 'propeller';

export const PART_LABEL: Record<PartKind, string> = {
  body: 'Body shell',
  arm: 'Arms',
  motor: 'Motors and pods',
  propeller: 'Propellers',
};

export interface DroneAsset {
  /** Matches an id in public/assets/manifest.json. */
  id: string;
  /** 'schematic' is drawn in code; 'approved-model' is a supplied, rights-cleared file. */
  kind: 'schematic' | 'approved-model';
  /** Root object, already centred at the origin with y up and resting on y = 0. */
  root: Object3D;
  /** Objects per component group. Empty when the asset is a single merged mesh. */
  parts: Map<PartKind, Object3D[]>;
  /** Named points (in root space, following any explode motion) used for annotations. */
  anchors: Map<string, Object3D>;
  /** True only when the asset's front direction is documented. Gates the front view. */
  frontDefined: boolean;
  /** Present only when parts can actually be separated. 0 = assembled, 1 = separated. */
  setExplode?(amount: number): void;
  /** Staged explode for scroll scrubbing: groups separate in order (shell first, propellers last). 0..1. */
  setExplodeStaged?(progress: number): void;
  /** Present only when the asset can play an assembly sequence. 0 = scattered, 1 = assembled. Returns groups that have landed. */
  setAssembly?(progress: number): PartKind[];
  /** Flight illustration only: spin all propellers to this angle (radians) and show blur discs (0..1). */
  setSpin?(radians: number, blur: number): void;
  /** Rotates one propeller to a resting angle (motors stopped; used to show that resting angle is not an error). */
  setRestingAngle?(index: number, radians: number): void;
  dispose(): void;
}

/** A camera/scene pose the story or the controls can ask for. */
export interface Pose {
  /** Azimuth around the vertical axis, degrees. */
  az: number;
  /** Elevation above the horizon, degrees (90 = top view). */
  el: number;
  /** Distance as a multiple of the fit-to-frame distance. */
  dist: number;
  /** Look-at point: an anchor name, or null for the model centre. */
  target: string | null;
  explode: number;
  focus: PartKind | null;
}
