#!/usr/bin/env python3
"""Pixel icons for the melee mods (32x32, dark outline like the icon pack)."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[2] / "assets/sprites/icons"
INK = (26, 22, 38, 255)
S1, S2, S3, S4 = (232, 234, 240, 255), (176, 180, 192, 255), (122, 126, 142, 255), (82, 84, 100, 255)


def outline(im):
    px = im.load()
    w, h = im.size
    o = im.copy()
    op = o.load()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] > 0 and px[nx, ny] != INK:
                        op[x, y] = INK
                        break
    return o


def nail(d, x0, y0, x1, y1):
    d.line((x0, y0, x1, y1), fill=S3, width=2)
    d.line((x0, y0 - 1, x1, y1 - 1), fill=S1, width=1)
    d.ellipse((x0 - 3, y0 - 3, x0 + 2, y0 + 2), fill=S2)
    d.point((x0 - 1, y0 - 2), fill=S1)


def nails():
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    # A bat end with nails driven through, one drop of blood.
    d.rounded_rectangle((3, 12, 28, 21), 4, fill=(150, 98, 52, 255))
    d.line((5, 13, 26, 13), fill=(196, 140, 82, 255))
    d.line((5, 20, 26, 20), fill=(104, 64, 34, 255))
    for x, up in ((8, True), (14, False), (20, True), (25, False)):
        if up:
            d.line((x, 4, x, 13), fill=S3)
            d.line((x - 1, 5, x - 1, 13), fill=S1)
            d.line((x - 2, 13, x + 1, 13), fill=S4)
        else:
            d.line((x, 20, x, 29), fill=S3)
            d.line((x - 1, 20, x - 1, 28), fill=S1)
            d.line((x - 2, 20, x + 1, 20), fill=S4)
    d.ellipse((22, 2, 26, 7), fill=(210, 30, 40, 255))
    d.point((23, 3), fill=(255, 120, 120, 255))
    return im


def tape():
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    d.ellipse((3, 4, 25, 26), fill=(70, 72, 84, 255))
    d.ellipse((5, 6, 23, 24), fill=(104, 108, 124, 255))
    d.arc((5, 6, 23, 24), 200, 300, fill=(150, 154, 170, 255))
    d.ellipse((10, 11, 18, 19), fill=(0, 0, 0, 0))
    d.ellipse((9, 10, 19, 20), outline=(210, 190, 140, 255))
    # The tail of tape peeling off to the right.
    d.polygon([(20, 22), (30, 26), (29, 30), (17, 25)], fill=(120, 124, 140, 255))
    d.line((20, 22, 30, 26), fill=(170, 174, 190, 255))
    return im


def weighted():
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    d.arc((9, 2, 23, 16), 180, 360, fill=S3, width=3)
    d.polygon([(7, 12), (25, 12), (29, 29), (3, 29)], fill=(64, 66, 80, 255))
    d.polygon([(8, 13), (13, 13), (10, 28), (5, 28)], fill=(96, 100, 118, 255))
    d.line((7, 12, 25, 12), fill=(130, 134, 150, 255))
    d.text((12, 17), "LB", fill=(220, 190, 90, 255))
    return im


def serrated():
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    d.polygon([(2, 9), (26, 9), (30, 13), (30, 19), (2, 19)], fill=S2)
    d.line((2, 10, 27, 10), fill=S1)
    for x in range(3, 30, 4):
        d.polygon([(x, 19), (x + 4, 19), (x + 1, 25)], fill=S3)
        d.point((x + 1, 20), fill=S1)
    d.rectangle((2, 12, 7, 17), fill=(120, 70, 40, 255))
    return im


def live_wire():
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    for i in range(5):
        x = 4 + i * 5
        d.ellipse((x, 9, x + 7, 23), outline=(200, 110, 50, 255), width=2)
        d.arc((x, 9, x + 7, 23), 250, 320, fill=(255, 190, 120, 255))
    d.polygon([(17, 1), (11, 15), (16, 15), (12, 30), (22, 12), (17, 12), (21, 1)], fill=(255, 226, 60, 255))
    d.line((17, 2, 13, 13), fill=(255, 250, 200, 255))
    return im


if __name__ == "__main__":
    for name, fn in (("nails", nails), ("tape_grip", tape), ("weighted", weighted), ("serrated", serrated), ("live_wire", live_wire)):
        outline(fn()).save(OUT / f"mod_{name}.png")
        print("mod_" + name)
