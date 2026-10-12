#!/usr/bin/env python3
"""Gun attachments as side-view pixel sprites at the guns' own texel scale
(tools/gun_art.py paints at 1 art texel, saved 2x), shaded by pixkit:

    python3 tools/gun_parts.py  ->  assets/sprites/guns/parts/<id>.png
                                    + assets/sprites/guns/parts/parts.json

parts.json gives each part its anchor (sprite px from the top-left) and the
gun mount it sits on:
    muzzle  left-middle on the muzzle (after a long barrel when fitted)
    rail    bottom-centre on the top rail (optics)
    under   top-centre under the barrel (laser)
    mag     top-centre on the magazine well
    window  centre on the ammo window (the round you loaded shows there)
"""
from __future__ import annotations

import json
from pathlib import Path

from pixkit import Icon

OUT = Path(__file__).resolve().parent.parent / "assets/sprites/guns/parts"
O = 4  # drawing origin inside the canvas (room for the outline)
PARTS = {}


def part(name, mount, anchor):
    def deco(fn):
        PARTS[name] = (fn, mount, anchor)
        return fn
    return deco


@part("suppressor", "muzzle", (O, O + 2))
def suppressor():
    ic = Icon(32)
    ic.rect(O, O, O + 13, O + 4, "gun")
    for x in range(O + 3, O + 12, 3):
        ic.rect(x, O, x, O + 4, "black", flat=True)
    ic.rect(O + 13, O + 1, O + 14, O + 3, "black")
    ic.glint(O + 1, O)
    return ic


@part("compensator", "muzzle", (O, O + 2))
def compensator():
    ic = Icon(32)
    ic.rect(O, O, O + 6, O + 4, "steel")
    for x in (O + 2, O + 4):
        ic.rect(x, O, x, O + 1, "ink", flat=True)
    ic.rect(O + 6, O + 1, O + 7, O + 3, "gun")
    return ic


@part("long_barrel", "muzzle", (O, O + 1))
def long_barrel():
    ic = Icon(32)
    ic.rect(O, O, O + 9, O + 2, "steel")
    ic.rect(O + 8, O - 1, O + 8, O - 1, "steel")
    ic.rect(O + 9, O, O + 10, O + 2, "gun")
    return ic


@part("short_barrel", "muzzle", (O, O + 2))
def short_barrel():
    ic = Icon(32)
    ic.poly([(O, O + 1), (O + 3, O), (O + 3, O + 4), (O, O + 3)], "steel")
    ic.rect(O + 3, O - 1, O + 4, O + 5, "gun")
    return ic


@part("red_dot", "rail", (O + 3, O + 5))
def red_dot():
    ic = Icon(32)
    ic.rect(O, O + 4, O + 6, O + 5, "gun")
    ic.poly([(O + 1, O + 4), (O + 1, O + 1), (O + 5, O), (O + 6, O + 4)], "gun", tone=1)
    ic.rect(O + 2, O + 1, O + 4, O + 3, "glass", flat=True, tone=-1)
    ic.pixels([(O + 3, O + 2)], "red", 4)
    return ic


@part("scope", "rail", (O + 8, O + 6))
def scope():
    ic = Icon(32)
    ic.rect(O + 2, O + 1, O + 14, O + 3, "gun")
    ic.rect(O, O, O + 2, O + 4, "gun")
    ic.rect(O + 14, O, O + 16, O + 4, "gun")
    ic.rect(O + 16, O + 1, O + 16, O + 3, "glass", flat=True, tone=1)
    ic.rect(O + 5, O + 4, O + 6, O + 6, "steel")
    ic.rect(O + 10, O + 4, O + 11, O + 6, "steel")
    ic.rect(O + 8, O - 1, O + 8, O, "steel")
    ic.glint(O + 3, O + 1)
    return ic


@part("laser", "under", (O + 3, O))
def laser():
    ic = Icon(32)
    ic.rect(O, O, O + 6, O + 2, "gun")
    ic.rect(O + 6, O, O + 7, O + 2, "red", flat=True, tone=1)
    ic.pixels([(O + 7, O + 1)], "pink", 4)
    return ic


@part("ext_mag", "mag", (O + 2, O))
def ext_mag():
    ic = Icon(32)
    ic.rect(O, O, O + 4, O + 7, "gun")
    ic.rect(O - 1, O + 7, O + 5, O + 8, "steel")
    ic.pixels([(O + 2, O + 2), (O + 2, O + 4)], "brass", 3)
    return ic


@part("drum_mag", "mag", (O + 5, O))
def drum_mag():
    ic = Icon(32)
    ic.rect(O + 3, O, O + 7, O + 3, "gun")
    ic.ellipse(O, O + 2, O + 10, O + 12, "gun", round_=True)
    ic.ellipse(O + 3, O + 5, O + 7, O + 9, "steel", round_=True)
    ic.pixels([(O + 5, O + 7)], "ink", 0)
    return ic


@part("quick_loader", "mag", (O + 3, O))
def quick_loader():
    ic = Icon(32)
    ic.poly([(O, O), (O + 6, O), (O + 7, O + 3), (O - 1, O + 3)], "red")
    ic.rect(O + 1, O + 3, O + 5, O + 4, "brass")
    return ic


def _round(tip):
    ic = Icon(32)
    ic.rect(O, O, O + 5, O + 3, "black")
    ic.rect(O + 1, O + 1, O + 3, O + 2, "brass", flat=True)
    ic.rect(O + 4, O + 1, O + 4, O + 2, tip, flat=True, tone=1)
    return ic


@part("hollow", "window", (O + 3, O + 2))
def hollow():
    return _round("copper")


@part("incendiary", "window", (O + 3, O + 2))
def incendiary():
    return _round("fire")


@part("ap_rounds", "window", (O + 3, O + 2))
def ap_rounds():
    return _round("steel")


@part("rubber", "window", (O + 3, O + 2))
def rubber():
    return _round("lime")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    meta = {}
    for name, (fn, mount, anchor) in PARTS.items():
        im = fn().render()
        box = im.getbbox()
        im = im.crop(box)
        ax, ay = anchor[0] - box[0], anchor[1] - box[1]
        im = im.resize((im.width * 2, im.height * 2), 0)
        im.save(OUT / f"{name}.png")
        meta[name] = {"mount": mount, "anchor": [ax * 2, ay * 2], "size": [im.width, im.height]}
    (OUT / "parts.json").write_text(json.dumps(meta, indent=1))
    print("parts", len(meta))


if __name__ == "__main__":
    main()
