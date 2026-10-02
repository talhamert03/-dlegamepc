#!/usr/bin/env python3
"""Procedural SFX and chiptune music loops -> game/assets/audio/{sfx,music}/*.ogg (via ffmpeg)."""
import math
import os
import subprocess
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SFX = os.path.join(ROOT, "game/assets/audio/sfx")
MUS = os.path.join(ROOT, "game/assets/audio/music")
SR = 22050
rng = np.random.default_rng(7)


def t_arr(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, d=0.1, s=0.0, r=0.05, total=None):
    total = total or n / SR
    t = np.arange(n) / SR
    e = np.ones(n)
    e = np.where(t < a, t / max(a, 1e-6), e)
    e = np.where((t >= a) & (t < a + d), 1 - (1 - s) * (t - a) / max(d, 1e-6), e)
    e = np.where(t >= a + d, s, e) if s > 0 else np.where(t >= a + d, 0, e)
    if s > 0:
        rel = t > total - r
        e[rel] *= np.clip((total - t[rel]) / r, 0, 1)
    return e


def square(f, t, duty=0.5):
    return np.where((t * f) % 1.0 < duty, 1.0, -1.0)


def tri(f, t):
    return 2 * np.abs(2 * ((t * f) % 1.0) - 1) - 1


def noise(n):
    return rng.uniform(-1, 1, n)


def sweep(f0, f1, d, wave="square", duty=0.5):
    t = t_arr(d)
    f = f0 * (f1 / f0) ** (t / d)
    ph = np.cumsum(f) / SR
    if wave == "square":
        return np.where(ph % 1.0 < duty, 1.0, -1.0)
    if wave == "tri":
        return 2 * np.abs(2 * (ph % 1.0) - 1) - 1
    return np.sin(2 * np.pi * ph)


def lowpass(x, a=0.2):
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc)
        y[i] = acc
    return y


def save(path, x, vol=0.8):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1
    x = x / m * vol
    pcm = (x * 32767).astype(np.int16)
    tmp = path + ".wav"
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "3", path + ".ogg"], check=True)
    os.remove(tmp)


def concat(*parts):
    return np.concatenate(parts)


def sfx():
    os.makedirs(SFX, exist_ok=True)
    d = 0.06
    x = square(1200, t_arr(d), 0.25) * env(int(SR * d), 0.001, 0.05)
    save(os.path.join(SFX, "ui_click"), x, 0.5)
    x = sweep(400, 900, 0.09, "square", 0.25) * env(int(SR * 0.09), 0.002, 0.08)
    save(os.path.join(SFX, "ui_open"), x, 0.45)
    x = sweep(900, 400, 0.09, "square", 0.25) * env(int(SR * 0.09), 0.002, 0.08)
    save(os.path.join(SFX, "ui_close"), x, 0.45)
    x = concat(*[square(f, t_arr(0.06), 0.25) * env(int(SR * 0.06), 0.002, 0.05) for f in (523, 659, 784)])
    save(os.path.join(SFX, "ui_travel"), x, 0.45)
    # hits
    for i, (f0, f1) in enumerate([(300, 80), (360, 90), (260, 70)]):
        n = int(SR * 0.09)
        x = (noise(n) * 0.6 + sweep(f0, f1, 0.09, "square") * 0.5) * env(n, 0.001, 0.08)
        save(os.path.join(SFX, f"hit{i}"), lowpass(x, 0.35), 0.55)
    n = int(SR * 0.18)
    x = (noise(n) * 0.5 + sweep(700, 120, 0.18, "square", 0.3) * 0.7) * env(n, 0.001, 0.17)
    save(os.path.join(SFX, "crit"), x, 0.7)
    n = int(SR * 0.12)
    save(os.path.join(SFX, "shoot"), (noise(n) * env(n, 0.001, 0.1)) * 0.5 + sweep(1600, 600, 0.12, "tri") * env(n, 0.001, 0.1) * 0.4, 0.4)
    n = int(SR * 0.25)
    save(os.path.join(SFX, "magic"), sweep(300, 1200, 0.25, "tri") * env(n, 0.01, 0.24) + square(880, t_arr(0.25), 0.125) * env(n, 0.01, 0.2) * 0.3, 0.5)
    x = concat(*[tri(f, t_arr(0.07)) * env(int(SR * 0.07), 0.002, 0.06) for f in (1318, 1568, 2093)])
    save(os.path.join(SFX, "coins"), x, 0.45)
    save(os.path.join(SFX, "coin"), tri(1975, t_arr(0.08)) * env(int(SR * 0.08), 0.001, 0.07), 0.3)
    x = concat(*[square(f, t_arr(0.07), 0.25) * env(int(SR * 0.07), 0.002, 0.06) for f in (784, 988, 1175)])
    save(os.path.join(SFX, "loot_rare"), x, 0.5)
    notes = [523, 659, 784, 1046, 1318, 1568]
    x = concat(*[(square(f, t_arr(0.09), 0.25) * 0.6 + tri(f * 2, t_arr(0.09)) * 0.4) * env(int(SR * 0.09), 0.002, 0.08) for f in notes])
    tail = tri(2093, t_arr(0.5)) * env(int(SR * 0.5), 0.005, 0.5) * 0.6
    save(os.path.join(SFX, "loot_legendary"), concat(x, tail), 0.6)
    x = concat(*[square(f, t_arr(0.08), 0.5) * env(int(SR * 0.08), 0.002, 0.07) for f in (392, 523, 659, 784)],
               square(1046, t_arr(0.3), 0.5) * env(int(SR * 0.3), 0.005, 0.3))
    save(os.path.join(SFX, "levelup"), x, 0.5)
    x = concat(*[square(f, t_arr(0.18), 0.5) * env(int(SR * 0.18), 0.005, 0.17) for f in (220, 207, 220, 207)])
    save(os.path.join(SFX, "boss_warning"), x, 0.55)
    n = int(SR * 0.3)
    x = (noise(n) * 0.3 + square(1046, t_arr(0.3), 0.125) * 0.5) * env(n, 0.001, 0.29)
    save(os.path.join(SFX, "smith_success"), concat(x, tri(1568, t_arr(0.25)) * env(int(SR * 0.25), 0.01, 0.24)), 0.55)
    save(os.path.join(SFX, "smith_fail"), sweep(400, 90, 0.35, "square", 0.5) * env(int(SR * 0.35), 0.002, 0.34), 0.5)
    x = concat(*[tri(f, t_arr(0.1)) * env(int(SR * 0.1), 0.002, 0.09) for f in (659, 784, 988, 1318)])
    save(os.path.join(SFX, "recruit"), x, 0.5)
    n = int(SR * 0.4)
    save(os.path.join(SFX, "death"), sweep(500, 60, 0.4, "square", 0.5) * env(n, 0.002, 0.39), 0.4)
    save(os.path.join(SFX, "heal"), sweep(600, 1400, 0.3, "sine") * env(int(SR * 0.3), 0.02, 0.28), 0.35)


# ------------------------------------------------------------------ music
NOTE = {n: i for i, n in enumerate(["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"])}


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


SCALES = {"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
          "phrygian": [0, 1, 3, 5, 7, 8, 10], "harmonic": [0, 2, 3, 5, 7, 8, 11]}


def song(name, key, scale, bpm, prog, seed, lead="square", bars=16, drums=True, mood=1.0):
    r = np.random.default_rng(seed)
    beat = 60 / bpm
    step = beat / 2
    total = bars * 8 * step
    n = int(SR * total)
    out = np.zeros(n)
    sc = SCALES[scale]
    root = 48 + NOTE[key]

    def deg(d, octv=0):
        return root + 12 * octv + sc[d % 7] + 12 * (d // 7)

    # melody motif generated once and varied
    motif = [int(x) for x in r.choice([0, 1, 2, 3, 4, 5, 6, 7], 8)]
    for bar in range(bars):
        chord = prog[bar % len(prog)]
        # bass (triangle) on beats
        for b in range(4):
            t0 = int(SR * (bar * 8 * step + b * 2 * step))
            d = 2 * step * 0.9
            m = deg(chord, -1) if b % 2 == 0 else deg(chord + 4, -1)
            tt = t_arr(d)
            seg = tri(freq(m), tt) * env(len(tt), 0.005, d * 0.9, 0.6, 0.05, d) * 0.5
            out[t0:t0 + len(seg)] += seg[: max(0, n - t0)]
        # arpeggio (pulse 12.5%)
        for s in range(8):
            t0 = int(SR * (bar * 8 * step + s * step))
            m = deg(chord + [0, 2, 4, 7][s % 4], 1)
            tt = t_arr(step * 0.8)
            seg = square(freq(m), tt, 0.125) * env(len(tt), 0.002, step * 0.7) * 0.12 * mood
            out[t0:t0 + len(seg)] += seg[: max(0, n - t0)]
        # lead melody (2 of every 4 bars)
        if bar % 4 in (1, 2, 3):
            var = r.integers(-1, 2)
            for s in range(8):
                if r.random() < 0.3 and s % 2 == 1:
                    continue
                t0 = int(SR * (bar * 8 * step + s * step))
                m = deg(motif[s] + chord // 2 + var, 1)
                dur = step * (1.8 if s % 4 == 3 else 0.9)
                tt = t_arr(dur)
                vib = 1 + 0.004 * np.sin(2 * np.pi * 6 * tt)
                if lead == "square":
                    w = np.where((np.cumsum(freq(m) * vib) / SR) % 1.0 < 0.5, 1.0, -1.0)
                else:
                    w = tri(freq(m), tt)
                seg = w * env(len(tt), 0.01, dur * 0.8, 0.5, 0.04, dur) * 0.22
                out[t0:t0 + len(seg)] += seg[: max(0, n - t0)]
        if drums:
            for s in range(8):
                t0 = int(SR * (bar * 8 * step + s * step))
                if s % 4 == 0:
                    tt = t_arr(0.12)
                    seg = sweep(150, 45, 0.12, "sine") * env(len(tt), 0.001, 0.11) * 0.5
                elif s % 4 == 2:
                    nn = int(SR * 0.1)
                    seg = noise(nn) * env(nn, 0.001, 0.09) * 0.25
                else:
                    nn = int(SR * 0.03)
                    seg = noise(nn) * env(nn, 0.001, 0.03) * 0.08
                out[t0:t0 + len(seg)] += seg[: max(0, n - t0)]
    out = lowpass(out, 0.45)
    save(os.path.join(MUS, name), out, 0.55)


def music():
    os.makedirs(MUS, exist_ok=True)
    song("title", "D", "major", 92, [0, 4, 5, 3], 1, lead="tri", drums=False)
    song("town", "F", "major", 100, [0, 5, 3, 4], 2, lead="tri")
    song("act1", "C", "major", 116, [0, 5, 3, 4], 3)
    song("act2", "A", "dorian", 104, [0, 3, 6, 4], 4, lead="tri")
    song("act3", "E", "phrygian", 110, [0, 1, 0, 6], 5)
    song("act4", "D", "harmonic", 120, [0, 5, 3, 4], 6, mood=1.2)
    song("boss", "A", "minor", 140, [0, 5, 6, 4], 7, mood=1.3)


if __name__ == "__main__":
    sfx()
    music()
    print("audio done")
