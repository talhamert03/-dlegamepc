"""PixelRig: a tiny 2.5D skeletal pixel-art renderer.

Characters are built from shaded primitive parts (capsules, ellipses, polygons)
attached to a 2D skeleton. Each part gets a dome-like height field; normals are
derived from it and lit from the top-left, then quantized into hand-made style
5-tone hue-shifted ramps. The result is post-processed with selective outlines,
inner contour lines, contact shadows and despeckling so it reads like hand-drawn
pixel art rather than downscaled vector art.
"""
from __future__ import annotations

import colorsys
import math
from dataclasses import dataclass, field

import numpy as np
from PIL import Image

LIGHT = np.array([-0.55, -0.78, 0.62])
LIGHT = LIGHT / np.linalg.norm(LIGHT)
OUTLINE = (43, 27, 46)


# --------------------------------------------------------------------------- colors
def hex_rgb(h: str):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def _shift_hue(h, target, amount):
    d = ((target - h + 0.5) % 1.0) - 0.5
    step = max(-amount, min(amount, d))
    return (h + step) % 1.0


NTONES = 7
BASE_TONE = 3


def make_ramp(base_hex: str, shade_hue=0.70, light_hue=0.13, contrast=1.0):
    """Return 7 colors dark->highlight with hue shifting (index 3 = base)."""
    r, g, b = [c / 255 for c in hex_rgb(base_hex)]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    out = []
    specs = [  # (hue target, hue amount, sat delta, value mult)
        (shade_hue, 0.08, 0.18, 0.40),
        (shade_hue, 0.055, 0.12, 0.56),
        (shade_hue, 0.03, 0.06, 0.76),
        (None, 0, 0, 1.0),
        (light_hue, 0.02, -0.06, 1.12),
        (light_hue, 0.035, -0.14, 1.24),
        (light_hue, 0.05, -0.32, 1.42),
    ]
    for tgt, amt, ds, vm in specs:
        hh = h if tgt is None or s < 0.05 else _shift_hue(h, tgt, amt)
        vm = 1 + (vm - 1) * contrast
        ss = min(1, max(0, s + ds * (1 if s > 0.05 else 0.3)))
        vv = v * vm
        if vv > 1:  # push saturation down when clipping value
            ss = max(0, ss - (vv - 1) * 0.8)
            vv = 1
        vv = max(0, vv)
        out.append(tuple(int(round(c * 255)) for c in colorsys.hsv_to_rgb(hh, ss, vv)))
    return out


@dataclass
class Material:
    ramp: list
    shiny: bool = False
    flat: float = 0.0       # 0 = full dome lighting, 1 = flat colour
    outline: tuple | None = None


def mat(base_hex, shiny=False, flat=0.0, contrast=1.0, **kw):
    return Material(make_ramp(base_hex, contrast=contrast, **kw), shiny=shiny, flat=flat)


# --------------------------------------------------------------------------- skeleton
@dataclass
class Bone:
    name: str
    parent: str | None
    length: float
    angle: float              # rest angle (degrees) relative to parent
    offset: tuple = (0.0, 0.0)  # in parent local space (along, perp)


class Skeleton:
    def __init__(self, bones: list[Bone], root_pos):
        self.bones = {b.name: b for b in bones}
        self.order = [b.name for b in bones]
        self.root_pos = np.array(root_pos, dtype=float)

    def solve(self, pose: dict, root_offset=(0, 0)):
        world = {}
        for name in self.order:
            b = self.bones[name]
            delta = pose.get(name, 0.0)
            if b.parent is None:
                origin = self.root_pos + np.array(root_offset, dtype=float)
                ang = b.angle + delta
            else:
                p_origin, p_ang, _ = world[b.parent]
                pr = math.radians(p_ang)
                ax = np.array([math.cos(pr), math.sin(pr)])
                ay = np.array([-math.sin(pr), math.cos(pr)])
                origin = p_origin + ax * b.offset[0] + ay * b.offset[1]
                ang = p_ang + b.angle + delta
            world[name] = (origin, ang, b.length)
        return world


# --------------------------------------------------------------------------- parts
@dataclass
class Part:
    bone: str
    kind: str                  # capsule | ellipse | poly
    material: str
    z: float
    geo: dict
    bevel: float | None = None  # distance (px) over which the dome rises
    tone: int = 0              # constant tone offset (e.g. far limbs -1)
    stripes: tuple | None = None  # (angle_deg_local, spacing, width, tone)
    line: bool = True          # draw inner contour against parts behind
    name: str = ""
    cast: bool = True          # casts contact shadow onto parts behind


def _seg_dist(px, py, ax, ay, bx, by):
    vx, vy = bx - ax, by - ay
    wx, wy = px - ax, py - ay
    l2 = vx * vx + vy * vy
    t = np.clip((wx * vx + wy * vy) / (l2 if l2 > 0 else 1), 0, 1)
    cx, cy = ax + vx * t, ay + vy * t
    return np.hypot(px - cx, py - cy), t


def _poly_sdf(px, py, pts):
    """Positive inside, distance to nearest edge."""
    pts = np.asarray(pts, dtype=float)
    n = len(pts)
    dist = np.full(px.shape, np.inf)
    inside = np.zeros(px.shape, dtype=bool)
    for i in range(n):
        ax, ay = pts[i]
        bx, by = pts[(i + 1) % n]
        d, _ = _seg_dist(px, py, ax, ay, bx, by)
        dist = np.minimum(dist, d)
        cond = ((ay > py) != (by > py)) & (px < (bx - ax) * (py - ay) / ((by - ay) + 1e-9) + ax)
        inside ^= cond
    return np.where(inside, dist, -dist)


def part_field(part: Part, world, X, Y):
    """Return (signed distance inside>0, bevel) evaluated on sample grid."""
    origin, ang, length = world[part.bone]
    r = math.radians(ang)
    c, s = math.cos(r), math.sin(r)
    dx, dy = X - origin[0], Y - origin[1]
    lx = dx * c + dy * s      # along bone
    ly = -dx * s + dy * c     # perpendicular
    g = part.geo
    if part.kind == "capsule":
        (ax, ay), (bx, by) = g["a"], g["b"]
        r0, r1 = g["r0"], g.get("r1", g["r0"])
        d, t = _seg_dist(lx, ly, ax, ay, bx, by)
        rad = r0 + (r1 - r0) * t
        sd = rad - d
        bevel = part.bevel or max(r0, r1)
    elif part.kind == "ellipse":
        cx, cy = g["c"]
        rx, ry = g["rx"], g["ry"]
        rot = math.radians(g.get("rot", 0))
        ex, ey = lx - cx, ly - cy
        if rot:
            ex, ey = ex * math.cos(rot) + ey * math.sin(rot), -ex * math.sin(rot) + ey * math.cos(rot)
        k = np.sqrt((ex / rx) ** 2 + (ey / ry) ** 2)
        sd = (1 - k) * min(rx, ry)
        bevel = part.bevel or min(rx, ry)
    elif part.kind == "poly":
        sd = _poly_sdf(lx, ly, g["pts"])
        bevel = part.bevel or 2.0
    else:
        raise ValueError(part.kind)
    return sd, bevel, lx, ly


@dataclass
class Rig:
    skeleton: Skeleton
    parts: list
    materials: dict
    face: object = None         # callable(img_rgba, world, ctx)


def render(rig: Rig, pose: dict, size, ss=4, root_offset=(0, 0), z_over=None,
           outline=True, face_ctx=None, part_filter=None):
    W, H = size
    world = rig.skeleton.solve(pose, root_offset)
    xs = (np.arange(W * ss) + 0.5) / ss
    ys = (np.arange(H * ss) + 0.5) / ss
    X, Y = np.meshgrid(xs, ys)
    top_z = np.full(X.shape, -1e9)
    top_id = np.full(X.shape, -1, dtype=int)
    inten = np.zeros(X.shape)
    stripe = np.zeros(X.shape)
    parts = [p for p in rig.parts if part_filter is None or part_filter(p)]
    zs = []
    for i, p in enumerate(parts):
        z = p.z
        if z_over and p.name in z_over:
            z = z_over[p.name]
        zs.append(z)
    for i in np.argsort(zs, kind="stable"):
        p = parts[i]
        sd, bevel, lx, ly = part_field(p, world, X, Y)
        inside = sd > 0
        if not inside.any():
            continue
        m = rig.materials[p.material]
        hgt = np.clip(sd / bevel, 0, 1)
        hgt = np.sqrt(1 - (1 - hgt) ** 2)
        gy, gx = np.gradient(hgt * bevel, 1 / ss)
        nx, ny = -gx * 1.1, -gy * 1.1
        nz = np.ones_like(nx)
        nrm = np.sqrt(nx * nx + ny * ny + nz * nz)
        li = (nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]) / nrm
        if m.flat:
            li = li * (1 - m.flat) + LIGHT[2] * m.flat
        upd = inside & (zs[i] >= top_z)
        top_z[upd] = zs[i]
        top_id[upd] = i
        inten[upd] = li[upd]
        st = np.zeros(X.shape)
        if p.stripes:
            a, spacing, width, _t = p.stripes
            ar = math.radians(a)
            coord = lx * math.cos(ar) + ly * math.sin(ar)
            st = ((coord % spacing) < width).astype(float)
        stripe[upd] = st[upd]

    # ---- reduce supersamples to pixels
    ids = top_id.reshape(H, ss, W, ss).transpose(0, 2, 1, 3).reshape(H, W, ss * ss)
    its = inten.reshape(H, ss, W, ss).transpose(0, 2, 1, 3).reshape(H, W, ss * ss)
    sts = stripe.reshape(H, ss, W, ss).transpose(0, 2, 1, 3).reshape(H, W, ss * ss)
    pix_id = np.full((H, W), -1, dtype=int)
    pix_i = np.zeros((H, W))
    pix_s = np.zeros((H, W))
    for yy in range(H):
        for xx in range(W):
            v = ids[yy, xx]
            opaque = v >= 0
            if opaque.sum() < ss * ss * 0.45:
                continue
            vals, cnt = np.unique(v[opaque], return_counts=True)
            best = vals[np.argmax(cnt)]
            sel = v == best
            pix_id[yy, xx] = best
            pix_i[yy, xx] = its[yy, xx][sel].mean()
            pix_s[yy, xx] = sts[yy, xx][sel].mean()

    # ---- tones
    tone = np.full((H, W), BASE_TONE, dtype=int)
    t = pix_i
    for thr, k in ((0.47, 3), (0.66, 4), (0.80, 5), (0.94, 6)):
        tone[t >= thr] = k
    for thr, k in ((0.47, 2), (0.30, 1), (0.12, 0)):
        tone[t < thr] = k
    for i, p in enumerate(parts):
        sel = pix_id == i
        if not sel.any():
            continue
        m = rig.materials[p.material]
        if not m.shiny:
            tone[sel & (tone == 6)] = 5
        tone[sel] += p.tone
        if p.stripes:
            tone[sel & (pix_s > 0.5)] += p.stripes[3]

    # contact shadow: pixels whose up-left neighbour belongs to a higher, casting part
    zarr = np.array(zs + [-1e9])
    pz = zarr[pix_id]
    cast = np.array([p.cast for p in parts] + [False])
    for (oy, ox) in [(-1, -1), (-1, 0)]:
        nb = _shift(pix_id, oy, ox)
        nbz = zarr[nb]
        shade = (pix_id >= 0) & (nb >= 0) & (nbz > pz + 0.5) & cast[nb]
        tone[shade] -= 2

    # despeckle: lone tone pixels inside a part take their neighbours' tone
    tone = np.clip(tone, 0, NTONES - 1)
    for _ in range(1):
        new = tone.copy()
        for yy in range(1, H - 1):
            for xx in range(1, W - 1):
                pid = pix_id[yy, xx]
                if pid < 0:
                    continue
                nbs = [(yy - 1, xx), (yy + 1, xx), (yy, xx - 1), (yy, xx + 1)]
                same = [tone[a, b] for a, b in nbs if pix_id[a, b] == pid]
                if len(same) == 4 and all(s != tone[yy, xx] for s in same):
                    vals, cnt = np.unique(same, return_counts=True)
                    if cnt.max() >= 3:
                        new[yy, xx] = vals[np.argmax(cnt)]
        tone = new

    # inner contour: pixel adjacent (right/down/left/up) to a much higher part -> darkest tone
    line_mask = np.zeros((H, W), dtype=bool)
    for (oy, ox) in [(0, 1), (1, 0), (0, -1), (-1, 0)]:
        nb = _shift(pix_id, oy, ox)
        nbz = zarr[nb]
        own_line = np.array([p.line for p in parts] + [False])
        line_mask |= (pix_id >= 0) & (nb >= 0) & (nb != pix_id) & (nbz > pz + 2.5) & own_line[nb]
    # ---- compose RGBA
    img = np.zeros((H, W, 4), dtype=np.uint8)
    for i, p in enumerate(parts):
        sel = pix_id == i
        if not sel.any():
            continue
        ramp = rig.materials[p.material].ramp
        for k in range(NTONES):
            mk = sel & (tone == k)
            img[mk, :3] = ramp[k]
        lm = sel & line_mask
        img[lm, :3] = _darker(ramp[0])
        img[sel, 3] = 255
    if face_ctx is not None and rig.face is not None:
        rig.face(img, world, face_ctx, pix_id, parts)
    if outline:
        img = add_outline(img)
    return img, world


def _darker(c, k=0.75):
    return tuple(int(v * k) for v in c)


def _shift(a, oy, ox, fill=-1):
    """out[y, x] = a[y + oy, x + ox]"""
    H, W = a.shape
    out = np.full_like(a, fill)
    ys0, ys1 = max(0, -oy), min(H, H - oy)
    xs0, xs1 = max(0, -ox), min(W, W - ox)
    out[ys0:ys1, xs0:xs1] = a[ys0 + oy:ys1 + oy, xs0 + ox:xs1 + ox]
    return out


def add_outline(img):
    """Exterior 1px outline. Top/left edges use a lighter selective outline."""
    H, W, _ = img.shape
    a = img[:, :, 3] > 0
    out = img.copy()
    for yy in range(H):
        for xx in range(W):
            if a[yy, xx]:
                continue
            nb = []
            for oy, ox in [(0, 1), (1, 0), (0, -1), (-1, 0)]:
                y2, x2 = yy + oy, xx + ox
                if 0 <= y2 < H and 0 <= x2 < W and a[y2, x2]:
                    nb.append((oy, ox, img[y2, x2, :3]))
            if not nb:
                continue
            # Only outline from the opaque pixel side
            out[yy, xx, :3] = OUTLINE
            out[yy, xx, 3] = 255
    return out


def to_image(arr):
    return Image.fromarray(arr, "RGBA")


def stamp(img, x, y, pattern, palette, mask_fn=None):
    """Stamp a small pixel pattern (list of strings) at x,y (top-left)."""
    H, W, _ = img.shape
    for j, row in enumerate(pattern):
        for i, ch in enumerate(row):
            if ch == ".":
                continue
            yy, xx = int(y) + j, int(x) + i
            if 0 <= yy < H and 0 <= xx < W:
                if mask_fn and not mask_fn(yy, xx):
                    continue
                img[yy, xx, :3] = palette[ch]
                img[yy, xx, 3] = 255
