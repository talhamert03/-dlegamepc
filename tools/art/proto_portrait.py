"""Prototype: archer portrait 96x144 to validate the renderer quality."""
import sys
sys.path.insert(0, ".")
from pixelrig import *

W, H = 96, 144

bones = [
    Bone("pelvis", None, 0, 0),
    Bone("torso", "pelvis", 30, -90),
    Bone("head", "torso", 0, 0, (33, 1)),
    Bone("thigh_l", "pelvis", 33, 92, (-5, 0)),
    Bone("shin_l", "thigh_l", 31, 0, (33, 0)),
    Bone("foot_l", "shin_l", 6, -80, (31, 0)),
    Bone("thigh_r", "pelvis", 33, 86, (5, 0)),
    Bone("shin_r", "thigh_r", 31, 2, (33, 0)),
    Bone("foot_r", "shin_r", 6, -95, (31, 0)),
    Bone("uarm_l", "torso", 21, 190, (27, -9)),
    Bone("larm_l", "uarm_l", 19, -18, (21, 0)),
    Bone("hand_l", "larm_l", 5, 0, (19, 0)),
    Bone("uarm_r", "torso", 21, 166, (27, 9)),
    Bone("larm_r", "uarm_r", 19, -22, (21, 0)),
    Bone("hand_r", "larm_r", 5, 0, (19, 0)),
    Bone("bow", "hand_r", 0, 46, (2, 0)),
]
sk = Skeleton(bones, (48, 72))

M = {
    "skin": mat("#F0C29E"),
    "hair": mat("#F2CC5E", shiny=True),
    "pink": mat("#E07BAF"),
    "white": mat("#F1E9EE"),
    "leather": mat("#8E5B3E"),
    "boot": mat("#B0738A"),
    "gold": mat("#E9B949", shiny=True),
    "wood": mat("#9A6440"),
    "string": mat("#EDE6D6", flat=0.8),
    "metal": mat("#BFC8D2", shiny=True),
    "eye": mat("#3E7BC9"),
    "feather": mat("#F4F1EA"),
}

P = []
def add(*a, **k):
    P.append(Part(*a, **k))

# ---- legs (left leg = screen left, nearer)
for side, z0, tone in (("l", 2, 0), ("r", 1, 0)):
    add(f"thigh_{side}", "capsule", "skin", z0, {"a": (0, 0), "b": (33, 0), "r0": 5.3, "r1": 3.7}, name=f"thigh_{side}")
    add(f"shin_{side}", "capsule", "boot", z0 + 0.2, {"a": (0, 0), "b": (31, 0), "r0": 3.9, "r1": 2.9}, name=f"shin_{side}")
    add(f"shin_{side}", "capsule", "boot", z0 + 0.3, {"a": (-1, 0), "b": (4, 0), "r0": 4.6, "r1": 4.3}, bevel=2.5)  # boot cuff
    add(f"shin_{side}", "capsule", "gold", z0 + 0.4, {"a": (2.5, -4.0), "b": (2.5, 4.0), "r0": 0.7}, bevel=1)
    add(f"foot_{side}", "capsule", "boot", z0 + 0.3, {"a": (-1, 0), "b": (6, 0), "r0": 3.0, "r1": 2.3})

# ---- torso
add("torso", "poly", "skin", 5, {"pts": [(0, -6.6), (13, -5.4), (25, -7.6), (31, -8.6), (31, 8.6), (25, 7.6), (13, 5.4), (0, 6.6)]}, bevel=6, name="torso")
add("torso", "ellipse", "skin", 4.9, {"c": (2, 0), "rx": 6, "ry": 8.2}, bevel=7)  # hips
# corset / chest armour
add("torso", "poly", "pink", 6, {"pts": [(14, -6.2), (24, -8.0), (27, -5), (25, 0), (27, 5), (24, 8.0), (14, 6.2), (16, 0)]}, bevel=3, name="chest")
add("torso", "poly", "gold", 6.2, {"pts": [(24, -7.8), (26.5, -4.8), (24.6, 0), (26.5, 4.8), (24, 7.8), (25.2, 4.8), (23.4, 0), (25.2, -4.8)]}, bevel=1)
add("torso", "ellipse", "gold", 6.3, {"c": (17, 0), "rx": 1.6, "ry": 1.6}, bevel=1.2)
add("torso", "poly", "white", 5.5, {"pts": [(11, -5.6), (15, -6.2), (15, 6.2), (11, 5.6)]}, bevel=2)
# belt + skirt
add("torso", "poly", "leather", 7, {"pts": [(7, -7.4), (10.5, -7.0), (10.5, 7.0), (7, 7.4)]}, bevel=1.5, name="belt")
add("torso", "ellipse", "gold", 7.2, {"c": (9, 1), "rx": 2.2, "ry": 2.2}, bevel=1.4)
add("torso", "poly", "pink", 6.8, {"pts": [(8, -7.8), (8, 7.8), (-9, 10.5), (-12, 4), (-8, 0), (-12, -4), (-9, -10)]}, bevel=2.5,
    stripes=(90, 5, 1, -2), name="skirt")
add("torso", "poly", "white", 6.7, {"pts": [(-8.6, -9.8), (-10.6, -10.2), (-10.6, 10.8), (-8.6, 10.5)]}, bevel=1)
# quiver behind
add("torso", "capsule", "leather", 0.5, {"a": (8, -6), "b": (34, -14), "r0": 3.2}, bevel=2)
for k, off in enumerate((-1.5, 0.5, 2.5)):
    add("torso", "capsule", "feather", 0.4, {"a": (34, -14 + off), "b": (40, -17 + off), "r0": 1.2}, bevel=1)
# neck
add("torso", "capsule", "skin", 4.8, {"a": (29, 1), "b": (34, 1), "r0": 3.0}, bevel=3)
# shoulder pad (left)
add("uarm_l", "ellipse", "pink", 9.5, {"c": (2, 0), "rx": 5.4, "ry": 4.8}, bevel=3, name="pad_l")
add("uarm_l", "poly", "gold", 9.6, {"pts": [(-2, -4.8), (-2, 4.8), (-0.6, 4.8), (-0.6, -4.8)]}, bevel=1)

# ---- arms
for side, z in (("l", 9), ("r", 8.5)):
    add(f"uarm_{side}", "capsule", "skin", z, {"a": (0, 0), "b": (21, 0), "r0": 3.0, "r1": 2.5})
    add(f"larm_{side}", "capsule", "skin", z + 0.1, {"a": (0, 0), "b": (19, 0), "r0": 2.5, "r1": 2.0})
    add(f"larm_{side}", "capsule", "leather", z + 0.2, {"a": (7, 0), "b": (18, 0), "r0": 2.9, "r1": 2.5}, bevel=2,
        stripes=(0, 4, 1, -2))
    add(f"hand_{side}", "ellipse", "skin", z + 0.3, {"c": (2.5, 0), "rx": 3.0, "ry": 2.3})

# ---- bow (in right hand)
add("bow", "capsule", "wood", 8.4, {"a": (-34, 6), "b": (0, 1), "r0": 1.4, "r1": 1.9}, bevel=1.4, name="bow_top")
add("bow", "capsule", "wood", 8.4, {"a": (0, 1), "b": (34, 6), "r0": 1.9, "r1": 1.4}, bevel=1.4, name="bow_bot")
add("bow", "capsule", "wood", 8.45, {"a": (-34, 6), "b": (-38, 2), "r0": 1.3, "r1": 0.9}, bevel=1)
add("bow", "capsule", "wood", 8.45, {"a": (34, 6), "b": (38, 2), "r0": 1.3, "r1": 0.9}, bevel=1)
add("bow", "capsule", "gold", 8.6, {"a": (-3, 1.4), "b": (3, 1.4), "r0": 2.1}, bevel=1.2)
add("bow", "capsule", "string", 8.3, {"a": (-38, 2.2), "b": (38, 2.2), "r0": 0.45}, bevel=1, line=False, cast=False)

# ---- head
add("head", "ellipse", "skin", 12, {"c": (-1.5, 0.5), "rx": 9.6, "ry": 8.2}, bevel=7, name="face")
add("head", "ellipse", "skin", 12.1, {"c": (-7.5, 1.2), "rx": 3.8, "ry": 5.6}, bevel=4, name="jaw")
# elf ear (screen left, near)
add("head", "poly", "skin", 12.5, {"pts": [(-1, -7.5), (5, -12.5), (0.5, -9.5), (-4, -7)]}, bevel=1.4, name="ear")
# hair back (long, to waist)
add("head", "poly", "hair", 3, {"pts": [(6, -9), (8.5, 0), (6, 9.5), (-6, 11.5), (-28, 12.5), (-44, 9), (-40, 2), (-44, -4),
                                        (-34, -10.5), (-12, -11.5), (-2, -10.5)]}, bevel=4, stripes=(90, 3, 1, -2), name="hair_back")
# hair top cap + bangs (u up, v right)
add("head", "poly", "hair", 13, {"pts": [(1, -10.4), (7, -10.4), (11, -7), (12.4, 0), (11, 7), (7, 10.2), (1.5, 10.4),
                                          (3.6, 7.6), (1.6, 5.8), (4.2, 4.2), (2.2, 2.2), (4.8, 0.6), (2.8, -1.4), (4.8, -3.4),
                                          (1.8, -5.6), (4.0, -7.4)]}, bevel=3.2, stripes=(95, 3, 1, -2), name="bangs")
add("head", "poly", "hair", 13.1, {"pts": [(3, 8.6), (2, 11.2), (-9, 11.0), (-14, 9.4), (-6, 8.8), (-1, 8.2)]}, bevel=1.8, stripes=(0, 3, 1, -2), name="side_lock")
add("head", "poly", "hair", 13.1, {"pts": [(3, -8.8), (2, -11.4), (-12, -11.6), (-17, -10.0), (-7, -9.0), (-1, -8.4)]}, bevel=1.8, stripes=(0, 3, 1, -2), name="side_lock2")
# circlet
add("head", "capsule", "gold", 13.4, {"a": (6.2, -9.8), "b": (8.2, 9.6), "r0": 0.75}, bevel=1, line=False)
add("head", "ellipse", "eye", 13.5, {"c": (7.4, 0.2), "rx": 1.3, "ry": 1.3}, bevel=1)


def face(img, world, ctx, pix_id, parts):
    origin, ang, _ = world["head"]
    face_ids = {i for i, p in enumerate(parts) if p.name in ("face", "jaw")}
    def on_face(y, x):
        return pix_id[y, x] in face_ids
    cx, cy = origin[0], origin[1]
    pal = {
        "k": (58, 32, 48), "w": (250, 246, 240), "i": (62, 123, 201), "I": (34, 64, 128),
        "h": (255, 255, 255), "b": (176, 120, 70), "m": (196, 92, 96), "s": (214, 150, 120),
    }
    eye = ["kkkk",
           "kwiI",
           ".whi",
           "..ii"]
    eye_far = ["kkk",
               "Iiw",
               "ihw",
               "ii."]
    # brows
    stamp(img, cx - 6, cy - 3, ["bbb."], pal, on_face)
    stamp(img, cx + 2, cy - 3, [".bbb"], pal, on_face)
    stamp(img, cx - 6, cy - 1, eye_far, pal, on_face)
    stamp(img, cx + 2, cy - 1, eye, pal, on_face)
    stamp(img, cx + 1, cy + 4, ["s"], pal, on_face)   # nose shadow
    stamp(img, cx - 1, cy + 6, ["mm"], pal, on_face)  # mouth


rig = Rig(sk, P, M, face)
pose = {}
img, world = render(rig, pose, (W, H), ss=4, face_ctx={})
im = to_image(img)
im.save("/tmp/claude-0/-home-user--dlegamepc/83754d3e-dfa8-5878-aa29-a40ad9936a1f/scratchpad/archer_portrait.png")
bg = Image.new("RGBA", (W, H), (40, 34, 44, 255))
bg.alpha_composite(im)
bg.resize((W * 4, H * 4), Image.NEAREST).save("/tmp/claude-0/-home-user--dlegamepc/83754d3e-dfa8-5878-aa29-a40ad9936a1f/scratchpad/archer_portrait_x4.png")
print("ok")
