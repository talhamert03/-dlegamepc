#!/usr/bin/env python3
"""Item icons (16x16, every base type x 7 tiers) and skill icons (20x20)."""
import json
import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixelrig import Bone, Part, Rig, Skeleton, mat, render, to_image  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GAME = os.path.join(ROOT, "game")
IT = os.path.join(GAME, "assets/sprites/items")
SK = os.path.join(GAME, "assets/sprites/skills")

# tier palettes: metal, accent (trim), gem, wood/leather, cloth
TIERS = [
    dict(metal="#9A9AA2", trim="#8A6A4A", gem="#8A8A8A", wood="#8A5A3A", cloth="#8E7A5E"),
    dict(metal="#BFC8D2", trim="#A8784A", gem="#6AA8D8", wood="#7A4E30", cloth="#5A6A8A"),
    dict(metal="#D8DEE6", trim="#E9B949", gem="#D84A4A", wood="#6A3E2A", cloth="#8A3A4A"),
    dict(metal="#A8D8F0", trim="#E8E8F0", gem="#4AD8C8", wood="#4A3A5A", cloth="#3A5A9A"),
    dict(metal="#F0D070", trim="#FFF0A0", gem="#B05CFF", wood="#3A2A2A", cloth="#7A2A6A"),
    dict(metal="#FF9A4A", trim="#FFE45C", gem="#FF3B2A", wood="#2A1A1A", cloth="#C9412A"),
    dict(metal="#E8E0FF", trim="#9FDFFF", gem="#FF5AE0", wood="#2A2050", cloth="#3A2A7A"),
]


class P:
    def __init__(self):
        self.p = []

    def c(self, m, z, a, b, r0, r1=None, **kw):
        self.p.append(Part("root", "capsule", m, z, {"a": a, "b": b, "r0": r0, "r1": r1 if r1 is not None else r0}, **kw))

    def e(self, m, z, c, rx, ry, rot=0, **kw):
        self.p.append(Part("root", "ellipse", m, z, {"c": c, "rx": rx, "ry": ry, "rot": rot}, **kw))

    def poly(self, m, z, pts, **kw):
        self.p.append(Part("root", "poly", m, z, {"pts": pts}, **kw))


def mats(t):
    pal = TIERS[t]
    return {"metal": mat(pal["metal"], shiny=True), "trim": mat(pal["trim"], shiny=True), "gem": mat(pal["gem"], shiny=True),
            "wood": mat(pal["wood"]), "cloth": mat(pal["cloth"]), "leather": mat("#7A4E30" if t < 3 else pal["wood"]),
            "string": mat("#EDE6D6", flat=0.7), "white": mat("#F4F1EA"), "glow": mat(pal["gem"], shiny=True, flat=0.4)}


def diag(t, L=1.0):
    """Point along the bottom-left -> top-right diagonal of a 16px icon."""
    return (2.5 + 11 * t * L, 13.5 - 11 * t * L)


def weapon_icon(bt, t):
    p = P()
    deco = t >= 2
    if bt in ("sword", "greatsword", "dagger"):
        L = {"sword": 1.0, "greatsword": 1.05, "dagger": 0.75}[bt]
        w = {"sword": 1.1, "greatsword": 1.6, "dagger": 1.0}[bt]
        p.c("leather", 5, diag(0.0), diag(0.17), 0.9)
        p.c("trim", 6, (diag(0.2)[0] - 2.4, diag(0.2)[1] - 2.4), (diag(0.2)[0] + 2.4, diag(0.2)[1] + 2.4), 0.8)
        p.poly("metal", 5.5, [(diag(0.22)[0] - w * 0.7, diag(0.22)[1] - w * 0.7), diag(L * 1.02), (diag(0.22)[0] + w * 0.7, diag(0.22)[1] + w * 0.7)], bevel=1.0)
        if deco:
            p.e("gem", 6.5, diag(0.2), 0.9, 0.9)
    elif bt == "mace":
        p.c("wood", 5, diag(0.0), diag(0.7), 0.8)
        p.e("metal", 6, diag(0.78), 3.0, 3.0, bevel=2)
        for a in range(0, 360, 90):
            cx, cy = diag(0.78)
            p.c("metal", 5.8, (cx, cy), (cx + math.cos(math.radians(a + 45)) * 4, cy + math.sin(math.radians(a + 45)) * 4), 0.7, 0.3)
        if deco:
            p.e("gem", 6.5, diag(0.78), 1, 1)
    elif bt == "axe":
        p.c("wood", 5, diag(0.0), diag(0.95), 0.8)
        cx, cy = diag(0.78)
        p.poly("metal", 6, [(cx - 1, cy - 1), (cx - 5, cy - 5), (cx - 1.5, cy - 7), (cx + 2, cy - 2)], bevel=1.2)
        p.poly("metal", 6, [(cx + 1, cy + 1), (cx + 5, cy + 4.5), (cx + 6.5, cy + 0.5), (cx + 2, cy - 1)], bevel=1.2)
        if deco:
            p.e("gem", 6.5, (cx, cy), 0.9, 0.9)
    elif bt in ("bow", "crossbow"):
        if bt == "bow":
            pts = [(4 + 9 * math.sin(math.pi * f) * 0.35 + f * 1, 1.5 + f * 13) for f in [i / 8 for i in range(9)]]
            for i in range(8):
                p.c("wood", 5, pts[i], pts[i + 1], 0.9)
            p.c("string", 4.5, (pts[0][0] - 0.5, pts[0][1]), (pts[-1][0] - 0.5, pts[-1][1]), 0.35, line=False)
            p.c("trim", 5.5, pts[3], pts[5], 1.1)
            p.c("white", 6, (2, 8), (13, 8), 0.4)
            p.poly("metal", 6.1, [(13, 6.8), (15.2, 8), (13, 9.2)], bevel=1)
        else:
            p.c("wood", 5, (2.5, 12), (13, 3), 1.1)
            p.c("metal", 5.5, (5, 4.5), (11, 11), 0.9)
            p.c("string", 5.2, (5, 4.5), (6.5, 9), 0.35, line=False)
        if deco:
            p.e("gem", 6.5, (5.5, 8), 0.9, 0.9)
    elif bt in ("staff", "wand", "scythe"):
        L = 0.85 if bt == "staff" else (0.65 if bt == "wand" else 0.9)
        p.c("wood", 5, diag(0.0), diag(L), 0.8 if bt != "wand" else 0.7)
        cx, cy = diag(L + 0.05)
        if bt == "scythe":
            p.poly("metal", 6, [(cx, cy), (cx - 7, cy - 1), (cx - 9, cy + 2.5), (cx - 3, cy + 1)], bevel=1.2)
        else:
            p.e("glow", 6, (cx, cy), 2.3 if bt == "staff" else 1.7, 2.3 if bt == "staff" else 1.7, bevel=1.5)
            p.c("trim", 5.5, diag(L - 0.1), diag(L - 0.02), 1.1)
    elif bt in ("lute", "flute"):
        if bt == "lute":
            p.c("wood", 5, (6, 10), (13, 2.5), 0.9)
            p.e("wood", 6, (5.5, 10.5), 4.2, 3.6, rot=-40, bevel=2.5)
            p.e("leather", 6.5, (5.8, 10.2), 1.2, 1.2)
            p.c("trim", 6.2, (12.5, 3), (14, 1.5), 1.1)
        else:
            p.c("wood", 5, diag(0.05), diag(0.95), 1.1)
            for f in (0.35, 0.5, 0.65):
                p.e("leather", 6, diag(f), 0.5, 0.5, line=False)
            p.c("trim", 5.5, diag(0.85), diag(0.95), 1.3)
    return p


def offhand_icon(bt, t):
    p = P()
    if bt == "shield":
        p.poly("metal", 5, [(2, 2), (14, 2), (14, 8), (8, 15), (2, 8)], bevel=2)
        p.poly("cloth", 5.5, [(3.5, 3.5), (12.5, 3.5), (12.5, 8), (8, 13), (3.5, 8)], bevel=1.5)
        p.c("trim", 6, (8, 4), (8, 12), 0.7)
        p.c("trim", 6, (4.5, 7), (11.5, 7), 0.7)
        if t >= 2:
            p.e("gem", 6.5, (8, 7), 1.2, 1.2)
    elif bt == "quiver":
        p.c("leather", 5, (5, 14), (10, 4), 2.4)
        for o in (-1.5, 0, 1.5):
            p.c("white", 4.5, (10 + o, 4), (12 + o, 1), 0.7)
        p.c("trim", 5.5, (6.5, 11), (8.8, 7), 2.6)
    elif bt == "orb":
        p.e("glow", 5, (8, 7), 5.2, 5.2, bevel=4)
        p.e("white", 5.2, (6.5, 5.3), 1.5, 1.2, line=False, cast=False)
        p.poly("trim", 4.8, [(4, 11), (12, 11), (10, 15), (6, 15)], bevel=1)
    elif bt == "tome":
        p.poly("cloth", 5, [(3, 2), (13, 2), (13, 14), (3, 14)], bevel=1.2)
        p.poly("white", 5.1, [(4, 12.5), (13, 12.5), (13, 14), (4, 14)], bevel=1, line=False)
        p.e("trim", 5.5, (8.5, 7), 2.2, 2.2, bevel=1)
        p.c("trim", 5.4, (3.5, 2.5), (3.5, 13.5), 0.8)
    elif bt == "dagger_off":
        return weapon_icon("dagger", t)
    return p


def armor_icon(slot, weight, t):
    p = P()
    main = "metal" if weight == "heavy" else ("leather" if weight == "medium" else "cloth")
    if slot == "helm":
        if weight == "light":
            p.poly("cloth", 5, [(2, 12), (14, 12), (10, 9), (11, 1), (6, 9)], bevel=1.5)
            p.c("trim", 5.5, (3, 11.5), (13, 11.5), 1)
        elif weight == "medium":
            p.e("leather", 5, (8, 9), 6, 6, bevel=3)
            p.poly("leather", 5.2, [(2.5, 9), (13.5, 9), (12, 14), (4, 14)], bevel=1)
            p.c("trim", 5.5, (3, 9), (13, 9), 0.8)
        else:
            p.e("metal", 5, (8, 8), 6, 6.5, bevel=3)
            p.poly("metal", 5.2, [(2, 8), (14, 8), (13, 14), (3, 14)], bevel=1.5)
            p.c("cloth" if t < 3 else "trim", 4.8, (8, 1), (8, -1), 1.5)
            p.c("leather", 5.5, (4, 9.5), (12, 9.5), 0.6)
        if t >= 2:
            p.e("gem", 6, (8, 7 if weight != "light" else 10.5), 1, 1)
    elif slot == "chest":
        p.poly(main, 5, [(3, 2), (6, 1.5), (8, 4), (10, 1.5), (13, 2), (15, 6), (12.5, 7), (12.5, 15), (3.5, 15), (3.5, 7), (1, 6)], bevel=2)
        if weight == "heavy":
            p.c("trim", 5.5, (8, 4.5), (8, 14), 0.6)
        else:
            p.c("trim", 5.5, (3.8, 11), (12.2, 11), 0.8)
        if t >= 2:
            p.e("gem", 6, (8, 7), 1, 1)
    elif slot == "gloves":
        p.c(main, 5, (5, 14), (6, 6), 2.6)
        for i, o in enumerate((-1.5, 0, 1.5, 3)):
            p.c(main, 5.2, (6 + o, 6.5), (6.5 + o * 1.1, 2.5 + abs(o) * 0.3), 0.8)
        p.c("trim", 5.5, (3, 12), (8, 12.5), 1.1)
    elif slot == "boots":
        p.c(main, 5, (6, 2), (6, 11), 2.6)
        p.c(main, 5.1, (6, 12), (13, 12.5), 2.2, 1.6)
        p.c("trim", 5.5, (3.5, 4), (8.5, 4), 0.9)
    return p


def acc_icon(bt, t):
    p = P()
    if bt == "belt":
        p.c("leather", 5, (1, 8), (15, 8), 2.2)
        p.poly("trim", 5.5, [(6, 5.5), (10, 5.5), (10, 10.5), (6, 10.5)], bevel=1)
        p.poly("leather", 5.6, [(7, 7), (9, 7), (9, 9), (7, 9)], bevel=1)
    elif bt == "cape":
        p.poly("cloth", 5, [(4, 2), (12, 2), (15, 15), (8, 13.5), (1, 15)], bevel=2, stripes=(90, 3, 1, -1))
        p.c("trim", 5.5, (4, 2.5), (12, 2.5), 1.1)
    elif bt == "amulet":
        for i in range(7):
            a0 = math.radians(200 + i * 20)
            a1 = math.radians(200 + (i + 1) * 20)
            p.c("trim", 5, (8 + math.cos(a0) * 6, 4 + math.sin(a0) * -5 + 2), (8 + math.cos(a1) * 6, 4 + math.sin(a1) * -5 + 2), 0.55)
        p.e("trim", 5.5, (8, 11), 3, 3.4, bevel=1.5)
        p.e("gem", 6, (8, 11), 1.8, 2.1, bevel=1.2)
    elif bt == "ring":
        p.e("trim", 5, (8, 9.5), 5, 4.2, bevel=1.6)
        p.e("trim", 5.1, (8, 10), 3.2, 2.6, bevel=1)
        p.parts_hole = True
        p.e("gem", 6, (8, 4.5), 2.4, 2.2, bevel=1.5)
    elif bt == "charm":
        p.poly("gem", 5, [(8, 1.5), (13, 7), (8, 15), (3, 7)], bevel=2)
        p.poly("white", 5.2, [(8, 3), (10, 6), (8, 8), (6, 6)], bevel=1, line=False, cast=False)
    return p


def render_icon(parts: P, t, size=16):
    sk = Skeleton([Bone("root", None, 0, 0)], (0, 0))
    rig = Rig(sk, parts.p, mats(t), None)
    img, _ = render(rig, {}, (size, size), ss=4)
    im = to_image(img).copy()
    if getattr(parts, "parts_hole", False):
        # punch the ring hole
        d = im.load()
        for y in range(size):
            for x in range(size):
                if ((x - 8) / 2.4) ** 2 + ((y - 10) / 1.8) ** 2 < 1:
                    d[x, y] = (0, 0, 0, 0)
    return im


# ------------------------------------------------------------------ skill icons
SYMBOL_MAP = {
    "bash": "shield", "recovery": "heart", "iron_skin": "shield", "challenge": "flag", "sword_mastery": "sword", "last_stand": "shield",
    "oath": "shield", "justice": "sword", "shield_wall": "shield", "steadfast": "shield", "judgement": "sun", "valor": "flag",
    "fortress": "shield", "thorns": "spikes", "banner": "flag",
    "whirl": "swirl", "warcry": "roar", "rage": "flame", "twohand": "axe", "thirst": "drop", "lacerate": "claw", "quake": "crack",
    "leap": "axe", "frenzy": "roar", "thick": "heart", "trance": "flame", "undying": "skull", "thunder": "bolt", "storm_weapon": "bolt",
    "ragnarok": "axe",
    "multishot": "arrows", "earth_strike": "spikes", "keen_eye": "eye", "wind_step": "wind", "pierce": "arrow", "mark": "target",
    "rain": "arrows", "vines": "leaf", "marksman": "target", "quickdraw": "arrow", "storm_arrow": "arrow", "trigger": "arrow",
    "wolf": "paw", "grace": "leaf", "starbreaker": "star",
    "shadow_step": "moon", "poison_blade": "drop", "dual": "dagger", "precision": "target", "sneaky": "eye", "weakspot": "target",
    "dance": "dagger", "smoke": "cloud", "execute": "skull", "cloak": "moon", "eclipse": "moon", "night_hunter": "moon",
    "plague_cloud": "cloud", "venom": "drop", "thousand": "dagger",
    "fireball": "flame", "ice_lance": "snow", "focus": "orb", "attune": "orb", "mana_shield": "shield", "haste": "wind",
    "meteor": "flame", "chain": "bolt", "cycle": "swirl", "wellspring": "orb", "inferno": "flame", "ember": "flame", "zero": "snow",
    "crystal": "snow", "arcane_storm": "star",
    "skeletons": "skull", "drain": "drop", "bone_armor": "shield", "lore": "book", "corpse": "skull", "curse": "eye",
    "bone_spear": "arrow", "doom": "skull", "legion": "skull", "harvest": "drop", "golem": "fist", "sovereign": "crown",
    "black_death": "cloud", "rot": "drop", "army": "skull",
    "heal": "heart", "smite": "sun", "wisdom": "book", "angel": "wing", "blessing": "sun", "purify": "drop", "mass_heal": "heart",
    "light_shield": "shield", "resurrection": "wing", "gate": "sun", "miracle": "star", "holy_mace": "sun", "faith": "sun", "tear": "drop",
    "courage": "note", "discord": "bolt", "rhythm": "note", "joy": "note", "fingers": "note", "luck": "star", "lullaby": "moon",
    "epic": "book", "choir": "note", "golden": "coin", "drums": "note", "march": "flag", "serenity": "leaf", "calm": "wind",
    "legends": "star",
}
CLASS_BG = {"knight": "#3D5FA8", "berserker": "#A8442E", "archer": "#4E8A3A", "assassin": "#5A2E46", "mage": "#3E3A9A",
            "necromancer": "#3A5A3A", "cleric": "#B89A3A", "bard": "#2E8A7A"}


def draw_symbol(d: ImageDraw.ImageDraw, sym, fg, hi):
    c = (10, 10)
    if sym == "shield":
        d.polygon([(5, 4), (15, 4), (15, 10), (10, 16), (5, 10)], fill=fg, outline=hi)
        d.line([(10, 5), (10, 14)], fill=hi)
    elif sym == "heart":
        d.ellipse([4, 5, 10, 11], fill=fg)
        d.ellipse([10, 5, 16, 11], fill=fg)
        d.polygon([(4, 9), (16, 9), (10, 16)], fill=fg)
        d.point([(7, 7)], fill=hi)
    elif sym == "sword":
        d.line([(5, 15), (15, 5)], fill=fg, width=2)
        d.line([(5, 11), (9, 15)], fill=hi, width=1)
        d.point([(15, 5)], fill=hi)
    elif sym == "dagger":
        d.line([(6, 14), (14, 6)], fill=fg, width=2)
        d.line([(4, 10), (8, 14)], fill=hi)
        d.line([(10, 14), (14, 10)], fill=hi)
    elif sym == "axe":
        d.line([(5, 15), (13, 7)], fill=hi, width=1)
        d.polygon([(10, 4), (16, 6), (14, 12), (11, 9)], fill=fg)
    elif sym == "flag":
        d.line([(6, 4), (6, 16)], fill=hi)
        d.polygon([(7, 4), (15, 6), (7, 10)], fill=fg)
    elif sym == "sun":
        d.ellipse([7, 7, 13, 13], fill=fg)
        for a in range(0, 360, 45):
            r = math.radians(a)
            d.line([(10 + math.cos(r) * 5, 10 + math.sin(r) * 5), (10 + math.cos(r) * 7, 10 + math.sin(r) * 7)], fill=hi)
    elif sym == "spikes":
        for x in (5, 9, 13):
            d.polygon([(x - 2, 16), (x, 5 + (x % 3)), (x + 2, 16)], fill=fg)
    elif sym == "swirl":
        for i in range(30):
            a = i * 0.45
            r = 1 + i * 0.22
            d.point([(10 + math.cos(a) * r, 10 + math.sin(a) * r)], fill=fg)
    elif sym == "roar":
        d.arc([4, 4, 16, 16], 300, 60, fill=fg, width=2)
        d.arc([7, 7, 13, 13], 300, 60, fill=hi)
        d.ellipse([3, 8, 6, 12], fill=fg)
    elif sym == "flame":
        d.polygon([(10, 3), (15, 11), (13, 16), (7, 16), (5, 11), (8, 8), (9, 11)], fill=fg)
        d.polygon([(10, 9), (12, 13), (10, 16), (8, 13)], fill=hi)
    elif sym == "drop":
        d.polygon([(10, 3), (14, 10), (6, 10)], fill=fg)
        d.ellipse([6, 8, 14, 16], fill=fg)
        d.point([(8, 11)], fill=hi)
    elif sym == "claw":
        for o in (-3, 0, 3):
            d.line([(7 + o, 15), (11 + o, 5)], fill=fg, width=1)
    elif sym == "crack":
        d.line([(3, 14), (17, 14)], fill=fg)
        d.line([(10, 14), (8, 10), (11, 7), (9, 4)], fill=hi)
    elif sym == "bolt":
        d.polygon([(11, 3), (6, 11), (10, 11), (8, 17), (14, 8), (10, 8), (12, 3)], fill=fg)
    elif sym == "skull":
        d.ellipse([5, 4, 15, 13], fill=fg)
        d.rectangle([7, 12, 13, 15], fill=fg)
        d.rectangle([7, 8, 8, 9], fill=(20, 14, 20))
        d.rectangle([12, 8, 13, 9], fill=(20, 14, 20))
    elif sym in ("arrows", "arrow"):
        n = 3 if sym == "arrows" else 1
        for i in range(n):
            o = (i - (n - 1) / 2) * 4
            d.line([(4 + o, 15), (15 + o, 4)], fill=fg)
            d.polygon([(15 + o, 4), (11 + o, 5), (14 + o, 8)], fill=hi)
    elif sym == "eye":
        d.ellipse([3, 7, 17, 13], fill=fg)
        d.ellipse([8, 7, 12, 13], fill=(20, 14, 20))
        d.point([(9, 8)], fill=hi)
    elif sym == "wind":
        for y in (6, 10, 14):
            d.arc([3, y - 3, 15, y + 3], 180, 360, fill=fg)
    elif sym == "target":
        d.ellipse([4, 4, 16, 16], outline=fg)
        d.ellipse([7, 7, 13, 13], outline=hi)
        d.point([(10, 10)], fill=fg)
    elif sym == "leaf":
        d.ellipse([5, 5, 15, 13], fill=fg)
        d.line([(5, 15), (14, 6)], fill=hi)
    elif sym == "paw":
        d.ellipse([7, 9, 13, 15], fill=fg)
        for x, y in ((5, 6), (9, 4), (13, 6)):
            d.ellipse([x - 1, y - 1, x + 2, y + 2], fill=fg)
    elif sym == "star":
        pts = []
        for i in range(10):
            r = 7 if i % 2 == 0 else 3
            a = math.radians(-90 + i * 36)
            pts.append((10 + math.cos(a) * r, 10 + math.sin(a) * r))
        d.polygon(pts, fill=fg, outline=hi)
    elif sym == "moon":
        d.ellipse([4, 4, 16, 16], fill=fg)
        d.ellipse([7, 3, 18, 14], fill=(0, 0, 0, 0))
    elif sym == "cloud":
        for x, y, r in ((7, 11, 3), (11, 9, 4), (14, 12, 3)):
            d.ellipse([x - r, y - r, x + r, y + r], fill=fg)
    elif sym == "snow":
        for a in range(0, 180, 60):
            r = math.radians(a)
            d.line([(10 - math.cos(r) * 7, 10 - math.sin(r) * 7), (10 + math.cos(r) * 7, 10 + math.sin(r) * 7)], fill=fg)
        d.point([(10, 10)], fill=hi)
    elif sym == "orb":
        d.ellipse([5, 5, 15, 15], fill=fg)
        d.ellipse([7, 7, 10, 10], fill=hi)
    elif sym == "book":
        d.rectangle([5, 4, 15, 16], fill=fg)
        d.line([(6, 4), (6, 16)], fill=hi)
        d.rectangle([9, 8, 12, 10], fill=hi)
    elif sym == "fist":
        d.rectangle([6, 6, 14, 14], fill=fg)
        for x in (7, 9, 11, 13):
            d.line([(x, 6), (x, 9)], fill=hi)
    elif sym == "crown":
        d.polygon([(4, 14), (4, 6), (7, 10), (10, 5), (13, 10), (16, 6), (16, 14)], fill=fg)
    elif sym == "wing":
        d.polygon([(4, 14), (10, 4), (16, 6), (12, 10), (15, 11), (10, 14)], fill=fg)
    elif sym == "note":
        d.ellipse([5, 12, 9, 16], fill=fg)
        d.line([(9, 14), (9, 4)], fill=fg)
        d.line([(9, 4), (14, 6)], fill=fg, width=2)
    elif sym == "coin":
        d.ellipse([5, 5, 15, 15], fill=fg, outline=hi)
        d.line([(10, 7), (10, 13)], fill=hi)


def skill_icon(sdef):
    size = 20
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    bg = CLASS_BG.get(sdef["class"], "#444")
    b = tuple(int(bg[i:i + 2], 16) for i in (1, 3, 5))
    dark = tuple(int(v * 0.55) for v in b)
    light = tuple(min(255, int(v * 1.35)) for v in b)
    typ = sdef["type"]
    # frame
    d.rectangle([0, 0, 19, 19], fill=(20, 14, 16))
    for y in range(1, 19):
        t = y / 19
        col = tuple(int(light[i] * (1 - t) + dark[i] * t) for i in range(3))
        d.line([(1, y), (18, y)], fill=col)
    border = (232, 185, 73) if typ == "ult" else ((200, 200, 210) if typ == "active" else (110, 100, 120))
    d.rectangle([1, 1, 18, 18], outline=border)
    if typ == "passive":
        d.rectangle([2, 2, 17, 17], outline=dark)
    sym = SYMBOL_MAP.get(sdef.get("icon", ""), "star")
    fg = (242, 230, 201)
    hi = (255, 255, 255)
    el = ""
    for e in sdef.get("effects", []):
        el = e.get("element", el)
    fg = {"fire": (255, 154, 74), "cold": (159, 223, 255), "lightning": (255, 228, 92), "chaos": (190, 120, 255),
          "holy": (255, 224, 138)}.get(el, fg)
    sym_im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sym_im)
    draw_symbol(sd, sym, fg + (255,), hi + (255,))
    # outline the symbol for readability
    px = sym_im.load()
    out = im.load()
    for y in range(size):
        for x in range(size):
            if px[x, y][3] == 0:
                near = any(0 <= x + dx < size and 0 <= y + dy < size and px[x + dx, y + dy][3] > 0
                           for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                if near and 2 <= x <= 17 and 2 <= y <= 17:
                    out[x, y] = (20, 14, 16, 255)
    im.alpha_composite(sym_im)
    return im


def main():
    os.makedirs(IT, exist_ok=True)
    os.makedirs(SK, exist_ok=True)
    items = json.load(open(os.path.join(GAME, "data/items.json"), encoding="utf-8"))
    n = 0
    for t in range(7):
        for bt in items["weapons"]:
            render_icon(weapon_icon(bt, t), t).save(os.path.join(IT, f"{bt}_t{t}.png"))
            n += 1
        for bt in items["offhands"]:
            render_icon(offhand_icon(bt, t), t).save(os.path.join(IT, f"{bt}_t{t}.png"))
            n += 1
        for slot in ("helm", "chest", "gloves", "boots"):
            for w in ("heavy", "medium", "light"):
                render_icon(armor_icon(slot, w, t), t).save(os.path.join(IT, f"{slot}_{w}_t{t}.png"))
                n += 1
        for bt in ("belt", "cape", "amulet", "ring", "charm"):
            render_icon(acc_icon(bt, t), t).save(os.path.join(IT, f"{bt}_t{t}.png"))
            n += 1
    sk = json.load(open(os.path.join(GAME, "data/skills.json"), encoding="utf-8"))["skills"]
    for s in sk:
        skill_icon(s).save(os.path.join(SK, f"{s['id']}.png"))
    print(n, "item icons,", len(sk), "skill icons")


if __name__ == "__main__":
    main()
