"""Currency and material icons as one matched set: small painted objects, light from the upper left,
dark outline, soft drop shadow.

    python3 tools/art/build_material_icons.py   ->  game/assets/ui_hd/mat_<id>.png (96 px) and gold.png

gold.png replaces the old monochrome coin glyph, so every UITheme.icon("gold") picks up the coin stack.
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "ui_hd")
SIZE = 96
SS = 4
S = SIZE * SS
OUTLINE = (24, 14, 10, 255)


def grad_fill(mask, top, bot, angle_tl=True):
    """Diagonal light: top-left bright, bottom-right dark."""
    g = Image.new("RGBA", (S, S))
    px = g.load()
    for y in range(0, S, 2):
        for x in range(0, S, 2):
            t = ((x + y) / (2 * S)) if angle_tl else y / S
            c = tuple(int(top[i] * (1 - t) + bot[i] * t) for i in range(3)) + (255,)
            px[x, y] = c
            if x + 1 < S:
                px[x + 1, y] = c
            if y + 1 < S:
                px[x, y + 1] = c
                if x + 1 < S:
                    px[x + 1, y + 1] = c
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(g, (0, 0), mask)
    return out


class Painter:
    def __init__(self):
        self.layers = []          # (mask, top, bot)
        self.union = Image.new("L", (S, S), 0)
        self.extra = []           # overlays drawn after fills (highlights, details)

    def shape(self, draw_fn, top, bot):
        m = Image.new("L", (S, S), 0)
        draw_fn(ImageDraw.Draw(m), lambda v: v * S / 100)
        self.layers.append((m, top, bot))
        self.union = ImageChops.lighter(self.union, m)
        return m

    def detail(self, draw_fn):
        im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        draw_fn(ImageDraw.Draw(im), lambda v: v * S / 100)
        self.extra.append(im)

    def render(self):
        out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ol = self.union.filter(ImageFilter.MaxFilter(int(S * 0.045) | 1))
        sh = ol.filter(ImageFilter.GaussianBlur(S * 0.02)).point(lambda v: int(v * 0.5))
        shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        shadow.putalpha(sh)
        out.alpha_composite(shadow, (int(S * 0.015), int(S * 0.035)))
        o = Image.new("RGBA", (S, S), OUTLINE)
        o.putalpha(ol)
        out.alpha_composite(o)
        for m, top, bot in self.layers:
            out.alpha_composite(grad_fill(m, top, bot))
        for e in self.extra:
            out.alpha_composite(e)
        return out.resize((SIZE, SIZE), Image.LANCZOS)


def ell(d, f, x0, y0, x1, y1, **kw):
    d.ellipse([f(x0), f(y0), f(x1), f(y1)], **kw)


def poly(d, f, pts, **kw):
    d.polygon([(f(x), f(y)) for x, y in pts], **kw)


# --------------------------------------------------------------------------- objects
def coins():
    p = Painter()
    for i, (cx, cy) in enumerate([(40, 70), (60, 64), (48, 50), (50, 34)]):
        p.shape(lambda d, f, cx=cx, cy=cy: (ell(d, f, cx - 26, cy - 9, cx + 26, cy + 13, fill=255)), (150, 90, 20), (110, 60, 10))
        p.shape(lambda d, f, cx=cx, cy=cy: ell(d, f, cx - 26, cy - 13, cx + 26, cy + 9, fill=255), (255, 236, 150), (220, 150, 40))
        p.detail(lambda d, f, cx=cx, cy=cy: ell(d, f, cx - 18, cy - 9, cx + 18, cy + 5, outline=(170, 110, 20, 200), width=int(f(2.2))))
    p.detail(lambda d, f: ell(d, f, 36, 26, 50, 31, fill=(255, 255, 240, 170)))
    return p.render()


def ingot():
    p = Painter()
    p.shape(lambda d, f: poly(d, f, [(10, 62), (28, 40), (90, 40), (90, 62), (72, 84), (10, 84)], fill=255), (110, 112, 120), (60, 62, 70))
    p.shape(lambda d, f: poly(d, f, [(10, 62), (28, 40), (90, 40), (72, 62)], fill=255), (225, 228, 235), (160, 165, 175))
    p.shape(lambda d, f: poly(d, f, [(10, 62), (72, 62), (72, 84), (10, 84)], fill=255), (170, 172, 180), (110, 112, 120))
    # a bent scrap on top
    p.shape(lambda d, f: poly(d, f, [(40, 34), (62, 14), (74, 20), (52, 40)], fill=255), (200, 160, 130), (120, 80, 60))
    p.detail(lambda d, f: d.line([(f(32), f(44)), (f(84), f(44))], fill=(255, 255, 255, 150), width=int(f(2.5))))
    return p.render()


def vial(top, bot, glow):
    p = Painter()
    p.shape(lambda d, f: ell(d, f, 18, 34, 82, 94, fill=255), top, bot)
    p.shape(lambda d, f: d.rectangle([f(40), f(14), f(60), f(42)], fill=255), (210, 230, 240), (140, 160, 180))
    p.shape(lambda d, f: d.rounded_rectangle([f(34), f(6), f(66), f(18)], radius=f(3), fill=255), (190, 130, 80), (110, 70, 40))
    p.detail(lambda d, f: ell(d, f, 28, 44, 46, 62, fill=(255, 255, 255, 150)))
    p.detail(lambda d, f: ell(d, f, 50, 70, 58, 78, fill=glow + (200,)))
    p.detail(lambda d, f: ell(d, f, 36, 74, 42, 80, fill=glow + (160,)))
    return p.render()


def dust():
    p = Painter()
    p.shape(lambda d, f: ell(d, f, 14, 40, 86, 94, fill=255), (120, 90, 170), (60, 40, 100))
    p.shape(lambda d, f: poly(d, f, [(34, 44), (40, 22), (60, 22), (66, 44)], fill=255), (140, 110, 190), (80, 60, 130))
    p.shape(lambda d, f: d.rectangle([f(34), f(28), f(66), f(34)], fill=255), (240, 200, 110), (180, 130, 50))
    p.shape(lambda d, f: ell(d, f, 26, 46, 74, 62, fill=255), (200, 240, 255), (110, 200, 255))
    for (x, y, r) in [(80, 20, 7), (16, 26, 5), (88, 50, 4), (50, 12, 4)]:
        p.detail(lambda d, f, x=x, y=y, r=r: poly(d, f, [(x, y - r), (x + r * 0.3, y - r * 0.3), (x + r, y), (x + r * 0.3, y + r * 0.3),
                                                    (x, y + r), (x - r * 0.3, y + r * 0.3), (x - r, y), (x - r * 0.3, y - r * 0.3)], fill=(220, 245, 255, 255)))
    return p.render()


def shard():
    p = Painter()
    p.shape(lambda d, f: poly(d, f, [(50, 4), (76, 40), (62, 94), (34, 94), (22, 46)], fill=255), (170, 250, 230), (40, 140, 130))
    p.shape(lambda d, f: poly(d, f, [(50, 4), (22, 46), (34, 94), (46, 50)], fill=255), (225, 255, 248), (110, 210, 195))
    p.detail(lambda d, f: poly(d, f, [(46, 16), (32, 44), (38, 46)], fill=(255, 255, 255, 190)))
    p.detail(lambda d, f: ell(d, f, 44, 52, 58, 66, fill=(255, 255, 255, 90)))
    return p.render()


def seal():
    p = Painter()
    # wavy wax disc
    pts = []
    for i in range(36):
        a = i * 2 * math.pi / 36
        r = 42 + (3 if i % 2 else -2)
        pts.append((50 + math.cos(a) * r, 52 + math.sin(a) * r))
    p.shape(lambda d, f: poly(d, f, pts, fill=255), (240, 190, 90), (170, 100, 20))
    p.shape(lambda d, f: ell(d, f, 22, 24, 78, 80, fill=255), (200, 140, 40), (250, 210, 120))
    p.detail(lambda d, f: poly(d, f, [(32, 64), (30, 38), (40, 48), (50, 32), (60, 48), (70, 38), (68, 64)], fill=(255, 240, 190, 255),
                               outline=(110, 60, 10, 255), width=int(f(2))))
    p.detail(lambda d, f: d.rectangle([f(32), f(64), f(68), f(70)], fill=(255, 240, 190, 255), outline=(110, 60, 10, 255), width=int(f(2))))
    return p.render()


def badge():
    p = Painter()
    p.shape(lambda d, f: poly(d, f, [(30, 50), (20, 96), (38, 86), (46, 96), (48, 54)], fill=255), (200, 60, 70), (110, 20, 30))
    p.shape(lambda d, f: poly(d, f, [(52, 54), (54, 96), (62, 86), (80, 96), (70, 50)], fill=255), (200, 60, 70), (110, 20, 30))
    p.shape(lambda d, f: poly(d, f, [(18, 8), (82, 8), (80, 46), (50, 70), (20, 46)], fill=255), (255, 220, 140), (190, 120, 40))
    p.shape(lambda d, f: poly(d, f, [(26, 14), (74, 14), (72, 44), (50, 61), (28, 44)], fill=255), (210, 70, 80), (120, 20, 35))
    p.detail(lambda d, f: poly(d, f, [(50, 22), (55, 34), (67, 34), (57, 42), (61, 54), (50, 46), (39, 54), (43, 42), (33, 34), (45, 34)],
                               fill=(255, 230, 160, 255)))
    return p.render()


MATERIALS = {
    "gold": coins,
    "iron_scrap": ingot,
    "shiny_essence": lambda: vial((255, 240, 130), (210, 150, 20), (255, 255, 200)),
    "epic_essence": lambda: vial((210, 140, 255), (110, 40, 190), (240, 210, 255)),
    "legendary_essence": lambda: vial((255, 180, 90), (210, 90, 10), (255, 230, 170)),
    "mythic_essence": lambda: vial((255, 120, 140), (180, 20, 50), (255, 210, 220)),
    "star_dust": dust,
    "soul_shard": shard,
    "tavern_seal": seal,
    "guild_badge": badge,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for k, fn in MATERIALS.items():
        im = fn()
        im.save(os.path.join(OUT, "mat_%s.png" % k))
        if k == "gold":
            im.save(os.path.join(OUT, "gold.png"))
    print("material icons:", len(MATERIALS))


if __name__ == "__main__":
    main()
