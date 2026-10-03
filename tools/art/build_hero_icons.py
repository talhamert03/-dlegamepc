#!/usr/bin/env python3
"""Re-cut the hero head icons from the HD portraits -> game/assets/hd/icons/<id>.png (128 px).

Uses the face finder of import_ai_art.head_icon (skin-tone cluster) with the manual centres in
art_src/icon_overrides.json for heroes whose face it cannot find (pale skin, masks, skulls).
  python3 tools/art/build_hero_icons.py [id ...]
"""
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from import_ai_art import head_icon  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PORT = os.path.join(ROOT, "game", "assets", "hd", "portraits")
OUT = os.path.join(ROOT, "game", "assets", "hd", "icons")
OV = json.load(open(os.path.join(ROOT, "art_src", "icon_overrides.json")))

only = set(sys.argv[1:])
for f in sorted(os.listdir(PORT)):
    if not f.endswith(".png"):
        continue
    cid = f[:-4]
    if only and cid not in only:
        continue
    img = Image.open(os.path.join(PORT, f)).convert("RGBA")
    head_icon(img, center=OV.get(cid)).save(os.path.join(OUT, cid + ".png"), optimize=True)
    print("ok", cid)
