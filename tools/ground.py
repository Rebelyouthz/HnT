#!/usr/bin/env python3
"""Street ground strip from a generated painting: crop the road, snap the
pseudo-pixel grid (backdrop.py), make it tile seamlessly left/right with a
minimum-error seam, and write a puddle mask (alpha) for the wet-reflection
shader: puddles are the dark, flat patches.

    python3 tools/ground.py src.png assets/backdrops/street.png --crop 0,200,1536,1024
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, str(Path(__file__).parent))
from backdrop import grid, snap  # noqa: E402


def seam_tile(img: np.ndarray, overlap: int) -> np.ndarray:
    """Wrap the right `overlap` columns onto the left ones along the vertical
    path of least colour difference, then drop them: the strip tiles."""
    h, w = img.shape[:2]
    a = img[:, w - overlap:].astype(np.float32)
    b = img[:, :overlap].astype(np.float32)
    err = ((a - b) ** 2).sum(axis=2)
    cost = err.copy()
    for y in range(1, h):
        prev = cost[y - 1]
        left = np.r_[np.inf, prev[:-1]]
        right = np.r_[prev[1:], np.inf]
        cost[y] += np.minimum(np.minimum(left, prev), right)
    path = np.zeros(h, int)
    path[-1] = int(np.argmin(cost[-1]))
    for y in range(h - 2, -1, -1):
        x = path[y + 1]
        lo, hi = max(0, x - 1), min(overlap, x + 2)
        path[y] = lo + int(np.argmin(cost[y, lo:hi]))
    out = img[:, : w - overlap].copy()
    for y in range(h):
        # Left of the seam comes from the strip's tail, right from its head.
        out[y, : path[y]] = img[y, w - overlap : w - overlap + path[y]]
    return out


def puddles(rgb: np.ndarray) -> np.ndarray:
    lum = rgb.astype(np.float32).mean(axis=2)
    im = Image.fromarray(lum.astype(np.uint8))
    mean = np.asarray(im.filter(ImageFilter.BoxBlur(2)), np.float32)
    sq = np.asarray(Image.fromarray(np.clip(lum * lum / 255.0, 0, 255).astype(np.uint8)).filter(ImageFilter.BoxBlur(2)), np.float32)
    var = np.clip(sq * 255.0 - mean * mean, 0, None) ** 0.5
    dark = np.clip((np.percentile(lum, 35) - mean) / 18.0, 0, 1)
    flat = np.clip(1.0 - var / 14.0, 0, 1)
    m = dark * flat
    # Bright glints sitting on puddle rims count as water too.
    m = np.maximum(m, np.clip((lum - np.percentile(lum, 97)) / 30.0, 0, 1) * 0.8)
    # Opening drops thin cracks and grate slots; only real pools survive.
    mi = Image.fromarray((m * 255).astype(np.uint8))
    mi = mi.filter(ImageFilter.MinFilter(5)).filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.BoxBlur(1))
    return np.asarray(mi)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--crop", default="")
    ap.add_argument("--period", type=float, default=0.0)
    ap.add_argument("--overlap", type=int, default=40)
    ap.add_argument("--gain", type=float, default=1.0, help="lift a too-dark painting (applied before snapping)")
    a = ap.parse_args()
    im = Image.open(a.src).convert("RGB")
    if a.crop:
        im = im.crop(tuple(int(v) for v in a.crop.split(",")))
    rgb = np.asarray(im)
    gray = rgb.astype(np.float32).mean(axis=2)
    if a.period > 0:
        px = py = a.period
        ox = oy = 0.0
    else:
        px, ox = grid(gray, 1)
        py, oy = grid(gray, 0)
    out = seam_tile(snap(rgb, px, ox, py, oy), a.overlap)
    mask = puddles(out)
    if a.gain != 1.0:
        f = out.astype(np.float32) / 255.0
        f = np.clip(f ** (1.0 / a.gain) * min(1.6, a.gain), 0, 1)
        # Tame the generator's white glints: they read as snow once lifted.
        lum = f.mean(axis=2, keepdims=True)
        hot = np.clip((lum - 0.55) / 0.3, 0, 1)
        f = f * (1 - hot * 0.45) + np.array([0.25, 0.4, 0.55]) * hot * 0.3
        out = (np.clip(f, 0, 1) * 255).astype(np.uint8)
    Path(a.dst).parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(out, "RGB").save(a.dst, optimize=True)
    Image.fromarray(mask, "L").save(str(Path(a.dst).with_suffix("")) + "_wet.png", optimize=True)
    print("grid %.2f x %.2f -> %dx%d, puddle cover %.0f%%" % (px, py, out.shape[1], out.shape[0], (mask > 128).mean() * 100))


if __name__ == "__main__":
    main()
