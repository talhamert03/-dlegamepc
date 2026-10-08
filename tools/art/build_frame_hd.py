"""Painted HD window materials for the panel frame (9-slice) and the leather body (seamless tile).

    python3 tools/art/build_frame_hd.py      ->  game/assets/ui_hd/frame/*.png

Everything is rendered at S px per logical UI pixel so it stays crisp up to 5-6x UI scale and is mipmapped
down for 2x. Light comes from the top left, like the rest of the UI.

frame_9.png   one 9-slice sheet: CORNER x CORNER corners, edges in between that tile along their length
leather.png   seamless dark tooled leather for the panel body
parchment.png seamless aged parchment (fibres, mottling, specks) for light sections
slate.png     seamless dark arcane slate (veins, grain) for the rune board
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 6                         # texture px per logical px
BORDER = 5                    # wood frame thickness (logical); + gold rule = 6.2, the panel content inset
CORNER = 18                   # corner fitting box (logical) = 9-slice margin
EDGE_LEN = 64                 # tiling period of an edge segment (logical)
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "ui_hd", "frame")
rng = np.random.default_rng(7)


# --------------------------------------------------------------------------- noise helpers
def periodic_noise(h, w, scale, seed):
    """Seamless (wraps in both axes) smooth noise in 0..1, feature size ~ scale px."""
    r = np.random.default_rng(seed)
    f = np.fft.fft2(r.standard_normal((h, w)))
    ky = np.fft.fftfreq(h)[:, None]
    kx = np.fft.fftfreq(w)[None, :]
    k = np.sqrt(kx * kx + ky * ky)
    f *= np.exp(-(k * scale) ** 2)
    n = np.real(np.fft.ifft2(f))
    n -= n.min()
    return n / max(1e-9, n.max())


def lerp(a, b, t):
    return a + (b - a) * t


def col(hexs):
    hexs = hexs.lstrip("#")
    return np.array([int(hexs[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


# --------------------------------------------------------------------------- wood strip
def wood_strip(length_px, thick_px, seed):
    """Horizontal walnut strip, grain along x, seamless along x. Returns float RGB (thick, length, 3)."""
    n1 = periodic_noise(thick_px * 4, length_px, 18 * S / 6, seed)[:thick_px * 4:4, :]
    n2 = periodic_noise(thick_px * 4, length_px, 4 * S / 6, seed + 1)[:thick_px * 4:4, :]
    y = np.linspace(0, 1, thick_px)[:, None]
    x = np.arange(length_px)[None, :]
    # grain: stretched sine rings disturbed by noise; integer cycles along x keep it seamless
    rings = np.sin((y * 9.0 + n1 * 3.2) * np.pi * 2 + np.sin(x / length_px * np.pi * 2 * 2) * 0.6)
    grain = 0.5 + 0.5 * rings
    fine = n2
    dark, mid, light = col("#2A170C"), col("#5A3720"), col("#7A4C2C")
    t = np.clip(0.55 * grain + 0.45 * fine, 0, 1)[..., None]
    rgb = np.where(t < 0.5, lerp(dark, mid, t * 2), lerp(mid, light, (t - 0.5) * 2))
    # fine pores
    pores = (periodic_noise(thick_px, length_px, 0.8, seed + 2) > 0.82)[..., None]
    rgb = rgb * np.where(pores, 0.82, 1.0)
    return rgb


def bevel_profile(thick_px):
    """Across-the-frame shading: lit outer lip, rounded top, shaded inner groove."""
    y = np.linspace(0, 1, thick_px)
    p = 0.78 + 0.35 * np.sin(np.clip(y / 0.7, 0, 1) * np.pi) ** 0.8
    p[y > 0.72] *= 0.55                         # groove before the gold rule
    p[:max(1, thick_px // 14)] *= 0.55          # dark outer edge
    return p


# --------------------------------------------------------------------------- gold rule
def gold_rule(length_px, thick_px):
    y = np.linspace(0, 1, thick_px)[:, None]
    base = col("#8A5A1E")
    hi = col("#FFE7A6")
    band = np.exp(-((y - 0.35) / 0.18) ** 2)                # specular band
    lo = np.clip(1 - y, 0, 1) * 0.3
    rgb = lerp(base, hi, np.clip(band + lo, 0, 1)[..., None])
    rgb = np.repeat(rgb, length_px, axis=1)
    sparkle = periodic_noise(thick_px, length_px, 1.2, 99)[..., None]
    return rgb * (0.92 + 0.16 * sparkle)


# --------------------------------------------------------------------------- the 9-slice sheet
def build_frame():
    C = CORNER * S                     # corner box px
    B = BORDER * S                     # wood thickness px
    G = int(round(1.2 * S))           # gold rule thickness px
    L = EDGE_LEN * S                   # edge segment px
    W = H = 2 * C + L
    img = np.zeros((H, W, 4), dtype=np.float32)

    # one horizontal strip profile (wood + gold rule + soft inner shadow), seamless with period L so the
    # game can repeat the edge segment; every pixel samples it at its depth from the nearest outer edge,
    # which mitres the four sides cleanly at the corners
    wood = wood_strip(L, B, 11) * bevel_profile(B)[:, None, None]
    gold = gold_rule(L, G)
    sh = int(2.5 * S)
    strip = np.zeros((B + G + sh, L, 4), dtype=np.float32)
    strip[:B, :, :3] = wood
    strip[:B, :, 3] = 255
    strip[B:B + G, :, :3] = gold
    strip[B:B + G, :, 3] = 255
    strip[B + G:, :, 3] = np.linspace(150, 0, sh)[:, None]       # inner shadow cast onto the body
    sw = strip.shape[0]
    yy, xx = np.mgrid[0:H, 0:W]
    depth = np.stack([yy, H - 1 - yy, xx, W - 1 - xx])           # top, bottom, left, right
    side = np.argmin(depth, axis=0)
    d = np.min(depth, axis=0)
    along = np.where(side < 2, xx, yy)
    along = (along - C) % L
    inside = d < sw
    px = strip[np.clip(d, 0, sw - 1), along]
    # light from the top left: top lit, left slightly less, bottom and right shaded
    shade = np.array([1.0, 0.72, 0.92, 0.68], dtype=np.float32)[side]
    px[..., :3] *= shade[..., None]
    img = np.where(inside[..., None], px, 0.0).astype(np.float32)

    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGBA")
    d = ImageDraw.Draw(out)
    # outer outline
    d.rounded_rectangle([0, 0, W - 1, H - 1], radius=int(3 * S), outline=(10, 6, 4, 255), width=max(2, S // 2))
    # cut the outer corners round (transparent outside the rounded rect)
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, W - 1, H - 1], radius=int(3 * S), fill=255)
    out.putalpha(Image.fromarray(np.minimum(np.array(out.split()[3]), np.array(mask))))

    # brass corner fittings with a ruby
    for (cx, cy, fx, fy, light) in [(0, 0, 1, 1, 1.0), (W, 0, -1, 1, 0.85), (0, H, 1, -1, 0.8), (W, H, -1, -1, 0.65)]:
        out.alpha_composite(corner_fitting(C, fx, fy, light), (cx if fx > 0 else cx - C, cy if fy > 0 else cy - C))
    return out


def corner_fitting(C, fx, fy, light):
    """L-shaped cast brass plate hugging the corner, three rivets, faceted ruby. C = box px."""
    ss = 2
    N = C * ss
    im = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    u = N / 16.0                                   # 1 logical px in this supersampled box
    # L plate polygon (top-left orientation), with a notched inner corner
    poly = [(0, 0), (15.5 * u, 0), (15.5 * u, 4.2 * u), (8.5 * u, 4.2 * u), (4.2 * u, 8.5 * u), (4.2 * u, 15.5 * u), (0, 15.5 * u)]
    # shadow
    sh = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    ImageDraw.Draw(sh).polygon([(x + 0.8 * u, y + 1.2 * u) for x, y in poly], fill=(0, 0, 0, 150))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(0.8 * u)))
    # body gradient
    m = Image.new("L", (N, N), 0)
    ImageDraw.Draw(m).polygon(poly, fill=255)
    g = np.zeros((N, N, 3), dtype=np.float32)
    yy, xx = np.mgrid[0:N, 0:N] / N
    t = np.clip((xx + yy) * 0.75, 0, 1)[..., None]
    g[:] = lerp(col("#FFE29A"), col("#8A5418"), t) * light
    noise = periodic_noise(N, N, 2.0, 5)[..., None]
    g *= 0.9 + 0.2 * noise
    plate = Image.fromarray(np.clip(g, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    plate.putalpha(m)
    im.alpha_composite(plate)
    d = ImageDraw.Draw(im)
    d.polygon(poly, outline=(26, 14, 6, 255), width=int(0.7 * u))
    # bevel: bright inner line along the top/left edges of the plate
    d.line([(1.0 * u, 14.5 * u), (1.0 * u, 1.0 * u), (14.5 * u, 1.0 * u)], fill=(255, 245, 210, int(160 * light)), width=int(0.5 * u))
    d.line([(4.9 * u, 14.8 * u), (4.9 * u, 8.8 * u), (8.8 * u, 4.9 * u), (14.8 * u, 4.9 * u)], fill=(60, 34, 12, 200), width=int(0.5 * u))
    # rivets
    for rx, ry in [(12.6 * u, 2.1 * u), (2.1 * u, 12.6 * u)]:
        rr = 1.1 * u
        d.ellipse([rx - rr, ry - rr, rx + rr, ry + rr], fill=(70, 42, 16, 255))
        d.ellipse([rx - rr * 0.75, ry - rr * 0.8, rx + rr * 0.55, ry + rr * 0.5], fill=(255, 236, 180, 255))
    # ruby: faceted diamond with a socket
    cx, cy, R = 3.4 * u, 3.4 * u, 2.6 * u
    d.ellipse([cx - R - 0.6 * u, cy - R - 0.6 * u, cx + R + 0.6 * u, cy + R + 0.6 * u], fill=(40, 22, 8, 255))
    facets = [((cx, cy - R), (cx + R, cy), (cx, cy), (255, 90, 100)), ((cx + R, cy), (cx, cy + R), (cx, cy), (150, 16, 34)),
              ((cx, cy + R), (cx - R, cy), (cx, cy), (110, 8, 26)), ((cx - R, cy), (cx, cy - R), (cx, cy), (220, 40, 60))]
    for a, b, c, fc in facets:
        d.polygon([a, b, c], fill=tuple(int(v * light) for v in fc) + (255,))
    d.ellipse([cx - 0.9 * u, cy - 1.6 * u, cx - 0.1 * u, cy - 0.8 * u], fill=(255, 230, 230, 220))
    im = im.resize((C, C), Image.LANCZOS)
    if fx < 0:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    if fy < 0:
        im = im.transpose(Image.FLIP_TOP_BOTTOM)
    return im


# --------------------------------------------------------------------------- leather body
def build_leather():
    T = 96 * S                                      # tile = 96 logical px
    big = periodic_noise(T, T, 40 * S / 6, 21)
    mid = periodic_noise(T, T, 6 * S / 6, 22)
    fine = periodic_noise(T, T, 1.0 * S / 6, 23)
    base = lerp(col("#1B130E"), col("#33241A"), (0.6 * big + 0.4 * mid)[..., None])
    pores = (fine > 0.78)[..., None]
    base = base * np.where(pores, 0.78, 1.0)
    # creases: thin dark meandering lines from thresholded mid noise
    crease = np.abs(mid - 0.5) < 0.012
    base = base * np.where(crease[..., None], 0.8, 1.0)
    return Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB")


# --------------------------------------------------------------------------- parchment
def build_parchment():
    T = 96 * S
    mott = periodic_noise(T, T, 30 * S / 6, 31)
    mid = periodic_noise(T, T, 5 * S / 6, 32)
    # fibres: noise stretched along x (filter anisotropically in frequency space)
    r = np.random.default_rng(33)
    f = np.fft.fft2(r.standard_normal((T, T)))
    ky = np.fft.fftfreq(T)[:, None]
    kx = np.fft.fftfreq(T)[None, :]
    f *= np.exp(-((kx * 9 * S / 6) ** 2 + (ky * 0.9 * S / 6) ** 2))
    fib = np.real(np.fft.ifft2(f))
    fib = (fib - fib.min()) / (fib.max() - fib.min())
    light, dark = col("#E2CA9C"), col("#B8945E")
    t = np.clip(0.55 * mott + 0.25 * mid + 0.2 * fib, 0, 1)
    rgb = lerp(dark, light, t[..., None] ** 0.9)
    # a few darker age blotches and fine specks
    blot = np.clip((mott - 0.72) * 4.0, 0, 1)[..., None]
    rgb = rgb * (1.0 - 0.12 * blot)
    speck = (periodic_noise(T, T, 0.7, 34) > 0.86)[..., None]
    rgb = rgb * np.where(speck, 0.9, 1.0)
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")


# --------------------------------------------------------------------------- slate
def build_slate():
    T = 96 * S
    big = periodic_noise(T, T, 26 * S / 6, 41)
    mid = periodic_noise(T, T, 4 * S / 6, 42)
    fine = periodic_noise(T, T, 0.9 * S / 6, 43)
    base = lerp(col("#15161D"), col("#2A2B36"), np.clip(0.6 * big + 0.3 * mid + 0.1 * fine, 0, 1)[..., None])
    # marble veins: a diagonal sine (whole cycles across the tile, so it stays seamless) bent by turbulence
    yy, xx = np.mgrid[0:T, 0:T].astype(np.float32)
    turb = periodic_noise(T, T, 20 * S, 44) * 0.8 + periodic_noise(T, T, 6 * S, 45) * 0.2
    ph = 2 * np.pi * (2 * xx + yy) / T + 3.0 * turb
    vein = np.exp(-(np.abs(np.sin(ph)) / 0.035) ** 2)[..., None]
    ph2 = 2 * np.pi * (xx - 3 * yy) / T + 3.5 * periodic_noise(T, T, 12 * S, 46)
    vein2 = np.exp(-(np.abs(np.sin(ph2)) / 0.025) ** 2)[..., None]
    base = base + col("#6A6E8A") * 0.20 * vein + col("#6A6E8A") * 0.08 * vein2
    pits = (fine > 0.84)[..., None]
    base = base * np.where(pits, 0.8, 1.0)
    return Image.fromarray(np.clip(base, 0, 255).astype(np.uint8), "RGB")


def main():
    os.makedirs(OUT, exist_ok=True)
    build_frame().save(os.path.join(OUT, "frame_9.png"))
    build_leather().save(os.path.join(OUT, "leather.png"))
    build_parchment().save(os.path.join(OUT, "parchment.png"))
    build_slate().save(os.path.join(OUT, "slate.png"))
    print("frame px/logical", S, "corner", CORNER, "border", BORDER, "->", OUT)


if __name__ == "__main__":
    main()
