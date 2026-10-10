#!/usr/bin/env python3
"""Icons for the coping hour (abilities, traits, items), 32x32 drawn in
code then doubled:  python3 tools/survive_art.py -> assets/sprites/survive/*.png"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets/sprites/survive"
INK = (14, 12, 18, 255)
W = (240, 238, 228, 255); RED = (214, 44, 52, 255); GOLD = (238, 186, 60, 255)
BLUE = (90, 170, 250, 255); GREEN = (80, 210, 110, 255); GREY = (120, 124, 136, 255)
BROWN = (120, 76, 42, 255); PURPLE = (170, 90, 230, 255); ORANGE = (240, 140, 40, 255)


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


def draw(name, d):
    if name == "invoice":
        d.polygon([(8, 5), (22, 5), (25, 8), (25, 27), (8, 27)], fill=W)
        for y in (10, 14, 18):
            d.line([(11, y), (22, y)], fill=GREY)
        d.rectangle([17, 21, 23, 24], fill=RED)
    elif name == "stapler":
        d.rectangle([5, 18, 27, 22], fill=GREY)
        d.polygon([(5, 17), (24, 11), (27, 13), (27, 17)], fill=RED)
        for x in (24, 27, 30):
            d.line([(x - 2, 8), (x, 6)], fill=W)
    elif name == "coffee":
        d.ellipse([3, 20, 29, 29], fill=(70, 40, 20, 255))
        d.rectangle([10, 8, 21, 22], fill=W)
        d.arc([19, 11, 26, 18], 270, 90, fill=W, width=2)
        for x in (12, 16):
            d.line([(x, 6), (x + 1, 2)], fill=(220, 220, 220, 255))
    elif name == "clipboard":
        d.rectangle([8, 5, 24, 28], fill=BROWN)
        d.rectangle([10, 8, 22, 26], fill=W)
        d.rectangle([13, 3, 19, 7], fill=GREY)
        for y in (12, 16, 20):
            d.line([(12, y), (20, y)], fill=GREY)
    elif name == "bolt":
        d.polygon([(18, 2), (8, 17), (15, 17), (11, 30), (25, 12), (17, 12), (22, 2)], fill=(255, 230, 90, 255))
    elif name == "wave":
        for r, c in ((13, GOLD), (9, ORANGE), (5, RED)):
            d.arc([16 - r, 16 - r, 16 + r, 16 + r], 200, 340, fill=c, width=3)
        d.rectangle([6, 24, 26, 27], fill=BROWN)
    elif name == "note":
        d.ellipse([6, 20, 13, 26], fill=BLUE); d.ellipse([18, 17, 25, 23], fill=BLUE)
        d.line([(12, 22), (12, 6)], fill=BLUE, width=2); d.line([(24, 19), (24, 4)], fill=BLUE, width=2)
        d.line([(12, 6), (24, 4)], fill=BLUE, width=3)
    elif name == "mine":
        d.rectangle([7, 14, 25, 25], fill=RED)
        d.rectangle([10, 17, 15, 20], fill=GOLD)
        d.ellipse([20, 7, 25, 12], fill=(255, 80, 80, 255))
    elif name == "camera":
        d.rectangle([5, 10, 27, 25], fill=GREY)
        d.ellipse([11, 12, 21, 22], fill=(40, 40, 50, 255)); d.ellipse([14, 15, 18, 19], fill=BLUE)
        d.rectangle([20, 6, 26, 10], fill=W)
    elif name == "drip":
        d.rectangle([12, 3, 20, 14], fill=(200, 230, 250, 255))
        d.line([(16, 14), (16, 22)], fill=(200, 200, 210, 255))
        d.polygon([(16, 22), (12, 28), (20, 28)], fill=BLUE)
        d.arc([4, 18, 28, 30], 0, 360, fill=(120, 200, 255, 255))
    # traits
    elif name == "t_dmg":
        d.polygon([(16, 3), (20, 12), (29, 13), (22, 19), (24, 28), (16, 23), (8, 28), (10, 19), (3, 13), (12, 12)], fill=RED)
    elif name == "t_area":
        d.ellipse([4, 4, 28, 28], outline=GREEN, width=3); d.ellipse([12, 12, 20, 20], fill=GREEN)
    elif name == "t_cd":
        d.ellipse([5, 5, 27, 27], fill=W); d.line([(16, 16), (16, 8)], fill=INK, width=2); d.line([(16, 16), (22, 18)], fill=INK, width=2)
    elif name == "t_proj":
        for x in (8, 16, 24):
            d.polygon([(x, 6), (x + 3, 14), (x - 3, 14)], fill=GOLD); d.line([(x, 14), (x, 26)], fill=BROWN, width=2)
    elif name == "t_speed":
        d.polygon([(6, 20), (18, 8), (18, 14), (27, 14), (27, 20)], fill=BLUE)
        for y in (10, 16, 22):
            d.line([(2, y), (8, y)], fill=W)
    elif name == "t_hp":
        d.polygon([(16, 27), (4, 14), (4, 8), (9, 4), (16, 9), (23, 4), (28, 8), (28, 14)], fill=RED)
        d.rectangle([14, 10, 18, 20], fill=W); d.rectangle([11, 13, 21, 17], fill=W)
    elif name == "t_regen":
        d.polygon([(16, 27), (4, 14), (4, 8), (9, 4), (16, 9), (23, 4), (28, 8), (28, 14)], fill=GREEN)
    elif name == "t_armor":
        d.polygon([(16, 3), (27, 7), (25, 20), (16, 29), (7, 20), (5, 7)], fill=GREY)
        d.polygon([(16, 7), (23, 10), (21, 19), (16, 24)], fill=W)
    elif name == "t_pickup":
        d.arc([5, 4, 27, 26], 180, 360, fill=RED, width=5)
        d.rectangle([5, 14, 10, 26], fill=RED); d.rectangle([22, 14, 27, 26], fill=RED)
        d.rectangle([5, 23, 10, 27], fill=W); d.rectangle([22, 23, 27, 27], fill=W)
    elif name == "t_crit":
        d.polygon([(16, 2), (19, 13), (30, 16), (19, 19), (16, 30), (13, 19), (2, 16), (13, 13)], fill=GOLD)
    elif name == "t_xp":
        d.polygon([(16, 3), (26, 14), (16, 29), (6, 14)], fill=GREEN); d.polygon([(16, 3), (16, 29), (6, 14)], fill=(50, 160, 80, 255))
    # items
    elif name == "i_coin":
        d.ellipse([5, 5, 27, 27], fill=GOLD); d.ellipse([9, 9, 23, 23], outline=(180, 130, 30, 255), width=2)
        d.line([(16, 11), (16, 21)], fill=(180, 130, 30, 255), width=2)
    elif name == "i_card":
        d.rectangle([4, 9, 28, 24], fill=BLUE); d.rectangle([6, 13, 14, 19], fill=W); d.line([(16, 20), (26, 20)], fill=W)
    elif name == "i_ticket":
        d.rectangle([5, 7, 27, 25], fill=(250, 220, 90, 255)); d.line([(8, 12), (24, 12)], fill=INK); d.line([(8, 16), (20, 16)], fill=INK)
        d.text((9, 17), "$", fill=RED)
    elif name == "i_amulet":
        d.arc([8, 2, 24, 16], 180, 360, fill=GOLD, width=2); d.ellipse([9, 13, 23, 27], fill=PURPLE); d.ellipse([13, 17, 17, 21], fill=W)
    elif name == "i_bell":
        d.pieslice([6, 6, 26, 30], 180, 360, fill=GOLD); d.rectangle([6, 17, 26, 20], fill=GOLD); d.ellipse([14, 20, 18, 24], fill=GREY)
    elif name == "i_thermos":
        d.rectangle([10, 6, 22, 28], fill=(70, 150, 120, 255)); d.rectangle([9, 3, 23, 7], fill=GREY); d.rectangle([12, 12, 20, 16], fill=W)
    elif name == "i_shirt":
        d.polygon([(6, 8), (12, 4), (20, 4), (26, 8), (24, 14), (21, 12), (21, 28), (11, 28), (11, 12), (8, 14)], fill=(255, 90, 160, 255))
        for p in ((14, 14), (18, 20), (13, 24)):
            d.ellipse([p[0], p[1], p[0] + 3, p[1] + 3], fill=GOLD)
    elif name == "i_tooth":
        d.polygon([(8, 6), (24, 6), (24, 16), (20, 28), (17, 18), (15, 18), (12, 28), (8, 16)], fill=GOLD)
    elif name == "i_glove":
        d.rectangle([9, 12, 23, 27], fill=RED)
        for x in (9, 13, 17, 21):
            d.rectangle([x, 5, x + 2, 13], fill=RED)
    elif name == "i_mug":
        d.rectangle([8, 8, 22, 27], fill=W); d.arc([18, 12, 28, 22], 270, 90, fill=W, width=3); d.text((10, 11), "#1", fill=RED)
    elif name == "i_hands":
        for ox in (0, 9):
            d.rectangle([5 + ox, 13, 13 + ox, 26], fill=(222, 170, 130, 255))
            for k in range(3):
                d.rectangle([5 + ox + k * 3, 7, 6 + ox + k * 3, 13], fill=(222, 170, 130, 255))
    elif name == "i_receipt":
        d.polygon([(9, 2), (23, 2), (23, 28), (20, 26), (17, 28), (14, 26), (11, 28), (9, 26)], fill=W)
        for y in (7, 11, 15, 19):
            d.line([(11, y), (21, y)], fill=GREY)
        d.line([(11, 22), (21, 22)], fill=RED, width=2)


NAMES = ["invoice", "stapler", "coffee", "clipboard", "bolt", "wave", "note", "mine", "camera", "drip",
         "t_dmg", "t_area", "t_cd", "t_proj", "t_speed", "t_hp", "t_regen", "t_armor", "t_pickup", "t_crit", "t_xp",
         "i_coin", "i_card", "i_ticket", "i_amulet", "i_bell", "i_thermos", "i_shirt", "i_tooth", "i_glove", "i_mug", "i_hands", "i_receipt"]

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (11 * 68, 3 * 68), (30, 34, 50, 255))
    for i, n in enumerate(NAMES):
        im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        draw(n, ImageDraw.Draw(im))
        im = outline(im).resize((64, 64), Image.NEAREST)
        im.save(OUT / f"{n}.png")
        sheet.alpha_composite(im, ((i % 11) * 68 + 2, (i // 11) * 68 + 2))
    sheet.save("/tmp/claude-0/survive_icons.png")
