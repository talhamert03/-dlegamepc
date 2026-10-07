#!/usr/bin/env python3
"""HD UI art: anti-aliased icons, orb buttons and slot frames for the premium (non-pixel) UI.

Everything is drawn on a 0..100 design grid, supersampled 4x and downscaled with Lanczos.
Output: game/assets/ui_hd/<name>.png  (icons 128 px, crisp up to ~25 logical px at 5x; orbs 112 px)
"""
import json
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "game", "assets", "ui_hd")
SS = 4

GOLD_TOP = (255, 244, 214)
GOLD_BOT = (222, 170, 82)
OUTLINE = (20, 16, 28)


class Canvas:
    """Draw on a 0..100 grid at size*SS pixels."""

    def __init__(self, size):
        self.size = size
        self.px = size * SS
        self.mask = Image.new("L", (self.px, self.px), 0)
        self.d = ImageDraw.Draw(self.mask)

    def p(self, x, y):
        return (x / 100 * self.px, y / 100 * self.px)

    def s(self, v):
        return v / 100 * self.px

    def poly(self, pts, fill=255):
        self.d.polygon([self.p(*q) for q in pts], fill=fill)

    def circle(self, cx, cy, r, fill=255):
        x, y = self.p(cx, cy)
        rr = self.s(r)
        self.d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=fill)

    def ring(self, cx, cy, r, w, fill=255):
        self.circle(cx, cy, r, fill)
        self.circle(cx, cy, r - w, 0)

    def rect(self, x0, y0, x1, y1, fill=255, r=0):
        a, b = self.p(x0, y0), self.p(x1, y1)
        if r:
            self.d.rounded_rectangle([a, b], radius=self.s(r), fill=fill)
        else:
            self.d.rectangle([a, b], fill=fill)

    def line(self, pts, w, fill=255):
        self.d.line([self.p(*q) for q in pts], fill=fill, width=max(1, int(self.s(w))), joint="curve")
        for q in (pts[0], pts[-1]):
            self.circle(q[0], q[1], w / 2, fill)

    def arc(self, cx, cy, r, a0, a1, w, fill=255):
        x, y = self.p(cx, cy)
        rr = self.s(r)
        self.d.arc([x - rr, y - rr, x + rr, y + rr], a0, a1, fill=fill, width=max(1, int(self.s(w))))


def finish(cv: Canvas, top=GOLD_TOP, bot=GOLD_BOT, outline=4.5):
    """Gradient glyph + dark outline + soft shadow, downsampled."""
    px = cv.px
    m = cv.mask
    grad = Image.new("RGB", (1, px))
    for y in range(px):
        t = y / (px - 1)
        grad.putpixel((0, y), tuple(int(top[i] * (1 - t) + bot[i] * t) for i in range(3)))
    grad = grad.resize((px, px))
    k = int(cv.s(outline)) | 1
    ol = m.filter(ImageFilter.MaxFilter(k))
    shadow = ol.filter(ImageFilter.GaussianBlur(cv.s(2)))
    out = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    sh = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    sh.putalpha(shadow.point(lambda v: int(v * 0.55)))
    out = Image.alpha_composite(out, sh.transform(sh.size, Image.AFFINE, (1, 0, 0, 0, 1, -cv.s(3))))
    ob = Image.new("RGBA", (px, px), OUTLINE + (0,))
    ob.putalpha(ol)
    out = Image.alpha_composite(out, ob)
    fg = grad.convert("RGBA")
    fg.putalpha(m)
    out = Image.alpha_composite(out, fg)
    # top highlight on the glyph
    hl = m.filter(ImageFilter.MinFilter(int(cv.s(3)) | 1))
    hl = ImageChops.subtract(m, hl.transform(hl.size, Image.AFFINE, (1, 0, 0, 0, 1, cv.s(2))))
    hlimg = Image.new("RGBA", (px, px), (255, 255, 255, 0))
    hlimg.putalpha(hl.point(lambda v: int(v * 0.35)))
    out = Image.alpha_composite(out, hlimg)
    return out.resize((cv.size, cv.size), Image.LANCZOS)


# --------------------------------------------------------------------------- icon glyphs
def g_power(c):
    c.arc(50, 54, 30, 300, 240, 11)
    c.line([(50, 14), (50, 50)], 11)


def g_gear(c):
    for k in range(8):
        a = k * math.pi / 4
        x, y = 50 + math.cos(a) * 34, 50 + math.sin(a) * 34
        c.circle(x, y, 9)
    c.circle(50, 50, 32)
    c.circle(50, 50, 12, 0)


def g_quest(c):
    c.rect(22, 12, 78, 88, r=8)
    for y in (32, 48, 64):
        c.rect(32, y - 3, 68, y + 3, 0)


def g_chart(c):
    c.rect(14, 60, 32, 88)
    c.rect(41, 36, 59, 88)
    c.rect(68, 14, 86, 88)


def g_note(c):
    c.circle(30, 76, 14)
    c.circle(74, 66, 14)
    c.rect(36, 18, 44, 76)
    c.rect(80, 10, 88, 66)
    c.poly([(36, 18), (88, 8), (88, 26), (36, 36)])


def g_menu(c):
    for y in (24, 50, 76):
        c.rect(14, y - 7, 86, y + 7, r=6)


def g_sort(c):
    c.poly([(30, 10), (52, 40), (8, 40)])
    c.rect(24, 38, 36, 90)
    c.poly([(70, 90), (92, 60), (48, 60)])
    c.rect(64, 10, 76, 62)


def g_close(c):
    c.line([(20, 20), (80, 80)], 16)
    c.line([(80, 20), (20, 80)], 16)


def g_lock(c):
    c.arc(50, 40, 22, 180, 360, 11)
    c.rect(25, 38, 33, 50)
    c.rect(67, 38, 75, 50)
    c.rect(16, 46, 84, 92, r=8)
    c.circle(50, 64, 7, 0)
    c.rect(47, 64, 53, 80, 0)


def g_star(c):
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        r = 46 if k % 2 == 0 else 20
        pts.append((50 + math.cos(a) * r, 54 + math.sin(a) * r))
    c.poly(pts)


def g_gold(c):
    c.circle(50, 50, 40)
    c.ring(50, 50, 30, 5, 0)
    c.rect(44, 30, 56, 70, 0)


def g_arrow_up(c):
    c.poly([(50, 8), (90, 52), (64, 52), (64, 92), (36, 92), (36, 52), (10, 52)])


def g_arrow_down(c):
    c.poly([(50, 92), (90, 48), (64, 48), (64, 8), (36, 8), (36, 48), (10, 48)])


def g_plus(c):
    c.rect(40, 10, 60, 90, r=5)
    c.rect(10, 40, 90, 60, r=5)


def g_minus(c):
    c.rect(10, 40, 90, 60, r=5)


def g_check(c):
    c.line([(14, 52), (40, 78), (88, 22)], 15)


def g_sword(c):
    c.poly([(84, 8), (92, 16), (42, 66), (34, 58)])
    c.line([(24, 50), (50, 76)], 9)
    c.line([(37, 63), (14, 86)], 10)


def g_shield(c):
    c.poly([(50, 8), (88, 20), (84, 58), (50, 92), (16, 58), (12, 20)])


def g_crown(c):
    c.poly([(10, 78), (10, 26), (30, 48), (50, 16), (70, 48), (90, 26), (90, 78)])
    c.rect(10, 80, 90, 92)


def g_hammer(c):
    c.rect(18, 12, 82, 40, r=5)
    c.rect(43, 38, 57, 92, r=4)


def g_boot(c):
    c.poly([(26, 8), (56, 8), (56, 58), (90, 66), (90, 90), (20, 90), (26, 60)])


def g_bag(c):
    c.circle(50, 62, 34)
    c.poly([(34, 26), (66, 26), (60, 36), (40, 36)])
    c.rect(36, 12, 64, 26, r=6)


def g_flag(c):
    c.rect(14, 8, 24, 92)
    c.poly([(24, 10), (88, 26), (24, 50)])


def g_gem(c):
    c.poly([(26, 14), (74, 14), (92, 38), (50, 92), (8, 38)])


def g_sparkle(c):
    c.poly([(50, 4), (60, 40), (96, 50), (60, 60), (50, 96), (40, 60), (4, 50), (40, 40)])


def g_book(c):
    c.rect(14, 12, 86, 88, r=6)
    c.rect(48, 12, 52, 88, 0)
    c.rect(22, 24, 42, 30, 0)


def g_chest(c):
    c.rect(10, 40, 90, 88, r=6)
    c.rect(10, 18, 90, 40, r=12)
    c.rect(44, 34, 56, 54, 0)


def g_clock(c):
    c.ring(50, 50, 42, 10)
    c.line([(50, 50), (50, 26)], 8)
    c.line([(50, 50), (68, 60)], 8)


def g_eye(c):
    c.poly([(4, 50), (26, 26), (74, 26), (96, 50), (74, 74), (26, 74)])
    c.circle(50, 50, 18, 0)
    c.circle(50, 50, 10)


def g_heart(c):
    c.circle(32, 36, 22)
    c.circle(68, 36, 22)
    c.poly([(12, 44), (88, 44), (50, 90)])


def g_mail(c):
    c.rect(8, 22, 92, 80, r=6)
    c.line([(12, 28), (50, 58), (88, 28)], 7, 0)


def g_map(c):
    c.poly([(8, 20), (34, 10), (66, 22), (92, 12), (92, 82), (66, 92), (34, 80), (8, 90)])
    c.line([(34, 12), (34, 80)], 4, 0)
    c.line([(66, 22), (66, 90)], 4, 0)


def g_people(c):
    c.circle(34, 32, 16)
    c.circle(68, 32, 16)
    c.rect(12, 52, 56, 92, r=14)
    c.rect(46, 52, 90, 92, r=14)


def g_pin(c):
    c.circle(50, 38, 30)
    c.poly([(26, 52), (74, 52), (50, 94)])
    c.circle(50, 38, 11, 0)


def g_potion(c):
    c.rect(40, 8, 60, 34, r=4)
    c.circle(50, 64, 30)
    c.rect(36, 30, 64, 44)


def g_skull(c):
    c.circle(50, 42, 36)
    c.rect(30, 62, 70, 90, r=6)
    c.circle(36, 44, 10, 0)
    c.circle(64, 44, 10, 0)
    c.poly([(50, 56), (56, 68), (44, 68)], 0)


def g_swap(c):
    c.poly([(70, 6), (94, 28), (70, 50)])
    c.rect(10, 22, 74, 34)
    c.poly([(30, 50), (6, 72), (30, 94)])
    c.rect(26, 66, 90, 78)


def g_tower(c):
    c.rect(26, 30, 74, 92)
    for x in (20, 40, 60):
        c.rect(x, 12, x + 20, 32)
    c.rect(26, 22, 74, 32)
    c.rect(42, 64, 58, 92, 0)


def g_town(c):
    c.poly([(50, 8), (92, 46), (8, 46)])
    c.rect(18, 44, 82, 92)
    c.rect(42, 62, 58, 92, 0)


def g_auto(c):
    c.arc(50, 50, 34, 200, 520, 11)
    c.poly([(70, 6), (92, 30), (62, 34)])


def g_dps(c):
    c.poly([(58, 4), (20, 56), (46, 56), (38, 96), (82, 40), (54, 40)])


def g_rune(c):
    # the Mannaz rune: two staves joined by a cross at the top
    c.line([(26, 12), (26, 90)], 12)
    c.line([(74, 12), (74, 90)], 12)
    c.line([(26, 14), (74, 52)], 11)
    c.line([(74, 14), (26, 52)], 11)


def g_cross(c):
    # cross pattée (status)
    c.poly([(40, 8), (60, 8), (56, 40), (88, 36), (88, 64), (56, 60), (60, 92), (40, 92), (44, 60), (12, 64), (12, 36), (44, 40)])


def g_bolt(c):
    c.poly([(60, 6), (20, 56), (46, 56), (36, 94), (80, 40), (54, 40), (66, 6)])


def g_target(c):
    c.ring(50, 50, 42, 10)
    c.ring(50, 50, 24, 9)
    c.circle(50, 50, 8)


def g_claw(c):
    for dx in (-24, 0, 24):
        c.poly([(42 + dx, 8), (54 + dx, 8), (60 + dx, 92), (52 + dx, 92)])


def g_drop(c):
    c.circle(50, 62, 28)
    c.poly([(50, 6), (76, 52), (24, 52)])


def g_flame(c):
    c.circle(50, 66, 28)
    c.poly([(24, 62), (40, 30), (50, 4), (62, 28), (78, 62)])
    c.circle(50, 70, 11, 0)


def g_spikes(c):
    c.poly([(8, 90), (22, 20), (36, 90)])
    c.poly([(32, 90), (50, 8), (68, 90)])
    c.poly([(64, 90), (78, 20), (92, 90)])


def g_arrow(c):
    c.line([(18, 82), (70, 30)], 9)
    c.poly([(54, 14), (90, 10), (86, 46)])
    c.poly([(12, 72), (28, 88), (18, 94), (6, 82)])


ICONS = {k[2:]: v for k, v in globals().items() if k.startswith("g_")}


# --------------------------------------------------------------------------- orb buttons & slots
ORB_COLORS = {"red": ((236, 96, 82), (128, 26, 32)), "green": ((110, 214, 120), (24, 96, 52)),
              "blue": ((112, 170, 255), (28, 58, 150)), "gold": ((255, 214, 120), (156, 98, 26)),
              "purple": ((196, 140, 255), (78, 40, 150))}


def orb(color, state, size=112):
    px = size * SS
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    top, bot = ORB_COLORS[color]
    if state == "hover":
        top = tuple(min(255, int(v * 1.12)) for v in top)
    if state == "pressed":
        top, bot = tuple(int(v * 0.85) for v in top), tuple(int(v * 0.85) for v in bot)
    r = px / 2
    # gold rim
    d.ellipse([0, 0, px - 1, px - 1], fill=(30, 22, 18, 255))
    d.ellipse([px * 0.04, px * 0.04, px * 0.96, px * 0.96], fill=(236, 196, 110, 255))
    d.ellipse([px * 0.09, px * 0.09, px * 0.91, px * 0.91], fill=(92, 62, 30, 255))
    # body radial gradient
    body = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    inner = int(px * 0.12)
    for k in range(60):
        t = k / 59
        col = tuple(int(bot[i] * (1 - t) + top[i] * t) for i in range(3)) + (255,)
        rr = (px / 2 - inner) * (1 - t * 0.85)
        cx, cy = r, r - (px * 0.08) * t
        ImageDraw.Draw(body).ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=col)
    img = Image.alpha_composite(img, body)
    # glossy highlight
    gl = Image.new("L", (px, px), 0)
    ImageDraw.Draw(gl).ellipse([px * 0.24, px * 0.16, px * 0.76, px * 0.48], fill=120)
    gl = gl.filter(ImageFilter.GaussianBlur(px * 0.03))
    white = Image.new("RGBA", (px, px), (255, 255, 255, 0))
    white.putalpha(gl)
    img = Image.alpha_composite(img, white)
    return img.resize((size, size), Image.LANCZOS)


def write(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name + ".png"))


def main():
    for name, fn in ICONS.items():
        cv = Canvas(128)
        fn(cv)
        write(finish(cv), name)
    for col in ORB_COLORS:
        for st in ("normal", "hover", "pressed"):
            write(orb(col, st), "orb_%s_%s" % (col, st))
    # app icon (tray / window) : crossed sword on a gold orb
    base = orb("gold", "normal", 256)
    cv = Canvas(160)
    g_sword(cv)
    glyph = finish(cv, top=(255, 255, 255), bot=(220, 230, 255))
    base.alpha_composite(glyph, (48, 48))
    write(base, "app_icon")
    print("icons:", len(ICONS))


if __name__ == "__main__":
    main()


# --------------------------------------------------------------------------- slots (20 logical px -> 80 px)
def _rr(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


def slot(kind, color=None, size=80):
    px = size * SS
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = int(px * 0.14)
    if kind in ("normal", "hover"):
        _rr(d, [0, 0, px - 1, px - 1], r, fill=(8, 10, 16, 255))
        # inner gradient well
        for k in range(24):
            t = k / 23
            c = (int(14 + 10 * t), int(17 + 11 * t), int(26 + 14 * t), 255)
            inset = int(px * 0.06) + k
            _rr(d, [inset, inset, px - 1 - inset, px - 1 - inset], max(2, r - k), fill=c)
        border = (201, 164, 92, 255) if kind == "hover" else (47, 54, 73, 255)
        _rr(d, [0, 0, px - 1, px - 1], r, outline=border, width=int(px * 0.04))
        _rr(d, [int(px * 0.05)] * 2 + [px - 1 - int(px * 0.05)] * 2, r, outline=(255, 255, 255, 18), width=int(px * 0.02))
    else:
        # rarity / selection overlay: coloured border with soft inner glow, transparent centre
        col = tuple(int(color.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
        glow = Image.new("L", (px, px), 0)
        gd = ImageDraw.Draw(glow)
        _rr(gd, [0, 0, px - 1, px - 1], r, outline=255, width=int(px * 0.16))
        glow = glow.filter(ImageFilter.GaussianBlur(px * 0.05))
        gl = Image.new("RGBA", (px, px), col + (0,))
        gl.putalpha(glow.point(lambda v: int(v * 0.55)))
        img = Image.alpha_composite(img, gl)
        d = ImageDraw.Draw(img)
        _rr(d, [0, 0, px - 1, px - 1], r, outline=col + (255,), width=int(px * 0.045))
        _rr(d, [int(px * 0.045)] * 2 + [px - 1 - int(px * 0.045)] * 2, r, outline=(255, 255, 255, 70), width=int(px * 0.015))
    return img.resize((size, size), Image.LANCZOS)


def build_slots():
    write(slot("normal"), "slot_normal")
    write(slot("hover"), "slot_hover")
    rc = json.load(open(os.path.join(ROOT, "game", "data", "items.json")))["rarity_colors"]
    for r, c in rc.items():
        write(slot("rarity", c), "slot_" + r)
    write(slot("rarity", "#FFD978"), "slot_selected")


if __name__ == "__main__":
    build_slots()
