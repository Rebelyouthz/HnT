#!/usr/bin/env python3
"""Loot pickups drawn in code (same house style as tools/gun_art.py):
character shards (one colour per hero) and the gear parcel.

    python3 tools/loot_art.py -> assets/sprites/loot/shard_son.png, shard_father.png, gear_box.png
"""
from pathlib import Path
from PIL import Image
from gun_art import Pen, shade, INK

OUT = Path(__file__).resolve().parent.parent / "assets/sprites/loot"


def shard(base):
    p = Pen(16, 24)
    light = shade(base, 1.45)
    dark = shade(base, 0.6)
    p.poly([(8, 1), (14, 9), (11, 22), (5, 22), (2, 9)], base)        # body
    p.poly([(8, 1), (8, 22), (5, 22), (2, 9)], light)                 # lit face
    p.poly([(8, 1), (14, 9), (11, 22), (8, 22)], dark)                # shade face
    p.d.line([8, 3, 8, 20], fill=shade(base, 1.8))
    p.px(5, 7, (255, 255, 255, 255))
    p.px(4, 9, (255, 255, 255, 255))
    p.outline()
    return p.im


def gear_box():
    p = Pen(24, 18)
    tan = (176, 128, 74, 255)
    p.box(2, 5, 21, 16, tan)
    p.box(2, 3, 21, 6, shade(tan, 1.2))           # lid
    p.box(10, 3, 13, 16, (200, 40, 36, 255), False)  # ribbon
    p.box(2, 9, 21, 10, (200, 40, 36, 255), False)
    p.poly([(11, 3), (7, 0), (9, 3)], (230, 70, 60, 255))
    p.poly([(12, 3), (16, 0), (14, 3)], (230, 70, 60, 255))
    p.d.line([3, 15, 20, 15], fill=shade(tan, 0.6))
    p.outline()
    return p.im


def main():
    for name, im in [("shard_son", shard((236, 196, 52, 255))), ("shard_father", shard((214, 60, 52, 255))), ("gear_box", gear_box())]:
        im = im.resize((im.width * 3, im.height * 3), Image.NEAREST)
        im.save(OUT / (name + ".png"))
    print("ok")


if __name__ == "__main__":
    main()
