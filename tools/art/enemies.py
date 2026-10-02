"""Enemy & boss sprite generation.

Humanoid enemies (goblins, skeletons, zombies, bandits, villains) reuse the hero Builder
with custom outfits. Creatures (slimes, beasts, flyers, spiders, golems, ents, worms...)
are built per frame from shaded primitives in screen space (facing right) and the final
frames are mirrored so every enemy faces the heroes (left).
"""
from __future__ import annotations

import math

from PIL import Image, ImageOps

from chars import Builder, Variant, materials, make_face, scaled_template, skeleton_for, _mix, face_ctx
from pixelrig import Bone, Part, Rig, Skeleton, mat, render, to_image, stamp
from poses import FAMILY, anim_side, world_to_delta

ANIMS = ["idle", "run", "attack", "skill", "hit", "death"]
FPS = {"idle": 6, "run": 10, "attack": 12, "skill": 10, "hit": 10, "death": 9, "victory": 6}
COUNTS = {"idle": 4, "run": 4, "attack": 6, "skill": 6, "hit": 2, "death": 6}


# =========================================================================== helpers
class Parts:
    def __init__(self):
        self.p = []

    def add(self, kind, material, z, geo, **kw):
        self.p.append(Part("root", kind, material, z, geo, **kw))

    def e(self, material, z, c, rx, ry, rot=0, **kw):
        self.add("ellipse", material, z, {"c": c, "rx": max(0.6, rx), "ry": max(0.6, ry), "rot": rot}, **kw)

    def c(self, material, z, a, b, r0, r1=None, **kw):
        self.add("capsule", material, z, {"a": a, "b": b, "r0": max(0.45, r0), "r1": max(0.45, r1 if r1 is not None else r0)}, **kw)

    def poly(self, material, z, pts, **kw):
        self.add("poly", material, z, {"pts": pts}, **kw)


def creature_mats(color, extra=None):
    m = {
        "body": mat(color),
        "belly": mat(_mix(color, "#F4EEDC", 0.45)),
        "dark": mat(_mix(color, "#1E1A24", 0.55)),
        "eye": mat("#1E1420", flat=0.6),
        "eyew": mat("#FFFFFF", flat=0.8),
        "glow": mat("#FFE45C", shiny=True, flat=0.6),
        "glow_red": mat("#FF4A3A", shiny=True, flat=0.6),
        "bone": mat("#E6DDC6"),
        "metal": mat("#BFC8D2", shiny=True),
        "gold": mat("#E9B949", shiny=True),
        "leaf": mat("#6CC24A"),
        "wood": mat("#7A5A3A"),
        "white": mat("#F4F1EA"),
        "orange": mat("#F29A3A"),
        "pink": mat("#F29AC0"),
        "purple": mat("#8A5AC9"),
        "red": mat("#C9414B"),
        "page": mat("#F3E7C8", flat=0.3),
        "fire": mat("#FFB347", shiny=True, flat=0.4),
    }
    if extra:
        m.update(extra)
    return m


def rig_from(parts: Parts, materials_):
    sk = Skeleton([Bone("root", None, 0, 0)], (0, 0))
    return Rig(sk, parts.p, materials_, None)


def frame_states(anim, n):
    return [{"anim": anim, "i": i, "n": n, "t": i / max(1, n)} for i in range(n)]


# =========================================================================== creature builders
def build_blob(vis, k, st, W, H, gy):
    P = Parts()
    kind = vis.get("kind", "")
    col = vis["color"]
    a, i, n = st["anim"], st["i"], st["n"]
    sx, sy, hop, lean = 1.0, 1.0, 0.0, 0.0
    if a == "idle":
        sy = [1.0, 0.96, 0.92, 0.96][i]
    elif a == "run":
        hop = [0, 3, 5, 2][i] * k
        sy = [0.85, 1.12, 1.1, 1.0][i]
    elif a == "attack":
        lean = [0, -2, -3, 5, 4, 1][i] * k
        sy = [1.0, 0.9, 0.85, 1.1, 1.05, 1.0][i]
    elif a == "skill":
        sy = [1.0, 1.1, 1.2, 1.25, 1.1, 1.0][i]
        sx = sy
    elif a == "hit":
        sy, lean = (0.82, -2 * k) if i == 0 else (0.9, -1 * k)
    elif a == "death":
        sy = max(0.25, 1 - i * 0.15)
        sx = 1 + i * 0.08
    sx = sx * (1 / max(0.8, sy) if a != "skill" else 1.0) ** 0.5
    cx = W * 0.45 + lean
    rx, ry = 10 * k * sx, 7.5 * k * sy
    cy = gy - ry - hop
    if kind == "penguin":
        ry = 9 * k * sy
        cy = gy - ry - hop
        P.e("body", 5, (cx, cy), 7 * k * sx, ry, bevel=6 * k)
        P.e("white", 5.5, (cx + 2.5 * k, cy + 1.5 * k), 4.2 * k * sx, ry * 0.75, bevel=3 * k)
        P.poly("orange", 6, [(cx + 5 * k, cy - 4 * k), (cx + 9.5 * k, cy - 3 * k), (cx + 5 * k, cy - 2 * k)], bevel=1)
        P.e("eye", 6.2, (cx + 3.5 * k, cy - 5 * k), 1.0 * k, 1.2 * k)
        P.e("body", 4.5, (cx - 5 * k, cy + 1 * k), 2 * k, 5 * k, rot=20 + lean * 3, tone=-1)
        P.e("orange", 4, (cx - 1 * k, gy - 1 * k), 2.5 * k, 1.2 * k)
        P.e("orange", 4, (cx + 3 * k, gy - 1 * k), 2.5 * k, 1.2 * k)
        return P
    P.e("body", 5, (cx, cy), rx, ry, bevel=ry * 0.9)
    P.e("body", 5.2, (cx - rx * 0.35, cy - ry * 0.45), rx * 0.28, ry * 0.2, tone=2, line=False, cast=False)
    if kind == "void":
        for j in range(4):
            x0 = cx - rx * 0.7 + j * rx * 0.45
            P.c("dark", 4.5, (x0, gy - 2 * k), (x0 - 2 * k + math.sin(i + j) * 2, gy + 0.5), 1.4 * k, 0.6 * k)
    if a == "death" and i >= 3:
        P.e("eye", 6, (cx + rx * 0.3, cy - ry * 0.1), 1.5 * k, 0.5 * k)
        return P
    ey = cy - ry * 0.15
    for dx in (0.15, 0.55):
        P.e("eyew", 6, (cx + rx * dx, ey), 1.6 * k, 2.0 * k * min(1, sy + 0.1))
        P.e("eye", 6.1, (cx + rx * dx + 0.5 * k, ey + 0.3 * k), 1.0 * k, 1.3 * k * min(1, sy + 0.1))
    P.e("eye", 6, (cx + rx * 0.4, cy + ry * 0.35), 1.6 * k, 0.6 * k)
    if vis.get("crown"):
        crown(P, cx - 2 * k, cy - ry - 2 * k, 6 * k)
    return P


def crown(P, x, y, w):
    P.poly("gold", 9, [(x - w, y + 2), (x - w, y - w * 0.4), (x - w * 0.5, y), (x, y - w * 0.6), (x + w * 0.5, y), (x + w, y - w * 0.4),
                       (x + w, y + 2)], bevel=1.2)
    P.e("red", 9.1, (x, y + 0.5), w * 0.18, w * 0.18, bevel=1)


def build_quad(vis, k, st, W, H, gy):
    P = Parts()
    kind = vis.get("kind", "wolf")
    a, i, n = st["anim"], st["i"], st["n"]
    L = {"wolf": 20, "boar": 18, "bunny": 9, "chimera": 22, "drake": 22}.get(kind, 18) * k
    R = {"wolf": 5.2, "boar": 7.0, "bunny": 4.2, "chimera": 6.5, "drake": 5.5}.get(kind, 5.5) * k
    leg = {"wolf": 9.5, "boar": 7.0, "bunny": 4.0, "chimera": 10.0, "drake": 9.0}.get(kind, 9.0) * k
    bob, lunge, head_dy, legs_phase, fold = 0.0, 0.0, 0.0, None, 0.0
    if a == "idle":
        bob = [0, 0.4, 0.8, 0.4][i] * k
    elif a == "run":
        legs_phase = i / n * 2 * math.pi
        bob = (-1.5 if i % 2 else 0) * k
    elif a == "attack":
        lunge = [0, -3, -4, 6, 5, 1][i] * k
        head_dy = [0, -1, -2, 2, 2, 0][i] * k
    elif a == "skill":
        head_dy = [0, -2, -4, -5, -4, -1][i] * k
    elif a == "hit":
        lunge = -2 * k
    elif a == "death":
        fold = min(1.0, i / 3)
    x0 = W * 0.30 + lunge
    x1 = x0 + L
    by = gy - leg - R * 0.6 - bob + fold * (leg * 0.8)
    col_mats = {}
    # legs
    swing = 0.5
    for j, (lx, far) in enumerate([(x0 + R * 0.2, True), (x1 - R * 0.2, True), (x0 + R * 0.6, False), (x1 + R * 0.1, False)]):
        ph = 0.0
        if legs_phase is not None:
            ph = math.sin(legs_phase + (0 if j in (0, 3) else math.pi)) * 30
        ang = math.radians(90 + ph - fold * 70 * (1 if j % 2 else -1))
        ll = leg * (1 - fold * 0.3)
        fx, fy = lx + math.cos(ang) * ll, by + R * 0.4 + math.sin(ang) * ll
        P.c("body" if not far else "dark", 3 if far else 6, (lx, by + R * 0.3), (fx, min(gy - 0.5, fy)), R * 0.42, R * 0.3,
            tone=-1 if far else 0)
        P.e("dark", 3.1 if far else 6.1, (fx + 0.8 * k, min(gy - 0.5, fy)), R * 0.42, R * 0.3)
    # body
    P.c("body", 5, (x0, by), (x1, by - 0.5 * k), R, R * 0.92, bevel=R * 0.85, name="torso")
    P.e("belly", 5.1, ((x0 + x1) / 2, by + R * 0.45), L * 0.42, R * 0.45, line=False)
    # tail
    if kind in ("wolf", "chimera", "drake"):
        tw = math.sin(st["t"] * 2 * math.pi) * 2 * k
        tail_mat = "dark" if kind == "chimera" else "body"
        P.c(tail_mat, 4, (x0 - R * 0.6, by - R * 0.3), (x0 - R * 0.6 - 7 * k, by - R * 0.9 - 3 * k + tw), R * 0.45, R * 0.25)
        if kind == "chimera":
            P.e("dark", 4.1, (x0 - R * 0.6 - 8 * k, by - R * 0.9 - 4 * k + tw), 2 * k, 1.6 * k)
    elif kind == "bunny":
        P.e("white", 4, (x0 - R * 0.7, by - R * 0.4), R * 0.55, R * 0.55)
    # head
    hx, hy = x1 + R * 0.55, by - R * 0.75 + head_dy
    hr = {"boar": 0.95, "bunny": 1.0, "chimera": 1.05}.get(kind, 0.85) * R
    if kind == "chimera":
        P.e("dark", 6.5, (hx - 1 * k, hy), hr * 1.45, hr * 1.4, bevel=hr, stripes=(0, 2.5 * k, 1, -2), name="mane")
    P.e("body", 7, (hx, hy), hr, hr * 0.9, bevel=hr * 0.8, name="head")
    sn = {"wolf": (5.5, 2.6, 2.2), "boar": (5.0, 3.6, 3.0), "bunny": (2.5, 1.8, 1.6), "chimera": (4.5, 3.0, 2.6), "drake": (6.5, 2.5, 2.0)}.get(kind, (5, 3, 2.5))
    sx_ = hx + hr * 0.6 + sn[0] * k * 0.4
    P.e("belly" if kind != "boar" else "body", 7.2, (sx_, hy + hr * 0.25), sn[1] * k, sn[2] * k, name="snout")
    P.e("eye", 7.4, (sx_ + sn[1] * k * 0.8, hy + hr * 0.05), 1.0 * k, 0.9 * k)
    glow = vis.get("glow")
    eye_m = "glow_red" if glow else "eye"
    if a == "death" and i >= 2:
        P.e("eye", 7.5, (hx + hr * 0.3, hy - hr * 0.15), 1.2 * k, 0.4 * k)
    else:
        P.e(eye_m, 7.5, (hx + hr * 0.35, hy - hr * 0.2), 1.0 * k, 1.0 * k)
    if kind == "boar":
        P.c("bone", 7.6, (sx_ + 0.5 * k, hy + hr * 0.6), (sx_ + 2.5 * k, hy - hr * 0.1), 0.8 * k, 0.4 * k)
        P.poly("dark", 5.4, [(x0, by - R * 0.8), (x1 + R * 0.3, by - R * 1.0), (x1, by - R * 0.4), (x0, by - R * 0.3)], bevel=1, stripes=(90, 2 * k, 1, -1))
    # ears
    if kind == "bunny":
        for o, z in ((-1.2, 6.8), (1.2, 7.3)):
            P.e("body", z, (hx - 1 * k + o * k, hy - hr - 4 * k), 1.3 * k, 4.5 * k, rot=-15)
            P.e("pink", z + 0.05, (hx - 1 * k + o * k, hy - hr - 4 * k), 0.6 * k, 3 * k, rot=-15, line=False)
    elif kind != "drake":
        for o, z in ((-2.2, 6.8), (0.6, 7.3)):
            ex = hx + o * k
            P.poly("body" if z > 7 else "dark", z, [(ex - 1.6 * k, hy - hr * 0.6), (ex - 0.4 * k, hy - hr - 4 * k), (ex + 1.6 * k, hy - hr * 0.5)], bevel=1)
    else:
        for o in (-2.5, 0.5):
            P.poly("bone", 7.3, [(hx + o * k, hy - hr * 0.6), (hx + o * k - 3 * k, hy - hr - 4 * k), (hx + o * k + 1.5 * k, hy - hr * 0.7)], bevel=1)
        # bony wings
        fl = math.sin(st["t"] * 2 * math.pi) * 3 * k
        P.poly("dark", 3.5, [(x0 + 4 * k, by - R * 0.8), (x0 - 4 * k, by - R * 2.6 - 6 * k + fl), (x1 - 2 * k, by - R * 0.9)], bevel=1.5)
    if vis.get("rider"):
        rc = vis["rider"]
        P.p.append(Part("root", "ellipse", "rider", 8, {"c": ((x0 + x1) / 2, by - R - 4 * k), "rx": 3 * k, "ry": 4 * k}))
        P.p.append(Part("root", "ellipse", "rider", 8.5, {"c": ((x0 + x1) / 2 + 1 * k, by - R - 10 * k), "rx": 3.4 * k, "ry": 3.2 * k}))
        P.p.append(Part("root", "poly", "rider", 8.4, {"pts": [((x0 + x1) / 2 - 2 * k, by - R - 11 * k), ((x0 + x1) / 2 - 7 * k, by - R - 13 * k),
                                                                ((x0 + x1) / 2 - 1 * k, by - R - 9 * k)]}, bevel=1))
        P.e("eye", 8.6, ((x0 + x1) / 2 + 3 * k, by - R - 10.5 * k), 0.7 * k, 0.8 * k)
        P.c("metal", 8.7, ((x0 + x1) / 2 + 3 * k, by - R - 5 * k), ((x0 + x1) / 2 + 10 * k, by - R - 12 * k), 0.6 * k)
    if vis.get("crown"):
        crown(P, hx, hy - hr - 1.5 * k, 3.5 * k)
    return P


def build_flyer(vis, k, st, W, H, gy):
    P = Parts()
    kind = vis.get("kind", "bat")
    a, i, n = st["anim"], st["i"], st["n"]
    t = st["t"]
    fl = math.sin(t * 2 * math.pi * (2 if a == "run" else 1))
    hover = 20 * k + math.sin(t * 2 * math.pi) * 1.5 * k
    lunge = 0.0
    if a == "attack":
        lunge = [0, -3, -4, 6, 5, 1][i] * k
        hover -= [0, 0, -2, 4, 3, 0][i] * k
    if a == "hit":
        lunge = -2 * k
    if a == "death":
        hover = max(4 * k, hover - i * 4 * k)
    cx, cy = W * 0.42 + lunge, gy - hover
    if kind == "bat":
        for side, z in ((-1, 3), (1, 6)):
            tip_y = cy - 6 * k * fl * (1 if side > 0 else 0.8)
            P.poly("dark" if side < 0 else "body", z, [(cx, cy - 1 * k), (cx - 2 * k + side * 2 * k, tip_y - 6 * k), (cx - 10 * k, tip_y - 2 * k),
                                                         (cx - 7 * k, cy + 1 * k), (cx - 4 * k, cy + 2 * k)], bevel=1.2, tone=-1 if side < 0 else 0)
        P.e("body", 5, (cx, cy), 4 * k, 4.5 * k, bevel=3 * k)
        for o in (-1.5, 1.2):
            P.poly("body", 5.2, [(cx + o * k - 1 * k, cy - 3 * k), (cx + o * k, cy - 7 * k), (cx + o * k + 1.2 * k, cy - 3 * k)], bevel=1)
        P.e("glow_red", 5.5, (cx + 2 * k, cy - 1 * k), 0.8 * k, 0.8 * k)
        P.c("white", 5.5, (cx + 2.5 * k, cy + 2 * k), (cx + 2.5 * k, cy + 3.2 * k), 0.4 * k)
    elif kind == "ghost":
        wave = [(cx - 6 * k + j * 3 * k, cy + 9 * k + (2 * k if (j + i) % 2 else 0)) for j in range(5)]
        pts = [(cx - 6.5 * k, cy)] + [(cx - 5 * k, cy - 6 * k), (cx, cy - 8.5 * k), (cx + 5 * k, cy - 6 * k), (cx + 6.5 * k, cy)] + list(reversed(wave))
        P.poly("body", 5, pts, bevel=4 * k)
        P.e("eye", 6, (cx + 1 * k, cy - 3 * k), 1.2 * k, 2 * k)
        P.e("eye", 6, (cx + 4 * k, cy - 3 * k), 1.1 * k, 1.8 * k)
        P.e("eye", 6, (cx + 2.5 * k, cy + 1.5 * k), 1.5 * k, 1.0 * k)
        P.e("body", 5.5, (cx + 6 * k, cy + 1 * k + fl * k), 1.6 * k, 2.5 * k, rot=-30)
    elif kind in ("fairy", "wisp"):
        if kind == "fairy":
            for side, z in ((-1, 3), (1, 6)):
                for up in (1, -1):
                    P.e("white", z, (cx - 3 * k, cy - up * 3 * k - fl * 1.5 * k * up), 4 * k, 2 * k * (1 + 0.3 * fl), rot=up * 30, tone=-1 if side < 0 else 0,
                        line=False)
            P.e("body", 5, (cx, cy + 2 * k), 2.5 * k, 3.5 * k)
            P.e("belly", 5.5, (cx + 0.5 * k, cy - 3 * k), 2.8 * k, 2.8 * k)
            P.e("body", 5.6, (cx - 0.5 * k, cy - 5 * k), 3 * k, 2 * k)
            P.e("eye", 5.8, (cx + 2 * k, cy - 3 * k), 0.6 * k, 0.8 * k)
        else:
            P.poly("fire", 4, [(cx - 3 * k, cy - 2 * k), (cx - 12 * k, cy - 2 * k + fl * 2 * k), (cx - 9 * k, cy + 1 * k), (cx - 3 * k, cy + 3 * k)], bevel=2)
            P.e("body", 5, (cx, cy), 5 * k, 5 * k, bevel=4 * k)
            P.e("white", 5.2, (cx - 1 * k, cy - 1.5 * k), 2.5 * k, 2.5 * k, line=False, cast=False)
            P.e("eye", 6, (cx + 2 * k, cy - 0.5 * k), 0.8 * k, 1.3 * k)
            P.e("eye", 6, (cx + 3.8 * k, cy - 0.5 * k), 0.7 * k, 1.2 * k)
    elif kind == "harpy":
        for side, z in ((-1, 3), (1, 7)):
            tip = cy - 8 * k * fl
            P.poly("body" if side > 0 else "dark", z, [(cx - 1 * k, cy - 3 * k), (cx - 8 * k, tip - 8 * k), (cx - 14 * k, tip - 2 * k), (cx - 5 * k, cy + 3 * k)],
                   bevel=1.5, stripes=(45, 2.5 * k, 1, -2), tone=-1 if side < 0 else 0)
        P.e("belly", 5, (cx, cy), 3 * k, 5 * k)
        P.e("belly", 6, (cx + 0.5 * k, cy - 7 * k), 3.2 * k, 3.2 * k)
        P.poly("dark", 6.2, [(cx - 3 * k, cy - 10 * k), (cx - 7 * k, cy - 2 * k), (cx - 1 * k, cy - 6 * k)], bevel=1)
        P.e("eye", 6.4, (cx + 2 * k, cy - 7 * k), 0.7 * k, 0.9 * k)
        for o in (-1, 1.5):
            P.c("orange", 4.5, (cx + o * k, cy + 4 * k), (cx + o * k + 1 * k, cy + 9 * k), 0.6 * k)
    elif kind == "book":
        open_ = 0.5 + 0.5 * fl
        P.poly("page", 5, [(cx - 6 * k, cy - 4 * k), (cx + 6 * k, cy - 4 * k), (cx + 6 * k, cy + 4 * k), (cx - 6 * k, cy + 4 * k)], bevel=1.5,
               stripes=(90, 2 * k, 1, -1))
        P.poly("body", 5.5, [(cx - 6 * k, cy - 4.5 * k), (cx - 6 * k - 4 * k * open_, cy - 7 * k), (cx - 6 * k - 4 * k * open_, cy + 2 * k), (cx - 6 * k, cy + 4.5 * k)], bevel=1)
        P.poly("body", 5.5, [(cx + 6 * k, cy - 4.5 * k), (cx + 6 * k + 4 * k * open_, cy - 7 * k), (cx + 6 * k + 4 * k * open_, cy + 2 * k), (cx + 6 * k, cy + 4.5 * k)], bevel=1)
        P.e("eyew", 6, (cx + 1 * k, cy), 2.5 * k, 2 * k)
        P.e("glow_red", 6.1, (cx + 1.5 * k, cy), 1 * k, 1.2 * k)
    elif kind == "gargoyle":
        for side, z in ((-1, 3), (1, 7)):
            tip = cy - 7 * k * fl
            P.poly("dark" if side < 0 else "body", z, [(cx - 2 * k, cy - 4 * k), (cx - 10 * k, tip - 9 * k), (cx - 15 * k, tip - 1 * k), (cx - 6 * k, cy + 2 * k)],
                   bevel=1.5, tone=-1 if side < 0 else 0)
        P.e("body", 5, (cx, cy), 5 * k, 6 * k, bevel=3 * k)
        P.e("body", 6, (cx + 2 * k, cy - 7 * k), 3.5 * k, 3.2 * k)
        for o in (-1, 1.5):
            P.poly("dark", 6.2, [(cx + o * k, cy - 9 * k), (cx + o * k - 1 * k, cy - 14 * k), (cx + o * k + 1.5 * k, cy - 9.5 * k)], bevel=1)
        P.e("glow_red", 6.3, (cx + 4 * k, cy - 7.5 * k), 0.7 * k, 0.7 * k)
        P.c("body", 6.5, (cx + 3 * k, cy - 1 * k), (cx + 7 * k, cy + 4 * k), 1.2 * k)
        P.c("body", 4.5, (cx - 2 * k, cy + 5 * k), (cx - 1 * k, cy + 10 * k), 1.4 * k)
    elif kind == "eye":
        for j in range(5):
            ang = math.radians(60 + j * 15)
            ex = cx + math.cos(ang) * 3 * k - 4 * k + j * 2 * k
            P.c("dark", 4, (ex, cy + 6 * k), (ex - 2 * k + math.sin(t * 6 + j) * 2 * k, cy + 15 * k), 1.4 * k, 0.5 * k)
        P.e("eyew", 5, (cx, cy), 8 * k, 8 * k, bevel=6 * k)
        P.e("body", 5.5, (cx + 3 * k, cy), 4 * k, 4.5 * k)
        P.e("eye", 5.6, (cx + 4 * k, cy), 2 * k, 3 * k)
        P.e("eyew", 5.7, (cx + 2 * k, cy - 2 * k), 1 * k, 1 * k, line=False)
    if vis.get("crown"):
        crown(P, cx, cy - 10 * k, 4 * k)
    # shadow on the ground
    P.e("eye", 0.1, (cx, gy - 0.5), 4 * k, 0.8, line=False, cast=False)
    return P


def build_mushroom(vis, k, st, W, H, gy):
    P = Parts()
    a, i = st["anim"], st["i"]
    sy, lean, hop = 1.0, 0.0, 0.0
    if a == "idle":
        sy = [1.0, 0.97, 0.94, 0.97][i]
    elif a == "run":
        hop = [0, 2, 3, 1][i] * k
    elif a == "attack":
        lean = [0, -2, -3, 5, 4, 1][i] * k
    elif a == "skill":
        sy = [1.0, 0.9, 1.1, 1.15, 1.05, 1.0][i]
    elif a == "hit":
        lean = -2 * k
    elif a == "death":
        sy = max(0.35, 1 - i * 0.13)
    cx = W * 0.45
    stem_h = 8 * k * sy
    P.c("belly", 5, (cx, gy - 1 - hop), (cx + lean * 0.3, gy - stem_h - hop), 4 * k, 3.5 * k, bevel=3 * k)
    capy = gy - stem_h - 3 * k - hop
    P.e("body", 6, (cx + lean * 0.6, capy), 9 * k, 5.5 * k * sy, bevel=4 * k)
    for dx, dy, r in ((-4, -2, 1.6), (1, -3.5, 1.3), (4.5, -1, 1.5), (-1, 0.5, 1.1)):
        P.e("belly", 6.3, (cx + lean * 0.6 + dx * k, capy + dy * k * sy), r * k, r * k * 0.8, line=False)
    if not (a == "death" and i >= 3):
        P.e("eye", 6.5, (cx + 1.5 * k + lean * 0.3, gy - stem_h * 0.6 - hop), 0.8 * k, 1.2 * k)
        P.e("eye", 6.5, (cx + 3.2 * k + lean * 0.3, gy - stem_h * 0.6 - hop), 0.7 * k, 1.1 * k)
    for o in (-2, 2):
        P.e("dark", 4.5, (cx + o * k, gy - 0.5), 1.8 * k, 1.0 * k)
    if vis.get("crown"):
        crown(P, cx + lean * 0.6, capy - 5 * k, 4 * k)
    return P


def build_spider(vis, k, st, W, H, gy):
    P = Parts()
    kind = vis.get("kind", "spider")
    a, i, n = st["anim"], st["i"], st["n"]
    ph = st["t"] * 2 * math.pi
    lunge = 0.0
    lift = 0.0
    if a == "attack":
        lunge = [0, -2, -3, 5, 4, 1][i] * k
    elif a == "hit":
        lunge = -2 * k
    elif a == "skill":
        lift = [0, 1, 2, 3, 2, 0][i] * k
    fold = min(1.0, i / 3) if a == "death" else 0.0
    cx = W * 0.42 + lunge
    by = gy - 6 * k + fold * 3 * k
    nlegs = 4 if kind != "beetle" else 3
    for j in range(nlegs):
        for far in (True, False):
            sw = math.sin(ph * (2 if a == "run" else 0.5) + j * 1.3 + (math.pi if far else 0)) * (2.5 if a == "run" else 0.7) * k
            lx = cx - 4 * k + j * 3 * k
            kx = lx + (j - 1.5) * 2.5 * k + sw
            ky = by - 5 * k * (1 - fold) - lift
            fx = lx + (j - 1.5) * 4 * k + sw * 1.3
            lm = "dark" if far else "body"
            P.c(lm, 3 if far else 6, (lx, by), (kx, ky), 0.8 * k, 0.7 * k, tone=-1 if far else 0)
            P.c(lm, 3 if far else 6, (kx, ky), (fx, gy - 0.5), 0.7 * k, 0.5 * k, tone=-1 if far else 0)
    if kind == "spider":
        P.e("body", 5, (cx - 5 * k, by - 2 * k - lift), 6 * k, 5 * k, bevel=4 * k)
        P.e("red", 5.2, (cx - 5.5 * k, by - 3 * k - lift), 2 * k, 1.5 * k, line=False)
        P.e("body", 5.5, (cx + 3 * k, by - 1 * k - lift), 3.8 * k, 3.2 * k)
        for o in (-0.8, 0.8):
            P.e("glow_red", 6, (cx + 5 * k, by - 2 * k + o * k - lift), 0.6 * k, 0.6 * k)
        P.c("bone", 6, (cx + 6 * k, by + 1 * k - lift), (cx + 7 * k, by + 3 * k - lift), 0.5 * k)
    elif kind == "crab":
        P.e("body", 5, (cx, by - 3 * k), 8 * k, 5 * k, bevel=4 * k)
        for o in (0, 1):
            clx = cx + 7 * k + o * 2 * k + lunge * 0.5
            P.c("body", 6 + o, (cx + 4 * k, by - 2 * k), (clx, by - 6 * k), 1.2 * k)
            P.e("body", 6.2 + o, (clx + 1.5 * k, by - 7 * k), 3 * k, 2.2 * k)
        for o in (-1.5, 1.5):
            P.c("dark", 6.5, (cx + 2 * k + o * k, by - 7 * k), (cx + 2 * k + o * k, by - 9 * k), 0.4 * k)
            P.e("eye", 6.6, (cx + 2 * k + o * k, by - 9.5 * k), 0.8 * k, 0.8 * k)
    elif kind == "scorpion":
        P.e("body", 5, (cx - 2 * k, by - 2 * k), 7 * k, 3.5 * k, bevel=3 * k, stripes=(90, 2 * k, 1, -1))
        tail = [(cx - 9 * k, by - 3 * k), (cx - 13 * k, by - 8 * k), (cx - 12 * k, by - 14 * k), (cx - 7 * k, by - 17 * k - lift * 2)]
        for j in range(3):
            P.c("body", 5.5, tail[j], tail[j + 1], (1.8 - j * 0.3) * k)
        P.poly("dark", 5.6, [tail[3], (tail[3][0] + 4 * k, tail[3][1] + 1 * k), (tail[3][0] + 1 * k, tail[3][1] + 3 * k)], bevel=1)
        for o in (0, 1):
            P.c("body", 6 + o, (cx + 4 * k, by - 2 * k), (cx + 9 * k + lunge * 0.4, by - 3 * k - o * k), 1 * k)
            P.e("body", 6.2 + o, (cx + 10.5 * k + lunge * 0.4, by - 3.5 * k - o * k), 2 * k, 1.4 * k)
        P.e("eye", 6.5, (cx + 4 * k, by - 4 * k), 0.6 * k, 0.6 * k)
    else:  # beetle
        P.e("body", 5, (cx - 1 * k, by - 4 * k - lift), 7 * k, 5.5 * k, bevel=4.5 * k)
        P.c("dark", 5.1, (cx - 1 * k, by - 9.5 * k - lift), (cx - 1 * k, by + 1 * k - lift), 0.4 * k, line=False)
        P.e("dark", 5.5, (cx + 6 * k, by - 2 * k - lift), 2.5 * k, 2.2 * k)
        P.c("dark", 5.6, (cx + 7 * k, by - 3 * k - lift), (cx + 10 * k, by - 7 * k - lift), 0.8 * k, 0.4 * k)
        P.e("glow", 5.7, (cx + 7 * k, by - 2.5 * k - lift), 0.5 * k, 0.5 * k)
    if vis.get("crown"):
        crown(P, cx, by - 9 * k, 3.5 * k)
    return P


def build_golem(vis, k, st, W, H, gy):
    P = Parts()
    kind = vis.get("kind", "yeti")
    a, i, n = st["anim"], st["i"], st["n"]
    sway = math.sin(st["t"] * 2 * math.pi) * 1.0 * k
    arm_up = 0.0
    lunge = 0.0
    step = 0.0
    if a == "run":
        step = math.sin(st["t"] * 2 * math.pi) * 3 * k
    elif a == "attack":
        arm_up = [0, 0.6, 1.0, -0.3, -0.5, 0][i]
        lunge = [0, -1, -2, 3, 3, 1][i] * k
    elif a == "skill":
        arm_up = [0, 0.6, 1.0, 1.0, 0.6, 0][i]
    elif a == "hit":
        lunge = -2 * k
    sink = min(1.0, i / 4) * 8 * k if a == "death" else 0.0
    cx = W * 0.42 + lunge
    hip = gy - 7 * k + sink
    body_m = "body"
    # legs
    for o, far in ((-3, True), (3, False)):
        P.c("dark" if far else body_m, 3 if far else 6, (cx + o * k, hip), (cx + o * k + (step if far else -step) * 0.5, gy - 1), 2.6 * k, 2.4 * k,
            tone=-1 if far else 0)
    tor_y = hip - 9 * k
    if kind == "elemental":
        P.poly("body", 5, [(cx - 7 * k, hip), (cx - 9 * k, tor_y - 2 * k), (cx - 5 * k, tor_y - 9 * k + sway), (cx - 1 * k, tor_y - 6 * k),
                           (cx + 2 * k, tor_y - 11 * k - sway), (cx + 5 * k, tor_y - 5 * k), (cx + 8 * k, tor_y - 7 * k + sway), (cx + 8 * k, hip)],
               bevel=3 * k)
        P.e("fire", 5.5, (cx, tor_y + 1 * k), 3.5 * k, 3.5 * k, line=False)
    elif kind == "crystal":
        P.poly("body", 5, [(cx - 8 * k, hip), (cx - 9 * k, tor_y - 3 * k), (cx - 3 * k, tor_y - 9 * k), (cx + 5 * k, tor_y - 8 * k),
                           (cx + 9 * k, tor_y - 1 * k), (cx + 7 * k, hip)], bevel=2 * k, stripes=(60, 4 * k, 1, 2))
        for o in (-5, 1, 6):
            P.poly("belly", 5.3, [(cx + o * k - 1.5 * k, tor_y - 6 * k), (cx + o * k, tor_y - 12 * k), (cx + o * k + 1.5 * k, tor_y - 6 * k)], bevel=1)
    elif kind == "clock":
        P.e("body", 5, (cx, tor_y), 9 * k, 9 * k, bevel=5 * k)
        P.e("gold", 5.3, (cx + 1 * k, tor_y), 5 * k, 5 * k, bevel=2 * k, stripes=(0, 2 * k, 1, -2))
        P.c("dark", 5.4, (cx + 1 * k, tor_y), (cx + 1 * k + math.cos(st["t"] * 6.28) * 3.5 * k, tor_y + math.sin(st["t"] * 6.28) * 3.5 * k), 0.5 * k)
    elif kind == "bone":
        P.e("bone", 5, (cx, tor_y), 8 * k, 9 * k, bevel=4 * k, stripes=(90, 2.5 * k, 1, -3))
    else:  # yeti
        P.e("body", 5, (cx, tor_y), 9 * k, 10 * k, bevel=6 * k, stripes=(80, 2.5 * k, 1, -1))
        P.e("belly", 5.2, (cx + 3 * k, tor_y + 2 * k), 5 * k, 6 * k, line=False)
    # head
    hx, hy = cx + 3 * k, tor_y - 10 * k + sway * 0.5
    head_m = "bone" if kind == "bone" else ("belly" if kind == "yeti" else "body")
    P.e(head_m, 7, (hx, hy), 4.2 * k, 3.8 * k, bevel=3 * k)
    eye_m = "glow" if kind in ("elemental", "clock", "crystal") else ("glow_red" if kind == "bone" else "eye")
    if not (a == "death" and i >= 3):
        P.e(eye_m, 7.5, (hx + 1.5 * k, hy - 0.5 * k), 0.8 * k, 1.0 * k)
        P.e(eye_m, 7.5, (hx + 3.4 * k, hy - 0.5 * k), 0.7 * k, 0.9 * k)
    if kind == "yeti":
        P.c("white", 7.6, (hx + 2 * k, hy + 2.2 * k), (hx + 4 * k, hy + 2.2 * k), 0.6 * k)
        for o in (-2.5, 0.5):
            P.poly("white", 7.7, [(hx + o * k, hy - 3 * k), (hx + o * k - 1 * k, hy - 6.5 * k), (hx + o * k + 1.5 * k, hy - 3.2 * k)], bevel=1)
    # arms
    for o, far, z in ((-7, True, 2.5), (7, False, 8)):
        sx = cx + o * k
        sy = tor_y - 5 * k
        ang = math.radians(100 - arm_up * 150 + (sway * 4 if far else -sway * 4))
        L = 12 * k
        ex = sx + math.cos(ang) * L * (1 if not far else 0.9)
        ey = sy + math.sin(ang) * L
        m = "dark" if far else ("fire" if kind == "elemental" else body_m)
        if kind == "bone":
            m = "bone"
        P.c(m, z, (sx, sy), (ex, ey), 2.8 * k, 3.4 * k, tone=-1 if far else 0)
        P.e(m, z + 0.1, (ex, ey + 1 * k), 3.6 * k, 3.2 * k, tone=-1 if far else 0)
    if vis.get("crown"):
        crown(P, hx, hy - 5 * k, 4 * k)
    return P


def build_ent(vis, k, st, W, H, gy):
    P = Parts()
    kind = vis.get("kind", "ent")
    a, i = st["anim"], st["i"]
    sway = math.sin(st["t"] * 2 * math.pi) * 1.2 * k
    arm_up = 0.0
    lunge = 0.0
    if a == "attack":
        arm_up = [0, 0.6, 1.0, -0.4, -0.5, 0][i]
        lunge = [0, -1, -2, 3, 3, 1][i] * k
    elif a == "skill":
        arm_up = [0, 0.7, 1.0, 1.0, 0.6, 0][i]
    elif a == "hit":
        lunge = -2 * k
    sink = min(1.0, i / 4) * 10 * k if a == "death" else 0.0
    cx = W * 0.42 + lunge
    if kind == "cactus":
        P.c("body", 5, (cx, gy - 1 + sink), (cx, gy - 20 * k + sink), 5.5 * k, 5 * k, bevel=4 * k, stripes=(0, 2.5 * k, 1, -1))
        for o, z in ((-1, 3), (1, 6)):
            bx = cx + o * 5 * k
            ang = -60 - arm_up * 40
            P.c("body", z, (bx, gy - 10 * k + sink), (bx + o * 5 * k, gy - 13 * k + sink + (-arm_up * 4 * k)), 2.4 * k, tone=-1 if o < 0 else 0)
            P.c("body", z, (bx + o * 5 * k, gy - 13 * k + sink - arm_up * 4 * k), (bx + o * 5 * k, gy - 18 * k + sink - arm_up * 6 * k), 2.2 * k, tone=-1 if o < 0 else 0)
        P.e("leaf", 6.5, (cx, gy - 25 * k + sink), 3 * k, 2.2 * k)
        P.e("gold", 6.6, (cx, gy - 25 * k + sink), 1 * k, 1 * k)
        P.e("eye", 6.2, (cx + 2 * k, gy - 15 * k + sink), 0.7 * k, 1.1 * k)
        P.e("eye", 6.2, (cx + 4 * k, gy - 15 * k + sink), 0.6 * k, 1.0 * k)
        return P
    # roots / feet
    for o in (-4, 0, 4):
        P.c("wood", 4, (cx + o * k * 0.5, gy - 4 * k + sink), (cx + o * k * 1.6, gy - 0.5), 1.4 * k, 0.7 * k)
    P.c("wood", 5, (cx, gy - 3 * k + sink), (cx + sway * 0.3, gy - 22 * k + sink), 6 * k, 5 * k, bevel=4 * k, stripes=(0, 2 * k, 1, -2))
    for o, far, z in ((-1, True, 3), (1, False, 7)):
        sx, sy = cx + o * 4 * k, gy - 18 * k + sink
        ang = math.radians(-90 + o * 60 + (-arm_up * 70 * o if not far else 0) + sway * 3)
        ex, ey = sx + math.cos(ang) * 11 * k, sy + math.sin(ang) * 11 * k
        P.c("wood", z, (sx, sy), (ex, ey), 2 * k, 1.2 * k, tone=-1 if far else 0)
        P.e("leaf", z + 0.1, (ex, ey), 3 * k, 2.5 * k, tone=-1 if far else 0)
    for dx, dy, r in ((-5, -27, 6.5), (4, -28, 6), (0, -32, 6), (-2, -24, 5)):
        P.e("leaf", 6 + dy * 0.01, (cx + dx * k + sway, gy + dy * k + sink), r * k, r * 0.8 * k, bevel=4 * k, stripes=(45, 3 * k, 1, -1))
    if not (a == "death" and i >= 3):
        P.e("glow", 6.5, (cx + 1.5 * k, gy - 16 * k + sink), 0.8 * k, 1.2 * k)
        P.e("glow", 6.5, (cx + 3.8 * k, gy - 16 * k + sink), 0.7 * k, 1.1 * k)
    P.e("dark", 6.4, (cx + 2.8 * k, gy - 12 * k + sink), 1.5 * k, 0.8 * k)
    return P


def build_worm(vis, k, st, W, H, gy):
    P = Parts()
    kind = vis.get("kind", "worm")
    a, i = st["anim"], st["i"]
    t = st["t"]
    rise = 1.0
    lunge = 0.0
    if a == "attack":
        lunge = [0, -2, -3, 6, 5, 1][i] * k
    elif a == "skill":
        rise = [1.0, 1.1, 1.2, 1.25, 1.15, 1.0][i]
    elif a == "hit":
        lunge = -2 * k
    elif a == "death":
        rise = max(0.2, 1 - i * 0.16)
    segs = 7
    pts = []
    for j in range(segs + 1):
        f = j / segs
        x = W * 0.3 + f * 16 * k + lunge * f
        y = gy - math.sin(f * math.pi * 0.85) * 26 * k * rise - f * 4 * k * rise + math.sin(t * 6.28 + f * 4) * 1.2 * k
        pts.append((x, y))
    for j in range(segs):
        r0 = (5.5 - j * 0.45) * k if kind != "tentacle" else (4.5 - j * 0.55) * k
        P.c("body", 5 + j * 0.01, pts[j], pts[j + 1], max(0.8 * k, r0), max(0.7 * k, r0 - 0.4 * k), bevel=r0 * 0.8,
            stripes=(90, 2.2 * k, 1, -1) if kind != "tentacle" else None)
        if kind == "tentacle" and j % 2 == 0:
            mx = (pts[j][0] + pts[j + 1][0]) / 2
            my = (pts[j][1] + pts[j + 1][1]) / 2
            P.e("pink", 5.3 + j * 0.01, (mx + 2 * k, my + 1 * k), 0.9 * k, 0.9 * k, line=False)
    hx, hy = pts[-1]
    if kind != "tentacle":
        P.e("dark", 6, (hx + 2 * k, hy + 1 * k), 3.5 * k, 3 * k)
        for o in (-2, 0, 2):
            P.poly("bone", 6.1, [(hx + 2 * k + o * k, hy - 1.5 * k), (hx + 3 * k + o * k, hy + 1 * k), (hx + 1 * k + o * k, hy + 0.5 * k)], bevel=1)
    else:
        P.e("glow_red", 6, (hx + 1 * k, hy), 1.2 * k, 1.2 * k)
    # ground mound
    P.e("dark", 6.5, (W * 0.3, gy - 1), 7 * k, 2 * k, line=False)
    if vis.get("crown"):
        crown(P, hx, hy - 5 * k, 3.5 * k)
    return P


CREATURES = {"blob": build_blob, "quad": build_quad, "flyer": build_flyer, "mushroom": build_mushroom,
             "spider": build_spider, "golem": build_golem, "ent": build_ent, "worm": build_worm}


def render_creature(vis, k, W, H):
    gy = H - 2
    mats = creature_mats(vis.get("color", "#6CC24A"), {"rider": mat(vis.get("rider", "#6FA840"))})
    if vis.get("leaf"):
        mats["leaf"] = mat(vis["leaf"])
    if vis.get("glow"):
        mats["glow"] = mat(vis["glow"], shiny=True, flat=0.6)
    fn = CREATURES[vis["rig"]]
    frames = []
    anims = {}
    start = 0
    for an in ANIMS:
        n = COUNTS[an]
        for st in frame_states(an, n):
            P = fn(vis, k, st, W, H, gy)
            rig = rig_from(P, mats)
            img, _ = render(rig, {}, (W, H), ss=3 if k > 1.4 else 4)
            frames.append(to_image(img))
        anims[an] = {"start": start, "count": n, "fps": FPS[an], "loop": an in ("idle", "run"), "impact": 3 if an in ("attack", "skill") else -1}
        start += n
    root = (int(W * 0.42), gy)
    return frames, anims, root


# =========================================================================== humanoid enemies
def humanoid_variant(vis, rig_kind):
    col = vis.get("color", "#E2A882")
    cloth = vis.get("cloth", "#6A4A3A")
    if rig_kind == "goblin":
        return Variant(cls="goblin", skin=col, hair="#3A2A22", hair_style="bald", eye="#FFE45C", primary=cloth,
                       secondary=_mix(cloth, "#2A1A14", 0.3), leather=cloth, ears="horns" if vis.get("horns") else "goblin", female=False)
    if rig_kind == "skeleton":
        return Variant(cls="skeleton", skin=col, hair=col, hair_style="bald", eye="#FF4A3A", primary=vis.get("cloth", "#5A5A6A"),
                       secondary="#3A3446", metal=col if vis.get("armor") else "#9AA2B0", ears="none", female=False)
    if rig_kind == "zombie":
        return Variant(cls="zombie", skin=col, hair="#3A3A2A", hair_style="bald" if vis.get("wrap") else "short", eye="#E8E85A",
                       primary=cloth, secondary=_mix(cloth, "#1E1A24", 0.3), ears="human", female=False)
    return Variant(cls="bandit", skin=col, hair="#2A2430", hair_style="long" if vis.get("female") else "short", eye="#C9414B" if vis.get("cape") else "#5A4A3A",
                   primary=cloth, secondary=_mix(cloth, "#1E1A24", 0.3), leather="#5A3E2E", accent=vis.get("cape", "#8A1E2E"),
                   ears="horns" if vis.get("horns") else "human", female=bool(vis.get("female")), beard=not vis.get("female") and vis.get("weapon") == "axe")


def build_humanoid_enemy(rig_kind, vis, m):
    v = humanoid_variant(vis, rig_kind)
    b = Builder(m, v)
    s = b.s
    weapon = vis.get("weapon", "sword")
    if rig_kind == "goblin":
        b.body()
        b.pants("leather", knee=1.0)
        b.top("primary", lo=0.05, hi=0.8, z=5.8, name="vest")
        b.belt("leather2", buckle="metal", u=0.3)
        b.head()
        goblin_face_bits(b, vis)
        if vis.get("helm"):
            helm(b)
        if vis.get("big"):
            tail(b)
    elif rig_kind == "skeleton":
        b.body(arms_mat="skin", legs_mat="skin", torso_mat="skin")
        for p in b.parts:
            if p.kind == "capsule" and p.bone.startswith(("uarm", "larm", "thigh", "shin")):
                g = p.geo
                g["r0"] *= 0.6
                g["r1"] = g.get("r1", g["r0"]) * 0.6
            if p.name == "torso":
                p.stripes = (90, 1.6 * m["k"] + 0.6, 1, -3)
        b.head()
        if vis.get("hood"):
            b.hood("dark")
        if vis.get("armor"):
            b.top("metal", lo=0.3, hi=1.0, name="breastplate")
            b.pauldrons("metal")
            b.greaves("metal")
        elif vis.get("cloth"):
            b.skirt("primary", length=0.4, flare=1, z=6.2)
        if vis.get("helm"):
            helm(b)
        if vis.get("shield"):
            b.shield()
    elif rig_kind == "zombie":
        b.body()
        b.top("primary", lo=0.1, hi=0.95, z=5.8, name="rags")
        b.pants("secondary")
        if vis.get("wrap"):
            for p in b.parts:
                if p.material == "skin" and p.name != "face":
                    p.material = "primary"
                    p.stripes = (90 if p.kind != "capsule" else 0, 1.6 * m["k"] + 0.6, 1, -2)
        b.head()
    else:  # bandit / cultist / vampire / anubis
        b.body()
        b.pants("secondary")
        b.boots("leather", height=0.7)
        b.top("primary", lo=0.0, hi=1.0, z=5.8, name="tunic")
        b.belt("leather", buckle="metal", u=0.3)
        if vis.get("cape"):
            b.cape("accent", length=1.0)
        b.head()
        if vis.get("hood"):
            b.hood("primary")
        if vis.get("hat"):
            b.hat_feather("primary")
        if vis.get("jackal"):
            jackal_head(b)
        if vis.get("helm"):
            helm(b)
    if vis.get("crown"):
        hu, hv = m["head_u"], m["head_v"]
        cu, cv = m["head_c"]
        b.add("head", "poly", "trim", 15.5, {"pts": [(cu + hu - 0.5, -hv * 0.8), (cu + hu + 3.5 * m["k"], -hv * 0.9), (cu + hu + 1.5 * m["k"], -hv * 0.3),
                                                      (cu + hu + 4 * m["k"], 0), (cu + hu + 1.5 * m["k"], hv * 0.3), (cu + hu + 3.5 * m["k"], hv * 0.9),
                                                      (cu + hu - 0.5, hv * 0.8)]}, bevel=1, name="crown")
    if weapon and weapon != "none":
        b.weapon(weapon)
    return b, v


def goblin_face_bits(b, vis):
    m = b.m
    hu, hv = m["head_u"], m["head_v"]
    cu, cv = m["head_c"]
    k = m["k"]
    # long nose and big ears
    b.add("head", "ellipse", "skin", 12.7, {"c": (cu - 1.5 * k, hv * 0.95), "rx": 1.6 * k, "ry": 2.6 * k}, bevel=1.2, name="nose")
    if b.v.ears == "goblin":
        b.add("head", "poly", "skin", 12.45, {"pts": [(cu + 0.5 * k, -1.5 * k), (cu + 3 * k, -hv - 6 * k), (cu - 1.5 * k, -2.5 * k)]}, bevel=1.2, name="ear")


def helm(b):
    m = b.m
    hu, hv = m["head_u"], m["head_v"]
    cu, cv = m["head_c"]
    b.add("head", "ellipse", "metal", 14.6, {"c": (cu + hu * 0.45, -0.2), "rx": hu * 0.7, "ry": hv + 0.6}, bevel=2, name="helm")
    b.add("head", "capsule", "metal_dark", 14.7, {"a": (cu + hu * 0.05, -hv - 0.4), "b": (cu + hu * 0.05, hv + 0.4), "r0": 0.7}, bevel=1)


def tail(b):
    m = b.m
    k = m["k"]
    b.add("torso", "capsule", "skin", 1.5, {"a": (0, -2 * k), "b": (-8 * k, -9 * k), "r0": 2.0 * k, "r1": 0.8 * k}, name="tail")


def jackal_head(b):
    m = b.m
    hu, hv = m["head_u"], m["head_v"]
    cu, cv = m["head_c"]
    k = m["k"]
    b.parts = [p for p in b.parts if p.bone != "head" or p.name in ("hood",)]
    b.add("head", "ellipse", "dark", 12, {"c": (cu, cv), "rx": hu * 0.9, "ry": hv * 0.9}, bevel=hv * 0.8, name="jhead")
    b.add("head", "capsule", "dark", 12.2, {"a": (cu - 1 * k, hv * 0.4), "b": (cu - 2.5 * k, hv + 5 * k), "r0": 2.2 * k, "r1": 1.2 * k}, bevel=1.5)
    for o in (-2, 1.5):
        b.add("head", "poly", "dark", 12.3, {"pts": [(cu + hu * 0.5, o * k - 1.5 * k), (cu + hu + 7 * k, o * k), (cu + hu * 0.5, o * k + 1.5 * k)]}, bevel=1)
    b.add("head", "ellipse", "trim", 12.5, {"c": (cu + 0.5 * k, hv * 0.45), "rx": 0.9 * k, "ry": 0.9 * k}, bevel=1)


def enemy_face(v, view, skull=False):
    if skull:
        def face(img, world, ctx, pix_id, parts):
            origin, ang, _ = world["head"]
            face_ids = {i for i, p in enumerate(parts) if p.name in ("face", "jaw")}
            cu, cv = ctx["head_c"]
            r = math.radians(ang)
            ax = (math.cos(r), math.sin(r))
            ay = (-math.sin(r), math.cos(r))
            ex = origin[0] + ax[0] * (cu - 0.6) + ay[0] * (cv + 1.6)
            ey = origin[1] + ax[1] * (cu - 0.6) + ay[1] * (cv + 1.6)
            pal = {"k": (30, 18, 26), "r": (255, 74, 58)}
            stamp(img, round(ex) - 2, round(ey) - 1, ["kk.kk", "kr.rk"] if ctx.get("expr") != "dead" else ["kk.kk", "kk.kk"], pal,
                  lambda y, x: pix_id[y, x] in face_ids)
            stamp(img, round(ex) - 1, round(ey) + 3, ["k.k"], pal, lambda y, x: pix_id[y, x] in face_ids)
        return face
    return make_face(v, view)


def render_humanoid(rig_kind, vis, k, W, H, villains, heroes):
    root = (W * 0.44, H - 2 - 13.6 * k)
    m = scaled_template("battle", k, W=W, H=H, root=root)
    if rig_kind == "hero":
        hid = vis.get("hero")
        src = villains.get(hid) or {}
        if not src:
            for h in heroes:
                if h["id"] == hid:
                    src = h
        hv = dict(src.get("visual", {}))
        v = Variant(cls=src.get("class", "knight"), **hv)
        from chars import build_class
        b = Builder(m, v)
        build_class(b)
        weapon = hv.get("weapon")
        fam = FAMILY.get(weapon or {"knight": "sword", "mage": "staff", "berserker": "axe"}.get(v.cls, "sword"), "blade")
    else:
        b, v = build_humanoid_enemy(rig_kind, vis, m)
        fam = FAMILY.get(vis.get("weapon", "sword"), "blade")
    mats_ = materials(v)
    if vis.get("tint"):
        pass
    skull = rig_kind == "skeleton"
    rig = Rig(skeleton_for(m), b.parts, mats_, enemy_face(v, "side", skull))
    rig.template = m
    A = anim_side(fam)
    if rig_kind == "zombie":
        for p in A["idle"] + A["run"]:
            p["uarm_n"] = 10
            p["larm_n"] = 0
            p["uarm_f"] = 20
            p["larm_f"] = 5
    frames = []
    anims = {}
    start = 0
    for an in ANIMS:
        seq = A[an]
        for p in seq:
            d = world_to_delta(rig.skeleton, {kk: x for kk, x in p.items() if not kk.startswith("_")})
            ro = p.get("_root", (0, 0))
            img, _ = render(rig, d, (W, H), ss=3 if k > 1.4 else 4, root_offset=(ro[0] * k, ro[1] * k),
                            face_ctx=face_ctx(rig, expr=p.get("_expr", "normal")))
            frames.append(to_image(img))
        anims[an] = {"start": start, "count": len(seq), "fps": FPS[an], "loop": an in ("idle", "run"), "impact": 3 if an in ("attack", "skill") else -1}
        start += len(seq)
    return frames, anims, (int(round(root[0])), int(round(H - 2)))


# =========================================================================== entry
HUMANOID = ("goblin", "skeleton", "zombie", "bandit", "hero")


def render_enemy(vis, villains=None, heroes=None):
    villains = villains or {}
    heroes = heroes or []
    k = float(vis.get("scale", 1.0))
    if vis.get("big"):
        k *= 1.15
    if vis["rig"] == "flyer" and vis.get("kind") in ("bat", "fairy", "wisp") and k < 1.4:
        k *= 1.35
    if vis["rig"] == "spider" and k < 1.4:
        k *= 1.2
    W = int(math.ceil(64 * max(1.0, k) / 2) * 2)
    H = int(math.ceil(56 * max(1.0, k) / 2) * 2)
    rk = vis["rig"]
    if rk in HUMANOID:
        kk = k * (0.85 if rk == "goblin" else 1.0)
        frames, anims, root = render_humanoid(rk, vis, kk, W, H, villains, heroes)
    else:
        frames, anims, root = render_creature(vis, k, W, H)
    # mirror so enemies face left
    out = [ImageOps.mirror(f) for f in frames]
    root = (W - 1 - root[0], root[1])
    # visible height for HP bar placement
    bbox = out[0].getbbox()
    height = root[1] - bbox[1] if bbox else 30
    sheet = Image.new("RGBA", (W * len(out), H), (0, 0, 0, 0))
    for i, f in enumerate(out):
        sheet.paste(f, (i * W, 0))
    return sheet, {"frame_w": W, "frame_h": H, "root": [root[0], root[1]], "height": int(height), "anims": anims}
