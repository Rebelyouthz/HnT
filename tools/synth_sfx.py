import math
import random
import struct
import wave
from pathlib import Path

OUT = Path("/home/timmietooth/projects/HnT/assets/audio")
OUT.mkdir(parents=True, exist_ok=True)
SR = 48000


def write_wav(name: str, samples: list[float], loop: bool = False) -> None:
    path = OUT / name
    n = len(samples)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = max(-0.98, min(0.98, s))
            frames += struct.pack("<h", int(v * 32767))
        w.writeframes(frames)
    print("wrote", path, "samples", n)


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


write_wav("snap.wav", mix(whoosh(0.28), impact(0.22, 140, 55, 0.35)))
write_wav("slap.wav", mix(impact(0.18, 90, 40, 0.5), whoosh(0.12)))
write_wav("web.wav", mix(whoosh(0.2), [tone(880 + i * 0.4, i / SR) * env(i / SR, 0.01, 0.25) * 0.4 for i in range(int(SR * 0.28))]))
write_wav("block.wav", impact(0.12, 520, 180, 0.2))
write_wav("dash.wav", whoosh(0.16))
write_wav("jump.wav", impact(0.1, 240, 160, 0.05))
write_wav("shuriken.wav", mix(whoosh(0.14), impact(0.08, 1400, 700, 0.1)))
write_wav("kill.wav", mix(impact(0.28, 70, 32, 0.55), whoosh(0.2)))
write_wav("throw.wav", impact(0.16, 110, 60, 0.25))
write_wav("finish.wav", mix(whoosh(0.35), impact(0.3, 55, 28, 0.4)))
write_wav("card.wav", mix(impact(0.12, 660, 440, 0.05), [tone(880, i / SR) * env(i / SR, 0.01, 0.2) * 0.3 for i in range(int(SR * 0.22))]))
write_wav("shop.wav", [tone(523.25, i / SR) * env(i / SR, 0.01, 0.18) * 0.4 + tone(659.25, i / SR) * env(i / SR, 0.02, 0.2) * 0.3 for i in range(int(SR * 0.24))])


def bass_loop(bpm: float, bars: int, motif: list[float], drums: bool) -> list[float]:
    beat = 60.0 / bpm
    dur = beat * 4 * bars
    n = int(SR * dur)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        beat_i = int(t / beat) % len(motif)
        freq = motif[beat_i]
        phase_t = t
        s = 0.0
        if freq > 1:
            s += 0.42 * math.sin(2 * math.pi * freq * phase_t)
            s += 0.18 * math.sin(2 * math.pi * freq * 2 * phase_t)
        # hat
        if drums and (int(t / (beat * 0.5)) % 2 == 0):
            ht = (t % (beat * 0.5))
            s += noise() * env(ht, 0.001, 0.04) * 0.08
        # kick
        if drums and int(t / beat) % 2 == 0:
            kt = t % beat
            s += math.sin(2 * math.pi * (70 - kt * 40) * kt) * env(kt, 0.004, 0.12) * 0.35
        out[i] = s * 0.7
    peak = max(0.001, max(abs(x) for x in out))
    return [x / peak * 0.7 for x in out]


clinic = bass_loop(120, 4, [65.41, 0, 73.42, 0, 65.41, 0, 49.0, 55.0], False)
write_wav("music_clinic.wav", clinic, True)
street = bass_loop(132, 4, [82.41, 82.41, 98.0, 0, 73.42, 73.42, 110.0, 98.0], True)
write_wav("music_street.wav", street, True)

# quiet placeholder VO if ElevenLabs files arrive later
vo = [tone(140, i / SR) * env(i / SR, 0.02, 0.35) * 0.01 for i in range(int(SR * 0.4))]
write_wav("vo_grounded.wav", vo)
write_wav("vo_son.wav", vo)
print("done")
