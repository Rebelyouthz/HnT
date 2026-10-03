#!/usr/bin/env python3
"""Reward chests for the AWARDS tab, 64x64 pixel art doubled to 128 like the
other hub icons:  python3 tools/chest_art.py  ->  assets/sprites/hub/chest_{locked,ready,open}.png

  locked  dark wood, iron bands, a padlock: not earned yet
  ready   lit wood, gold bands, glow and sparkles: claim me
  open    lid thrown back, coins and a gem spilling, a receipt on top
"""
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets/sprites/hub"
INK = (16, 12, 18, 255)


def k(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)


def outline(im):
    a = im.load()
    w, h = im.size
    out = im.copy()
    o = out.load()
    for y in range(h):
        for x in range(w):
            if a[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and a[nx, ny][3] > 0:
                        o[x, y] = INK
                        break
    return out


def planks(d, x0, y0, x1, y1, wood):
    d.rectangle([x0, y0, x1, y1], fill=wood)
    for y in range(y0 + 4, y1, 5):
        d.line([x0, y, x1, y], fill=k(wood, 0.7))
    d.line([x0, y0, x1, y0], fill=k(wood, 1.35))
    for i, x in enumerate(range(x0 + 3, x1, 7)):
        d.point([x, y0 + 2 + (i % 3)], fill=k(wood, 0.6))


def chest(state):
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if state == "locked":
        wood, band = (86, 54, 36, 255), (92, 96, 108, 255)
    else:
        wood, band = (150, 88, 44, 255), (232, 182, 58, 255)
    # Body.
    planks(d, 10, 32, 53, 54, wood)
    d.rectangle([10, 52, 53, 54], fill=k(wood, 0.55))
    if state == "open":
        # Lid thrown back: its underside, dark inside, loot spilling.
        d.polygon([(10, 31), (53, 31), (50, 14), (13, 14)], fill=k(wood, 0.5))
        d.line([13, 14, 50, 14], fill=k(band, 1.0))
        d.rectangle([12, 29, 51, 33], fill=(40, 22, 18, 255))
        for i, (x, y) in enumerate([(16, 27), (21, 25), (27, 26), (33, 24), (39, 26), (45, 27), (24, 29), (36, 29), (30, 28)]):
            d.ellipse([x - 3, y - 2, x + 3, y + 2], fill=(246, 196, 64, 255))
            d.point([x - 1, y - 1], fill=(255, 244, 190, 255))
        d.polygon([(30, 18), (35, 22), (30, 27), (25, 22)], fill=(80, 170, 255, 255))
        d.point([29, 20], fill=(220, 240, 255, 255))
        d.rectangle([38, 15, 45, 24], fill=(236, 232, 220, 255))
        for y in (17, 19, 21):
            d.line([39, y, 44, y], fill=(150, 146, 140, 255))
        # Coins on the floor.
        for x, y in ((6, 56), (56, 57), (59, 55)):
            d.ellipse([x - 2, y - 1, x + 2, y + 1], fill=(246, 196, 64, 255))
    else:
        # Closed lid: a rounded top.
        d.rectangle([10, 22, 53, 31], fill=wood)
        d.pieslice([10, 12, 53, 34], 180, 360, fill=k(wood, 1.1))
        d.line([12, 23, 51, 23], fill=k(wood, 1.4))
        d.line([10, 31, 53, 31], fill=k(wood, 0.5))
    # Bands and corners.
    for x in (15, 47):
        d.rectangle([x - 2, 32 if state == "open" else 17, x + 1, 54], fill=band)
        d.line([x - 2, 32 if state == "open" else 17, x - 2, 54], fill=k(band, 1.3))
    d.rectangle([10, 32, 53, 34], fill=band)
    d.line([10, 32, 53, 32], fill=k(band, 1.3))
    # Lock plate.
    d.rectangle([28, 30, 35, 39], fill=k(band, 0.9))
    d.rectangle([31, 34, 32, 37], fill=INK)
    if state == "locked":
        d.arc([26, 35, 37, 46], 180, 360, fill=(150, 154, 166, 255), width=2)
        d.rectangle([26, 40, 37, 49], fill=(128, 132, 144, 255))
        d.line([26, 40, 37, 40], fill=(190, 194, 204, 255))
        d.rectangle([31, 43, 32, 46], fill=INK)
    if state == "ready":
        for x, y in ((8, 14), (55, 18), (50, 8), (14, 6)):
            d.line([x - 2, y, x + 2, y], fill=(255, 250, 210, 255))
            d.line([x, y - 2, x, y + 2], fill=(255, 250, 210, 255))
    im = outline(im)
    if state == "ready":
        # Glow behind it (added after the outline so it stays soft).
        glow = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        g = ImageDraw.Draw(glow)
        for r, a in ((31, 30), (28, 55), (25, 85), (22, 120)):
            g.ellipse([32 - r, 36 - r, 32 + r, 36 + r], fill=(255, 196, 60, a))
        glow.alpha_composite(im)
        im = glow
    return im.resize((128, 128), Image.NEAREST)


if __name__ == "__main__":
    for s in ("locked", "ready", "open"):
        chest(s).save(OUT / f"chest_{s}.png")
    prev = Image.new("RGBA", (400, 140), (30, 34, 50, 255))
    for i, s in enumerate(("locked", "ready", "open")):
        im = Image.open(OUT / f"chest_{s}.png")
        prev.paste(im, (6 + i * 132, 6), im)
    prev.save("/tmp/claude-0/chests.png")
