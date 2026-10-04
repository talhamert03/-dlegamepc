#!/usr/bin/env python3
"""Builds the class-family item icons from the painted HD icons (no new AI art needed).

Each family gets its own look by recolouring the source painting in HSV space: fabric and leather hues are
moved to the family palette while gold trim, gems and highlights are kept, so the brush work stays intact.

  warrior (heavy)  : crimson and steel
  mage    (light)  : deep violet and blue
  healer  (holy)   : ivory and gold
  ranger  (medium) : forest green and brown leather

Run from the game folder:  python3 tools/gen_family_icons.py
"""
import os
import numpy as np
from PIL import Image, ImageFilter

SRC = "assets/hd/items"


def load(name):
    return np.asarray(Image.open(os.path.join(SRC, name + ".png")).convert("RGBA")).astype(np.float32) / 255.0


def save(arr, name):
    img = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA")
    img.save(os.path.join(SRC, name + ".png"))


def rgb_to_hsv(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = np.max(rgb, axis=-1)
    mn = np.min(rgb, axis=-1)
    d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-6
    rc = np.where(m, (mx - r) / np.where(m, d, 1), 0)
    gc = np.where(m, (mx - g) / np.where(m, d, 1), 0)
    bc = np.where(m, (mx - b) / np.where(m, d, 1), 0)
    h = np.where(r == mx, bc - gc, h)
    h = np.where(g == mx, 2.0 + rc - bc, h)
    h = np.where(b == mx, 4.0 + gc - rc, h)
    h = (h / 6.0) % 1.0
    h = np.where(m, h, 0)
    s = np.where(mx > 1e-6, d / np.where(mx > 1e-6, mx, 1), 0)
    return np.stack([h, s, mx], axis=-1)


def hsv_to_rgb(hsv):
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    i = np.floor(h * 6.0)
    f = h * 6.0 - i
    p = v * (1 - s)
    q = v * (1 - s * f)
    t = v * (1 - s * (1 - f))
    i = i.astype(int) % 6
    r = np.choose(i, [v, q, p, p, t, v])
    g = np.choose(i, [t, v, v, q, p, p])
    b = np.choose(i, [p, p, t, v, v, q])
    return np.stack([r, g, b], axis=-1)


def hue_mask(hsv, lo, hi, smin=0.18):
    """Soft mask of pixels whose hue (degrees) lies in [lo, hi] (wrapping) and that are saturated enough."""
    h = hsv[..., 0] * 360.0
    if lo <= hi:
        inside = (h >= lo) & (h <= hi)
    else:
        inside = (h >= lo) | (h <= hi)
    sat = np.clip((hsv[..., 1] - smin) / 0.12, 0, 1)
    return inside.astype(np.float32) * sat


def is_gold(hsv):
    h = hsv[..., 0] * 360.0
    return ((h >= 34) & (h <= 58) & (hsv[..., 1] > 0.35) & (hsv[..., 2] > 0.45)).astype(np.float32)


def recolor(arr, rules, keep_gold=True):
    """rules: list of (lo, hi, smin, target) with target = (hue_deg or None, sat_mul, val_mul, val_add)."""
    rgb = arr[..., :3]
    hsv = rgb_to_hsv(rgb)
    out = hsv.copy()
    gold = is_gold(hsv) if keep_gold else np.zeros(hsv.shape[:2], np.float32)
    for lo, hi, smin, (th, sm, vm, va) in rules:
        m = hue_mask(hsv, lo, hi, smin) * (1 - gold)
        nh = hsv[..., 0] if th is None else np.full_like(hsv[..., 0], th / 360.0)
        ns = np.clip(hsv[..., 1] * sm, 0, 1)
        nv = np.clip(hsv[..., 2] * vm + va, 0, 1)
        out[..., 0] = out[..., 0] * (1 - m) + nh * m
        out[..., 1] = out[..., 1] * (1 - m) + ns * m
        out[..., 2] = out[..., 2] * (1 - m) + nv * m
    res = arr.copy()
    res[..., :3] = hsv_to_rgb(out)
    return res


def metal_to(arr, hue, sat, vmul=1.0):
    """Unsaturated metal / grey -> tinted metal (gold, dark iron...)."""
    rgb = arr[..., :3]
    hsv = rgb_to_hsv(rgb)
    m = np.clip((0.22 - hsv[..., 1]) / 0.12, 0, 1) * np.clip((hsv[..., 2] - 0.18) / 0.15, 0, 1)
    out = hsv.copy()
    out[..., 0] = hsv[..., 0] * (1 - m) + (hue / 360.0) * m
    out[..., 1] = hsv[..., 1] * (1 - m) + sat * m
    out[..., 2] = np.clip(hsv[..., 2] * (1 - m) + hsv[..., 2] * vmul * m, 0, 1)
    res = arr.copy()
    res[..., :3] = hsv_to_rgb(out)
    return res


def halo(arr, color, strength=0.55, radius=5):
    """Soft outer glow behind the painting (holy / ornate pieces)."""
    a = Image.fromarray((arr[..., 3] * 255).astype(np.uint8))
    g = np.asarray(a.filter(ImageFilter.GaussianBlur(radius))).astype(np.float32) / 255.0 * strength
    base = np.zeros_like(arr)
    base[..., 0], base[..., 1], base[..., 2] = color
    base[..., 3] = g
    # composite the painting over the glow
    out = base.copy()
    sa = arr[..., 3:4]
    out[..., :3] = arr[..., :3] * sa + base[..., :3] * (1 - sa)
    out[..., 3] = np.clip(arr[..., 3] + g * (1 - arr[..., 3]), 0, 1)
    return out


IVORY = (40, 0.10, 1.0, 0.38)      # any fabric hue -> warm ivory
ALL = (0, 360, 0.15)


def ivory_gold(arr, extra=()):
    rules = [(0, 360, 0.15, IVORY)] + list(extra)
    return recolor(arr, rules)


def main():
    made = []
    # ---- healer: holy vestments (from the robes) ------------------------------------------------------
    for piece in ["chest", "helm", "gloves", "boots"]:
        for v in ["a", "b"]:
            src = load("%s_light_%s" % (piece, v))
            out = metal_to(src, 44, 0.62, 1.1)
            out = ivory_gold(out)
            if v == "b":
                out = halo(out, (1.0, 0.86, 0.45), 0.5, 4)
            save(out, "%s_holy_%s" % (piece, v))
            made.append("%s_holy_%s" % (piece, v))
    # ---- capes per family ------------------------------------------------------------------------------
    red_cape, blue_cape = load("cape_a"), load("cape_b")
    save(red_cape, "cape_heavy_a")
    save(recolor(blue_cape, [(170, 290, 0.15, (356, 1.05, 0.95, 0.0))]), "cape_heavy_b")
    save(recolor(red_cape, [(330, 30, 0.2, (272, 0.95, 0.9, 0.0))]), "cape_light_a")
    save(blue_cape, "cape_light_b")
    save(halo(ivory_gold(red_cape), (1.0, 0.86, 0.45), 0.35, 4), "cape_holy_a")
    save(halo(ivory_gold(blue_cape), (1.0, 0.86, 0.45), 0.5, 4), "cape_holy_b")
    save(recolor(red_cape, [(330, 30, 0.2, (128, 0.85, 0.72, 0.0))]), "cape_medium_a")
    save(recolor(blue_cape, [(170, 290, 0.15, (115, 0.8, 0.7, 0.0))]), "cape_medium_b")
    made += ["cape_%s_%s" % (w, v) for w in ["heavy", "light", "holy", "medium"] for v in "ab"]
    # ---- belts per family ------------------------------------------------------------------------------
    for v in ["a", "b"]:
        b = load("belt_" + v)
        save(recolor(b, [(0, 40, 0.15, (220, 0.18, 0.85, 0.05))]), "belt_heavy_" + v)
        save(recolor(b, [(0, 40, 0.15, (276, 0.85, 0.9, 0.0))]), "belt_light_" + v)
        save(ivory_gold(b), "belt_holy_" + v)
        save(b, "belt_medium_" + v)
        made += ["belt_%s_%s" % (w, v) for w in ["heavy", "light", "holy", "medium"]]
    # ---- healer weapons: golden scepter (from the wand) and a holy staff ------------------------------
    for v in ["a", "b"]:
        w = load("wand_" + v)
        w = recolor(w, [(170, 300, 0.15, (48, 0.25, 1.15, 0.25)), (0, 40, 0.15, (42, 1.1, 1.25, 0.08))])
        w = metal_to(w, 44, 0.6, 1.1)
        save(halo(w, (1.0, 0.9, 0.55), 0.45 if v == "b" else 0.3, 4), "scepter_" + v)
        s = load("staff_" + v)
        s = recolor(s, [(170, 300, 0.15, (50, 0.22, 1.2, 0.28)), (0, 40, 0.15, (40, 0.9, 1.2, 0.06))])
        s = metal_to(s, 44, 0.6, 1.1)
        save(halo(s, (1.0, 0.9, 0.55), 0.45 if v == "b" else 0.3, 4), "holy_staff_" + v)
        made += ["scepter_" + v, "holy_staff_" + v]
    print("made %d icons" % len(made))


if __name__ == "__main__":
    main()
