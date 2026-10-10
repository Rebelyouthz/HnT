#!/usr/bin/env python3
"""Turn a generated pixel-art backdrop into a true pixel-grid texture.

AI "pixel art" is drawn on a soft ~4 px pseudo-grid. This finds the grid
(period and phase from gradient energy), takes the median colour of every
block, and writes the native-resolution PNG. The game draws it with nearest
at BACKDROP_TEXEL world units per texel (SpriteBook), i.e. 6 screen pixels per
texel on 1080p under the 1.5x couch camera: integer, crisp, no shimmer.

    python3 tools/backdrop.py in.jpg assets/backdrops/dock.png [--crop x0,y0,x1,y1]
Also writes <out>.json with the texel height of the ground line (sidewalk).
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image


def _energy(gray: np.ndarray, axis: int) -> np.ndarray:
    return np.abs(np.diff(gray, axis=axis)).mean(axis=1 - axis)


def grid(gray: np.ndarray, axis: int) -> tuple[float, float]:
    """(period, phase) of the pseudo-pixel grid along one axis."""
    e = _energy(gray, axis)
    e = e - e.mean()
    n = e.shape[0]
    idx = np.arange(n)
    best = (0.0, 4.0, 0.0)
    for p in np.arange(3.0, 8.01, 0.02):
        # Project edge energy onto a comb of period p; the phase comes from
        # the complex sum (a Fourier coefficient at 1/p).
        z = (e * np.exp(-2j * np.pi * idx / p)).sum()
        score = abs(z) / n
        if score > best[0]:
            best = (score, float(p), float((-np.angle(z) / (2 * np.pi) * p) % p))
    return best[1], best[2]


def snap(img: np.ndarray, px: float, ox: float, py: float, oy: float) -> np.ndarray:
    h, w = img.shape[:2]
    xs = np.arange(ox + 0.5, w - 1, px)
    ys = np.arange(oy + 0.5, h - 1, py)
    out = np.zeros((len(ys) - 1, len(xs) - 1, 3), np.uint8)
    for j in range(len(ys) - 1):
        y0, y1 = int(round(ys[j])), int(round(ys[j + 1]))
        for i in range(len(xs) - 1):
            x0, x1 = int(round(xs[i])), int(round(xs[i + 1]))
            # Inner 60% of the block: skip the soft AI edge between blocks.
            iy0 = y0 + (y1 - y0) // 5
            iy1 = max(iy0 + 1, y1 - (y1 - y0) // 5)
            ix0 = x0 + (x1 - x0) // 5
            ix1 = max(ix0 + 1, x1 - (x1 - x0) // 5)
            block = img[iy0:iy1, ix0:ix1].reshape(-1, 3)
            out[j, i] = np.median(block, axis=0)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--crop", default="")
    ap.add_argument("--ground", type=float, default=0.86,
                    help="ground line (sidewalk top) as a fraction of the source height")
    ap.add_argument("--period", type=float, default=0.0,
                    help="force a square grid of this many source px per texel (images with no real grid)")
    a = ap.parse_args()
    im = Image.open(a.src).convert("RGB")
    ground_px = im.size[1] * a.ground
    if a.crop:
        x0, y0, x1, y1 = (int(v) for v in a.crop.split(","))
        im = im.crop((x0, y0, x1, y1))
        ground_px -= y0
    rgb = np.asarray(im)
    gray = rgb.astype(np.float32).mean(axis=2)
    if a.period > 0:
        px = py = a.period
        ox = oy = 0.0
    else:
        px, ox = grid(gray, 1)
        py, oy = grid(gray, 0)
    out = snap(rgb, px, ox, py, oy)
    Path(a.dst).parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(out, "RGB").save(a.dst, optimize=True)
    meta = {"ground": round((ground_px - oy) / py, 1), "size": [out.shape[1], out.shape[0]]}
    Path(a.dst).with_suffix(".json").write_text(json.dumps(meta))
    print("grid %.2f x %.2f px, phase %.2f/%.2f -> %dx%d, ground texel %.1f"
          % (px, py, ox, oy, out.shape[1], out.shape[0], meta["ground"]))


if __name__ == "__main__":
    main()
