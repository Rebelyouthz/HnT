#!/usr/bin/env python3
"""Full-width painted grounds for the non-cobble maps, same contract as
tools/road_art.py: one 1920x860 image (4 texels a unit) from the kerb down,
tiling only sideways, plus a wet mask.

The ground is drawn as an oblique floor: rows get taller toward the camera
(foreshortening) and depth lines slant one way, so lines stay parallel and
the image still repeats every 1920 px.

    python3 tools/ground_art.py   -> assets/backdrops/<name>_road.png + _road_wet.png
      lot_ground      wet asphalt car park, slanted stall lines, cracks, oil
      concrete_floor  processing floor slabs, safety stripe, stains
      clinic_floor    clinic tiles, scuffs, mop streaks
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

OUT = Path(__file__).resolve().parent.parent / "assets/backdrops"
W, H = 1920, 860
SLANT = 0.55            # depth lines lean this much x per y
DEPTH = 1400.0          # ground units from kerb to the bottom edge


def coords():
    y = np.arange(H, dtype=float)[:, None]
    x = np.arange(W, dtype=float)[None, :]
    t = y / H
    v = DEPTH * (t ** 1.45)                       # far rows squashed
    u = (x + SLANT * y) % W                       # oblique shear, still periodic
    return np.broadcast_to(u, (H, W)), np.broadcast_to(v, (H, W)), t


def wnoise(rng, sigma, shape=(H, W)):
    n = rng.normal(0, 1, shape)
    n = ndimage.gaussian_filter(n, sigma, mode="wrap")
    return n / (np.abs(n).max() + 1e-6)


def ellipse_mask(u, v, cx, cy, rx, ry):
    du = (u - cx + W / 2) % W - W / 2
    return np.clip(1.3 - ((du / rx) ** 2 + ((v - cy) / ry) ** 2), 0, 1)


def stripes(u, period, width, offset=0.0):
    d = np.abs(((u - offset) % period) - period / 2) - (period / 2 - width / 2)
    return np.clip(d + 1.0, 0, 1)                # 1 inside the stripe


def finish(img, wet, name, rng, t):
    haze = np.clip(1.0 - t / 0.35, 0, 1)[..., None]
    img = img * (1 - haze * 0.22) + np.array([40, 46, 60]) * haze * 0.22
    patch = wnoise(rng, 60)
    img *= (1.0 + 0.18 * patch)[..., None]
    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")
    out = out.filter(ImageFilter.GaussianBlur(0.5)).filter(ImageFilter.UnsharpMask(radius=1.4, percent=40, threshold=3))
    out.save(OUT / f"{name}_road.png")
    Image.fromarray((np.clip(wet, 0, 1) * 255).astype(np.uint8), "L").save(OUT / f"{name}_road_wet.png")
    print(name, "ok", np.asarray(out).mean())


def lot():
    rng = np.random.default_rng(11)
    u, v, t = coords()
    g = wnoise(rng, 1.0) * 0.5 + wnoise(rng, 3) * 0.5
    img = np.stack([30 + 9 * g, 33 + 9 * g, 36 + 9 * g], -1)
    # Aggregate speckle.
    sp = rng.random((H, W)) < 0.02
    img[sp] += 18
    # Stall lines: slanted white bars every 320 units in a far and a near row,
    # a long line between them; paint worn by tyres.
    wear = np.clip(wnoise(rng, 2) * 1.6 + 0.4, 0, 1)
    far = (v > 40) & (v < 420)
    near = (v > 760) & (v < 1240)
    bar = stripes(u, 320, 24) * (far | near)
    long = np.clip(1 - np.abs(v - 590) / 12, 0, 1)
    paint = np.clip(bar + long, 0, 1) * wear
    img = img * (1 - paint[..., None] * 0.8) + np.array([196, 196, 186]) * paint[..., None] * 0.8
    # Cracks: random walks in ground space.
    crack = np.zeros((H, W))
    for i in range(26):
        x, y = rng.uniform(0, W), rng.uniform(0, H)
        a = rng.uniform(0, np.pi)
        for s in range(rng.integers(40, 160)):
            a += rng.normal(0, 0.35)
            x = (x + np.cos(a) * 2.2) % W
            y = y + np.sin(a) * 2.2 * (0.4 + y / H)
            if 0 <= y < H:
                crack[int(y), int(x)] = 1
    crack = ndimage.binary_dilation(crack > 0, iterations=1)
    img[crack] *= 0.35
    # Oil stains (dark rainbow sheen later from the reflection) and puddles.
    wet = np.full((H, W), 0.18)
    for i in range(16):
        m = ellipse_mask(u, v, rng.uniform(0, W), rng.uniform(80, DEPTH - 80), rng.uniform(40, 120), rng.uniform(30, 80))
        m = ndimage.gaussian_filter(m, 2) * (0.5 + 0.5 * wnoise(rng, 6) > 0.1)
        img *= (1 - m * 0.45)[..., None]
        wet = np.maximum(wet, m * 0.5)
    for i in range(12):
        m = ellipse_mask(u, v, rng.uniform(0, W), rng.uniform(60, DEPTH - 40), rng.uniform(110, 260), rng.uniform(60, 140))
        m = np.clip(ndimage.gaussian_filter(m, 3) * 1.4, 0, 1)
        img = img * (1 - m[..., None] * 0.7) + np.array([12, 18, 24]) * m[..., None] * 0.7
        wet = np.maximum(wet, m)
    # Two drain grates.
    for cx in (520.0, 1500.0):
        gm = (np.abs(((u - cx + W / 2) % W) - W / 2) < 46) & (np.abs(v - 600) < 34)
        bars = (np.floor(((u - cx) % W) / 8) % 2 == 0)
        img[gm] = np.where(bars[gm][:, None], [10, 11, 13], [46, 48, 50])
        wet[gm] = 0.7
    finish(img, wet, "lot_ground", rng, t)


def concrete():
    rng = np.random.default_rng(23)
    u, v, t = coords()
    g = wnoise(rng, 1.2) * 0.4 + wnoise(rng, 8) * 0.6
    img = np.stack([70 + 14 * g, 66 + 13 * g, 58 + 12 * g], -1)
    # Slab joints: every 240 along, rows every 260 deep.
    ju = np.abs((u % 240) - 120) > 118
    jv = np.abs((v % 260) - 130) > 127
    joint = (ju | jv)
    img[joint] *= 0.45
    # Hazard stripe near the kerb (yellow/black diagonal).
    band = (v > 30) & (v < 70)
    diag = (np.floor((u + v * 1.2) / 26) % 2 == 0)
    img[band & diag] = [190, 150, 30]
    img[band & ~diag] = [24, 22, 20]
    # Stains and rust bolts.
    wet = np.full((H, W), 0.12)
    for i in range(22):
        m = ellipse_mask(u, v, rng.uniform(0, W), rng.uniform(100, DEPTH), rng.uniform(40, 160), rng.uniform(30, 110))
        m = ndimage.gaussian_filter(m, 4)
        img *= (1 - m * rng.uniform(0.15, 0.4))[..., None]
        wet = np.maximum(wet, m * 0.6)
    finish(img, wet, "concrete_floor", rng, t)


def clinic():
    rng = np.random.default_rng(37)
    u, v, t = coords()
    g = wnoise(rng, 1.0)
    tile_u = np.floor(u / 96)
    tile_v = np.floor(v / 110)
    check = ((tile_u + tile_v) % 2 == 0)
    base = np.where(check[..., None], [150, 160, 150], [118, 128, 122])
    img = base * (1 + 0.05 * g[..., None])
    grout = (np.abs((u % 96) - 48) > 46.5) | (np.abs((v % 110) - 55) > 53.5)
    img[grout] = [60, 66, 62]
    # Scuffs and mop streaks.
    wet = np.full((H, W), 0.25)
    for i in range(14):
        m = ellipse_mask(u, v, rng.uniform(0, W), rng.uniform(60, DEPTH), rng.uniform(160, 380), rng.uniform(20, 50))
        m = ndimage.gaussian_filter(m, 3)
        wet = np.maximum(wet, m * 0.8)
        img *= (1 - m * 0.08)[..., None]
    sc = wnoise(rng, 2) > 0.55
    img[sc] *= 0.82
    finish(img, wet, "clinic_floor", rng, t)


if __name__ == "__main__":
    lot()
    concrete()
    clinic()
