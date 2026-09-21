"""Synth boss sting, boss/vs/survive loops, intro sting. Run once."""
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


def bass_loop(bpm: float, bars: int, motif: list[float], drums: bool, grit: float) -> list[float]:
    beat = 60.0 / bpm
    dur = beat * 4 * bars
    n = int(SR * dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        beat_i = int(t / beat) % len(motif)
        freq = motif[beat_i]
        s = 0.0
        if freq > 1:
            s += 0.44 * math.sin(2 * math.pi * freq * t)
            s += 0.16 * math.sin(2 * math.pi * freq * 2 * t)
            s += 0.08 * math.sin(2 * math.pi * freq * 3 * t) * grit
        if drums and (int(t / (beat * 0.5)) % 2 == 0):
            ht = t % (beat * 0.5)
            s += noise() * env(ht, 0.001, 0.04) * 0.09
        if drums and int(t / beat) % 2 == 0:
            kt = t % beat
            s += math.sin(2 * math.pi * (62 - kt * 36) * kt) * env(kt, 0.004, 0.14) * 0.38
        out[i] = s * 0.72
    peak = max(0.001, max(abs(x) for x in out))
    return [x / peak * 0.72 for x in out]


def sting(dur: float, f0: float, f1: float) -> list[float]:
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        e = env(t, 0.01, dur)
        f = f0 + (f1 - f0) * (t / dur)
        s = tone(f, t) * 0.5 + tone(f * 0.5, t) * 0.3 + noise() * 0.12 * e
        out.append(s * e)
    return out


write_wav("sting_boss.wav", sting(0.55, 220, 70))
write_wav("sting_intro.wav", sting(0.4, 330, 110))
write_wav("music_boss.wav", bass_loop(148, 4, [55.0, 55.0, 73.42, 0, 49.0, 49.0, 82.41, 73.42], True, 0.8))
write_wav("music_vs.wav", bass_loop(160, 4, [110.0, 0, 98.0, 110.0, 82.41, 0, 130.81, 98.0], True, 0.6))
write_wav("music_survive.wav", bass_loop(138, 4, [41.2, 41.2, 49.0, 36.71, 41.2, 0, 55.0, 49.0], True, 0.5))
print("story audio done")
