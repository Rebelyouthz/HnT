#!/usr/bin/env python3
"""Pixel-art firearms, side view, muzzle to the right, at the character
texel scale (4.5 texels per world unit). Drawn by hand in code so every gun
reads at a glance in the hand and on the floor:

    python3 tools/gun_art.py   ->  assets/sprites/guns/<id>.png + guns.json

guns.json stores per gun the grip point (where the hand holds it) and the
muzzle point, in texels from the top-left, for GunHold and the projectiles.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets/sprites/guns"
INK = (14, 12, 16, 255)


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)


class Pen:
    def __init__(self, w, h):
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def box(self, x0, y0, x1, y1, c, light=True):
        """Filled block with a lit top edge and a dark bottom edge."""
        self.d.rectangle([x0, y0, x1, y1], fill=c)
        if light and y1 - y0 >= 2:
            self.d.line([x0, y0, x1, y0], fill=shade(c, 1.45))
            self.d.line([x0, y1, x1, y1], fill=shade(c, 0.6))

    def poly(self, pts, c):
        self.d.polygon(pts, fill=c)

    def px(self, x, y, c):
        self.d.point([x, y], fill=c)

    def outline(self):
        """One-texel dark outline around everything drawn (the sprite style)."""
        src = self.im.copy()
        a = src.load()
        w, h = src.size
        out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        o = out.load()
        for y in range(h):
            for x in range(w):
                if a[x, y][3] > 0:
                    o[x, y] = a[x, y]
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and a[nx, ny][3] > 0:
                        o[x, y] = INK
                        break
        self.im = out


STEEL = (88, 92, 102, 255)
DARK = (44, 46, 54, 255)
GRIP = (52, 34, 26, 255)


def pistol():
    p = Pen(30, 18)
    p.box(4, 3, 27, 7, STEEL)                      # slide
    for x in range(17, 25, 2):                      # serrations
        p.d.line([x, 4, x, 6], fill=shade(STEEL, 0.7))
    p.box(5, 8, 22, 9, DARK)                        # frame
    p.poly([(6, 9), (12, 9), (10, 17), (4, 17)], GRIP)   # grip
    for y in range(11, 16, 2):
        p.d.line([6, y, 9, y], fill=shade(GRIP, 1.4))
    p.d.arc([10, 8, 16, 14], 0, 180, fill=DARK)     # trigger guard
    p.px(12, 11, (180, 40, 50, 255))                # trigger
    p.box(27, 4, 28, 6, DARK, False)                # muzzle
    p.px(26, 2, STEEL)                              # front sight
    p.px(6, 2, STEEL)
    p.outline()
    return p.im, {"grip": [8, 12], "muzzle": [29, 5]}


def nailgun():
    p = Pen(38, 24)
    yel = (226, 176, 36, 255)
    p.box(4, 4, 30, 11, yel)                        # body
    p.box(30, 6, 35, 9, DARK)                       # nose
    p.box(33, 5, 34, 10, (120, 124, 130, 255), False)
    p.box(8, 12, 26, 14, DARK)                      # magazine strip
    for x in range(9, 26, 2):
        p.px(x, 13, (170, 170, 176, 255))           # nails in the strip
    p.poly([(8, 11), (14, 11), (12, 22), (6, 22)], (40, 40, 44, 255))  # grip
    p.box(4, 5, 7, 10, (200, 60, 40, 255))          # hose fitting
    p.d.line([10, 6, 26, 6], fill=shade(yel, 1.3))
    p.d.text((14, 5), "", fill=INK)
    p.outline()
    return p.im, {"grip": [10, 15], "muzzle": [36, 8]}


def shotgun():
    p = Pen(76, 20)
    wood = (120, 72, 38, 255)
    p.poly([(2, 6), (20, 5), (22, 11), (14, 15), (2, 15)], wood)   # stock
    p.d.line([3, 7, 19, 6], fill=shade(wood, 1.4))
    p.box(20, 5, 36, 10, DARK)                      # receiver
    p.box(36, 5, 73, 7, STEEL)                      # barrel
    p.box(36, 8, 66, 10, shade(STEEL, 0.8))         # magazine tube
    p.box(44, 8, 58, 11, wood)                      # pump
    for x in range(46, 57, 2):
        p.d.line([x, 9, x, 10], fill=shade(wood, 0.6))
    p.d.arc([24, 9, 30, 15], 0, 180, fill=DARK)
    p.px(26, 12, (180, 40, 50, 255))
    p.px(72, 4, STEEL)
    p.box(73, 5, 74, 7, INK, False)
    p.outline()
    return p.im, {"grip": [24, 12], "muzzle": [75, 6]}


def smg():
    p = Pen(44, 24)
    p.box(8, 5, 34, 10, DARK)                       # receiver
    p.box(34, 6, 41, 8, STEEL)                      # barrel + shroud
    for x in range(35, 41, 2):
        p.px(x, 7, INK)
    p.poly([(1, 6), (8, 6), (8, 9), (1, 10)], shade(DARK, 0.8))   # folded stock
    p.poly([(12, 10), (17, 10), (15, 20), (11, 20)], (38, 38, 42, 255))  # grip
    p.box(20, 11, 23, 22, (64, 66, 72, 255))        # long magazine
    p.d.line([21, 12, 21, 21], fill=shade(STEEL, 1.2))
    p.d.arc([15, 9, 20, 14], 0, 180, fill=INK)
    p.px(17, 11, (180, 40, 50, 255))
    p.d.line([10, 6, 33, 6], fill=shade(DARK, 1.6))
    p.box(14, 3, 18, 4, DARK)                       # rear sight
    p.box(42, 6, 43, 8, INK, False)
    p.outline()
    return p.im, {"grip": [13, 14], "muzzle": [43, 7]}


def ray():
    """FINAL NOTICE: a debt-office ray gun. Brass, a red ink chamber that
    glows, a dish emitter, a little receipt printer on top."""
    p = Pen(48, 28)
    brass = (196, 150, 64, 255)
    p.poly([(6, 8), (30, 6), (32, 14), (8, 15)], brass)               # body
    p.d.line([7, 9, 29, 7], fill=shade(brass, 1.4))
    p.d.ellipse([14, 6, 26, 15], fill=(150, 18, 28, 255))           # ink chamber
    p.d.ellipse([16, 8, 22, 12], fill=(255, 70, 70, 255))
    p.px(18, 9, (255, 220, 220, 255))
    p.box(30, 8, 38, 12, shade(brass, 0.8))                          # neck
    for i, r in enumerate((5, 4, 3)):                                 # emitter rings
        x = 39 + i * 3
        p.d.ellipse([x - 1, 10 - r, x + 1, 10 + r], outline=shade(brass, 1.2 - i * 0.15))
    p.poly([(10, 15), (16, 15), (13, 26), (7, 26)], (60, 30, 30, 255))  # grip
    p.box(10, 2, 20, 5, (220, 220, 210, 255))                        # receipt printer
    p.d.line([12, 0, 12, 2], fill=(240, 240, 232, 255))
    p.d.line([14, 1, 14, 2], fill=(240, 240, 232, 255))
    p.outline()
    return p.im, {"grip": [11, 18], "muzzle": [46, 10]}


def revolver():
    """BIG IRON: a long-barrel six-shooter, nickel and walnut."""
    p = Pen(36, 18)
    nickel = (150, 156, 168, 255)
    p.box(16, 4, 34, 6, nickel)                     # barrel
    p.box(16, 7, 30, 7, shade(nickel, 0.7), False)  # ejector rod
    p.d.ellipse([9, 3, 17, 10], fill=shade(nickel, 0.85))   # cylinder
    for x in (11, 13, 15):
        p.d.line([x, 4, x, 9], fill=shade(nickel, 0.6))
    p.box(6, 3, 10, 9, nickel)                      # frame
    p.px(6, 1, DARK)                                # hammer
    p.px(7, 2, DARK)
    p.poly([(5, 9), (10, 9), (8, 17), (2, 17), (3, 13)], (98, 56, 30, 255))   # grip
    p.d.line([4, 12, 7, 11], fill=(140, 90, 52, 255))
    p.d.arc([9, 8, 15, 14], 0, 180, fill=DARK)
    p.px(11, 11, (180, 40, 50, 255))
    p.px(33, 3, nickel)
    p.box(34, 4, 35, 6, INK, False)
    p.outline()
    return p.im, {"grip": [7, 12], "muzzle": [35, 5]}


def flare():
    """FLARE GUN: orange plastic, fat barrel, a red cartridge rim."""
    p = Pen(32, 20)
    orange = (238, 112, 28, 255)
    p.box(6, 4, 28, 10, orange)                     # fat barrel
    p.d.line([7, 5, 27, 5], fill=shade(orange, 1.35))
    p.box(4, 5, 7, 9, (200, 40, 36, 255))           # breech / cartridge rim
    p.box(28, 5, 30, 9, shade(orange, 0.7), False)
    p.poly([(8, 10), (14, 10), (12, 19), (6, 19)], shade(orange, 0.85))   # grip
    p.d.line([8, 13, 11, 13], fill=shade(orange, 1.2))
    p.d.arc([12, 9, 18, 15], 0, 180, fill=DARK)
    p.px(14, 12, DARK)
    p.box(30, 6, 31, 8, INK, False)
    p.outline()
    return p.im, {"grip": [9, 13], "muzzle": [31, 7]}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {}
    for name, fn in [("pistol", pistol), ("nailgun", nailgun), ("shotgun", shotgun), ("smg", smg), ("ray", ray),
                     ("revolver", revolver), ("flare_gun", flare)]:
        im, m = fn()
        # The guns are painted at 1 texel = 1 px of a 2.25 texel/unit grid:
        # double them so they sit at the characters' 4.5 texels per unit.
        im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
        m = {k: [v[0] * 2, v[1] * 2] for k, v in m.items()}
        m["size"] = [im.width, im.height]
        im.save(OUT / (name + ".png"))
        meta[name] = m
    (OUT / "guns.json").write_text(json.dumps(meta, indent=1))
    sheet = Image.new("RGBA", (200, 300), (40, 44, 60, 255))
    y = 4
    for name in meta:
        im = Image.open(OUT / (name + ".png"))
        sheet.paste(im, (4, y), im)
        y += im.height + 6
    sheet.resize((600, 900), Image.NEAREST).save("/tmp/claude-0/guns_preview.png")
    print(json.dumps(meta))


if __name__ == "__main__":
    main()
