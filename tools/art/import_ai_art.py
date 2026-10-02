#!/usr/bin/env python3
"""Download + process AI-generated character art into game assets.

  python3 tools/art/import_ai_art.py heroes      # uses art_src/urls_heroes.json  {id: url}
  python3 tools/art/import_ai_art.py enemies     # uses art_src/urls_enemies.json

Raw downloads are kept in art_src/raw/<kind>/<id>.png. Outputs (game/assets/hd/):
  <kind>/<id>.png        battle sprite, trimmed, 360 px tall (drawn ~60 logical px, linear + mipmaps)
  portraits/<id>.png     heroes only, 720 px tall full-body portrait
  icons/<id>.png         heroes only, 128 px head crop
  meta.json              {kind: {id: {"w","h","foot_x"}}}  (foot_x = feet anchor in sprite px)
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "art_src")
OUT = os.path.join(ROOT, "game", "assets", "hd")
SPRITE_H = {"heroes": 360, "enemies": 360, "pets": 240}


def download(url, path):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return True
    os.makedirs(os.path.dirname(path), exist_ok=True)
    r = subprocess.run(["curl", "-sSfL", "-o", path, url], capture_output=True)
    return r.returncode == 0


def clean_alpha(img):
    a = np.array(img)
    alpha = a[:, :, 3]
    alpha[alpha < 24] = 0
    a[:, :, 3] = alpha
    return Image.fromarray(a, "RGBA")


def trim(img, pad=4):
    bbox = img.getchannel("A").getbbox()
    if not bbox:
        return img
    x0, y0, x1, y1 = bbox
    return img.crop((max(0, x0 - pad), max(0, y0 - pad), min(img.width, x1 + pad), min(img.height, y1 + pad)))


def scale_h(img, h):
    w = max(1, round(img.width * h / img.height))
    return img.resize((w, h), Image.LANCZOS)


def foot_x(img):
    """x of the feet: alpha centre of mass over the bottom 8% rows."""
    a = np.array(img.getchannel("A"), dtype=float)
    rows = a[int(a.shape[0] * 0.92):, :]
    if rows.sum() <= 0:
        return img.width / 2
    xs = np.arange(a.shape[1])
    return float((rows.sum(axis=0) * xs).sum() / rows.sum())


def head_icon(img, size=128, center=None):
    """Square crop centred on the face: centroid of skin-toned pixels in the upper part of the figure
    (or an explicit (x, y) fraction from art_src/icon_overrides.json)."""
    arr = np.array(img).astype(int)
    h = arr.shape[0]
    if center:
        side = int(h * 0.2)
        cx, cy = center[0] * img.width, center[1] * h
        x0, y0 = int(cx - side / 2), int(max(0, cy - side * 0.45))
        canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        canvas.paste(img.crop((x0, y0, x0 + side, y0 + side)), (0, 0))
        return canvas.resize((size, size), Image.LANCZOS)
    top = arr[: int(h * 0.32)]
    r, g, b, a = top[..., 0], top[..., 1], top[..., 2], top[..., 3]
    skin = (a > 200) & (r > 150) & (r > g + 8) & (g > b + 4) & (r - b > 35) & (r - b < 140) & (g > 90)
    side = int(h * 0.2)
    if skin.sum() > 40:
        ys, xs = np.nonzero(skin)
        # the face is the densest skin cluster: take the median of the upper half of skin pixels
        order = np.argsort(ys)[: max(20, len(ys) // 2)]
        cx, cy = float(np.median(xs[order])), float(np.median(ys[order]))
    else:
        band = a[: int(h * 0.14)] if False else np.array(img.getchannel("A"), dtype=float)[: int(h * 0.14)]
        xs_ = np.arange(band.shape[1])
        cx = (band.sum(axis=0) * xs_).sum() / max(1.0, band.sum())
        cy = side * 0.45
    x0 = int(cx - side / 2)
    y0 = int(max(0, cy - side * 0.45))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img.crop((x0, y0, x0 + side, y0 + side)), (0, 0))
    return canvas.resize((size, size), Image.LANCZOS)


def main():
    kind = sys.argv[1] if len(sys.argv) > 1 else "heroes"
    urls = json.load(open(os.path.join(SRC, f"urls_{kind}.json")))
    meta_path = os.path.join(OUT, "meta.json")
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {}
    meta.setdefault(kind, {})
    for d in (kind, "portraits", "icons"):
        os.makedirs(os.path.join(OUT, d), exist_ok=True)
    only = set(sys.argv[2:])
    for cid, url in urls.items():
        if only and cid not in only:
            continue
        raw = os.path.join(SRC, "raw", kind, cid + ".png")
        if not download(url, raw):
            print("download failed", cid)
            continue
        img = trim(clean_alpha(Image.open(raw).convert("RGBA")))
        spr = scale_h(img, SPRITE_H[kind])
        spr.save(os.path.join(OUT, kind, cid + ".png"), optimize=True)
        meta[kind][cid] = {"w": spr.width, "h": spr.height, "foot_x": round(foot_x(spr), 1)}
        if kind == "heroes":
            scale_h(img, 560).save(os.path.join(OUT, "portraits", cid + ".png"), optimize=True)
            ov_path = os.path.join(SRC, "icon_overrides.json")
            ov = json.load(open(ov_path)) if os.path.exists(ov_path) else {}
            head_icon(img, center=ov.get(cid)).save(os.path.join(OUT, "icons", cid + ".png"), optimize=True)
        print("ok", cid, spr.size)
    json.dump(meta, open(meta_path, "w"), indent=1)


if __name__ == "__main__":
    main()
