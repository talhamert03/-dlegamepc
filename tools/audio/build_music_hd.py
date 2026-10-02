#!/usr/bin/env python3
"""Fantasy-RPG music loops (44.1 kHz) -> game/assets/audio/music/*.ogg

Synthesised instruments instead of chip voices: plucked harp/lute (Karplus-Strong), warm string pad
(detuned saws through a low-pass), breathy flute lead with vibrato, soft sine bass, frame drum / taiko /
shaker, all through a convolution hall reverb. Every track is rendered twice its length and the reverb
tail is folded back onto the start, so the loop point is seamless.

  python3 tools/audio/build_music_hd.py [name ...]
"""
import os
import subprocess
import sys
import wave

import numpy as np
from scipy import signal

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MUS = os.path.join(ROOT, "game/assets/audio/music")
SR = 44100
NOTE = {n: i for i, n in enumerate(["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"])}
SCALES = {"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
          "phrygian": [0, 1, 3, 5, 7, 8, 10], "harmonic": [0, 2, 3, 5, 7, 8, 11], "lydian": [0, 2, 4, 6, 7, 9, 11]}


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def tt(d):
    return np.arange(int(SR * d)) / SR


def adsr(n, a, d, s, r):
    a, d, r = int(SR * a), int(SR * d), int(SR * r)
    env = np.full(n, s, dtype=np.float64)
    a = min(a, n)
    env[:a] = np.linspace(0, 1, a, endpoint=False) if a else env[:a]
    d2 = min(d, n - a)
    if d2 > 0:
        env[a:a + d2] = np.linspace(1, s, d2, endpoint=False)
    r = min(r, n)
    if r > 0:
        env[-r:] *= np.linspace(1, 0, r)
    return env


def pluck(f, d, bright=0.5, decay=0.996, rng=None):
    """Karplus-Strong string: harp / lute."""
    rng = rng or np.random.default_rng()
    n = int(SR * d)
    p = max(2, int(SR / f))
    exc = rng.uniform(-1, 1, p)
    exc = signal.lfilter([bright, 1 - bright], [1], exc)
    x = np.zeros(n)
    x[:p] = exc
    a = np.zeros(p + 2)
    a[0] = 1.0
    a[p] = -decay * 0.5
    a[p + 1] = -decay * 0.5
    y = signal.lfilter([1.0], a, x)
    return y * adsr(n, 0.001, 0.05, 1.0, 0.04)


def pad(freqs, d, cutoff=1800):
    t = tt(d)
    x = np.zeros(len(t))
    for f in freqs:
        for det in (-0.006, 0.0, 0.0065):
            ph = 2 * np.pi * f * (1 + det) * t + np.random.random() * 6
            x += (2 * ((ph / (2 * np.pi)) % 1.0) - 1) * 0.33
    x = signal.sosfilt(signal.butter(2, cutoff, fs=SR, output="sos"), x)
    return x * adsr(len(t), d * 0.35, 0.1, 0.9, d * 0.35) / max(1, len(freqs))


def flute(f, d):
    t = tt(d)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.25, 0, 1)
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    x = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.05 * np.sin(3 * ph)
    breath = signal.sosfilt(signal.butter(2, [f * 0.9, f * 3.0], btype="band", fs=SR, output="sos"), np.random.standard_normal(len(t)))
    x += breath * 0.08
    return x * adsr(len(t), 0.05, 0.1, 0.8, min(0.15, d * 0.4))


def bell(f, d):
    t = tt(d)
    mod = np.sin(2 * np.pi * f * 3.5 * t) * 2.0 * np.exp(-t * 3)
    return np.sin(2 * np.pi * f * t + mod) * np.exp(-t * 2.2) * adsr(len(t), 0.002, 0.0, 1.0, 0.05)


def bass(f, d):
    t = tt(d)
    x = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t)
    return x * adsr(len(t), 0.01, 0.2, 0.7, 0.08)


def drum(kind, d=0.5):
    t = tt(d)
    if kind == "taiko":
        f = 55 + 70 * np.exp(-t * 18)
        x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 6)
        x += signal.sosfilt(signal.butter(2, 900, fs=SR, output="sos"), np.random.standard_normal(len(t))) * np.exp(-t * 30) * 0.4
        return x
    if kind == "frame":
        f = 90 + 60 * np.exp(-t * 25)
        return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 12) * 0.8
    if kind == "shaker":
        x = signal.sosfilt(signal.butter(2, 5000, btype="high", fs=SR, output="sos"), np.random.standard_normal(len(t)))
        return x * np.exp(-t * 45) * 0.25
    return np.zeros(len(t))


def hall(x, seconds=2.2, wet=0.28):
    n = int(SR * seconds)
    rng = np.random.default_rng(5)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (SR * seconds / 6.0))
    ir = signal.sosfilt(signal.butter(1, 4500, fs=SR, output="sos"), ir)
    ir /= np.sqrt(np.sum(ir ** 2))
    w = signal.fftconvolve(x, ir)[: len(x)]
    return x * (1 - wet) + w * wet * 1.6


def put(out, x, at):
    i = int(SR * at)
    x = x[: max(0, len(out) - i)]
    out[i:i + len(x)] += x


def song(name, key, scale, bpm, prog, seed, bars=16, style="calm", lead="flute"):
    rng = np.random.default_rng(seed)
    np.random.seed(seed)
    beat = 60.0 / bpm
    bar = beat * 4
    total = bars * bar
    out = np.zeros(int(SR * (total + 3.0)))
    sc = SCALES[scale]
    root = 48 + NOTE[key]

    def deg(d, octv=0):
        return root + 12 * octv + sc[d % 7] + 12 * (d // 7)

    motif = [int(x) for x in rng.choice([0, 2, 4, 3, 1, 4, 5, 2], 8)]
    rhythm = [1.0, 0.5, 0.5, 1.0, 0.5, 0.5]   # beats, sums to 4
    for b in range(bars):
        ch = prog[b % len(prog)]
        t0 = b * bar
        triad = [deg(ch), deg(ch + 2), deg(ch + 4)]
        put(out, pad([hz(m) for m in triad], bar * 1.02, 1400 if style != "battle" else 2200) * 0.55, t0)
        put(out, bass(hz(deg(ch, -1)), beat * 1.9) * 0.55, t0)
        put(out, bass(hz(deg(ch, -1)), beat * 1.9) * 0.45, t0 + beat * 2)
        # harp arpeggio in eighths
        arp = [0, 2, 4, 7, 4, 2, 4, 7]
        for s in range(8):
            m = deg(ch + arp[s], 1 if style != "battle" else 0)
            put(out, pluck(hz(m), beat * 1.6, 0.45, 0.9965, rng) * (0.22 if s % 2 == 0 else 0.16), t0 + s * beat / 2)
        # lead from the third bar of every 4-bar phrase on
        if b % 4 in (1, 2, 3) or style == "battle" and b >= 4:
            at = t0
            for i, r in enumerate(rhythm):
                if rng.random() < 0.18 and i:
                    at += r * beat
                    continue
                m = deg(motif[(i + b) % 8] + (ch % 3), 2 if lead == "bell" else 1)
                d = r * beat * 0.95
                x = flute(hz(m), d) * 0.32 if lead == "flute" else bell(hz(m), d + 0.6) * 0.22
                put(out, x, at)
                at += r * beat
        if style in ("adventure", "battle", "boss"):
            for s in range(8):
                at = t0 + s * beat / 2
                if s in (0, 4) or (style == "boss" and s in (3, 6)):
                    put(out, drum("taiko" if style == "boss" else "frame") * (0.7 if style == "boss" else 0.5), at)
                elif style == "battle" and s in (2, 6):
                    put(out, drum("frame") * 0.35, at)
                put(out, drum("shaker", 0.12) * (0.5 if s % 2 else 0.3), at)
    out = hall(out, 2.4 if style == "calm" else 1.8, 0.32 if style == "calm" else 0.22)
    # fold the tail onto the start for a seamless loop
    n = int(SR * total)
    loop = out[:n].copy()
    tail = out[n:]
    loop[: len(tail)] += tail
    loop = signal.sosfilt(signal.butter(1, 30, btype="high", fs=SR, output="sos"), loop)
    loop = np.tanh(loop / (np.max(np.abs(loop)) or 1) * 1.2) / np.tanh(1.2) * 0.6
    pcm = (loop * 32767).astype(np.int16)
    tmp = os.path.join(MUS, name + ".wav")
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "4",
                    os.path.join(MUS, name + ".ogg")], check=True)
    os.remove(tmp)
    print("ok", name, round(total, 1), "s")


TRACKS = {
    "title": dict(key="D", scale="lydian", bpm=76, prog=[0, 4, 5, 3], seed=1, style="calm", lead="flute"),
    "town": dict(key="F", scale="major", bpm=96, prog=[0, 5, 3, 4], seed=2, style="adventure", lead="bell"),
    "act1": dict(key="C", scale="major", bpm=108, prog=[0, 5, 3, 4], seed=3, style="adventure", lead="flute"),
    "act2": dict(key="A", scale="dorian", bpm=100, prog=[0, 3, 6, 4], seed=4, style="adventure", lead="bell"),
    "act3": dict(key="E", scale="phrygian", bpm=104, prog=[0, 1, 0, 6], seed=5, style="battle", lead="flute"),
    "act4": dict(key="D", scale="harmonic", bpm=112, prog=[0, 5, 3, 4], seed=6, style="battle", lead="flute"),
    "boss": dict(key="A", scale="minor", bpm=128, prog=[0, 5, 6, 4], seed=7, style="boss", lead="flute"),
}


def main(names=None):
    os.makedirs(MUS, exist_ok=True)
    for k, v in TRACKS.items():
        if names and k not in names:
            continue
        song(k, **v)


if __name__ == "__main__":
    main(sys.argv[1:])
