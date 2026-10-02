#!/usr/bin/env python3
"""Render all enemy, boss and summon sprite sheets from game/data/enemies.json.

Usage: python3 tools/art/build_enemies.py [id ...]
"""
import json
import os
import sys
from multiprocessing import Pool

from PIL import ImageOps

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from enemies import render_enemy  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GAME = os.path.join(ROOT, "game")
OUT = os.path.join(GAME, "assets/sprites/enemies")

SUMMONS = {
    "summon_skeleton": {"rig": "skeleton", "weapon": "sword", "color": "#D8E8C8", "glow": "#8CFF7A"},
    "summon_wolf": {"rig": "quad", "kind": "wolf", "color": "#8FA0B8"},
    "summon_golem": {"rig": "golem", "kind": "bone", "color": "#E6DDC6", "scale": 1.1},
}


def job(args):
    eid, vis, villains, heroes, face_right = args
    sheet, info = render_enemy(vis, villains, heroes)
    if face_right:
        # summons fight for the heroes: mirror back so they face right
        W = info["frame_w"]
        n = sheet.width // W
        from PIL import Image
        out = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
        for i in range(n):
            out.paste(ImageOps.mirror(sheet.crop((i * W, 0, (i + 1) * W, info["frame_h"]))), (i * W, 0))
        sheet = out
        info["root"] = [W - 1 - info["root"][0], info["root"][1]]
    sheet.save(os.path.join(OUT, f"{eid}.png"))
    return eid, info


def main():
    os.makedirs(OUT, exist_ok=True)
    data = json.load(open(os.path.join(GAME, "data/enemies.json"), encoding="utf-8"))
    heroes = json.load(open(os.path.join(GAME, "data/heroes.json"), encoding="utf-8"))["heroes"]
    villains = data.get("villains", {})
    jobs = []
    for eid, e in list(data["enemies"].items()) + list(data["bosses"].items()):
        jobs.append((eid, e["visual"], villains, heroes, False))
    for sid, vis in SUMMONS.items():
        jobs.append((sid, vis, villains, heroes, True))
    only = set(sys.argv[1:])
    if only:
        jobs = [j for j in jobs if j[0] in only]
    meta_path = os.path.join(OUT, "anims.json")
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {"sheets": {}}
    with Pool(4) as pool:
        for eid, info in pool.imap_unordered(job, jobs):
            meta["sheets"][eid] = info
            print(eid, info["frame_w"], info["frame_h"], flush=True)
    json.dump(meta, open(meta_path, "w"), indent=1)


if __name__ == "__main__":
    main()
