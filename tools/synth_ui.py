#!/usr/bin/env python3
"""Menu reward / upgrade sounds, synthesized (numpy):

    python3 tools/synth_ui.py  ->  assets/audio/ui/*.wav

coin_tick   short bright blip for counting up (pitch it up while counting)
coin_land   bell ding when a coin reaches the counter
gem_land    glassy chime for gems
reward_pop  the reward banner bursting in (thump + sparkle)
whoosh      coins leaving for the corner
up_rise     rising arpeggio for an upgrade
up_boom     the big landing of an upgrade (sub thump + shimmer)
part_slide  metal part sliding along a rail
part_click  part locking into place (two clicks + ring)
part_off    part unscrewed (reverse ratchet)
deny        soft "no" buzz
"""
from pathlib import Path
import wave

import numpy as np

OUT = Path(__file__).resolve().parent.parent / "assets/audio/ui"
SR = 44100
rng = np.random.default_rng(7)


def t_(secs):
    return np.arange(int(SR * secs)) / SR


def env(t, a, d, curve=4.0):
    e = np.minimum(1.0, t / max(a, 1e-4))
    tail = np.clip((t - a) / max(d, 1e-4), 0, 1)
    return e * (1 - tail) ** curve


def sine(f, t):
    return np.sin(2 * np.pi * f * t)


def bell(f, secs=0.6, partials=((1, 1), (2.76, 0.4), (5.4, 0.2), (8.9, 0.1))):
    t = t_(secs)
    s = sum(a * sine(f * k, t) * np.exp(-t * (4 + k * 2.2)) for k, a in partials)
    return s * env(t, 0.002, secs, 1.0)


def noise(secs):
    return rng.uniform(-1, 1, int(SR * secs))


def lowpass(x, k=0.15):
    y = np.zeros_like(x)
    kk = np.broadcast_to(np.asarray(k, dtype=float), x.shape)
    acc = 0.0
    for i, v in enumerate(x):
        acc += kk[i] * (v - acc)
        y[i] = acc
    return y


def mix(*parts):
    n = max(len(p) for p, _ in parts)
    out = np.zeros(n)
    for p, at in parts:
        i = int(at * SR)
        seg = p[: max(0, n - i)]
        out[i:i + len(seg)] += seg
    return out


def save(name, x, gain=0.8):
    x = x / max(1e-6, np.max(np.abs(x))) * gain
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print("wrote", name)


def main():
    t = t_(0.06)
    save("coin_tick", sine(2400, t) * env(t, 0.001, 0.05) + 0.4 * sine(3600, t) * env(t, 0.001, 0.03), 0.5)
    save("coin_land", mix((bell(1568, 0.45), 0), (bell(2093, 0.4) * 0.6, 0.035)), 0.6)
    save("gem_land", mix((bell(2637, 0.6, ((1, 1), (3.0, 0.5), (4.2, 0.3))), 0), (bell(3520, 0.5) * 0.5, 0.05)), 0.55)
    tt = t_(0.5)
    thump = sine(90 * np.exp(-tt * 9) + 40, tt) * env(tt, 0.003, 0.3, 2)
    spark = lowpass(noise(0.5), 0.6) * env(tt, 0.002, 0.35, 3) * 0.3
    save("reward_pop", mix((thump, 0), (spark, 0), (bell(1760, 0.5) * 0.5, 0.02), (bell(2637, 0.45) * 0.35, 0.07)))
    tw = t_(0.35)
    wn = lowpass(noise(0.35), 0.08 + 0.3 * tw / 0.35)
    save("whoosh", wn * np.sin(np.pi * tw / 0.35) ** 2, 0.5)
    notes = [523, 659, 784, 1047, 1319]
    save("up_rise", mix(*[(bell(f, 0.5) * (0.6 + 0.1 * i), i * 0.06) for i, f in enumerate(notes)]), 0.7)
    tb = t_(1.0)
    sub = sine(70 * np.exp(-tb * 5) + 35, tb) * env(tb, 0.004, 0.7, 2)
    shim = sum(sine(f, tb) * 0.15 for f in (1047, 1319, 1568, 2093)) * env(tb, 0.05, 0.9, 2)
    save("up_boom", mix((sub, 0), (shim, 0.02), (lowpass(noise(0.4), 0.3) * env(t_(0.4), 0.001, 0.3) * 0.5, 0)))
    ts = t_(0.32)
    scrape = lowpass(noise(0.32), 0.5) * (0.4 + 0.6 * ts / 0.32) * env(ts, 0.02, 0.3, 1)
    save("part_slide", scrape + 0.15 * sine(900 + 600 * ts, ts) * env(ts, 0.02, 0.3), 0.45)

    def click(f=3200):
        tc = t_(0.03)
        return (lowpass(noise(0.03), 0.9) + 0.5 * sine(f, tc)) * env(tc, 0.0005, 0.025, 3)
    save("part_click", mix((click(2600), 0), (click(3400), 0.07), (bell(1175, 0.35) * 0.35, 0.07)), 0.75)
    save("part_off", mix(*[(click(2200 + i * 200) * (0.6 + 0.1 * i), i * 0.045) for i in range(4)]), 0.6)
    td = t_(0.22)
    save("deny", (np.sign(sine(140, td)) * 0.4 + sine(110, td)) * env(td, 0.005, 0.2, 2), 0.35)


if __name__ == "__main__":
    main()
