// ILLUSTRATIVE SCHEMATIC, drawn in code from simple shapes.
// Proportions were eyeballed from team photos of a small black X-frame
// quadcopter. It is not measured geometry, it is not an approved model, and
// it carries no motor identities or propeller types: all four propellers are
// drawn identically and flat on purpose.

import * as THREE from 'three';
import type { DroneAsset, PartKind } from './types';

/** Arm tips (x, z). Order is drawing order only, never a motor mapping. */
const TIPS: [number, number][] = [
  [0.63, 0.62],
  [-0.63, 0.62],
  [-0.63, -0.6],
  [0.63, -0.6],
];
const ROOTS: [number, number][] = [
  [0.235, 0.3],
  [-0.235, 0.3],
  [-0.2, -0.33],
  [0.2, -0.33],
];
/** Arbitrary resting angles: propellers stop wherever they stop. */
const REST = [0.5, 2.2, 2.75, 1.1];

function canopyGeometry(): THREE.BufferGeometry {
  // Top outline from the photos: narrow, squared-off back; wider, rounded nose.
  const bw = 0.2; // half width at the back
  const fw = 0.255; // half width at the nose
  const s = new THREE.Shape();
  s.moveTo(-bw + 0.09, 0.5);
  s.lineTo(bw - 0.09, 0.5);
  s.quadraticCurveTo(bw, 0.5, bw, 0.41);
  s.lineTo(fw, -0.2);
  s.bezierCurveTo(fw, -0.46, 0.13, -0.53, 0, -0.53);
  s.bezierCurveTo(-0.13, -0.53, -fw, -0.46, -fw, -0.2);
  s.lineTo(-bw, 0.41);
  s.quadraticCurveTo(-bw, 0.5, -bw + 0.09, 0.5);
  // Few bevel segments give the crisp chamfered side facets seen on the shell.
  const g = new THREE.ExtrudeGeometry(s, {
    depth: 0.09,
    bevelEnabled: true,
    bevelThickness: 0.065,
    bevelSize: 0.06,
    bevelSegments: 3,
    curveSegments: 36,
  });
  g.rotateX(-Math.PI / 2);
  // A shallow wedge: the shell rises slightly toward the back.
  const p = g.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const z = p.getZ(i);
    const y = p.getY(i);
    if (y > 0.05) p.setY(i, y + 0.025 * (0.5 - z));
  }
  g.computeVertexNormals();
  g.translate(0, 0.175, 0);
  return g;
}

function bladeGeometry(): THREE.BufferGeometry {
  const b = new THREE.Shape();
  b.moveTo(0.02, -0.009);
  b.bezierCurveTo(0.08, -0.024, 0.2, -0.026, 0.262, -0.007);
  b.quadraticCurveTo(0.279, 0.004, 0.26, 0.014);
  b.bezierCurveTo(0.19, 0.024, 0.08, 0.02, 0.02, 0.009);
  b.lineTo(0.02, -0.009);
  const g = new THREE.ExtrudeGeometry(b, { depth: 0.006, bevelEnabled: false, curveSegments: 18 });
  g.rotateX(-Math.PI / 2);
  return g;
}

type Mats = Record<'body' | 'arm' | 'pod' | 'brass' | 'prop' | 'screw', THREE.MeshStandardMaterial>;

function materials(): Mats {
  // Deep gloss black, like automotive paint: near-black base, strong clearcoat
  // so white light reads as crisp reflections rather than lifting the colour.
  const gloss = (roughness: number) =>
    new THREE.MeshPhysicalMaterial({
      color: 0x010101,
      roughness,
      metalness: 0.15,
      clearcoat: 1,
      clearcoatRoughness: 0.04,
      reflectivity: 0.6,
    });
  return {
    body: gloss(0.16),
    arm: gloss(0.3),
    pod: gloss(0.28),
    // Motor cans are bright metal in the photos.
    brass: new THREE.MeshStandardMaterial({ color: 0xd9dde2, roughness: 0.12, metalness: 1 }),
    prop: gloss(0.26),
    screw: new THREE.MeshStandardMaterial({ color: 0xb8bcc2, roughness: 0.25, metalness: 1 }),
  };
}

function mesh(g: THREE.BufferGeometry, m: THREE.Material, x = 0, y = 0, z = 0): THREE.Mesh {
  const o = new THREE.Mesh(g, m);
  o.position.set(x, y, z);
  return o;
}

function anchor(name: string, parent: THREE.Object3D, x: number, y: number, z: number, map: Map<string, THREE.Object3D>) {
  const a = new THREE.Object3D();
  a.name = name;
  a.position.set(x, y, z);
  parent.add(a);
  map.set(name, a);
}

export function createSchematicDrone(): DroneAsset {
  const m = materials();
  const root = new THREE.Group();
  root.name = 'schematic-drone';
  const parts = new Map<PartKind, THREE.Object3D[]>([
    ['body', []],
    ['arm', []],
    ['motor', []],
    ['propeller', []],
  ]);
  const anchors = new Map<string, THREE.Object3D>();
  const movers: { obj: THREE.Object3D; kind: PartKind; base: THREE.Vector3; dir: THREE.Vector3; from: THREE.Vector3; tilt: number }[] = [];
  const addPart = (kind: PartKind, obj: THREE.Object3D, dir: THREE.Vector3, from: THREE.Vector3, tilt = 0) => {
    root.add(obj);
    parts.get(kind)!.push(obj);
    movers.push({ obj, kind, base: obj.position.clone(), dir, from, tilt });
  };

  // Body shell and its small feet.
  const body = new THREE.Group();
  body.add(mesh(canopyGeometry(), m.body));
  const leg = new THREE.BoxGeometry(0.05, 0.12, 0.07);
  for (const [x, z] of [[0.12, 0.22], [-0.12, 0.22], [0.12, -0.24], [-0.12, -0.24]]) body.add(mesh(leg, m.body, x, 0.06, z));
  anchor('body', body, 0, 0.36, -0.1, anchors);
  addPart('body', body, new THREE.Vector3(0, 0.26, 0), new THREE.Vector3(0, 2.2, 0), 0.5);

  const knuckle = new THREE.CylinderGeometry(0.03, 0.03, 0.05, 20);
  const podG = new THREE.CylinderGeometry(0.05, 0.036, 0.17, 28);
  const collarG = new THREE.CylinderGeometry(0.062, 0.062, 0.022, 28);
  const canG = new THREE.CylinderGeometry(0.033, 0.033, 0.085, 28);
  const shaftG = new THREE.CylinderGeometry(0.013, 0.013, 0.02, 16);
  const hubG = new THREE.CylinderGeometry(0.022, 0.022, 0.026, 20);
  const capG = new THREE.ConeGeometry(0.017, 0.034, 16);
  const screwG = new THREE.CylinderGeometry(0.017, 0.017, 0.008, 16);
  const toothG = new THREE.BoxGeometry(0.018, 0.02, 0.012);
  const blade = bladeGeometry();

  const props: THREE.Group[] = [];
  TIPS.forEach(([tx, tz], i) => {
    const [rx, rz] = ROOTS[i];
    const out = new THREE.Vector3(tx, 0, tz).normalize();

    // Arm: a thin square beam from the body to the pod.
    const arm = new THREE.Group();
    const from = new THREE.Vector3(rx, 0.16, rz);
    const to = new THREE.Vector3(tx, 0.13, tz);
    const len = from.distanceTo(to);
    const beam = mesh(new THREE.BoxGeometry(0.03, 0.028, len), m.arm);
    beam.position.copy(from).lerp(to, 0.5);
    beam.lookAt(to);
    arm.add(beam);
    arm.add(mesh(knuckle, m.arm, rx, 0.17, rz));
    arm.add(mesh(screwG, m.screw, rx, 0.197, rz)); // screw head on the arm mount
    anchor(`arm${i}`, arm, (rx + tx) / 2, 0.16, (rz + tz) / 2, anchors);
    addPart('arm', arm, out.clone().multiplyScalar(0.1), out.clone().multiplyScalar(1.8).add(new THREE.Vector3(0, 0.4, 0)), 0.7);

    // Motor: pod (also the foot), collar and the metal motor can.
    const motor = new THREE.Group();
    motor.position.set(tx, 0, tz);
    motor.add(mesh(podG, m.pod, 0, 0.085, 0));
    motor.add(mesh(collarG, m.pod, 0, 0.165, 0));
    for (let k = 0; k < 6; k++) {
      // Toothed motor clip around the collar.
      const a = (k / 6) * Math.PI * 2;
      const tooth = mesh(toothG, m.pod, Math.cos(a) * 0.066, 0.18, Math.sin(a) * 0.066);
      tooth.rotation.y = -a;
      motor.add(tooth);
    }
    motor.add(mesh(canG, m.brass, 0, 0.2125, 0));
    motor.add(mesh(shaftG, m.pod, 0, 0.262, 0));
    anchor(`motor${i}`, motor, 0, 0.2, 0, anchors);
    addPart('motor', motor, out.clone().multiplyScalar(0.24).add(new THREE.Vector3(0, 0.04, 0)), out.clone().multiplyScalar(2.3).add(new THREE.Vector3(0, -0.3, 0)), -0.8);

    // Propeller: hub, two identical flat blades, cap.
    const prop = new THREE.Group();
    prop.position.set(tx, 0.274, tz);
    prop.rotation.y = REST[i];
    prop.add(mesh(hubG, m.prop));
    const b1 = mesh(blade, m.prop, 0, -0.003, 0);
    const b2 = mesh(blade, m.prop, 0, -0.003, 0);
    b2.rotation.y = Math.PI;
    prop.add(b1, b2, mesh(capG, m.prop, 0, 0.028, 0));
    anchor(`prop${i}`, prop, 0, 0.01, 0, anchors);
    anchor(`propTip${i}`, prop, 0.2, 0, 0, anchors);
    addPart('propeller', prop, out.clone().multiplyScalar(0.24).add(new THREE.Vector3(0, 0.3, 0)), out.clone().multiplyScalar(1.6).add(new THREE.Vector3(0, 2.0, 0)), 0.9);
    props.push(prop);
  });

  // Assembly: parts fly in from outside and land in order body → arms → motors → propellers.
  let explode = 0;
  let staged = 0;
  let assembly = 1;
  // Scroll-scrubbed exploded view: shell lifts first, propellers last, each travelling further.
  const STAGE: Record<PartKind, number> = { body: 0, arm: 0.2, motor: 0.4, propeller: 0.6 };
  const stageAmount = (k: PartKind) => {
    const t = Math.min(1, Math.max(0, (staged - STAGE[k]) / 0.4));
    return (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2) * 2.0;
  };
  const rest = [0, 0, 0, 0];
  const DELAY: Record<PartKind, number> = { body: 0, arm: 0.14, motor: 0.3, propeller: 0.46 };
  const SPAN = 0.52;
  const local = (k: PartKind) => Math.min(1, Math.max(0, (assembly - DELAY[k]) / SPAN));
  const land = (t: number) => 1 - Math.pow(1 - t, 4);
  const apply = () => {
    for (const mv of movers) {
      const away = 1 - land(local(mv.kind));
      mv.obj.position.copy(mv.base).addScaledVector(mv.dir, Math.max(explode, stageAmount(mv.kind))).addScaledVector(mv.from, away);
      mv.obj.rotation.x = mv.tilt * away;
      mv.obj.visible = local(mv.kind) > 0 || assembly >= 1;
    }
    props.forEach((p, i) => (p.rotation.y = REST[i] + rest[i]));
  };

  root.traverse((o) => {
    if ((o as THREE.Mesh).isMesh) {
      o.castShadow = false;
      o.receiveShadow = false;
    }
  });

  return {
    id: 'schematic-v1',
    kind: 'schematic',
    root,
    parts,
    anchors,
    frontDefined: false,
    setExplode(t: number) {
      explode = t;
      apply();
    },
    setExplodeStaged(p: number) {
      staged = p;
      apply();
    },
    setAssembly(p: number) {
      assembly = p;
      apply();
      return (Object.keys(DELAY) as PartKind[]).filter((k) => local(k) >= 1);
    },
    setRestingAngle(index: number, radians: number) {
      rest[index] = radians;
      apply();
    },
    dispose() {
      const geos = new Set<THREE.BufferGeometry>();
      root.traverse((o) => {
        const me = o as THREE.Mesh;
        if (me.isMesh) geos.add(me.geometry);
      });
      geos.forEach((g) => g.dispose());
      Object.values(m).forEach((mat) => mat.dispose());
    },
  };
}
