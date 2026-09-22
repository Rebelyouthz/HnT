#!/usr/bin/env python3
"""Short extra SFX + VO fallbacks. Does not rewrite existing music."""
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


write_wav("parry.wav", mix(chirp(0.12, 880, 1480), impact(0.08, 420, 180, 0.12)))
write_wav("dumpster.wav", mix(impact(0.22, 70, 28, 0.55), whoosh(0.16)))
write_wav("fridge.wav", mix(chirp(0.14, 240, 180), impact(0.1, 160, 80, 0.2)))
write_wav("dual_snap.wav", mix(chirp(0.18, 520, 1040), chirp(0.16, 780, 1560), impact(0.1, 200, 80, 0.08)))
write_wav("vo_dad_bounce.wav", mix(bark(0.38, 140, 110), impact(0.08, 90, 50, 0.1)))
write_wav("vo_dad_fridge.wav", mix(bark(0.42, 120, 90), chirp(0.12, 180, 140)))
write_wav("vo_son_dumpster.wav", mix(bark(0.28, 240, 200), whoosh(0.1)))
write_wav("vo_son_dual.wav", mix(bark(0.22, 280, 340), chirp(0.16, 400, 720)))
write_wav("vo_mayor_lottery.wav", mix(bark(0.5, 110, 95), chirp(0.2, 160, 220)))
write_wav("revenge.wav", mix(impact(0.14, 90, 40, 0.22), chirp(0.16, 220, 720)))
write_wav("cart.wav", mix(whoosh(0.22), impact(0.1, 140, 60, 0.18)))
write_wav("siren.wav", mix(chirp(0.28, 620, 920), chirp(0.28, 920, 620)))
write_wav("fax.wav", mix(impact(0.08, 200, 90, 0.12), chirp(0.18, 180, 90)))
write_wav("vo_dad_revenge.wav", mix(bark(0.32, 130, 100), impact(0.08, 80, 40, 0.1)))
write_wav("vo_son_cart.wav", mix(bark(0.24, 260, 300), whoosh(0.12)))
write_wav("vo_dad_fax.wav", mix(bark(0.36, 115, 95), chirp(0.14, 160, 120)))
print("extras sfx done")
