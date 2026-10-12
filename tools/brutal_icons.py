#!/usr/bin/env python3
"""BONE YARD tree icons as 32x32 pixel art, drawn with the same kit as every
other icon in the game (tools/pixkit.py: hue-shifted ramps, rim light,
selective outlines). One unique picture per move; the supers get a gold
ring. Written next to the other icons as brutal_<id>.png so
IconBook.tex("brutal_<id>") finds them.

    python3 tools/brutal_icons.py [--sheet]
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pixkit import Icon, sheet  # noqa: E402
from icon_pack import m_fist, m_heart, m_skull  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/sprites/icons"
ICONS = {}


def icon(name):
    def deco(fn):
        ICONS[name] = fn
        return fn
    return deco


def crack(ic, pts, mat="white"):
    ic.line(pts, mat, flat=True)


def burst(ic, cx, cy, r=5, mat="yellow"):
    for i in range(8):
        a = i * math.pi / 4
        rr = r if i % 2 == 0 else r - 2
        ic.pixels([(int(cx + math.cos(a) * rr), int(cy + math.sin(a) * rr))], mat, 4)


def drops(ic, pts):
    for x, y in pts:
        ic.ellipse(x, y, x + 1, y + 2, "blood", flat=True)


@icon("brutal_arm_breaker")
def arm_breaker():
    ic = Icon()
    # Upper arm down-left, forearm bent the wrong way up-right.
    ic.line([(4, 26), (15, 16)], "skin", width=6)
    ic.line([(15, 16), (25, 6)], "skin", width=5)
    ic.ellipse(22, 2, 29, 9, "skin", round_=True)
    ic.rect(2, 24, 8, 30, "blue")
    crack(ic, [(13, 13), (16, 16), (14, 18), (18, 21)], "white")
    burst(ic, 15, 16, 6, "yellow")
    drops(ic, [(18, 22), (20, 26)])
    return ic


@icon("brutal_knee_snap")
def knee_snap():
    ic = Icon()
    # Thigh down to the knee, shin kicked backwards.
    ic.line([(10, 3), (14, 15)], "denim", width=6)
    ic.line([(14, 15), (24, 22)], "denim", width=5)
    ic.poly([(22, 20), (30, 22), (30, 27), (21, 26)], "black")
    ic.ellipse(11, 12, 18, 19, "denim", round_=True)
    burst(ic, 14, 15, 7, "yellow")
    crack(ic, [(12, 13), (15, 15), (13, 17)], "white")
    # The boot that did it.
    ic.poly([(2, 18), (8, 16), (9, 22), (2, 23)], "leather")
    return ic


@icon("brutal_neck_crack")
def neck_crack():
    ic = Icon()
    ic.ellipse(9, 6, 23, 20, "skin", round_=True)
    ic.rect(13, 19, 19, 26, "skin")
    ic.rect(8, 25, 24, 31, "red")
    # Two hands on the jaw, twisting.
    ic.ellipse(3, 10, 10, 19, "skin", round_=True)
    ic.ellipse(22, 7, 29, 16, "skin", round_=True)
    ic.arc([4, 2, 28, 22], 200, 330, "white", width=1)
    ic.pixels([(26, 4), (27, 5), (25, 5)], "white", 4)
    crack(ic, [(14, 20), (16, 22), (15, 24), (18, 25)], "white")
    ic.pixels([(13, 11), (19, 11)], "ink", 0)
    return ic


@icon("brutal_death_touch")
def death_touch():
    ic = Icon()
    # Open palm, five glowing points.
    ic.rect(9, 14, 23, 28, "skin")
    for i, h in enumerate((7, 3, 2, 4)):
        ic.rect(9 + i * 4, h, 11 + i * 4, 15, "skin")
    ic.poly([(6, 16), (9, 15), (10, 22), (5, 20)], "skin")
    for x, y in ((10, 4), (14, 1), (18, 0), (22, 2), (6, 15)):
        ic.ellipse(x - 1, y, x + 1, y + 2, "cyan", flat=True)
        ic.pixels([(x, y + 1)], "white", 4)
    ic.pixels([(16, 21)], "cyan", 4)
    return ic


@icon("brutal_eye_gouge")
def eye_gouge():
    ic = Icon()
    ic.ellipse(4, 9, 28, 23, "white", round_=True)
    ic.ellipse(11, 10, 21, 22, "sky", round_=True)
    ic.ellipse(14, 13, 18, 19, "ink", flat=True)
    ic.pixels([(15, 14)], "white", 4)
    # Two thumbs coming in.
    ic.line([(0, 4), (8, 11)], "skin", width=4)
    ic.line([(31, 28), (24, 21)], "skin", width=4)
    drops(ic, [(9, 22), (22, 23), (16, 24)])
    return ic


@icon("brutal_pipe_javelin")
def pipe_javelin():
    ic = Icon()
    # Torso with a pipe straight through it.
    ic.poly([(9, 6), (23, 6), (25, 28), (7, 28)], "red")
    ic.ellipse(11, 0, 21, 8, "skin", round_=True)
    ic.line([(0, 18), (31, 13)], "steel", width=3)
    ic.ellipse(28, 11, 31, 15, "steel", round_=True)
    drops(ic, [(15, 19), (18, 21), (20, 24)])
    ic.pixels([(2, 17), (3, 17)], "white", 4)
    return ic


@icon("brutal_heart_punch")
def heart_punch():
    ic = Icon()
    m_fist(ic, 3, 12, "skin")
    m_heart(ic, 15, 2, 1.25, "blood")
    drops(ic, [(19, 18), (23, 21), (21, 25)])
    return ic


@icon("brutal_spine_rip")
def spine_rip():
    ic = Icon()
    m_skull(ic, 7, 1, "white")
    for i in range(6):
        y = 21 + i * 2
        ic.rect(14 - (i % 2), y, 18 + (i % 2), y + 1, "cream")
    ic.ellipse(20, 0, 30, 9, "skin", round_=True)
    drops(ic, [(11, 26), (21, 28)])
    return ic


@icon("brutal_back_breaker")
def back_breaker():
    ic = Icon()
    # A knee raised, a body folded over it the wrong way.
    ic.rect(10, 20, 16, 31, "denim")
    ic.ellipse(8, 16, 18, 24, "denim", round_=True)
    ic.arc([1, 4, 27, 30], 190, 350, "red", width=5)
    ic.ellipse(0, 15, 6, 21, "skin", round_=True)
    crack(ic, [(13, 8), (14, 11), (12, 13)], "white")
    burst(ic, 13, 10, 6, "yellow")
    return ic


@icon("brutal_throat_punch")
def throat_punch():
    ic = Icon()
    ic.ellipse(16, 1, 28, 13, "skin", round_=True)
    ic.rect(19, 12, 25, 22, "skin")
    ic.rect(15, 21, 30, 31, "olive")
    m_fist(ic, 1, 10, "skin")
    burst(ic, 20, 16, 5, "yellow")
    ic.pixels([(20, 6), (24, 6)], "ink", 0)
    ic.line([(20, 10), (24, 9)], "ink", flat=True)
    return ic


@icon("brutal_temple_tap")
def temple_tap():
    ic = Icon()
    ic.ellipse(6, 5, 24, 25, "skin", round_=True)
    ic.rect(6, 4, 24, 9, "brown")
    # Two fingers to the temple, the point lights up.
    ic.line([(31, 14), (23, 13)], "skin", width=3)
    ic.line([(31, 18), (24, 17)], "skin", width=3)
    ic.ellipse(19, 11, 23, 15, "cyan", flat=True)
    ic.pixels([(21, 13)], "white", 4)
    # Eyes rolled back: X X.
    for cx in (11, 17):
        ic.pixels([(cx - 1, 15), (cx + 1, 17), (cx + 1, 15), (cx - 1, 17), (cx, 16)], "ink", 0)
    return ic


@icon("brutal_bat_homerun")
def bat_homerun():
    ic = Icon()
    ic.line([(3, 28), (24, 7)], "wood", width=4)
    ic.ellipse(20, 3, 28, 11, "wood", round_=True)
    ic.rect(1, 27, 5, 31, "black")
    m_skull(ic, 13, 13, "white")
    for i in range(3):
        ic.line([(26 - i * 2, 13 + i * 4), (31, 11 + i * 4)], "white", flat=True)
    return ic


@icon("brutal_rib_breaker")
def rib_breaker():
    ic = Icon()
    # A ribcage, three ribs snapped.
    ic.rect(15, 3, 17, 29, "cream")
    for i in range(5):
        y = 6 + i * 5
        ic.arc([5, y - 2, 27, y + 8], 200, 340, "cream", width=2)
    for x, y in ((8, 9), (22, 14), (9, 19)):
        burst(ic, x, y, 3, "yellow")
        ic.pixels([(x, y)], "blood", 1)
    return ic


@icon("brutal_jaw_breaker")
def jaw_breaker():
    ic = Icon()
    m_skull(ic, 6, 2, "white")
    # The jaw knocked loose to the side, teeth flying.
    ic.poly([(14, 21), (26, 23), (24, 28), (13, 26)], "white")
    for x, y in ((27, 15), (29, 19), (25, 11)):
        ic.rect(x, y, x + 1, y + 2, "white")
    m_fist(ic, 1, 20, "skin")
    return ic


@icon("brutal_chain_noose")
def chain_noose():
    ic = Icon()
    ic.ellipse(9, 2, 23, 16, "skin", round_=True)
    ic.rect(8, 20, 24, 31, "red")
    # Chain links round the neck, the end pulled tight.
    for i in range(7):
        x = 8 + i * 2.6
        y = 18 + (1 if i % 2 else 0)
        ic.ring(int(x) - 2, int(y) - 1, int(x) + 2, int(y) + 2, 1, "steel")
    ic.line([(25, 18), (31, 26)], "steel", width=2)
    ic.pixels([(13, 8), (19, 8)], "ink", 0)
    return ic


def super_frame(ic):
    ic.ring(0, 0, 31, 31, 2, "gold")


@icon("brutal_two_way")
def two_way():
    ic = Icon()
    super_frame(ic)
    # A leg kicked back and a head flying off the other way.
    ic.line([(6, 26), (14, 18)], "denim", width=4)
    ic.line([(14, 18), (8, 10)], "denim", width=4)
    ic.ellipse(18, 4, 27, 13, "skin", round_=True)
    ic.arc([8, 2, 30, 24], 280, 350, "white", width=1)
    ic.arc([2, 8, 24, 30], 100, 170, "white", width=1)
    drops(ic, [(16, 14), (14, 16)])
    return ic


@icon("brutal_skull_crusher")
def skull_crusher():
    ic = Icon()
    super_frame(ic)
    m_skull(ic, 7, 8, "white")
    # Two palms closing on the temples.
    ic.rect(3, 10, 7, 22, "skin")
    ic.rect(25, 10, 29, 22, "skin")
    crack(ic, [(15, 8), (16, 12), (14, 14)], "ink")
    burst(ic, 16, 6, 4, "yellow")
    return ic


@icon("brutal_flamingo_reaper")
def flamingo_reaper():
    ic = Icon()
    super_frame(ic)
    # One leg raised high, three motion arcs off the same foot.
    ic.line([(13, 28), (14, 17)], "black", width=3)
    ic.line([(14, 17), (25, 9)], "black", width=3)
    ic.ellipse(10, 4, 17, 11, "skin", round_=True)
    ic.rect(11, 11, 17, 19, "black")
    for i in range(3):
        ic.arc([16 - i * 2, 2 + i * 2, 29 - i, 18 + i], 270, 360, ("fire", "orange", "yellow")[i], width=1)
    return ic


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    made = [fn().save(OUT / f"{name}.png") for name, fn in ICONS.items()]
    print(f"brutal icons {len(made)}")
    if "--sheet" in sys.argv:
        sheet(made, "/tmp/claude-0/icons/brutal.png", scale=6, cols=6)


if __name__ == "__main__":
    main()
