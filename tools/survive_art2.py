#!/usr/bin/env python3
"""Icons for the SURVIVOR DECK auto weapons and the ACTIVE SKILLS (same
32x32-then-doubled style as tools/survive_art.py):
    python3 tools/survive_art2.py -> assets/sprites/survive/*.png"""
from PIL import Image, ImageDraw
import survive_art as sa

INK, W, RED, GOLD, BLUE, GREEN, GREY, BROWN, PURPLE, ORANGE = (sa.INK, sa.W, sa.RED, sa.GOLD, sa.BLUE, sa.GREEN,
                                                               sa.GREY, sa.BROWN, sa.PURPLE, sa.ORANGE)
SKIN = (222, 170, 130, 255)
DARK = (40, 44, 58, 255)


def draw(name, d):
    if name == "pigeon":
        d.ellipse([7, 12, 24, 24], fill=GREY)
        d.ellipse([18, 7, 27, 16], fill=GREY)
        d.polygon([(27, 11), (31, 12), (27, 13)], fill=ORANGE)
        d.point((24, 10), fill=INK)
        d.polygon([(9, 15), (2, 9), (13, 14)], fill=(160, 164, 176, 255))
        d.line([(13, 24), (12, 29)], fill=ORANGE); d.line([(18, 24), (19, 29)], fill=ORANGE)
    elif name == "vending":
        d.rectangle([7, 3, 25, 29], fill=RED)
        d.rectangle([10, 6, 19, 20], fill=(40, 60, 90, 255))
        for y in (8, 12, 16):
            d.rectangle([11, y, 18, y + 2], fill=GOLD)
        d.rectangle([21, 7, 23, 15], fill=W)
        d.rectangle([10, 23, 22, 26], fill=DARK)
    elif name == "blower":
        d.rectangle([4, 12, 14, 22], fill=ORANGE)
        d.polygon([(14, 14), (29, 11), (29, 23), (14, 20)], fill=GREY)
        d.line([(6, 22), (6, 27)], fill=DARK, width=2)
        for y in (9, 17, 25):
            d.line([(24, y), (30, y - 2)], fill=W)
    elif name == "taser":
        d.rectangle([4, 14, 16, 22], fill=(250, 210, 40, 255))
        d.rectangle([6, 22, 10, 28], fill=DARK)
        d.line([(16, 16), (22, 12), (19, 18), (28, 14)], fill=BLUE, width=2)
        d.line([(16, 20), (23, 24), (20, 19), (29, 23)], fill=BLUE, width=2)
    elif name == "roomba":
        d.ellipse([3, 9, 29, 27], fill=DARK)
        d.ellipse([5, 9, 27, 23], fill=GREY)
        d.ellipse([13, 13, 19, 18], fill=GREEN)
        for x in (4, 26):
            d.line([(x, 25), (x + (3 if x < 10 else -3), 29)], fill=W)
    elif name == "spray":
        d.rectangle([10, 9, 20, 29], fill=PURPLE)
        d.rectangle([12, 5, 18, 9], fill=GREY)
        d.rectangle([14, 2, 17, 5], fill=W)
        for (x, y) in ((22, 3), (25, 6), (27, 2), (24, 9), (29, 7)):
            d.point((x, y), fill=GREEN); d.point((x + 1, y), fill=GREEN)
        d.line([(12, 18), (18, 18)], fill=W)
    # ---- actives ----
    elif name == "a_frag":
        d.ellipse([7, 10, 25, 29], fill=(80, 110, 60, 255))
        for y in (15, 20, 25):
            d.line([(9, y), (23, y)], fill=(50, 70, 40, 255))
        d.rectangle([13, 5, 19, 10], fill=GREY)
        d.arc([17, 1, 27, 11], 180, 360, fill=GOLD, width=2)
    elif name == "a_turret":
        d.rectangle([9, 22, 23, 28], fill=DARK)
        d.line([(16, 22), (8, 29)], fill=GREY, width=2); d.line([(16, 22), (24, 29)], fill=GREY, width=2)
        d.rectangle([9, 12, 21, 21], fill=GREY)
        d.rectangle([21, 15, 30, 18], fill=DARK)
        d.ellipse([12, 14, 16, 18], fill=RED)
    elif name == "a_stomp":
        d.polygon([(8, 4), (20, 4), (20, 18), (26, 20), (26, 25), (8, 25)], fill=BROWN)
        d.rectangle([8, 25, 26, 27], fill=DARK)
        for x in (2, 29):
            d.line([(x, 20), (x + (3 if x < 10 else -3), 26)], fill=GOLD, width=2)
        d.arc([2, 24, 30, 31], 180, 360, fill=GOLD)
    elif name == "a_adrenaline":
        d.rectangle([13, 4, 19, 22], fill=W)
        d.rectangle([14, 8, 18, 20], fill=RED)
        d.rectangle([11, 3, 21, 5], fill=GREY)
        d.line([(16, 22), (16, 30)], fill=GREY)
        d.line([(4, 14), (8, 14), (10, 9), (12, 18)], fill=GOLD, width=1)
        d.line([(20, 18), (23, 10), (25, 16), (29, 16)], fill=GOLD, width=1)
    elif name == "a_decoy":
        d.rectangle([9, 9, 23, 26], fill=(196, 160, 108, 255))
        d.ellipse([11, 2, 21, 12], fill=(196, 160, 108, 255))
        d.point((14, 6), fill=INK); d.point((18, 6), fill=INK)
        d.line([(13, 9), (19, 9)], fill=INK)
        d.line([(16, 26), (16, 30)], fill=BROWN, width=2)
        d.text((12, 14), "?", fill=RED)
    elif name == "a_molotov":
        d.rectangle([12, 13, 20, 29], fill=(90, 160, 70, 255))
        d.rectangle([14, 8, 18, 13], fill=(90, 160, 70, 255))
        d.rectangle([14, 5, 18, 8], fill=W)
        d.polygon([(16, 0), (21, 5), (16, 7), (11, 5)], fill=ORANGE)
        d.polygon([(16, 2), (18, 5), (14, 5)], fill=GOLD)
    elif name == "a_medkit":
        d.rectangle([4, 9, 28, 27], fill=W)
        d.rectangle([12, 5, 20, 9], fill=GREY)
        d.rectangle([14, 12, 18, 24], fill=RED)
        d.rectangle([10, 16, 22, 20], fill=RED)
    elif name == "a_charge":
        d.ellipse([12, 6, 22, 16], fill=SKIN)
        d.polygon([(10, 16), (24, 16), (26, 27), (8, 27)], fill=DARK)
        for y in (9, 15, 21):
            d.line([(1, y), (8, y)], fill=W)
        d.polygon([(24, 12), (31, 17), (24, 22)], fill=GOLD)
    elif name == "deck_pack":
        d.rectangle([5, 6, 23, 28], fill=(60, 140, 90, 255))
        d.rectangle([9, 3, 27, 25], fill=(80, 200, 120, 255))
        d.rectangle([12, 7, 24, 21], fill=DARK)
        d.text((14, 8), "S", fill=GOLD)


NAMES = ["pigeon", "vending", "blower", "taser", "roomba", "spray",
         "a_frag", "a_turret", "a_stomp", "a_adrenaline", "a_decoy", "a_molotov", "a_medkit", "a_charge", "deck_pack"]

if __name__ == "__main__":
    sheet = Image.new("RGBA", (8 * 68, 2 * 68), (30, 34, 50, 255))
    for i, n in enumerate(NAMES):
        im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        draw(n, ImageDraw.Draw(im))
        im = sa.outline(im).resize((64, 64), Image.NEAREST)
        im.save(sa.OUT / f"{n}.png")
        sheet.alpha_composite(im, ((i % 8) * 68 + 2, (i // 8) * 68 + 2))
    sheet.save("/tmp/claude-0/pol/survive_icons2.png")
