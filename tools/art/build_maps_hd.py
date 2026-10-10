#!/usr/bin/env python3
"""Painted HD world maps (1440x900, 6x the logical 240x150 map) for the World window.

Same geography as build_maps.py (same height field, river and decoration seeds) so the zone nodes in
game/data/map_nodes.json still sit where they did; drawn as an inked, hill-shaded atlas instead of flat
pixel blobs: depth-graded water with shore foam and wave strokes, lit relief, ink coastlines, a tapered
river, shaded trees / snow peaks / dunes / obsidian spires, the whole route as a quiet dashed ink line,
a compass rose in the emptiest corner and aged paper toning.

    python3 tools/art/build_maps_hd.py          -> game/assets/ui/map_act{1..4}.jpg (opaque: JPEG keeps the download small)
"""
import json
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "game", "assets", "ui")
W, H = 240, 150
K = 6
WW, HH = W * K, H * K

ACTS = {
    1: dict(low="#86C05E", high="#4F8E3C", peak="#3C6E30", shore="#E6D8A0", deep="#2E6FA8", shallow="#6FB6DE",
            deco="tree", seed=11),
    2: dict(low="#EEF3F7", high="#BCCBDA", peak="#93A6BE", shore="#DCE6EE", deep="#3D7FB8", shallow="#8FC6EA",
            deco="peak", seed=12),
    3: dict(low="#EBCF8E", high="#D0A862", peak="#B48A48", shore="#F2E2B0", deep="#1F86A8", shallow="#5CC2D8",
            deco="dune", seed=13),
    4: dict(low="#6E5E74", high="#4C3C56", peak="#352840", shore="#8A5A5A", deep="#7A1E2C", shallow="#C2404E",
            deco="spike", seed=14),
}


def rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def value_noise(shape, scale, rng):
    """Smooth value noise in [0,1]: a coarse random grid upsampled with cubic zoom."""
    gh, gw = max(2, shape[0] // scale + 2), max(2, shape[1] // scale + 2)
    g = rng.random((gh, gw)).astype(np.float32)
    z = ndimage.zoom(g, (shape[0] / (gh - 1), shape[1] / (gw - 1)), order=3)
    return np.clip(z[:shape[0], :shape[1]], 0, 1)


def build(act, cfg, nodes):
    rng = random.Random(cfg["seed"])
    seeds = [rng.uniform(0, 6.28) for _ in range(8)]
    nrng = np.random.default_rng(cfg["seed"] * 7)

    # ---- height field, same formula as the pixel map, sampled at 6x
    ys, xs = np.mgrid[0:HH, 0:WW].astype(np.float32)
    x = xs / K
    y = ys / K
    h = np.zeros_like(x)
    for i in range(4):
        f = 0.02 * (2 ** i)
        h += np.sin(x * f + seeds[i]) * np.cos(y * f * 1.3 + seeds[i + 4]) / (1.6 ** i)
    edge = np.minimum(np.minimum(x, y), np.minimum(W - 1 - x, H - 1 - y))
    h -= np.clip(10 - edge, 0, None) * 0.08
    # fine relief so slopes are not glassy
    h_detail = h + (value_noise(h.shape, 40, nrng) - 0.5) * 0.10 + (value_noise(h.shape, 12, nrng) - 0.5) * 0.04

    sea = -0.35
    land_m = h_detail > sea

    # ---- colours: the sine height field forms diagonal ridges, so the land tint follows a blend of the
    # height and broad organic noise (the coastline itself keeps the original field)
    img = np.zeros((HH, WW, 3), np.float32)
    low, high, peak = rgb(cfg["low"]), rgb(cfg["high"]), rgb(cfg["peak"])
    blob = value_noise(h.shape, 160, nrng) * 0.7 + value_noise(h.shape, 60, nrng) * 0.3
    tint_f = (blob - 0.5) * 2.2 + 0.2
    t1 = (smoothstep(-0.35, 0.75, tint_f) * 0.6)[..., None]
    t2 = (smoothstep(0.75, 1.3, tint_f) * 0.6)[..., None]
    land_c = low * (1 - t1) + high * t1
    land_c = land_c * (1 - t2) + peak * t2
    deep, shallow, shore = rgb(cfg["deep"]), rgb(cfg["shallow"]), rgb(cfg["shore"])
    depth = smoothstep(sea, sea - 0.45, h_detail)[..., None]
    water_c = shallow * (1 - depth) + deep * depth
    img = np.where(land_m[..., None], land_c, water_c)
    # beach band just above the waterline
    beach = (smoothstep(sea + 0.07, sea, h_detail) * land_m)[..., None]
    img = img * (1 - beach * 0.85) + shore * beach * 0.85

    # ---- hill shading (light from the upper left) on land
    # relief from the fine detail only (the big ridges would shade into stripes), plus a soft rim of shade
    # inland from the coast so landmasses read as raised
    hills = value_noise(h.shape, 110, nrng) * 0.7 + value_noise(h.shape, 36, nrng) * 0.3
    relief = ndimage.gaussian_filter(hills, 3.0) * 0.5 + (blob - 0.5) * 0.3
    gy, gx = np.gradient(relief)
    shade = np.clip((gx * -0.7 + gy * -0.7) * 260.0, -0.3, 0.3)
    img = np.where(land_m[..., None], img * (1 + shade[..., None] * 0.6), img)
    # paper grain everywhere
    grain = (value_noise(h.shape, 6, nrng) - 0.5) * 18 + (nrng.random(h.shape).astype(np.float32) - 0.5) * 8
    img += grain[..., None]

    # ---- shore foam and ink coastline
    dist_to_land = ndimage.distance_transform_edt(~land_m)
    foam = np.clip(1 - dist_to_land / 7.0, 0, 1) * (~land_m)
    img = img * (1 - foam[..., None] * 0.45) + 255 * foam[..., None] * 0.45
    coast = land_m ^ ndimage.binary_erosion(land_m, iterations=2)
    img[coast] = img[coast] * 0.45 + np.array([40, 28, 18]) * 0.55

    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(im, "RGBA")

    # ---- wave strokes on open water
    for _ in range(140):
        wx, wy = nrng.integers(30, WW - 30), nrng.integers(30, HH - 30)
        if dist_to_land[wy, wx] > 22:
            ww = nrng.integers(10, 22)
            pts = [(wx + i, wy + math.sin(i / ww * math.pi * 2) * 2.2) for i in range(0, ww, 2)]
            d.line(pts, fill=(255, 255, 255, 70), width=2)

    # ---- river (same random walk as the pixel map, smoothed and tapered)
    rx = rng.randint(60, 180)
    path = []
    for yy in range(4, H - 4):
        rx += rng.choice([-1, 0, 0, 1])
        path.append((rx * K + K / 2, yy * K + K / 2))
    arr = np.array(path)
    arr[:, 0] = ndimage.uniform_filter1d(arr[:, 0], 9, mode="nearest")
    for i in range(len(arr) - 1):
        t = i / len(arr)
        wdt = int(5 + 7 * t)
        d.line([tuple(arr[i]), tuple(arr[i + 1])], fill=tuple(int(v) for v in (rgb(cfg["deep"]) * 0.7)) + (255,), width=wdt + 4)
    for i in range(len(arr) - 1):
        t = i / len(arr)
        wdt = int(5 + 7 * t)
        d.line([tuple(arr[i]), tuple(arr[i + 1])], fill=tuple(int(v) for v in rgb(cfg["shallow"])) + (255,), width=wdt)

    # ---- keep the route clear of decoration
    route = [(px * K, py * K) for px, py in nodes]

    def near_route(px, py, r=60):
        for i in range(len(route) - 1):
            (ax, ay), (bx, by) = route[i], route[i + 1]
            vx, vy = bx - ax, by - ay
            L2 = vx * vx + vy * vy
            t = max(0.0, min(1.0, ((px - ax) * vx + (py - ay) * vy) / L2)) if L2 else 0.0
            if math.hypot(px - (ax + vx * t), py - (ay + vy * t)) < r:
                return True
        return False

    # ---- decorations, same spots as the pixel map (+ extra ones for density at this resolution)
    spots = []
    for _ in range(70):
        spots.append((rng.randint(10, W - 10), rng.randint(10, H - 10)))
    for _ in range(90):
        spots.append((int(nrng.integers(10, W - 10)), int(nrng.integers(10, H - 10))))
    spots.sort(key=lambda p: p[1])   # back to front
    for sx, sy in spots:
        X, Y = sx * K, sy * K
        if not land_m[min(HH - 1, Y), min(WW - 1, X)] or dist_to_land[min(HH - 1, Y), min(WW - 1, X)] > 0:
            continue
        if near_route(X, Y):
            continue
        s = float(nrng.uniform(0.85, 1.25))
        _deco(d, cfg["deco"], X, Y, s)

    # ---- the whole route, dashed ink (the game draws the walked part in gold over it)
    for i in range(len(route) - 1):
        (ax, ay), (bx, by) = route[i], route[i + 1]
        L = math.hypot(bx - ax, by - ay)
        n = int(L / 16)
        for k in range(n):
            t0, t1 = k / n, (k + 0.55) / n
            p0 = (ax + (bx - ax) * t0, ay + (by - ay) * t0)
            p1 = (ax + (bx - ax) * t1, ay + (by - ay) * t1)
            d.line([(p0[0] + 2, p0[1] + 2), (p1[0] + 2, p1[1] + 2)], fill=(0, 0, 0, 60), width=5)
            d.line([p0, p1], fill=(70, 44, 24, 200), width=4)

    # ---- compass rose in the corner furthest from the route
    corners = [(130, 130), (WW - 130, 130), (130, HH - 130), (WW - 130, HH - 130)]
    cx, cy = max(corners, key=lambda c: min(math.hypot(c[0] - rx_, c[1] - ry_) for rx_, ry_ in route))
    _compass(d, cx, cy, 72)

    # ---- aged paper toning: warm vignette and darker rim
    vig = np.zeros((HH, WW), np.float32)
    e = np.minimum(np.minimum(xs, ys), np.minimum(WW - 1 - xs, HH - 1 - ys))
    vig = np.clip(1 - e / 90.0, 0, 1) ** 1.6
    arr2 = np.asarray(im).astype(np.float32)
    tone = np.array([88, 58, 30], np.float32)
    arr2[..., :3] = arr2[..., :3] * (1 - vig[..., None] * 0.55) + tone * vig[..., None] * 0.55
    im = Image.fromarray(np.clip(arr2, 0, 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(im, "RGBA")
    d.rectangle([6, 6, WW - 7, HH - 7], outline=(60, 38, 20, 230), width=4)
    d.rectangle([14, 14, WW - 15, HH - 15], outline=(60, 38, 20, 120), width=2)
    return im


def _deco(d, kind, X, Y, s):
    if kind == "tree":
        r = 11 * s
        d.ellipse([X - r * 1.1, Y + r * 0.9, X + r * 1.1, Y + r * 1.5], fill=(20, 40, 16, 70))
        d.rectangle([X - 2 * s, Y + r * 0.2, X + 2 * s, Y + r * 1.2], fill=(84, 58, 36, 255))
        d.ellipse([X - r, Y - r, X + r, Y + r], fill=(46, 96, 40, 255), outline=(26, 52, 22, 255), width=2)
        d.ellipse([X - r * 0.75, Y - r * 0.85, X + r * 0.25, Y + r * 0.1], fill=(92, 150, 66, 255))
        d.ellipse([X - r * 0.5, Y - r * 0.7, X - r * 0.1, Y - r * 0.35], fill=(150, 196, 104, 200))
    elif kind == "peak":
        w, hgt = 22 * s, 28 * s
        d.polygon([(X - w, Y + hgt * 0.4), (X + w, Y + hgt * 0.4), (X + w * 1.3, Y + hgt * 0.55), (X - w * 0.8, Y + hgt * 0.55)], fill=(40, 50, 70, 50))
        d.polygon([(X - w, Y + hgt * 0.4), (X, Y - hgt * 0.6), (X + w, Y + hgt * 0.4)], fill=(120, 138, 166, 255), outline=(52, 62, 86, 255))
        d.polygon([(X, Y - hgt * 0.6), (X + w, Y + hgt * 0.4), (X + w * 0.15, Y + hgt * 0.4)], fill=(86, 100, 130, 255))
        d.polygon([(X - w * 0.36, Y - hgt * 0.24), (X, Y - hgt * 0.6), (X + w * 0.36, Y - hgt * 0.24), (X + w * 0.1, Y - hgt * 0.14), (X - w * 0.12, Y - hgt * 0.2)], fill=(250, 252, 255, 255))
    elif kind == "dune":
        w = 26 * s
        pts = [(X - w + i, Y - math.sin(i / (2 * w) * math.pi) * 9 * s) for i in range(0, int(2 * w), 3)]
        shadow = [(px_ + 3, py_ + 4) for px_, py_ in pts]
        d.line(shadow, fill=(140, 96, 40, 110), width=4)
        d.line(pts, fill=(160, 112, 52, 255), width=4)
        d.line([(px_ - 1, py_ - 2) for px_, py_ in pts[: len(pts) // 2]], fill=(255, 238, 190, 200), width=2)
    else:
        hgt, w = 30 * s, 6 * s
        for dx, k in ((-9 * s, 0.7), (0, 1.0), (8 * s, 0.8)):
            top = Y - hgt * k
            d.polygon([(X + dx - w, Y + 6), (X + dx, top), (X + dx + w, Y + 6)], fill=(36, 24, 46, 255), outline=(14, 8, 20, 255))
            d.line([(X + dx, top + 2), (X + dx - w * 0.5, Y + 2)], fill=(170, 90, 200, 160), width=2)
        d.ellipse([X - 16 * s, Y + 3, X + 16 * s, Y + 10], fill=(0, 0, 0, 70))


def _compass(d, cx, cy, r):
    ink = (66, 42, 22, 230)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=ink, width=3)
    d.ellipse([cx - r * 0.82, cy - r * 0.82, cx + r * 0.82, cy + r * 0.82], outline=(66, 42, 22, 140), width=2)
    for a in range(0, 360, 15):
        rr = r * (0.9 if a % 45 else 0.84)
        d.line([(cx + math.cos(math.radians(a)) * rr, cy + math.sin(math.radians(a)) * rr),
                (cx + math.cos(math.radians(a)) * r, cy + math.sin(math.radians(a)) * r)], fill=ink, width=2)
    for a, L in ((-90, 1.0), (0, 0.78), (90, 0.78), (180, 0.78), (-45, 0.5), (45, 0.5), (135, 0.5), (-135, 0.5)):
        ra = math.radians(a)
        tip = (cx + math.cos(ra) * r * L, cy + math.sin(ra) * r * L)
        side = math.radians(a + 90)
        wv = r * 0.12
        p1 = (cx + math.cos(side) * wv, cy + math.sin(side) * wv)
        p2 = (cx - math.cos(side) * wv, cy - math.sin(side) * wv)
        d.polygon([p1, tip, (cx, cy)], fill=(176, 40, 36, 235) if a == -90 else (232, 214, 170, 235), outline=ink)
        d.polygon([p2, tip, (cx, cy)], fill=(120, 24, 22, 235) if a == -90 else (120, 90, 54, 235), outline=ink)
    d.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(214, 168, 72, 255), outline=ink, width=2)
    # N
    nx, ny = cx, cy - r - 18
    d.line([(nx - 7, ny + 9), (nx - 7, ny - 9), (nx + 7, ny + 9), (nx + 7, ny - 9)], fill=ink, width=4)


def main():
    nodes = json.load(open(os.path.join(ROOT, "game", "data", "map_nodes.json")))
    for act, cfg in ACTS.items():
        im = build(act, cfg, nodes[str(act)])
        im.convert("RGB").save(os.path.join(OUT, f"map_act{act}.jpg"), quality=90, optimize=True, progressive=True)
        print("map", act, im.size)


if __name__ == "__main__":
    main()
