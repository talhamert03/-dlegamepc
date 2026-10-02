#!/usr/bin/env python3
"""Generates the pixel-art UI kit into game/assets/ui/."""
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "game", "assets", "ui")
os.makedirs(OUT, exist_ok=True)


def hx(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def rect(im, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if 0 <= x < im.width and 0 <= y < im.height:
                im.putpixel((x, y), c)


def frame(im, x0, y0, x1, y1, c):
    for x in range(x0, x1 + 1):
        im.putpixel((x, y0), c)
        im.putpixel((x, y1), c)
    for y in range(y0, y1 + 1):
        im.putpixel((x0, y), c)
        im.putpixel((x1, y), c)


def save(im, name):
    im.save(os.path.join(OUT, name))


OUTL = hx("#140E10")
# ------------------------------------------------------------------ panel frame (9-slice, margin 8)
def panel():
    im = new(32, 32)
    rect(im, 0, 0, 31, 31, OUTL)
    # wood/metal frame band (3px) with vertical gradient
    for y in range(1, 31):
        t = y / 31
        c = tuple(int(a + (b - a) * t) for a, b in zip(hx("#7A5A44")[:3], hx("#3A2A22")[:3])) + (255,)
        for x in range(1, 31):
            im.putpixel((x, y), c)
    frame(im, 1, 1, 30, 30, hx("#8E6B52"))
    frame(im, 4, 4, 27, 27, hx("#24181A"))
    rect(im, 5, 5, 26, 26, hx("#1E1A1F", 238))
    # inner top shadow
    for x in range(5, 27):
        im.putpixel((x, 5), hx("#151116", 245))
    # corner metal plates + rivets
    for cx, cy in ((0, 0), (25, 0), (0, 25), (25, 25)):
        rect(im, cx, cy, cx + 6, cy + 6, OUTL)
        rect(im, cx + 1, cy + 1, cx + 5, cy + 5, hx("#8A8796"))
        rect(im, cx + 1, cy + 1, cx + 5, cy + 1, hx("#B9B6C4"))
        rect(im, cx + 1, cy + 5, cx + 5, cy + 5, hx("#5A5866"))
        im.putpixel((cx + 3, cy + 3), hx("#E8D9A8"))
        im.putpixel((cx + 4, cy + 4), hx("#6A5A3A"))
    save(im, "panel.png")


# ------------------------------------------------------------------ title plaque (margin 6)
def plaque():
    im = new(24, 16)
    rect(im, 0, 0, 23, 15, OUTL)
    rect(im, 1, 1, 22, 14, hx("#C8A165"))
    rect(im, 2, 2, 21, 13, hx("#4A3A30"))
    rect(im, 3, 3, 20, 12, hx("#2A2226"))
    for x in range(3, 21):
        im.putpixel((x, 3), hx("#3A3036"))
    rect(im, 1, 1, 22, 1, hx("#E8C98A"))
    save(im, "plaque.png")


# ------------------------------------------------------------------ buttons (margin 4)
BTN = {
    "orange": ("#E8742A", "#FFB36A", "#9A4418"),
    "blue": ("#3D6FD6", "#8FB4FF", "#22408A"),
    "brown": ("#6A4A3A", "#9A7258", "#3A281F"),
    "red": ("#C9363A", "#FF8A80", "#7A1E22"),
    "green": ("#3E9E4A", "#8FE08A", "#1F5A28"),
    "gray": ("#4A4650", "#7A7684", "#2A2830"),
    "gold": ("#C8962E", "#FFE08A", "#7A5418"),
}


def button(name, base, light, dark, state):
    im = new(16, 12)
    b, l, d = hx(base), hx(light), hx(dark)
    if state == "hover":
        b = tuple(min(255, int(c * 1.15)) for c in b[:3]) + (255,)
    if state == "pressed":
        b = tuple(int(c * 0.85) for c in b[:3]) + (255,)
        l, d = d, l
    if state == "disabled":
        g = int(sum(b[:3]) / 3 * 0.6)
        b = (g, g, g + 6, 255)
        l = (g + 25, g + 25, g + 30, 255)
        d = (g - 20, g - 20, g - 15, 255)
    rect(im, 0, 0, 15, 11, OUTL)
    rect(im, 1, 1, 14, 10, b)
    rect(im, 1, 1, 14, 1, l)
    rect(im, 1, 1, 1, 9, l)
    rect(im, 1, 10, 14, 10, d)
    rect(im, 14, 2, 14, 10, d)
    # corner cut
    for p in ((0, 0), (15, 0), (0, 11), (15, 11)):
        im.putpixel(p, (0, 0, 0, 0))
    save(im, f"btn_{name}_{state}.png")


# ------------------------------------------------------------------ item slot 20x20
def slot(state="normal"):
    im = new(20, 20)
    rect(im, 0, 0, 19, 19, OUTL)
    base = hx("#2C2630") if state == "normal" else hx("#3A3442")
    rect(im, 1, 1, 18, 18, base)
    rect(im, 1, 1, 18, 1, hx("#1A161C"))
    rect(im, 1, 1, 1, 18, hx("#1A161C"))
    rect(im, 1, 18, 18, 18, hx("#463E4A"))
    rect(im, 18, 1, 18, 18, hx("#463E4A"))
    save(im, f"slot_{state}.png")


def slot_rarity():
    cols = {"common": "#8A8A8A", "magic": "#4F8CFF", "rare": "#F5D547", "epic": "#B05CFF", "legendary": "#FF8A1F",
            "set": "#3DDC84", "mythic": "#FF3B5C"}
    for k, c in cols.items():
        im = new(20, 20)
        frame(im, 1, 1, 18, 18, hx(c))
        # inner glow corners
        g = hx(c, 110)
        for p in ((2, 2), (17, 2), (2, 17), (17, 17), (3, 2), (2, 3), (16, 2), (17, 3), (2, 16), (3, 17), (16, 17), (17, 16)):
            im.putpixel(p, g)
        save(im, f"slot_{k}.png")


# ------------------------------------------------------------------ round buttons for the strip (14x14)
ICONS = {
    "town": ["...k...", "..kwk..", ".kwwwk.", "kwwwwwk", ".wwkww.", ".wwkww.", ".wwkww."],
    "chart": [".......", ".....w.", "...w.w.", "...w.w.", ".w.w.w.", ".w.w.w.", "wwwwwww"],
    "auto": ["..www..", ".w...w.", "w..w..w", "w..ww.w", "w.....w", ".w...w.", "..www.."],
    "gear": ["..w.w..", ".wwwww.", "wwk.kww", ".wk.kw.", "wwk.kww", ".wwwww.", "..w.w.."],
    "mail": ["wwwwwww", "ww...ww", "w.w.w.w", "w..w..w", "w.....w", "wwwwwww", "......."],
    "power": ["...w...", ".w.w.w.", "w..w..w", "w.....w", "w.....w", ".w...w.", "..www.."],
    "note": ["...wwww", "...w..w", "...w..w", "...w..w", ".www.ww", "wwww.ww", ".ww...."],
    "quest": ["..www..", ".w...w.", ".....w.", "....w..", "...w...", ".......", "...w..."],
    "menu": ["wwwwwww", ".......", "wwwwwww", ".......", "wwwwwww", ".......", "......."],
    "close": ["w.....w", ".w...w.", "..w.w..", "...w...", "..w.w..", ".w...w.", "w.....w"],
    "plus": ["...w...", "...w...", "...w...", "wwwwwww", "...w...", "...w...", "...w..."],
    "minus": [".......", ".......", ".......", "wwwwwww", ".......", ".......", "......."],
    "lock": ["..www..", ".w...w.", ".w...w.", "wwwwwww", "www.www", "wwwwwww", "wwwwwww"],
    "check": [".......", "......w", ".....w.", "w...w..", ".w.w...", "..w....", "......."],
    "arrow_up": ["...w...", "..www..", ".wwwww.", "...w...", "...w...", "...w...", "......."],
    "arrow_down": [".......", "...w...", "...w...", "...w...", ".wwwww.", "..www..", "...w..."],
    "sort": ["w......", "ww.....", "www....", "wwww...", "wwwww..", "wwwwww.", "wwwwwww"],
    "eye": [".......", "..www..", ".w.k.w.", "w.kkk.w", ".w.k.w.", "..www..", "......."],
    "pin": ["..www..", "..www..", ".wwwww.", "...w...", "...w...", "...w...", "......."],
    "swap": ["..w....", ".ww....", "wwwwww.", ".......", ".wwwwww", "....ww.", "....w.."],
}
ICON_PAL = {"w": hx("#F2E6C9"), "k": hx("#2A2226")}


def icon_img(rows, color=None):
    pal = dict(ICON_PAL)
    if color:
        pal["w"] = hx(color)
    im = new(len(rows[0]), len(rows))
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in pal:
                im.putpixel((x, y), pal[ch])
    return im


def round_button(name, base, light, dark, icon):
    for state in ("normal", "hover", "pressed"):
        im = new(14, 14)
        b, l, d = hx(base), hx(light), hx(dark)
        if state == "hover":
            b = tuple(min(255, int(c * 1.15)) for c in b[:3]) + (255,)
        if state == "pressed":
            b = tuple(int(c * 0.85) for c in b[:3]) + (255,)
        for y in range(14):
            for x in range(14):
                dx, dy = x - 6.5, y - 6.5
                r = (dx * dx + dy * dy) ** 0.5
                if r <= 6.9:
                    c = OUTL
                    if r <= 5.9:
                        c = b
                        if dx + dy < -5.5:
                            c = l
                        elif dx + dy > 5.5:
                            c = d
                    im.putpixel((x, y), c)
        ic = icon_img(ICONS[icon])
        im.alpha_composite(ic, (4, 4 if state != "pressed" else 5))
        save(im, f"round_{name}_{state}.png")


def icons():
    os.makedirs(os.path.join(OUT, "icons"), exist_ok=True)
    for k, rows in ICONS.items():
        icon_img(rows).save(os.path.join(OUT, "icons", f"{k}.png"))
    # coloured small glyphs
    extra = {
        "gold": (["..www..", ".wyyyw.", "wyywyyw", "wywwwyw", "wyywyyw", ".wyyyw.", "..www.."], {"w": "#7A5418", "y": "#F7C948"}),
        "heart": ([".rr.rr.", "rrrrrrr", "rrwrrrr", "rrrrrrr", ".rrrrr.", "..rrr..", "...r..."], {"r": "#D63A3A", "w": "#FFC0C0"}),
        "star": (["...y...", "...y...", "yyyyyyy", ".yyyyy.", "..yyy..", ".yy.yy.", "y.....y"], {"y": "#F7C948"}),
        "skull": ([".wwwww.", "wwwwwww", "wkwwwkw", "wwwkwww", ".wwwww.", ".w.w.w.", "......."], {"w": "#E6DDC6", "k": "#2A2226"}),
        "gem": (["..bbb..", ".bwbbb.", "bwbbbbb", ".bbbbb.", "..bbb..", "...b...", "......."], {"b": "#7FD8FF", "w": "#FFFFFF"}),
        "chest": ([".kkkkk.", "kyyyyyk", "kkkwkkk", "kyywyyk", "kyyyyyk", "kkkkkkk", "......."], {"k": "#3A2A22", "y": "#C8962E", "w": "#F7E08A"}),
        "sword": (["......w", ".....w.", "....w..", "y..w...", ".yw....", ".ky....", "k..y..."], {"w": "#E6E8F0", "y": "#C8962E", "k": "#5A3A2A"}),
        "shield": (["bbbbbbb", "bwwbbbb", "bwbbbbb", "bbbbbbb", ".bbbbb.", "..bbb..", "...b..."], {"b": "#3D6FD6", "w": "#BFD8FF"}),
        "boot": ([".kkk...", ".kbk...", ".kbk...", ".kbk...", ".kbbkk.", "kbbbbbk", "kkkkkkk"], {"k": "#2A1A14", "b": "#8E5B3E"}),
        "potion": (["..kk...", "..ww...", ".wrrw..", "wrrrrw.", "wrrrrw.", ".wwww..", "......."], {"k": "#5A3A2A", "w": "#DDEEFF", "r": "#D63A3A"}),
        "clock": ([".wwwww.", "w..w..w", "w..w..w", "w..ww.w", "w.....w", "w.....w", ".wwwww."], {"w": "#F2E6C9"}),
        "crown": (["y..y..y", "yy.y.yy", "yyyyyyy", "yryyyry", "yyyyyyy", ".......", "......."], {"y": "#F7C948", "r": "#D63A3A"}),
        "hammer": (["kkkkk..", "kkkkk..", "..b....", "..b....", "..b....", "..b....", "..b...."], {"k": "#8A8796", "b": "#8E5B3E"}),
        "map": (["yyyyyyy", "y.r...y", "y..r..y", "y...r.y", "y..rr.y", "y.....y", "yyyyyyy"], {"y": "#E8D9A8", "r": "#D63A3A"}),
        "people": (["..w..w.", ".www.ww", "..w..w.", ".www.ww", "wwwwwww", "wwwwwww", "......."], {"w": "#F2E6C9"}),
        "bag": (["..kkk..", ".k...k.", "bbbbbbb", "bbbybbb", "bbbbbbb", "bbbbbbb", ".bbbbb."], {"k": "#3A2A22", "b": "#8E5B3E", "y": "#F7C948"}),
        "book": (["kkkkkk.", "krrrrk.", "krwwrk.", "krrrrk.", "krrrrk.", "kwwwwwk", "kkkkkkk"], {"k": "#3A2A22", "r": "#8A3A5A", "w": "#F3E7C8"}),
        "flag": (["krrrr..", "krrrrr.", "krrrr..", "k......", "k......", "k......", "k......"], {"k": "#5A3A2A", "r": "#D63A3A"}),
        "sparkle": (["...w...", "...w...", ".wwwww.", "wwwywww", ".wwwww.", "...w...", "...w..."], {"w": "#FFE08A", "y": "#FFFFFF"}),
        "tower": ([".w.w.w.", ".wwwww.", "..www..", "..wkw..", "..www..", "..wkw..", ".wwwww."], {"w": "#9AA2B0", "k": "#2A2226"}),
    }
    for k, (rows, pal) in extra.items():
        p = {c: hx(v) for c, v in pal.items()}
        im = new(len(rows[0]), len(rows))
        for y, r in enumerate(rows):
            for x, ch in enumerate(r):
                if ch in p:
                    im.putpixel((x, y), p[ch])
        im.save(os.path.join(OUT, "icons", f"{k}.png"))


def bars():
    im = new(8, 6)
    rect(im, 0, 0, 7, 5, OUTL)
    rect(im, 1, 1, 6, 4, hx("#2A2226"))
    save(im, "bar_bg.png")


def strip_frame():
    # side control panel background (9-slice margin 4)
    im = new(16, 16)
    rect(im, 0, 0, 15, 15, OUTL)
    rect(im, 1, 1, 14, 14, hx("#2A2228", 235))
    frame(im, 1, 1, 14, 14, hx("#5C4033"))
    rect(im, 1, 1, 14, 1, hx("#7A5A44"))
    save(im, "strip_panel.png")
    # tooltip (9-slice margin 3)
    t = new(10, 10)
    rect(t, 0, 0, 9, 9, OUTL)
    rect(t, 1, 1, 8, 8, hx("#16121A", 245))
    frame(t, 1, 1, 8, 8, hx("#5C4F66"))
    save(t, "tooltip.png")


def app_icon():
    # 64x64 app icon: chest + sword on dark plaque
    im = new(64, 64)
    for y in range(64):
        for x in range(64):
            dx, dy = x - 31.5, y - 31.5
            if (dx * dx + dy * dy) ** 0.5 < 31:
                im.putpixel((x, y), hx("#2A2226"))
            if 29 < (dx * dx + dy * dy) ** 0.5 < 31:
                im.putpixel((x, y), hx("#C8A165"))
    ch = Image.open(os.path.join(OUT, "icons", "chest.png")).resize((35, 35), Image.NEAREST)
    im.alpha_composite(ch, (14, 18))
    sw = Image.open(os.path.join(OUT, "icons", "sword.png")).resize((28, 28), Image.NEAREST)
    im.alpha_composite(sw, (24, 6))
    save(im, "icon.png")


if __name__ == "__main__":
    panel()
    plaque()
    for n, (b, l, d) in BTN.items():
        for st in ("normal", "hover", "pressed", "disabled"):
            button(n, b, l, d, st)
    slot("normal")
    slot("hover")
    slot_rarity()
    icons()
    round_button("red", "#C9363A", "#FF8A80", "#7A1E22", "town")
    round_button("green", "#3E9E4A", "#8FE08A", "#1F5A28", "chart")
    round_button("blue", "#3D6FD6", "#8FB4FF", "#22408A", "auto")
    bars()
    strip_frame()
    app_icon()
    print("ui kit done")
