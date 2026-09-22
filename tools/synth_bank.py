#!/usr/bin/env python3
"""Per-attack, per-character SFX + extra banks. Does not rewrite existing loops."""
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


def whoosh(dur: float, lift: float = 900.0) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.02, dur)
        s = noise() * e * 0.45 + tone(420 + t * lift, t) * 0.25 * e
        out.append(s)
    return out


def chirp(dur: float, f0: float, f1: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.008, dur)
        f = f0 + (f1 - f0) * (t / dur)
        out.append(tone(f, t) * e * 0.5)
    return out


def mix(*parts: list[float]) -> list[float]:
    m = max(len(p) for p in parts)
    out = [0.0] * m
    for p in parts:
        for i, v in enumerate(p):
            out[i] += v
    peak = max(0.001, max(abs(x) for x in out))
    return [x / peak * 0.86 for x in out]


def voiceish(dur: float, f0: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.02, dur)
        form = tone(f0, t) * 0.4 + tone(f0 * 2.05, t) * 0.2 + noise() * 0.04
        out.append(form * e)
    return out


def loop_pad(dur: float, f0: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        s = tone(f0, t) * 0.18 + tone(f0 * 1.5, t) * 0.08 + tone(f0 * 0.5, t) * 0.12
        s += noise() * 0.03 * (0.5 + 0.5 * math.sin(t * 1.7))
        out.append(s * 0.7)
    return out


roles = {
    "son": 1.12,
    "dad": 0.86,
}

kinds = {
    "jab": (0.08, 260, 140, 0.1, 0.05),
    "cross": (0.12, 170, 80, 0.22, 0.07),
    "bam": (0.18, 90, 36, 0.45, 0.12),
    "slap": (0.1, 320, 90, 0.18, 0.08),
    "combo": (0.14, 200, 70, 0.2, 0.1),
    "land": (0.1, 140, 70, 0.16, 0.06),
    "uppercut": (0.16, 180, 70, 0.28, 0.14),
    "roundhouse": (0.18, 110, 48, 0.32, 0.16),
    "air_mix": (0.16, 150, 60, 0.3, 0.14),
    "jump": (0.1, 240, 140, 0.08, 0.08),
    "light": (0.1, 220, 110, 0.14, 0.06),
    "heavy": (0.18, 120, 50, 0.32, 0.1),
}

for role, mul in roles.items():
    for kind, (dur, f0, f1, grit, who) in kinds.items():
        fname = f"{kind}_{role}.wav"
        write_wav(
            fname,
            mix(
                impact(dur, f0 * mul, f1 * mul, grit),
                whoosh(who + 0.04, 700.0 * mul),
            ),
        )

write_wav("smash.wav", mix(impact(0.16, 90, 40, 0.5), whoosh(0.08)))
write_wav("pop.wav", mix(impact(0.12, 220, 70, 0.35), chirp(0.08, 600, 180)))
write_wav("splash.wav", mix(impact(0.28, 48, 18, 0.7), whoosh(0.18), chirp(0.12, 180, 40)))
write_wav("grab.wav", mix(whoosh(0.12), impact(0.14, 100, 50, 0.3)))
write_wav("wall_bounce.wav", mix(impact(0.12, 180, 70, 0.4), chirp(0.1, 300, 120)))
write_wav("chrome_ui.wav", mix(chirp(0.12, 880, 1320), impact(0.06, 520, 300, 0.05)))
write_wav("polaroid.wav", mix(chirp(0.1, 1400, 900), impact(0.05, 400, 200, 0.08)))
write_wav("heat_up.wav", mix(chirp(0.3, 110, 220), impact(0.12, 80, 40, 0.2)))
write_wav("envelope.wav", mix(chirp(0.16, 520, 780), whoosh(0.1)))
write_wav("vo_dad_level.wav", mix(voiceish(1.1, 110), chirp(0.2, 180, 90)))
write_wav("vo_son_kong.wav", mix(voiceish(0.9, 190), chirp(0.16, 280, 140)))
write_wav("vo_mayor_radio.wav", mix(voiceish(1.6, 95), chirp(0.3, 140, 70)))
write_wav("music_tension.wav", loop_pad(8.0, 55.0))
write_wav("music_patrol.wav", loop_pad(6.0, 72.0))
write_wav("music_dojo.wav", loop_pad(6.0, 98.0))
write_wav("vo_dad_nooo.wav", mix(voiceish(0.85, 95), chirp(0.35, 140, 60), whoosh(0.2)))
write_wav("vo_son_aaa.wav", mix(voiceish(0.7, 210), chirp(0.28, 320, 180), whoosh(0.16)))
write_wav("van.wav", mix(whoosh(0.4, 200.0), impact(0.22, 70, 28, 0.5)))
write_wav("music_chase.wav", loop_pad(8.0, 48.0))
print("bank sfx done")
