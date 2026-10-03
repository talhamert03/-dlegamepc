#!/usr/bin/env python3
"""AI item icon sheets (6x6 on magenta) -> game/assets/hd/items/<type>_<a|b>.png (96 px, centred, transparent).

  sheet a = starter/low-tier look (tiers 0-2), sheet b = ornate high-tier look (tiers 3+)
  python3 tools/art/import_items.py
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from import_sheets import key_magenta, _cuts, _crop  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "art_src")
OUT = os.path.join(ROOT, "game", "assets", "hd", "items")
ORDER = ["sword", "greatsword", "axe", "mace", "dagger", "scythe",
         "bow", "crossbow", "staff", "wand", "orb", "tome",
         "lute", "flute", "shield", "quiver", "dagger_off", "helm_heavy",
         "helm_medium", "helm_light", "chest_heavy", "chest_medium", "chest_light", "gloves_heavy",
         "gloves_medium", "gloves_light", "boots_heavy", "boots_medium", "boots_light", "belt",
         "cape", "amulet", "ring", "charm", "gold", "gem"]
SIZE = 96
PAD = 5


def main():
    urls = json.load(open(os.path.join(SRC, "urls_items.json")))
    os.makedirs(OUT, exist_ok=True)
    for tag, url in urls.items():
        raw = os.path.join(SRC, "raw", "items", f"sheet_{tag}.png")
        if not os.path.exists(raw):
            subprocess.run(["curl", "-sSfL", "-o", raw, url], check=True)
        arr = key_magenta(Image.open(raw))
        mask = arr[..., 3] > 30
        rows = _cuts(mask.sum(axis=1), 6)
        for r in range(6):
            cols = _cuts(mask[rows[r]:rows[r + 1]].sum(axis=0), 6)
            for c in range(6):
                cell = _crop(arr[rows[r]:rows[r + 1], cols[c]:cols[c + 1]].copy())
                if cell is None:
                    continue
                im = Image.fromarray(cell, "RGBA")
                k = (SIZE - PAD * 2) / max(im.width, im.height)
                im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
                canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
                canvas.alpha_composite(im, ((SIZE - im.width) // 2, (SIZE - im.height) // 2))
                canvas.save(os.path.join(OUT, f"{ORDER[r * 6 + c]}_{tag}.png"), optimize=True)
    print("ok", len(os.listdir(OUT)))


if __name__ == "__main__":
    main()
