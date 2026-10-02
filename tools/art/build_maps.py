#!/usr/bin/env python3
"""Parchment world maps for each act (240x150) + node coordinates (game/data/map_nodes.json)."""
import json
import math
import os
import random

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "game", "assets", "ui")
W, H = 240, 150

ACTS = {
    1: dict(land="#7FB85A", land2="#5E9A44", water="#5AA0D0", deco="tree", deco_col="#3E7A3A", seed=11),
    2: dict(land="#E6EEF4", land2="#B8CCDA", water="#7FB8E0", deco="peak", deco_col="#8A9AB8", seed=12),
    3: dict(land="#E8CC8A", land2="#D2AE6A", water="#4AA8C8", deco="dune", deco_col="#B8904A", seed=13),
    4: dict(land="#6A5A6E", land2="#4E3E56", water="#A83A4A", deco="spike", deco_col="#2E2236", seed=14),
}


def hx(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)


def build(act, cfg):
    rng = random.Random(cfg["seed"])
    im = Image.new("RGBA", (W, H), hx("#E8D9A8"))
    px = im.load()
    land, land2, water = hx(cfg["land"]), hx(cfg["land2"]), hx(cfg["water"])
    seeds = [rng.uniform(0, 6.28) for _ in range(8)]

    def height(x, y):
        v = 0
        for i in range(4):
            f = 0.02 * (2 ** i)
            v += math.sin(x * f + seeds[i]) * math.cos(y * f * 1.3 + seeds[i + 4]) / (1.6 ** i)
        return v

    for y in range(4, H - 4):
        for x in range(4, W - 4):
            h = height(x, y)
            edge = min(x, y, W - 1 - x, H - 1 - y)
            if edge < 10:
                h -= (10 - edge) * 0.08
            if h > -0.35:
                c = land if h < 0.45 else land2
                if (x + y) % 2 == 0 and abs(h - 0.45) < 0.03:
                    c = shade(land2, 0.9)
                px[x, y] = c
            elif h > -0.45:
                px[x, y] = shade(hx("#E8D9A8"), 0.92)
            else:
                px[x, y] = water if (x * 3 + y) % 7 else shade(water, 1.1)
    # river
    rx = rng.randint(60, 180)
    for y in range(4, H - 4):
        rx += rng.choice([-1, 0, 0, 1])
        for dx in range(-1, 2):
            if 4 < rx + dx < W - 4:
                px[rx + dx, y] = water
    # decorations
    dc = hx(cfg["deco_col"])
    for i in range(70):
        x, y = rng.randint(10, W - 10), rng.randint(10, H - 10)
        if px[x, y][:3] in (land[:3], land2[:3]):
            if cfg["deco"] == "tree":
                for dy in range(3):
                    for dx in range(-dy, dy + 1):
                        px[x + dx, y + dy] = dc
                px[x, y + 3] = hx("#5A3E2E")
            elif cfg["deco"] == "peak":
                for dy in range(5):
                    for dx in range(-dy, dy + 1):
                        px[x + dx, y + dy] = dc if dy > 1 else hx("#FFFFFF")
            elif cfg["deco"] == "dune":
                for dx in range(-3, 4):
                    px[x + dx, y + abs(dx) // 2] = dc
            else:
                for dy in range(4):
                    px[x, y + dy] = dc
                    px[x + 1, y + dy + 1] = dc
    # parchment frame
    for x in range(W):
        for y in range(H):
            edge = min(x, y, W - 1 - x, H - 1 - y)
            if edge < 4:
                px[x, y] = shade(hx("#C8A878"), 0.75 + edge * 0.06)
            elif edge == 4:
                px[x, y] = hx("#8A6A4A")
    # node path (10 nodes, snaking)
    nodes = []
    for i in range(10):
        t = i / 9
        x = 24 + t * (W - 48)
        y = H / 2 + math.sin(t * math.pi * 2.2 + act) * (H * 0.28) + rng.randint(-6, 6)
        nodes.append([int(x), int(y)])
    for i in range(9):
        (x0, y0), (x1, y1) = nodes[i], nodes[i + 1]
        steps = int(math.hypot(x1 - x0, y1 - y0) / 4)
        for s in range(1, steps):
            t = s / steps
            x, y = int(x0 + (x1 - x0) * t), int(y0 + (y1 - y0) * t)
            for dx in (0, 1):
                for dy in (0, 1):
                    px[x + dx, y + dy] = hx("#4AB8E8")
    return im, nodes


def main():
    data = {}
    for act, cfg in ACTS.items():
        im, nodes = build(act, cfg)
        im.save(os.path.join(OUT, f"map_act{act}.png"))
        data[str(act)] = nodes
    json.dump(data, open(os.path.join(ROOT, "game", "data", "map_nodes.json"), "w"))
    print("maps done")


if __name__ == "__main__":
    main()
