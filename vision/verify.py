"""Reference Python implementation of the Android PropellerEngine.

Runs the exported ONNX detector with the same preprocessing, quality gates,
class-agnostic NMS and top-down motor assignment as the Kotlin engine, so the
APK's behaviour can be checked on a desktop:

    python vision/verify.py model.onnx photo1.jpg [photo2.jpg ...]
"""
import json
import sys

import numpy as np
import onnxruntime as ort
from PIL import Image, ImageOps

INPUT, CONF, MIN_CLASS_CONF, IOU = 640, 0.35, 0.40, 0.5
MISMATCH_CONF = 0.60  # a mismatch verdict needs a confident type
BLUR_MIN, DARK_MAX, BRIGHT_MIN = 60.0, 45.0, 235.0
TYPES = ('cw', 'ccw')
REFERENCE = {'front_left': 'cw', 'front_right': 'ccw', 'rear_left': 'ccw', 'rear_right': 'cw'}


def grey(im, target):
    s = target / max(im.size)
    g = im.convert('L').resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.BILINEAR)
    return np.asarray(g, dtype=np.float32)


def quality(im):
    g = grey(im, 320)
    lap = g[:-2, 1:-1] + g[2:, 1:-1] + g[1:-1, :-2] + g[1:-1, 2:] - 4 * g[1:-1, 1:-1]
    out = []
    if lap.var() < BLUR_MIN: out.append('IMAGE_BLURRY')
    if g.mean() < DARK_MAX: out.append('IMAGE_TOO_DARK')
    if g.mean() > BRIGHT_MIN: out.append('IMAGE_OVEREXPOSED')
    return out


def detect(sess, im):
    scale = min(INPUT / im.width, INPUT / im.height)
    nw, nh = int(im.width * scale), int(im.height * scale)
    px, py = (INPUT - nw) / 2, (INPUT - nh) / 2
    canvas = Image.new('RGB', (INPUT, INPUT), (114, 114, 114))
    canvas.paste(im.resize((nw, nh), Image.BILINEAR), (int(px), int(py)))
    x = np.asarray(canvas, dtype=np.float32).transpose(2, 0, 1)[None] / 255
    raw = sess.run(None, {sess.get_inputs()[0].name: x})[0][0]
    scores = raw[4:]
    cls, conf = scores.argmax(0), scores.max(0)
    keep = conf >= CONF
    dets = []
    for (cx, cy, w, h), c, p, sc in zip(raw[:4].T[keep], cls[keep], conf[keep], scores.T[keep]):
        cx, cy, w, h = (cx - px) / scale, (cy - py) / scale, w / scale, h / scale
        dets.append([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, int(c), float(p), sc.astype(float)])
    dets.sort(key=lambda d: -d[5])
    out = []
    for d in dets:
        if all(iou(d, k) <= IOU for k in out): out.append(d)
    return out


def tta_types(sess, im, dets):
    """Average class scores over 90-degree rotations (rotation keeps chirality)."""
    acc = [d[6].copy() for d in dets]
    for k in (1, 2, 3):
        rot = im.rotate(90 * k, expand=True)
        rd = detect(sess, rot)
        for i, d in enumerate(dets):
            x, y, w, h = (d[0] + d[2]) / 2, (d[1] + d[3]) / 2, im.width, im.height
            for _ in range(k):  # PIL rotates counter-clockwise: (x, y) -> (y, w - x)
                x, y, w, h = y, w - x, h, w
            near = [r for r in rd if r[0] <= x <= r[2] and r[1] <= y <= r[3]]
            if near:
                acc[i] += min(near, key=lambda r: abs((r[0] + r[2]) / 2 - x) + abs((r[1] + r[3]) / 2 - y))[6]
    for d, sc in zip(dets, acc):
        d[4] = int(sc.argmax()); d[5] = float(sc.max() / 4)
    return dets


def iou(a, b):
    iw = max(0, min(a[2], b[2]) - max(a[0], b[0])); ih = max(0, min(a[3], b[3]) - max(a[1], b[1]))
    inter = iw * ih
    return inter / ((a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - inter)


def assign(im, dets):
    g = grey(im, 320); gh, gw = g.shape; s = gw / im.width
    c = np.array([[(d[0] + d[2]) / 2, (d[1] + d[3]) / 2] for d in dets]); cx, cy = c.mean(0)
    rx, ry = np.ptp(c[:, 0]) * s * 0.38, np.ptp(c[:, 1]) * s * 0.38
    x0, x1 = max(0, int(cx * s - rx)), min(gw, int(cx * s + rx)); y0, y1 = max(0, int(cy * s - ry)), min(gh, int(cy * s + ry))
    reg = g[y0:y1, x0:x1]
    if reg.size < 50: return None
    thr = np.sort(reg.ravel())[int(reg.size * 0.35)]
    ys, xs = np.nonzero(reg <= thr); xs = xs + x0; ys = ys + y0
    if len(xs) < 50: return None
    mx, my = xs.mean(), ys.mean(); dx_, dy_ = xs - mx, ys - my
    sxx, syy, sxy = (dx_ ** 2).sum(), (dy_ ** 2).sum(), (dx_ * dy_).sum()
    th = 0.5 * np.arctan2(2 * sxy, sxx - syy); r = np.sqrt(((sxx - syy) / 2) ** 2 + sxy ** 2)
    l1, l2 = (sxx + syy) / 2 + r, (sxx + syy) / 2 - r
    if l2 <= 0 or not 1.4 <= l1 / l2 <= 4.5: return None  # side views are far more elongated
    dx, dy = np.cos(th), np.sin(th); half = np.sqrt(l1 / len(xs))
    along = dx_ * dx + dy_ * dy; across = np.abs(-dx_ * dy + dy_ * dx)
    p, m = across[along > half], across[along < -half]
    if len(p) == 0 or len(m) == 0: return None
    if m.mean() > p.mean(): dx, dy = -dx, -dy
    nx, ny = -dy, dx; out = {}
    for d, (bx, by) in zip(dets, c):
        a = (bx - cx) * dx + (by - cy) * dy; b = (bx - cx) * nx + (by - cy) * ny
        k = ('front_' if a > 0 else 'rear_') + ('right' if b > 0 else 'left')
        if k in out: return None
        out[k] = d
    ctr = {k: np.array([(v[0] + v[2]) / 2, (v[1] + v[3]) / 2]) for k, v in out.items()}
    dist = lambda a, b: float(np.hypot(*(ctr[a] - ctr[b])))
    for a, b in [(dist('front_left', 'front_right'), dist('rear_left', 'rear_right')),
                 (dist('front_left', 'rear_left'), dist('front_right', 'rear_right'))]:
        if min(a, b) / max(a, b) < 0.89: return None
    return out


def verify(sess, path):
    im = ImageOps.exif_transpose(Image.open(path)).convert('RGB')
    reasons = quality(im); dets = detect(sess, im)
    if not dets: reasons.append('NO_PROPELLERS_DETECTED')
    elif len(dets) < 4: reasons.append('INCOMPLETE_DRONE_VIEW')
    elif len(dets) > 4: reasons.append('AMBIGUOUS_DETECTIONS')
    if any(d[5] < MIN_CLASS_CONF for d in dets): reasons.append('LOW_CONFIDENCE_CLASSIFICATION')
    if len(dets) == 4: dets = tta_types(sess, im, dets)
    motors = assign(im, dets) if len(dets) == 4 else None
    if len(dets) == 4 and motors is None: reasons.append('UNSUPPORTED_VIEW_TOP_DOWN_REQUIRED')
    if reasons or not motors:
        return {'status': 'unable_to_verify', 'reasons': reasons, 'detections': len(dets)}
    findings = {k: (TYPES[v[4]], REFERENCE[k], round(v[5], 2)) for k, v in motors.items()}
    ok = all(o == e for o, e, _ in findings.values())
    if not ok and any(o != e and c < MISMATCH_CONF for o, e, c in findings.values()):
        return {'status': 'unable_to_verify', 'reasons': ['LOW_CONFIDENCE_CLASSIFICATION'], 'motors': findings}
    return {'status': 'pass' if ok else 'incorrect_installation', 'motors': findings}


if __name__ == '__main__':
    sess = ort.InferenceSession(sys.argv[1], providers=['CPUExecutionProvider'])
    for p in sys.argv[2:]:
        print(p.split('/')[-1].split('\\')[-1], json.dumps(verify(sess, p)))
