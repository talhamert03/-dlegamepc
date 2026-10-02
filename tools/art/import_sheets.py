#!/usr/bin/env python3
"""AI sprite sheets (6 columns x 4 rows on a flat magenta background) -> registered frame atlases.

  python3 tools/art/import_sheets.py <kind> [id ...]      # kind: heroes | enemies | pets

Input:  art_src/urls_sheets_<kind>.json {id: url}; raw downloads kept in art_src/raw/sheets_<kind>/<id>.png
Rows:   0 idle loop, 1 run loop, 2 attack (melee swing / bow shot / spell cast), 3 hurt x2 + death x4
Output: game/assets/hd/anim/<kind>/<id>.png   atlas, 6 x 4 cells of identical size
        game/assets/hd/anim/meta.json         {kind: {id: {"cw","ch","ax","ay","h"}}}
          (ax, ay) = feet anchor inside every cell, h = standing height in px (idle median)
Every frame is keyed, cleaned and re-registered so the feet sit on the same anchor: no jitter between frames.
"""
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "art_src")
OUT = os.path.join(ROOT, "game", "assets", "hd", "anim")
COLS, ROWS = 6, 4
PAD = 3


def download(url, path):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return True
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return subprocess.run(["curl", "-sSfL", "-o", path, url], capture_output=True).returncode == 0


def key_magenta(img, key="magenta"):
    """RGBA with the magenta (or cyan) background removed.

    Solid pixels stay untouched; anti-aliased edges and glows are un-mixed from the key colour so they keep a soft,
    clean alpha instead of a pink fringe."""
    a = np.array(img.convert("RGB")).astype(np.float64)
    if key == "cyan":
        a = a[..., [1, 0, 2]]          # swap r/g so cyan keys exactly like magenta, swapped back below
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    m = np.minimum(r, b) - g           # magenta-ness: how much r and b exceed g together
    k = np.clip((m - 60.0) / 170.0, 0.0, 1.0)      # estimated share of key colour in the pixel
    alpha = 1.0 - k
    safe = np.maximum(alpha, 1e-3)
    a[..., 0] = np.clip((r - k * 255.0) / safe, 0, 255)
    a[..., 2] = np.clip((b - k * 255.0) / safe, 0, 255)
    a[..., 1] = np.clip(g / safe, 0, 255)
    if key == "cyan":
        a = a[..., [1, 0, 2]]
    alpha[alpha < 0.12] = 0.0
    return np.dstack([a, alpha * 255.0]).round().astype(np.uint8)


def _cuts(profile, n, slack=0.2):
    """n-1 cut positions: the emptiest line near every expected grid boundary."""
    size = len(profile) / n
    cuts = [0]
    for k in range(1, n):
        e = int(round(k * size))
        lo, hi = max(1, int(e - size * slack)), min(len(profile) - 1, int(e + size * slack))
        win = profile[lo:hi]
        best = np.flatnonzero(win == win.min()) + lo
        cuts.append(int(best[np.argmin(np.abs(best - e))]))
    cuts.append(len(profile))
    return cuts


def _segments(profile, min_gap=3):
    """Runs of non-empty columns separated by at least min_gap empty ones -> [(start, end)]."""
    on = profile > 0
    segs, start, gap = [], None, 0
    for i, v in enumerate(on):
        if v:
            if start is None:
                start = i
            gap = 0
            end = i + 1
        elif start is not None:
            gap += 1
            if gap >= min_gap:
                segs.append((start, end))
                start = None
    if start is not None:
        segs.append((start, end))
    return [sg for sg in segs if sg[1] - sg[0] >= 6]


def _crop(sub):
    m = sub[..., 3] > 30
    lab, n = ndimage.label(ndimage.binary_dilation(m, iterations=2))
    if n == 0:
        return None
    sizes = ndimage.sum(m, lab, range(1, n + 1))
    keep = [i + 1 for i in range(n) if sizes[i] >= max(8, sizes.max() * 0.004)]
    sub[..., 3] = np.where(np.isin(lab, keep), sub[..., 3], 0)
    ys, xs = np.nonzero(sub[..., 3] > 30)
    return sub[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def frames_from(arr):
    """Split into COLS x ROWS frames. Rows: emptiest lines near the grid. Columns: the real figures when the row
    has clean gaps (the AI does not always place them on an even grid, sometimes draws 5), else the grid."""
    mask = arr[..., 3] > 30
    rows = _cuts(mask.sum(axis=1), ROWS)
    out = []
    for r in range(ROWS):
        band = mask[rows[r]:rows[r + 1]]
        prof = band.sum(axis=0)
        segs = _segments(prof)
        widths = [b - a for a, b in segs]
        med = float(np.median(widths)) if widths else 0.0
        plausible = bool(widths) and all(0.55 * med <= w_ <= 1.6 * med for w_ in widths) and med < band.shape[1] / 3.5
        if not plausible:
            segs = []
        if 4 <= len(segs) < COLS:
            # fewer figures than columns: stretch them over the 6 frames
            picks = [segs[min(len(segs) - 1, int(i * len(segs) / COLS))] for i in range(COLS)]
            bounds = [(a, b) for a, b in picks]
        elif len(segs) == COLS:
            bounds = segs
        else:
            cols = _cuts(prof, COLS)
            bounds = [(cols[c], cols[c + 1]) for c in range(COLS)]
        row = []
        for a, b in bounds:
            row.append(_crop(arr[rows[r]:rows[r + 1], a:b].copy()))
        out.append(row)
    return out


def anchor(fr, row):
    """Feet anchor: bottom row of opaque pixels; x = centre of the torso band (stable through swings)."""
    a = fr[..., 3] > 100
    ys = np.nonzero(a.any(axis=1))[0]
    bottom = ys.max() + 1
    top = ys.min()
    hgt = bottom - top
    if row == 3:
        band = a[top:bottom]
    else:
        band = a[top + int(hgt * 0.30): top + int(hgt * 0.80)]     # torso + hips, ignores weapon tips above
    cols = band.sum(axis=0).astype(float)
    xs = np.arange(a.shape[1])
    # trimmed centre: median of the mass distribution resists weapon / cape protrusions
    cum = np.cumsum(cols)
    ax = float(np.searchsorted(cum, cum[-1] / 2.0))
    return ax, float(bottom), float(hgt)


def build(kind, cid, raw, key="magenta"):
    arr = key_magenta(Image.open(raw), key)
    frames = frames_from(arr)
    anchors = [[anchor(f, r) if f is not None else None for f in frames[r]] for r in range(ROWS)]
    # stabilise loops: within idle and run rows use the row median x so small AI drift disappears
    left = right = up = down = 0
    for r in range(ROWS):
        for c in range(COLS):
            f, an = frames[r][c], anchors[r][c]
            if f is None:
                continue
            ax, ay, _ = an
            left = max(left, ax); right = max(right, f.shape[1] - ax)
            up = max(up, ay); down = max(down, f.shape[0] - ay)
    cw = int(np.ceil(left + right)) + PAD * 2
    chh = int(np.ceil(up + down)) + PAD * 2
    axc, ayc = int(np.ceil(left)) + PAD, int(np.ceil(up)) + PAD
    atlas = Image.new("RGBA", (cw * COLS, chh * ROWS), (0, 0, 0, 0))
    for r in range(ROWS):
        for c in range(COLS):
            f = frames[r][c]
            if f is None:
                # missing frame: repeat the previous one so the animation never blinks
                f = next((frames[r][k] for k in range(c - 1, -1, -1) if frames[r][k] is not None), frames[0][0])
                an = anchor(f, r)
            else:
                an = anchors[r][c]
            ax, ay, _ = an
            atlas.alpha_composite(Image.fromarray(f, "RGBA"), (int(round(c * cw + axc - ax)), int(round(r * chh + ayc - ay))))
    idle_h = float(np.median([anchors[0][c][2] for c in range(COLS) if anchors[0][c]]))
    os.makedirs(os.path.join(OUT, kind), exist_ok=True)
    atlas.save(os.path.join(OUT, kind, cid + ".png"), optimize=True)
    return {"cw": cw, "ch": chh, "ax": axc, "ay": ayc, "h": round(idle_h, 1)}


def main():
    kind = sys.argv[1]
    only = set(sys.argv[2:])
    urls = json.load(open(os.path.join(SRC, f"urls_sheets_{kind}.json")))
    pp = os.path.join(SRC, f"prompts_sheets_{kind}.json")
    prompts = json.load(open(pp)) if os.path.exists(pp) else {}
    meta_path = os.path.join(OUT, "meta.json")
    meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {}
    meta.setdefault(kind, {})
    for cid, url in urls.items():
        if only and cid not in only:
            continue
        raw = os.path.join(SRC, "raw", "sheets_" + kind, cid + ".png")
        if not download(url, raw):
            print("download failed", cid)
            continue
        pr = prompts.get(cid, {})
        meta[kind][cid] = build(kind, cid, raw, pr.get("key", "magenta"))
        if "flying" in pr.get("prompt", ""):
            meta[kind][cid]["fly"] = True
        print("ok", cid, meta[kind][cid])
    os.makedirs(OUT, exist_ok=True)
    json.dump(meta, open(meta_path, "w"), indent=1, sort_keys=True)


if __name__ == "__main__":
    main()
