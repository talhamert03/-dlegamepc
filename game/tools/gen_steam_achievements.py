#!/usr/bin/env python3
"""Steamworks achievement kit: one 256x256 icon per achievement (earned + locked/grey version) and a CSV with
API name, display names and descriptions in English and Turkish, ready to type into the Steamworks admin.

Run from the game folder:  python3 tools/gen_steam_achievements.py
Output: ../steam/achievements/*.jpg and ../steam/achievements/achievements.csv
"""
import csv
import json
import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageOps

OUT = "../steam/achievements"
ICON_DIR = "assets/ui_hd"
S = 256

# category -> (emblem icon, gem colour)
CAT = {
    "kills": ("sword", (210, 60, 50)), "gold": ("gold", (240, 190, 70)), "legendaries": ("star", (255, 140, 40)),
    "mythics": ("star", (255, 70, 100)), "combines": ("hammer", (170, 110, 255)), "bosses": ("skull", (200, 60, 60)),
    "deaths": ("skull", (120, 120, 140)), "offline": ("clock", (110, 170, 255)), "playtime": ("clock", (110, 200, 160)),
    "boss": ("skull", (220, 70, 60)), "level": ("star", (120, 220, 120)), "heroes": ("people", (90, 160, 255)),
    "party": ("people", (90, 200, 255)), "enhance": ("hammer", (255, 170, 60)), "stars": ("star", (255, 210, 80)),
    "advance": ("crown", (200, 140, 255)), "faction": ("flag", (220, 90, 80)), "guild": ("flag", (230, 180, 80)),
    "zone": ("map", (110, 200, 120)),
}


def medallion(icon_name, gem):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S / 2
    # dark backdrop so the round medal reads on Steam's square tile
    bg = Image.new("RGBA", (S, S), (24, 16, 12, 255))
    g = ImageDraw.Draw(bg)
    for k in range(40, 0, -1):
        a = int(4 + 2.2 * (40 - k))
        g.ellipse([c - k * 3.2, c - k * 3.2, c + k * 3.2, c + k * 3.2], fill=(gem[0] // 4 + a // 3, gem[1] // 5 + a // 4, gem[2] // 6 + a // 5, 255))
    img.alpha_composite(bg)
    # gold rim with notches
    d.ellipse([18, 18, S - 18, S - 18], fill=(60, 36, 14, 255))
    d.ellipse([24, 24, S - 24, S - 24], fill=(226, 180, 90, 255))
    d.ellipse([34, 34, S - 34, S - 34], fill=(150, 98, 38, 255))
    for i in range(24):
        a = i * math.tau / 24
        x, y = c + math.cos(a) * (c - 29), c + math.sin(a) * (c - 29)
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(255, 232, 160, 255))
    # inner field in the gem colour
    for k in range(60, 0, -1):
        t = k / 60
        col = (int(gem[0] * (0.35 + 0.65 * (1 - t))), int(gem[1] * (0.35 + 0.65 * (1 - t))), int(gem[2] * (0.35 + 0.65 * (1 - t))), 255)
        r = 84 * t
        d.ellipse([c - r, c - r - 4 * (1 - t), c + r, c + r - 4 * (1 - t)], fill=col)
    d.ellipse([c - 86, c - 86, c + 86, c + 86], outline=(40, 20, 8, 255), width=4)
    # emblem
    path = os.path.join(ICON_DIR, icon_name + ".png")
    if os.path.exists(path):
        ic = Image.open(path).convert("RGBA").resize((118, 118), Image.LANCZOS)
        sh = Image.new("RGBA", ic.size, (0, 0, 0, 0))
        sh.putalpha(ic.getchannel("A").point(lambda v: int(v * 0.6)))
        img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(4)), (int(c - 59) + 3, int(c - 59) + 5))
        img.alpha_composite(ic, (int(c - 59), int(c - 59)))
    # gloss
    gl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(gl).ellipse([c - 70, c - 82, c + 70, c - 10], fill=(255, 255, 255, 34))
    img.alpha_composite(gl.filter(ImageFilter.GaussianBlur(6)))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    data = json.load(open("data/achievements.json"))["achievements"]
    rows = []
    for a in data:
        cond = a.get("cond", {})
        key = cond.get("stat") or cond.get("type", "")
        icon, gem = CAT.get(key, ("star", (200, 170, 90)))
        img = medallion(icon, gem).convert("RGB")
        img.save(os.path.join(OUT, a["id"] + ".jpg"), quality=92)
        grey = ImageOps.grayscale(img).point(lambda v: int(v * 0.55)).convert("RGB")
        grey.save(os.path.join(OUT, a["id"] + "_locked.jpg"), quality=92)
        rows.append([a["id"], a["name"]["en"], a["desc"]["en"], a["name"]["tr"], a["desc"]["tr"],
                     a["id"] + ".jpg", a["id"] + "_locked.jpg"])
    with open(os.path.join(OUT, "achievements.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["api_name", "name_en", "desc_en", "name_tr", "desc_tr", "icon", "icon_locked"])
        w.writerows(rows)
    print("wrote %d achievements to %s" % (len(rows), OUT))


if __name__ == "__main__":
    main()
