"""Element and status icons as one family: a coloured enamel disc in a bronze rim with a cream glyph.

    python3 tools/art/build_status_icons.py      ->  game/assets/ui_hd/st_<name>.png (96 px)

Used for zone threat chips, the codex and the status pips over units in the battle strip.
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
import build_ui_hd as ui  # noqa: E402

SIZE = 96
CREAM_TOP = (255, 252, 240)
CREAM_BOT = (236, 214, 170)


def g_snow(c):
    for k in range(3):
        a = k * math.pi / 3
        dx, dy = math.cos(a) * 42, math.sin(a) * 42
        c.line([(50 - dx, 50 - dy), (50 + dx, 50 + dy)], 9)
        for s in (-1, 1):
            bx, by = 50 + s * dx * 0.62, 50 + s * dy * 0.62
            for t in (-1, 1):
                b = a + t * 0.75 + (0 if s > 0 else math.pi)
                c.line([(bx, by), (bx + math.cos(b) * 14, by + math.sin(b) * 14)], 7)


def g_stun(c):
    # three small stars circling
    for k in range(3):
        a = -math.pi / 2 + k * 2 * math.pi / 3
        cx, cy = 50 + math.cos(a) * 26, 54 + math.sin(a) * 20
        pts = []
        for i in range(10):
            r = 17 if i % 2 == 0 else 7
            b = -math.pi / 2 + i * math.pi / 5
            pts.append((cx + math.cos(b) * r, cy + math.sin(b) * r))
        c.poly(pts)


def g_crack_shield(c):
    c.poly([(14, 10), (86, 10), (84, 50), (50, 94), (16, 50)])
    c.poly([(54, 6), (42, 34), (58, 50), (40, 72), (48, 96), (36, 96), (28, 70), (44, 50), (30, 34), (44, 6)], 0)


def g_fire(c):
    # body with three licking tongues, hollow core
    c.circle(50, 68, 26)
    c.poly([(24, 66), (22, 40), (34, 50), (40, 18), (52, 40), (60, 4), (70, 34), (78, 26), (78, 66)])
    c.poly([(50, 86), (38, 70), (46, 58), (50, 44), (58, 60), (62, 72)], 0)


def g_buff(c):
    c.poly([(50, 6), (88, 50), (64, 50), (64, 92), (36, 92), (36, 50), (12, 50)])


def g_weaken(c):
    c.poly([(50, 94), (88, 50), (64, 50), (64, 8), (36, 8), (36, 50), (12, 50)])


# name: (glyph, enamel top, enamel bottom)
ICONS = {
    "fire": (g_fire, (255, 150, 70), (170, 40, 10)),
    "cold": (g_snow, (140, 215, 255), (30, 90, 170)),
    "lightning": (ui.g_bolt, (255, 230, 100), (180, 120, 10)),
    "chaos": (ui.g_skull, (190, 120, 255), (70, 20, 120)),
    "holy": (ui.g_sparkle, (255, 236, 160), (190, 140, 40)),
    "physical": (ui.g_sword, (200, 200, 210), (90, 90, 105)),
    "burn": (g_fire, (255, 130, 60), (150, 30, 10)),
    "chill": (g_snow, (170, 230, 255), (60, 130, 200)),
    "freeze": (ui.g_gem, (210, 245, 255), (90, 170, 220)),
    "shock": (ui.g_bolt, (255, 245, 140), (200, 160, 20)),
    "poison": (ui.g_drop, (170, 235, 100), (40, 110, 30)),
    "bleed": (ui.g_drop, (240, 80, 90), (110, 10, 25)),
    "stun": (g_stun, (255, 220, 110), (170, 110, 20)),
    "vulnerable": (g_crack_shield, (255, 120, 170), (130, 20, 70)),
    "weaken": (g_weaken, (170, 150, 210), (70, 55, 110)),
    "buff": (g_buff, (140, 235, 140), (30, 120, 50)),
}


def disc(top, bot):
    S = SIZE * 4
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    def circ(r, a, b):
        m = Image.new("L", (S, S), 0)
        ImageDraw.Draw(m).ellipse([S / 2 - r, S / 2 - r, S / 2 + r, S / 2 + r], fill=255)
        g = Image.new("RGBA", (1, S))
        for y in range(S):
            t = y / (S - 1)
            g.putpixel((0, y), tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3)) + (255,))
        layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        layer.paste(g.resize((S, S)), (0, 0), m)
        im.alpha_composite(layer)

    circ(S * 0.48, (18, 10, 6), (18, 10, 6))
    circ(S * 0.45, (255, 226, 160), (130, 80, 28))
    circ(S * 0.385, (18, 10, 6), (18, 10, 6))
    circ(S * 0.37, top, bot)
    # glossy cap
    gl = Image.new("L", (S, S), 0)
    ImageDraw.Draw(gl).ellipse([S * 0.22, S * 0.16, S * 0.78, S * 0.5], fill=70)
    gl = gl.filter(ImageFilter.GaussianBlur(S * 0.03))
    w = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    w.putalpha(gl)
    im.alpha_composite(w)
    return im.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    out_dir = ui.OUT
    for name, (fn, top, bot) in ICONS.items():
        im = disc(top, bot)
        cv = ui.Canvas(int(SIZE * 0.6))
        fn(cv)
        g = ui.finish(cv, top=CREAM_TOP, bot=CREAM_BOT, outline=6.0)
        o = (SIZE - g.width) // 2
        im.alpha_composite(g, (o, o + 1))
        im.save(os.path.join(out_dir, "st_%s.png" % name))
    print("status icons:", len(ICONS))


if __name__ == "__main__":
    main()
