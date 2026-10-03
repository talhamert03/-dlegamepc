#!/usr/bin/env python3
"""HD round skill icons -> game/assets/hd/skills/<skill id>.png (96 px).

A jewel-like medallion per skill: radial gradient in the class colour (tinted by the skill's element),
an embossed glyph (the HD UI glyph set from build_ui_hd plus skill-only shapes), a glossy highlight and a
rim that tells the type (active: gold, passive: silver-blue, ultimate: crimson with a double ring).
  python3 tools/art/build_skill_icons_hd.py
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_ui_hd as hd  # noqa: E402
from build_icons import SYMBOL_MAP  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "game", "assets", "hd", "skills")
SIZE = 96
SS = 4

CLASS_COL = {"knight": (61, 95, 168), "berserker": (168, 68, 46), "archer": (78, 138, 58), "assassin": (110, 50, 90),
             "mage": (70, 64, 170), "necromancer": (58, 96, 66), "cleric": (190, 150, 60), "bard": (46, 138, 122)}
ELEM_COL = {"fire": (255, 120, 50), "cold": (90, 190, 255), "lightning": (250, 220, 80), "chaos": (170, 90, 240),
            "holy": (255, 220, 120)}


# extra glyphs on the 0..100 grid ----------------------------------------------------------------
def g_swirl(c):
    for i in range(46):
        a = i * 0.32
        r = 6 + i * 0.85
        c.circle(50 + math.cos(a) * r, 50 + math.sin(a) * r, 5.5)


def g_roar(c):
    c.arc(30, 50, 22, 300, 60, 9)
    c.arc(30, 50, 38, 310, 50, 8)
    c.arc(30, 50, 54, 318, 42, 7)
    c.circle(22, 50, 10)


def g_axe(c):
    c.line([(24, 88), (64, 24)], 9)
    c.poly([(54, 8), (92, 24), (82, 58), (64, 40)])


def g_sun(c):
    c.circle(50, 50, 20)
    for k in range(8):
        a = math.radians(k * 45)
        c.line([(50 + math.cos(a) * 28, 50 + math.sin(a) * 28), (50 + math.cos(a) * 42, 50 + math.sin(a) * 42)], 8)


def g_moon(c):
    c.circle(50, 50, 36)
    c.circle(66, 40, 32, 0)


def g_cloud(c):
    c.circle(32, 58, 18)
    c.circle(54, 46, 24)
    c.circle(74, 60, 16)
    c.rect(22, 58, 84, 76, r=8)


def g_snow(c):
    for k in range(3):
        a = math.radians(k * 60)
        c.line([(50 - math.cos(a) * 40, 50 - math.sin(a) * 40), (50 + math.cos(a) * 40, 50 + math.sin(a) * 40)], 8)
    c.circle(50, 50, 9)


def g_orb(c):
    c.ring(50, 50, 38, 9)
    c.circle(50, 50, 20)


def g_fist(c):
    c.rect(22, 30, 78, 76, r=12)
    for x in (30, 44, 58):
        c.line([(x + 4, 30), (x + 4, 46)], 3, 0)
    c.rect(30, 74, 70, 92, r=6)


def g_wing(c):
    c.poly([(10, 80), (50, 12), (92, 22), (70, 44), (88, 50), (62, 66), (74, 74), (40, 86)])


def g_leaf(c):
    c.poly([(16, 84), (22, 40), (50, 14), (86, 12), (82, 50), (56, 78)])
    c.line([(18, 82), (70, 28)], 4, 0)


def g_paw(c):
    c.circle(50, 64, 20)
    for x, y in ((24, 36), (42, 22), (60, 22), (78, 36)):
        c.circle(x, y, 9)


def g_dagger(c):
    c.poly([(80, 10), (88, 18), (46, 60), (38, 52)])
    c.line([(28, 46), (54, 72)], 8)
    c.line([(40, 60), (16, 84)], 9)


def g_crack(c):
    c.line([(10, 80), (90, 80)], 7)
    c.line([(50, 80), (40, 56), (58, 40), (44, 16)], 7)


def g_wind(c):
    for y in (30, 50, 70):
        c.arc(40, y, 28, 180, 360, 7)
        c.line([(12, y), (58, y)], 7)


def g_arrows(c):
    for o in (-18, 0, 18):
        c.line([(18 + o, 86), (78 + o, 26)], 6)
        c.poly([(86 + o, 18), (66 + o, 24), (80 + o, 38)])


GLYPH = {"shield": hd.g_shield, "heart": hd.g_heart, "sword": hd.g_sword, "dagger": g_dagger, "axe": g_axe, "flag": hd.g_flag,
         "sun": g_sun, "spikes": hd.g_spikes, "swirl": g_swirl, "roar": g_roar, "flame": hd.g_flame, "drop": hd.g_drop,
         "claw": hd.g_claw, "crack": g_crack, "bolt": hd.g_bolt, "skull": hd.g_skull, "arrows": g_arrows, "arrow": hd.g_arrow,
         "eye": hd.g_eye, "wind": g_wind, "target": hd.g_target, "leaf": g_leaf, "paw": g_paw, "star": hd.g_star, "moon": g_moon,
         "cloud": g_cloud, "snow": g_snow, "orb": g_orb, "book": hd.g_book, "fist": g_fist, "crown": hd.g_crown, "wing": g_wing,
         "note": hd.g_note, "coin": hd.g_gold}


def lerp(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def medallion(sdef):
    px = SIZE * SS
    img = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    base = CLASS_COL.get(sdef["class"], (90, 90, 110))
    el = ""
    for e in sdef.get("effects", []):
        el = e.get("element", el)
    if el in ELEM_COL:
        base = lerp(base, ELEM_COL[el], 0.45)
    typ = sdef["type"]
    rim = {"active": ((255, 226, 140), (150, 96, 28)), "passive": ((210, 226, 245), (80, 96, 130)),
           "ult": ((255, 130, 110), (120, 20, 30))}.get(typ, ((230, 230, 230), (90, 90, 90)))
    c = px / 2
    R = px * 0.47
    d = ImageDraw.Draw(img)
    # rim
    for i in range(int(R), int(R * 0.80), -1):
        t = (R - i) / (R * 0.2)
        col = lerp(rim[0], rim[1], abs(0.5 - t) * 2)
        d.ellipse([c - i, c - i, c + i, c + i], fill=col + (255,))
    d.ellipse([c - R, c - R, c + R, c + R], outline=(20, 12, 16, 255), width=SS * 2)
    # radial body
    r0 = R * 0.80
    hi = lerp(base, (255, 255, 255), 0.35)
    lo = lerp(base, (0, 0, 0), 0.6)
    for i in range(int(r0), 0, -1):
        t = i / r0
        col = lerp(hi, lo, t ** 1.4)
        oy = (1 - t) * r0 * 0.25
        d.ellipse([c - i, c - i - oy, c + i, c + i - oy], fill=col + (255,))
    d.ellipse([c - r0, c - r0, c + r0, c + r0], outline=(20, 12, 16, 255), width=SS * 2)
    if typ == "ult":
        d.ellipse([c - r0 + SS * 4, c - r0 + SS * 4, c + r0 - SS * 4, c + r0 - SS * 4], outline=rim[0] + (180,), width=SS * 2)
    # glyph
    sym = SYMBOL_MAP.get(sdef.get("icon", ""), "star")
    fn = GLYPH.get(sym, hd.g_star)
    cv = hd.Canvas(int(SIZE * 0.56))
    fn(cv)
    top = (255, 250, 236) if el not in ELEM_COL else lerp((255, 255, 255), ELEM_COL[el], 0.25)
    bot = lerp(top, (200, 160, 90), 0.5) if typ != "passive" else lerp(top, (150, 170, 210), 0.5)
    glyph = hd.finish(cv, top=top, bot=bot, outline=5).resize((int(px * 0.56), int(px * 0.56)), Image.LANCZOS)
    img.alpha_composite(glyph, (int(c - glyph.width / 2), int(c - glyph.height / 2)))
    # gloss
    gl = Image.new("L", (px, px), 0)
    gd = ImageDraw.Draw(gl)
    gd.ellipse([c - r0 * 0.78, c - r0 * 0.92, c + r0 * 0.78, c - r0 * 0.05], fill=70)
    gl = gl.filter(ImageFilter.GaussianBlur(SS * 3))
    white = Image.new("RGBA", (px, px), (255, 255, 255, 0))
    white.putalpha(gl)
    mask = Image.new("L", (px, px), 0)
    ImageDraw.Draw(mask).ellipse([c - r0, c - r0, c + r0, c + r0], fill=255)
    white.putalpha(Image.composite(white.getchannel("A"), Image.new("L", (px, px), 0), mask))
    img = Image.alpha_composite(img, white)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    sk = json.load(open(os.path.join(ROOT, "game", "data", "skills.json"), encoding="utf-8"))["skills"]
    for s in sk:
        medallion(s).save(os.path.join(OUT, s["id"] + ".png"), optimize=True)
    print("hd skill icons:", len(sk))


if __name__ == "__main__":
    main()
