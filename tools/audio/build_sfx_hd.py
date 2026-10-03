#!/usr/bin/env python3
"""Layered, physically-flavoured combat SFX (44.1 kHz) -> game/assets/audio/sfx/*.ogg

Each sound is built from a few layers instead of a single chip voice:
  transient click (shaped noise) + low body thump (pitch-dropping sine) + material layer
  (inharmonic metal partials for blades, wood/flesh noise for blunt hits, sparkles for magic)
  + a short stereo-less room tail. Several variants per sound so repeated hits never sound identical.

  python3 tools/audio/build_sfx_hd.py
"""
import os
import subprocess
import wave

import numpy as np
from scipy import signal

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SFX = os.path.join(ROOT, "game/assets/audio/sfx")
SR = 44100
rng = np.random.default_rng(11)


def t(d):
    return np.arange(int(SR * d)) / SR


def noise(d):
    return rng.standard_normal(int(SR * d))


def band(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, hi], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lp(x, f, order=2):
    return signal.sosfilt(signal.butter(order, f, btype="low", fs=SR, output="sos"), x)


def hp(x, f, order=2):
    return signal.sosfilt(signal.butter(order, f, btype="high", fs=SR, output="sos"), x)


def expdec(d, tau, attack=0.001):
    tt = t(d)
    a = np.clip(tt / max(attack, 1e-4), 0, 1)
    return a * np.exp(-tt / tau)


def pad(x, d):
    n = int(SR * d)
    return np.pad(x, (0, max(0, n - len(x))))[:n]


def mix(d, *layers):
    out = np.zeros(int(SR * d))
    for offset, x in layers:
        i = int(SR * offset)
        x = x[: max(0, len(out) - i)]
        out[i:i + len(x)] += x
    return out


def room(x, wet=0.18, size=0.045):
    """Tiny Schroeder-ish room: a few damped combs."""
    y = x.copy()
    for k, g in [(1.0, 0.5), (1.37, 0.42), (1.71, 0.36), (2.13, 0.3)]:
        dl = int(SR * size * k)
        c = np.zeros(len(x) + dl * 6)
        c[: len(x)] += x
        for i in range(dl, len(c)):
            c[i] += c[i - dl] * g
        y = np.pad(y, (0, len(c) - len(y)))
        y += lp(c, 5000) * wet / 4
    return y


def thump(d, f0, f1, tau):
    tt = t(d)
    f = f1 + (f0 - f1) * np.exp(-tt / (tau * 0.35))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * expdec(d, tau, 0.0015)


def click(d=0.012, lo=1500, hi=9000):
    return band(noise(d), lo, hi) * expdec(d, 0.0025, 0.0002)


def metal(d, base, tau, n=5):
    tt = t(d)
    ratios = [1.0, 1.47, 2.09, 2.56, 3.14, 3.88][:n]
    x = np.zeros(len(tt))
    for i, r in enumerate(ratios):
        x += np.sin(2 * np.pi * base * r * tt + rng.random() * 6) * np.exp(-tt / (tau * (1.0 - i * 0.12))) / (1 + i * 0.6)
    return x


def whoosh(d, f0, f1):
    x = noise(d)
    out = np.zeros_like(x)
    seg = 256
    for i in range(0, len(x), seg):
        k = i / len(x)
        fc = f0 + (f1 - f0) * k
        out[i:i + seg] = band(x[i:i + seg + 512], fc * 0.7, min(fc * 1.4, 18000), 1)[:len(out[i:i + seg])]
    env = np.sin(np.linspace(0, np.pi, len(x))) ** 1.6
    return out * env


def fade(x, ms=6):
    n = int(SR * ms / 1000)
    x = x.copy()
    x[-n:] *= np.linspace(1, 0, n)
    return x


def save(name, x, peak=0.9):
    x = fade(np.asarray(x, dtype=np.float64))
    x = np.tanh(x / (np.max(np.abs(x)) or 1) * 1.4) / np.tanh(1.4) * peak
    pcm = (x * 32767).astype(np.int16)
    tmp = os.path.join(SFX, name + ".wav")
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5",
                    os.path.join(SFX, name + ".ogg")], check=True)
    os.remove(tmp)


def main():
    os.makedirs(SFX, exist_ok=True)
    # blade hits: sharp click + metallic ring + flesh thud
    for i, (base, f0) in enumerate([(1850, 180), (2150, 160), (1650, 200)]):
        d = 0.42
        x = mix(d, (0, click(0.014) * 0.9), (0, thump(0.18, f0, 60, 0.07) * 0.9),
                (0.002, metal(0.38, base, 0.07) * 0.32), (0, lp(noise(0.12), 2200) * expdec(0.12, 0.025) * 0.5))
        save(f"hit{i}", room(x, 0.14))
    # blunt / beast hits (heavy weapons, monsters)
    for i, f0 in enumerate([140, 120]):
        d = 0.36
        x = mix(d, (0, click(0.012, 600, 5000) * 0.7), (0, thump(0.3, f0, 45, 0.11) * 1.2),
                (0, lp(noise(0.2), 900) * expdec(0.2, 0.05) * 0.7))
        save(f"hit_blunt{i}", room(x, 0.16))
    # critical: bigger, with a boom and a long bright ring
    d = 0.75
    x = mix(d, (0, click(0.02, 2000, 12000) * 1.0), (0, thump(0.5, 220, 40, 0.16) * 1.4),
            (0.003, metal(0.7, 2400, 0.16, 6) * 0.45), (0.0, hp(noise(0.25), 3000) * expdec(0.25, 0.06) * 0.35))
    save("crit", room(x, 0.22, 0.06))
    # weapon swing (played at wind-up)
    for i, (a, b) in enumerate([(700, 3200), (500, 2600)]):
        save(f"swing{i}", whoosh(0.22, a, b) * 0.9, 0.6)
    # arrow release + impact
    d = 0.3
    x = mix(d, (0, band(noise(0.03), 2000, 7000) * expdec(0.03, 0.006) * 0.8), (0.0, thump(0.09, 300, 120, 0.02) * 0.4),
            (0.01, whoosh(0.2, 2500, 5000) * 0.6))
    save("shoot", x, 0.55)
    # magic cast: rising shimmer
    d = 0.5
    tt = t(d)
    sh = np.zeros(len(tt))
    for f in [880, 1320, 1760, 2640]:
        sh += np.sin(2 * np.pi * f * tt * (1 + tt * 0.6)) * (1 + np.sin(2 * np.pi * 9 * tt)) * 0.5
    x = sh * np.sin(np.linspace(0, np.pi, len(tt))) ** 2 * 0.35 + whoosh(d, 400, 4000) * 0.5
    save("magic", room(x, 0.25), 0.55)
    # magic impact: sparkle burst
    d = 0.45
    x = mix(d, (0, click(0.01, 3000, 14000)), (0, thump(0.2, 400, 90, 0.05) * 0.6),
            (0.0, metal(0.42, 3100, 0.09, 4) * 0.25), (0.0, hp(noise(0.3), 5000) * expdec(0.3, 0.08) * 0.3))
    save("hit_magic", room(x, 0.25))
    # death puff (monster dissolve)
    d = 0.5
    x = mix(d, (0, thump(0.35, 180, 50, 0.1) * 0.8), (0, lp(noise(0.45), 1800) * expdec(0.45, 0.12) * 0.6))
    save("death", room(x, 0.2), 0.6)
    # ---- weapon-specific impacts
    # blade slash: fast swish into a wet cut + faint steel
    for i, f0 in enumerate([5200, 4300, 6100]):
        d = 0.38
        sw = whoosh(0.09, f0 * 0.4, f0) * 0.8
        cut = band(noise(0.08), 1200, 6000) * expdec(0.08, 0.018) * 1.0
        x = mix(d, (0, sw), (0.07, cut), (0.07, thump(0.14, 200, 70, 0.04) * 0.7), (0.072, metal(0.25, 2900 + i * 300, 0.04, 4) * 0.15))
        save(f"slash{i}", room(x, 0.12))
    # heavy chop (axes, greatswords): swish + crunch + deep thud
    d = 0.45
    x = mix(d, (0, whoosh(0.12, 900, 3500) * 0.7), (0.1, lp(noise(0.12), 1600) * expdec(0.12, 0.03) * 1.2),
            (0.1, thump(0.3, 150, 42, 0.1) * 1.3), (0.1, click(0.012, 800, 6000) * 0.8))
    save("chop", room(x, 0.16))
    # arrow: string twang + whoosh when fired, wooden thunk when it lands
    d = 0.35
    tw = np.sin(2 * np.pi * 180 * t(0.25) * (1 + 0.15 * np.exp(-t(0.25) * 30))) * expdec(0.25, 0.05)
    x = mix(d, (0, tw * 0.5), (0, click(0.008, 1500, 6000) * 0.7), (0.02, whoosh(0.25, 2500, 6500) * 0.55))
    save("arrow_fly", x, 0.5)
    d = 0.3
    x = mix(d, (0, click(0.01, 900, 5000) * 1.0), (0, thump(0.12, 520, 160, 0.025) * 0.8),
            (0.004, band(noise(0.06), 300, 1500) * expdec(0.06, 0.015) * 0.6))
    save("arrow_hit", room(x, 0.1))
    # spell impacts by element
    d = 0.6
    crackle = np.zeros(int(SR * 0.5))
    for k in range(60):
        i0 = rng.integers(0, len(crackle) - 200)
        seg = band(rng.standard_normal(120), 2000, 9000)
        crackle[i0:i0 + len(seg)] += seg * rng.uniform(0.2, 1.0) * np.exp(-i0 / (SR * 0.2))
    x = mix(d, (0, lp(noise(0.4), 900) * np.sin(np.linspace(0, np.pi, int(SR * 0.4))) ** 0.5 * expdec(0.4, 0.15) * 1.4),
            (0, thump(0.3, 120, 50, 0.08)), (0.02, crackle * 0.5))
    save("magic_fire", room(x, 0.2))
    d = 0.6
    shards = np.zeros(int(SR * 0.5))
    for k in range(14):
        i0 = int(rng.integers(0, int(SR * 0.12)))
        f = rng.uniform(3000, 7500)
        seg = np.sin(2 * np.pi * f * t(0.25)) * expdec(0.25, 0.04)
        shards[i0:i0 + len(seg)] += seg[: len(shards) - i0] * rng.uniform(0.3, 1.0)
    x = mix(d, (0, click(0.015, 3000, 14000)), (0, shards * 0.35), (0, hp(noise(0.3), 4000) * expdec(0.3, 0.05) * 0.4))
    save("magic_ice", room(x, 0.25))
    d = 0.45
    tt0 = t(0.3)
    saw = ((tt0 * 95 + np.cumsum(rng.standard_normal(len(tt0))) * 0.002) % 1.0) * 2 - 1
    x = mix(d, (0, (saw * 0.6 + hp(noise(0.3), 2000) * 0.6) * expdec(0.3, 0.06)), (0, click(0.02, 2000, 12000)))
    save("magic_shock", room(x, 0.15))
    d = 0.8
    x = mix(d, (0, bell_like := np.sum([np.sin(2 * np.pi * f * t(0.7)) * np.exp(-t(0.7) * (3 + i)) / (1 + i)
                                         for i, f in enumerate([1046, 1568, 2093, 2637])], axis=0) * 0.5),
            (0, hp(noise(0.3), 5000) * expdec(0.3, 0.08) * 0.3), (0, thump(0.2, 300, 120, 0.05) * 0.4))
    save("magic_holy", room(x, 0.3))
    d = 0.6
    tt1 = t(0.45)
    warp = np.sin(2 * np.pi * np.cumsum(90 - 50 * tt1) / SR * 1.0) * expdec(0.45, 0.15)
    x = mix(d, (0, warp * 0.8), (0, lp(noise(0.45), 700) * expdec(0.45, 0.12) * 0.9), (0, click(0.012, 600, 4000) * 0.5))
    save("magic_dark", room(x, 0.25))
    # equip: leather rustle + buckle clink; unequip: softer rustle
    d = 0.4
    x = mix(d, (0, band(noise(0.18), 800, 4000) * expdec(0.18, 0.05) * 0.6), (0.06, metal(0.3, 2600, 0.05, 4) * 0.35),
            (0.06, click(0.01, 2000, 9000) * 0.6), (0.0, thump(0.12, 220, 90, 0.03) * 0.4))
    save("equip", room(x, 0.12), 0.65)
    d = 0.3
    x = mix(d, (0, band(noise(0.2), 600, 3000) * expdec(0.2, 0.06) * 0.6), (0.02, thump(0.1, 180, 80, 0.03) * 0.3))
    save("unequip", room(x, 0.1), 0.5)
    # chests: drop (wooden thud + coin jingle), shake (rattling lid), open (creak + clunk + shimmer)
    d = 0.7
    jingle = np.zeros(int(SR * 0.6))
    for k in range(7):
        jingle += pad(np.pad(metal(0.25, 3000 + rng.random() * 2500, 0.05, 4), (int(SR * (0.04 + k * 0.05 + rng.random() * 0.03)), 0)), 0.6) * (0.5 - k * 0.05)
    x = mix(d, (0, thump(0.3, 140, 60, 0.07) * 1.0), (0, lp(noise(0.08), 1400) * expdec(0.08, 0.02) * 0.8),
            (0.05, thump(0.2, 120, 60, 0.05) * 0.4), (0.06, jingle * 0.5))
    save("chest_drop", room(x, 0.14), 0.8)
    d = 0.5
    x = np.zeros(int(SR * d))
    for k in range(6):
        x += pad(np.pad(lp(noise(0.05), 2500) * expdec(0.05, 0.012) * (0.5 + 0.1 * k), (int(SR * k * 0.07), 0)), d)
        x += pad(np.pad(metal(0.08, 900 + rng.random() * 300, 0.02, 3) * 0.25, (int(SR * k * 0.07), 0)), d)
    save("chest_shake", room(x, 0.1), 0.6)
    d = 1.4
    creak_t = t(0.35)
    creak = np.sin(2 * np.pi * np.cumsum(180 + 120 * creak_t + 25 * np.sin(2 * np.pi * 31 * creak_t)) / SR)
    creak = band(np.sign(creak) * np.abs(creak) ** 0.3, 300, 2500) * np.sin(np.linspace(0, np.pi, len(creak_t))) * 0.35
    shimmer = np.zeros(int(SR * 1.1))
    for k in range(12):
        f = 1800 * 2 ** (k / 6)
        shimmer += pad(np.pad(np.sin(2 * np.pi * f * t(0.6)) * expdec(0.6, 0.18) * 0.12, (int(SR * k * 0.04), 0)), 1.1)
    x = mix(d, (0, creak), (0.3, thump(0.3, 160, 55, 0.08) * 0.9), (0.3, click(0.02, 400, 3000) * 0.6),
            (0.33, lp(noise(0.5), 9000) * expdec(0.5, 0.12) * 0.08), (0.34, shimmer), (0.36, jingle * 0.4))
    save("chest_open", room(x, 0.22), 0.85)
    # ---------------------------------------------------------------- item handling, per material
    def pluck_ks(f, d, decay=0.996, bright=0.5):
        n = int(SR * d)
        per = max(2, int(SR / f))
        x = np.zeros(n)
        x[:per] = rng.uniform(-1, 1, per)
        x[:per] = signal.lfilter([bright, 1 - bright], [1], x[:per])
        for i in range(per, n):
            x[i] = decay * 0.5 * (x[i - per] + x[i - per - 1])
        return x * expdec(d, d * 0.5, 0.0005)

    def chime(freqs, d, gap=0.05, tau=0.25):
        out = np.zeros(int(SR * d))
        for k, f in enumerate(freqs):
            tt = t(d - k * gap)
            tone = (np.sin(2 * np.pi * f * tt) + 0.3 * np.sin(2 * np.pi * f * 2.76 * tt)) * np.exp(-tt / tau)
            i = int(SR * k * gap)
            out[i:i + len(tone)] += tone[: len(out) - i]
        return out

    def rustle(d, lo=900, hi=4500, grains=14):
        out = np.zeros(int(SR * d))
        for k in range(grains):
            g = band(noise(0.04), lo, hi) * expdec(0.04, 0.012)
            i = int(rng.uniform(0, d - 0.05) * SR)
            out[i:i + len(g)] += g * rng.uniform(0.3, 1.0)
        return out * np.sin(np.linspace(0, np.pi, len(out))) ** 0.7

    def jingle(d, n=10, lo=3500, hi=7000):
        out = np.zeros(int(SR * d))
        for k in range(n):
            m_ = metal(0.06, rng.uniform(lo, hi), 0.012, 3) * rng.uniform(0.3, 1.0)
            i = int(rng.uniform(0, d - 0.07) * SR)
            out[i:i + len(m_)] += m_
        return out

    # blades: drawn from the scabbard / slid back in
    x = mix(0.5, (0, whoosh(0.22, 2500, 7000) * 0.5), (0.03, metal(0.4, 2400, 0.12, 5) * 0.55), (0.02, click(0.01, 3000, 9000) * 0.4))
    save("pick_blade", room(x, 0.1), 0.6)
    x = mix(0.5, (0, whoosh(0.15, 5000, 2000) * 0.4), (0.12, click(0.015, 1500, 6000) * 0.9), (0.12, metal(0.35, 1900, 0.09, 5) * 0.5),
            (0.12, thump(0.15, 180, 80, 0.04) * 0.5))
    save("equip_blade", room(x, 0.12), 0.7)
    # plate & mail: clank and jingling rings
    x = mix(0.5, (0, metal(0.3, 820, 0.07, 6) * 0.7), (0, click(0.012, 800, 5000) * 0.8), (0.01, jingle(0.25, 8) * 0.35))
    save("pick_metal", room(x, 0.12), 0.65)
    x = mix(0.6, (0, metal(0.35, 640, 0.09, 6) * 0.8), (0, thump(0.2, 160, 70, 0.05) * 0.8), (0.0, click(0.015, 600, 4000) * 0.9),
            (0.05, jingle(0.4, 14) * 0.4), (0.12, metal(0.3, 980, 0.06, 5) * 0.4))
    save("equip_metal", room(x, 0.14), 0.75)
    # bows: wood creak and a string being drawn / released
    creak_t = t(0.25)
    creak = band(np.sign(np.sin(2 * np.pi * np.cumsum(110 + 60 * creak_t + 15 * np.sin(2 * np.pi * 23 * creak_t)) / SR)), 200, 1600) * np.sin(np.linspace(0, np.pi, len(creak_t))) * 0.35
    x = mix(0.5, (0, creak), (0.12, pluck_ks(196, 0.35, 0.994, 0.7) * 0.5))
    save("pick_bow", room(x, 0.1), 0.6)
    x = mix(0.6, (0, creak * 0.7), (0.15, pluck_ks(147, 0.45, 0.995, 0.85) * 0.8), (0.15, click(0.01, 1000, 5000) * 0.4))
    save("equip_bow", room(x, 0.12), 0.7)
    # leather & cloth: rustle, buckle
    save("pick_cloth", room(rustle(0.3), 0.08), 0.55)
    x = mix(0.5, (0, rustle(0.35, 700, 3500, 18)), (0.22, metal(0.12, 2800, 0.03, 3) * 0.4), (0.24, thump(0.1, 150, 70, 0.03) * 0.3))
    save("equip_cloth", room(x, 0.1), 0.6)
    # jewellery: tiny bells
    save("pick_jewel", room(chime([2637, 3520, 3136], 0.6, 0.04, 0.18), 0.25), 0.5)
    save("equip_jewel", room(chime([1568, 2093, 2637, 3136], 0.9, 0.06, 0.3), 0.3), 0.6)
    # staves, orbs, tomes: shimmer
    sh = np.zeros(int(SR * 0.7))
    for k in range(8):
        f = 900 * 2 ** (k / 5)
        tone = np.sin(2 * np.pi * f * t(0.4)) * expdec(0.4, 0.15) * 0.15
        i = int(SR * k * 0.03)
        sh[i:i + len(tone)] += tone
    save("pick_magic", room(sh + band(noise(0.7), 4000, 12000) * expdec(0.7, 0.2) * 0.05, 0.3), 0.5)
    x = mix(0.9, (0, whoosh(0.35, 600, 3000) * 0.35), (0.15, chime([784, 1175, 1568], 0.7, 0.05, 0.3)), (0.15, sh[: int(SR * 0.7)] * 0.6))
    save("equip_magic", room(x, 0.3), 0.65)
    # instruments: lute pluck / strum
    save("pick_music", room(pluck_ks(330, 0.5, 0.996, 0.6), 0.15), 0.55)
    x = np.zeros(int(SR * 0.9))
    for k, f in enumerate([196, 247, 294, 392]):
        p_ = pluck_ks(f, 0.8, 0.996, 0.6)
        i = int(SR * k * 0.025)
        x[i:i + len(p_)] += p_[: len(x) - i] * 0.5
    save("equip_music", room(x, 0.15), 0.65)
    # put-down on a wooden shelf, and a coin purse for sales
    save("item_drop", room(mix(0.25, (0, thump(0.18, 210, 90, 0.035) * 0.8), (0, click(0.012, 500, 3000) * 0.6)), 0.08), 0.5)
    coins_ = np.zeros(int(SR * 0.8))
    for k in range(12):
        m_ = metal(0.15, rng.uniform(2500, 5200), 0.03, 4) * rng.uniform(0.3, 1.0)
        i = int(SR * (k * 0.035 + rng.uniform(0, 0.02)))
        coins_[i:i + len(m_)] += m_[: len(coins_) - i]
    save("sell", room(coins_, 0.18), 0.7)
    print("ok")


if __name__ == "__main__":
    main()
