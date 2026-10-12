#!/usr/bin/env python3
"""Melee weapons as held in the fist: side view, handle at the left, the
business end to the right, at the characters' texel scale (painted on the
2.25 texel/unit grid and doubled, like tools/gun_art.py).

    python3 tools/held_art.py  ->  assets/sprites/held/<id>.png + held.json

held.json: per weapon the grip point (where the fist closes) and the tip
(the striking end, for trails and sparks), in texels from the top-left.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from gun_art import Pen, shade, INK, STEEL, DARK

OUT = Path(__file__).resolve().parent.parent / "assets/sprites/held"
WOOD = (132, 84, 44, 255)
TAPE = (40, 40, 46, 255)
BLOOD = (120, 14, 18, 255)


def pipe():
    p = Pen(54, 8)
    p.box(2, 2, 51, 5, (104, 110, 118, 255))
    p.d.line([3, 3, 50, 3], fill=(170, 176, 186, 255))
    p.box(48, 1, 52, 6, (84, 88, 96, 255))           # elbow joint
    for x in (20, 33):
        p.px(x, 4, (140, 70, 40, 255))                # rust
    p.box(2, 2, 10, 5, TAPE)                          # grip tape
    p.outline()
    return p.im, {"grip": [5, 4], "tip": [51, 4]}


def board():
    p = Pen(56, 10)
    p.box(2, 2, 53, 7, WOOD)
    for x in range(8, 52, 7):
        p.d.line([x, 3, x + 4, 3], fill=shade(WOOD, 0.75))
        p.d.line([x + 2, 6, x + 5, 6], fill=shade(WOOD, 0.8))
    p.px(50, 1, STEEL)                                # nails
    p.px(50, 0, STEEL)
    p.px(46, 8, STEEL)
    p.px(46, 9, STEEL)
    p.outline()
    return p.im, {"grip": [5, 5], "tip": [52, 4]}


def chain():
    p = Pen(56, 10)
    p.box(1, 3, 7, 6, (90, 40, 30, 255))              # leather wrap
    for i in range(12):
        x = 8 + i * 4
        c = (150, 154, 162, 255)
        if i % 2 == 0:
            p.d.ellipse([x, 2, x + 5, 7], outline=c)
        else:
            p.d.line([x, 4, x + 5, 4], fill=c)
            p.d.line([x, 5, x + 5, 5], fill=shade(c, 0.7))
    p.outline()
    return p.im, {"grip": [4, 5], "tip": [54, 5]}


def crowbar():
    p = Pen(48, 12)
    red = (176, 36, 30, 255)
    p.box(2, 5, 42, 7, red)
    p.d.line([3, 5, 41, 5], fill=shade(red, 1.4))
    p.poly([(42, 5), (46, 3), (47, 6), (44, 8), (42, 7)], red)   # hook
    p.poly([(46, 3), (45, 1), (43, 2)], shade(red, 0.8))
    p.box(1, 5, 4, 8, shade(STEEL, 0.9))             # flat end
    p.outline()
    return p.im, {"grip": [7, 6], "tip": [45, 4]}


def knife():
    p = Pen(24, 8)
    p.box(1, 3, 8, 5, TAPE)
    p.box(8, 2, 9, 6, STEEL)                          # guard
    p.poly([(10, 3), (21, 3), (23, 4), (20, 5), (10, 5)], (204, 208, 216, 255))
    p.d.line([10, 3, 21, 3], fill=(250, 250, 255, 255))
    p.outline()
    return p.im, {"grip": [4, 4], "tip": [22, 4]}


def clipboard():
    p = Pen(20, 24)
    p.box(2, 3, 17, 22, (150, 110, 64, 255))
    p.box(4, 6, 15, 20, (236, 232, 220, 255), False)
    for y in range(8, 19, 2):
        p.d.line([5, y, 13, y], fill=(150, 150, 160, 255))
    p.box(7, 1, 12, 4, STEEL)
    p.outline()
    return p.im, {"grip": [3, 12], "tip": [17, 12]}


def stapler():
    p = Pen(18, 10)
    p.box(1, 6, 16, 8, DARK)
    p.poly([(1, 5), (15, 2), (17, 4), (16, 6), (1, 6)], (180, 40, 36, 255))
    p.d.line([2, 5, 14, 3], fill=(230, 90, 80, 255))
    p.outline()
    return p.im, {"grip": [4, 6], "tip": [16, 5]}


def baseball_bat():
    """LOUISVILLE LIEN: ash bat, tape grip, a few nails driven through."""
    p = Pen(56, 12)
    ash = (198, 150, 92, 255)
    p.poly([(2, 5), (18, 4), (52, 2), (54, 5), (54, 7), (52, 9), (18, 7), (2, 6)], ash)
    p.d.line([18, 4, 51, 3], fill=shade(ash, 1.25))
    p.d.line([18, 7, 51, 8], fill=shade(ash, 0.7))
    p.box(1, 4, 3, 7, shade(ash, 0.8))              # knob
    p.box(3, 4, 14, 6, TAPE)
    for x, y in ((40, 1), (46, 0), (49, 10), (43, 10)):
        p.px(x, y, STEEL)
        p.px(x, y + (1 if y < 5 else -1), STEEL)
    p.px(50, 5, BLOOD)
    p.px(51, 6, BLOOD)
    p.outline()
    return p.im, {"grip": [7, 5], "tip": [53, 5]}


def machete():
    p = Pen(44, 12)
    p.box(1, 5, 11, 7, (30, 30, 34, 255))           # handle
    for x in (3, 6, 9):
        p.px(x, 6, (90, 90, 96, 255))               # rivets
    blade = (186, 192, 200, 255)
    p.poly([(12, 4), (34, 3), (41, 4), (42, 6), (38, 9), (12, 8)], blade)
    p.d.line([13, 4, 34, 3], fill=(240, 244, 250, 255))
    p.d.line([14, 8, 37, 8], fill=shade(blade, 0.75))
    p.px(30, 6, BLOOD)
    p.px(31, 7, BLOOD)
    p.px(36, 6, BLOOD)
    p.outline()
    return p.im, {"grip": [5, 6], "tip": [41, 5]}


def sledgehammer():
    p = Pen(58, 20)
    p.box(2, 9, 46, 11, WOOD)
    p.d.line([3, 9, 45, 9], fill=shade(WOOD, 1.35))
    p.box(2, 9, 12, 11, TAPE)
    head = (70, 74, 82, 255)
    p.box(44, 2, 55, 17, head)
    p.d.line([45, 3, 54, 3], fill=shade(head, 1.6))
    p.d.line([45, 3, 45, 16], fill=shade(head, 1.3))
    p.box(42, 8, 44, 12, shade(head, 0.8))
    p.outline()
    return p.im, {"grip": [6, 10], "tip": [50, 10]}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {}
    for name, fn in [("pipe", pipe), ("board", board), ("chain", chain), ("crowbar", crowbar),
                     ("knife", knife), ("clipboard", clipboard), ("stapler", stapler),
                     ("baseball_bat", baseball_bat), ("machete", machete), ("sledgehammer", sledgehammer)]:
        im, m = fn()
        im = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
        m = {k: [v[0] * 2, v[1] * 2] for k, v in m.items()}
        m["size"] = [im.width, im.height]
        im.save(OUT / (name + ".png"))
        meta[name] = m
    (OUT / "held.json").write_text(json.dumps(meta, indent=1))
    sheet = Image.new("RGBA", (130, 260), (40, 44, 60, 255))
    y = 4
    for name in meta:
        im = Image.open(OUT / (name + ".png"))
        sheet.paste(im, (4, y), im)
        y += im.height + 4
    sheet.resize((520, 1040), Image.NEAREST).save("/tmp/claude-0/held_preview.png")
    print(list(meta))


if __name__ == "__main__":
    main()
