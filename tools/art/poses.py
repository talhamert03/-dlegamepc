"""Poses and animations. All values are WORLD angles (degrees) for bones, which
are converted into parent-relative deltas against the rest skeleton."""
from __future__ import annotations

import math

# Weapon "families" drive stance and attack animations
FAMILY = {
    "sword": "blade", "mace": "blade", "axe": "heavy", "greatsword": "heavy",
    "dagger": "dagger", "bow": "bow", "staff": "staff", "scythe": "staff", "lute": "lute",
}

CLASS_WEAPON = {
    "knight": "sword", "berserker": "axe", "archer": "bow", "assassin": "dagger",
    "mage": "staff", "necromancer": "scythe", "cleric": "mace", "bard": "lute",
}


def world_to_delta(skel, world_angles: dict):
    """Convert desired world angles into deltas for Skeleton.solve()."""
    rest_world = {}
    deltas = {}
    for name in skel.order:
        b = skel.bones[name]
        parent_world = 0.0 if b.parent is None else rest_world[b.parent]
        if name in world_angles:
            target = world_angles[name]
            deltas[name] = target - (parent_world + b.angle)
            rest_world[name] = target
        else:
            rest_world[name] = parent_world + b.angle
    return deltas


def lerp(a, b, t):
    return a + (b - a) * t


def blend(p0: dict, p1: dict, t: float):
    out = dict(p0)
    for k, v in p1.items():
        if k.startswith("_"):
            continue
        out[k] = lerp(p0.get(k, v), v, t)
    return out


# --------------------------------------------------------------------------- side view (battle)
def base_side(fam):
    """World angles for the idle stance per weapon family."""
    p = {
        "torso": -90, "head": -90,
        "thigh_n": 80, "shin_n": 88, "foot_n": 0,
        "thigh_f": 100, "shin_f": 94, "foot_f": 2,
        "uarm_f": 100, "larm_f": 70, "hand_f": 70,
        "uarm_n": 78, "larm_n": 40, "hand_n": 40,
        "cape": 96, "tail": 110,
    }
    if fam == "blade":
        p.update({"uarm_n": 70, "larm_n": 5, "hand_n": 5, "weapon": -55, "uarm_f": 75, "larm_f": 20, "offhand": -90})
    elif fam == "heavy":
        p.update({"uarm_n": 40, "larm_n": -60, "hand_n": -60, "weapon": -140, "uarm_f": 95, "larm_f": 60})
    elif fam == "dagger":
        p.update({"torso": -84, "uarm_n": 60, "larm_n": 10, "hand_n": 10, "weapon": 30,
                  "uarm_f": 105, "larm_f": 40, "offhand": 60, "thigh_n": 70, "shin_n": 95, "thigh_f": 110})
    elif fam == "bow":
        p.update({"uarm_n": 20, "larm_n": 0, "hand_n": 0, "weapon": -90, "uarm_f": 60, "larm_f": 0})
    elif fam == "staff":
        p.update({"uarm_n": 60, "larm_n": -20, "hand_n": -20, "weapon": -95, "uarm_f": 95, "larm_f": 70})
    elif fam == "lute":
        p.update({"uarm_n": 70, "larm_n": 20, "hand_n": 20, "weapon": -150, "uarm_f": 60, "larm_f": -10})
    return p


def anim_side(fam):
    base = base_side(fam)
    A = {}
    # idle: breathing bob + subtle arm motion
    A["idle"] = []
    for i, (dy, da) in enumerate([(0, 0), (0, 2), (1, 4), (0, 2)]):
        p = dict(base)
        p["_root"] = (0, dy)
        for k in ("uarm_n", "uarm_f"):
            p[k] = base[k] + da * 0.6
        p["cape"] = base["cape"] - da
        p["tail"] = base["tail"] - da
        A["idle"].append(p)
    # run: 6 frame cycle
    A["run"] = []
    for i in range(6):
        ph = i / 6 * 2 * math.pi
        sw = math.sin(ph)
        p = dict(base)
        p["torso"] = -84
        p["head"] = -86
        p["thigh_n"] = 90 - 38 * sw
        p["thigh_f"] = 90 + 38 * sw
        p["shin_n"] = p["thigh_n"] + 10 + 45 * max(0, math.sin(ph + 1.2))
        p["shin_f"] = p["thigh_f"] + 10 + 45 * max(0, math.sin(ph + math.pi + 1.2))
        p["foot_n"] = p["shin_n"] - 90
        p["foot_f"] = p["shin_f"] - 90
        if fam in ("bow", "lute", "staff"):
            p["uarm_f"] = base["uarm_f"] - 30 * sw
        else:
            p["uarm_f"] = 90 - 35 * sw
            p["larm_f"] = p["uarm_f"] - 50
        p["cape"] = 130 + 8 * sw
        p["tail"] = 150 + 6 * sw
        p["_root"] = (0, -1 if i in (1, 4) else 0)
        A["run"].append(p)
    # attack per family (impact frame = 3)
    A["attack"] = attack_frames(fam, base)
    A["skill"] = skill_frames(fam, base)
    # hit
    h1 = dict(base); h1["torso"] = -100; h1["head"] = -108; h1["_root"] = (-1, 0); h1["_expr"] = "hurt"
    h2 = dict(base); h2["torso"] = -96; h2["head"] = -100; h2["_root"] = (-1, 0); h2["_expr"] = "hurt"
    A["hit"] = [h1, h2]
    # death: fall backwards
    A["death"] = []
    for i in range(6):
        t = min(1.0, i / 4)
        p = dict(base)
        p["torso"] = lerp(-90, -170, t)
        p["head"] = lerp(-90, -175, t)
        p["thigh_n"] = lerp(80, 10, t)
        p["thigh_f"] = lerp(100, 20, t)
        p["shin_n"] = lerp(88, 0, t)
        p["shin_f"] = lerp(94, 5, t)
        p["uarm_n"] = lerp(base["uarm_n"], 200, t)
        p["uarm_f"] = lerp(base["uarm_f"], 180, t)
        p["cape"] = lerp(96, 10, t)
        p["_root"] = (lerp(0, -4, t), lerp(0, 9, t))
        p["_expr"] = "dead" if i >= 2 else "hurt"
        A["death"].append(p)
    # victory: weapon raised
    A["victory"] = []
    for i, dy in enumerate([0, -1, -2, -1]):
        p = dict(base)
        p["uarm_n"] = -60
        p["larm_n"] = -80
        p["hand_n"] = -80
        p["weapon"] = {"bow": -90, "lute": -60, "staff": -100}.get(fam, -100)
        p["_root"] = (0, dy)
        p["_expr"] = "happy"
        A["victory"].append(p)
    return A


def attack_frames(fam, base):
    F = []
    def f(**kw):
        p = dict(base)
        p.update({k: v for k, v in kw.items() if not k.startswith("r_")})
        if "r_root" in kw:
            p["_root"] = kw["r_root"]
        F.append(p)
    if fam in ("blade", "heavy"):
        f(uarm_n=-20, larm_n=-80, hand_n=-80, weapon=-140, torso=-96)                 # wind up
        f(uarm_n=-60, larm_n=-110, hand_n=-110, weapon=-170, torso=-100)              # raised
        f(uarm_n=10, larm_n=-30, hand_n=-30, weapon=-60, torso=-86, r_root=(1, 0))     # swing
        f(uarm_n=50, larm_n=40, hand_n=40, weapon=20, torso=-80, r_root=(2, 0))        # impact
        f(uarm_n=70, larm_n=70, hand_n=70, weapon=60, torso=-82, r_root=(1, 0))        # follow through
        f(uarm_n=72, larm_n=20, hand_n=20, weapon=-30, torso=-88)                       # recover
    elif fam == "dagger":
        f(uarm_n=110, larm_n=150, hand_n=150, weapon=120, torso=-95, r_root=(-1, 0))
        f(uarm_n=90, larm_n=130, hand_n=130, weapon=90, torso=-92)
        f(uarm_n=20, larm_n=0, hand_n=0, weapon=-10, torso=-78, r_root=(3, 0))
        f(uarm_n=0, larm_n=-5, hand_n=-5, weapon=-15, torso=-75, r_root=(4, 0))
        f(uarm_n=30, larm_n=10, hand_n=10, weapon=20, torso=-80, r_root=(2, 0))
        f(uarm_n=60, larm_n=10, hand_n=10, weapon=30, torso=-84)
    elif fam == "bow":
        f(uarm_n=10, larm_n=0, hand_n=0, weapon=-90, uarm_f=40, larm_f=10)
        f(uarm_n=0, larm_n=0, hand_n=0, weapon=-90, uarm_f=10, larm_f=170, torso=-94)
        f(uarm_n=0, larm_n=0, hand_n=0, weapon=-90, uarm_f=0, larm_f=175, torso=-96)
        f(uarm_n=0, larm_n=0, hand_n=0, weapon=-90, uarm_f=40, larm_f=60, torso=-92, r_root=(-1, 0))
        f(uarm_n=10, larm_n=0, hand_n=0, weapon=-90, uarm_f=50, larm_f=20)
        f(uarm_n=18, larm_n=0, hand_n=0, weapon=-90, uarm_f=60, larm_f=0)
    elif fam == "staff":
        f(uarm_n=40, larm_n=-40, hand_n=-40, weapon=-110, torso=-94)
        f(uarm_n=-10, larm_n=-60, hand_n=-60, weapon=-120, torso=-98)
        f(uarm_n=-30, larm_n=-50, hand_n=-50, weapon=-100, torso=-98)
        f(uarm_n=20, larm_n=-5, hand_n=-5, weapon=-45, torso=-84, r_root=(1, 0))
        f(uarm_n=35, larm_n=-10, hand_n=-10, weapon=-60, torso=-86)
        f(uarm_n=55, larm_n=-20, hand_n=-20, weapon=-90, torso=-90)
    elif fam == "lute":
        for k, d in enumerate([0, 15, -10, 20, -5, 0]):
            f(uarm_n=70 + d, larm_n=20 + d * 1.5, hand_n=20 + d * 1.5, r_root=(0, -1 if k in (2, 3) else 0))
    return F


def skill_frames(fam, base):
    F = []
    if fam in ("blade", "heavy", "dagger"):
        # leaping overhead strike
        seq = [
            dict(uarm_n=-40, larm_n=-100, hand_n=-100, weapon=-160, torso=-100, _root=(0, 1), thigh_n=60, shin_n=100, thigh_f=120, shin_f=130),
            dict(uarm_n=-80, larm_n=-120, hand_n=-120, weapon=-190, torso=-104, _root=(1, -4), thigh_n=50, shin_n=110, thigh_f=110, shin_f=150),
            dict(uarm_n=-70, larm_n=-110, hand_n=-110, weapon=-180, torso=-100, _root=(3, -6), thigh_n=45, shin_n=110, thigh_f=105, shin_f=150),
            dict(uarm_n=20, larm_n=10, hand_n=10, weapon=-10, torso=-80, _root=(5, -2)),
            dict(uarm_n=70, larm_n=80, hand_n=80, weapon=70, torso=-70, _root=(5, 1), thigh_n=60, shin_n=110),
            dict(uarm_n=70, larm_n=40, hand_n=40, weapon=0, torso=-84, _root=(2, 0)),
        ]
    elif fam == "bow":
        seq = [
            dict(uarm_n=-20, larm_n=-30, hand_n=-30, weapon=-120, uarm_f=-10, larm_f=150, torso=-96),
            dict(uarm_n=-35, larm_n=-40, hand_n=-40, weapon=-130, uarm_f=-30, larm_f=160, torso=-100, _root=(0, -1)),
            dict(uarm_n=-35, larm_n=-40, hand_n=-40, weapon=-130, uarm_f=-40, larm_f=170, torso=-102, _root=(0, -2)),
            dict(uarm_n=-30, larm_n=-40, hand_n=-40, weapon=-130, uarm_f=20, larm_f=60, torso=-98, _root=(-1, -1)),
            dict(uarm_n=0, larm_n=-10, hand_n=-10, weapon=-100, uarm_f=50, larm_f=30, torso=-92),
            dict(uarm_n=15, larm_n=0, hand_n=0, weapon=-90, uarm_f=60, larm_f=0),
        ]
    elif fam == "staff":
        seq = [
            dict(uarm_n=0, larm_n=-60, hand_n=-60, weapon=-100, uarm_f=40, larm_f=-20, torso=-94),
            dict(uarm_n=-60, larm_n=-90, hand_n=-90, weapon=-95, uarm_f=-20, larm_f=-60, torso=-100, _root=(0, -1)),
            dict(uarm_n=-80, larm_n=-95, hand_n=-95, weapon=-92, uarm_f=-40, larm_f=-80, torso=-102, _root=(0, -2)),
            dict(uarm_n=-80, larm_n=-95, hand_n=-95, weapon=-92, uarm_f=-40, larm_f=-80, torso=-102, _root=(0, -2)),
            dict(uarm_n=20, larm_n=-10, hand_n=-10, weapon=-40, uarm_f=30, larm_f=0, torso=-84, _root=(1, 0)),
            dict(uarm_n=55, larm_n=-20, hand_n=-20, weapon=-90, torso=-90),
        ]
    else:  # lute
        seq = [dict(uarm_n=70 + d, larm_n=20 + d * 2, hand_n=20 + d * 2, torso=-90 - d * 0.3, _root=(0, r))
               for d, r in [(0, 0), (25, -1), (-15, -2), (30, -2), (-10, -1), (0, 0)]]
    for kw in seq:
        p = dict(base)
        p.update(kw)
        F.append(p)
    return F


# --------------------------------------------------------------------------- portrait (front view)
def portrait_pose(cls):
    p = {"torso": -90, "head": -90}
    if cls == "knight":
        p.update({"uarm_n": 100, "larm_n": 60, "uarm_f": 80, "larm_f": 40, "weapon": -60, "offhand": -90,
                  "thigh_n": 96, "thigh_f": 84})
    elif cls == "berserker":
        p.update({"uarm_f": -30, "larm_f": -150, "weapon": -200, "uarm_n": 100, "larm_n": 80, "thigh_n": 98, "thigh_f": 82})
    elif cls == "archer":
        p.update({"uarm_n": 100, "larm_n": 72, "uarm_f": 76, "larm_f": 54, "weapon": 100})
    elif cls == "assassin":
        p.update({"uarm_n": 110, "larm_n": 150, "uarm_f": 70, "larm_f": 30, "weapon": 70, "offhand": 200,
                  "thigh_n": 100, "thigh_f": 80})
    elif cls in ("mage", "necromancer"):
        p.update({"uarm_f": 60, "larm_f": -40, "weapon": -95, "uarm_n": 105, "larm_n": 80})
    elif cls == "cleric":
        p.update({"uarm_f": 75, "larm_f": 40, "weapon": 100, "uarm_n": 70, "larm_n": -20, "offhand": -10})
    elif cls == "bard":
        p.update({"uarm_f": 70, "larm_f": 120, "weapon": -150, "uarm_n": 60, "larm_n": 0})
    return p
