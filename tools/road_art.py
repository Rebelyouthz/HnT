#!/usr/bin/env python3
"""One painted cobblestone road per screen: a single wide image that spans
the whole street band from the kerb down past the camera, tiling only
sideways (the one seam is where one image meets the next). Stones grow
with perspective toward the viewer; wet mortar, puddles, glossy top edges.

    python3 tools/road_art.py   ->  assets/backdrops/street_road.png
                                    assets/backdrops/street_road_wet.png

At 4 texels per world unit: 1920 x 860 = 480 x 215 world units (the road is
laid from the kerb, y 426, down to 641).
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

OUT = Path(__file__).resolve().parent.parent / "assets/backdrops"
W, H = 1920, 860
rng = np.random.default_rng(7)


def superellipse(cx, cy, rx, ry, n=3.2, k=28, wob=0.0):
    pts = []
    for i in range(k):
        t = 2 * np.pi * i / k
        c, s = np.cos(t), np.sin(t)
        x = np.sign(c) * abs(c) ** (2 / n) * rx
        y = np.sign(s) * abs(s) ** (2 / n) * ry
        j = 1.0 + rng.uniform(-wob, wob)
        pts.append((cx + x * j, cy + y * j))
    return pts


def main():
    ids = Image.new("I", (W, H), 0)
    d = ImageDraw.Draw(ids)
    tops, bots, cols = [0], [1], [(0, 0, 0)]
    y = 0.0
    row = 0
    while y < H:
        f = y / H
        rh = 13 + 88 * f ** 1.35                 # far rows small, near rows big
        gap = max(1.2, rh * 0.04)
        sw = rh * rng.uniform(1.25, 1.6)         # stone length
        n = max(6, int(round(W / sw)))
        sw = W / n
        off = (row % 2) * sw * 0.5 + rng.uniform(-sw * 0.15, sw * 0.15)
        edges = [off + i * sw + rng.uniform(-sw * 0.22, sw * 0.22) for i in range(n)]
        edges.append(edges[0] + W)
        for i in range(n):
            x0, x1 = edges[i], edges[i + 1]
            cx = (x0 + x1) / 2
            hh = rh * rng.uniform(0.86, 1.0)
            cy = y + rh / 2 + rng.uniform(-rh * 0.06, rh * 0.06)
            rx = (x1 - x0) / 2 - gap / 2
            ry = hh / 2 - gap / 2
            sid = len(tops)
            warm = rng.random() < 0.08
            base = rng.uniform(0.7, 1.3)
            tint = rng.uniform(-3, 3)
            if warm:
                col = (46 * base, 42 * base, 42 * base)
            else:
                col = ((34 + tint) * base, (39 + tint) * base, 48 * base)
            cols.append(col)
            tops.append(cy - ry)
            bots.append(cy + ry)
            for shift in (0, -W, W):              # wrap so it tiles sideways
                pts = superellipse(cx + shift, cy, rx, ry, n=rng.uniform(3.6, 5.5), k=36, wob=0.07)
                d.polygon(pts, fill=sid)
        y += rh
        row += 1
    idm = np.asarray(ids, dtype=np.int32)
    stone = idm > 0
    tops = np.array(tops)
    bots = np.array(bots)
    cols = np.array(cols, dtype=float)
    yy = np.arange(H)[:, None].repeat(W, 1).astype(float)
    rel = np.clip((yy - tops[idm]) / np.maximum(1.0, bots[idm] - tops[idm]), 0, 1)
    img = cols[idm].copy()
    # Grain: two octaves of noise per pixel, stronger on the big near stones.
    g1 = ndimage.gaussian_filter(rng.normal(0, 1, (H, W)), 1.2)
    g2 = ndimage.gaussian_filter(rng.normal(0, 1, (H, W)), 4.0)
    g0 = rng.normal(0, 1, (H, W))
    grain = (g0 * 0.05 + g1 * 0.1 + g2 * 0.14)[..., None]
    img *= 1.0 + grain
    # Rounded tops: distance to the joint gives a bevel; the upper rim catches
    # the light (wet sheen), the lower rim falls into shadow.
    dist = ndimage.distance_transform_edt(stone)
    rim = np.clip(1.0 - dist / 6.0, 0, 1)
    up = (rel < 0.45)
    img += (rim * up * 22.0)[..., None] * np.array([0.8, 0.95, 1.15])
    img *= (1.0 - (rim * (~up) * 0.3))[..., None]
    # Dome shading across the stone.
    img *= (1.08 - 0.28 * rel)[..., None]
    # Mortar: near black, a little blue, wet.
    mortar = ~stone
    grime = ndimage.gaussian_filter(rng.normal(0, 1, (H, W)), 6)
    mcol = np.stack([18 + 6 * grime, 21 + 5 * grime, 27 + 3 * grime], -1)
    img[mortar] = np.clip(mcol[mortar], 6, 50)
    # Puddles: big soft ovals, squashed by perspective, darker and smooth.
    wet = mortar.astype(float) * 0.85
    pud = np.zeros((H, W))
    for i in range(14):
        cx = rng.uniform(0, W)
        cy = rng.uniform(H * 0.15, H * 0.95)
        rx = rng.uniform(70, 220) * (0.6 + cy / H)
        ry = rx * rng.uniform(0.16, 0.26)
        for shift in (0, -W, W):
            yy2, xx2 = np.ogrid[:H, :W]
            e = ((xx2 - cx - shift) / rx) ** 2 + ((yy2 - cy) / ry) ** 2
            pud = np.maximum(pud, np.clip(1.4 - e, 0, 1))
    pud = ndimage.gaussian_filter(pud, 3)
    pud = np.clip(pud * 1.3, 0, 1)
    # A puddle drowns the stones: smooth dark water, the cobbles faint under it.
    img = img * (1 - pud[..., None] * 0.78) + np.array([12, 16, 26]) * pud[..., None] * 0.78
    wet = np.clip(np.maximum(wet, pud), 0, 1)
    # Stone faces themselves are damp: a faint sheen everywhere.
    wet = np.maximum(wet, 0.12 * stone)
    # Big soft light and dirt patches so the road is not one even grid.
    patch = ndimage.gaussian_filter(rng.normal(0, 1, (H // 8 + 1, W // 8)), 6, mode="wrap")
    patch = np.kron(patch, np.ones((8, 8)))[:H, :W]
    patch = patch / (np.abs(patch).max() + 1e-6)
    img *= (1.0 + 0.22 * patch)[..., None]
    # Distance haze: the far rows (by the kerb) a touch lighter and bluer.
    haze = np.clip(1.0 - yy / (H * 0.35), 0, 1)[..., None]
    img = img * (1 - haze * 0.25) + np.array([40, 46, 60]) * haze * 0.25
    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")
    out = out.filter(ImageFilter.GaussianBlur(0.6)).filter(ImageFilter.UnsharpMask(radius=1.5, percent=40, threshold=3))
    out.save(OUT / "street_road.png")
    Image.fromarray((wet * 255).astype(np.uint8), "L").save(OUT / "street_road_wet.png")
    print("ok", out.size, np.asarray(out).mean())


if __name__ == "__main__":
    main()
