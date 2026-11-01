// Drone viewer: renderer, lighting, camera framing, inertia, zoom, views,
// component focus and story poses. It knows nothing about page content and
// talks to the model only through the DroneAsset interface.

import * as THREE from 'three';
import { RoomEnvironment } from 'three/examples/jsm/environments/RoomEnvironment.js';
import type { DroneAsset, PartKind, Pose } from './types';

export type ViewerState = 'loading' | 'ready' | 'failed' | 'lost';
export type Lighting = 'bench' | 'low';
export type ViewName = 'perspective' | 'top' | 'side' | 'front';

export interface ViewerOptions {
  container: HTMLElement;
  createAsset: () => DroneAsset | Promise<DroneAsset>;
  /** Pointer drag rotation. The story stage is not interactive; the explore stage is. */
  interactive: boolean;
  reducedMotion: boolean;
  ground: 'dark' | 'light';
  onState?: (s: ViewerState, detail?: string) => void;
  onFrame?: () => void;
  onInteract?: () => void;
  /** Distance multiplier for the home pose (smaller = bigger drone). */
  homeDist?: number;
  /** Shift the model up by this fraction of the stage height (leaves room for captions). */
  viewShiftY?: number;
  /** Play the asset's assembly sequence on load (skipped for reduced motion). */
  assemble?: boolean;
  onLanded?: (kind: PartKind) => void;
  onAssembled?: () => void;
}

export const HOME: Pose = { az: 32, el: 26, dist: 1, target: null, explode: 0, focus: null };

const VIEWS: Record<ViewName, { az: number; el: number }> = {
  perspective: { az: 32, el: 26 },
  top: { az: 0, el: 89 },
  side: { az: 90, el: 5 },
  front: { az: 0, el: 6 },
};

const LIGHTING: Record<Lighting, { key: number; rim: number; hemi: number; env: number; exposure: number }> = {
  bench: { key: 2.4, rim: 2.0, hemi: 0.25, env: 0.38, exposure: 1.0 },
  low: { key: 0.3, rim: 0.4, hemi: 0.05, env: 0.07, exposure: 0.8 },
};

const ZOOM_MIN = 0.55;
const ZOOM_MAX = 3.4;
const FOV = 26;
const ACCENT = new THREE.Color(0xf5c518);
const KINDS: PartKind[] = ['body', 'arm', 'motor', 'propeller'];

const damp = (cur: number, goal: number, rate: number, dt: number) => goal + (cur - goal) * Math.exp(-rate * dt);
const wrapPi = (a: number) => Math.atan2(Math.sin(a), Math.cos(a));
const easeInOut = (t: number) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

function radialTexture(stops: [number, string][]): THREE.CanvasTexture {
  const c = document.createElement('canvas');
  c.width = c.height = 128;
  const g = c.getContext('2d')!;
  const grd = g.createRadialGradient(64, 64, 0, 64, 64, 64);
  for (const [o, col] of stops) grd.addColorStop(o, col);
  g.fillStyle = grd;
  g.fillRect(0, 0, 128, 128);
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}

export function webglAvailable(): boolean {
  try {
    const c = document.createElement('canvas');
    return !!(c.getContext('webgl2') || c.getContext('webgl'));
  } catch {
    return false;
  }
}

export class DroneViewer {
  readonly frontDefined: boolean = false;
  readonly supportsExplode: boolean = false;
  readonly parts: PartKind[] = [];

  private opts: ViewerOptions;
  private renderer!: THREE.WebGLRenderer;
  private scene = new THREE.Scene();
  private camera = new THREE.PerspectiveCamera(FOV, 1, 0.05, 100);
  private storyGroup = new THREE.Group();
  private userGroup = new THREE.Group();
  private holder = new THREE.Group();
  private asset: DroneAsset | null = null;
  private pmrem?: THREE.PMREMGenerator;
  private envTex?: THREE.Texture;
  private textures: THREE.Texture[] = [];
  private key = new THREE.DirectionalLight(0xfff4e6, 2.6);
  private rim = new THREE.DirectionalLight(0x8fbaff, 3.2);
  private rim2 = new THREE.DirectionalLight(0x9fd0ff, 2.2);
  private hemi = new THREE.HemisphereLight(0xffffff, 0x202326, 0.55);
  private fitDistance = 4.6;

  // Animated state (cur eases toward goal every frame).
  private cur = { az: HOME.az, el: HOME.el, dist: HOME.dist, explode: 0, zoom: 1, lift: -0.22 };
  private goal = { az: HOME.az, el: HOME.el, dist: HOME.dist, explode: 0, zoom: 1, lift: 0 };
  private target = new THREE.Vector3();
  private targetGoal = new THREE.Vector3();
  private targetAnchor: string | null = null;
  private yaw = 0;
  private pitch = 0;
  private vYaw = 0;
  private vPitch = 0;
  private returning = false;
  private turn: { from: number; start: number; dur: number } | null = null;
  private focusGoal: PartKind | null = null;
  private focusCur = new Map<PartKind, { hi: number; ghost: number }>();
  private kindMats = new Map<PartKind, THREE.MeshStandardMaterial[]>();
  private light = { ...LIGHTING.bench };
  private lightGoal = { ...LIGHTING.bench };
  private rest: { cur: number; goal: number }[] = [0, 0, 0, 0].map(() => ({ cur: 0, goal: 0 }));
  private idle = 0;
  private lastInteraction = -Infinity;
  private assembly: { start: number; dur: number; landed: Set<PartKind> } | null = null;

  // Loop and lifecycle.
  private raf = 0;
  private last = 0;
  private visible = true;
  private onScreen = true;
  private lost = false;
  private disposed = false;
  private ro?: ResizeObserver;
  private io?: IntersectionObserver;
  private cleanups: (() => void)[] = [];
  private pointers = new Map<number, { x: number; y: number }>();
  private pinchDist = 0;
  private lastMoveT = 0;
  wheelZoom = false;
  pinchZoom = false;

  constructor(opts: ViewerOptions) {
    this.opts = opts;
  }

  async init(): Promise<void> {
    const { container } = this.opts;
    this.opts.onState?.('loading');
    if (!webglAvailable()) throw new Error('WebGL is not available in this browser.');

    const small = Math.min(window.innerWidth, window.innerHeight) < 700;
    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, small ? 1.5 : 2));
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.setClearColor(0x000000, 0);
    const canvas = this.renderer.domElement;
    canvas.setAttribute('aria-hidden', 'true');
    canvas.className = 'viewer-canvas';
    container.appendChild(canvas);

    this.pmrem = new THREE.PMREMGenerator(this.renderer);
    this.envTex = this.pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
    this.scene.environment = this.envTex;

    this.key.position.set(3, 5, 4);
    this.rim.position.set(-4, 2.5, -4);
    this.rim2.position.set(4.5, 1.2, -3);
    this.scene.add(this.key, this.rim, this.rim2, this.hemi);
    this.scene.add(this.storyGroup);
    this.storyGroup.add(this.userGroup);
    this.userGroup.add(this.holder);

    const asset = await this.opts.createAsset();
    if (this.disposed) {
      asset.dispose();
      return;
    }
    this.asset = asset;
    (this as { frontDefined: boolean }).frontDefined = asset.frontDefined;
    (this as { supportsExplode: boolean }).supportsExplode = !!asset.setExplode;
    this.holder.add(asset.root);
    for (const k of KINDS) {
      const objs = asset.parts.get(k) ?? [];
      if (!objs.length) continue;
      this.parts.push(k);
      const mats = new Set<THREE.MeshStandardMaterial>();
      for (const o of objs)
        o.traverse((c) => {
          const me = c as THREE.Mesh;
          if (me.isMesh) mats.add(me.material as THREE.MeshStandardMaterial);
        });
      this.kindMats.set(k, [...mats]);
      this.focusCur.set(k, { hi: 0, ghost: 0 });
    }
    this.normalize();
    this.addFloor();

    canvas.addEventListener('webglcontextlost', this.onLost, false);
    canvas.addEventListener('webglcontextrestored', this.onRestored, false);
    this.cleanups.push(() => {
      canvas.removeEventListener('webglcontextlost', this.onLost);
      canvas.removeEventListener('webglcontextrestored', this.onRestored);
    });
    if (this.opts.interactive) this.bindPointer(container);

    this.ro = new ResizeObserver(() => this.resize());
    this.ro.observe(container);
    this.io = new IntersectionObserver(([e]) => {
      this.onScreen = e.isIntersecting;
      this.kick();
    }, { rootMargin: '120px' });
    this.io.observe(container);
    const vis = () => {
      this.visible = document.visibilityState === 'visible';
      this.kick();
    };
    document.addEventListener('visibilitychange', vis);
    this.cleanups.push(() => document.removeEventListener('visibilitychange', vis));

    if (this.opts.reducedMotion || this.opts.assemble) this.cur.lift = 0;
    this.resize();
    this.applyPose(this.home, true);
    if (this.opts.assemble && !this.opts.reducedMotion && asset.setAssembly) {
      // Cinematic intro: parts fly in and lock together while the camera dollies in.
      asset.setAssembly(0);
      this.assembly = { start: performance.now() + 350, dur: 3400, landed: new Set() };
      this.cur.dist = this.goal.dist * 1.55;
      this.cur.az = this.goal.az - 70;
      this.cur.el = this.goal.el + 18;
    } else {
      asset.setAssembly?.(1);
      this.opts.onAssembled?.();
    }
    this.tick(performance.now());
    this.opts.onState?.('ready');
  }

  get home(): Pose {
    return { ...HOME, dist: this.opts.homeDist ?? HOME.dist };
  }

  /** Centre the model, scale its bounding sphere to radius 1 and record the fit distance. */
  private normalize() {
    const box = new THREE.Box3().setFromObject(this.asset!.root);
    const sphere = box.getBoundingSphere(new THREE.Sphere());
    const s = 1 / sphere.radius;
    this.holder.scale.setScalar(s);
    this.holder.position.set(-sphere.center.x * s, -sphere.center.y * s, -sphere.center.z * s);
    this.fitDistance = 1.08 / Math.sin(THREE.MathUtils.degToRad(FOV / 2));
  }

  private addFloor() {
    const shadowTex = radialTexture([
      [0, 'rgba(0,0,0,0.55)'],
      [0.55, 'rgba(0,0,0,0.18)'],
      [1, 'rgba(0,0,0,0)'],
    ]);
    this.textures.push(shadowTex);
    const shadow = new THREE.Mesh(
      new THREE.PlaneGeometry(1.9, 1.8),
      new THREE.MeshBasicMaterial({ map: shadowTex, transparent: true, depthWrite: false }),
    );
    shadow.rotation.x = -Math.PI / 2;
    shadow.position.y = 0.002;
    shadow.renderOrder = -1;
    this.asset!.root.parent!.add(shadow);

    if (this.opts.ground === 'dark') {
      // Glowing pad rings under the drone.
      const ringMat = (opacity: number) =>
        new THREE.MeshBasicMaterial({ color: 0xf5c518, transparent: true, opacity, depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide });
      const ring = new THREE.Mesh(new THREE.RingGeometry(1.02, 1.04, 160), ringMat(0.55));
      const halo = new THREE.Mesh(new THREE.RingGeometry(1.04, 1.16, 160), ringMat(0.1));
      const inner = new THREE.Mesh(new THREE.RingGeometry(0.62, 0.63, 128), ringMat(0.22));
      for (const r of [ring, halo, inner]) {
        r.rotation.x = -Math.PI / 2;
        r.position.y = 0.004;
        r.renderOrder = -1;
        this.asset!.root.parent!.add(r);
      }

      const poolTex = radialTexture([
        [0, 'rgba(255,244,222,0.22)'],
        [0.5, 'rgba(255,244,222,0.06)'],
        [1, 'rgba(255,244,222,0)'],
      ]);
      this.textures.push(poolTex);
      const pool = new THREE.Mesh(
        new THREE.PlaneGeometry(4.2, 4.2),
        new THREE.MeshBasicMaterial({ map: poolTex, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }),
      );
      pool.rotation.x = -Math.PI / 2;
      pool.position.y = 0.001;
      pool.renderOrder = -2;
      this.asset!.root.parent!.add(pool);

      // Soft overhead beam: a studio spotlight falling on the bench.
      const c = document.createElement('canvas');
      c.width = 4;
      c.height = 128;
      const g = c.getContext('2d')!;
      const grd = g.createLinearGradient(0, 0, 0, 128);
      grd.addColorStop(0, 'rgba(255,244,222,0)');
      grd.addColorStop(1, 'rgba(255,244,222,0.5)');
      g.fillStyle = grd;
      g.fillRect(0, 0, 4, 128);
      const beamTex = new THREE.CanvasTexture(c);
      beamTex.colorSpace = THREE.SRGBColorSpace;
      this.textures.push(beamTex);
      const beam = new THREE.Mesh(
        new THREE.CylinderGeometry(0.25, 1.9, 4.5, 48, 1, true),
        new THREE.MeshBasicMaterial({
          map: beamTex,
          transparent: true,
          opacity: 0.09,
          depthWrite: false,
          side: THREE.DoubleSide,
          blending: THREE.AdditiveBlending,
        }),
      );
      beam.position.y = 2.25;
      beam.renderOrder = -3;
      this.asset!.root.parent!.add(beam);
    }
  }

  // ---------- public controls ----------

  /** Move toward a pose. The story calls this on each step; controls call it for views. */
  applyPose(p: Pose, immediate = false) {
    this.goal.az = this.cur.az + wrapPi(THREE.MathUtils.degToRad(p.az - this.cur.az)) * THREE.MathUtils.RAD2DEG;
    this.goal.el = p.el;
    this.goal.dist = p.dist;
    this.goal.explode = this.supportsExplode ? p.explode : 0;
    this.targetAnchor = p.target;
    this.focusGoal = p.focus;
    if (immediate || this.opts.reducedMotion) this.snap();
    this.kick();
  }

  setView(name: ViewName) {
    if (name === 'front' && !this.frontDefined) return;
    const v = VIEWS[name];
    this.returning = true;
    this.applyPose({ az: v.az, el: v.el, dist: this.home.dist, target: null, explode: this.goal.explode, focus: this.focusGoal });
    this.touch();
  }

  focus(kind: PartKind | null) {
    this.focusGoal = kind;
    this.kick();
  }

  explode(amount: number) {
    if (!this.supportsExplode) return;
    this.goal.explode = amount;
    if (this.opts.reducedMotion) this.cur.explode = amount;
    this.kick();
  }

  get exploded() {
    return this.goal.explode > 0.5;
  }

  rotateBy(dYawDeg: number, dPitchDeg = 0) {
    this.turn = null;
    this.returning = false;
    this.yaw += THREE.MathUtils.degToRad(dYawDeg);
    this.pitch = THREE.MathUtils.clamp(this.pitch + THREE.MathUtils.degToRad(dPitchDeg), -0.5, 0.9);
    this.touch();
  }

  zoomBy(factor: number) {
    this.goal.zoom = THREE.MathUtils.clamp(this.goal.zoom * factor, ZOOM_MIN, ZOOM_MAX);
    if (this.opts.reducedMotion) this.cur.zoom = this.goal.zoom;
    this.touch();
  }

  closeUp() {
    this.goal.zoom = 2.6;
    if (this.opts.reducedMotion) this.cur.zoom = this.goal.zoom;
    this.touch();
  }

  reset() {
    this.turn = null;
    this.vYaw = this.vPitch = 0;
    this.returning = true;
    this.goal.zoom = 1;
    this.applyPose({ ...this.home, explode: 0, focus: null });
    if (this.opts.reducedMotion) {
      this.yaw = this.pitch = 0;
      this.cur.zoom = 1;
    }
    this.touch();
  }

  /** One smooth full turn of the model. */
  turn360() {
    if (this.opts.reducedMotion) return;
    this.returning = false;
    this.vYaw = this.vPitch = 0;
    this.turn = { from: this.yaw, start: performance.now(), dur: 3600 };
    this.touch();
  }

  setLighting(l: Lighting) {
    this.lightGoal = { ...LIGHTING[l] };
    if (this.opts.reducedMotion) this.light = { ...this.lightGoal };
    this.kick();
  }

  /** Set where one propeller rests (motors stopped). Used by the story to show resting angle is not an error. */
  setRestingAngle(index: number, radians: number) {
    if (!this.asset?.setRestingAngle || !this.rest[index]) return;
    this.rest[index].goal = radians;
    if (this.opts.reducedMotion) this.rest[index].cur = radians;
    this.kick();
  }

  /** Screen position (container pixels) of a named anchor. */
  project(name: string): { x: number; y: number; visible: boolean } | null {
    const a = this.asset?.anchors.get(name);
    if (!a) return null;
    const v = a.getWorldPosition(new THREE.Vector3()).project(this.camera);
    const { clientWidth: w, clientHeight: h } = this.opts.container;
    return { x: (v.x * 0.5 + 0.5) * w, y: (-v.y * 0.5 + 0.5) * h, visible: v.z < 1 && Math.abs(v.x) < 1.05 && Math.abs(v.y) < 1.05 };
  }

  resize() {
    const { clientWidth: w, clientHeight: h } = this.opts.container;
    if (!w || !h || !this.renderer) return;
    this.renderer.setSize(w, h, false);
    this.camera.aspect = w / h;
    // Keep the whole model in frame on narrow (portrait) stages.
    this.camera.fov = w / h < 1 ? Math.min(44, FOV / Math.max(w / h, 0.6)) : FOV;
    const shift = this.opts.viewShiftY ?? 0;
    if (shift) this.camera.setViewOffset(w, h, 0, h * shift, w, h);
    else this.camera.clearViewOffset();
    this.camera.updateProjectionMatrix();
    this.kick();
  }

  dispose() {
    this.disposed = true;
    cancelAnimationFrame(this.raf);
    this.ro?.disconnect();
    this.io?.disconnect();
    this.cleanups.forEach((f) => f());
    this.asset?.dispose();
    this.scene.traverse((o) => {
      const me = o as THREE.Mesh;
      if (me.isMesh && !this.asset?.root.getObjectById(me.id)) {
        me.geometry.dispose();
        (me.material as THREE.Material).dispose();
      }
    });
    this.textures.forEach((t) => t.dispose());
    this.envTex?.dispose();
    this.pmrem?.dispose();
    this.renderer?.dispose();
    this.renderer?.domElement.remove();
  }

  // ---------- internals ----------

  private touch() {
    this.lastInteraction = performance.now();
    this.opts.onInteract?.();
    this.kick();
  }

  private snap() {
    this.cur.az = this.goal.az;
    this.cur.el = this.goal.el;
    this.cur.dist = this.goal.dist;
    this.cur.explode = this.goal.explode;
    this.cur.zoom = this.goal.zoom;
    this.resolveTarget();
    this.target.copy(this.targetGoal);
    for (const [k, f] of this.focusCur) {
      f.hi = this.focusGoal === k ? 1 : 0;
      f.ghost = this.focusGoal && this.focusGoal !== k ? 1 : 0;
    }
  }

  private resolveTarget() {
    const a = this.targetAnchor ? this.asset?.anchors.get(this.targetAnchor) : null;
    if (a) {
      this.storyGroup.updateMatrixWorld(true);
      a.getWorldPosition(this.targetGoal);
    } else this.targetGoal.set(0, 0, 0);
  }

  private onLost = (e: Event) => {
    e.preventDefault();
    this.lost = true;
    cancelAnimationFrame(this.raf);
    this.raf = 0;
    this.opts.onState?.('lost', 'The 3D view lost its graphics context.');
  };

  private onRestored = () => {
    this.lost = false;
    this.opts.onState?.('ready');
    this.kick();
  };

  private kick() {
    if (this.disposed || this.lost || this.raf || !this.renderer) return;
    if (!this.visible || !this.onScreen) return;
    this.last = performance.now();
    this.raf = requestAnimationFrame(this.tick);
  }

  private tick = (now: number) => {
    this.raf = 0;
    if (this.disposed || this.lost || !this.visible || !this.onScreen) return;
    const dt = Math.min(0.05, Math.max(0.001, (now - this.last) / 1000));
    this.last = now;
    this.update(dt, now);
    this.renderer.render(this.scene, this.camera);
    this.opts.onFrame?.();
    this.raf = requestAnimationFrame(this.tick);
  };

  private update(dt: number, now: number) {
    const rm = this.opts.reducedMotion;
    const c = this.cur, g = this.goal;
    if (this.assembly && this.asset?.setAssembly) {
      const a = this.assembly;
      const p = Math.min(1, Math.max(0, (now - a.start) / a.dur));
      for (const k of this.asset.setAssembly(p)) {
        if (a.landed.has(k)) continue;
        a.landed.add(k);
        this.opts.onLanded?.(k);
      }
      if (p >= 1) {
        this.assembly = null;
        this.opts.onAssembled?.();
      }
    }
    const camRate = this.assembly ? 1.5 : 5;
    c.az = damp(c.az, g.az, camRate, dt);
    c.el = damp(c.el, g.el, camRate, dt);
    c.dist = damp(c.dist, g.dist, camRate, dt);
    c.zoom = damp(c.zoom, g.zoom, 6, dt);
    c.explode = damp(c.explode, g.explode, 4.5, dt);
    c.lift = rm ? 0 : damp(c.lift, g.lift, 4, dt);

    // User rotation: drag, inertia, scripted turn, or smooth return home.
    const dragging = this.pointers.size > 0;
    if (this.turn) {
      const t = Math.min(1, (now - this.turn.start) / this.turn.dur);
      this.yaw = this.turn.from + easeInOut(t) * Math.PI * 2;
      if (t >= 1) {
        this.yaw = wrapPi(this.yaw);
        this.turn = null;
      }
    } else if (this.returning && !dragging) {
      this.yaw = wrapPi(this.yaw);
      this.yaw = damp(this.yaw, 0, 5, dt);
      this.pitch = damp(this.pitch, 0, 5, dt);
      if (Math.abs(this.yaw) < 0.001 && Math.abs(this.pitch) < 0.001) this.returning = false;
    } else if (!dragging) {
      this.yaw += this.vYaw * dt;
      this.pitch = THREE.MathUtils.clamp(this.pitch + this.vPitch * dt, -0.5, 0.9);
      const decay = Math.exp(-dt * 4.5);
      this.vYaw *= decay;
      this.vPitch *= decay;
    }

    // Idle drift: very small, pauses on interaction, returns after ~1.8 s.
    const idleOn = !rm && !dragging && !this.turn && !this.assembly && now - this.lastInteraction > 1800;
    this.idle = damp(this.idle, idleOn ? 1 : 0, idleOn ? 1.2 : 8, dt);
    const t = now / 1000;
    this.userGroup.rotation.set(this.pitch, this.yaw + Math.sin(t * 0.38) * 0.07 * this.idle, 0, 'XYZ');
    this.storyGroup.position.y = c.lift + Math.sin(t * 0.9) * 0.008 * this.idle;

    this.asset?.setExplode?.(c.explode);
    if (this.asset?.setRestingAngle)
      this.rest.forEach((r, i) => {
        if (Math.abs(r.cur - r.goal) > 1e-4) {
          r.cur = rm ? r.goal : damp(r.cur, r.goal, 2.2, dt);
          this.asset!.setRestingAngle!(i, r.cur);
        }
      });

    // Component focus: selected group tinted, the rest ghosted.
    for (const [k, f] of this.focusCur) {
      const hiGoal = this.focusGoal === k ? 1 : 0;
      const ghostGoal = this.focusGoal && this.focusGoal !== k ? 1 : 0;
      if (Math.abs(f.hi - hiGoal) < 1e-3 && Math.abs(f.ghost - ghostGoal) < 1e-3 && f.hi === hiGoal && f.ghost === ghostGoal) continue;
      f.hi = rm ? hiGoal : damp(f.hi, hiGoal, 7, dt);
      f.ghost = rm ? ghostGoal : damp(f.ghost, ghostGoal, 7, dt);
      if (Math.abs(f.hi - hiGoal) < 1e-3) f.hi = hiGoal;
      if (Math.abs(f.ghost - ghostGoal) < 1e-3) f.ghost = ghostGoal;
      for (const m of this.kindMats.get(k) ?? []) {
        m.emissive.copy(ACCENT).multiplyScalar(0.32 * f.hi);
        m.opacity = 1 - 0.82 * f.ghost;
        const tr = f.ghost > 0.001;
        if (m.transparent !== tr) {
          m.transparent = tr;
          m.needsUpdate = true;
        }
        m.depthWrite = f.ghost < 0.5;
      }
    }

    // Lighting preset easing.
    const L = this.light, LG = this.lightGoal;
    for (const key of Object.keys(L) as (keyof typeof L)[]) L[key] = rm ? LG[key] : damp(L[key], LG[key], 3, dt);
    this.key.intensity = L.key;
    this.rim.intensity = L.rim;
    this.rim2.intensity = L.rim * 0.5;
    this.hemi.intensity = L.hemi;
    this.scene.environmentIntensity = L.env;
    this.renderer.toneMappingExposure = L.exposure;

    // Camera orbit around the (possibly anchored) target.
    this.storyGroup.updateMatrixWorld(true);
    this.resolveTarget();
    this.target.x = damp(this.target.x, this.targetGoal.x, 5, dt);
    this.target.y = damp(this.target.y, this.targetGoal.y, 5, dt);
    this.target.z = damp(this.target.z, this.targetGoal.z, 5, dt);
    const az = THREE.MathUtils.degToRad(c.az);
    const el = THREE.MathUtils.degToRad(Math.min(89.4, c.el));
    const d = (this.fitDistance * c.dist) / c.zoom;
    this.camera.position.set(
      this.target.x + d * Math.cos(el) * Math.sin(az),
      this.target.y + d * Math.sin(el),
      this.target.z + d * Math.cos(el) * Math.cos(az),
    );
    this.camera.lookAt(this.target);
  }

  private bindPointer(el: HTMLElement) {
    const down = (e: PointerEvent) => {
      if (e.pointerType === 'mouse' && e.button !== 0) return;
      if (this.pointers.size >= 2) return;
      el.setPointerCapture(e.pointerId);
      this.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
      this.turn = null;
      this.returning = false;
      this.vYaw = this.vPitch = 0;
      this.lastMoveT = performance.now();
      if (this.pointers.size === 2) this.pinchDist = this.pinchSpan();
      el.classList.add('is-grabbing');
      this.touch();
    };
    const move = (e: PointerEvent) => {
      const p = this.pointers.get(e.pointerId);
      if (!p) return;
      const now = performance.now();
      const dt = Math.max(0.008, (now - this.lastMoveT) / 1000);
      this.lastMoveT = now;
      const dx = e.clientX - p.x;
      const dy = e.clientY - p.y;
      p.x = e.clientX;
      p.y = e.clientY;
      if (this.pointers.size === 2) {
        if (!this.pinchZoom) return;
        const span = this.pinchSpan();
        if (this.pinchDist > 0) this.goal.zoom = THREE.MathUtils.clamp(this.goal.zoom * (span / this.pinchDist), ZOOM_MIN, ZOOM_MAX);
        this.pinchDist = span;
      } else {
        const ry = dx * 0.0085;
        const rx = e.pointerType === 'touch' && !this.pinchZoom ? 0 : dy * 0.006;
        this.yaw += ry;
        this.pitch = THREE.MathUtils.clamp(this.pitch + rx, -0.5, 0.9);
        this.vYaw = THREE.MathUtils.clamp(0.6 * this.vYaw + 0.4 * (ry / dt), -9, 9);
        this.vPitch = THREE.MathUtils.clamp(0.6 * this.vPitch + 0.4 * (rx / dt), -6, 6);
      }
      this.touch();
    };
    const up = (e: PointerEvent) => {
      if (!this.pointers.delete(e.pointerId)) return;
      if (performance.now() - this.lastMoveT > 90) this.vYaw = this.vPitch = 0;
      if (this.pointers.size < 2) this.pinchDist = 0;
      if (this.pointers.size === 0) el.classList.remove('is-grabbing');
      this.touch();
    };
    const wheel = (e: WheelEvent) => {
      if (!this.wheelZoom) return; // inline: let the page scroll normally
      e.preventDefault();
      this.goal.zoom = THREE.MathUtils.clamp(this.goal.zoom * Math.exp(-e.deltaY * 0.0015), ZOOM_MIN, ZOOM_MAX);
      this.touch();
    };
    el.addEventListener('pointerdown', down);
    el.addEventListener('pointermove', move);
    el.addEventListener('pointerup', up);
    el.addEventListener('pointercancel', up);
    el.addEventListener('wheel', wheel, { passive: false });
    this.cleanups.push(() => {
      el.removeEventListener('pointerdown', down);
      el.removeEventListener('pointermove', move);
      el.removeEventListener('pointerup', up);
      el.removeEventListener('pointercancel', up);
      el.removeEventListener('wheel', wheel);
    });
  }

  private pinchSpan() {
    const [a, b] = [...this.pointers.values()];
    return a && b ? Math.hypot(a.x - b.x, a.y - b.y) : 0;
  }
}
