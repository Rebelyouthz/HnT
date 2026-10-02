#!/usr/bin/env python3
"""Stitch several painted facade sections into one continuous street.

Every section is a separate generated painting of the same street (same
prompt frame, different shops). Each is cut so its kerb (the front edge of
the sidewalk) sits on the bottom row, then neighbours are joined along the
vertical path of least colour difference inside an overlap band, so the
street runs on without a visible seam. The long strip is written as chunks
(GPU-friendly widths) plus a JSON the game lays out left to right:

    python3 tools/street_strip.py assets/backdrops/dock_strip a.png b.png c.png ...
    -> dock_strip_0.png, dock_strip_1.png, ..., dock_strip.json
       {"ground": <kerb row>, "texel": 0.26, "parts": [w0, w1, ...], "sections": [[x0, name], ...]}
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

HEIGHT = 792
OVERLAP = 120
CHUNK = 4096


def kerb_row(rgb: np.ndarray) -> int:
    """Front edge of the sidewalk: the lit pavement above, the dark road
    below. Strongest bright-to-dark step in the lower part of the image."""
    lum = rgb.astype(np.float32).mean(axis=2).mean(axis=1)
    h = len(lum)
    best, at = -1e9, int(h * 0.92)
    for y in range(int(h * 0.66), int(h * 0.97)):
        above = lum[max(0, y - 8):y].mean()
        below = lum[y:y + 8].mean()
        d = above - below
        if d > best:
            best, at = d, y
    return at


def cut(path: str, kerb: int = 0) -> np.ndarray:
    im = Image.open(path).convert("RGB")
    rgb = np.asarray(im)
    k = kerb or kerb_row(rgb)
    # One street scale: everything above the kerb fills the strip height,
    # so a painting framed wider (smaller buildings) is enlarged to match.
    if k < HEIGHT:
        f = HEIGHT / float(k)
        im = im.resize((int(round(im.width * f)), int(round(im.height * f))), Image.LANCZOS)
        rgb = np.asarray(im)
        k = HEIGHT
    top = k - HEIGHT
    if top < 0:
        pad = np.repeat(rgb[:1], -top, axis=0)
        rgb = np.concatenate([pad, rgb], axis=0)
        k -= top
        top = 0
    print("%s: kerb %d" % (Path(path).name, k))
    return rgb[top:k].copy()


def seam_join(a: np.ndarray, b: np.ndarray, overlap: int) -> np.ndarray:
    """a's last `overlap` columns and b's first ones cover the same span;
    cross over along the cheapest vertical path, feathered by 2 px."""
    h = a.shape[0]
    ta = a[:, -overlap:].astype(np.float32)
    hb = b[:, :overlap].astype(np.float32)
    err = ((ta - hb) ** 2).sum(axis=2)
    # Keep the path off the very edges of the band.
    err[:, :8] += 1e7
    err[:, -8:] += 1e7
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
    band = np.empty_like(ta)
    xs = np.arange(overlap)[None, :]
    w = np.clip((xs - path[:, None] + 2) / 4.0, 0.0, 1.0)[..., None]
    band = ta * (1.0 - w) + hb * w
    return np.concatenate([a[:, :-overlap], band.astype(np.uint8), b[:, overlap:]], axis=1)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("sections", nargs="+")
    ap.add_argument("--texel", type=float, default=0.26)
    a = ap.parse_args()
    strip = None
    starts = []
    for p in a.sections:
        # name.png or name.png@kerbrow to override the detector.
        kerb = 0
        if "@" in p:
            p, k = p.split("@")
            kerb = int(k)
        img = cut(p, kerb)
        if strip is None:
            starts.append([0, Path(p).stem])
            strip = img
        else:
            starts.append([strip.shape[1] - OVERLAP, Path(p).stem])
            strip = seam_join(strip, img, OVERLAP)
    out = Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    parts = []
    x = 0
    i = 0
    w = strip.shape[1]
    while x < w:
        piece = strip[:, x:x + CHUNK]
        Image.fromarray(piece).save(out.parent / ("%s_%d.png" % (out.name, i)), optimize=True)
        parts.append(int(piece.shape[1]))
        x += CHUNK
        i += 1
    meta = {"ground": HEIGHT - 1, "texel": a.texel, "parts": parts, "sections": starts}
    (out.parent / (out.name + ".json")).write_text(json.dumps(meta))
    Image.fromarray(strip).resize((w // 6, HEIGHT // 6)).save(out.parent / (out.name + "_preview.png"))
    print("strip %d px (%d world units at texel %.2f), %d parts" % (w, int(w * a.texel), a.texel, len(parts)))


if __name__ == "__main__":
    main()
