"""App icon set (16-256 px + .ico) and the Steam store / library art, built from the game's own art.

    python3 tools/art/build_store_art.py

Outputs
    game/assets/ui/icon.png          256 px project icon (window / taskbar on Linux)
    game/assets/ui/icon.ico          16..256 multi-size icon for the Windows export
    steam/store_art/*.png            header, small / main / vertical capsule, library capsule, hero, logo
    steam/store_art/icons/*.png      every icon size on its own, for review

The icon is a bronze-rimmed medallion with the World Crystal over a crossed sword. Below 48 px the sword
and rim rivets are dropped so the crystal still reads at taskbar size.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GAME = os.path.join(ROOT, "game")
OUT = os.path.join(ROOT, "steam", "store_art")
FONT_LOGO = os.path.join(GAME, "assets/fonts/CinzelDecorative-Bold.ttf")
FONT_SUB = os.path.join(GAME, "assets/fonts/Cinzel-Bold.ttf")
SCENE = os.path.join(GAME, "assets/hd/scenes/forest.jpg")
PORTRAITS = os.path.join(GAME, "assets/hd/portraits")
# same line-up as the title poster: id, x (0..1), height scale, foot y, back row
POSTER = [("nova", 0.39, 0.92, 1.0, True), ("bjorn", 0.665, 0.96, 1.03, True), ("lyra", 0.22, 1.0, 1.1, False),
          ("pip", 0.79, 0.98, 1.1, False), ("kael", 0.5, 1.16, 1.2, False)]


# --------------------------------------------------------------------------- helpers
def vgrad(w, h, top, bot):
    g = Image.new("RGBA", (1, h))
    for y in range(h):
        k = y / max(1, h - 1)
        g.putpixel((0, y), tuple(int(top[i] + (bot[i] - top[i]) * k) for i in range(4)))
    return g.resize((w, h))


def fill_mask(mask, top, bot):
    """Gradient through a mask."""
    w, h = mask.size
    layer = vgrad(w, h, top, bot)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(layer, (0, 0), mask)
    return out


def circle_mask(size, cx, cy, r):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    return m


def poly_mask(size, pts):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return m


# --------------------------------------------------------------------------- icon
def icon_master(simple: bool, S=1024):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    c = S / 2
    # drop shadow
    sh = circle_mask((S, S), c, c + S * 0.02, S * 0.47).filter(ImageFilter.GaussianBlur(S * 0.02))
    im.alpha_composite(Image.composite(Image.new("RGBA", (S, S), (0, 0, 0, 150)), Image.new("RGBA", (S, S), (0, 0, 0, 0)), sh))
    # outline, bronze rim, dark bed
    im.alpha_composite(fill_mask(circle_mask((S, S), c, c, S * 0.47), (20, 12, 8, 255), (20, 12, 8, 255)))
    im.alpha_composite(fill_mask(circle_mask((S, S), c, c, S * 0.445), (255, 222, 150, 255), (140, 86, 30, 255)))
    im.alpha_composite(fill_mask(circle_mask((S, S), c, c, S * 0.385), (22, 14, 10, 255), (22, 14, 10, 255)))
    im.alpha_composite(fill_mask(circle_mask((S, S), c, c, S * 0.37), (58, 40, 92, 255), (16, 12, 34, 255)))
    d = ImageDraw.Draw(im)
    if not simple:
        for k in range(8):
            a = k * math.pi / 4 + math.pi / 8
            x, y = c + math.cos(a) * S * 0.415, c + math.sin(a) * S * 0.415
            r = S * 0.018
            d.ellipse([x - r, y - r, x + r, y + r], fill=(255, 240, 200, 255), outline=(60, 36, 14, 255), width=max(1, S // 300))
        # crossed sword behind the crystal
        sw = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        sd = ImageDraw.Draw(sw)
        bw = S * 0.035
        sd.polygon([(c - bw, c + S * 0.2), (c - bw, c - S * 0.26), (c, c - S * 0.32), (c + bw, c - S * 0.26), (c + bw, c + S * 0.2)],
                   fill=(225, 232, 245, 255), outline=(25, 20, 30, 255), width=S // 120)
        sd.rectangle([c - S * 0.12, c + S * 0.18, c + S * 0.12, c + S * 0.215], fill=(230, 180, 80, 255), outline=(25, 20, 30, 255), width=S // 140)
        sd.rectangle([c - S * 0.022, c + S * 0.215, c + S * 0.022, c + S * 0.3], fill=(110, 60, 30, 255), outline=(25, 20, 30, 255), width=S // 160)
        sd.ellipse([c - S * 0.035, c + S * 0.29, c + S * 0.035, c + S * 0.36], fill=(230, 180, 80, 255), outline=(25, 20, 30, 255), width=S // 160)
        sw = sw.rotate(-38, resample=Image.BICUBIC, center=(c, c))
        im.alpha_composite(sw)
    # glow behind the crystal
    gl = circle_mask((S, S), c, c, S * 0.24).filter(ImageFilter.GaussianBlur(S * 0.06))
    im.alpha_composite(Image.composite(Image.new("RGBA", (S, S), (120, 210, 255, 170)), Image.new("RGBA", (S, S), (0, 0, 0, 0)), gl))
    # faceted crystal
    k = 1.25 if simple else 1.0
    top, bot = (c, c - S * 0.27 * k), (c, c + S * 0.27 * k)
    l, r, m = (c - S * 0.14 * k, c - S * 0.03 * k), (c + S * 0.14 * k, c - S * 0.03 * k), (c, c - S * 0.03 * k)
    out = poly_mask((S, S), [top, r, bot, l]).filter(ImageFilter.MaxFilter(max(3, (S // 90) | 1)))
    im.alpha_composite(fill_mask(out, (10, 18, 40, 255), (10, 18, 40, 255)))
    for pts, a, b in [([top, l, m], (225, 248, 255, 255), (90, 180, 245, 255)), ([top, m, r], (165, 230, 255, 255), (50, 140, 230, 255)),
                      ([l, bot, m], (100, 190, 250, 255), (35, 100, 205, 255)), ([m, bot, r], (75, 160, 240, 255), (25, 75, 180, 255))]:
        im.alpha_composite(fill_mask(poly_mask((S, S), pts), a, b))
    hl = poly_mask((S, S), [(c - S * 0.03 * k, c - S * 0.2 * k), (c - S * 0.09 * k, c - S * 0.06 * k), (c - S * 0.06 * k, c - S * 0.06 * k)])
    im.alpha_composite(fill_mask(hl, (255, 255, 255, 200), (255, 255, 255, 120)))
    return im


def build_icons():
    big = icon_master(False)
    small = icon_master(True)
    sizes = [16, 20, 24, 32, 40, 48, 64, 96, 128, 256]
    imgs = {}
    os.makedirs(os.path.join(OUT, "icons"), exist_ok=True)
    for s in sizes:
        src = small if s < 48 else big
        im = src.resize((s, s), Image.LANCZOS)
        if s < 48:
            im = ImageEnhance.Sharpness(im).enhance(1.6)
        imgs[s] = im
        im.save(os.path.join(OUT, "icons", "icon_%d.png" % s))
    imgs[256].save(os.path.join(GAME, "assets/ui/icon.png"))
    imgs[256].save(os.path.join(GAME, "assets/ui/icon.ico"), sizes=[(s, s) for s in [16, 24, 32, 48, 64, 128, 256]],
                   append_images=[imgs[s] for s in [16, 24, 32, 48, 64, 128]])
    big.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, "icons", "icon_512.png"))
    return imgs


# --------------------------------------------------------------------------- logo
def logo(width):
    """IDLE PARTY in burnished gold with a dark outline, DESKTOP LEGENDS on a crimson ribbon (transparent)."""
    W = width
    fs = int(W * 0.17)
    f = ImageFont.truetype(FONT_LOGO, fs)
    txt = "IDLE PARTY"
    tw = f.getbbox(txt)[2]
    H = int(fs * 2.0)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    x = (W - tw) // 2
    y = int(fs * 0.05)
    m = Image.new("L", (W, H), 0)
    ImageDraw.Draw(m).text((x, y), txt, font=f, fill=255)
    bb = m.getbbox()
    stroke = m.filter(ImageFilter.MaxFilter((int(fs * 0.09) | 1)))
    glow = m.filter(ImageFilter.MaxFilter((int(fs * 0.13) | 1))).filter(ImageFilter.GaussianBlur(fs * 0.08))
    im.alpha_composite(fill_mask(glow, (255, 140, 40, 150), (255, 90, 20, 150)))
    im.alpha_composite(fill_mask(stroke, (40, 16, 8, 255), (25, 10, 6, 255)))
    gold = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gold.paste(vgrad(W, bb[3] - bb[1], (255, 248, 210, 255), (205, 120, 30, 255)), (0, bb[1]))
    im.alpha_composite(Image.composite(gold, Image.new("RGBA", (W, H), (0, 0, 0, 0)), m))
    # thin highlight on the upper half of the letters
    hi = Image.new("L", (W, H), 0)
    ImageDraw.Draw(hi).rectangle([0, bb[1], W, bb[1] + (bb[3] - bb[1]) * 0.35], fill=90)
    im.alpha_composite(Image.composite(Image.new("RGBA", (W, H), (255, 255, 255, 255)), Image.new("RGBA", (W, H), (0, 0, 0, 0)),
                                       Image.composite(hi, Image.new("L", (W, H), 0), m)))
    # ribbon
    fs2 = int(fs * 0.36)
    f2 = ImageFont.truetype(FONT_SUB, fs2)
    sub = "DESKTOP LEGENDS"
    sw = f2.getbbox(sub)[2]
    rw, rh = int(sw + fs2 * 2.2), int(fs2 * 1.7)
    rx, ry = (W - rw) // 2, bb[3] + int(fs * 0.08)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([rx - 6, ry - 6, rx + rw + 6, ry + rh + 6], radius=fs2 // 3, fill=(20, 10, 6, 255))
    d.rounded_rectangle([rx - 3, ry - 3, rx + rw + 3, ry + rh + 3], radius=fs2 // 3, fill=(214, 160, 80, 255))
    rib = Image.new("L", (W, H), 0)
    ImageDraw.Draw(rib).rounded_rectangle([rx, ry, rx + rw, ry + rh], radius=fs2 // 4, fill=255)
    im.alpha_composite(fill_mask(rib, (150, 28, 38, 255), (70, 10, 18, 255)))
    d.text(((W - sw) // 2, ry + (rh - fs2) // 2 - fs2 * 0.08), sub, font=f2, fill=(255, 236, 200, 255), stroke_width=max(1, fs2 // 14), stroke_fill=(30, 8, 8, 255))
    return im.crop(im.getbbox())


# --------------------------------------------------------------------------- key art
def key_art(w, h, with_logo=True, logo_w=0.62, hero_scale=1.0, blur=0.0, logo_bottom=0.95):
    bg = Image.open(SCENE).convert("RGB")
    sc = max(w / bg.width, h / bg.height) * 1.06
    bg = bg.resize((int(bg.width * sc), int(bg.height * sc)), Image.LANCZOS)
    bg = bg.crop(((bg.width - w) // 2, (bg.height - h) // 2, (bg.width - w) // 2 + w, (bg.height - h) // 2 + h))
    if blur:
        bg = bg.filter(ImageFilter.GaussianBlur(blur))
    # teal storm grade like the title screen
    bg = Image.blend(bg, Image.new("RGB", (w, h), (20, 50, 46)), 0.45)
    bg = ImageEnhance.Brightness(bg).enhance(0.75)
    im = bg.convert("RGBA")
    im.alpha_composite(vgrad(w, int(h * 0.6), (3, 12, 10, 190), (3, 12, 10, 0)), (0, 0))
    # god rays
    rays = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rays)
    for i in range(6):
        x0 = w * (0.08 + i * 0.13)
        wt = w * (0.018 + 0.01 * (i % 3))
        rd.polygon([(x0 - wt, 0), (x0 + wt, 0), (x0 + w * 0.2 + wt * 3, h * 0.85), (x0 + w * 0.2 - wt * 3, h * 0.85)], fill=(220, 255, 230, 22))
    im.alpha_composite(rays.filter(ImageFilter.GaussianBlur(w * 0.01)))
    # heroes, back row first, rim light from a blurred silhouette
    for hid, fx, hs, fy, back in sorted(POSTER, key=lambda p: not p[4]):
        p = Image.open(os.path.join(PORTRAITS, hid + ".png")).convert("RGBA")
        # same framing as the title poster: height and foot line relative to the frame height
        hh = int(h * hs * hero_scale)
        pw = int(p.width * hh / p.height)
        p = p.resize((pw, hh), Image.LANCZOS)
        px, py = int(w * fx - pw / 2), int(h * (1.0 + (fy - 1.0) * hero_scale)) - hh
        a = p.split()[-1]
        rim_c = (140, 240, 215, 80) if back else (255, 200, 120, 110)
        rim = Image.new("RGBA", p.size, rim_c)
        rim.putalpha(a.filter(ImageFilter.GaussianBlur(1.2)).point(lambda v: int(v * rim_c[3] / 255)))
        ro = max(1, h // 300)
        for o in [(-ro, 0), (ro, 0), (0, -ro)]:
            im.alpha_composite(rim, (px + o[0], py + o[1]))
        if back:
            p = Image.merge("RGBA", (*ImageEnhance.Brightness(p.convert("RGB")).enhance(0.68).split(), a))
        im.alpha_composite(p, (px, py))
    # floor fog, vignette
    im.alpha_composite(vgrad(w, int(h * 0.45), (3, 6, 6, 0), (3, 4, 4, 235)), (0, h - int(h * 0.45)))
    vig = Image.new("L", (w, h), 0)
    ImageDraw.Draw(vig).ellipse([-w * 0.15, -h * 0.25, w * 1.15, h * 1.25], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(min(w, h) * 0.12))
    dark = Image.new("RGBA", (w, h), (0, 0, 0, 200))
    dark.putalpha(vig.point(lambda v: 200 - int(v * 200 / 255)))
    im.alpha_composite(dark)
    if with_logo:
        lg = logo(int(w * logo_w))
        im.alpha_composite(lg, ((w - lg.width) // 2, int(h * logo_bottom) - lg.height))
    return im.convert("RGB")


def build_steam():
    os.makedirs(OUT, exist_ok=True)
    specs = {
        "header_capsule_920x430": (920, 430, dict(logo_w=0.62, logo_bottom=0.95)),
        "small_capsule_462x174": (462, 174, dict(logo_w=0.78, logo_bottom=0.96, hero_scale=0.9)),
        "main_capsule_1232x706": (1232, 706, dict(logo_w=0.58, logo_bottom=0.95)),
        "vertical_capsule_748x896": (748, 896, dict(logo_w=0.86, logo_bottom=0.95, hero_scale=0.9)),
        "library_capsule_600x900": (600, 900, dict(logo_w=0.88, logo_bottom=0.95, hero_scale=0.9)),
        "library_hero_3840x1240": (3840, 1240, dict(with_logo=False, blur=2.0, hero_scale=0.78)),
    }
    for name, (w, h, kw) in specs.items():
        key_art(w, h, **kw).save(os.path.join(OUT, name + ".png"))
    logo(1280).save(os.path.join(OUT, "library_logo_1280.png"))


if __name__ == "__main__":
    build_icons()
    build_steam()
    print("icon set + steam art ->", OUT)
