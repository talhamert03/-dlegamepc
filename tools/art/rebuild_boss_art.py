#!/usr/bin/env python3
"""Large boss paintings for the intro cinematic and other big views: game/assets/hd/boss_art/<id>.png at the
raw painting's own size (cap 1024 px). Battle sprites stay at 360 px (game/assets/hd/enemies).
  python3 tools/art/rebuild_boss_art.py
"""
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from import_ai_art import SRC, OUT, ROOT, clean_alpha, trim  # noqa: E402

MAX_H = 1024
# only the bosses shown large (intro cinematic); add ids here when another big view needs one
BIG = ["goblin_king", "ice_witch", "pharaoh", "demon_hunter"]


def main():
    bosses = json.load(open(os.path.join(ROOT, "game", "data", "enemies.json"))).get("bosses", {})
    out = os.path.join(OUT, "boss_art")
    os.makedirs(out, exist_ok=True)
    n = 0
    for bid in BIG:
        raw = os.path.join(SRC, "raw", "enemies", bid + ".png")
        if not os.path.exists(raw):
            continue
        img = trim(clean_alpha(Image.open(raw).convert("RGBA")))
        if img.height > MAX_H:
            img = img.resize((round(img.width * MAX_H / img.height), MAX_H), Image.LANCZOS)
        img.save(os.path.join(out, bid + ".png"), optimize=True)
        n += 1
    print("boss art", n, "of", len(BIG))


if __name__ == "__main__":
    main()
