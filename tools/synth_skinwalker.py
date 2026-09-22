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
    print("wrote", path, "n", len(samples))


def env(t: float, a: float, d: float) -> float:
    if t < a:
        return t / a if a > 0 else 1.0
    return max(0.0, 1.0 - (t - a) / max(d, 0.001))


def tone(freq: float, t: float) -> float:
    return math.sin(2 * math.pi * freq * t)


def noise() -> float:
    return random.random() * 2 - 1


def mix(*parts: list[float]) -> list[float]:
    m = max(len(p) for p in parts)
    out = [0.0] * m
    for p in parts:
        for i, v in enumerate(p):
            out[i] += v
    peak = max(0.001, max(abs(x) for x in out))
    return [x / peak * 0.86 for x in out]


def whistle() -> list[float]:
    n = int(SR * 1.15)
    out = []
    for i in range(n):
        t = i / SR
        f = 1680 - t * 420 + math.sin(t * 18) * 70
        e = env(t, 0.04, 1.1)
        s = tone(f, t) * 0.55 + tone(f * 2.02, t) * 0.12
        if 0.4 < t < 0.52:
            s *= 0.15
        out.append(s * e)
    return out


def help_call() -> list[float]:
    # Wrong "help": two formants that don't belong to a mouth you know.
    n = int(SR * 0.85)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.03, 0.82)
        f1 = 620 + math.sin(t * 40) * 80
        f2 = 1480 - t * 200
        s = tone(f1, t) * 0.4 + tone(f2, t) * 0.28 + tone(f1 * 0.5, t) * 0.18
        if t > 0.35:
            s += tone(210, t) * 0.2 * e
        out.append(s * e * (1.0 if t < 0.5 else 0.7))
    return out


def gape() -> list[float]:
    n = int(SR * 0.55)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.02, 0.53)
        s = tone(90 - t * 30, t) * 0.5 + noise() * 0.35 * e + tone(40, t) * 0.3
        out.append(s * e)
    return out


def phase() -> list[float]:
    n = int(SR * 0.32)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.005, 0.3)
        s = noise() * e * 0.5 + tone(2400 - t * 1800, t) * 0.35
        if int(t * 80) % 2 == 0:
            s *= 0.2
        out.append(s)
    return out


def crawl() -> list[float]:
    n = int(SR * 0.42)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.01, 0.4)
        click = 1.0 if (t * 18) % 1.0 < 0.08 else 0.15
        s = (tone(140, t) * 0.3 + noise() * 0.4) * click * e
        out.append(s)
    return out


def dad_line() -> list[float]:
    # Fallback VO bed. EL overwrite if the mp3 lands.
    n = int(SR * 1.6)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.02, 1.55)
        f = 118 + math.sin(t * 9) * 8
        s = tone(f, t) * 0.45 + tone(f * 2, t) * 0.12
        out.append(s * e)
    return out


def son_line() -> list[float]:
    n = int(SR * 2.1)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.02, 2.05)
        f = 168 + math.sin(t * 7) * 10
        s = tone(f, t) * 0.4 + tone(f * 2.1, t) * 0.1
        out.append(s * e)
    return out


write_wav("sfx_whistle.wav", mix(whistle()))
write_wav("sfx_help_call.wav", mix(help_call()))
write_wav("sfx_gape.wav", mix(gape()))
write_wav("sfx_phase.wav", mix(phase()))
write_wav("sfx_crawl.wav", mix(crawl()))
write_wav("vo_dad_skinwalker.wav", mix(dad_line()))
write_wav("vo_son_skinwalker.wav", mix(son_line()))
