#!/usr/bin/env python3
"""Pixel sprites for props that were drawn with plain shapes: quest items,
the City Hall filing cabinet / crate, and the Rail Bridge freight train."""
import random
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ICONS = ROOT / "assets/sprites/icons"
PROPS = ROOT / "assets/sprites/props"
INK = (24, 20, 34, 255)


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


def grime(im, amount=0.08, seed=1):
    r = random.Random(seed)
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] > 0 and c != INK:
                k = 1.0 + r.uniform(-amount, amount)
                px[x, y] = (min(255, int(c[0] * k)), min(255, int(c[1] * k)), min(255, int(c[2] * k)), c[3])
    return im


def quest():
    out = {}
    im = Image.new("RGBA", (24, 24)); d = ImageDraw.Draw(im)
    d.ellipse((3, 5, 20, 19), outline=(200, 36, 48, 255), width=3)
    d.arc((3, 5, 20, 19), 200, 290, fill=(255, 110, 110, 255))
    d.rectangle((10, 17, 13, 18), fill=(130, 130, 140, 255))
    d.ellipse((8, 18, 15, 23), fill=(240, 200, 70, 255)); d.point((10, 19), fill=(255, 250, 200, 255))
    out["quest_collar"] = im
    im = Image.new("RGBA", (24, 24)); d = ImageDraw.Draw(im)
    d.ellipse((5, 9, 18, 22), outline=(240, 200, 70, 255), width=3)
    d.arc((5, 9, 18, 22), 190, 260, fill=(255, 245, 190, 255))
    d.polygon([(8, 8), (11, 3), (15, 8), (11, 11)], fill=(150, 230, 255, 255))
    d.point((11, 5), fill=(255, 255, 255, 255))
    out["quest_ring"] = im
    im = Image.new("RGBA", (24, 24)); d = ImageDraw.Draw(im)
    d.rectangle((2, 6, 21, 19), fill=(242, 236, 214, 255))
    d.line((2, 6, 11, 13, 21, 6), fill=(170, 160, 140, 255))
    d.line((2, 19, 9, 12), fill=(200, 192, 172, 255)); d.line((21, 19, 14, 12), fill=(200, 192, 172, 255))
    d.ellipse((9, 11, 14, 16), fill=(200, 30, 36, 255)); d.point((10, 12), fill=(255, 120, 120, 255))
    out["quest_letter"] = im
    im = Image.new("RGBA", (24, 24)); d = ImageDraw.Draw(im)
    d.polygon([(3, 7), (20, 5), (21, 17), (4, 19)], fill=(246, 240, 220, 255))
    d.line((6, 10, 17, 9), fill=(120, 120, 136, 255)); d.line((6, 13, 15, 12), fill=(120, 120, 136, 255))
    d.rectangle((14, 14, 18, 16), fill=(220, 60, 60, 255))
    out["quest_ticket"] = im
    im = Image.new("RGBA", (24, 24)); d = ImageDraw.Draw(im)
    d.rounded_rectangle((3, 7, 20, 18), 2, fill=(120, 74, 40, 255))
    d.line((3, 12, 20, 12), fill=(84, 50, 26, 255)); d.line((4, 8, 19, 8), fill=(160, 104, 60, 255))
    d.rectangle((14, 9, 18, 11), fill=(110, 190, 255, 255))
    d.rectangle((5, 5, 12, 7), fill=(110, 200, 110, 255))
    out["quest_wallet"] = im
    for k, v in out.items():
        outline(v).save(ICONS / f"{k}.png")


def cabinet():
    im = Image.new("RGBA", (56, 94)); d = ImageDraw.Draw(im)
    d.rectangle((2, 2, 53, 91), fill=(112, 124, 112, 255))
    d.rectangle((2, 2, 53, 5), fill=(170, 182, 168, 255))
    d.rectangle((48, 2, 53, 91), fill=(84, 94, 84, 255))
    for k in range(3):
        y = 10 + k * 27
        d.rectangle((7, y, 45, y + 22), fill=(96, 108, 96, 255))
        d.line((7, y, 45, y), fill=(140, 152, 138, 255))
        d.line((7, y + 22, 45, y + 22), fill=(62, 70, 62, 255))
        d.rectangle((19, y + 8, 33, y + 11), fill=(210, 212, 200, 255))
        d.rectangle((22, y + 3, 30, y + 6), fill=(236, 232, 210, 255))
    # A dent and a paper sticking out of the top drawer.
    d.polygon([(30, 9), (40, 2), (44, 8), (34, 13)], fill=(246, 244, 232, 255))
    d.ellipse((10, 70, 18, 76), fill=(86, 98, 86, 255))
    outline(grime(im, 0.07, 3)).save(PROPS / "cabinet.png")
    im = Image.new("RGBA", (80, 72)); d = ImageDraw.Draw(im)
    d.rectangle((2, 2, 77, 69), fill=(150, 100, 52, 255))
    for x in range(2, 78, 15):
        d.line((x, 2, x, 69), fill=(118, 76, 38, 255))
    d.rectangle((2, 2, 77, 9), fill=(176, 122, 66, 255)); d.rectangle((2, 62, 77, 69), fill=(110, 70, 34, 255))
    d.line((6, 12, 73, 59), fill=(96, 60, 28, 255), width=5); d.line((73, 12, 6, 59), fill=(96, 60, 28, 255), width=5)
    d.text((26, 28), "FILE", fill=(40, 24, 12, 255))
    outline(grime(im, 0.09, 4)).save(PROPS / "crate.png")


def car(kind, seed):
    W, H = 260, 128
    im = Image.new("RGBA", (W, H)); d = ImageDraw.Draw(im)
    r = random.Random(seed)
    body = {"loco": (176, 136, 36), "rust": (110, 56, 34), "blue": (46, 62, 80), "grey": (70, 70, 66)}[kind]
    hi = tuple(min(255, c + 44) for c in body) + (255,)
    lo = tuple(max(0, c - 40) for c in body) + (255,)
    b = body + (255,)
    top = 18 if kind != "loco" else 30
    d.rectangle((8, top, W - 9, H - 26), fill=b)
    d.rectangle((8, top, W - 9, top + 6), fill=hi)
    d.rectangle((8, H - 34, W - 9, H - 26), fill=lo)
    if kind == "loco":
        d.rectangle((150, 6, W - 16, top), fill=b)
        d.rectangle((150, 6, W - 16, 10), fill=hi)
        for wx in (162, 196, 226):
            d.rectangle((wx, 14, wx + 20, 26), fill=(255, 230, 150, 255))
        d.rectangle((22, top + 18, 140, top + 26), fill=(30, 30, 30, 255))
        for k in range(6):
            d.rectangle((24 + k * 20, top + 34, 34 + k * 20, H - 40), fill=lo)
        d.rectangle((30, top - 14, 44, top), fill=(50, 50, 52, 255))
        d.text((60, top + 44), "RAVEN FREIGHT", fill=(40, 30, 10, 255))
    else:
        for k in range(10):
            x = 20 + k * 23
            d.line((x, top + 8, x, H - 36), fill=lo, width=2)
        d.rectangle((100, top + 10, 160, H - 36), outline=lo, width=3)
        d.line((130, top + 10, 130, H - 36), fill=lo, width=2)
        if kind != "grey":
            # Graffiti tag.
            cols = [(230, 80, 160, 255), (90, 220, 255, 255), (250, 210, 60, 255)]
            c = cols[seed % 3]
            pts = [(30 + i * 10, 70 + r.randint(-12, 12)) for i in range(7)]
            d.line(pts, fill=c, width=5)
            d.line([(p[0], p[1] - 3) for p in pts], fill=(255, 255, 255, 140), width=1)
    # Rust streaks.
    for _ in range(18):
        x = r.randint(12, W - 14)
        d.line((x, top + 8, x + r.randint(-2, 2), top + 8 + r.randint(10, 40)), fill=(140, 70, 30, 120))
    # Under-frame and couplers; wheels are drawn by the game.
    d.rectangle((14, H - 26, W - 15, H - 20), fill=(30, 28, 28, 255))
    d.rectangle((0, H - 40, 8, H - 34), fill=(24, 24, 24, 255)); d.rectangle((W - 8, H - 40, W - 1, H - 34), fill=(24, 24, 24, 255))
    outline(grime(im, 0.06, seed)).save(PROPS / f"train_{kind}.png")


if __name__ == "__main__":
    quest()
    cabinet()
    for i, k in enumerate(("loco", "rust", "blue", "grey")):
        car(k, 11 + i)
    print("ok")
