// Fluid "ink" cursor: a WebGL2 stable-fluids simulation that trails the pointer
// and bursts on click. Ported to plain TypeScript from the SplashCursor React
// component supplied by the frontend owner (same shaders and solver); the
// React wrapper, theme switching and contained mode are dropped because this
// site mounts one full-screen instance. Purple palette only, per the site's
// black/white/purple rule.

const QUALITY = {
  low: { sim: 64, dye: 512, iterations: 10 },
  medium: { sim: 96, dye: 1024, iterations: 16 },
  high: { sim: 128, dye: 1440, iterations: 20 },
};
const BLOOM_RESOLUTION = 256;
const BLOOM_ITERATIONS = 4;
const BLOOM_THRESHOLD = 0.3;
const BLOOM_KNEE = 0.7;

const VERTEX = `#version 300 es
precision highp float;
in vec2 aPosition;
uniform vec2 texelSize;
out vec2 vUv;
out vec2 vL;
out vec2 vR;
out vec2 vT;
out vec2 vB;
void main() {
  vUv = aPosition * 0.5 + 0.5;
  vL = vUv - vec2(texelSize.x, 0.0);
  vR = vUv + vec2(texelSize.x, 0.0);
  vT = vUv + vec2(0.0, texelSize.y);
  vB = vUv - vec2(0.0, texelSize.y);
  gl_Position = vec4(aPosition, 0.0, 1.0);
}`;

const HEADER = `#version 300 es
precision highp float;
precision highp sampler2D;
in vec2 vUv;
in vec2 vL;
in vec2 vR;
in vec2 vT;
in vec2 vB;
out vec4 outColor;
`;

const SHADERS: Record<string, string> = {
  copy: `uniform sampler2D uTexture;
void main() { outColor = texture(uTexture, vUv); }`,
  clear: `uniform sampler2D uTexture;
uniform float value;
void main() { outColor = value * texture(uTexture, vUv); }`,
  splat: `uniform sampler2D uTarget;
uniform float aspectRatio;
uniform vec3 color;
uniform vec2 pointA;
uniform vec2 pointB;
uniform float radius;
void main() {
  vec2 scale = vec2(aspectRatio, 1.0);
  vec2 pa = (vUv - pointA) * scale;
  vec2 ba = (pointB - pointA) * scale;
  float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-9), 0.0, 1.0);
  vec2 d = pa - ba * h;
  vec3 base = texture(uTarget, vUv).xyz;
  outColor = vec4(base + exp(-dot(d, d) / radius) * color, 1.0);
}`,
  burst: `uniform sampler2D uTarget;
uniform float aspectRatio;
uniform vec2 point;
uniform float radius;
uniform float strength;
uniform float seed;
void main() {
  vec2 d = (vUv - point) * vec2(aspectRatio, 1.0);
  float distance = length(d);
  vec2 direction = d / max(distance, 0.00001);
  float angle = atan(d.y, d.x);
  float petals = 0.78 + 0.22 * sin(angle * 5.0 + seed) * sin(angle * 3.0 - seed * 1.7);
  vec2 twist = vec2(-direction.y, direction.x) * 0.3 * sin(angle * 4.0 + seed * 2.3);
  float falloff = exp(-dot(d, d) / radius) * distance / sqrt(radius);
  outColor = vec4(texture(uTarget, vUv).xy + (direction * petals + twist) * falloff * strength, 0.0, 1.0);
}`,
  crown: `uniform sampler2D uTarget;
uniform float aspectRatio;
uniform vec2 point;
uniform float radius;
uniform vec3 colorA;
uniform vec3 colorB;
uniform float seed;
void main() {
  vec2 d = (vUv - point) * vec2(aspectRatio, 1.0);
  vec3 ink = exp(-dot(d, d) / (radius * 0.45)) * colorA;
  for (int i = 0; i < 7; i++) {
    float index = float(i);
    float angle = seed + index * 0.8975979 + sin(seed * 3.0 + index * 1.9) * 0.35;
    float reach = sqrt(radius) * (0.75 + 0.45 * fract(sin(seed * 7.1 + index * 3.7) * 43.7));
    float drop = radius * (0.08 + 0.12 * fract(sin(seed * 2.9 + index * 5.3) * 31.9));
    vec2 q = d - vec2(cos(angle), sin(angle)) * reach;
    ink += exp(-dot(q, q) / drop) * mix(colorA, colorB, fract(index * 0.37 + 0.2));
  }
  outColor = vec4(texture(uTarget, vUv).xyz + ink, 1.0);
}`,
  advection: `uniform sampler2D uVelocity;
uniform sampler2D uSource;
uniform vec2 texelSize;
uniform float dt;
uniform float dissipation;
void main() {
  vec2 coord = vUv - dt * texture(uVelocity, vUv).xy * texelSize;
  outColor = texture(uSource, coord) / (1.0 + dissipation * dt);
}`,
  divergence: `uniform sampler2D uVelocity;
void main() {
  float L = texture(uVelocity, vL).x;
  float R = texture(uVelocity, vR).x;
  float T = texture(uVelocity, vT).y;
  float B = texture(uVelocity, vB).y;
  vec2 C = texture(uVelocity, vUv).xy;
  if (vL.x < 0.0) L = -C.x;
  if (vR.x > 1.0) R = -C.x;
  if (vT.y > 1.0) T = -C.y;
  if (vB.y < 0.0) B = -C.y;
  outColor = vec4(0.5 * (R - L + T - B), 0.0, 0.0, 1.0);
}`,
  curl: `uniform sampler2D uVelocity;
void main() {
  float L = texture(uVelocity, vL).y;
  float R = texture(uVelocity, vR).y;
  float T = texture(uVelocity, vT).x;
  float B = texture(uVelocity, vB).x;
  outColor = vec4(0.5 * (R - L - T + B), 0.0, 0.0, 1.0);
}`,
  vorticity: `uniform sampler2D uVelocity;
uniform sampler2D uCurl;
uniform float curl;
uniform float dt;
void main() {
  float L = texture(uCurl, vL).x;
  float R = texture(uCurl, vR).x;
  float T = texture(uCurl, vT).x;
  float B = texture(uCurl, vB).x;
  float C = texture(uCurl, vUv).x;
  vec2 force = 0.5 * vec2(abs(T) - abs(B), abs(R) - abs(L));
  force /= length(force) + 0.0001;
  force *= curl * C;
  force.y *= -1.0;
  vec2 velocity = texture(uVelocity, vUv).xy + force * dt;
  outColor = vec4(clamp(velocity, -1000.0, 1000.0), 0.0, 1.0);
}`,
  pressure: `uniform sampler2D uPressure;
uniform sampler2D uDivergence;
void main() {
  float L = texture(uPressure, vL).x;
  float R = texture(uPressure, vR).x;
  float T = texture(uPressure, vT).x;
  float B = texture(uPressure, vB).x;
  float divergence = texture(uDivergence, vUv).x;
  outColor = vec4((L + R + B + T - divergence) * 0.25, 0.0, 0.0, 1.0);
}`,
  gradient: `uniform sampler2D uPressure;
uniform sampler2D uVelocity;
void main() {
  float L = texture(uPressure, vL).x;
  float R = texture(uPressure, vR).x;
  float T = texture(uPressure, vT).x;
  float B = texture(uPressure, vB).x;
  vec2 velocity = texture(uVelocity, vUv).xy - vec2(R - L, T - B);
  outColor = vec4(velocity, 0.0, 1.0);
}`,
  prefilter: `uniform sampler2D uTexture;
uniform vec3 curve;
uniform float threshold;
void main() {
  vec3 c = texture(uTexture, vUv).rgb;
  float br = max(c.r, max(c.g, c.b));
  float rq = clamp(br - curve.x, 0.0, curve.y);
  rq = curve.z * rq * rq;
  c *= max(rq, br - threshold) / max(br, 0.0001);
  outColor = vec4(c, 0.0);
}`,
  blur: `uniform sampler2D uTexture;
uniform float intensity;
void main() {
  vec4 sum = texture(uTexture, vL) + texture(uTexture, vR) + texture(uTexture, vT) + texture(uTexture, vB);
  outColor = sum * 0.25 * intensity;
}`,
  display: `uniform sampler2D uTexture;
uniform sampler2D uBloom;
uniform vec2 texelSize;
uniform float shading;
uniform float bloom;
float hash(vec2 p) {
  vec3 q = fract(vec3(p.xyx) * 0.1031);
  q += dot(q, q.yzx + 33.33);
  return fract((q.x + q.y) * q.z);
}
void main() {
  vec3 c = texture(uTexture, vUv).rgb;
  if (shading > 0.0) {
    float dx = length(texture(uTexture, vR).rgb) - length(texture(uTexture, vL).rgb);
    float dy = length(texture(uTexture, vT).rgb) - length(texture(uTexture, vB).rgb);
    vec3 n = normalize(vec3(dx, dy, length(texelSize)));
    c *= mix(1.0, clamp(n.z + 0.7, 0.7, 1.0), shading);
  }
  if (bloom > 0.0) c += max(texture(uBloom, vUv).rgb, 0.0) * bloom;
  c = max(c, 0.0);
  float peak = max(c.r, max(c.g, c.b));
  float grain = (hash(gl_FragCoord.xy) - 0.5) / 255.0 * smoothstep(0.0, 0.03, peak);
  c = max(c + grain, 0.0);
  float alpha = clamp(max(c.r, max(c.g, c.b)), 0.0, 1.0);
  outColor = vec4(min(c, vec3(alpha)), alpha);
}`,
};

export interface SplashOptions {
  colors: string[];
  colorSpeed: number;
  intensity: number;
  size: number;
  force: number;
  swirl: number;
  trail: number;
  momentum: number;
  shading: number;
  glow: number;
  quality: keyof typeof QUALITY;
  clickSplash: boolean;
  intro: boolean;
  zIndex: number;
}

const DEFAULTS: SplashOptions = {
  colors: ['#3b0a6b', '#7a4fc4', '#a983e6'],
  colorSpeed: 1,
  intensity: 1,
  size: 1,
  force: 1,
  swirl: 3,
  trail: 1,
  momentum: 1,
  shading: 1,
  glow: 0,
  quality: 'high',
  clickSplash: true,
  intro: true,
  zIndex: 50,
};

type Format = { internal: number; format: number };
interface Target {
  texture: WebGLTexture;
  fbo: WebGLFramebuffer;
  width: number;
  height: number;
  texelX: number;
  texelY: number;
  attach: (unit: number) => number;
}
interface DoubleTarget {
  read: Target;
  write: Target;
  width: number;
  height: number;
  texelX: number;
  texelY: number;
  swap: () => void;
}
interface Pointer {
  x: number;
  y: number;
  px: number;
  py: number;
  ready: boolean;
  moved: boolean;
  offset: number;
}

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v));

const parseColor = (value: string): [number, number, number] => {
  let hex = String(value).replace('#', '').trim();
  if (hex.length === 3) hex = [...hex].map((c) => c + c).join('');
  const n = parseInt(hex.slice(0, 6), 16);
  if (Number.isNaN(n)) return [1, 1, 1];
  return [((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255];
};

/** Mounts a full-screen fluid cursor. Returns a dispose function (no-op if WebGL2 float targets are unavailable). */
export function mountSplashCursor(partial: Partial<SplashOptions> = {}): () => void {
  const s = { ...DEFAULTS, ...partial };
  const palette = (s.colors.length ? s.colors : ['#ffffff']).map(parseColor);
  const root = document.createElement('div');
  root.className = 'splash-cursor';
  root.style.zIndex = String(s.zIndex);
  root.setAttribute('aria-hidden', 'true');
  const canvas = document.createElement('canvas');
  canvas.className = 'splash-cursor__canvas';
  root.append(canvas);
  document.body.append(root);

  const gl = canvas.getContext('webgl2', {
    alpha: true,
    premultipliedAlpha: true,
    antialias: false,
    depth: false,
    stencil: false,
    preserveDrawingBuffer: false,
  });
  const bail = () => {
    root.remove();
    return () => {};
  };
  if (!gl) return bail();
  gl.getExtension('EXT_color_buffer_float');
  gl.getExtension('EXT_color_buffer_half_float');

  const renderable = (internal: number, format: number) => {
    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, internal, 4, 4, 0, format, gl.HALF_FLOAT, null);
    const fbo = gl.createFramebuffer();
    gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
    const ok = gl.checkFramebufferStatus(gl.FRAMEBUFFER) === gl.FRAMEBUFFER_COMPLETE;
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.deleteFramebuffer(fbo);
    gl.deleteTexture(texture);
    return ok;
  };
  const rgba: Format = { internal: gl.RGBA16F, format: gl.RGBA };
  if (!renderable(rgba.internal, rgba.format)) return bail();
  const rg: Format = renderable(gl.RG16F, gl.RG) ? { internal: gl.RG16F, format: gl.RG } : rgba;
  const r: Format = renderable(gl.R16F, gl.RED) ? { internal: gl.R16F, format: gl.RED } : rg;

  const compile = (type: number, source: string) => {
    const shader = gl.createShader(type)!;
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    return shader;
  };
  const vertex = compile(gl.VERTEX_SHADER, VERTEX);
  const programs: Record<string, { program: WebGLProgram; uniforms: Record<string, WebGLUniformLocation | null> }> = {};
  let broken = false;
  for (const [name, body] of Object.entries(SHADERS)) {
    const fragment = compile(gl.FRAGMENT_SHADER, HEADER + body);
    const program = gl.createProgram()!;
    gl.attachShader(program, vertex);
    gl.attachShader(program, fragment);
    gl.bindAttribLocation(program, 0, 'aPosition');
    gl.linkProgram(program);
    gl.deleteShader(fragment);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) broken = true;
    const uniforms: Record<string, WebGLUniformLocation | null> = {};
    const count = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS) as number;
    for (let i = 0; i < count; i++) {
      const info = gl.getActiveUniform(program, i);
      if (info) uniforms[info.name] = gl.getUniformLocation(program, info.name);
    }
    programs[name] = { program, uniforms };
  }
  gl.deleteShader(vertex);

  const buffer = gl.createBuffer();
  const vao = gl.createVertexArray();
  gl.bindVertexArray(vao);
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
  gl.enableVertexAttribArray(0);
  gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);

  const targets = new Set<Target>();
  let disposed = false;
  let lost = false;

  const release = () => {
    if (gl.isContextLost()) return;
    targets.forEach((t) => {
      gl.deleteFramebuffer(t.fbo);
      gl.deleteTexture(t.texture);
    });
    targets.clear();
    Object.values(programs).forEach((p) => gl.deleteProgram(p.program));
    gl.deleteBuffer(buffer);
    gl.deleteVertexArray(vao);
  };
  if (broken) {
    release();
    return bail();
  }

  const use = (name: string) => {
    const item = programs[name];
    gl.useProgram(item.program);
    return item.uniforms;
  };
  const blit = (target: Target | null) => {
    if (target) {
      gl.viewport(0, 0, target.width, target.height);
      gl.bindFramebuffer(gl.FRAMEBUFFER, target.fbo);
    } else {
      gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
      gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    }
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
  };
  const createTarget = (width: number, height: number, format: Format, filter: number): Target => {
    gl.activeTexture(gl.TEXTURE0);
    const texture = gl.createTexture()!;
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, filter);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, filter);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texImage2D(gl.TEXTURE_2D, 0, format.internal, width, height, 0, format.format, gl.HALF_FLOAT, null);
    const fbo = gl.createFramebuffer()!;
    gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
    gl.viewport(0, 0, width, height);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    const target: Target = {
      texture,
      fbo,
      width,
      height,
      texelX: 1 / width,
      texelY: 1 / height,
      attach: (unit) => {
        gl.activeTexture(gl.TEXTURE0 + unit);
        gl.bindTexture(gl.TEXTURE_2D, texture);
        return unit;
      },
    };
    targets.add(target);
    return target;
  };
  const destroyTarget = (t: Target | null) => {
    if (!t) return;
    gl.deleteFramebuffer(t.fbo);
    gl.deleteTexture(t.texture);
    targets.delete(t);
  };
  const reshape = (t: Target, width: number, height: number, format: Format) => {
    gl.bindTexture(gl.TEXTURE_2D, t.texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, format.internal, width, height, 0, format.format, gl.HALF_FLOAT, null);
    t.width = width;
    t.height = height;
    t.texelX = 1 / width;
    t.texelY = 1 / height;
  };
  const createDouble = (width: number, height: number, format: Format, filter: number): DoubleTarget => {
    const pair: DoubleTarget = {
      read: createTarget(width, height, format, filter),
      write: createTarget(width, height, format, filter),
      width,
      height,
      texelX: 1 / width,
      texelY: 1 / height,
      swap: () => {
        const cur = pair.read;
        pair.read = pair.write;
        pair.write = cur;
      },
    };
    return pair;
  };
  const resizeDouble = (pair: DoubleTarget, width: number, height: number, format: Format, filter: number, keep: boolean) => {
    if (keep) {
      const next = createTarget(width, height, format, filter);
      const u = use('copy');
      gl.uniform1i(u.uTexture, pair.read.attach(0));
      blit(next);
      destroyTarget(pair.read);
      pair.read = next;
    } else reshape(pair.read, width, height, format);
    reshape(pair.write, width, height, format);
    pair.width = width;
    pair.height = height;
    pair.texelX = 1 / width;
    pair.texelY = 1 / height;
  };
  const resolution = (base: number) => {
    const w = gl.drawingBufferWidth;
    const h = gl.drawingBufferHeight;
    const aspect = Math.max(w, h) / Math.max(1, Math.min(w, h));
    const short = Math.round(base);
    const long = Math.round(base * aspect);
    return w > h ? { width: long, height: short } : { width: short, height: long };
  };
  const fit = () => {
    const ratio = Math.min(window.devicePixelRatio || 1, 2);
    const width = Math.max(1, Math.floor(canvas.clientWidth * ratio));
    const height = Math.max(1, Math.floor(canvas.clientHeight * ratio));
    if (canvas.width === width && canvas.height === height) return;
    canvas.width = width;
    canvas.height = height;
  };
  const sizes = () => {
    const q = QUALITY[s.quality];
    const shortSide = Math.min(gl.drawingBufferWidth, gl.drawingBufferHeight);
    return { sim: resolution(q.sim), ink: resolution(Math.max(q.sim, Math.min(q.dye, shortSide))) };
  };

  fit();
  const initial = sizes();
  const dye = createDouble(initial.ink.width, initial.ink.height, rgba, gl.LINEAR);
  const velocity = createDouble(initial.sim.width, initial.sim.height, rg, gl.LINEAR);
  const pressure = createDouble(initial.sim.width, initial.sim.height, r, gl.NEAREST);
  const divergence = createTarget(initial.sim.width, initial.sim.height, r, gl.NEAREST);
  const curl = createTarget(initial.sim.width, initial.sim.height, r, gl.NEAREST);
  let bloom: Target | null = null;
  let bloomChain: Target[] = [];

  const dropBloom = () => {
    destroyTarget(bloom);
    bloomChain.forEach(destroyTarget);
    bloom = null;
    bloomChain = [];
  };
  const ensureBloom = () => {
    if (bloom) return bloom;
    const size = resolution(BLOOM_RESOLUTION);
    const created = createTarget(size.width, size.height, rgba, gl.LINEAR);
    for (let i = 0; i < BLOOM_ITERATIONS; i++) {
      const w = size.width >> (i + 1);
      const h = size.height >> (i + 1);
      if (w < 2 || h < 2) break;
      bloomChain.push(createTarget(w, h, rgba, gl.LINEAR));
    }
    bloom = created;
    return created;
  };
  const resize = () => {
    fit();
    const next = sizes();
    if (dye.width !== next.ink.width || dye.height !== next.ink.height) resizeDouble(dye, next.ink.width, next.ink.height, rgba, gl.LINEAR, true);
    if (velocity.width !== next.sim.width || velocity.height !== next.sim.height) {
      resizeDouble(velocity, next.sim.width, next.sim.height, rg, gl.LINEAR, true);
      resizeDouble(pressure, next.sim.width, next.sim.height, r, gl.NEAREST, false);
      reshape(divergence, next.sim.width, next.sim.height, r);
      reshape(curl, next.sim.width, next.sim.height, r);
    }
    const glowSize = resolution(BLOOM_RESOLUTION);
    if (bloom && (bloom.width !== glowSize.width || bloom.height !== glowSize.height)) dropBloom();
  };
  const radiusFor = (scale: number) => {
    const aspect = canvas.width / canvas.height;
    return ((0.2 * s.size * scale) / 100) * (aspect > 1 ? aspect : 1);
  };
  const splat = (ax: number, ay: number, bx: number, by: number, vx: number, vy: number, color: number[], radius: number) => {
    const u = use('splat');
    gl.uniform1i(u.uTarget, velocity.read.attach(0));
    gl.uniform1f(u.aspectRatio, canvas.width / canvas.height);
    gl.uniform2f(u.pointA, ax, ay);
    gl.uniform2f(u.pointB, bx, by);
    gl.uniform3f(u.color, vx, vy, 0);
    gl.uniform1f(u.radius, radius);
    blit(velocity.write);
    velocity.swap();
    gl.uniform1i(u.uTarget, dye.read.attach(0));
    gl.uniform3f(u.color, color[0], color[1], color[2]);
    blit(dye.write);
    dye.swap();
  };
  const colorAt = (offset: number, now: number) => {
    const phase = (((offset + (now / 1000) * s.colorSpeed * 0.6) % 1) + 1) % 1;
    if (palette.length === 1) return palette[0];
    const position = phase * palette.length;
    const from = palette[Math.floor(position) % palette.length];
    const to = palette[(Math.floor(position) + 1) % palette.length];
    const t = position - Math.floor(position);
    const b = t * t * (3 - 2 * t);
    return [from[0] + (to[0] - from[0]) * b, from[1] + (to[1] - from[1]) * b, from[2] + (to[2] - from[2]) * b];
  };
  const inkFor = (color: number[], amount: number) => color.map((c) => c * amount);

  const flush = (p: Pointer, dt: number, now: number) => {
    const aspect = canvas.width / canvas.height;
    const length = Math.hypot((p.x - p.px) * aspect, p.y - p.py);
    if (length > 0.35) {
      p.px = p.x;
      p.py = p.y;
      return;
    }
    let dx = p.x - p.px;
    let dy = p.y - p.py;
    if (aspect < 1) dx *= aspect;
    else dy /= aspect;
    const radius = radiusFor(1);
    const spread = 1 + length / (1.77 * Math.sqrt(radius));
    const push = (6000 * s.force) / Math.sqrt(spread);
    const amount = (0.15 * s.intensity * Math.min(dt * 60, 1)) / Math.sqrt(spread);
    splat(p.px, p.py, p.x, p.y, dx * push, dy * push, inkFor(colorAt(p.offset, now), amount), radius);
    p.px = p.x;
    p.py = p.y;
  };
  const burst = (x: number, y: number, now: number) => {
    const seed = Math.random() * Math.PI * 2;
    const aspect = canvas.width / canvas.height;
    let u = use('burst');
    gl.uniform1i(u.uTarget, velocity.read.attach(0));
    gl.uniform1f(u.aspectRatio, aspect);
    gl.uniform2f(u.point, x, y);
    gl.uniform1f(u.radius, radiusFor(3));
    gl.uniform1f(u.strength, 1100 * s.force);
    gl.uniform1f(u.seed, seed);
    blit(velocity.write);
    velocity.swap();
    const offset = Math.random();
    const amount = 1.6 * s.intensity;
    const first = inkFor(colorAt(offset, now), amount);
    const second = inkFor(colorAt(offset + 0.3, now), amount);
    u = use('crown');
    gl.uniform1i(u.uTarget, dye.read.attach(0));
    gl.uniform1f(u.aspectRatio, aspect);
    gl.uniform2f(u.point, x, y);
    gl.uniform1f(u.radius, radiusFor(1.6));
    gl.uniform3f(u.colorA, first[0], first[1], first[2]);
    gl.uniform3f(u.colorB, second[0], second[1], second[2]);
    gl.uniform1f(u.seed, seed);
    blit(dye.write);
    dye.swap();
  };
  const step = (dt: number) => {
    const iterations = QUALITY[s.quality].iterations;
    gl.disable(gl.BLEND);
    let u = use('curl');
    gl.uniform2f(u.texelSize, velocity.texelX, velocity.texelY);
    gl.uniform1i(u.uVelocity, velocity.read.attach(0));
    blit(curl);
    u = use('vorticity');
    gl.uniform2f(u.texelSize, velocity.texelX, velocity.texelY);
    gl.uniform1i(u.uVelocity, velocity.read.attach(0));
    gl.uniform1i(u.uCurl, curl.attach(1));
    gl.uniform1f(u.curl, s.swirl);
    gl.uniform1f(u.dt, dt);
    blit(velocity.write);
    velocity.swap();
    u = use('divergence');
    gl.uniform2f(u.texelSize, velocity.texelX, velocity.texelY);
    gl.uniform1i(u.uVelocity, velocity.read.attach(0));
    blit(divergence);
    u = use('clear');
    gl.uniform1i(u.uTexture, pressure.read.attach(0));
    gl.uniform1f(u.value, 0.1);
    blit(pressure.write);
    pressure.swap();
    u = use('pressure');
    gl.uniform2f(u.texelSize, velocity.texelX, velocity.texelY);
    gl.uniform1i(u.uDivergence, divergence.attach(0));
    for (let i = 0; i < iterations; i++) {
      gl.uniform1i(u.uPressure, pressure.read.attach(1));
      blit(pressure.write);
      pressure.swap();
    }
    u = use('gradient');
    gl.uniform2f(u.texelSize, velocity.texelX, velocity.texelY);
    gl.uniform1i(u.uPressure, pressure.read.attach(0));
    gl.uniform1i(u.uVelocity, velocity.read.attach(1));
    blit(velocity.write);
    velocity.swap();
    u = use('advection');
    gl.uniform2f(u.texelSize, velocity.texelX, velocity.texelY);
    gl.uniform1i(u.uVelocity, velocity.read.attach(0));
    gl.uniform1i(u.uSource, velocity.read.attach(0));
    gl.uniform1f(u.dt, dt);
    gl.uniform1f(u.dissipation, 2 / s.momentum);
    blit(velocity.write);
    velocity.swap();
    gl.uniform1i(u.uVelocity, velocity.read.attach(0));
    gl.uniform1i(u.uSource, dye.read.attach(1));
    gl.uniform1f(u.dissipation, 3.5 / s.trail);
    blit(dye.write);
    dye.swap();
  };
  const applyBloom = (amount: number) => {
    const base = ensureBloom();
    if (!bloomChain.length) return;
    gl.disable(gl.BLEND);
    let u = use('prefilter');
    const knee = BLOOM_THRESHOLD * BLOOM_KNEE + 0.0001;
    gl.uniform3f(u.curve, BLOOM_THRESHOLD - knee, knee * 2, 0.25 / knee);
    gl.uniform1f(u.threshold, BLOOM_THRESHOLD);
    gl.uniform1i(u.uTexture, dye.read.attach(0));
    blit(base);
    u = use('blur');
    gl.uniform1f(u.intensity, 1);
    let last = base;
    for (const t of bloomChain) {
      gl.uniform2f(u.texelSize, last.texelX, last.texelY);
      gl.uniform1i(u.uTexture, last.attach(0));
      blit(t);
      last = t;
    }
    gl.blendFunc(gl.ONE, gl.ONE);
    gl.enable(gl.BLEND);
    for (let i = bloomChain.length - 2; i >= 0; i--) {
      const t = bloomChain[i];
      gl.uniform2f(u.texelSize, last.texelX, last.texelY);
      gl.uniform1i(u.uTexture, last.attach(0));
      blit(t);
      last = t;
    }
    gl.disable(gl.BLEND);
    gl.uniform1f(u.intensity, amount);
    gl.uniform2f(u.texelSize, last.texelX, last.texelY);
    gl.uniform1i(u.uTexture, last.attach(0));
    blit(base);
  };
  const render = () => {
    if (s.glow > 0) applyBloom(2 * s.glow);
    gl.disable(gl.BLEND);
    const u = use('display');
    gl.uniform2f(u.texelSize, 1 / gl.drawingBufferWidth, 1 / gl.drawingBufferHeight);
    gl.uniform1i(u.uTexture, dye.read.attach(0));
    gl.uniform1i(u.uBloom, (bloom ?? dye.read).attach(1));
    gl.uniform1f(u.shading, s.shading);
    gl.uniform1f(u.bloom, s.glow > 0 ? 1 : 0);
    blit(null);
  };
  const clearScreen = () => {
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT);
  };

  const pointers = new Map<string, Pointer>();
  const bursts: { x: number; y: number }[] = [];
  const reduced = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false;
  const introPointer: Pointer = { x: 0, y: 0, px: 0, py: 0, ready: false, moved: false, offset: Math.random() };
  let introStart = s.intro && !reduced ? performance.now() + 150 : -1;
  let raf = 0;
  let last = 0;
  let lastActivity = performance.now();

  const advanceIntro = (now: number) => {
    if (introStart < 0) return;
    const progress = (now - introStart) / 1100;
    if (progress < 0) return;
    const t = Math.min(progress, 1);
    const e = t * t * (3 - 2 * t);
    const x = 0.2 + 0.6 * e;
    const y = 0.5 + 0.12 * Math.sin(e * Math.PI * 2);
    if (!introPointer.ready) {
      introPointer.x = introPointer.px = x;
      introPointer.y = introPointer.py = y;
      introPointer.ready = true;
    } else {
      introPointer.x = x;
      introPointer.y = y;
      introPointer.moved = true;
    }
    if (t >= 1) introStart = -1;
    lastActivity = now;
  };
  const frame = (now: number) => {
    raf = 0;
    if (disposed || lost) return;
    const dt = clamp((now - last) / 1000, 0, 1 / 60);
    last = now;
    resize();
    advanceIntro(now);
    if (introPointer.moved) {
      introPointer.moved = false;
      flush(introPointer, dt, now);
    }
    pointers.forEach((p) => {
      if (!p.moved) return;
      p.moved = false;
      flush(p, dt, now);
    });
    bursts.splice(0).forEach((pt) => burst(pt.x, pt.y, now));
    step(dt);
    render();
    const quiet = (2.2 * s.trail + 0.4) * 1000;
    if (introStart >= 0 || now - lastActivity < quiet) raf = requestAnimationFrame(frame);
    else clearScreen();
  };
  const wake = () => {
    lastActivity = performance.now();
    if (raf || disposed || lost) return;
    last = performance.now();
    raf = requestAnimationFrame(frame);
  };
  const locate = (clientX: number, clientY: number) => {
    const rect = canvas.getBoundingClientRect();
    if (!rect.width || !rect.height) return null;
    return { x: (clientX - rect.left) / rect.width, y: 1 - (clientY - rect.top) / rect.height };
  };
  const track = (id: string, clientX: number, clientY: number) => {
    const point = locate(clientX, clientY);
    let p = pointers.get(id);
    if (!point) {
      if (p) p.ready = false;
      return;
    }
    if (!p) {
      p = { x: 0, y: 0, px: 0, py: 0, ready: false, moved: false, offset: Math.random() };
      pointers.set(id, p);
    }
    if (!p.ready) {
      p.x = p.px = point.x;
      p.y = p.py = point.y;
      p.ready = true;
      return;
    }
    p.x = point.x;
    p.y = point.y;
    p.moved = true;
    wake();
  };
  const press = (clientX: number, clientY: number) => {
    if (!s.clickSplash) return;
    const point = locate(clientX, clientY);
    if (!point) return;
    bursts.push(point);
    wake();
  };

  const onPointerMove = (e: PointerEvent) => {
    if (e.pointerType !== 'touch') track(`p${e.pointerId}`, e.clientX, e.clientY);
  };
  const onPointerDown = (e: PointerEvent) => {
    if (e.pointerType !== 'touch') press(e.clientX, e.clientY);
  };
  const onTouchStart = (e: TouchEvent) => {
    Array.from(e.changedTouches).forEach((t) => {
      pointers.delete(`t${t.identifier}`);
      track(`t${t.identifier}`, t.clientX, t.clientY);
      press(t.clientX, t.clientY);
    });
  };
  const onTouchMove = (e: TouchEvent) => {
    Array.from(e.changedTouches).forEach((t) => track(`t${t.identifier}`, t.clientX, t.clientY));
  };
  const onTouchEnd = (e: TouchEvent) => {
    Array.from(e.changedTouches).forEach((t) => pointers.delete(`t${t.identifier}`));
  };
  const onLeave = () => pointers.forEach((p) => (p.ready = false));
  const onLost = (e: Event) => {
    e.preventDefault();
    lost = true;
    cancelAnimationFrame(raf);
    raf = 0;
  };

  window.addEventListener('pointermove', onPointerMove, { passive: true });
  window.addEventListener('pointerdown', onPointerDown, { passive: true });
  window.addEventListener('touchstart', onTouchStart, { passive: true });
  window.addEventListener('touchmove', onTouchMove, { passive: true });
  window.addEventListener('touchend', onTouchEnd, { passive: true });
  window.addEventListener('touchcancel', onTouchEnd, { passive: true });
  document.documentElement.addEventListener('pointerleave', onLeave);
  canvas.addEventListener('webglcontextlost', onLost);

  resize();
  if (introStart >= 0) wake();

  return () => {
    disposed = true;
    cancelAnimationFrame(raf);
    window.removeEventListener('pointermove', onPointerMove);
    window.removeEventListener('pointerdown', onPointerDown);
    window.removeEventListener('touchstart', onTouchStart);
    window.removeEventListener('touchmove', onTouchMove);
    window.removeEventListener('touchend', onTouchEnd);
    window.removeEventListener('touchcancel', onTouchEnd);
    document.documentElement.removeEventListener('pointerleave', onLeave);
    canvas.removeEventListener('webglcontextlost', onLost);
    release();
    root.remove();
  };
}
