#!/usr/bin/env python3
"""Rebuild the hero full-body portraits (game/assets/hd/portraits) from the raw paintings at native size.

The importer scaled them to 560 px tall; the title poster, the recruit card and the Hero window bust crop
show them much larger than that at 4K. This keeps the painting's own resolution (about 1000 px tall).
  python3 tools/art/rebuild_portraits.py
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from import_ai_art import SRC, OUT, clean_alpha, trim  # noqa: E402

MAX_H = 1024


def main():
    raw_dir = os.path.join(SRC, "raw", "heroes")
    n = 0
    for f in sorted(os.listdir(raw_dir)):
        if not f.endswith(".png"):
            continue
        img = trim(clean_alpha(Image.open(os.path.join(raw_dir, f)).convert("RGBA")))
        if img.height > MAX_H:
            img = img.resize((round(img.width * MAX_H / img.height), MAX_H), Image.LANCZOS)
        img.save(os.path.join(OUT, "portraits", f), optimize=True)
        n += 1
    print("portraits", n)


if __name__ == "__main__":
    main()
