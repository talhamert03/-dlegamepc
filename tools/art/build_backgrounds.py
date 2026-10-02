#!/usr/bin/env python3
"""Procedural, horizontally tileable parallax backgrounds for every zone theme.

Each theme produces game/assets/backgrounds/<theme>/{sky,far,mid,ground,fore}.png (480x84).
"""
import math
import os
import random

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "game", "assets", "backgrounds")
W, H = 480, 84
GROUND = 66


def hx(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(a, b, t):
    return tuple(int(round(x + (y - x) * t)) for x, y in zip(a, b))


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (c[3] if len(c) > 3 else 255,)


class Canvas:
    def __init__(self):
        self.im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        self.px = self.im.load()

    def put(self, x, y, c):
        x = int(x) % W
        y = int(y)
        if 0 <= y < H:
            if len(c) == 4 and c[3] < 255:
                o = self.px[x, y]
                a = c[3] / 255
                if o[3] == 0:
                    self.px[x, y] = c
                else:
                    self.px[x, y] = tuple(int(o[i] * (1 - a) + c[i] * a) for i in range(3)) + (max(o[3], c[3]),)
            else:
                self.px[x, y] = c if len(c) == 4 else c + (255,)

    def rect(self, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.put(x, y, c)

    def circle(self, cx, cy, r, c, light=None, dark=None):
        for y in range(int(cy - r - 1), int(cy + r + 2)):
            for x in range(int(cx - r - 1), int(cx + r + 2)):
                d = math.hypot(x - cx, y - cy)
                if d <= r:
                    col = c
                    if light and (x - cx) + (y - cy) < -r * 0.5:
                        col = light
                    elif dark and (x - cx) + (y - cy) > r * 0.6:
                        col = dark
                    self.put(x, y, col)

    def tri(self, cx, top, bot, half_w, c, light=None):
        for y in range(int(top), int(bot) + 1):
            t = (y - top) / max(1, bot - top)
            w = half_w * t
            for x in range(int(cx - w), int(cx + w) + 1):
                col = c
                if light and x < cx - w * 0.3 and y > top + 1:
                    col = light
                self.put(x, y, col)


def periodic_noise(x, seeds, octaves=4, base_period=W):
    v = 0.0
    amp = 1.0
    tot = 0.0
    for o in range(octaves):
        per = base_period / (2 ** o)
        ph = seeds[o]
        v += amp * math.sin(2 * math.pi * x / per + ph) * 0.5
        v += amp * math.sin(2 * math.pi * x / (per / 3) + ph * 1.7) * 0.25
        tot += amp * 0.75
        amp *= 0.5
    return v / tot


# ------------------------------------------------------------------ layers
def sky(theme):
    c = Canvas()
    top, bot = hx(theme["sky"][0]), hx(theme["sky"][1])
    bands = 10
    for y in range(H):
        t = y / (GROUND + 6)
        t = min(1.0, t)
        b = t * bands
        bi = int(b)
        frac = b - bi
        c0 = mix(top, bot, bi / bands)
        c1 = mix(top, bot, min(1.0, (bi + 1) / bands))
        for x in range(W):
            # ordered dithering between bands
            dither = ((x + y * 2) % 4) / 4.0
            col = c1 if frac > 0.5 + (dither - 0.5) * 0.5 else c0
            c.put(x, y, col)
    if theme.get("indoor"):
        rng = random.Random(theme["seed"])
        wall = hx(theme["sky"][1])
        for y in range(0, H, 8):
            off = (y // 8) % 2 * 8
            for x in range(off, W, 16):
                c.rect(x, y, x, y + 7, shade(wall, 0.8))
            for x in range(W):
                c.put(x, y, shade(wall, 0.75))
        for i in range(30):
            x, y = rng.randrange(W), rng.randrange(GROUND)
            c.put(x, y, shade(wall, 1.15))
        return c.im
    rng = random.Random(theme["seed"])
    # clouds
    cloud = hx(theme.get("cloud", "#FFFFFF"), 210)
    for i in range(theme.get("clouds", 6)):
        cx, cy = rng.randrange(W), rng.randrange(6, 34)
        for j in range(rng.randint(3, 6)):
            r = rng.randint(3, 7)
            c.circle(cx + j * rng.randint(4, 8), cy + rng.randint(-2, 2), r, cloud, light=shade(cloud, 1.12)[:3] + (225,), dark=shade(cloud, 0.88)[:3] + (200,))
    if theme.get("stars"):
        for i in range(60):
            c.put(rng.randrange(W), rng.randrange(GROUND - 10), hx("#F2E6C9", rng.choice([120, 200, 255])))
    if theme.get("sun"):
        c.circle(380, 18, 8, hx(theme["sun"]), light=hx("#FFFFFF"))
    return c.im


def far(theme):
    c = Canvas()
    kind = theme.get("far", "mountains")
    rng = random.Random(theme["seed"] + 1)
    col = hx(theme["far_col"])
    light = shade(col, 1.15)
    dark = shade(col, 0.85)
    seeds = [rng.uniform(0, 6.28) for _ in range(6)]
    if kind in ("mountains", "hills", "dunes", "snowpeaks"):
        base_h = {"mountains": 30, "hills": 14, "dunes": 12, "snowpeaks": 34}[kind]
        rough = {"mountains": 16, "hills": 6, "dunes": 6, "snowpeaks": 18}[kind]
        for x in range(W):
            n = periodic_noise(x, seeds, 4 if kind in ("mountains", "snowpeaks") else 2)
            if kind in ("mountains", "snowpeaks"):
                n = abs(n) * 1.6 - 0.3
            top = GROUND + 2 - base_h - n * rough
            for y in range(int(top), GROUND + 4):
                cc = col
                if kind == "snowpeaks" and y < top + 4 + (x % 3):
                    cc = hx("#E8F0F8")
                slope = periodic_noise(x + 1, seeds, 3) - periodic_noise(x - 1, seeds, 3)
                if y < top + 2:
                    cc = light if slope < 0 else dark
                c.put(x, y, cc)
        if theme.get("castle"):
            x0 = rng.randrange(W)
            for i, (dx, w, h) in enumerate([(0, 10, 28), (10, 8, 20), (18, 14, 36), (32, 8, 24), (40, 10, 18)]):
                c.rect(x0 + dx, GROUND - h, x0 + dx + w, GROUND, shade(col, 0.7))
                for k in range(0, w, 3):
                    c.rect(x0 + dx + k, GROUND - h - 2, x0 + dx + k + 1, GROUND - h - 1, shade(col, 0.7))
                if i == 2:
                    c.rect(x0 + dx + 6, GROUND - h + 8, x0 + dx + 7, GROUND - h + 10, hx("#FFD98A"))
    elif kind == "cave":
        for x in range(W):
            n = periodic_noise(x, seeds, 3)
            top_h = 10 + n * 8
            for y in range(0, int(top_h)):
                c.put(x, y, dark)
            if x % 23 == 0:
                for y in range(int(top_h), int(top_h) + 6 + x % 5):
                    c.put(x, y, col)
            for y in range(int(GROUND - 8 + n * 4), GROUND + 3):
                c.put(x, y, col)
        for i in range(12):
            x = rng.randrange(W)
            y = rng.randrange(14, GROUND - 14)
            if theme.get("crystals"):
                cc = hx(theme["crystals"])
                c.tri(x, y - 5, y + 2, 2, cc, light=shade(cc, 1.3))
    elif kind == "castle_wall":
        for y in range(18, GROUND + 4):
            for x in range(W):
                cc = col if ((x // 12 + (y // 6) % 2) % 2 == 0) else dark
                if y % 6 == 0 or (x + (y // 6) % 2 * 6) % 12 == 0:
                    cc = shade(col, 0.7)
                c.put(x, y, cc)
        for x in range(0, W, 8):
            c.rect(x, 12, x + 4, 18, col)
    elif kind == "city":
        x = 0
        while x < W:
            w = rng.randint(14, 30)
            h = rng.randint(10, 30)
            c.rect(x, GROUND - h, x + w - 2, GROUND, shade(col, 0.95))
            c.tri(x + w / 2 - 1, GROUND - h - 8, GROUND - h, w / 2, shade(col, 0.8))
            for k in range(2, w - 4, 5):
                if rng.random() < 0.5:
                    c.rect(x + k, GROUND - h + 4, x + k + 1, GROUND - h + 6, hx("#FFD98A"))
            x += w
    return c.im


def tree_pine(c, x, base, h, col, rng, snow=False):
    dark = shade(col, 0.75)
    light = shade(col, 1.2)
    c.rect(x - 1, base - 4, x + 1, base, hx("#5A3E2E"))
    for i in range(3):
        top = base - h + i * h * 0.22
        bot = base - 3 - (2 - i) * h * 0.12
        c.tri(x, top, bot, h * (0.22 + i * 0.07), col, light=light)
        for xx in range(int(x - h * 0.3), int(x + h * 0.3)):
            if rng.random() < 0.3:
                c.put(xx, bot, dark)
        if snow:
            c.tri(x, top, top + 3, 2 + i, hx("#EEF4FA"))


def tree_oak(c, x, base, h, col, rng):
    c.rect(x - 1, base - h * 0.45, x + 1, base, hx("#5A3E2E"))
    c.rect(x - 2, base - 2, x + 2, base, hx("#4A3226"))
    light = shade(col, 1.22)
    dark = shade(col, 0.78)
    for j in range(6):
        cx = x + rng.randint(-int(h * 0.3), int(h * 0.3))
        cy = base - h * 0.55 - rng.randint(0, int(h * 0.35))
        c.circle(cx, cy, h * 0.24 + rng.random() * 2, col, light=light, dark=dark)


def tree_dead(c, x, base, h, col, rng):
    c.rect(x - 1, base - h, x, base, col)
    for i in range(4):
        y = base - h * (0.4 + i * 0.15)
        d = rng.choice([-1, 1])
        for k in range(int(h * 0.25)):
            c.put(x + d * k, y - k * 0.6, col)


def mid(theme):
    c = Canvas()
    kind = theme.get("mid", "oak")
    rng = random.Random(theme["seed"] + 2)
    col = hx(theme["mid_col"])
    n = theme.get("mid_n", 16)
    xs = sorted(rng.randrange(W) for _ in range(n))
    for x in xs:
        base = GROUND + 2 + rng.randint(-2, 1)
        h = rng.randint(*theme.get("mid_h", (18, 30)))
        if kind == "pine":
            tree_pine(c, x, base, h, col, rng)
        elif kind == "snowpine":
            tree_pine(c, x, base, h, col, rng, snow=True)
        elif kind == "oak":
            tree_oak(c, x, base, h, col, rng)
        elif kind == "mixed":
            (tree_pine if rng.random() < 0.5 else tree_oak)(c, x, base, h, col, rng)
        elif kind == "dead":
            tree_dead(c, x, base, h, col, rng)
        elif kind == "grave":
            c.rect(x - 2, base - 7, x + 2, base, col)
            c.rect(x - 1, base - 8, x + 1, base - 8, col)
            c.rect(x - 1, base - 5, x + 1, base - 5, shade(col, 0.7))
            if rng.random() < 0.3:
                tree_dead(c, x + 6, base, h, shade(col, 0.6), rng)
        elif kind == "rock":
            c.circle(x, base - 3, rng.randint(3, 7), col, light=shade(col, 1.2), dark=shade(col, 0.8))
        elif kind == "crystal":
            cc = col
            for j in range(3):
                c.tri(x + j * 3 - 3, base - h * (0.5 + j * 0.15), base, 2 + j, cc, light=shade(cc, 1.35))
        elif kind == "pillar":
            c.rect(x - 3, base - h, x + 3, base, col)
            c.rect(x - 4, base - h - 2, x + 4, base - h, shade(col, 1.15))
            c.rect(x - 4, base - 2, x + 4, base, shade(col, 0.85))
            c.rect(x - 1, base - h, x - 1, base, shade(col, 1.2))
        elif kind == "torch":
            c.rect(x, base - 14, x + 1, base, hx("#5A3E2E"))
            c.circle(x + 0.5, base - 16, 2, hx("#FFB347"), light=hx("#FFF0A0"))
        elif kind == "shelf":
            c.rect(x - 7, base - 26, x + 7, base, shade(col, 0.8))
            for yy in range(base - 24, base, 6):
                for xx in range(x - 6, x + 7, 2):
                    c.rect(xx, yy, xx, yy + 4, rng.choice([hx("#8A3A5A"), hx("#3A5A8A"), hx("#5A8A3A"), hx("#C8962E")]))
        elif kind == "tent":
            c.tri(x, base - 14, base, 10, col, light=shade(col, 1.2))
            c.rect(x - 1, base - 6, x + 1, base, shade(col, 0.5))
            c.rect(x, base - 17, x, base - 14, hx("#5A3E2E"))
        elif kind == "cactus":
            c.rect(x - 1, base - h * 0.6, x + 1, base, col)
            c.rect(x + 2, base - h * 0.45, x + 3, base - h * 0.3, col)
            c.rect(x + 3, base - h * 0.55, x + 3, base - h * 0.4, col)
        elif kind == "palm":
            for k in range(int(h * 0.8)):
                c.put(x + k * 0.15, base - k, hx("#7A5A3A"))
            top = (x + h * 0.12, base - h * 0.8)
            for ang in (-150, -110, -70, -30, -180, 0):
                for k in range(9):
                    r = math.radians(ang)
                    c.put(top[0] + math.cos(r) * k, top[1] + math.sin(r) * k * 0.6 + k * k * 0.04, col)
        elif kind == "house":
            w = rng.randint(14, 20)
            c.rect(x, base - 12, x + w, base, hx("#C9A880"))
            c.tri(x + w / 2, base - 22, base - 12, w / 2 + 3, col, light=shade(col, 1.2))
            c.rect(x + 3, base - 8, x + 5, base - 5, hx("#FFD98A"))
            c.rect(x + w - 6, base - 7, x + w - 4, base, hx("#5A3E2E"))
        elif kind == "bones":
            for j in range(3):
                c.rect(x + j * 2, base - 2 - j, x + j * 2 + 4, base - 2 - j, hx("#E6DDC6"))
            c.circle(x + 3, base - 6, 2, hx("#E6DDC6"))
        elif kind == "ship":
            c.rect(x - 14, base - 6, x + 14, base, shade(col, 0.8))
            c.rect(x, base - 26, x, base - 6, hx("#5A3E2E"))
            c.tri(x + 1, base - 26, base - 10, 8, hx("#E8DCC8"))
        elif kind == "banner":
            c.rect(x, base - 30, x, base, hx("#3A3036"))
            c.rect(x + 1, base - 30, x + 6, base - 20, col)
    return c.im


def ground(theme):
    c = Canvas()
    rng = random.Random(theme["seed"] + 3)
    top = hx(theme["ground"][0])
    base = hx(theme["ground"][1])
    path = hx(theme["ground"][2])
    for x in range(W):
        edge = GROUND + int(round(math.sin(x / 9.0) * 0.8 + math.sin(x / 23.0 + 1.3) * 0.9))
        for y in range(edge, H):
            cc = base
            if y < edge + 2:
                cc = top
            elif y < edge + 3 and (x + y) % 3 == 0:
                cc = shade(top, 0.85)
            if 72 <= y <= 80:
                cc = path
                if y in (72, 80) and x % 2 == 0:
                    cc = shade(path, 0.85)
            c.put(x, y, cc)
        if rng.random() < 0.35:
            c.put(x, edge - 1, top)
            if rng.random() < 0.3:
                c.put(x, edge - 2, shade(top, 1.15))
    # details on the path
    for i in range(50):
        x, y = rng.randrange(W), rng.randrange(73, 80)
        c.put(x, y, shade(path, rng.choice([0.8, 1.15])))
        if rng.random() < 0.3:
            c.put(x + 1, y, shade(path, 0.8))
    flowers = theme.get("flowers")
    if flowers:
        for i in range(26):
            x = rng.randrange(W)
            y = rng.choice([GROUND + 2, GROUND + 3, 82, 83])
            c.put(x, y, hx(rng.choice(flowers)))
    return c.im


def fore(theme):
    kind = theme.get("fore")
    if not kind:
        return None
    c = Canvas()
    rng = random.Random(theme["seed"] + 4)
    col = hx(theme.get("fore_col", theme["mid_col"]))
    for i in range(theme.get("fore_n", 8)):
        x = rng.randrange(W)
        if kind == "bush":
            for j in range(4):
                c.circle(x + j * 4, 84 - rng.randint(1, 4), rng.randint(3, 5), col, light=shade(col, 1.2), dark=shade(col, 0.8))
        elif kind == "grass":
            for j in range(12):
                hh = rng.randint(3, 8)
                for k in range(hh):
                    c.put(x + j + k * 0.2, 84 - k, shade(col, 0.9 + k * 0.04))
        elif kind == "rocks":
            c.circle(x, 85, rng.randint(4, 7), col, light=shade(col, 1.2), dark=shade(col, 0.8))
        elif kind == "stalactite":
            c.tri(x, -1, rng.randint(8, 16), 3, col)
            c.tri(x, -1, rng.randint(8, 16), 3, col)
    return c.im


THEMES = {
    "meadow": dict(seed=1, sky=("#6FB4E8", "#CDEBF5"), clouds=7, far="hills", far_col="#7FA8B8", mid="oak", mid_col="#5A9A3A", mid_n=10,
                   ground=("#6CC24A", "#4E8A34", "#B8945E"), flowers=["#F7E08A", "#FF9AC8", "#FFFFFF"], fore="grass", fore_col="#4E8A34"),
    "forest": dict(seed=2, sky=("#78B8E0", "#D0ECF2"), far="hills", far_col="#5A8A7A", mid="mixed", mid_col="#3E7A3A", mid_n=22, mid_h=(22, 36),
                   ground=("#5AA83E", "#3E7A2E", "#9A7A4E"), flowers=["#F7E08A"], fore="bush", fore_col="#2E6A2E"),
    "forest_fog": dict(seed=3, sky=("#9AB8C8", "#DDE8EC"), clouds=3, far="hills", far_col="#8AA8A8", mid="pine", mid_col="#4A7A5A", mid_n=24,
                       mid_h=(24, 38), ground=("#6AA84E", "#4A7A3A", "#9A8A6A"), fore="bush", fore_col="#3A6A4A"),
    "cave": dict(seed=4, indoor=True, sky=("#1E1A24", "#2E2836"), far="cave", far_col="#3A3446", mid="rock", mid_col="#4A4256", mid_n=12,
                 ground=("#5A5266", "#3A3446", "#4A4256"), fore="stalactite", fore_col="#2A2430"),
    "camp": dict(seed=5, sky=("#E8A06A", "#F6D8A8"), far="hills", far_col="#9A7A6A", mid="tent", mid_col="#8A6A3A", mid_n=9,
                 ground=("#9A8A4E", "#7A6A3E", "#A88A5E"), fore="grass", fore_col="#6A6A3E"),
    "graveyard": dict(seed=6, sky=("#4A5A7A", "#9AA8C0"), clouds=4, cloud="#C0C8D8", far="hills", far_col="#4A5466", mid="grave", mid_col="#7A7A8A",
                      mid_n=18, ground=("#5A7A4E", "#3E5A3A", "#6A6A5E"), fore="grass", fore_col="#3A4A3A"),
    "snow": dict(seed=7, sky=("#8AB8E0", "#E2EEF6"), far="snowpeaks", far_col="#8A9AB8", mid="snowpine", mid_col="#3E6A5A", mid_n=16,
                 ground=("#F0F6FA", "#C8D8E8", "#B8C8D8"), fore="rocks", fore_col="#DDE8F0"),
    "ice": dict(seed=8, sky=("#9AC8F0", "#E6F4FC"), far="snowpeaks", far_col="#9AB8D8", mid="crystal", mid_col="#9FDFFF", mid_n=14,
                ground=("#DDF0FA", "#A8D0E8", "#C8E4F4")),
    "ice_cave": dict(seed=9, indoor=True, sky=("#2A3A5A", "#4A6A8A"), far="cave", far_col="#4A6A8A", crystals="#9FDFFF", mid="crystal",
                     mid_col="#7FC8F0", mid_n=14, ground=("#A8D0E8", "#6A9AB8", "#8AB8D0"), fore="stalactite", fore_col="#3A5A7A"),
    "mine": dict(seed=10, indoor=True, sky=("#2A2226", "#3A3030"), far="cave", far_col="#4A3A36", mid="torch", mid_col="#5A3E2E", mid_n=8,
                 ground=("#6A5A4E", "#4A3A30", "#5A4A3E"), fore="rocks", fore_col="#3A2E2A"),
    "storm": dict(seed=11, sky=("#3A4458", "#7A8498"), clouds=10, cloud="#5A6478", far="mountains", far_col="#4A5466", mid="dead",
                  mid_col="#3A3A46", mid_n=10, ground=("#6A7A6A", "#4A5A4E", "#7A7A6A"), fore="grass", fore_col="#3A4A3E"),
    "harbor": dict(seed=12, sky=("#6AB8E8", "#D8F0FA"), sun="#FFF0A0", far="hills", far_col="#3A8AB8", mid="ship", mid_col="#8A5A3A", mid_n=4,
                   ground=("#E8D8A8", "#C8B07A", "#B89A6A")),
    "desert": dict(seed=13, sky=("#E8B86A", "#FAE8C0"), sun="#FFF4C0", clouds=2, far="dunes", far_col="#D8A86A", mid="cactus", mid_col="#5A9A4A",
                   mid_n=8, ground=("#F0D8A0", "#D8B878", "#C8A060")),
    "oasis": dict(seed=14, sky=("#6AC0E8", "#E0F4FA"), far="dunes", far_col="#D8B07A", mid="palm", mid_col="#4A9A3A", mid_n=10,
                  ground=("#E8D8A0", "#C8B078", "#7AB8D8"), flowers=["#FF9AC8"]),
    "tomb": dict(seed=15, indoor=True, sky=("#3A2E22", "#5A4A36"), far="castle_wall", far_col="#7A6448", mid="pillar", mid_col="#A8906A", mid_n=8,
                 ground=("#A8906A", "#7A6448", "#8A7458")),
    "lava": dict(seed=16, sky=("#3A1E1E", "#A84A2A"), clouds=5, cloud="#5A2A26", far="mountains", far_col="#4A2A26", mid="rock", mid_col="#4A3430",
                 mid_n=12, ground=("#5A3A30", "#3A2420", "#FF7A33")),
    "ruins": dict(seed=17, sky=("#A8B8D8", "#E8E4F0"), far="hills", far_col="#9A9AB8", mid="pillar", mid_col="#B8B0C8", mid_n=10,
                  ground=("#8AA86A", "#6A7A5A", "#A8A098"), fore="grass", fore_col="#5A7A4A"),
    "library": dict(seed=18, indoor=True, sky=("#2E2236", "#4A3A52"), far="castle_wall", far_col="#5A4A62", mid="shelf", mid_col="#8A5A3A",
                    mid_n=12, ground=("#7A5A4A", "#5A3E2E", "#8A3A3A")),
    "temple": dict(seed=19, sky=("#F0B86A", "#FCE8C0"), sun="#FFF4C0", far="dunes", far_col="#D8A060", mid="pillar", mid_col="#E8D0A0", mid_n=10,
                   ground=("#E8D0A0", "#C8A878", "#D8B888")),
    "ash": dict(seed=20, sky=("#4A3A3A", "#8A6A5A"), clouds=6, cloud="#5A4A46", far="mountains", far_col="#3A2E2E", mid="dead", mid_col="#2A2226",
                mid_n=12, ground=("#6A5A56", "#4A3E3A", "#5A4A46")),
    "blood": dict(seed=21, sky=("#3A1A26", "#8A3A4A"), far="hills", far_col="#4A1E2A", mid="dead", mid_col="#2A1A1E", mid_n=10,
                  ground=("#5A3A3E", "#3A2226", "#8A1E2E")),
    "bones": dict(seed=22, sky=("#5A5A6A", "#A8A0A8"), far="hills", far_col="#6A6670", mid="bones", mid_col="#E6DDC6", mid_n=14,
                  ground=("#8A847A", "#6A645A", "#7A746A")),
    "dark_forest": dict(seed=23, sky=("#1E1A2E", "#4A3A5A"), stars=True, clouds=0, far="hills", far_col="#2A2236", mid="pine", mid_col="#2A2A3A",
                        mid_n=24, mid_h=(24, 38), ground=("#3A3A4A", "#2A2436", "#4A3E4A"), fore="bush", fore_col="#1E1A2A"),
    "temple_dark": dict(seed=24, indoor=True, sky=("#1E1424", "#3A2436"), far="castle_wall", far_col="#3A2A3E", mid="torch", mid_col="#5A3E2E",
                        mid_n=10, ground=("#4A3446", "#2E2236", "#6A1E2E")),
    "void": dict(seed=25, sky=("#120E1E", "#3A2456"), stars=True, clouds=0, far="mountains", far_col="#2A1E3E", mid="crystal", mid_col="#8A5AC9",
                 mid_n=12, ground=("#3A2E4A", "#1E1A2A", "#5A3A7A")),
    "castle": dict(seed=26, sky=("#3A3A56", "#8A8AA8"), clouds=5, cloud="#6A6A86", far="castle_wall", far_col="#5A5666", mid="banner",
                   mid_col="#8A1E2E", mid_n=8, ground=("#6A6672", "#4A4652", "#7A7682")),
    "hall": dict(seed=27, indoor=True, sky=("#2A1A22", "#4A2A36"), far="castle_wall", far_col="#5A3A46", mid="pillar", mid_col="#6A4A56",
                 mid_n=8, ground=("#5A3A46", "#3A2430", "#8A1E2E")),
    "throne": dict(seed=28, indoor=True, sky=("#1A1222", "#3A2236"), far="castle_wall", far_col="#3A2A3E", mid="banner", mid_col="#5A1E4A",
                   mid_n=8, ground=("#3A2A3E", "#22182A", "#6A1E3E")),
    "town": dict(seed=29, sky=("#7AB8E8", "#D8EEF8"), clouds=6, far="city", far_col="#9AA8B8", mid="house", mid_col="#B8503A", mid_n=9,
                 ground=("#7AB84E", "#5A8A3E", "#C8B08A"), flowers=["#F7E08A", "#FF9AC8"]),
}


def main():
    for name, theme in THEMES.items():
        d = os.path.join(OUT, name)
        os.makedirs(d, exist_ok=True)
        sky(theme).save(os.path.join(d, "sky.png"))
        far(theme).save(os.path.join(d, "far.png"))
        mid(theme).save(os.path.join(d, "mid.png"))
        ground(theme).save(os.path.join(d, "ground.png"))
        f = fore(theme)
        if f is not None:
            f.save(os.path.join(d, "fore.png"))
        print(name)


if __name__ == "__main__":
    main()
