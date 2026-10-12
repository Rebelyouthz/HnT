#!/usr/bin/env python3
"""Over-the-head badges (house pixel style): WANTED bounty, ELITE, BOSS.
    python3 tools/badge_art.py -> assets/sprites/ui/badge_<kind>.png (3x)"""
from pathlib import Path
from PIL import Image
from gun_art import Pen, shade

OUT = Path(__file__).resolve().parent.parent / "assets/sprites/ui"
GOLD = (240, 196, 60, 255)
RED = (200, 40, 40, 255)
PUR = (150, 80, 210, 255)
WHT = (240, 236, 226, 255)
INKC = (20, 14, 24, 255)


def shield(col):
    p = Pen(18, 20)
    p.poly([(2, 2), (15, 2), (15, 10), (8.5, 18), (2, 10)], col)
    p.poly([(2, 2), (8, 2), (8, 17), (2, 10)], shade(col, 1.25))
    p.d.line([3, 3, 14, 3], fill=shade(col, 1.6))
    return p


def bounty():
    p = shield(GOLD)
    # A coin with a bounty "$".
    p.d.ellipse([5, 5, 12, 12], fill=shade(GOLD, 0.75))
    p.d.line([8, 6, 8, 11], fill=INKC)
    p.d.line([7, 7, 10, 7], fill=INKC)
    p.d.line([7, 10, 10, 10], fill=INKC)
    p.outline()
    return p.im


def elite():
    p = shield(PUR)
    # Double chevron.
    p.d.line([5, 8, 8, 5, 12, 8], fill=WHT, width=2)
    p.d.line([5, 12, 8, 9, 12, 12], fill=WHT, width=2)
    p.outline()
    return p.im


def boss():
    p = shield(RED)
    # Skull.
    p.d.ellipse([5, 4, 12, 11], fill=WHT)
    p.d.rectangle([6, 10, 11, 13], fill=WHT)
    p.px(7, 7, INKC)
    p.px(10, 7, INKC)
    p.d.line([7, 12, 10, 12], fill=INKC)
    p.outline()
    return p.im


for name, fn in [("bounty", bounty), ("elite", elite), ("boss", boss)]:
    fn().resize((54, 60), Image.NEAREST).save(OUT / f"badge_{name}.png")
print("ok")
