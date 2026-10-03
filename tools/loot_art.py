#!/usr/bin/env python3
"""Pixel art for the run economy, drawn in code at the character texel scale:
    python3 tools/loot_art.py
  assets/sprites/loot/xp_gem.png       green insight crystal (XP)
  assets/sprites/loot/xp_gem_big.png   the big one elites drop
  assets/sprites/props/shop_cart.png   the halfway vendor cart
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent / "assets/sprites"
INK = (14, 12, 18, 255)


def k(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (c[3] if len(c) > 3 else 255,)


def outline(im):
    a = im.load(); w, h = im.size
    out = im.copy(); o = out.load()
    for y in range(h):
        for x in range(w):
            if a[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and a[nx, ny][3] > 200:
                        o[x, y] = INK
                        break
    return out


def gem(size, col):
    im = Image.new("RGBA", (size, size + size // 3), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size // 2
    h = size + size // 3
    top, mid, bot = 1, h // 3, h - 2
    d.polygon([(c, top), (size - 2, mid), (c, bot), (1, mid)], fill=col)
    d.polygon([(c, top), (c, bot), (1, mid)], fill=k(col, 0.72))
    d.polygon([(c, top), (size - 2, mid), (c + size // 6, mid)], fill=k(col, 1.35))
    d.line([(c - size // 6, mid - 1), (c - 1, top + 3)], fill=(240, 255, 240, 255))
    d.point([(c + size // 5, mid + size // 4)], fill=(230, 255, 230, 255))
    return outline(im)


def cart():
    """A street vendor cart: striped umbrella, a hand-painted UPGRADES board,
    crates of gun parts, energy drinks, med flasks, a lantern."""
    W, H = 150, 150
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    wood = (124, 78, 44, 255)
    dark = (60, 44, 34, 255)
    # Umbrella pole + striped canopy.
    d.rectangle([73, 18, 76, 92], fill=(90, 92, 100, 255))
    for i in range(8):
        x0 = 8 + i * 17
        col = (196, 40, 46, 255) if i % 2 == 0 else (236, 228, 210, 255)
        d.polygon([(75, 6), (x0, 34), (x0 + 17, 34)], fill=col)
    d.line([(8, 34), (144, 34)], fill=k((196, 40, 46, 255), 0.6), width=2)
    for x in range(10, 142, 12):
        d.pieslice([x, 30, x + 12, 40], 0, 180, fill=(196, 40, 46, 255) if (x // 12) % 2 else (236, 228, 210, 255))
    # Counter body.
    d.rectangle([14, 86, 136, 126], fill=wood)
    for y in range(90, 126, 6):
        d.line([(14, y), (136, y)], fill=k(wood, 0.75))
    d.rectangle([10, 80, 140, 87], fill=k(wood, 1.25))
    # Sign board.
    d.rectangle([30, 96, 120, 116], fill=(24, 22, 30, 255))
    d.rectangle([30, 96, 120, 116], outline=(232, 182, 58, 255))
    # Pixel letters "UPGRADES" (5x7 font, hand-drawn bitmaps).
    font = {
        "U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
        "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
        "G": ["01111", "10000", "10000", "10011", "10001", "10001", "01111"],
        "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
        "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
        "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
        "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
        "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
    }
    x = 35
    for ch in "UPGRADES":
        for ry, row in enumerate(font[ch]):
            for rx, b in enumerate(row):
                if b == "1":
                    d.point([(x + rx, 102 + ry)], fill=(255, 220, 90, 255))
        x += 10
    # Goods on the counter: gun parts crate, drinks, flasks.
    d.rectangle([18, 64, 50, 80], fill=k(wood, 0.9))
    d.line([(18, 72), (50, 72)], fill=k(wood, 0.6))
    for gx in (22, 32, 42):
        d.rectangle([gx, 58, gx + 6, 64], fill=(80, 84, 94, 255))
    for i, cx in enumerate((58, 64, 70)):
        d.rectangle([cx, 66, cx + 4, 80], fill=[(60, 200, 240, 255), (250, 210, 40, 255), (230, 60, 200, 255)][i])
        d.point([(cx + 1, 68)], fill=(255, 255, 255, 255))
    for i, cx in enumerate((84, 96)):
        d.ellipse([cx, 66, cx + 9, 80], fill=(210, 40, 44, 255))
        d.rectangle([cx + 3, 61, cx + 6, 66], fill=(200, 200, 210, 255))
    d.rectangle([108, 60, 132, 80], fill=(38, 40, 46, 255))
    d.rectangle([110, 62, 130, 72], fill=(90, 200, 110, 255))
    # Lantern.
    d.line([(124, 34), (124, 44)], fill=INK)
    d.rectangle([120, 44, 128, 54], fill=(255, 200, 90, 255))
    # Wheels.
    for wx in (32, 118):
        d.ellipse([wx - 13, 114, wx + 13, 140], fill=dark)
        d.ellipse([wx - 6, 121, wx + 6, 133], fill=(120, 122, 130, 255))
        d.point([(wx, 127)], fill=INK)
    # Handles.
    d.line([(136, 96), (148, 90)], fill=dark, width=3)
    return outline(im)


def icon(name):
    """24x24 cart item icons, doubled."""
    im = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if name == "can":
        d.rectangle([7, 4, 16, 20], fill=(220, 40, 46, 255))
        d.rectangle([7, 9, 16, 14], fill=(240, 236, 226, 255))
        d.line([(8, 4), (15, 4)], fill=(200, 200, 210, 255))
        d.point([(9, 6)], fill=(255, 255, 255, 255))
    elif name == "lens":
        d.ellipse([3, 3, 15, 15], fill=(120, 220, 255, 255))
        d.ellipse([5, 5, 13, 13], fill=(190, 245, 255, 255))
        d.line([(14, 14), (20, 20)], fill=(120, 80, 50, 255), width=3)
        d.point([(7, 7)], fill=(255, 255, 255, 255))
    elif name == "magnet":
        d.arc([4, 3, 19, 18], 180, 360, fill=(210, 40, 46, 255), width=4)
        d.rectangle([4, 10, 7, 19], fill=(210, 40, 46, 255))
        d.rectangle([16, 10, 19, 19], fill=(210, 40, 46, 255))
        d.rectangle([4, 17, 7, 20], fill=(220, 220, 230, 255))
        d.rectangle([16, 17, 19, 20], fill=(220, 220, 230, 255))
    elif name == "med":
        d.rectangle([3, 6, 20, 19], fill=(236, 236, 230, 255))
        d.rectangle([9, 3, 14, 6], fill=(140, 140, 150, 255))
        d.rectangle([10, 8, 13, 17], fill=(210, 40, 46, 255))
        d.rectangle([7, 11, 16, 14], fill=(210, 40, 46, 255))
    elif name == "heart":
        d.polygon([(12, 20), (3, 10), (3, 6), (7, 3), (12, 7), (17, 3), (21, 6), (21, 10)], fill=(220, 30, 50, 255))
        d.point([(6, 6), (7, 6)], fill=(255, 190, 200, 255))
    elif name == "fist":
        d.rectangle([5, 6, 19, 18], fill=(222, 170, 130, 255))
        for x in (6, 10, 14):
            d.rectangle([x, 5, x + 3, 9], fill=(214, 190, 80, 255))
        d.line([(5, 12), (19, 12)], fill=(180, 130, 100, 255))
    elif name == "mag":
        d.polygon([(8, 3), (15, 3), (17, 20), (10, 20)], fill=(70, 74, 84, 255))
        for y in (5, 8, 11):
            d.rectangle([10, y, 13, y + 1], fill=(214, 170, 70, 255))
    elif name == "gun":
        d.rectangle([3, 7, 20, 11], fill=(90, 94, 104, 255))
        d.polygon([(5, 11), (10, 11), (9, 19), (4, 19)], fill=(70, 46, 34, 255))
        d.point([(18, 5), (19, 4), (20, 3)], fill=(240, 220, 120, 255))
    elif name == "syringe":
        d.line([(4, 20), (16, 8)], fill=(200, 230, 255, 255), width=4)
        d.line([(16, 8), (21, 3)], fill=(180, 180, 190, 255), width=1)
        d.line([(6, 18), (12, 12)], fill=(80, 255, 120, 255), width=2)
    return outline(im).resize((48, 48), Image.NEAREST)


if __name__ == "__main__":
    (ROOT / "loot/cart").mkdir(parents=True, exist_ok=True)
    for n in ("can", "lens", "magnet", "med", "heart", "fist", "mag", "gun", "syringe"):
        icon(n).save(ROOT / f"loot/cart/{n}.png")
    (ROOT / "loot").mkdir(parents=True, exist_ok=True)
    (ROOT / "props").mkdir(parents=True, exist_ok=True)
    gem(18, (60, 220, 110, 255)).resize((36, 48), Image.NEAREST).save(ROOT / "loot/xp_gem.png")
    gem(26, (90, 230, 255, 255)).resize((52, 68), Image.NEAREST).save(ROOT / "loot/xp_gem_big.png")
    c = cart()
    c.resize((c.width * 2, c.height * 2), Image.NEAREST).save(ROOT / "props/shop_cart.png")
    prev = Image.new("RGBA", (420, 320), (30, 34, 50, 255))
    for i, p in enumerate(["loot/xp_gem.png", "loot/xp_gem_big.png"]):
        im = Image.open(ROOT / p); prev.alpha_composite(im, (10 + i * 70, 10))
    im = Image.open(ROOT / "props/shop_cart.png"); prev.alpha_composite(im, (110, 10))
    prev.save("/tmp/claude-0/loot_prev.png")
