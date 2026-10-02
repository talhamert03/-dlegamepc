#!/usr/bin/env python3
"""Generate hero battle sprite sheets, portraits and head icons from game/data/heroes.json.

Outputs (relative to game/):
  assets/sprites/heroes/<id>.png      all battle frames in one horizontal strip (64x56 each)
  assets/portraits/<id>.png           96x144 portrait
  assets/sprites/heroes/icons/<id>.png 20x20 head icon
  assets/sprites/heroes/anims.json    animation table (shared by every hero)
"""
import json
import os
import sys
from multiprocessing import Pool

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from chars import Variant, build_rig, face_ctx  # noqa: E402
from pixelrig import render, to_image  # noqa: E402
from poses import CLASS_WEAPON, FAMILY, anim_side, portrait_pose, world_to_delta  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GAME = os.path.join(ROOT, "game")
ANIMS = ["idle", "run", "attack", "skill", "hit", "death", "victory"]
FPS = {"idle": 6, "run": 10, "attack": 12, "skill": 10, "hit": 10, "death": 8, "victory": 6}
LOOP = {"idle": True, "run": True, "victory": True}
IMPACT = {"attack": 3, "skill": 3}


def variant_for(h):
    vis = dict(h.get("visual", {}))
    return Variant(cls=h["class"], **vis)


def weapon_family(h):
    w = h.get("visual", {}).get("weapon") or CLASS_WEAPON[h["class"]]
    return FAMILY[w]


def render_hero(h):
    v = variant_for(h)
    rig = build_rig("battle", v)
    m = rig.template
    A = anim_side(weapon_family(h))
    frames = []
    for an in ANIMS:
        for p in A[an]:
            d = world_to_delta(rig.skeleton, {k: x for k, x in p.items() if not k.startswith("_")})
            a, world = render(rig, d, (m["W"], m["H"]), ss=4, root_offset=p.get("_root", (0, 0)),
                              face_ctx=face_ctx(rig, expr=p.get("_expr", "normal")))
            frames.append(to_image(a))
            if an == "idle" and len(frames) == 1:
                hx, hy = world["head"][0]
    sheet = Image.new("RGBA", (m["W"] * len(frames), m["H"]), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * m["W"], 0))
    os.makedirs(os.path.join(GAME, "assets/sprites/heroes/icons"), exist_ok=True)
    sheet.save(os.path.join(GAME, f"assets/sprites/heroes/{h['id']}.png"))
    # head icon: crop around the head of idle frame 0
    cu = m["head_c"][0]
    cx, cy = int(round(hx)), int(round(hy - cu))
    icon = frames[0].crop((cx - 10, cy - 11, cx + 10, cy + 9))
    icon.save(os.path.join(GAME, f"assets/sprites/heroes/icons/{h['id']}.png"))
    # portrait
    prig = build_rig("portrait", v)
    pm = prig.template
    pose = world_to_delta(prig.skeleton, portrait_pose(h["class"]))
    a, _ = render(prig, pose, (pm["W"], pm["H"]), ss=4, face_ctx=face_ctx(prig))
    os.makedirs(os.path.join(GAME, "assets/portraits"), exist_ok=True)
    to_image(a).save(os.path.join(GAME, f"assets/portraits/{h['id']}.png"))
    return h["id"], len(frames)


def anim_table():
    A = anim_side("blade")
    out = {"frame_w": 64, "frame_h": 56, "anims": {}}
    start = 0
    for an in ANIMS:
        n = len(A[an])
        out["anims"][an] = {"start": start, "count": n, "fps": FPS[an], "loop": LOOP.get(an, False),
                            "impact": IMPACT.get(an, -1)}
        start += n
    return out


def main():
    data = json.load(open(os.path.join(GAME, "data/heroes.json"), encoding="utf-8"))
    heroes = data["heroes"]
    only = set(sys.argv[1:])
    if only:
        heroes = [h for h in heroes if h["id"] in only]
    os.makedirs(os.path.join(GAME, "assets/sprites/heroes"), exist_ok=True)
    with Pool(4) as pool:
        for hid, n in pool.imap_unordered(render_hero, heroes):
            print(hid, n, flush=True)
    json.dump(anim_table(), open(os.path.join(GAME, "assets/sprites/heroes/anims.json"), "w"), indent=1)


if __name__ == "__main__":
    main()
