"""Hero character definitions for the PixelRig renderer.

Two templates share the same skeleton names and feature builders:
  * "battle"   48x48 side view (3/4, facing right), used on the battle strip
  * "portrait" 96x144 front 3/4 view, used in the Hero panel (stained-glass frame)

A hero = class outfit (features) + variant (hair style/colour, eye colour,
primary/secondary colours, accessories).
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field

from pixelrig import Bone, Part, Rig, Skeleton, mat, stamp, render, to_image

# --------------------------------------------------------------------------- templates
TEMPLATES = {
    "battle": dict(
        W=64, H=56, view="side", root=(28, 40.6), detail=0,
        T=9.0, SW=4.2, WW=3.4, HW=3.9, neck=1.2,
        head_u=7.0, head_v=6.6, head_c=(5.6, 0.6),
        thigh=6.0, thigh_r=(2.6, 2.0), shin=6.2, shin_r=(2.0, 1.6), foot=3.6, foot_r=1.55,
        uarm=5.4, uarm_r=(1.75, 1.5), larm=5.0, larm_r=(1.5, 1.3), hand=1.7,
        weapon_hand="n", scale=0.42,
    ),
    "portrait": dict(
        W=96, H=144, view="front", root=(48, 72), detail=1,
        T=30.0, SW=8.6, WW=5.4, HW=6.6, neck=3.0,
        head_u=9.4, head_v=7.8, head_c=(9.6, 0.6),
        thigh=33.0, thigh_r=(5.3, 3.7), shin=31.0, shin_r=(3.9, 2.9), foot=6.0, foot_r=2.8,
        uarm=21.0, uarm_r=(3.0, 2.5), larm=19.0, larm_r=(2.5, 2.0), hand=2.8,
        weapon_hand="f", scale=1.0,
    ),
}


def skeleton_for(m):
    T = m["T"]
    if m["view"] == "side":
        bones = [
            Bone("pelvis", None, 0, 0),
            Bone("torso", "pelvis", T, -90),
            Bone("head", "torso", 0, 0, (T + m["neck"], 0.4)),
            Bone("thigh_f", "pelvis", m["thigh"], 98, (-0.4, -0.9)),
            Bone("shin_f", "thigh_f", m["shin"], -4, (m["thigh"], 0)),
            Bone("foot_f", "shin_f", m["foot"], -88, (m["shin"], 0)),
            Bone("thigh_n", "pelvis", m["thigh"], 82, (0.6, 0.9)),
            Bone("shin_n", "thigh_n", m["shin"], 6, (m["thigh"], 0)),
            Bone("foot_n", "shin_n", m["foot"], -92, (m["shin"], 0)),
            Bone("uarm_f", "torso", m["uarm"], 186, (T - 1.4, -1.2)),
            Bone("larm_f", "uarm_f", m["larm"], -24, (m["uarm"], 0)),
            Bone("hand_f", "larm_f", 1.5, 0, (m["larm"], 0)),
            Bone("uarm_n", "torso", m["uarm"], 168, (T - 1.4, 0.8)),
            Bone("larm_n", "uarm_n", m["larm"], -32, (m["uarm"], 0)),
            Bone("hand_n", "larm_n", 1.5, 0, (m["larm"], 0)),
            Bone("weapon", "hand_n", 0, -70, (0.8, 0)),
            Bone("offhand", "hand_f", 0, -60, (0.8, 0)),
            Bone("cape", "torso", 12, 180, (T - 0.5, -2.2)),
            Bone("tail", "head", 10, 150, (1.0, -5.6)),
        ]
    else:
        bones = [
            Bone("pelvis", None, 0, 0),
            Bone("torso", "pelvis", T, -90),
            Bone("head", "torso", 0, 0, (T + m["neck"], 1)),
            Bone("thigh_n", "pelvis", m["thigh"], 92, (-5, 0)),
            Bone("shin_n", "thigh_n", m["shin"], 0, (m["thigh"], 0)),
            Bone("foot_n", "shin_n", m["foot"], -80, (m["shin"], 0)),
            Bone("thigh_f", "pelvis", m["thigh"], 86, (5, 0)),
            Bone("shin_f", "thigh_f", m["shin"], 2, (m["thigh"], 0)),
            Bone("foot_f", "shin_f", m["foot"], -95, (m["shin"], 0)),
            Bone("uarm_n", "torso", m["uarm"], 190, (T - 3, -m["SW"] + 0.4)),
            Bone("larm_n", "uarm_n", m["larm"], -18, (m["uarm"], 0)),
            Bone("hand_n", "larm_n", 4, 0, (m["larm"], 0)),
            Bone("uarm_f", "torso", m["uarm"], 166, (T - 3, m["SW"] - 0.4)),
            Bone("larm_f", "uarm_f", m["larm"], -22, (m["uarm"], 0)),
            Bone("hand_f", "larm_f", 4, 0, (m["larm"], 0)),
            Bone("weapon", "hand_f", 0, 46, (2, 0)),
            Bone("offhand", "hand_n", 0, -40, (2, 0)),
            Bone("cape", "torso", 40, 180, (T - 1, -2)),
            Bone("tail", "head", 30, 175, (2, -6)),
        ]
    return Skeleton(bones, m["root"])


# --------------------------------------------------------------------------- variant
@dataclass
class Variant:
    cls: str
    skin: str = "#F0C29E"
    hair: str = "#F2CC5E"
    hair_style: str = "long"        # long | short | ponytail | spiky | bob | twin | bald | braid
    eye: str = "#3E7BC9"
    primary: str = "#E07BAF"
    secondary: str = "#F1E9EE"
    trim: str = "#E9B949"
    leather: str = "#8E5B3E"
    metal: str = "#BFC8D2"
    accent: str = "#3E7BC9"
    female: bool = True
    beard: bool = False
    ears: str = "human"             # human | elf | cat | horns
    extras: tuple = ()              # misc accessory keys
    weapon: str | None = None       # override class weapon


def materials(v: Variant):
    return {
        "skin": mat(v.skin),
        "hair": mat(v.hair, shiny=True),
        "eye": mat(v.eye),
        "primary": mat(v.primary),
        "secondary": mat(v.secondary),
        "trim": mat(v.trim, shiny=True),
        "leather": mat(v.leather),
        "leather2": mat(_mix(v.leather, "#2A1A14", 0.35)),
        "metal": mat(v.metal, shiny=True),
        "metal_dark": mat(_mix(v.metal, "#303848", 0.45), shiny=True),
        "accent": mat(v.accent, shiny=True),
        "wood": mat("#9A6440"),
        "string": mat("#EDE6D6", flat=0.8),
        "feather": mat("#F4F1EA"),
        "fur": mat("#C9B49A"),
        "bone": mat("#E6DDC6"),
        "dark": mat("#3A3046"),
        "glow": mat("#9FF3FF", shiny=True, flat=0.5),
        "glow_green": mat("#8CFF7A", shiny=True, flat=0.5),
        "glow_purple": mat("#C58CFF", shiny=True, flat=0.5),
        "red": mat("#C9414B"),
        "page": mat("#F3E7C8", flat=0.4),
        "horn": mat("#5B4A5E"),
    }


def _mix(a, b, t):
    a = a.lstrip("#")
    b = b.lstrip("#")
    ca = [int(a[i:i + 2], 16) for i in (0, 2, 4)]
    cb = [int(b[i:i + 2], 16) for i in (0, 2, 4)]
    c = [round(x + (y - x) * t) for x, y in zip(ca, cb)]
    return "#%02X%02X%02X" % tuple(c)


# --------------------------------------------------------------------------- builder
class Builder:
    def __init__(self, m, v: Variant):
        self.m = m
        self.v = v
        self.parts: list[Part] = []
        self.side = m["view"] == "side"
        self.s = m["scale"]

    def add(self, bone, kind, material, z, geo, **kw):
        self.parts.append(Part(bone, kind, material, z, geo, **kw))

    # ----------------------------------------------------------------- body
    def body(self, legs_mat="skin", arms_mat="skin", torso_mat="skin"):
        m, s = self.m, self.s
        for side in ("n", "f"):
            far = side == "f" and self.side
            zl = (1.0 if side == "f" else 2.0) if not self.side else (-2.0 if far else 2.0)
            tone = -1 if far else 0
            self.add(f"thigh_{side}", "capsule", legs_mat, zl,
                     {"a": (0, 0), "b": (m["thigh"], 0), "r0": m["thigh_r"][0], "r1": m["thigh_r"][1]},
                     tone=tone, name=f"thigh_{side}")
            self.add(f"shin_{side}", "capsule", legs_mat, zl + 0.1,
                     {"a": (0, 0), "b": (m["shin"], 0), "r0": m["shin_r"][0], "r1": m["shin_r"][1]},
                     tone=tone, name=f"shin_{side}")
            self.add(f"foot_{side}", "capsule", legs_mat, zl + 0.2,
                     {"a": (-0.5 * s, 0), "b": (m["foot"], 0), "r0": m["foot_r"], "r1": m["foot_r"] * 0.8},
                     tone=tone, name=f"foot_{side}")
        T, SW, WW, HW = m["T"], m["SW"], m["WW"], m["HW"]
        self.add("torso", "poly", torso_mat, 5,
                 {"pts": [(0, -HW), (T * 0.42, -WW), (T * 0.82, -SW * 0.92), (T, -SW), (T, SW), (T * 0.82, SW * 0.92),
                          (T * 0.42, WW), (0, HW)]}, bevel=6 * s + 1, name="torso")
        self.add("torso", "ellipse", torso_mat, 4.9, {"c": (T * 0.06, 0), "rx": HW * 0.95, "ry": HW * 1.18},
                 bevel=HW, name="hips")
        self.add("torso", "capsule", "skin", 4.8, {"a": (T - 1 * s, 0.3), "b": (T + m["neck"] + 1, 0.3),
                                                   "r0": 3.0 * s + 0.6}, bevel=2, name="neck")
        for side in ("n", "f"):
            far = side == "f" and self.side
            z = (-1.0 if far else 9.0) if self.side else (9.0 if side == "n" else 8.6)
            tone = -1 if far else 0
            self.add(f"uarm_{side}", "capsule", arms_mat, z,
                     {"a": (0, 0), "b": (m["uarm"], 0), "r0": m["uarm_r"][0], "r1": m["uarm_r"][1]},
                     tone=tone, name=f"uarm_{side}")
            self.add(f"larm_{side}", "capsule", arms_mat, z + 0.1,
                     {"a": (0, 0), "b": (m["larm"], 0), "r0": m["larm_r"][0], "r1": m["larm_r"][1]},
                     tone=tone, name=f"larm_{side}")
            self.add(f"hand_{side}", "ellipse", "skin", z + 0.3,
                     {"c": (m["hand"] * 0.55, 0), "rx": m["hand"], "ry": m["hand"] * 0.8},
                     tone=tone, name=f"hand_{side}")

    def arm_z(self, side):
        far = side == "f" and self.side
        return (-1.0 if far else 9.0) if self.side else (9.0 if side == "n" else 8.6)

    def leg_z(self, side):
        far = side == "f" and self.side
        return (1.0 if side == "f" else 2.0) if not self.side else (-2.0 if far else 2.0)

    # ----------------------------------------------------------------- clothing helpers
    def sleeves(self, material, upper=1.0, lower=0.0, bevel=None, stripes=None, puff=0.0):
        m = self.m
        for side in ("n", "f"):
            z = self.arm_z(side) + 0.15
            tone = -1 if (side == "f" and self.side) else 0
            if upper > 0:
                self.add(f"uarm_{side}", "capsule", material, z,
                         {"a": (-0.5, 0), "b": (m["uarm"] * upper, 0), "r0": m["uarm_r"][0] + 0.5 + puff,
                          "r1": m["uarm_r"][1] + 0.4}, tone=tone, bevel=bevel, stripes=stripes)
            if lower > 0:
                self.add(f"larm_{side}", "capsule", material, z + 0.1,
                         {"a": (m["larm"] * (1 - lower), 0), "b": (m["larm"] * 0.97, 0), "r0": m["larm_r"][0] + 0.45,
                          "r1": m["larm_r"][1] + 0.55}, tone=tone, bevel=bevel, stripes=stripes)

    def bracers(self, material, frac=0.55):
        m = self.m
        for side in ("n", "f"):
            z = self.arm_z(side) + 0.25
            tone = -1 if (side == "f" and self.side) else 0
            self.add(f"larm_{side}", "capsule", material, z,
                     {"a": (m["larm"] * (1 - frac), 0), "b": (m["larm"] * 0.95, 0), "r0": m["larm_r"][0] + 0.45,
                      "r1": m["larm_r"][1] + 0.45}, tone=tone, bevel=1.5 * self.s + 0.6,
                     stripes=(0, 4, 1, -2) if self.m["detail"] else None)

    def gloves(self, material):
        m = self.m
        for side in ("n", "f"):
            z = self.arm_z(side) + 0.35
            tone = -1 if (side == "f" and self.side) else 0
            self.add(f"hand_{side}", "ellipse", material, z,
                     {"c": (m["hand"] * 0.55, 0), "rx": m["hand"] + 0.35, "ry": m["hand"] * 0.8 + 0.35}, tone=tone)

    def pants(self, material, knee=1.0, stripes=None):
        m = self.m
        for side in ("n", "f"):
            z = self.leg_z(side) + 0.15
            tone = -1 if (side == "f" and self.side) else 0
            self.add(f"thigh_{side}", "capsule", material, z,
                     {"a": (-0.5, 0), "b": (m["thigh"], 0), "r0": m["thigh_r"][0] + 0.4, "r1": m["thigh_r"][1] + 0.35},
                     tone=tone, stripes=stripes)
            if knee > 1:
                self.add(f"shin_{side}", "capsule", material, z + 0.1,
                         {"a": (0, 0), "b": (m["shin"] * (knee - 1), 0), "r0": m["shin_r"][0] + 0.35,
                          "r1": m["shin_r"][1] + 0.35}, tone=tone)

    def boots(self, material, height=0.75, cuff=True, trim=None):
        m, s = self.m, self.s
        for side in ("n", "f"):
            z = self.leg_z(side) + 0.3
            tone = -1 if (side == "f" and self.side) else 0
            self.add(f"shin_{side}", "capsule", material, z,
                     {"a": (m["shin"] * (1 - height), 0), "b": (m["shin"], 0), "r0": m["shin_r"][0] + 0.4,
                      "r1": m["shin_r"][1] + 0.5}, tone=tone)
            if cuff:
                a = m["shin"] * (1 - height)
                self.add(f"shin_{side}", "capsule", material, z + 0.05,
                         {"a": (a - 0.8 * s, 0), "b": (a + 3.5 * s, 0), "r0": m["shin_r"][0] + 0.9 * s + 0.3},
                         tone=tone, bevel=2.2 * s + 0.4)
                if trim:
                    self.add(f"shin_{side}", "capsule", trim, z + 0.1,
                             {"a": (a + 2.8 * s, -m["shin_r"][0] - 0.5), "b": (a + 2.8 * s, m["shin_r"][0] + 0.5),
                              "r0": 0.7 * s + 0.15}, tone=tone, bevel=1)
            self.add(f"foot_{side}", "capsule", material, z + 0.1,
                     {"a": (-0.8 * s, 0), "b": (m["foot"] + 0.3, 0), "r0": m["foot_r"] + 0.35,
                      "r1": m["foot_r"] * 0.8 + 0.25}, tone=tone)

    def greaves(self, material):
        self.boots(material, height=0.95, cuff=True)
        m = self.m
        for side in ("n", "f"):  # knee guard
            z = self.leg_z(side) + 0.4
            tone = -1 if (side == "f" and self.side) else 0
            self.add(f"shin_{side}", "ellipse", material, z, {"c": (0.5, 0.0), "rx": m["shin_r"][0] + 0.9,
                                                              "ry": m["shin_r"][0] + 0.6}, tone=tone)

    def top(self, material, lo=0.35, hi=1.0, bevel=None, stripes=None, neckline=0.0, z=6.0, name="top"):
        m = self.m
        T, SW, WW = m["T"], m["SW"], m["WW"]
        a = T * lo
        b = T * hi
        def w(u):
            if u < T * 0.42:
                return WW + (m["HW"] - WW) * (1 - u / (T * 0.42)) * 0.6 + 0.4
            if u < T * 0.82:
                return WW + (SW * 0.92 - WW) * (u - T * 0.42) / (T * 0.4) + 0.45
            return SW * 0.92 + 0.5
        pts = [(a, -w(a)), (b, -w(b) - 0.2), (b, w(b) + 0.2), (a, w(a))]
        if neckline and not self.side:
            pts = [(a, -w(a)), (b, -w(b) - 0.2), (b, -neckline), (b - neckline * 0.9, 0), (b, neckline),
                   (b, w(b) + 0.2), (a, w(a))]
        self.add("torso", "poly", material, z, {"pts": pts}, bevel=bevel or (3 * self.s + 1), stripes=stripes, name=name)

    def skirt(self, material, length=0.9, flare=1.5, z=6.8, stripes=None, front_open=False):
        m = self.m
        T, HW = m["T"], m["HW"]
        top = T * 0.28
        bot = -m["thigh"] * length
        s = self.s
        if self.side:
            pts = [(top, -HW - 0.4), (top, HW + 0.4), (bot, HW + flare), (bot - 0.5, 0), (bot, -HW - flare - 0.6)]
        else:
            pts = [(top, -HW - 0.5), (top, HW + 0.5), (bot, HW + flare), (bot - 2 * s, HW * 0.4), (bot + 1.5, 0),
                   (bot - 2 * s, -HW * 0.4), (bot, -HW - flare)]
        self.add("torso", "poly", material, z, {"pts": pts}, bevel=2.5 * s + 0.5, stripes=stripes, name="skirt")

    def belt(self, material, buckle="trim", u=0.30, z=7.2):
        m = self.m
        T = m["T"]
        w = m["WW"] + (m["HW"] - m["WW"]) * 0.5 + 0.7
        h = max(1.2, 3.4 * self.s)
        self.add("torso", "poly", material, z, {"pts": [(T * u - h / 2, -w), (T * u + h / 2, -w + 0.2),
                                                        (T * u + h / 2, w - 0.2), (T * u - h / 2, w)]}, bevel=1.2,
                 name="belt")
        if buckle:
            bv = w - 1.2 if self.side else 1.0
            self.add("torso", "ellipse", buckle, z + 0.1, {"c": (T * u, bv), "rx": h * 0.6, "ry": h * 0.6}, bevel=1)

    def pauldrons(self, material, size=1.0, trim=None):
        m, s = self.m, self.s
        for side in ("n", "f"):
            z = self.arm_z(side) + 0.6
            tone = -1 if (side == "f" and self.side) else 0
            r = (m["uarm_r"][0] + 2.2 * s + 0.8) * size
            self.add(f"uarm_{side}", "ellipse", material, z, {"c": (r * 0.35, 0), "rx": r * 0.95, "ry": r},
                     tone=tone, bevel=r * 0.7, name=f"pad_{side}")
            if trim:
                self.add(f"uarm_{side}", "capsule", trim, z + 0.05,
                         {"a": (r * 1.1, -r * 0.9), "b": (r * 1.1, r * 0.9), "r0": 0.6 * s + 0.2}, tone=tone, bevel=1)

    def cape(self, material, length=1.0, width=1.0, z=-3.0, lining=None):
        m, s = self.m, self.s
        L = (m["T"] + m["thigh"] * 0.9) * length
        if self.side:
            pts = [(0, -1.2 * width), (0, 2.2 * width), (L, -0.5 * width), (L + 1, -4.2 * width), (L * 0.5, -3.6 * width)]
            self.add("cape", "poly", material, z, {"pts": pts}, bevel=2.5, stripes=None, name="cape")
        else:
            W0 = m["SW"] + 1
            W1 = (m["SW"] + 7 * s) * width
            pts = [(0, -W0), (0, W0), (L, W1), (L + 3 * s, 0), (L, -W1)]
            self.add("cape", "poly", material, z, {"pts": pts}, bevel=4, stripes=(0, 6 * s, 1, -1), name="cape")

    def hood(self, material, z=14.5, up=True):
        m, s = self.m, self.s
        hu, hv = m["head_u"], m["head_v"]
        cu, cv = m["head_c"]
        if self.side:
            pts = [(cu + hu + 1.3, -1.5), (cu + hu * 0.6, hv * 0.85), (cu + 0.6, hv * 0.55), (cu - hu * 0.2, hv * 0.35),
                   (cu - hu * 0.55, -0.8), (cu - hu - 1.0, -hv * 0.75), (cu - hu * 0.2, -hv - 1.4), (cu + hu * 0.8, -hv - 0.4)]
        else:
            pts = [(cu + hu + 2 * s, 0), (cu + hu * 0.75, hv + 1.6), (cu - hu * 0.5, hv + 1.8), (cu - hu * 1.15, hv + 0.6),
                   (cu - hu * 0.9, hv * 0.65), (cu + hu * 0.35, hv * 0.72), (cu + hu * 0.6, 0), (cu + hu * 0.35, -hv * 0.72),
                   (cu - hu * 0.9, -hv * 0.65), (cu - hu * 1.15, -hv - 0.6), (cu - hu * 0.5, -hv - 1.8),
                   (cu + hu * 0.75, -hv - 1.6)]
        self.add("head", "poly", material, z, {"pts": pts}, bevel=3 * s + 0.8, name="hood")

    # ----------------------------------------------------------------- head
    def head(self):
        m, v, s = self.m, self.v, self.s
        hu, hv = m["head_u"], m["head_v"]
        cu, cv = m["head_c"]
        if self.side:
            self.add("head", "ellipse", "skin", 12, {"c": (cu, cv), "rx": hu, "ry": hv}, bevel=hv * 0.8, name="face")
            self.add("head", "ellipse", "skin", 12.05, {"c": (cu - hu * 0.55, cv + hv * 0.42), "rx": hu * 0.45,
                                                         "ry": hv * 0.5}, bevel=2, name="jaw")
            # ear (near side, behind face centre)
            if v.ears == "elf":
                self.add("head", "poly", "skin", 12.4, {"pts": [(cu + 0.4, -1.2), (cu + 4.2, -4.6), (cu - 0.2, -3.0),
                                                                 (cu - 1.6, -1.0)]}, bevel=1, name="ear")
            elif v.ears == "human":
                self.add("head", "ellipse", "skin", 12.4, {"c": (cu - 0.6, -1.0), "rx": 1.5, "ry": 1.1}, bevel=1, name="ear")
        else:
            self.add("head", "ellipse", "skin", 12, {"c": (cu - 1.5, cv), "rx": hu, "ry": hv}, bevel=hv * 0.85, name="face")
            self.add("head", "poly", "skin", 12.1, {"pts": [(cu - 2, -hv * 0.92), (cu - 2, hv * 0.92 + 0.6), (cu - hu + 0.6, 3.0),
                                                             (cu - hu - 1.4, 1.2), (cu - hu - 1.4, -0.4), (cu - hu + 0.6, -2.4)]},
                     bevel=3, name="jaw")
            if v.ears == "elf":
                self.add("head", "poly", "skin", 12.5, {"pts": [(cu - 1, -hv + 0.7), (cu + 5, -hv - 4.3), (cu + 0.5, -hv - 1.3),
                                                                 (cu - 4, -hv + 1.2)]}, bevel=1.4, name="ear")
                self.add("head", "poly", "skin", 12.5, {"pts": [(cu - 1, hv - 0.2), (cu + 5, hv + 4.6), (cu + 0.5, hv + 1.6),
                                                                 (cu - 4, hv - 0.6)]}, bevel=1.4, name="ear2", tone=-1)
            elif v.ears == "human":
                for sg in (-1, 1):
                    self.add("head", "ellipse", "skin", 11.9, {"c": (cu - 2, sg * (hv - 0.2) + cv), "rx": 2.6, "ry": 1.6},
                             bevel=1.5, name="ear")
        if v.ears == "cat":
            for sg in ((-1, 1) if not self.side else (-1,)):
                base_v = sg * hv * 0.55 + (0 if not self.side else -0.5)
                self.add("head", "poly", "hair", 13.6, {"pts": [(cu + hu * 0.75, base_v - 2.4 * s - 1),
                                                                 (cu + hu + 5.5 * s + 1.5, base_v),
                                                                 (cu + hu * 0.75, base_v + 2.4 * s + 1)]}, bevel=1.2)
        if v.ears == "horns":
            for sg in ((-1, 1) if not self.side else (1,)):
                bv = sg * hv * 0.45
                self.add("head", "poly", "horn", 13.7, {"pts": [(cu + hu * 0.7, bv - 1.6 * s - 0.6), (cu + hu + 6 * s + 1.5, bv + sg * 2.5 * s),
                                                                 (cu + hu * 0.7, bv + 1.6 * s + 0.6)]}, bevel=1.2)
        self.hair()
        if v.beard:
            if self.side:
                self.add("head", "poly", "hair", 12.6, {"pts": [(cu - 2.6, -0.4), (cu - 3.0, hv + 0.2), (cu - hu - 2.6, hv * 0.55),
                                                                 (cu - hu - 1.4, -0.8)]}, bevel=1.5, name="beard")
            else:
                self.add("head", "poly", "hair", 12.6, {"pts": [(cu - 6.5, -hv + 0.8), (cu - 7.5, -2.2), (cu - 7.5, 2.2), (cu - 6.5, hv - 0.8),
                                                                 (cu - hu - 5, hv * 0.45), (cu - hu - 7, 0), (cu - hu - 5, -hv * 0.45)]}, bevel=2,
                         stripes=(0, 3, 1, -2), name="beard")

    def hair(self):
        m, v, s = self.m, self.v, self.s
        hu, hv = m["head_u"], m["head_v"]
        cu, cv = m["head_c"]
        st = v.hair_style
        if st == "bald":
            return
        strands = (95, 3 * s + 0.6, 1, -2) if m["detail"] else None
        if self.side:
            # cap covering top and back of head, bangs at the front
            cap = [(cu + hu + 1.0, -hv * 0.6), (cu + hu + 1.1, hv * 0.35), (cu + hu * 0.55, hv + 0.9),
                   (cu + hu * 0.18, hv * 0.62), (cu + hu * 0.38, hv * 0.36), (cu + hu * 0.05, hv * 0.12),
                   (cu + hu * 0.2, -hv * 0.2), (cu - hu * 0.15, -hv * 0.3), (cu - hu * 0.62, -hv * 0.22),
                   (cu - hu * 0.85, -hv - 0.4), (cu + hu * 0.3, -hv - 1.0)]
            if st == "spiky":
                cap = [(cu + hu + 2.6, -hv * 0.5), (cu + hu + 0.8, -hv * 0.1), (cu + hu + 2.4, hv * 0.4), (cu + hu * 0.5, hv + 1.4),
                       (cu + hu * 0.3, hv * 0.62), (cu + hu * 0.45, hv * 0.35), (cu + hu * 0.25, hv * 0.1), (cu - hu * 0.55, -hv * 0.25),
                       (cu - hu * 0.6, -hv - 2.2), (cu, -hv - 0.6), (cu + hu * 0.5, -hv - 1.8)]
            self.add("head", "poly", "hair", 13, {"pts": cap}, bevel=2.2, name="hair_cap")
            if st in ("long", "twin", "braid"):
                L = 9.5 if st == "long" else 7.5
                self.add("head", "poly", "hair", 3.5, {"pts": [(cu, -hv * 0.2), (cu + hu * 0.3, -hv - 0.8), (cu - hu - L, -hv - 1.5),
                                                                (cu - hu - L - 1.5, -hv * 0.15), (cu - hu * 0.6, 0.6)]},
                         bevel=1.8, name="hair_back", tone=-1)
            elif st == "ponytail":
                self.add("tail", "capsule", "hair", 3.5, {"a": (0, 0), "b": (8.5, 0.6), "r0": 2.1, "r1": 1.2},
                         bevel=1.6, name="ponytail")
                self.add("tail", "ellipse", "trim", 13.8, {"c": (0.4, 0), "rx": 1.0, "ry": 1.3}, bevel=1)
            elif st in ("short", "bob", "spiky"):
                ext = 2.6 if st == "bob" else 0.6
                self.add("head", "poly", "hair", 3.5, {"pts": [(cu + hu * 0.4, -hv * 0.3), (cu + hu * 0.2, -hv - 0.8),
                                                                (cu - hu * 0.55 - ext, -hv - 0.5), (cu - hu * 0.6 - ext, -hv * 0.1)]},
                         bevel=1.6, name="hair_back", tone=-1)
        else:
            cap = [(cu + 1, -hv - 2.2), (cu + 7, -hv - 2.2), (cu + hu + 1.4, -hv * 0.85), (cu + hu + 2.8, 0), (cu + hu + 1.4, hv * 0.85),
                   (cu + 7, hv + 2.0), (cu + 1.5, hv + 2.2), (cu + 3.6, hv * 0.93), (cu + 1.6, hv * 0.71), (cu + 4.2, hv * 0.51),
                   (cu + 2.2, hv * 0.27), (cu + 4.8, hv * 0.07), (cu + 2.8, -hv * 0.17), (cu + 4.8, -hv * 0.41),
                   (cu + 1.8, -hv * 0.68), (cu + 4.0, -hv * 0.9)]
            if st == "spiky":
                cap = [(cu + 1, -hv - 2.5), (cu + 6, -hv - 4.5), (cu + 8, -hv * 0.6), (cu + hu + 5, -hv * 0.5), (cu + hu + 3, -hv * 0.1),
                       (cu + hu + 6, hv * 0.2), (cu + hu + 2, hv * 0.6), (cu + 8, hv + 3.5), (cu + 1.5, hv + 2.5),
                       (cu + 3.2, hv * 0.8), (cu + 1.0, hv * 0.55), (cu + 4.0, hv * 0.35), (cu + 2.0, 0), (cu + 4.5, -hv * 0.3),
                       (cu + 1.5, -hv * 0.6), (cu + 3.5, -hv * 0.85)]
            self.add("head", "poly", "hair", 13, {"pts": cap}, bevel=3.2, stripes=strands, name="hair_cap")
            if st != "spiky":
                self.add("head", "poly", "hair", 13.05, {"pts": [(cu + hu - 0.6, -hv * 0.75), (cu + hu + 0.6, -hv * 0.3), (cu + hu + 0.4, hv * 0.2),
                                                                  (cu + hu - 0.8, hv * 0.55), (cu + hu - 1.6, hv * 0.15), (cu + hu - 1.4, -hv * 0.35)]},
                         bevel=1, tone=2, line=False, cast=False, name="hair_shine")
            lock = 14 if st in ("long", "twin", "braid") else (8 if st == "bob" else 4)
            if st not in ("short", "spiky"):
                self.add("head", "poly", "hair", 13.1, {"pts": [(cu + 3, hv - 0.6), (cu + 2, hv + 2.6), (cu - lock + 4, hv + 2.4),
                                                                 (cu - lock, hv + 0.8), (cu - 6, hv * 0.9), (cu - 1, hv * 0.85)]},
                         bevel=1.8, stripes=(0, 3, 1, -2), name="side_lock")
                self.add("head", "poly", "hair", 13.1, {"pts": [(cu + 3, -hv + 0.6), (cu + 2, -hv - 2.8), (cu - lock + 2, -hv - 3.2),
                                                                 (cu - lock - 3, -hv - 1.6), (cu - 7, -hv * 0.95), (cu - 1, -hv * 0.95)]},
                         bevel=1.8, stripes=(0, 3, 1, -2), name="side_lock2")
            if st in ("long", "braid", "twin", "ponytail", "bob"):
                L = {"long": 44, "braid": 40, "twin": 30, "ponytail": 36, "bob": 14}[st]
                W2 = 13 if st != "bob" else 11
                self.add("head", "poly", "hair", 3, {"pts": [(cu + 6, -hv - 1), (cu + 8.5, 0), (cu + 6, hv + 1.5), (cu - 6, hv + 3),
                                                              (cu - L * 0.6, W2 + 1), (cu - L, W2 - 2), (cu - L + 4, 2), (cu - L, -4),
                                                              (cu - L * 0.75, -W2 + 1), (cu - 12, -hv - 3)]},
                         bevel=4, stripes=(0, 3, 1, -2), name="hair_back")
            elif st in ("short", "spiky"):
                self.add("head", "poly", "hair", 3, {"pts": [(cu + 6, -hv - 1.5), (cu + 8.5, 0), (cu + 6, hv + 1.5), (cu - 7, hv + 1.6),
                                                              (cu - 9, 0), (cu - 7, -hv - 1.6)]}, bevel=3, name="hair_back")

    # ----------------------------------------------------------------- weapons
    def weapon(self, kind):
        s, side = self.s, self.side
        zw = 10.5 if side else 8.4
        sc = 0.48 if side else 1.0     # battle sprites use smaller weapons
        if kind == "sword":
            L = 30 * sc
            self.add("weapon", "capsule", "leather2", zw, {"a": (-2.5 * sc, 0), "b": (2.5 * sc, 0), "r0": 1.0 * sc + 0.35}, bevel=1)
            self.add("weapon", "capsule", "trim", zw + 0.1, {"a": (2.6 * sc, -4.6 * sc - 0.5), "b": (2.6 * sc, 4.6 * sc + 0.5),
                                                              "r0": 1.0 * sc + 0.3}, bevel=1)
            self.add("weapon", "poly", "metal", zw + 0.05, {"pts": [(3.2 * sc, -1.8 * sc - 0.45), (L, -1.4 * sc - 0.35), (L + 3 * sc, 0),
                                                                     (L, 1.4 * sc + 0.35), (3.2 * sc, 1.8 * sc + 0.45)]},
                     bevel=1.2, name="blade")
        elif kind == "greatsword":
            L = 40 * sc
            self.add("weapon", "capsule", "leather2", zw, {"a": (-5 * sc, 0), "b": (3 * sc, 0), "r0": 1.1 * sc + 0.4}, bevel=1)
            self.add("weapon", "capsule", "trim", zw + 0.1, {"a": (3.4 * sc, -6 * sc - 0.5), "b": (3.4 * sc, 6 * sc + 0.5),
                                                              "r0": 1.3 * sc + 0.3}, bevel=1)
            self.add("weapon", "poly", "metal", zw + 0.05, {"pts": [(4 * sc, -2.8 * sc - 0.5), (L, -2.4 * sc - 0.5), (L + 5 * sc, 0),
                                                                     (L, 2.4 * sc + 0.5), (4 * sc, 2.8 * sc + 0.5)]},
                     bevel=1.4, name="blade")
        elif kind == "axe":
            L = 34 * sc
            self.add("weapon", "capsule", "wood", zw, {"a": (-8 * sc, 0), "b": (L, 0), "r0": 1.1 * sc + 0.35}, bevel=1)
            self.add("weapon", "poly", "metal", zw + 0.1, {"pts": [(L - 10 * sc, 0.5), (L - 13 * sc, 9 * sc + 1), (L - 4 * sc, 12 * sc + 1.2),
                                                                    (L + 1 * sc, 9 * sc + 1), (L - 1 * sc, 0.5)]},
                     bevel=1.6, name="axehead")
            self.add("weapon", "poly", "metal", zw + 0.1, {"pts": [(L - 9 * sc, -0.5), (L - 11 * sc, -6 * sc - 0.5), (L - 4 * sc, -8 * sc - 0.6),
                                                                    (L, -6 * sc - 0.5), (L - 2 * sc, -0.5)]}, bevel=1.4)
        elif kind == "mace":
            L = 24 * sc
            self.add("weapon", "capsule", "wood", zw, {"a": (-3 * sc, 0), "b": (L, 0), "r0": 1.0 * sc + 0.35}, bevel=1)
            self.add("weapon", "ellipse", "metal", zw + 0.1, {"c": (L + 1.5 * sc, 0), "rx": 4.2 * sc + 0.5, "ry": 3.8 * sc + 0.5},
                     bevel=2, name="macehead")
            for a in (-1, 1):
                self.add("weapon", "poly", "metal", zw + 0.05, {"pts": [(L - 1 * sc, a * 3 * sc), (L + 1.5 * sc, a * (7 * sc + 0.8)),
                                                                         (L + 4 * sc, a * 3 * sc)]}, bevel=1)
        elif kind == "dagger":
            L = 15 * sc
            self.add("weapon", "capsule", "leather2", zw, {"a": (-2 * sc, 0), "b": (2 * sc, 0), "r0": 1 * sc + 0.3}, bevel=1)
            self.add("weapon", "capsule", "trim", zw + 0.1, {"a": (2.2 * sc, -3 * sc - 0.3), "b": (2.2 * sc, 3 * sc + 0.3),
                                                              "r0": 0.9 * sc + 0.25}, bevel=1)
            self.add("weapon", "poly", "metal", zw + 0.05, {"pts": [(2.6 * sc, -1.6 * sc - 0.4), (L, -0.8 * sc - 0.2), (L + 2.5 * sc, 0.6 * sc),
                                                                     (L - 1 * sc, 1.6 * sc + 0.4), (2.6 * sc, 1.6 * sc + 0.4)]},
                     bevel=1, name="blade")
        elif kind == "bow":
            R = 34 * sc
            k = 1 if side else 1
            self.add("weapon", "capsule", "wood", zw - 2, {"a": (-R, 6 * sc), "b": (0, 1 * sc), "r0": 1.4 * sc + 0.3,
                                                             "r1": 1.9 * sc + 0.3}, bevel=1.4, name="bow_top")
            self.add("weapon", "capsule", "wood", zw - 2, {"a": (0, 1 * sc), "b": (R, 6 * sc), "r0": 1.9 * sc + 0.3,
                                                             "r1": 1.4 * sc + 0.3}, bevel=1.4, name="bow_bot")
            self.add("weapon", "capsule", "wood", zw - 1.95, {"a": (-R, 6 * sc), "b": (-R - 4 * sc, 2 * sc), "r0": 1.2 * sc + 0.2}, bevel=1)
            self.add("weapon", "capsule", "wood", zw - 1.95, {"a": (R, 6 * sc), "b": (R + 4 * sc, 2 * sc), "r0": 1.2 * sc + 0.2}, bevel=1)
            self.add("weapon", "capsule", "trim", zw - 1.8, {"a": (-3 * sc, 1.4 * sc), "b": (3 * sc, 1.4 * sc), "r0": 2.1 * sc + 0.2}, bevel=1.2)
            self.add("weapon", "capsule", "string", zw - 2.1, {"a": (-R - 4 * sc, 2.2 * sc), "b": (R + 4 * sc, 2.2 * sc),
                                                                 "r0": 0.45 if not side else 0.35}, bevel=1, line=False, cast=False,
                     name="bowstring")
        elif kind == "staff":
            L = 44 * sc
            self.add("weapon", "capsule", "wood", zw - 1.5, {"a": (-L * 0.55, 0), "b": (L * 0.62, 0), "r0": 1.2 * sc + 0.35}, bevel=1)
            self.add("weapon", "poly", "trim", zw - 1.4, {"pts": [(L * 0.6, -2.5 * sc - 0.4), (L * 0.6 + 7 * sc, -4 * sc - 0.6), (L * 0.6 + 4 * sc, 0),
                                                                   (L * 0.6 + 7 * sc, 4 * sc + 0.6), (L * 0.6, 2.5 * sc + 0.4)]}, bevel=1)
            self.add("weapon", "ellipse", "accent", zw - 1.3, {"c": (L * 0.6 + 6 * sc, 0), "rx": 3.8 * sc + 0.6, "ry": 3.8 * sc + 0.6},
                     bevel=3 * sc + 0.6, name="orb")
        elif kind == "scythe":
            L = 44 * sc
            self.add("weapon", "capsule", "dark", zw - 1.5, {"a": (-L * 0.5, 0), "b": (L * 0.62, 0), "r0": 1.2 * sc + 0.35}, bevel=1)
            self.add("weapon", "poly", "metal", zw - 1.4, {"pts": [(L * 0.58, 0), (L * 0.66, -2 * sc), (L * 0.55, -14 * sc - 2),
                                                                    (L * 0.38, -20 * sc - 2.5), (L * 0.47, -12 * sc - 1), (L * 0.5, -2 * sc)]},
                     bevel=1.4, name="scythe_blade")
            self.add("weapon", "ellipse", "glow_green", zw - 1.3, {"c": (L * 0.62, 0), "rx": 2.0 * sc + 0.5, "ry": 2.0 * sc + 0.5}, bevel=1)
        elif kind == "lute":
            self.add("weapon", "ellipse", "wood", zw - 0.5, {"c": (2 * sc, 6 * sc), "rx": 7 * sc + 0.6, "ry": 6 * sc + 0.6}, bevel=4 * sc + 0.5,
                     name="lute_body")
            self.add("weapon", "ellipse", "dark", zw - 0.45, {"c": (2 * sc, 6 * sc), "rx": 1.8 * sc + 0.3, "ry": 1.8 * sc + 0.3}, bevel=1)
            self.add("weapon", "capsule", "leather2", zw - 0.4, {"a": (-4 * sc, 6 * sc), "b": (-20 * sc, 6 * sc), "r0": 1.1 * sc + 0.3}, bevel=1)
            self.add("weapon", "capsule", "trim", zw - 0.35, {"a": (-20 * sc, 6 * sc), "b": (-24 * sc, 4 * sc), "r0": 1.4 * sc + 0.3}, bevel=1)
        elif kind == "book":
            self.add("offhand", "poly", "primary", 10.2 if side else 9.4,
                     {"pts": [(-4 * sc - 0.6, -5 * sc - 0.6), (6 * sc + 0.6, -5 * sc - 0.6), (6 * sc + 0.6, 5 * sc + 0.6), (-4 * sc - 0.6, 5 * sc + 0.6)]},
                     bevel=1.2, name="book")
            self.add("offhand", "poly", "page", 10.25 if side else 9.45,
                     {"pts": [(-3 * sc - 0.4, 4 * sc + 0.4), (5 * sc + 0.4, 4 * sc + 0.4), (5 * sc + 0.4, 5.6 * sc + 0.6), (-3 * sc - 0.4, 5.6 * sc + 0.6)]},
                     bevel=1, line=False)
            self.add("offhand", "ellipse", "trim", 10.3 if side else 9.5, {"c": (1 * sc, 0), "rx": 1.6 * sc + 0.3, "ry": 1.6 * sc + 0.3}, bevel=1)

    def shield(self):
        s, side = self.s, self.side
        sc = 0.48 if side else 1.0
        z = 10.8 if side else 9.6
        R = 10 * sc + 0.8
        self.add("offhand", "ellipse", "primary", z, {"c": (0, 0), "rx": R * 1.15, "ry": R}, bevel=R * 0.5, name="shield")
        self.add("offhand", "ellipse", "metal", z - 0.05, {"c": (0, 0), "rx": R * 1.15 + 0.9, "ry": R + 0.9}, bevel=1.2)
        self.add("offhand", "ellipse", "trim", z + 0.05, {"c": (0, 0), "rx": R * 0.38, "ry": R * 0.34}, bevel=1.2)
        if not side:
            self.add("offhand", "capsule", "trim", z + 0.04, {"a": (-R, 0), "b": (R, 0), "r0": 0.8}, bevel=1, line=False)
            self.add("offhand", "capsule", "trim", z + 0.04, {"a": (0, -R * 0.9), "b": (0, R * 0.9), "r0": 0.8}, bevel=1, line=False)

    def quiver(self):
        m, s = self.m, self.s
        T = m["T"]
        if self.side:
            self.add("torso", "capsule", "leather", -2.5, {"a": (T * 0.25, -3.6), "b": (T * 1.05, -6.2), "r0": 1.4}, bevel=1, name="quiver")
            for o in (-0.6, 0.7):
                self.add("torso", "capsule", "feather", -2.6, {"a": (T * 1.05, -6.2 + o), "b": (T * 1.32, -7.3 + o), "r0": 0.6},
                         bevel=1, line=False)
        else:
            self.add("torso", "capsule", "leather", 0.5, {"a": (T * 0.27, -6), "b": (T * 1.13, -14), "r0": 3.2}, bevel=2, name="quiver")
            for o in (-1.5, 0.5, 2.5):
                self.add("torso", "capsule", "feather", 0.4, {"a": (T * 1.13, -14 + o), "b": (T * 1.33, -17 + o), "r0": 1.2}, bevel=1)

    def hat_wizard(self, material, band="trim"):
        m, s = self.m, self.s
        hu, hv = m["head_u"], m["head_v"]
        cu, cv = m["head_c"]
        if self.side:
            self.add("head", "ellipse", material, 14.2, {"c": (cu + hu * 0.55, 0.2), "rx": 1.6, "ry": hv + 3.4}, bevel=1, name="brim")
            self.add("head", "poly", material, 14.1, {"pts": [(cu + hu * 0.5, -hv + 0.5), (cu + hu * 0.5, hv - 0.5),
                                                               (cu + hu + 7.5, -1.5), (cu + hu + 10.5, -6.5), (cu + hu + 6, -3.0)]},
                     bevel=2.2, name="hat")
            self.add("head", "poly", band, 14.15, {"pts": [(cu + hu * 0.55, -hv + 0.6), (cu + hu * 0.55, hv - 0.6),
                                                            (cu + hu * 0.55 + 1.6, hv - 1.2), (cu + hu * 0.55 + 1.6, -hv + 1.2)]}, bevel=1)
        else:
            self.add("head", "ellipse", material, 14.2, {"c": (cu + hu * 0.6, 0.5), "rx": 3.2, "ry": hv + 10}, bevel=2, name="brim")
            self.add("head", "poly", material, 14.1, {"pts": [(cu + hu * 0.5, -hv - 1), (cu + hu * 0.5, hv + 1), (cu + hu + 14, 3),
                                                               (cu + hu + 24, 11), (cu + hu + 14, -2)]}, bevel=4, name="hat")
            self.add("head", "poly", band, 14.15, {"pts": [(cu + hu * 0.55, -hv - 0.6), (cu + hu * 0.55, hv + 0.6),
                                                            (cu + hu * 0.55 + 3, hv - 0.2), (cu + hu * 0.55 + 3, -hv + 0.2)]}, bevel=1.2)

    def hat_feather(self, material):
        m, s = self.m, self.s
        hu, hv = m["head_u"], m["head_v"]
        cu, cv = m["head_c"]
        if self.side:
            self.add("head", "ellipse", material, 14.2, {"c": (cu + hu * 0.65, 0.5), "rx": 1.4, "ry": hv + 2.6}, bevel=1, name="brim")
            self.add("head", "ellipse", material, 14.1, {"c": (cu + hu * 0.85, -0.4), "rx": hu * 0.55, "ry": hv * 0.85}, bevel=2, name="hat")
            self.add("head", "poly", "red", 14.3, {"pts": [(cu + hu * 0.9, -hv * 0.6), (cu + hu + 4.5, -hv - 3.5), (cu + hu + 1.5, -hv - 1),
                                                            (cu + hu * 0.8, -hv * 0.4)]}, bevel=1, name="plume")
        else:
            self.add("head", "ellipse", material, 14.2, {"c": (cu + hu * 0.65, 1), "rx": 3, "ry": hv + 7}, bevel=2, name="brim")
            self.add("head", "ellipse", material, 14.1, {"c": (cu + hu * 0.95, 0), "rx": hu * 0.6, "ry": hv * 0.95}, bevel=3, name="hat")
            self.add("head", "poly", "red", 14.3, {"pts": [(cu + hu * 0.9, -hv * 0.6), (cu + hu + 12, -hv - 9), (cu + hu + 4, -hv - 2),
                                                            (cu + hu * 0.8, -hv * 0.2)]}, bevel=2, stripes=(30, 3, 1, -2), name="plume")

    def halo(self):
        m = self.m
        hu, hv = m["head_u"], m["head_v"]
        cu, cv = m["head_c"]
        if self.side:
            self.add("head", "ellipse", "trim", 15, {"c": (cu + hu + 3.0, -0.5), "rx": 0.9, "ry": hv * 0.85}, bevel=1, line=False,
                     cast=False, name="halo")
        else:
            self.add("head", "ellipse", "trim", 15, {"c": (cu + hu + 6, 0), "rx": 1.6, "ry": hv + 2}, bevel=1, line=False,
                     cast=False, name="halo")

    def mask(self, material):
        m = self.m
        hu, hv = m["head_u"], m["head_v"]
        cu, cv = m["head_c"]
        if self.side:
            self.add("head", "poly", material, 12.8, {"pts": [(cu - 1.6, -1.0), (cu - 1.4, hv + 0.8), (cu - hu - 0.6, hv * 0.55),
                                                               (cu - hu - 0.2, -1.4)]}, bevel=1.2, name="mask")
        else:
            self.add("head", "poly", material, 12.8, {"pts": [(cu - 4, -hv - 0.5), (cu - 4, hv + 0.5), (cu - hu - 1, hv * 0.7),
                                                               (cu - hu - 2.5, 0), (cu - hu - 1, -hv * 0.7)]}, bevel=2, name="mask")

    def scarf(self, material):
        m, s = self.m, self.s
        T = m["T"]
        if self.side:
            self.add("torso", "capsule", material, 12.5, {"a": (T + 0.2, -1.8), "b": (T + 0.2, 2.6), "r0": 1.5}, bevel=1, name="scarf")
            self.add("torso", "poly", material, -2.8, {"pts": [(T + 0.6, -1.5), (T - 0.6, -2.5), (T - 4.0, -8.5), (T - 2.0, -9.6)]},
                     bevel=1, name="scarf_tail")
        else:
            self.add("torso", "capsule", material, 12.5, {"a": (T + 1, -6.5), "b": (T + 1, 6.5), "r0": 3.4}, bevel=2.4, name="scarf")
            self.add("torso", "poly", material, 12.4, {"pts": [(T, 2), (T - 14, 5), (T - 16, 1), (T - 2, -1)]}, bevel=2, name="scarf_tail")

    def fur_collar(self):
        m = self.m
        T = m["T"]
        if self.side:
            self.add("torso", "ellipse", "fur", 11.5, {"c": (T - 0.4, -0.4), "rx": 2.2, "ry": 4.6}, bevel=1.6, stripes=(90, 2, 1, -2), name="fur")
        else:
            self.add("torso", "ellipse", "fur", 11.5, {"c": (T - 1.5, 0), "rx": 5.5, "ry": 14}, bevel=3.5, stripes=(90, 3, 1, -2), name="fur")

    def skull_pauldron(self):
        m, s = self.m, self.s
        side = "n" if self.side else "n"
        r = m["uarm_r"][0] + 2.5 * s + 0.6
        self.add(f"uarm_{side}", "ellipse", "bone", self.arm_z(side) + 0.7, {"c": (r * 0.3, 0), "rx": r, "ry": r * 0.95},
                 bevel=r * 0.6, name="skull")


# --------------------------------------------------------------------------- classes
def build_class(b: Builder):
    v = b.v
    c = v.cls
    s = b.s
    if c == "knight":
        b.body(arms_mat="secondary", legs_mat="secondary", torso_mat="secondary")
        b.cape("primary", length=1.0)
        b.top("metal", lo=0.30, hi=1.0, name="breastplate")
        b.top("primary", lo=-0.05, hi=0.52, z=6.3, name="tabard", stripes=None)
        b.skirt("metal_dark", length=0.45, flare=0.8, z=6.2)
        b.belt("leather", buckle="trim", u=0.36, z=7)
        b.sleeves("metal", upper=0.0, lower=0.75)
        b.gloves("metal_dark")
        b.pauldrons("metal", trim="trim")
        b.greaves("metal")
        b.pants("secondary")
        b.head()
        b.weapon(v.weapon or "sword")
        b.shield()
    elif c == "berserker":
        b.body()
        b.pants("leather", knee=1.3, stripes=None)
        b.belt("leather2", buckle="metal", u=0.24, z=7)
        b.skirt("fur", length=0.35, flare=1.2, z=6.9)
        b.bracers("leather2", frac=0.6)
        b.boots("fur", height=0.6, cuff=True)
        b.fur_collar()
        b.pauldrons("fur", size=0.85)
        b.top("leather2", lo=0.46, hi=0.62, z=5.6, name="strap")
        b.head()
        b.weapon(v.weapon or "axe")
    elif c == "archer":
        b.body()
        b.quiver()
        b.top("secondary", lo=0.32, hi=0.55, z=5.5, name="undershirt")
        b.top("primary", lo=0.48, hi=1.0, z=6, neckline=4.0, name="corset")
        b.skirt("primary", length=0.5, flare=2.2, stripes=(90, 5 * s + 0.6, 1, -2) if b.m["detail"] else None)
        b.belt("leather", buckle="trim", u=0.30)
        b.pauldrons("primary", size=0.7, trim="trim")
        b.bracers("leather")
        b.boots("primary", height=0.85, trim="trim")
        b.head()
        b.weapon(v.weapon or "bow")
    elif c == "assassin":
        b.body(torso_mat="dark", arms_mat="dark", legs_mat="dark")
        b.top("leather2", lo=0.0, hi=1.0, z=5.6, name="vest")
        b.belt("primary", buckle="metal", u=0.30)
        b.sleeves("dark", upper=1.0, lower=1.0)
        b.bracers("leather")
        b.gloves("leather2")
        b.pants("dark")
        b.boots("leather2", height=0.7)
        b.head()
        b.hood("dark")
        b.mask("dark")
        b.scarf("primary")
        b.weapon(v.weapon or "dagger")
        _offhand_dagger(b)
    elif c == "mage":
        b.body(torso_mat="primary", arms_mat="primary", legs_mat="primary")
        b.skirt("primary", length=1.75, flare=4.0 * s + 1.2, z=6.5, stripes=(90, 6 * s + 1, 1, -2) if b.m["detail"] else None)
        b.top("primary", lo=0.25, hi=1.0, z=6.0, neckline=0, name="robe")
        b.top("secondary", lo=0.85, hi=1.0, z=6.1, name="collar")
        b.belt("trim", buckle="accent", u=0.4)
        b.sleeves("primary", upper=1.0, lower=1.0, puff=0.6)
        b.boots("leather", height=0.3, cuff=False)
        b.cape("secondary", length=1.1, z=-3.2)
        b.head()
        b.hat_wizard("primary")
        b.weapon(v.weapon or "staff")
    elif c == "necromancer":
        b.body(torso_mat="primary", arms_mat="primary", legs_mat="dark")
        b.skirt("primary", length=1.6, flare=3.0 * s + 1, z=6.5)
        b.top("primary", lo=0.25, hi=1.0, z=6.0, name="robe")
        b.belt("bone", buckle="glow_green", u=0.4)
        b.sleeves("primary", upper=1.0, lower=1.0, puff=0.5)
        b.boots("dark", height=0.4)
        b.cape("dark", length=1.15, z=-3.2)
        b.head()
        b.hood("primary")
        b.skull_pauldron()
        b.weapon(v.weapon or "scythe")
    elif c == "cleric":
        b.body(torso_mat="secondary", arms_mat="secondary", legs_mat="secondary")
        b.skirt("secondary", length=1.55, flare=3.0 * s + 1, z=6.5, stripes=(90, 6 * s + 1, 1, -2) if b.m["detail"] else None)
        b.top("secondary", lo=0.25, hi=1.0, z=6.0, name="robe")
        b.top("trim", lo=0.84, hi=1.0, z=6.1, name="collar")
        b.top("primary", lo=0.0, hi=0.5, z=6.6, name="sash")
        b.belt("trim", buckle="accent", u=0.4)
        b.sleeves("secondary", upper=1.0, lower=0.9, puff=0.7)
        b.boots("leather", height=0.3, cuff=False)
        b.head()
        b.halo()
        b.weapon(v.weapon or "mace")
        b.weapon("book")
    elif c == "bard":
        b.body(torso_mat="primary", arms_mat="secondary", legs_mat="secondary")
        b.cape("secondary", length=0.75, z=-3.0)
        b.top("primary", lo=-0.1, hi=1.0, z=6.0, name="tunic")
        b.skirt("primary", length=0.45, flare=1.5, z=6.4)
        b.belt("leather", buckle="trim", u=0.3)
        b.sleeves("secondary", upper=1.0, lower=0.8, puff=0.6)
        b.pants("secondary")
        b.boots("leather", height=0.8, trim="trim")
        b.head()
        b.hat_feather("primary")
        b.weapon(v.weapon or "lute")
    else:
        raise ValueError(c)


def _offhand_dagger(b: Builder):
    sc = 0.48 if b.side else 1.0
    z = -0.6 if b.side else 9.5
    L = 15 * sc
    b.add("offhand", "capsule", "leather2", z, {"a": (-2 * sc, 0), "b": (2 * sc, 0), "r0": 1 * sc + 0.3}, bevel=1,
          tone=-1 if b.side else 0)
    b.add("offhand", "poly", "metal", z + 0.05, {"pts": [(2.6 * sc, -1.6 * sc - 0.4), (L, -0.8 * sc - 0.2), (L + 2.5 * sc, 0.6 * sc),
                                                          (L - 1 * sc, 1.6 * sc + 0.4), (2.6 * sc, 1.6 * sc + 0.4)]},
          bevel=1, tone=-1 if b.side else 0)


# --------------------------------------------------------------------------- faces
def make_face(v: Variant, view: str):
    eye_rgb = _hex(v.eye)
    eye_dark = tuple(int(c * 0.55) for c in eye_rgb)
    skin = _hex(v.skin)
    blush = tuple(min(255, int(c)) for c in (skin[0], int(skin[1] * 0.78), int(skin[2] * 0.78)))
    mouth = (int(skin[0] * 0.78), int(skin[1] * 0.48), int(skin[2] * 0.5))
    brow = tuple(int(c * 0.55) for c in _hex(v.hair))
    pal = {"k": (52, 30, 46), "w": (250, 246, 240), "i": eye_rgb, "I": eye_dark, "h": (255, 255, 255),
           "b": brow, "m": mouth, "s": tuple(int(c * 0.82) for c in skin), "r": blush}

    def face(img, world, ctx, pix_id, parts):
        origin, ang, _ = world["head"]
        face_ids = {i for i, p in enumerate(parts) if p.name in ("face", "jaw")}
        masked = ctx.get("mask", False)

        def on_face(y, x):
            return pix_id[y, x] in face_ids

        expr = ctx.get("expr", "normal")
        cu, cv = ctx["head_c"]
        # head local (u up, v right) -> world; head bone angle ~ -90
        r = math.radians(ang)
        ax = (math.cos(r), math.sin(r))
        ay = (-math.sin(r), math.cos(r))

        def P(u, vv):
            return (origin[0] + ax[0] * u + ay[0] * vv, origin[1] + ax[1] * u + ay[1] * vv)

        if view == "side":
            ex, ey = P(cu - 0.6, cv + 1.4)
            ex, ey = round(ex), round(ey)
            if expr == "hurt":
                stamp(img, ex - 2, ey - 1, ["k..k", ".kk."], pal, on_face)
            elif expr == "dead":
                stamp(img, ex - 2, ey - 1, ["k.k.", ".k..", "k.k."], pal, on_face)
            elif expr == "happy":
                stamp(img, ex - 2, ey - 1, [".k..k", "k.kk.k"], pal, on_face)
            else:
                stamp(img, ex - 2, ey - 2, ["k.kk", "i.wi", "I.iI"], pal, on_face)
            if not masked:
                stamp(img, ex - 2, ey + 1, ["r"], pal, on_face)
                mx, my = P(cu - 3.6, cv + 3.6)
                stamp(img, round(mx) - 1, round(my), ["m"] if expr != "happy" else ["mm"], pal, on_face)
        else:
            ex, ey = P(cu - 1.5, cv)
            cx, cy = round(ex), round(ey)
            if expr in ("normal", "happy"):
                eye = [".kkkk", "kwiiI", "kwhiI", ".wiiI", "..II."]
                eye_far = ["kkkk", "Iiiw", "Ihiw", ".II."]
                stamp(img, cx - 6, cy - 4, ["bbb."], pal, on_face)
                stamp(img, cx + 2, cy - 4, [".bbbb"], pal, on_face)
                stamp(img, cx - 6, cy - 2, eye_far, pal, on_face)
                stamp(img, cx + 2, cy - 2, eye, pal, on_face)
            if not masked:
                stamp(img, cx, cy + 3, ["s"], pal, on_face)
                stamp(img, cx - 1, cy + 6, ["mm"], pal, on_face)
    return face


def _hex(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def build_rig(template: str, v: Variant) -> Rig:
    m = TEMPLATES[template]
    b = Builder(m, v)
    build_class(b)
    rig = Rig(skeleton_for(m), b.parts, materials(v), make_face(v, m["view"]))
    rig.template = m
    return rig


def face_ctx(rig, **kw):
    m = rig.template
    ctx = {"head_c": m["head_c"], "mask": any(p.name == "mask" for p in rig.parts)}
    ctx.update(kw)
    return ctx
