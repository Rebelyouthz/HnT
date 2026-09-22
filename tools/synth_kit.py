#!/usr/bin/env python3
"""New kit SFX only. Does not rewrite music loops."""
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


write_wav("foot.wav", mix(impact(0.08, 90, 50, 0.15), whoosh(0.06)))
write_wav("stumble.wav", mix(impact(0.18, 70, 32, 0.4), whoosh(0.14)))
write_wav("trick_ok.wav", mix(chirp(0.16, 520, 780), impact(0.08, 400, 280, 0.05)))
write_wav("trick_perfect.wav", mix(chirp(0.22, 660, 990), chirp(0.18, 880, 1320), impact(0.1, 520, 300, 0.04)))
write_wav("pistol.wav", mix(impact(0.12, 180, 40, 0.55), whoosh(0.08)))
write_wav("hammer.wav", mix(impact(0.16, 140, 55, 0.45), impact(0.08, 420, 180, 0.2)))
write_wav("wheel.wav", mix(chirp(0.4, 220, 880), [tone(440 + (i % 8000) * 0.02, i / SR) * env(i / SR, 0.02, 0.45) * 0.25 for i in range(int(SR * 0.5))]))
write_wav("slot.wav", mix(chirp(0.18, 300, 500), chirp(0.14, 500, 300)))
write_wav("levelup.wav", mix(chirp(0.28, 392, 784), chirp(0.24, 523, 1046), impact(0.12, 200, 90, 0.1)))
write_wav("stomp1.wav", mix(impact(0.16, 90, 40, 0.5), whoosh(0.08)))
write_wav("stomp2.wav", mix(impact(0.2, 70, 28, 0.62), whoosh(0.12)))
write_wav("stomp3.wav", mix(impact(0.28, 48, 18, 0.7), whoosh(0.18), chirp(0.12, 180, 40)))
write_wav("uppercut.wav", mix(whoosh(0.14), impact(0.16, 160, 70, 0.3)))
write_wav("roundhouse.wav", mix(whoosh(0.18), impact(0.14, 110, 50, 0.35)))
write_wav("light_son.wav", mix(impact(0.1, 240, 140, 0.12), whoosh(0.06)))
write_wav("light_dad.wav", mix(impact(0.12, 140, 70, 0.2), whoosh(0.07)))
write_wav("heavy_son.wav", mix(impact(0.16, 160, 70, 0.28), whoosh(0.1)))
write_wav("heavy_dad.wav", mix(impact(0.2, 90, 40, 0.4), whoosh(0.12)))
write_wav("jump_son.wav", mix(chirp(0.1, 280, 200), impact(0.08, 200, 140, 0.05)))
write_wav("jump_dad.wav", mix(chirp(0.12, 180, 120), impact(0.09, 140, 90, 0.08)))
print("kit sfx done")
