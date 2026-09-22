#!/usr/bin/env python3
"""Tower / parachute SFX + VO fallbacks. Does not rewrite existing wavs."""
import math
import os
import random
import struct
import wave
from pathlib import Path

OUT = Path("/home/timmietooth/projects/HnT/assets/audio")
OUT.mkdir(parents=True, exist_ok=True)
SR = 48000


def write_wav(name: str, samples: list[float]) -> None:
    path = OUT / name
    if path.exists() and name not in {
        "cling.wav", "cling_ok.wav", "cling_fail.wav", "creak.wav", "wind.wav",
        "zip.wav", "mom_door.wav", "music_summit.wav", "music_fall.wav",
        "vo_dad_summit.wav", "vo_son_summit.wav",
    }:
        return
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
        return t / a if a else 1.0
    return max(0.0, 1.0 - (t - a) / max(d, 0.001))


def tone(freq: float, t: float) -> float:
    return math.sin(2 * math.pi * freq * t)


def noise() -> float:
    return random.random() * 2 - 1


def whoosh(dur: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.02, dur)
        out.append(noise() * e * 0.5 + tone(180 + t * 700, t) * 0.2 * e)
    return out


def impact(dur: float, f0: float, f1: float, grit: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.004, dur)
        f = f0 + (f1 - f0) * (t / dur)
        out.append((tone(f, t) * 0.55 + noise() * grit * e) * e)
    return out


def mix(*parts: list[float]) -> list[float]:
    m = max(len(p) for p in parts)
    out = [0.0] * m
    for p in parts:
        for i, v in enumerate(p):
            out[i] += v
    peak = max(0.001, max(abs(x) for x in out))
    return [x / peak * 0.86 for x in out]


def pad(dur: float, f: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = 0.5 + 0.5 * math.sin(t * 0.7)
        out.append((tone(f, t) * 0.35 + tone(f * 1.5, t) * 0.12 + tone(f * 0.5, t) * 0.2) * e * 0.25)
    return out


def bark(dur: float, f0: float, f1: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.02, dur)
        f = f0 + (f1 - f0) * (t / dur)
        out.append((tone(f, t) * 0.55 + tone(f * 1.5, t) * 0.2) * e)
    return out


write_wav("cling.wav", mix(whoosh(0.18), [tone(880, i / SR) * env(i / SR, 0.01, 0.18) * 0.4 for i in range(int(SR * 0.18))]))
write_wav("cling_ok.wav", mix(impact(0.12, 420, 880, 0.08), whoosh(0.1)))
write_wav("cling_fail.wav", mix(impact(0.2, 140, 40, 0.4), whoosh(0.16)))
write_wav("creak.wav", mix(
    [tone(90 + 20 * math.sin(i / SR * 8), i / SR) * env(i / SR, 0.05, 0.45) * 0.4 for i in range(int(SR * 0.5))],
    whoosh(0.3),
))
write_wav("wind.wav", whoosh(1.4))
write_wav("zip.wav", mix(whoosh(0.22), [tone(600 + i * 0.04, i / SR) * env(i / SR, 0.01, 0.28) * 0.35 for i in range(int(SR * 0.3))]))
write_wav("mom_door.wav", mix(impact(0.18, 80, 40, 0.5), bark(0.4, 210, 160), whoosh(0.2)))
write_wav("music_summit.wav", pad(8.0, 196.0))
write_wav("music_fall.wav", pad(8.0, 110.0))
write_wav("vo_dad_summit.wav", mix(bark(0.42, 126, 98), whoosh(0.12)))
write_wav("vo_son_summit.wav", mix(bark(0.28, 248, 300), whoosh(0.08)))
print("tower sfx done")
