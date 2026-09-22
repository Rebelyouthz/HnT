#!/usr/bin/env python3
"""New extra SFX + VO fallbacks only. Does not rewrite existing wavs."""
import math
import random
import struct
import wave
from pathlib import Path

OUT = Path("/home/timmietooth/projects/HnT/assets/audio")
OUT.mkdir(parents=True, exist_ok=True)
SR = 48000


def write_wav(name: str, samples: list[float]) -> None:
    path = OUT / name
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = max(-0.98, min(0.98, s))
            frames += struct.pack("<h", int(v * 32767))
        w.writeframes(frames)
    print("wrote", path)


def env(t: float, a: float, d: float) -> float:
    if t < a:
        return t / a if a > 0 else 1.0
    return max(0.0, 1.0 - (t - a) / max(d, 0.001))


def tone(freq: float, t: float) -> float:
    return math.sin(2 * math.pi * freq * t)


def noise() -> float:
    return random.random() * 2 - 1


def impact(dur: float, f0: float, f1: float, grit: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.004, dur)
        f = f0 + (f1 - f0) * (t / dur)
        s = tone(f, t) * 0.55 + tone(f * 0.5, t) * 0.35 + noise() * grit * e
        out.append(s * e)
    return out


def whoosh(dur: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.02, dur)
        s = noise() * e * 0.45 + tone(420 + t * 900, t) * 0.25 * e
        out.append(s)
    return out


def mix(*parts: list[float]) -> list[float]:
    m = max(len(p) for p in parts)
    out = [0.0] * m
    for p in parts:
        for i, v in enumerate(p):
            out[i] += v
    peak = max(0.001, max(abs(x) for x in out))
    return [x / peak * 0.86 for x in out]


def chirp(dur: float, f0: float, f1: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.008, dur)
        f = f0 + (f1 - f0) * (t / dur)
        out.append(tone(f, t) * e * 0.5)
    return out


def bark(dur: float, f0: float, f1: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.02, dur)
        f = f0 + (f1 - f0) * (t / dur)
        s = tone(f, t) * 0.55 + tone(f * 1.5, t) * 0.2 + noise() * 0.08
        out.append(s * e)
    return out


write_wav("boom.wav", mix(impact(0.22, 70, 24, 0.62), whoosh(0.18), chirp(0.12, 180, 80)))
write_wav("pole.wav", mix(whoosh(0.16), chirp(0.14, 280, 720)))
write_wav("dive.wav", mix(whoosh(0.14), impact(0.1, 160, 70, 0.2)))
write_wav("vo_dad_barrel.wav", mix(bark(0.34, 128, 96), impact(0.08, 80, 40, 0.12)))
write_wav("vo_son_pole.wav", mix(bark(0.24, 255, 310), whoosh(0.1)))
write_wav("vo_dad_dive.wav", mix(bark(0.3, 132, 100), whoosh(0.12)))
write_wav("vo_mayor_cooler.wav", mix(bark(0.4, 108, 92), chirp(0.16, 150, 200)))
write_wav("hood.wav", mix(whoosh(0.14), impact(0.09, 140, 60, 0.18), chirp(0.1, 220, 480)))
write_wav("bench.wav", mix(impact(0.08, 180, 90, 0.14), whoosh(0.1)))
write_wav("vo_dad_manhole.wav", mix(bark(0.32, 124, 90), whoosh(0.12)))
write_wav("vo_son_hood.wav", mix(bark(0.22, 250, 320), chirp(0.1, 300, 520)))
write_wav("vo_dad_slide.wav", mix(bark(0.2, 140, 100), whoosh(0.12)))
write_wav("vo_mayor_clock.wav", mix(bark(0.36, 104, 88), impact(0.06, 90, 50, 0.1)))
write_wav("vo_mayor_bleach.wav", mix(bark(0.34, 110, 94), chirp(0.12, 160, 210)))
print("more extras sfx done")
