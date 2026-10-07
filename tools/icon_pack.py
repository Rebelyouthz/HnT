#!/usr/bin/env python3
"""Every icon in the game as 32x32 pixel art (tools/pixkit.py does the
shading, hue-shifted ramps and selective outlines).

    python3 tools/icon_pack.py            -> assets/sprites/icons/*.png
                                            + assets/sprites/survive/*.png
    python3 tools/icon_pack.py --sheet    also writes contact sheets to /tmp

Shown in the game at whole multiples of the 640x360 pixel grid (a texel is
2 design px = 3 screen px), nearest filtered, via `IconBook`.
"""
from __future__ import annotations

import sys
from pathlib import Path

from pixkit import Icon, sheet

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/sprites/icons"
SURV = ROOT / "assets/sprites/survive"
ICONS = {}
SURV_ICONS = {}


def icon(name, surv=False):
    def deco(fn):
        (SURV_ICONS if surv else ICONS)[name] = fn
        return fn
    return deco


# --- shared motifs -------------------------------------------------------

def m_heart(ic, x, y, s=1.0, mat="red"):
    import math
    w = 12 * s
    pts = []
    for i in range(48):
        t = i / 48 * 2 * math.pi
        hx = 16 * math.sin(t) ** 3
        hy = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((x + w / 2 + hx / 34 * w, y + w * 0.42 - hy / 34 * w))
    ic.poly(pts, mat, round_=True, light=(0.3, 0.25))
    ic.glint(int(x + w * 0.24), int(y + w * 0.2), True)


def m_fist(ic, x, y, mat="skin"):
    ic.rect(x, y + 3, x + 13, y + 13, mat)
    for i in range(4):
        ic.rect(x + i * 3 + 1, y, x + i * 3 + 3, y + 5, mat)
    ic.rect(x - 2, y + 6, x + 2, y + 11, mat)
    ic.rect(x + 2, y + 13, x + 11, y + 17, "blue")


def m_boot(ic, x, y, mat="red", sole="white"):
    ic.poly([(x + 3, y), (x + 10, y), (x + 10, y + 8), (x + 18, y + 11), (x + 18, y + 15), (x + 1, y + 15), (x + 2, y + 6)], mat)
    ic.rect(x + 1, y + 15, x + 18, y + 17, sole)
    ic.line([(x + 5, y + 5), (x + 9, y + 5)], "white")
    ic.line([(x + 6, y + 8), (x + 10, y + 8)], "white")


def m_clock(ic, x, y, r=11, mat="steel", face="paper"):
    ic.ellipse(x, y, x + 2 * r, y + 2 * r, mat, round_=True)
    ic.ellipse(x + 3, y + 3, x + 2 * r - 3, y + 2 * r - 3, face, flat=True)
    cx, cy = x + r, y + r
    ic.line([(cx, cy), (cx, cy - r + 5)], "ink", flat=True)
    ic.line([(cx, cy), (cx + r - 6, cy + 1)], "red", flat=True)
    for ox, oy in ((0, -r + 4), (r - 4, 0), (0, r - 4), (-r + 4, 0)):
        ic.pixels([(cx + ox, cy + oy)], "ink", 1)


def m_magnet(ic, x, y):
    ic.arc([x, y, x + 20, y + 20], 180, 360, "red", width=6)
    ic.rect(x, y + 10, x + 5, y + 18, "red")
    ic.rect(x + 15, y + 10, x + 20, y + 18, "red")
    ic.rect(x, y + 17, x + 5, y + 21, "white")
    ic.rect(x + 15, y + 17, x + 20, y + 21, "white")


def m_clover(ic, x, y):
    for dx, dy in ((5, 0), (0, 5), (10, 5), (5, 10)):
        ic.ellipse(x + dx, y + dy, x + dx + 9, y + dy + 9, "green", round_=True)
    ic.line([(x + 10, y + 16), (x + 13, y + 23)], "jade", width=2)


def m_shield(ic, x, y, mat="steel", trim="gold"):
    ic.poly([(x, y), (x + 20, y), (x + 20, y + 10), (x + 10, y + 22), (x, y + 10)], trim)
    ic.poly([(x + 3, y + 3), (x + 17, y + 3), (x + 17, y + 10), (x + 10, y + 18), (x + 3, y + 10)], mat)
    ic.glint(x + 5, y + 5)


def m_drop(ic, x, y, mat="sky"):
    ic.poly([(x + 6, y), (x + 12, y + 10), (x, y + 10)], mat)
    ic.ellipse(x, y + 6, x + 12, y + 18, mat, round_=True)
    ic.glint(x + 3, y + 9, True)


def m_star(ic, cx, cy, r=12, mat="gold"):
    import math
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    ic.poly(pts, mat)
    ic.glint(int(cx - 2), int(cy - 3))


def m_bolt(ic, x, y, mat="yellow"):
    ic.poly([(x + 10, y), (x + 2, y + 13), (x + 8, y + 13), (x + 4, y + 26), (x + 16, y + 10), (x + 10, y + 10), (x + 14, y)], mat)


def m_skull(ic, x, y, mat="white"):
    ic.ellipse(x, y, x + 18, y + 16, mat, round_=True)
    ic.rect(x + 4, y + 12, x + 14, y + 19, mat)
    ic.ellipse(x + 3, y + 6, x + 7, y + 10, "ink", flat=True)
    ic.ellipse(x + 11, y + 6, x + 15, y + 10, "ink", flat=True)
    ic.pixels([(x + 9, y + 12)], "ink", 0)
    for i in range(3):
        ic.pixels([(x + 6 + i * 3, y + 17), (x + 6 + i * 3, y + 18)], "grey", 1)


def m_paper(ic, x0, y0, x1, y1, lines=True, mat="paper", ink="slate"):
    ic.rect(x0, y0, x1, y1, mat)
    if lines:
        for y in range(y0 + 3, y1 - 1, 3):
            ic.line([(x0 + 2, y), (x1 - 3, y)], ink, flat=True)


def m_flame(ic, x, y, s=1.0):
    ic.poly([(x + 8 * s, y), (x + 16 * s, y + 12 * s), (x + 13 * s, y + 20 * s), (x + 3 * s, y + 20 * s), (x, y + 12 * s), (x + 4 * s, y + 8 * s)], "fire")
    ic.poly([(x + 8 * s, y + 7 * s), (x + 12 * s, y + 14 * s), (x + 10 * s, y + 19 * s), (x + 6 * s, y + 19 * s), (x + 4 * s, y + 14 * s)], "yellow", flat=True, tone=1)


def m_plus(ic, x, y, mat="lime"):
    ic.rect(x + 2, y, x + 5, y + 7, mat)
    ic.rect(x, y + 2, x + 7, y + 5, mat)


def m_arrow_up(ic, x, y, mat="lime"):
    ic.poly([(x + 4, y), (x + 9, y + 5), (x + 6, y + 5), (x + 6, y + 10), (x + 2, y + 10), (x + 2, y + 5), (x - 1, y + 5)], mat)


def m_bottle(ic, x, y, mat="green", label="paper"):
    ic.rect(x + 3, y, x + 6, y + 6, mat)
    ic.rect(x, y + 6, x + 9, y + 21, mat)
    ic.rect(x + 1, y + 11, x + 8, y + 16, label, flat=True)
    ic.glint(x + 2, y + 8)


def m_drone(ic, x, y, body="white"):
    ic.rect(x, y + 2, x + 9, y + 3, "slate")
    ic.rect(x + 14, y + 2, x + 23, y + 3, "slate")
    ic.ellipse(x + 5, y + 4, x + 18, y + 12, body, round_=True)
    ic.ellipse(x + 9, y + 7, x + 13, y + 10, "cyan", flat=True, tone=1)
    ic.rect(x + 4, y, x + 5, y + 4, "slate")
    ic.rect(x + 18, y, x + 19, y + 4, "slate")


def m_gun(ic, x, y):
    ic.rect(x, y, x + 18, y + 5, "steel")
    ic.poly([(x + 2, y + 5), (x + 8, y + 5), (x + 6, y + 14), (x, y + 14)], "leather")
    ic.rect(x + 18, y + 1, x + 20, y + 3, "gun")


# --- currency & status ----------------------------------------------------

@icon("cur_gold")
def cur_gold():
    ic = Icon()
    ic.ellipse(4, 3, 27, 26, "gold", round_=True)
    ic.ellipse(4, 6, 27, 29, "brass")
    ic.ellipse(4, 3, 27, 26, "gold", round_=True)
    ic.ring(8, 7, 23, 22, 2, "brass", flat=True)
    ic.rect(14, 10, 17, 19, "gold")
    ic.glint(9, 7, True)
    return ic


@icon("cur_gem")
def cur_gem():
    ic = Icon()
    ic.poly([(4, 11), (10, 4), (22, 4), (28, 11), (16, 28)], "blue")
    ic.poly([(4, 11), (28, 11), (16, 28)], "blue", flat=True, tone=-1)
    ic.poly([(10, 4), (16, 11), (22, 4)], "cyan", flat=True, tone=1)
    ic.poly([(4, 11), (10, 4), (16, 11)], "sky", flat=True, tone=0)
    ic.poly([(16, 11), (22, 4), (28, 11)], "sky", flat=True, tone=-1)
    ic.poly([(10, 11), (22, 11), (16, 26)], "sky", flat=True, tone=0)
    ic.glint(10, 7, True)
    return ic


@icon("cur_scoin")
def cur_scoin():
    ic = Icon()
    ic.ellipse(4, 6, 27, 29, "teal")
    ic.ellipse(4, 3, 27, 26, "mint", round_=True)
    ic.ring(7, 6, 24, 23, 2, "jade", flat=True)
    # An S cut into the face.
    ic.line([(19, 10), (13, 10), (12, 12), (13, 14), (18, 15), (19, 17), (18, 19), (12, 19)], "jade", width=2, flat=True, tone=-1)
    ic.glint(9, 7, True)
    return ic


@icon("cur_rep")
def cur_rep():
    ic = Icon()
    m_shield(ic, 6, 4, "slate", "steel")
    m_star(ic, 16, 14, 6, "white")
    return ic


@icon("cur_xp")
def cur_xp():
    ic = Icon()
    ic.poly([(16, 2), (27, 16), (16, 30), (5, 16)], "lime")
    ic.poly([(16, 2), (27, 16), (16, 16)], "mint", flat=True, tone=1)
    ic.poly([(5, 16), (16, 30), (16, 16)], "green", flat=True, tone=-1)
    ic.glint(14, 7, True)
    return ic


@icon("cur_chi")
def cur_chi():
    ic = Icon()
    ic.ellipse(4, 4, 27, 27, "violet", round_=True)
    ic.ellipse(8, 8, 23, 23, "cyan", round_=True)
    ic.ellipse(12, 12, 19, 19, "white", flat=True)
    return ic


@icon("cur_flow")
def cur_flow():
    ic = Icon()
    ic.arc([3, 6, 29, 32], 200, 340, "cyan", width=4)
    ic.arc([7, 12, 25, 30], 200, 340, "sky", width=3)
    m_boot(ic, 7, 4, "cyan", "white")
    return ic


@icon("cur_ammo")
def cur_ammo():
    ic = Icon()
    for i, x in enumerate((6, 13, 20)):
        ic.rect(x, 12, x + 5, 27, "brass")
        ic.ellipse(x, 6, x + 5, 15, "copper", round_=True)
        ic.rect(x, 25, x + 5, 27, "gold")
    return ic


@icon("cur_knife")
def cur_knife():
    ic = Icon()
    ic.poly([(4, 27), (21, 6), (26, 4), (24, 9), (8, 29)], "steel")
    ic.line([(6, 27), (22, 8)], "white", flat=True)
    ic.line([(4, 26), (8, 30)], "leather", width=3)
    ic.glint(22, 7)
    return ic


@icon("cur_heart")
def cur_heart():
    ic = Icon()
    m_heart(ic, 3, 5, 2.1)
    return ic


@icon("cur_wheel")
def cur_wheel():
    ic = Icon()
    import math
    cols = ["gold", "violet", "green", "red"]
    for i in range(8):
        a0 = i * math.pi / 4
        a1 = a0 + math.pi / 4
        ic.poly([(16, 16), (16 + math.cos(a0) * 13, 16 + math.sin(a0) * 13), (16 + math.cos(a1) * 13, 16 + math.sin(a1) * 13)], cols[i % 4], flat=True)
    ic.ring(2, 2, 30, 30, 2, "gold", round_=True)
    ic.ellipse(13, 13, 19, 19, "white", round_=True)
    ic.poly([(13, 0), (19, 0), (16, 6)], "red")
    return ic


@icon("cur_chest")
def cur_chest():
    ic = Icon()
    ic.rect(3, 14, 28, 28, "wood")
    ic.poly([(3, 14), (5, 7), (26, 7), (28, 14)], "wood", tone=1)
    ic.rect(3, 13, 28, 15, "gold")
    ic.rect(13, 12, 18, 19, "gold")
    ic.rect(15, 15, 16, 17, "ink", flat=True)
    for x in (6, 24):
        ic.rect(x, 7, x + 1, 28, "brass")
    ic.glint(14, 13)
    return ic


@icon("cur_key")
def cur_key():
    ic = Icon()
    ic.ring(3, 3, 15, 15, 3, "gold", round_=True)
    ic.line([(13, 13), (27, 27)], "gold", width=3)
    ic.line([(21, 21), (18, 24)], "gold", width=2)
    ic.line([(25, 25), (22, 28)], "gold", width=2)
    return ic


@icon("cur_lock")
def cur_lock():
    ic = Icon()
    ic.arc([9, 3, 23, 19], 180, 360, "steel", width=3)
    ic.rect(9, 10, 12, 14, "steel")
    ic.rect(20, 10, 23, 14, "steel")
    ic.rect(6, 13, 26, 28, "gold")
    ic.ellipse(14, 17, 18, 21, "ink", flat=True)
    ic.rect(15, 20, 17, 24, "ink", flat=True)
    return ic


# --- story level-up items -----------------------------------------------

@icon("card_protein_shake")
def protein_shake():
    ic = Icon()
    ic.poly([(9, 9), (23, 9), (21, 29), (11, 29)], "glass")
    ic.poly([(10, 14), (22, 14), (21, 28), (11, 28)], "pink")
    ic.rect(8, 6, 24, 9, "white")
    ic.line([(19, 6), (23, 1)], "red", width=2)
    ic.rect(12, 18, 20, 22, "white", flat=True)
    ic.pixels([(14, 20), (15, 20), (16, 20), (17, 20), (18, 20)], "red", 1)
    ic.glint(11, 11)
    return ic


@icon("card_running_shoes")
def running_shoes():
    ic = Icon()
    m_boot(ic, 6, 7, "red", "white")
    for y in (12, 16, 20):
        ic.line([(1, y), (5, y)], "sky", flat=True)
    return ic


@icon("card_thick_hoodie")
def thick_hoodie():
    ic = Icon()
    ic.poly([(9, 6), (23, 6), (29, 14), (26, 18), (24, 15), (24, 29), (8, 29), (8, 15), (6, 18), (3, 14)], "slate")
    ic.ellipse(11, 3, 21, 12, "slate", round_=True)
    ic.ellipse(13, 6, 19, 12, "ink", flat=True)
    ic.rect(11, 21, 21, 25, "slate", tone=-1)
    ic.line([(14, 12), (14, 18)], "white", flat=True)
    ic.line([(18, 12), (18, 18)], "white", flat=True)
    return ic


@icon("card_chi_battery")
def chi_battery():
    ic = Icon()
    ic.rect(8, 6, 23, 29, "gun")
    ic.rect(12, 3, 19, 6, "steel")
    ic.rect(10, 9, 21, 27, "violet", flat=True, tone=-1)
    for y in (19, 15, 11):
        ic.rect(11, y, 20, y + 2, "cyan")
    ic.rect(11, 23, 20, 26, "cyan")
    m_bolt(ic, 9, 4, "yellow")
    return ic


@icon("card_paper_drone")
def paper_drone():
    ic = Icon()
    m_drone(ic, 4, 3)
    ic.line([(16, 15), (16, 18)], "slate")
    ic.rect(9, 19, 23, 25, "paper", round_=True)
    ic.line([(11, 21), (21, 21)], "slate", flat=True)
    ic.line([(11, 23), (19, 23)], "slate", flat=True)
    ic.rect(15, 19, 17, 25, "red", flat=True)
    return ic


@icon("card_stapler_orbit")
def stapler_orbit():
    ic = Icon()
    ic.arc([2, 2, 30, 30], 30, 330, "sky", width=1, flat=True)
    ic.rect(8, 15, 24, 19, "red")
    ic.poly([(8, 15), (10, 10), (24, 12), (24, 15)], "red", tone=1)
    ic.rect(7, 19, 25, 21, "gun")
    ic.pixels([(26, 18), (27, 18), (28, 18)], "steel", 4)
    ic.glint(11, 11)
    return ic


@icon("card_molotov_lob")
def molotov_lob():
    ic = Icon()
    m_bottle(ic, 10, 8, "olive", "paper")
    ic.rect(12, 5, 17, 8, "paper")
    m_flame(ic, 9, -1, 0.6)
    ic.pixels([(4, 14), (26, 20), (5, 24), (25, 10)], "fire", 3)
    return ic


@icon("card_stray_cat")
def stray_cat():
    ic = Icon()
    ic.ellipse(5, 14, 23, 28, "orange", round_=True)
    ic.ellipse(15, 5, 28, 17, "orange", round_=True)
    ic.poly([(16, 9), (17, 2), (21, 7)], "orange")
    ic.poly([(23, 7), (26, 2), (27, 10)], "orange")
    ic.line([(6, 23), (2, 15), (4, 10)], "orange", width=2)
    for x in (9, 13, 17):
        ic.line([(x, 17), (x + 2, 25)], "orange", flat=True, tone=-1)
    ic.pixels([(19, 10), (24, 10)], "lime", 3)
    ic.pixels([(19, 11), (24, 11)], "ink", 0)
    ic.pixels([(21, 13), (22, 13)], "pink", 2)
    return ic


@icon("card_repo_drone")
def repo_drone():
    ic = Icon()
    m_drone(ic, 4, 4, "slate")
    ic.pixels([(15, 10), (16, 10)], "red", 3)
    m_bolt(ic, 9, 14, "cyan")
    return ic


@icon("card_pigeon_squad")
def pigeon_squad():
    ic = Icon()
    for (x, y) in ((2, 16), (12, 5), (18, 18)):
        ic.ellipse(x, y + 3, x + 11, y + 10, "grey", round_=True)
        ic.ellipse(x + 8, y, x + 13, y + 5, "slate", round_=True)
        ic.poly([(x + 2, y + 4), (x + 6, y - 2), (x + 9, y + 4)], "steel")
        ic.pixels([(x + 14, y + 2)], "orange", 3)
        ic.pixels([(x + 11, y + 2)], "ink", 0)
    return ic


@icon("card_air_horn")
def air_horn():
    ic = Icon()
    ic.rect(4, 14, 11, 27, "red")
    ic.rect(5, 10, 10, 14, "gun")
    ic.poly([(10, 11), (20, 7), (20, 21), (10, 17)], "steel")
    ic.rect(20, 5, 23, 23, "steel", tone=1)
    for i, r in enumerate((4, 7, 10)):
        ic.arc([24 - r, 14 - r, 24 + r, 14 + r], 300, 60, "yellow", flat=True)
    return ic


@icon("card_smoke_bomb")
def smoke_bomb():
    ic = Icon()
    for (x, y, s) in ((2, 8, 12), (13, 3, 14), (16, 12, 14), (5, 15, 12)):
        ic.ellipse(x, y, x + s, y + s, "ghost", round_=True)
    ic.ellipse(9, 17, 21, 29, "black", round_=True)
    ic.line([(18, 18), (21, 14)], "brown", width=2)
    ic.pixels([(22, 13)], "fire", 4)
    ic.glint(12, 20)
    return ic


@icon("card_knife_belt")
def knife_belt():
    ic = Icon()
    ic.rect(2, 18, 29, 25, "leather")
    ic.rect(13, 17, 19, 26, "brass")
    ic.rect(15, 19, 17, 24, "leather", flat=True)
    for x in (4, 9, 21, 26):
        ic.poly([(x, 18), (x + 2, 4), (x + 4, 18)], "steel")
        ic.rect(x, 18, x + 4, 22, "black")
        ic.glint(x + 2, 7)
    return ic


@icon("card_slingshot")
def slingshot():
    ic = Icon()
    ic.line([(16, 29), (16, 18)], "wood", width=4)
    ic.line([(16, 18), (8, 6)], "wood", width=3)
    ic.line([(16, 18), (24, 6)], "wood", width=3)
    ic.line([(8, 6), (14, 16), (24, 6)], "brown", flat=True)
    ic.ellipse(11, 13, 17, 19, "leather", round_=True)
    ic.ellipse(22, 20, 28, 26, "grey", round_=True)
    return ic


@icon("card_brass_knuckles")
def brass_knuckles():
    ic = Icon()
    ic.rect(4, 12, 28, 21, "brass", round_=True)
    for i in range(4):
        x = 5 + i * 6
        ic.ring(x, 6, x + 6, 13, 2, "brass", round_=True)
    ic.rect(8, 20, 24, 27, "brass", tone=1, round_=True)
    ic.rect(11, 22, 21, 25, "ink", flat=True)
    ic.glint(7, 14)
    ic.glint(19, 7)
    return ic


@icon("card_vampire_tooth")
def vampire_tooth():
    ic = Icon()
    ic.poly([(8, 4), (24, 4), (22, 14), (18, 28), (16, 30), (14, 28), (10, 14)], "white")
    ic.rect(8, 4, 24, 8, "pink", tone=1)
    m_drop(ic, 20, 18, mat="blood")
    ic.glint(12, 8)
    return ic


@icon("card_tie_boomerang")
def tie_boomerang():
    ic = Icon()
    ic.poly([(4, 10), (14, 4), (17, 8), (9, 14), (12, 26), (8, 28)], "red")
    ic.poly([(14, 4), (28, 10), (27, 14), (17, 8)], "red", tone=1)
    for x, y in ((8, 12), (11, 20), (20, 9)):
        ic.rect(x, y, x + 2, y + 1, "navy", flat=True)
    ic.arc([4, 2, 30, 30], 200, 320, "white", width=1)
    ic.glint(15, 6)
    return ic


@icon("card_heat_wave")
def heat_wave():
    ic = Icon()
    ic.ring(2, 8, 30, 30, 3, "orange", round_=True)
    m_flame(ic, 16, 10, s=0.8)
    for x, y in ((4, 18), (27, 18), (16, 8)):
        ic.rect(x, y, x + 2, y + 3, "yellow", flat=True)
    return ic


@icon("card_throwing_bag")
def throwing_bag():
    ic = Icon()
    ic.poly([(6, 14), (26, 14), (28, 29), (4, 29)], "leather")
    ic.rect(5, 12, 27, 16, "leather", tone=1)
    ic.rect(9, 4, 13, 14, "green")
    ic.rect(10, 1, 12, 5, "paper")
    ic.ellipse(16, 6, 24, 14, "olive", round_=True)
    ic.rect(19, 3, 21, 7, "steel")
    ic.rect(14, 19, 18, 23, "brass")
    ic.glint(8, 17)
    return ic


# --- story rule cards (by idea) --------------------------------------------

@icon("card_head_trampoline")
def head_trampoline():
    ic = Icon()
    ic.ellipse(4, 18, 27, 29, "navy")
    ic.ellipse(6, 19, 25, 26, "blue", flat=True)
    for x in (6, 25):
        ic.rect(x, 25, x + 1, 30, "steel")
    m_boot(ic, 8, 1, "red", "white")
    ic.pixels([(4, 14), (27, 12), (2, 9)], "yellow", 4)
    return ic


@icon("card_family_discount")
def family_discount():
    ic = Icon()
    ic.poly([(3, 9), (18, 4), (28, 14), (13, 28), (3, 18)], "gold")
    ic.ellipse(7, 9, 11, 13, "ink", flat=True)
    ic.line([(13, 22), (22, 12)], "red", width=2)
    ic.ellipse(13, 12, 16, 15, "red", flat=True)
    ic.ellipse(19, 19, 22, 22, "red", flat=True)
    return ic


@icon("card_office_rage")
def office_rage():
    ic = Icon()
    ic.rect(4, 14, 26, 19, "steel")
    ic.poly([(4, 14), (6, 9), (26, 11), (26, 14)], "red")
    ic.rect(3, 19, 27, 21, "gun")
    m_drop(ic, 19, 13, "blood")
    ic.pixels([(10, 24), (11, 25), (14, 26)], "blood", 2)
    return ic


@icon("card_quiet_lunch")
def quiet_lunch():
    ic = Icon()
    ic.rect(4, 12, 27, 27, "brown")
    ic.poly([(4, 12), (8, 5), (23, 5), (27, 12)], "paper")
    ic.rect(13, 8, 18, 15, "red")
    m_plus(ic, 12, 17, "lime")
    return ic


@icon("card_double_slap")
def double_slap():
    ic = Icon()
    for x, mat in ((3, "skin"), (14, "skin")):
        ic.rect(x, 10, x + 11, 24, mat)
        for i in range(4):
            ic.rect(x + i * 3, 4 + (i % 2), x + i * 3 + 2, 11, mat)
    m_heart(ic, 21, 1, 0.8, "pink")
    ic.pixels([(2, 26), (9, 28), (16, 27), (27, 26)], "yellow", 4)
    return ic


@icon("card_ricochet_policy")
def ricochet_policy():
    ic = Icon()
    ic.rect(24, 3, 29, 28, "steel")
    ic.line([(2, 26), (23, 15), (6, 4)], "yellow", width=1, flat=True, tone=1)
    ic.ellipse(3, 2, 9, 7, "brass", round_=True)
    ic.pixels([(23, 14), (22, 16), (24, 17)], "white", 4)
    return ic


@icon("card_tutoring")
def tutoring():
    ic = Icon()
    ic.poly([(2, 10), (16, 4), (30, 10), (16, 16)], "ink")
    ic.rect(9, 12, 23, 18, "black")
    ic.line([(26, 11), (26, 20)], "gold")
    ic.ellipse(24, 19, 28, 23, "gold", round_=True)
    ic.rect(6, 22, 26, 29, "red")
    ic.rect(6, 22, 26, 23, "paper", flat=True)
    return ic


@icon("card_pendulum_politics")
def pendulum_politics():
    ic = Icon()
    for a in ((16, 2, 3, 15), (16, 2, 29, 15), (16, 2, 16, 20)):
        ic.line([a[:2], a[2:]], "white", flat=True)
    ic.arc([4, 6, 28, 26], 20, 160, "white", flat=True)
    ic.rect(12, 18, 20, 21, "steel")
    ic.ellipse(11, 21, 21, 30, "yellow", round_=True)
    return ic


@icon("card_cop_out")
def cop_out():
    ic = Icon()
    m_star(ic, 16, 15, 13, "gold")
    ic.ellipse(11, 10, 21, 20, "brass", flat=True)
    ic.line([(4, 4), (28, 28)], "red", width=3)
    return ic


@icon("card_steam_tax")
def steam_tax():
    ic = Icon()
    ic.ellipse(4, 12, 25, 29, "steel", round_=True)
    ic.rect(12, 9, 17, 13, "gun")
    ic.line([(23, 18), (29, 13)], "steel", width=3)
    for (x, y) in ((8, 2), (14, 0), (19, 3)):
        ic.ellipse(x, y, x + 6, y + 6, "ghost", round_=True)
    return ic


@icon("card_family_blitz")
def family_blitz():
    ic = Icon()
    m_boot(ic, 12, 8, "blue", "white")
    for y in (10, 15, 20):
        ic.line([(1, y), (10, y)], "cyan", flat=True)
    m_bolt(ic, 1, 1, "yellow")
    return ic


@icon("card_street_credit")
def street_credit():
    ic = Icon()
    for i in range(4):
        ic.rect(4 + i, 18 - i * 4, 22 + i, 24 - i * 4, "green")
        ic.ellipse(11 + i, 19 - i * 4, 15 + i, 23 - i * 4, "lime", flat=True)
    ic.ellipse(18, 18, 29, 29, "gold", round_=True)
    return ic


@icon("card_coping_magnet")
def coping_magnet():
    ic = Icon()
    m_magnet(ic, 6, 4)
    ic.pixels([(3, 29), (16, 28), (29, 29), (10, 30), (22, 30)], "lime", 3)
    return ic


@icon("card_orbit_form")
def orbit_form():
    ic = Icon()
    ic.ring(3, 9, 28, 22, 1, "sky", flat=True)
    ic.ellipse(11, 10, 20, 21, "skin", round_=True)
    ic.poly([(1, 13), (8, 15), (1, 17)], "steel")
    ic.poly([(30, 13), (23, 15), (30, 17)], "steel")
    return ic


@icon("card_drip_feed")
def drip_feed():
    ic = Icon()
    ic.rect(10, 2, 21, 15, "glass")
    ic.rect(11, 8, 20, 14, "red", flat=True)
    ic.line([(15, 15), (15, 22)], "white")
    m_drop(ic, 10, 19, "red")
    return ic


@icon("card_vacuum_hour")
def vacuum_hour():
    ic = Icon()
    for r, mat in ((13, "violet"), (9, "purple"), (5, "cyan")):
        ic.arc([16 - r, 16 - r, 16 + r, 16 + r], 0, 300, mat, width=2)
    ic.ellipse(13, 13, 19, 19, "white", flat=True)
    return ic


@icon("card_open_tab")
def open_tab():
    ic = Icon()
    m_paper(ic, 7, 2, 24, 29)
    ic.poly([(7, 29), (10, 26), (13, 29), (16, 26), (19, 29), (22, 26), (24, 29)], "paper")
    ic.rect(10, 22, 21, 24, "green", flat=True)
    return ic


@icon("card_invoice_void")
def invoice_void():
    ic = Icon()
    m_paper(ic, 6, 3, 25, 28)
    ic.line([(4, 4), (27, 27)], "red", width=3)
    ic.line([(27, 4), (4, 27)], "red", width=3)
    return ic


@icon("card_named_line")
def named_line():
    ic = Icon()
    ic.line([(2, 26), (10, 18), (16, 22), (28, 6)], "gold", width=3)
    m_star(ic, 25, 7, 6, "yellow")
    return ic


@icon("card_stomp_policy")
def stomp_policy():
    ic = Icon()
    m_boot(ic, 7, 3, "brown", "black")
    ic.rect(2, 24, 29, 26, "slate")
    ic.pixels([(4, 22), (27, 22), (6, 20), (25, 19)], "yellow", 4)
    return ic


@icon("card_idle_alibi")
def idle_alibi():
    ic = Icon()
    m_clock(ic, 4, 4, 12, "gold")
    return ic


@icon("card_courier_policy")
def courier_policy():
    ic = Icon()
    ic.rect(2, 10, 22, 24, "yellow")
    ic.poly([(22, 13), (26, 13), (30, 18), (30, 24), (22, 24)], "yellow", tone=-1)
    ic.rect(24, 14, 27, 18, "glass", flat=True)
    for x in (6, 23):
        ic.ellipse(x, 21, x + 6, 27, "black", round_=True)
    return ic


@icon("card_orchard_copay")
def orchard_copay():
    ic = Icon()
    ic.ellipse(5, 9, 26, 29, "red", round_=True)
    ic.line([(16, 10), (17, 3)], "brown", width=2)
    ic.ellipse(17, 2, 25, 7, "green")
    ic.glint(10, 13, True)
    return ic


@icon("card_brine_lungs")
def brine_lungs():
    ic = Icon()
    for (x, y, r) in ((6, 18, 8), (17, 8, 10), (20, 22, 6), (5, 4, 5)):
        ic.ring(x, y, x + r, y + r, 1, "cyan", flat=True)
        ic.glint(x + 2, y + 2)
    return ic


@icon("card_wall_bounce")
def wall_bounce():
    ic = Icon()
    for y in range(3, 29, 5):
        off = 0 if (y // 5) % 2 == 0 else 3
        for x in range(20 + off - 6, 31, 6):
            ic.rect(max(20, x), y, min(30, x + 5), y + 4, "rust")
    ic.line([(2, 26), (18, 16), (4, 6)], "white", flat=True)
    ic.ellipse(1, 3, 7, 9, "steel", round_=True)
    return ic


@icon("card_snack_break")
def snack_break():
    ic = Icon()
    ic.rect(7, 2, 24, 29, "white")
    ic.line([(7, 11), (24, 11)], "slate", flat=True)
    ic.rect(20, 5, 21, 9, "steel")
    ic.rect(20, 14, 21, 20, "steel")
    ic.pixels([(10, 24), (13, 26), (11, 15)], "slate", 1)
    return ic


@icon("card_revenge_policy")
def revenge_policy():
    ic = Icon()
    m_skull(ic, 7, 4, "white")
    ic.pixels([(10, 11), (11, 11), (18, 11), (19, 11)], "red", 3)
    return ic


@icon("card_cart_hop")
def cart_hop():
    ic = Icon()
    ic.rect(5, 10, 26, 20, "steel")
    for x in range(8, 25, 4):
        ic.line([(x, 11), (x, 19)], "gun", flat=True)
    ic.line([(2, 5), (5, 10)], "steel", width=2)
    for x in (7, 20):
        ic.ellipse(x, 22, x + 5, 27, "black", round_=True)
    ic.arc([6, 0, 28, 14], 200, 340, "yellow", flat=True)
    return ic


@icon("card_weapon_catch")
def weapon_catch():
    ic = Icon()
    ic.line([(4, 24), (22, 6)], "steel", width=4)
    ic.arc([6, 6, 30, 30], 270, 90, "cyan", flat=True)
    ic.poly([(26, 24), (30, 18), (22, 20)], "cyan")
    return ic


@icon("card_clash_policy")
def clash_policy():
    ic = Icon()
    ic.line([(4, 4), (26, 26)], "steel", width=3)
    ic.line([(26, 4), (4, 26)], "steel", width=3)
    ic.rect(2, 2, 6, 6, "gold")
    ic.rect(24, 2, 28, 6, "gold")
    ic.ellipse(12, 12, 19, 19, "yellow", round_=True)
    return ic


@icon("card_awning_hop")
def awning_hop():
    ic = Icon()
    for i in range(6):
        ic.poly([(2 + i * 5, 14), (7 + i * 5, 14), (7 + i * 5, 24), (2 + i * 5, 21)], "red" if i % 2 == 0 else "white")
    ic.rect(1, 12, 30, 14, "gun")
    ic.arc([6, 0, 26, 18], 200, 340, "yellow", flat=True)
    return ic


@icon("card_news_cycle")
def news_cycle():
    ic = Icon()
    ic.rect(4, 6, 27, 27, "paper")
    ic.rect(7, 9, 24, 13, "ink", flat=True)
    for y in (16, 19, 22):
        ic.line([(7, y), (14, y)], "slate", flat=True)
    ic.rect(17, 16, 24, 24, "steel", flat=True)
    return ic


@icon("card_oil_policy")
def oil_policy():
    ic = Icon()
    ic.rect(7, 5, 24, 29, "blue")
    for y in (10, 17, 24):
        ic.rect(7, y, 24, y + 1, "navy")
    ic.ellipse(7, 3, 24, 8, "blue", tone=1)
    m_flame(ic, 18, 0, 0.6)
    return ic


@icon("card_pole_vault")
def pole_vault():
    ic = Icon()
    ic.rect(14, 8, 16, 30, "slate")
    ic.line([(15, 8), (24, 4)], "slate", width=2)
    ic.rect(22, 3, 28, 6, "gun")
    ic.ellipse(21, 6, 29, 12, "yellow", round_=True)
    ic.arc([0, 6, 18, 24], 180, 300, "cyan", flat=True)
    return ic


@icon("card_dive_bounce")
def dive_bounce():
    ic = Icon()
    m_arrow_up(ic, 12, 2, "cyan")
    ic.poly([(4, 18), (10, 26), (16, 20), (22, 26), (28, 18)], "sky")
    return ic


@icon("card_hood_hop")
def hood_hop():
    ic = Icon()
    ic.poly([(2, 20), (8, 12), (20, 12), (26, 18), (30, 19), (30, 25), (2, 25)], "red")
    ic.poly([(9, 13), (14, 13), (14, 18), (6, 18)], "glass", flat=True)
    for x in (5, 21):
        ic.ellipse(x, 22, x + 6, 28, "black", round_=True)
    ic.arc([14, 0, 30, 16], 200, 340, "yellow", flat=True)
    return ic


@icon("card_steam_lid")
def steam_lid():
    ic = Icon()
    ic.ellipse(3, 18, 28, 29, "gun")
    ic.ellipse(5, 19, 26, 27, "steel", flat=True)
    for x in (8, 13, 18, 23):
        ic.line([(x, 20), (x, 26)], "gun", flat=True)
    for (x, y) in ((6, 6), (13, 2), (19, 7)):
        ic.ellipse(x, y, x + 8, y + 8, "ghost", round_=True)
    return ic


@icon("card_slide_tax")
def slide_tax():
    ic = Icon()
    ic.rect(1, 23, 30, 28, "slate")
    ic.poly([(6, 22), (12, 14), (24, 18), (28, 22)], "blue")
    for x in (2, 5, 8):
        ic.pixels([(x, 21), (x + 1, 20)], "yellow", 4)
    return ic


@icon("card_escape_clause")
def escape_clause():
    ic = Icon()
    ic.rect(10, 4, 21, 29, "slate")
    for y in range(7, 27, 5):
        ic.rect(12, y, 14, y + 2, "yellow", flat=True)
        ic.rect(17, y, 19, y + 2, "yellow", flat=True)
    ic.poly([(23, 14), (30, 20), (26, 20), (26, 28), (20, 28)], "cyan")
    return ic


@icon("card_talking_stick")
def talking_stick():
    ic = Icon()
    ic.line([(6, 28), (24, 4)], "wood", width=4)
    for (x, y) in ((10, 22), (16, 14), (21, 8)):
        ic.ellipse(x - 2, y - 2, x + 2, y + 2, "red", round_=True)
    ic.poly([(24, 4), (29, 2), (27, 8)], "white")
    return ic


@icon("card_landlord_void")
def landlord_void():
    ic = Icon()
    ic.poly([(3, 15), (16, 3), (29, 15)], "red")
    ic.rect(6, 15, 26, 29, "paper")
    ic.rect(13, 20, 18, 29, "brown")
    ic.line([(3, 4), (28, 29)], "black", width=3)
    return ic


@icon("card_shuttle_rip")
def shuttle_rip():
    ic = Icon()
    ic.poly([(16, 2), (22, 14), (22, 26), (10, 26), (10, 14)], "white")
    ic.ellipse(13, 9, 19, 15, "glass", flat=True)
    ic.poly([(10, 18), (4, 28), (10, 26)], "red")
    ic.poly([(22, 18), (28, 28), (22, 26)], "red")
    m_flame(ic, 11, 26, 0.35)
    return ic


# --- survivor gear ---------------------------------------------------------

def m_cap(ic, mat, brim=None):
    ic.ellipse(6, 7, 25, 25, mat, round_=True)
    ic.erase_rect(0, 19, 31, 31)
    ic.rect(4, 18, 29, 21, brim or mat, tone=-1)


@icon("gear_night_cap")
def gear_night_cap():
    ic = Icon()
    m_cap(ic, "navy")
    ic.rect(4, 18, 30, 21, "navy", tone=-1)
    ic.ellipse(13, 10, 19, 15, "yellow", flat=True)
    ic.ellipse(15, 9, 20, 14, "navy", flat=True)
    return ic


@icon("gear_hard_hat")
def gear_hard_hat():
    ic = Icon()
    ic.ellipse(6, 6, 25, 26, "yellow", round_=True)
    ic.erase_rect(0, 18, 31, 31)
    ic.rect(3, 17, 28, 20, "yellow", tone=-1)
    ic.rect(14, 6, 17, 17, "orange")
    return ic


@icon("gear_tinfoil_hat")
def gear_tinfoil_hat():
    ic = Icon()
    ic.poly([(16, 4), (27, 25), (5, 25)], "steel")
    for (a, b) in (((16, 6), (12, 14)), ((14, 13), (20, 18)), ((19, 17), (11, 22))):
        ic.line([a, b], "white", flat=True, tone=1)
    ic.line([(5, 25), (27, 25)], "grey", width=2)
    ic.line([(16, 4), (16, 0)], "steel", flat=True)
    ic.pixels([(16, 0)], "red", 4)
    for (x, y) in ((22, 3), (25, 7), (9, 5)):
        ic.pixels([(x, y)], "yellow", 4)
    return ic


@icon("gear_headset")
def gear_headset():
    ic = Icon()
    ic.arc([5, 3, 27, 27], 180, 360, "black", width=3)
    ic.rect(3, 13, 9, 23, "gun")
    ic.rect(23, 13, 29, 23, "gun")
    ic.line([(6, 23), (10, 28), (16, 28)], "black", width=2)
    ic.ellipse(15, 26, 19, 30, "red", round_=True)
    return ic


def m_jacket(ic, mat, collar=None):
    ic.poly([(9, 4), (23, 4), (30, 12), (27, 17), (24, 14), (24, 29), (8, 29), (8, 14), (5, 17), (2, 12)], mat)
    ic.poly([(12, 4), (16, 12), (20, 4)], collar or "ink", flat=True)
    ic.line([(16, 12), (16, 28)], mat, flat=True, tone=-1)


@icon("gear_rain_coat")
def gear_rain_coat():
    ic = Icon()
    m_jacket(ic, "yellow")
    for y in (15, 20, 25):
        ic.pixels([(18, y)], "black", 1)
    return ic


@icon("gear_hi_vis")
def gear_hi_vis():
    ic = Icon()
    m_jacket(ic, "hivis")
    ic.rect(8, 18, 24, 20, "steel", flat=True, tone=2)
    ic.rect(8, 24, 24, 26, "steel", flat=True, tone=2)
    return ic


@icon("gear_varsity")
def gear_varsity():
    ic = Icon()
    m_jacket(ic, "red", "white")
    ic.poly([(2, 12), (9, 4), (8, 14), (5, 17)], "white")
    ic.poly([(30, 12), (23, 4), (24, 14), (27, 17)], "white")
    ic.rect(9, 14, 13, 19, "gold", flat=True)
    return ic


@icon("gear_lab_coat")
def gear_lab_coat():
    ic = Icon()
    m_jacket(ic, "white", "sky")
    ic.rect(19, 15, 22, 17, "white", tone=-1)
    ic.line([(20, 13), (20, 16)], "blue", flat=True)
    return ic


@icon("gear_office_blazer")
def gear_office_blazer():
    ic = Icon()
    m_jacket(ic, "slate", "white")
    ic.poly([(15, 6), (17, 6), (18, 18), (16, 21), (14, 18)], "red")
    return ic


def m_shoe(ic, mat, sole="white", hi=False):
    top = 4 if hi else 10
    ic.poly([(6, top), (15, top), (16, 17), (28, 20), (28, 25), (4, 25), (5, 15)], mat)
    ic.rect(3, 25, 29, 28, sole)


@icon("gear_crocs")
def gear_crocs():
    ic = Icon()
    ic.ellipse(3, 13, 29, 28, "mint", round_=True)
    ic.erase_rect(0, 0, 31, 15)
    ic.rect(3, 15, 29, 22, "mint")
    for x in (10, 15, 20, 25):
        ic.ellipse(x, 17, x + 2, 19, "teal", flat=True)
    ic.arc([2, 8, 14, 22], 180, 270, "mint", width=2)
    return ic


@icon("gear_high_tops")
def gear_high_tops():
    ic = Icon()
    m_shoe(ic, "red", "white", hi=True)
    ic.ellipse(8, 14, 14, 20, "white", flat=True)
    for y in (7, 10, 13):
        ic.line([(9, y), (14, y)], "white", flat=True)
    return ic


@icon("gear_steel_toes")
def gear_steel_toes():
    ic = Icon()
    m_shoe(ic, "brown", "black", hi=True)
    ic.ellipse(19, 17, 29, 26, "steel", round_=True)
    return ic


@icon("gear_slippers")
def gear_slippers():
    ic = Icon()
    for (x, y) in ((2, 6), (8, 16)):
        ic.ellipse(x, y, x + 22, y + 11, "brown", round_=True)
        ic.ellipse(x + 9, y - 2, x + 22, y + 8, "red", round_=True)
        ic.pixels([(x + 13, y + 1), (x + 17, y), (x + 20, y + 2)], "cream", 4)
    return ic


@icon("gear_rabbit_foot")
def gear_rabbit_foot():
    ic = Icon()
    ic.ellipse(7, 10, 23, 30, "cream", round_=True)
    for x in (7, 12, 17):
        ic.ellipse(x, 24, x + 6, 30, "cream", round_=True)
    for x in (9, 14, 19):
        ic.ellipse(x, 26, x + 2, 28, "pink", flat=True)
    ic.rect(11, 5, 19, 11, "gold")
    ic.ring(12, 0, 18, 6, 1, "steel", flat=True)
    ic.pixels([(10, 15), (13, 18), (18, 14), (20, 19)], "cream", 1)
    return ic


@icon("gear_parking_pass")
def gear_parking_pass():
    ic = Icon()
    ic.rect(6, 4, 25, 28, "blue")
    ic.rect(9, 8, 22, 20, "white", flat=True)
    ic.line([(13, 17), (13, 10), (17, 10), (18, 11), (18, 13), (17, 14), (13, 14)], "blue", width=2, flat=True)
    ic.rect(13, 1, 18, 4, "steel")
    return ic


@icon("gear_family_photo")
def gear_family_photo():
    ic = Icon()
    ic.rect(4, 5, 27, 27, "wood")
    ic.rect(7, 8, 24, 24, "sky", flat=True)
    ic.ellipse(9, 11, 15, 17, "skin", flat=True)
    ic.ellipse(17, 14, 22, 19, "skin", flat=True)
    ic.rect(8, 17, 16, 24, "brown", flat=True)
    ic.rect(16, 19, 23, 24, "denim", flat=True)
    return ic


@icon("gear_loyalty_card")
def gear_loyalty_card():
    ic = Icon()
    ic.rect(3, 8, 28, 24, "gold")
    ic.rect(3, 11, 28, 13, "black", flat=True)
    for x in (6, 11, 16):
        ic.ellipse(x, 16, x + 3, 19, "red", flat=True)
    ic.ellipse(21, 16, 24, 19, "brown", flat=True)
    ic.glint(5, 9)
    return ic


@icon("gear_brass_bell")
def gear_brass_bell():
    ic = Icon()
    ic.poly([(16, 4), (24, 10), (26, 24), (6, 24), (8, 10)], "brass")
    ic.ellipse(13, 1, 19, 6, "brass", round_=True)
    ic.rect(4, 23, 28, 26, "brass", tone=-1)
    ic.ellipse(14, 25, 18, 29, "gold", round_=True)
    ic.glint(11, 10, True)
    return ic


def m_chain(ic, mat="gold"):
    for i in range(9):
        a = 3.14159 * (0.1 + 0.8 * i / 8)
        import math
        x, y = 16 - math.cos(a) * 11, 4 + math.sin(a) * 13
        ic.ring(int(x) - 2, int(y) - 2, int(x) + 2, int(y) + 2, 1, mat, flat=True)


@icon("gear_gold_chain")
def gear_gold_chain():
    ic = Icon()
    m_chain(ic, "gold")
    ic.ellipse(11, 17, 21, 27, "gold", round_=True)
    ic.rect(14, 20, 18, 24, "yellow", flat=True)
    ic.glint(13, 19)
    return ic


@icon("gear_dog_tags")
def gear_dog_tags():
    ic = Icon()
    m_chain(ic, "steel")
    ic.rect(9, 16, 17, 28, "steel")
    ic.rect(15, 18, 23, 29, "steel", tone=-1)
    for y in (20, 23):
        ic.line([(11, y), (15, y)], "slate", flat=True)
    return ic


@icon("gear_whistle")
def gear_whistle():
    ic = Icon()
    ic.arc([4, 0, 28, 20], 20, 160, "red", width=1, flat=True)
    ic.rect(8, 16, 22, 24, "steel")
    ic.ellipse(18, 14, 28, 26, "steel", round_=True)
    ic.ellipse(21, 17, 25, 22, "ink", flat=True)
    ic.rect(4, 18, 8, 22, "gun")
    return ic


@icon("gear_lanyard")
def gear_lanyard():
    ic = Icon()
    ic.line([(6, 1), (13, 14)], "blue", width=2)
    ic.line([(26, 1), (19, 14)], "blue", width=2)
    ic.rect(9, 14, 23, 29, "white")
    ic.rect(9, 14, 23, 18, "red")
    ic.rect(12, 21, 20, 22, "slate", flat=True)
    ic.rect(12, 24, 17, 25, "slate", flat=True)
    return ic


def m_ring(ic, band, stone=None):
    ic.ring(6, 9, 26, 29, 4, band, round_=True)
    if stone:
        ic.ellipse(11, 2, 21, 12, stone, round_=True)
        ic.glint(13, 4, True)


@icon("gear_mood_ring")
def gear_mood_ring():
    ic = Icon()
    m_ring(ic, "steel", "violet")
    return ic


@icon("gear_class_ring")
def gear_class_ring():
    ic = Icon()
    m_ring(ic, "gold", "red")
    return ic


@icon("gear_wedding_band")
def gear_wedding_band():
    ic = Icon()
    m_ring(ic, "gold")
    ic.glint(9, 14, True)
    return ic


@icon("gear_knuckle_ring")
def gear_knuckle_ring():
    ic = Icon()
    for x in (2, 9, 16, 23):
        ic.ring(x, 12, x + 7, 20, 2, "steel", round_=True)
    ic.rect(2, 19, 30, 23, "steel")
    return ic


@icon("slot_neck")
def slot_neck():
    ic = Icon()
    m_chain(ic, "slate")
    ic.ellipse(11, 17, 21, 27, "slate")
    return ic


@icon("slot_ring")
def slot_ring():
    ic = Icon()
    m_ring(ic, "slate", "slate")
    return ic


@icon("slot_cap")
def slot_cap():
    ic = Icon()
    m_cap(ic, "slate")
    return ic


@icon("slot_jacket")
def slot_jacket():
    ic = Icon()
    m_jacket(ic, "slate")
    return ic


@icon("slot_shoes")
def slot_shoes():
    ic = Icon()
    m_shoe(ic, "slate", "grey")
    return ic


@icon("slot_charm")
def slot_charm():
    ic = Icon()
    ic.ring(9, 2, 22, 15, 2, "slate", flat=True)
    ic.poly([(16, 12), (24, 20), (16, 29), (8, 20)], "slate")
    return ic


@icon("gear_box")
def gear_box():
    ic = Icon()
    ic.rect(4, 12, 27, 28, "brown")
    ic.poly([(4, 12), (9, 6), (22, 6), (27, 12)], "wood")
    ic.rect(14, 6, 17, 28, "mint")
    ic.rect(4, 17, 27, 19, "mint")
    ic.pixels([(16, 3), (12, 4), (20, 4)], "yellow", 4)
    return ic


# --- gun attachments (icons; the on-gun sprites come from gun_parts) --------

@icon("part_suppressor")
def part_suppressor():
    ic = Icon()
    ic.rect(3, 12, 25, 19, "steel")
    for x in range(7, 23, 4):
        ic.rect(x, 12, x, 19, "gun", flat=True)
    ic.rect(25, 13, 28, 18, "gun")
    ic.rect(1, 14, 3, 17, "gun")
    ic.glint(5, 13)
    return ic


@icon("part_compensator")
def part_compensator():
    ic = Icon()
    ic.rect(6, 11, 24, 20, "steel")
    for x in (10, 15, 20):
        ic.rect(x, 11, x + 2, 14, "ink", flat=True)
    ic.rect(4, 13, 6, 18, "gun")
    for x in (11, 16, 21):
        ic.line([(x, 9), (x - 1, 5)], "ghost", flat=True)
    return ic


@icon("part_red_dot")
def part_red_dot():
    ic = Icon()
    ic.rect(5, 18, 26, 22, "gun")
    ic.poly([(9, 18), (9, 9), (22, 7), (24, 18)], "gun", tone=1)
    ic.rect(11, 10, 20, 17, "glass", flat=True, tone=-1)
    ic.ellipse(14, 12, 17, 15, "red", flat=True, tone=2)
    return ic


@icon("part_laser")
def part_laser():
    ic = Icon()
    ic.rect(3, 13, 15, 19, "gun")
    ic.rect(15, 14, 17, 18, "red")
    ic.line([(17, 16), (30, 16)], "red", flat=True, tone=2)
    ic.pixels([(30, 16), (29, 15), (29, 17)], "pink", 4)
    return ic


@icon("part_scope")
def part_scope():
    ic = Icon()
    ic.rect(4, 11, 27, 17, "gun")
    ic.ellipse(1, 9, 7, 19, "gun", round_=True)
    ic.ellipse(24, 9, 30, 19, "gun", round_=True)
    ic.ellipse(26, 11, 29, 17, "glass", flat=True)
    ic.rect(11, 17, 14, 22, "steel")
    ic.rect(18, 17, 21, 22, "steel")
    ic.rect(14, 8, 17, 11, "steel")
    return ic


@icon("part_long_barrel")
def part_long_barrel():
    ic = Icon()
    ic.rect(1, 13, 30, 17, "steel")
    ic.rect(1, 12, 7, 18, "gun")
    ic.rect(27, 12, 30, 18, "gun")
    ic.glint(9, 13)
    return ic


@icon("part_short_barrel")
def part_short_barrel():
    ic = Icon()
    ic.rect(8, 11, 22, 19, "steel")
    ic.rect(6, 10, 10, 20, "gun")
    ic.poly([(22, 11), (25, 9), (25, 21), (22, 19)], "steel", tone=1)
    for (x, y) in ((27, 12), (28, 16), (27, 19)):
        ic.pixels([(x, y)], "yellow", 4)
    return ic


@icon("part_ext_mag")
def part_ext_mag():
    ic = Icon()
    ic.poly([(11, 2), (19, 2), (22, 28), (14, 28)], "gun")
    ic.rect(12, 2, 18, 4, "brass")
    ic.rect(13, 24, 22, 28, "steel")
    return ic


@icon("part_drum_mag")
def part_drum_mag():
    ic = Icon()
    ic.rect(13, 2, 19, 10, "gun")
    ic.ellipse(4, 8, 27, 30, "gun", round_=True)
    ic.ellipse(11, 15, 20, 24, "steel", round_=True)
    ic.ellipse(14, 18, 17, 21, "ink", flat=True)
    return ic


@icon("part_quick_loader")
def part_quick_loader():
    ic = Icon()
    ic.ellipse(4, 4, 27, 27, "steel", round_=True)
    import math
    for i in range(6):
        a = i * math.pi / 3
        x, y = 16 + math.cos(a) * 7, 16 + math.sin(a) * 7
        ic.ellipse(x - 3, y - 3, x + 3, y + 3, "brass", round_=True)
    ic.ellipse(13, 13, 19, 19, "gun", flat=True)
    return ic


def m_round(ic, mat_tip, mat_case="brass"):
    ic.rect(10, 13, 21, 29, mat_case)
    ic.poly([(10, 13), (21, 13), (19, 6), (16, 2), (12, 6)], mat_tip)
    ic.rect(9, 27, 22, 29, mat_case, tone=-1)
    ic.glint(12, 15)


@icon("part_hollow")
def part_hollow():
    ic = Icon()
    m_round(ic, "copper")
    ic.ellipse(14, 2, 18, 6, "ink", flat=True)
    return ic


@icon("part_incendiary")
def part_incendiary():
    ic = Icon()
    m_round(ic, "red")
    m_flame(ic, 20, 0, 0.5)
    return ic


@icon("part_ap_rounds")
def part_ap_rounds():
    ic = Icon()
    m_round(ic, "black")
    ic.poly([(13, 7), (16, 1), (19, 7)], "steel", tone=1)
    return ic


@icon("part_rubber")
def part_rubber():
    ic = Icon()
    ic.rect(10, 13, 21, 29, "green")
    ic.ellipse(10, 5, 21, 17, "black", round_=True)
    ic.rect(9, 27, 22, 29, "brass")
    return ic


@icon("slot_muzzle")
def slot_muzzle():
    ic = Icon()
    ic.rect(4, 12, 25, 19, "slate")
    return ic


@icon("slot_optic")
def slot_optic():
    ic = Icon()
    ic.ring(7, 7, 24, 24, 2, "slate", flat=True)
    ic.line([(16, 4), (16, 27)], "slate", flat=True)
    ic.line([(4, 16), (27, 16)], "slate", flat=True)
    return ic


@icon("slot_barrel")
def slot_barrel():
    ic = Icon()
    ic.rect(2, 13, 29, 18, "slate")
    return ic


@icon("slot_mag")
def slot_mag():
    ic = Icon()
    ic.poly([(11, 2), (19, 2), (22, 28), (14, 28)], "slate")
    return ic


@icon("slot_ammo")
def slot_ammo():
    ic = Icon()
    m_round(ic, "slate", "grey")
    return ic


# --- brawl / parkour skill nodes and META ---------------------------------

@icon("node_hp")
def node_hp():
    ic = Icon()
    m_heart(ic, 4, 4, 2.0)
    m_plus(ic, 21, 20)
    return ic


@icon("node_steam")
def node_steam():
    ic = Icon()
    ic.ellipse(4, 12, 25, 29, "steel", round_=True)
    ic.rect(12, 9, 17, 13, "gun")
    ic.line([(23, 18), (29, 13)], "steel", width=3)
    for (x, y) in ((6, 2), (13, 0), (19, 4)):
        ic.ellipse(x, y, x + 7, y + 7, "ghost", round_=True)
    return ic


@icon("node_bandage")
def node_bandage():
    ic = Icon()
    ic.poly([(3, 20), (20, 3), (28, 11), (11, 28)], "cream")
    ic.poly([(11, 12), (15, 8), (23, 16), (19, 20)], "paper", tone=1)
    ic.pixels([(14, 14), (17, 14), (15, 16), (18, 17), (16, 18)], "brown", 1)
    return ic


@icon("node_wardrobe")
def node_wardrobe():
    ic = Icon()
    ic.rect(5, 3, 26, 29, "wood")
    ic.line([(16, 4), (16, 28)], "brown", flat=True, tone=-1)
    ic.pixels([(14, 16), (18, 16)], "gold", 4)
    m_heart(ic, 18, 19, 0.75)
    return ic


@icon("node_gut")
def node_gut():
    ic = Icon()
    m_shield(ic, 5, 4, "steel", "brass")
    m_heart(ic, 10, 9, 0.9)
    return ic


@icon("node_patience")
def node_patience():
    ic = Icon()
    ic.poly([(8, 3), (24, 3), (16, 16)], "glass")
    ic.poly([(8, 29), (24, 29), (16, 16)], "glass")
    ic.poly([(12, 9), (20, 9), (16, 15)], "yellow", flat=True)
    ic.poly([(10, 28), (22, 28), (16, 22)], "yellow", flat=True)
    ic.rect(6, 1, 26, 3, "wood")
    ic.rect(6, 29, 26, 31, "wood")
    return ic


@icon("node_disarm")
def node_disarm():
    ic = Icon()
    ic.line([(4, 26), (20, 10)], "steel", width=3)
    ic.rect(18, 4, 28, 14, "skin")
    ic.pixels([(24, 20), (27, 24), (21, 23)], "yellow", 4)
    return ic


@icon("node_sand")
def node_sand():
    ic = Icon()
    ic.poly([(6, 10), (22, 10), (26, 29), (2, 29)], "cream")
    ic.rect(9, 6, 19, 10, "brown")
    for (x, y) in ((23, 4), (27, 8), (25, 12), (29, 5), (28, 14)):
        ic.pixels([(x, y)], "cream", 3)
    return ic


@icon("node_heavy")
def node_heavy():
    ic = Icon()
    m_fist(ic, 9, 4)
    for y in (8, 12):
        ic.line([(1, y), (6, y)], "yellow", flat=True)
    return ic


@icon("node_cling")
def node_cling():
    ic = Icon()
    ic.rect(20, 1, 26, 30, "rust")
    ic.rect(8, 10, 20, 22, "skin")
    for i in range(4):
        ic.rect(17, 8 + i * 4, 23, 10 + i * 4, "skin")
    return ic


@icon("node_commute")
def node_commute():
    ic = Icon()
    ic.rect(3, 6, 28, 22, "yellow")
    ic.rect(5, 9, 26, 15, "glass", flat=True)
    for x in (10, 17):
        ic.line([(x, 9), (x, 15)], "yellow", flat=True)
    for x in (5, 21):
        ic.ellipse(x, 20, x + 6, 26, "black", round_=True)
    m_magnet(ic, 20, 18)
    return ic


@icon("node_quiet")
def node_quiet():
    ic = Icon()
    ic.rect(6, 10, 20, 24, "skin")
    ic.rect(13, 2, 17, 12, "skin")
    ic.ellipse(18, 6, 28, 16, "white", round_=True)
    ic.line([(20, 8), (26, 14)], "red", width=2)
    return ic


@icon("node_xp")
def node_xp():
    ic = Icon()
    m_magnet(ic, 2, 2)
    ic.poly([(24, 14), (30, 21), (24, 28), (18, 21)], "lime")
    return ic


@icon("node_crown")
def node_crown():
    ic = Icon()
    ic.poly([(3, 10), (10, 16), (16, 5), (22, 16), (29, 10), (26, 25), (6, 25)], "gold")
    ic.rect(5, 23, 27, 27, "gold", tone=-1)
    for x in (9, 16, 23):
        ic.ellipse(x - 2, 20, x + 1, 23, "red", flat=True)
    ic.glint(15, 8)
    return ic


@icon("node_eyes")
def node_eyes():
    ic = Icon()
    ic.ellipse(2, 9, 29, 23, "white", round_=True)
    ic.ellipse(11, 10, 21, 22, "jade", round_=True)
    ic.ellipse(14, 13, 18, 19, "ink", flat=True)
    ic.glint(13, 12)
    ic.arc([2, 3, 29, 17], 200, 340, "ink", flat=True)
    return ic


@icon("node_pinball")
def node_pinball():
    ic = Icon()
    ic.ellipse(4, 4, 27, 27, "pink", round_=True)
    ic.ellipse(9, 9, 22, 22, "violet", round_=True)
    ic.ellipse(13, 13, 18, 18, "white", flat=True)
    m_bolt(ic, 17, 1, "yellow")
    return ic


@icon("node_school")
def node_school():
    ic = Icon()
    ic.rect(14, 3, 15, 29, "steel")
    ic.poly([(15, 4), (29, 8), (15, 13)], "red")
    ic.rect(10, 27, 20, 29, "gun")
    return ic


@icon("node_group")
def node_group():
    ic = Icon()
    for (x, y, s) in ((2, 10, 10), (19, 10, 10), (9, 5, 13)):
        ic.ellipse(x, y, x + s, y + s, "skin", round_=True)
    ic.rect(1, 20, 30, 29, "denim")
    ic.poly([(23, 20), (29, 24), (23, 29), (17, 24)], "sky")
    return ic


@icon("node_joke")
def node_joke():
    ic = Icon()
    ic.ellipse(3, 3, 28, 22, "white", round_=True)
    ic.poly([(8, 19), (6, 28), (14, 20)], "white")
    for x in (9, 15, 21):
        ic.ellipse(x - 1, 11, x + 2, 14, "slate", flat=True)
    return ic


# Parkour nodes.
@icon("node_jump")
def node_jump():
    ic = Icon()
    m_boot(ic, 7, 8, "cyan", "white")
    m_arrow_up(ic, 21, 2, "lime")
    m_arrow_up(ic, 1, 10, "lime")
    return ic


@icon("node_float")
def node_float():
    ic = Icon()
    ic.arc([2, 3, 30, 27], 180, 360, "red", width=4)
    ic.rect(2, 14, 30, 15, "red", tone=-1)
    for x in (4, 16, 28):
        ic.line([(x, 15), (16, 28)], "white", flat=True)
    ic.rect(14, 26, 18, 30, "blue")
    return ic


@icon("node_wall")
def node_wall():
    ic = Icon()
    for y in range(2, 30, 5):
        off = 0 if (y // 5) % 2 == 0 else 3
        for x in range(off - 3, 12, 6):
            ic.rect(max(1, x), y, min(11, x + 5), y + 4, "rust")
    m_boot(ic, 12, 6, "cyan", "white")
    return ic


@icon("node_hang")
def node_hang():
    ic = Icon()
    ic.rect(1, 3, 30, 6, "steel")
    for x in (9, 19):
        ic.rect(x, 6, x + 4, 14, "skin")
    m_clock(ic, 8, 14, 8, "slate")
    return ic


@icon("node_stomp")
def node_stomp():
    ic = Icon()
    m_boot(ic, 7, 1, "brown", "black")
    ic.rect(1, 24, 30, 27, "slate")
    for x in (3, 26):
        ic.line([(x, 22), (x + (3 if x < 16 else -3), 17)], "yellow", flat=True)
    return ic


@icon("node_slide")
def node_slide():
    ic = Icon()
    ic.rect(1, 23, 30, 27, "slate")
    ic.poly([(4, 22), (12, 13), (26, 17), (30, 22)], "red")
    for x in (1, 4):
        ic.line([(x, 15), (x + 6, 15)], "cyan", flat=True)
    return ic


@icon("node_quake")
def node_quake():
    ic = Icon()
    ic.rect(1, 20, 30, 29, "brown")
    ic.line([(16, 20), (13, 24), (17, 27), (14, 29)], "ink", flat=True)
    ic.line([(8, 20), (6, 25)], "ink", flat=True)
    ic.line([(24, 20), (27, 26)], "ink", flat=True)
    for (x, y) in ((6, 12), (14, 8), (22, 12)):
        ic.ellipse(x, y, x + 4, y + 4, "cream", round_=True)
    return ic


@icon("node_roll")
def node_roll():
    ic = Icon()
    ic.arc([3, 3, 28, 28], 30, 330, "cyan", width=3)
    ic.poly([(24, 3), (29, 9), (22, 10)], "cyan")
    ic.ellipse(10, 10, 21, 21, "skin", round_=True)
    return ic


@icon("node_meteor")
def node_meteor():
    ic = Icon()
    for i, mat in enumerate(("fire", "orange", "yellow")):
        ic.line([(2 + i * 2, 2), (16, 16)], mat, width=3 - i)
    ic.ellipse(14, 14, 28, 28, "rust", round_=True)
    ic.pixels([(18, 19), (23, 22)], "black", 1)
    return ic


@icon("node_iron")
def node_iron():
    ic = Icon()
    ic.rect(10, 2, 21, 15, "denim")
    ic.ellipse(8, 12, 23, 24, "steel", round_=True)
    ic.rect(10, 22, 21, 29, "denim")
    return ic


@icon("node_ghost")
def node_ghost():
    ic = Icon()
    ic.ellipse(7, 3, 24, 20, "ghost", round_=True)
    ic.rect(7, 12, 24, 26, "ghost")
    ic.poly([(7, 26), (10, 29), (13, 26), (16, 29), (19, 26), (22, 29), (24, 26)], "ghost")
    ic.ellipse(11, 9, 14, 13, "ink", flat=True)
    ic.ellipse(17, 9, 20, 13, "ink", flat=True)
    return ic


@icon("node_score")
def node_score():
    ic = Icon()
    m_star(ic, 16, 14, 13, "gold")
    ic.rect(8, 24, 24, 29, "red")
    return ic


@icon("node_chain")
def node_chain():
    ic = Icon()
    for i in range(3):
        ic.ring(2 + i * 9, 10 + (i % 2) * 2, 13 + i * 9, 20 + (i % 2) * 2, 2, "steel", round_=True)
    m_arrow_up(ic, 22, 0, "lime")
    return ic


@icon("node_combo")
def node_combo():
    ic = Icon()
    for i, x in enumerate((3, 11, 19)):
        ic.poly([(x, 8), (x + 8, 16), (x, 24), (x + 3, 16)], ("yellow", "orange", "red")[i])
    return ic


@icon("node_speed")
def node_speed():
    ic = Icon()
    m_boot(ic, 11, 7, "cyan", "white")
    for y in (9, 14, 19):
        ic.line([(1, y), (9, y)], "sky", flat=True)
    return ic


@icon("node_heal")
def node_heal():
    ic = Icon()
    ic.rect(11, 3, 20, 28, "red")
    ic.rect(3, 11, 28, 20, "red")
    ic.rect(13, 5, 18, 26, "white", flat=True)
    ic.rect(5, 13, 26, 18, "white", flat=True)
    return ic


# META upgrades (permanent).
@icon("meta_strength")
def meta_strength():
    ic = Icon()
    ic.rect(2, 13, 30, 18, "steel")
    for x in (3, 7, 22, 26):
        ic.rect(x, 7, x + 3, 24, "gun")
    return ic


@icon("meta_fortune")
def meta_fortune():
    ic = Icon()
    for i, (x, y) in enumerate(((3, 18), (11, 14), (18, 18), (8, 7), (16, 5))):
        ic.ellipse(x, y, x + 11, y + 9, "gold", round_=True)
    ic.glint(19, 7)
    return ic


@icon("meta_shard")
def meta_shard():
    ic = Icon()
    ic.poly([(16, 1), (24, 12), (19, 30), (9, 26), (6, 10)], "violet")
    ic.poly([(16, 1), (24, 12), (15, 15)], "pink", flat=True, tone=1)
    ic.glint(15, 6, True)
    return ic


@icon("meta_scavenger")
def meta_scavenger():
    ic = Icon()
    ic.ellipse(3, 3, 21, 21, "steel", round_=True)
    ic.ellipse(6, 6, 18, 18, "glass", flat=True)
    ic.line([(18, 18), (28, 28)], "wood", width=4)
    return ic


@icon("meta_starter")
def meta_starter():
    ic = Icon()
    ic.rect(3, 12, 28, 28, "red")
    ic.rect(11, 6, 20, 12, "gun")
    ic.rect(13, 8, 18, 12, "red", flat=True)
    ic.rect(3, 17, 28, 19, "black")
    ic.rect(14, 15, 17, 21, "steel")
    return ic


@icon("meta_life")
def meta_life():
    ic = Icon()
    m_heart(ic, 4, 4, 2.0, "pink")
    ic.rect(13, 10, 18, 22, "white", flat=True)
    ic.rect(10, 13, 21, 18, "white", flat=True)
    return ic


@icon("meta_amount")
def meta_amount():
    ic = Icon()
    for i, y in enumerate((5, 13, 21)):
        ic.poly([(4 + i * 2, y), (20 + i * 2, y + 2), (4 + i * 2, y + 5)], "steel")
        ic.rect(1 + i * 2, y + 1, 4 + i * 2, y + 4, "brass")
    m_plus(ic, 22, 12)
    return ic


@icon("meta_reroll")
def meta_reroll():
    ic = Icon()
    ic.rect(6, 6, 25, 25, "white")
    for (x, y) in ((9, 9), (19, 9), (14, 14), (9, 19), (19, 19)):
        ic.ellipse(x, y, x + 3, y + 3, "red", flat=True)
    ic.arc([1, 1, 30, 30], 200, 320, "cyan", width=2)
    return ic


@icon("meta_banish")
def meta_banish():
    ic = Icon()
    ic.rect(7, 4, 24, 27, "paper")
    ic.ellipse(4, 4, 27, 27, "red", round_=True)
    ic.ellipse(8, 8, 23, 23, "paper", flat=True)
    ic.line([(9, 22), (22, 9)], "red", width=3)
    return ic


@icon("meta_revival")
def meta_revival():
    ic = Icon()
    ic.poly([(16, 2), (29, 14), (21, 14), (21, 29), (11, 29), (11, 14), (3, 14)], "gold")
    ic.rect(13, 16, 18, 26, "white", flat=True)
    return ic


@icon("meta_greed")
def meta_greed():
    ic = Icon()
    ic.ellipse(4, 9, 27, 29, "brown", round_=True)
    ic.rect(10, 5, 21, 10, "brown", tone=-1)
    ic.line([(9, 9), (22, 9)], "gold", width=2)
    ic.ellipse(11, 15, 20, 24, "mint", round_=True)
    return ic


# --- survivor abilities, traits, items, ultimates (overwrite survive/) ----

@icon("invoice", True)
def s_invoice():
    ic = Icon()
    m_paper(ic, 7, 3, 24, 28)
    ic.rect(10, 6, 18, 8, "red", flat=True)
    ic.rect(15, 22, 22, 25, "red", flat=True)
    ic.line([(27, 5), (30, 2)], "white", flat=True)
    return ic


@icon("stapler", True)
def s_stapler():
    return stapler_orbit()


@icon("coffee", True)
def s_coffee():
    ic = Icon()
    ic.rect(7, 10, 22, 28, "white")
    ic.rect(7, 10, 22, 13, "brown", flat=True)
    ic.arc([18, 14, 28, 24], 270, 90, "white", width=2)
    for x in (10, 15):
        ic.line([(x, 7), (x + 1, 4), (x, 1)], "ghost", flat=True)
    ic.rect(10, 17, 19, 22, "red", flat=True)
    return ic


@icon("clipboard", True)
def s_clipboard():
    ic = Icon()
    ic.rect(6, 4, 25, 29, "wood")
    m_paper(ic, 8, 8, 23, 27)
    ic.rect(12, 2, 19, 7, "steel")
    return ic


@icon("bolt", True)
def s_bolt():
    ic = Icon()
    m_bolt(ic, 8, 2, "yellow")
    ic.pixels([(4, 8), (26, 14), (6, 24)], "white", 4)
    return ic


@icon("wave", True)
def s_wave():
    ic = Icon()
    for i, mat in enumerate(("cyan", "sky", "blue")):
        ic.arc([2 + i * 3, 6 + i * 3, 30 - i * 3, 30 - i * 3], 200, 340, mat, width=2)
    ic.ellipse(12, 18, 20, 26, "skin", round_=True)
    return ic


@icon("note", True)
def s_note():
    ic = Icon()
    ic.ellipse(4, 20, 12, 28, "violet", round_=True)
    ic.ellipse(18, 17, 26, 25, "violet", round_=True)
    ic.rect(10, 5, 12, 24, "violet")
    ic.rect(24, 3, 26, 21, "violet")
    ic.poly([(10, 5), (26, 2), (26, 7), (10, 10)], "violet")
    return ic


@icon("mine", True)
def s_mine():
    ic = Icon()
    ic.ellipse(4, 14, 27, 28, "gun", round_=True)
    ic.rect(13, 9, 18, 15, "steel")
    ic.ellipse(14, 6, 17, 9, "red", flat=True, tone=2)
    m_magnet(ic, 9, 17)
    return ic


@icon("camera", True)
def s_camera():
    ic = Icon()
    ic.rect(3, 10, 28, 26, "gun")
    ic.rect(8, 6, 15, 10, "gun")
    ic.ellipse(10, 11, 23, 24, "steel", round_=True)
    ic.ellipse(13, 14, 20, 21, "glass", round_=True)
    ic.rect(22, 7, 26, 10, "yellow")
    ic.pixels([(24, 4), (27, 3), (21, 3)], "yellow", 4)
    return ic


@icon("drip", True)
def s_drip():
    return drip_feed()


@icon("cart", True)
def s_cart():
    return cart_hop()


@icon("bag", True)
def s_bag():
    ic = Icon()
    ic.ellipse(4, 9, 27, 29, "black", round_=True)
    ic.poly([(12, 9), (20, 9), (22, 4), (10, 4)], "black")
    ic.line([(10, 4), (22, 4)], "yellow", width=2)
    ic.glint(9, 14)
    ic.pixels([(16, 20), (17, 21)], "slate", 3)
    return ic


@icon("hydrant", True)
def s_hydrant():
    ic = Icon()
    ic.rect(9, 10, 19, 28, "red")
    ic.rect(6, 14, 22, 18, "red", tone=-1)
    ic.ellipse(9, 6, 19, 13, "red", round_=True)
    ic.rect(12, 3, 16, 6, "steel")
    ic.rect(7, 27, 21, 29, "gun")
    for i in range(3):
        ic.line([(22, 16), (30, 10 + i * 4)], "sky", flat=True)
    return ic


@icon("mailbomb", True)
def s_mailbomb():
    ic = Icon()
    ic.rect(4, 11, 27, 27, "cream")
    ic.line([(4, 11), (16, 20), (27, 11)], "brown", flat=True)
    ic.line([(22, 10), (26, 3)], "white")
    ic.pixels([(26, 2), (27, 1)], "fire", 4)
    ic.rect(7, 22, 12, 25, "red", flat=True)
    return ic


@icon("sprinkler", True)
def s_sprinkler():
    ic = Icon()
    ic.rect(14, 14, 17, 29, "green")
    ic.ellipse(11, 10, 20, 16, "steel", round_=True)
    for a in ((15, 10, 4, 3), (16, 10, 28, 3), (15, 10, 2, 12), (16, 10, 29, 12)):
        ic.line([a[:2], a[2:]], "sky", flat=True)
    return ic


@icon("audit", True)
def s_audit():
    ic = Icon()
    m_paper(ic, 3, 3, 20, 26)
    ic.ellipse(13, 12, 26, 25, "steel", round_=True)
    ic.ellipse(15, 14, 24, 23, "glass", flat=True)
    ic.line([(24, 23), (29, 28)], "wood", width=3)
    return ic


@icon("gravy", True)
def s_gravy():
    ic = Icon()
    ic.ellipse(1, 22, 30, 30, "brown", tone=-1)
    ic.poly([(3, 10), (22, 10), (28, 6), (26, 13), (20, 20), (8, 20)], "white", round_=True)
    ic.ellipse(4, 8, 22, 13, "brown", flat=True)
    ic.arc([0, 9, 9, 19], 90, 270, "white", width=2)
    ic.poly([(27, 7), (30, 12), (29, 24), (27, 24)], "brown")
    ic.rect(10, 20, 16, 22, "white", tone=-1)
    return ic


@icon("evolve", True)
def s_evolve():
    ic = Icon()
    m_arrow_up(ic, 11, 1, "gold")
    m_star(ic, 16, 21, 9, "violet")
    return ic


@icon("name_badge", True)
def s_name_badge():
    ic = Icon()
    ic.rect(4, 8, 27, 25, "white")
    ic.rect(4, 8, 27, 13, "red")
    ic.rect(7, 16, 24, 18, "slate", flat=True)
    ic.rect(7, 20, 18, 21, "slate", flat=True)
    ic.rect(13, 3, 18, 8, "steel")
    ic.arc([1, 1, 30, 30], 200, 320, "cyan", width=1, flat=True)
    ic.poly([(26, 2), (30, 6), (25, 7)], "cyan")
    return ic


@icon("shredder", True)
def s_shredder():
    ic = Icon()
    import math
    pts = []
    for i in range(16):
        a = i * math.pi / 8
        rr = 14 if i % 2 == 0 else 10
        pts.append((16 + math.cos(a) * rr, 16 + math.sin(a) * rr))
    ic.poly(pts, "steel", round_=True)
    ic.ellipse(11, 11, 20, 20, "gun", round_=True)
    ic.ellipse(14, 14, 17, 17, "ink", flat=True)
    ic.pixels([(4, 26), (27, 5), (2, 6)], "paper", 3)
    return ic


@icon("fax_beam", True)
def s_fax_beam():
    ic = Icon()
    ic.rect(2, 12, 16, 26, "grey")
    ic.rect(4, 9, 14, 12, "paper")
    ic.rect(4, 15, 9, 17, "ink", flat=True)
    ic.rect(15, 15, 18, 21, "red")
    ic.rect(18, 16, 30, 20, "red", flat=True, tone=2)
    ic.rect(18, 17, 30, 19, "white", flat=True)
    return ic


@icon("rubber_stamp", True)
def s_rubber_stamp():
    ic = Icon()
    ic.ellipse(11, 1, 21, 10, "wood", round_=True)
    ic.rect(14, 9, 18, 15, "wood")
    ic.rect(6, 15, 26, 21, "black")
    ic.rect(5, 21, 27, 24, "red")
    ic.rect(3, 26, 29, 30, "red", flat=True, tone=-1)
    ic.rect(6, 27, 26, 28, "paper", flat=True)
    return ic


@icon("nail_driver", True)
def s_nail_driver():
    ic = Icon()
    ic.rect(4, 8, 22, 15, "yellow")
    ic.rect(22, 10, 27, 13, "gun")
    ic.poly([(7, 15), (13, 15), (11, 26), (5, 26)], "black")
    for x in (24, 28):
        ic.line([(x + 2, 11), (x + 5, 11)], "steel", flat=True, tone=2)
    ic.rect(8, 16, 18, 18, "steel")
    return ic


@icon("paperweight", True)
def s_paperweight():
    ic = Icon()
    ic.ellipse(4, 8, 27, 29, "glass", round_=True)
    ic.ellipse(10, 15, 21, 25, "violet", round_=True)
    ic.ellipse(13, 18, 18, 22, "pink", flat=True)
    ic.rect(4, 25, 27, 28, "glass", tone=-1)
    ic.glint(9, 12, True)
    return ic


# Traits.
@icon("t_dmg", True)
def t_dmg():
    ic = Icon()
    m_fist(ic, 9, 5)
    return ic


@icon("t_area", True)
def t_area():
    ic = Icon()
    for r, mat in ((13, "orange"), (9, "fire"), (5, "yellow")):
        ic.ring(16 - r, 16 - r, 16 + r, 16 + r, 2, mat, round_=True)
    return ic


@icon("t_cd", True)
def t_cd():
    ic = Icon()
    m_clock(ic, 4, 4, 12, "sky")
    return ic


@icon("t_proj", True)
def t_proj():
    return meta_amount()


@icon("t_speed", True)
def t_speed():
    return node_speed()


@icon("t_hp", True)
def t_hp():
    return node_hp()


@icon("t_regen", True)
def t_regen():
    ic = Icon()
    m_heart(ic, 3, 3, 1.8, "red")
    ic.arc([12, 12, 30, 30], 270, 180, "lime", width=2)
    ic.poly([(12, 20), (16, 25), (8, 25)], "lime")
    return ic


@icon("t_armor", True)
def t_armor():
    ic = Icon()
    m_shield(ic, 6, 4, "steel", "gold")
    return ic


@icon("t_pickup", True)
def t_pickup():
    ic = Icon()
    m_magnet(ic, 5, 4)
    return ic


@icon("t_crit", True)
def t_crit():
    ic = Icon()
    ic.ring(3, 3, 28, 28, 2, "red", round_=True)
    ic.ring(9, 9, 22, 22, 2, "red", round_=True)
    ic.ellipse(14, 14, 17, 17, "yellow", flat=True, tone=1)
    for (a, b) in (((16, 0), (16, 6)), ((16, 25), (16, 31)), ((0, 16), (6, 16)), ((25, 16), (31, 16))):
        ic.line([a, b], "red", flat=True)
    return ic


@icon("t_xp", True)
def t_xp():
    return cur_xp()


@icon("t_curse", True)
def t_curse():
    ic = Icon()
    m_skull(ic, 7, 3, "violet")
    ic.pixels([(10, 10), (11, 10), (18, 10), (19, 10)], "lime", 4)
    return ic


@icon("t_thorns", True)
def t_thorns():
    ic = Icon()
    ic.ellipse(8, 8, 23, 23, "green", round_=True)
    import math
    for i in range(8):
        a = i * math.pi / 4
        ic.poly([(16 + math.cos(a) * 6, 16 + math.sin(a) * 6), (16 + math.cos(a + 0.35) * 6, 16 + math.sin(a + 0.35) * 6), (16 + math.cos(a + 0.17) * 14, 16 + math.sin(a + 0.17) * 14)], "jade")
    return ic


@icon("t_luck", True)
def t_luck():
    ic = Icon()
    m_clover(ic, 4, 2)
    return ic


@icon("t_vamp", True)
def t_vamp():
    ic = Icon()
    ic.ellipse(4, 4, 27, 23, "white", round_=True)
    ic.poly([(9, 18), (12, 18), (10, 26)], "white")
    ic.poly([(19, 18), (22, 18), (21, 26)], "white")
    ic.rect(6, 14, 25, 17, "blood", flat=True)
    m_drop(ic, 18, 20, "blood")
    return ic


# Items.
@icon("i_coin", True)
def i_coin():
    ic = cur_gold()
    m_clover(ic, 18, 16)
    return ic


@icon("i_card", True)
def i_card():
    ic = Icon()
    ic.rect(3, 7, 28, 25, "blue")
    ic.rect(3, 10, 28, 12, "black", flat=True)
    ic.rect(6, 16, 12, 21, "gold")
    ic.rect(18, 20, 25, 21, "white", flat=True)
    ic.glint(5, 8)
    return ic


@icon("i_ticket", True)
def i_ticket():
    ic = Icon()
    ic.rect(3, 9, 28, 23, "orange")
    for y in (9, 23):
        for x in range(4, 28, 3):
            ic.erase([(x, y)])
    ic.line([(20, 10), (20, 22)], "orange", flat=True, tone=-1)
    ic.rect(6, 13, 16, 15, "paper", flat=True)
    ic.rect(6, 17, 13, 19, "paper", flat=True)
    return ic


@icon("i_amulet", True)
def i_amulet():
    ic = Icon()
    ic.arc([6, 0, 26, 18], 0, 180, "gold", flat=True)
    m_heart(ic, 9, 13, 1.2, "pink")
    return ic


@icon("i_bell", True)
def i_bell():
    ic = Icon()
    ic.ellipse(5, 7, 26, 26, "steel", round_=True)
    ic.rect(4, 22, 27, 25, "gun")
    ic.rect(14, 3, 17, 8, "gun")
    ic.rect(22, 9, 29, 12, "red")
    ic.glint(10, 11, True)
    return ic


@icon("i_thermos", True)
def i_thermos():
    ic = Icon()
    ic.rect(9, 7, 22, 29, "red")
    ic.rect(10, 3, 21, 7, "steel")
    ic.rect(9, 13, 22, 15, "steel")
    ic.rect(9, 24, 22, 26, "steel")
    ic.glint(11, 9)
    return ic


@icon("i_shirt", True)
def i_shirt():
    ic = Icon()
    m_jacket(ic, "pink", "skin")
    for (x, y) in ((10, 17), (20, 21), (13, 25), (21, 14)):
        ic.ellipse(x - 1, y - 1, x + 1, y + 1, "yellow", flat=True)
    return ic


@icon("i_tooth", True)
def i_tooth():
    ic = Icon()
    ic.poly([(6, 6), (26, 6), (25, 17), (22, 29), (18, 20), (14, 20), (10, 29), (7, 17)], "brass")
    ic.glint(10, 9, True)
    return ic


@icon("i_glove", True)
def i_glove():
    ic = Icon()
    m_fist(ic, 9, 7, "red")
    m_magnet(ic, 19, 1)
    return ic


@icon("i_mug", True)
def i_mug():
    ic = Icon()
    ic.rect(6, 8, 22, 28, "black")
    ic.arc([17, 12, 28, 24], 270, 90, "black", width=2)
    ic.poly([(9, 8), (12, 8), (11, 14)], "white")
    ic.poly([(15, 8), (18, 8), (17, 14)], "white")
    m_drop(ic, 9, 15, "blood")
    return ic


@icon("i_hands", True)
def i_hands():
    ic = Icon()
    for x, mat in ((2, "skin"), (16, "skin")):
        ic.rect(x, 12, x + 12, 24, mat)
        for i in range(4):
            ic.rect(x + i * 3, 5 + (i % 2), x + i * 3 + 2, 13, mat)
    m_plus(ic, 12, 22)
    return ic


@icon("i_receipt", True)
def i_receipt():
    ic = Icon()
    ic.ellipse(4, 3, 27, 13, "paper")
    ic.rect(8, 8, 23, 29, "paper")
    for y in (13, 16, 19, 22):
        ic.line([(10, y), (20, y)], "slate", flat=True)
    ic.poly([(8, 29), (11, 27), (14, 29), (17, 27), (20, 29), (23, 27)], "paper")
    return ic


# Ultimates.
@icon("u_crash", True)
def u_crash():
    ic = Icon()
    ic.rect(3, 11, 21, 23, "steel")
    for x in range(6, 21, 4):
        ic.line([(x, 12), (x, 22)], "gun", flat=True)
    for x in (5, 16):
        ic.ellipse(x, 22, x + 5, 27, "black", round_=True)
    m_star(ic, 25, 10, 7, "yellow")
    return ic


@icon("u_dome", True)
def u_dome():
    ic = Icon()
    ic.ellipse(2, 6, 29, 33, "cyan", round_=True)
    ic.ellipse(5, 9, 26, 30, "navy", flat=True)
    ic.erase_rect(0, 24, 31, 31)
    ic.rect(1, 24, 30, 27, "steel")
    ic.ellipse(12, 13, 19, 20, "skin", round_=True)
    return ic


@icon("u_friday", True)
def u_friday():
    ic = Icon()
    ic.rect(6, 10, 25, 29, "black")
    ic.arc([10, 3, 21, 16], 180, 360, "black", width=2)
    ic.rect(9, 15, 22, 21, "red", flat=True)
    ic.pixels([(12, 18), (13, 18), (18, 18), (19, 18)], "white", 4)
    return ic


@icon("tag_bleed")
def tag_bleed():
    ic = Icon()
    ic.poly([(16, 2), (25, 16), (24, 22), (20, 27), (12, 27), (8, 22), (7, 16)], "blood", round_=True)
    ic.glint(12, 12, True)
    ic.ellipse(3, 25, 8, 29, "blood")
    ic.ellipse(24, 24, 29, 28, "blood")
    return ic


@icon("tag_fire")
def tag_fire():
    ic = Icon()
    m_flame(ic, 7, 3, 1.1)
    return ic


# --- 16 px flying coins (rewards fly to the corner counter) -----------------

@icon("cur_gold_s")
def cur_gold_s():
    ic = Icon(16)
    ic.ellipse(2, 3, 13, 14, "brass")
    ic.ellipse(2, 1, 13, 12, "gold", round_=True)
    ic.rect(7, 4, 8, 9, "brass", flat=True)
    ic.glint(4, 3)
    return ic


@icon("cur_gem_s")
def cur_gem_s():
    ic = Icon(16)
    ic.poly([(1, 5), (4, 2), (11, 2), (14, 5), (7.5, 14)], "blue")
    ic.poly([(4, 2), (7.5, 5), (11, 2)], "cyan", flat=True, tone=1)
    ic.poly([(1, 5), (14, 5), (7.5, 14)], "sky", flat=True, tone=-1)
    ic.glint(5, 3)
    return ic


@icon("cur_scoin_s")
def cur_scoin_s():
    ic = Icon(16)
    ic.ellipse(2, 3, 13, 14, "teal")
    ic.ellipse(2, 1, 13, 12, "mint", round_=True)
    ic.line([(10, 4), (6, 4), (6, 6), (9, 7), (9, 9), (5, 9)], "jade", flat=True, tone=-1)
    ic.glint(4, 3)
    return ic


@icon("cur_rep_s")
def cur_rep_s():
    ic = Icon(16)
    ic.poly([(2, 1), (13, 1), (13, 7), (7.5, 14), (2, 7)], "steel")
    ic.rect(6, 4, 9, 8, "white", flat=True)
    return ic


@icon("cur_xp_s")
def cur_xp_s():
    ic = Icon(16)
    ic.poly([(8, 1), (14, 8), (8, 15), (2, 8)], "lime")
    ic.poly([(8, 1), (14, 8), (8, 8)], "mint", flat=True, tone=1)
    ic.glint(7, 4)
    return ic


@icon("cur_flow_s")
def cur_flow_s():
    ic = Icon(16)
    ic.poly([(3, 2), (8, 2), (8, 7), (14, 9), (14, 12), (2, 12)], "cyan")
    ic.rect(1, 12, 14, 14, "white")
    return ic


# --- rewards center -------------------------------------------------------

@icon("cur_gift")
def cur_gift():
    ic = Icon()
    ic.rect(4, 14, 27, 28, "red")
    ic.rect(3, 10, 28, 15, "red", tone=1)
    ic.rect(14, 10, 17, 28, "gold")
    ic.rect(3, 12, 28, 13, "gold", flat=True)
    ic.ellipse(7, 3, 15, 11, "gold")
    ic.ellipse(16, 3, 24, 11, "gold")
    ic.ellipse(10, 5, 13, 9, "red", flat=True)
    ic.ellipse(18, 5, 21, 9, "red", flat=True)
    ic.rect(14, 8, 17, 11, "gold", tone=1)
    ic.glint(6, 16)
    return ic


@icon("cur_power")
def cur_power():
    ic = Icon()
    m_star(ic, 16, 16, r=14, mat="orange")
    m_fist(ic, 9, 9)
    ic.glint(24, 7)
    return ic


@icon("cur_title")
def cur_title():
    ic = Icon()
    ic.poly([(9, 18), (5, 30), (10, 27), (13, 30), (15, 20)], "red")
    ic.poly([(23, 18), (27, 30), (22, 27), (19, 30), (17, 20)], "red")
    ic.ellipse(5, 2, 27, 24, "gold")
    ic.ellipse(9, 6, 23, 20, "brass")
    m_star(ic, 16, 13, r=6, mat="yellow")
    ic.glint(10, 6)
    return ic


@icon("cur_road")
def cur_road():
    ic = Icon()
    ic.rect(14, 4, 17, 30, "wood")
    ic.poly([(4, 6), (24, 6), (28, 10), (24, 14), (4, 14)], "teal")
    ic.poly([(27, 16), (7, 16), (3, 20), (7, 24), (27, 24)], "orange")
    ic.rect(7, 9, 20, 10, "white", flat=True)
    ic.rect(11, 19, 24, 20, "white", flat=True)
    ic.glint(6, 7)
    return ic


@icon("cur_calendar")
def cur_calendar():
    ic = Icon()
    ic.rect(4, 6, 27, 28, "paper")
    ic.rect(4, 6, 27, 12, "red")
    for x in (9, 21):
        ic.rect(x, 3, x + 2, 9, "steel")
    for gy in range(3):
        for gx in range(4):
            ic.rect(7 + gx * 5, 15 + gy * 4, 9 + gx * 5, 16 + gy * 4, "slate", flat=True)
    ic.rect(17, 19, 20, 21, "red", flat=True)
    return ic


# --- sheet header icons (menus) ------------------------------------------

@icon("head_armory")
def head_armory():
    ic = Icon()
    # A bat and a pistol crossed.
    ic.line([(5, 27), (25, 5)], "wood", width=4)
    ic.ellipse(22, 2, 28, 8, "wood")
    ic.rect(4, 25, 8, 29, "black")
    m_gun(ic, 6, 10)
    ic.glint(24, 4)
    return ic


@icon("head_codex")
def head_codex():
    ic = Icon()
    ic.rect(5, 4, 26, 28, "red")
    ic.rect(7, 6, 26, 26, "paper", tone=1)
    ic.rect(5, 4, 8, 28, "red", tone=-1)
    ic.ellipse(12, 9, 22, 19, "gold")
    m_skull(ic, 13, 10)
    ic.rect(11, 22, 23, 23, "slate", flat=True)
    ic.glint(9, 6)
    return ic


@icon("head_moves")
def head_moves():
    ic = Icon()
    m_fist(ic, 4, 8)
    m_boot(ic, 15, 14)
    ic.line([(2, 24), (10, 20)], "white", width=1)
    ic.line([(2, 28), (12, 25)], "white", width=1)
    ic.glint(25, 12)
    return ic


@icon("head_heroes")
def head_heroes():
    ic = Icon()
    # Two heads, Dad bigger behind the Kid.
    ic.ellipse(3, 5, 17, 19, "skin")
    ic.ellipse(3, 2, 17, 10, "brown")
    ic.rect(2, 19, 18, 29, "steel")
    ic.ellipse(14, 10, 27, 23, "skin")
    ic.ellipse(14, 8, 27, 14, "brown", tone=1)
    ic.rect(13, 22, 28, 30, "black")
    ic.glint(22, 13)
    return ic


@icon("head_build")
def head_build():
    ic = Icon()
    # A skill tree: trunk and three lit nodes.
    ic.line([(16, 29), (16, 8)], "wood", width=2)
    ic.line([(16, 18), (7, 11)], "wood", width=2)
    ic.line([(16, 18), (25, 11)], "wood", width=2)
    for x, y in ((16, 6), (6, 10), (26, 10)):
        ic.ellipse(x - 4, y - 4, x + 4, y + 4, "gold")
    ic.ellipse(12, 24, 20, 31, "lime")
    ic.glint(15, 4)
    return ic


@icon("head_options")
def head_options():
    ic = Icon()
    import math
    pts = []
    for i in range(16):
        a = i * math.pi / 8
        r = 14 if i % 2 == 0 else 10
        pts.append((16 + r * math.cos(a), 16 + r * math.sin(a)))
    ic.poly(pts, "steel")
    ic.ellipse(10, 10, 22, 22, "gun")
    ic.ellipse(13, 13, 19, 19, "black", flat=True)
    ic.glint(9, 7)
    return ic


@icon("head_stats")
def head_stats():
    ic = Icon()
    ic.rect(3, 27, 29, 29, "slate")
    for i, (h, m) in enumerate(((8, "red"), (14, "orange"), (20, "gold"), (11, "lime"))):
        x = 5 + i * 6
        ic.rect(x, 27 - h, x + 4, 27, m)
    ic.line([(5, 16), (11, 10), (17, 13), (25, 4)], "white", width=1)
    ic.glint(25, 4)
    return ic


@icon("head_jobs")
def head_jobs():
    ic = Icon()
    ic.rect(6, 5, 26, 29, "wood")
    m_paper(ic, 8, 8, 24, 27)
    ic.rect(12, 3, 20, 7, "steel")
    ic.pixels([(10, 12), (10, 17), (10, 22)], "lime", step=1)
    return ic


@icon("head_log")
def head_log():
    ic = Icon()
    ic.rect(6, 3, 26, 29, "sky")
    ic.rect(8, 5, 26, 27, "paper", tone=1)
    for y in (6, 11, 16, 21, 26):
        ic.rect(4, y, 8, y + 1, "steel")
    ic.line([(12, 10), (23, 10)], "slate")
    ic.line([(12, 15), (23, 15)], "slate")
    ic.line([(12, 20), (19, 20)], "slate")
    ic.line([(22, 29), (29, 18)], "yellow", width=2)
    return ic


@icon("head_gear")
def head_gear():
    ic = Icon()
    # The hoodie on its hanger.
    ic.line([(16, 2), (16, 6)], "steel")
    ic.line([(5, 10), (16, 5), (27, 10)], "steel", width=1)
    ic.poly([(6, 10), (26, 10), (30, 20), (25, 21), (24, 29), (8, 29), (7, 21), (2, 20)], "steel", tone=1)
    ic.ellipse(11, 8, 21, 16, "gun")
    ic.rect(13, 19, 19, 24, "gun", tone=-1)
    ic.glint(9, 13)
    return ic


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    made = []
    for name, fn in ICONS.items():
        made.append(fn().save(OUT / f"{name}.png"))
    surv = []
    for name, fn in SURV_ICONS.items():
        surv.append(fn().save(SURV / f"{name}.png"))
    # Empty gun slots: a dim silhouette of that slot's typical part.
    from PIL import Image
    for slot, part in (("muzzle", "suppressor"), ("optic", "red_dot"), ("barrel", "long_barrel"), ("mag", "ext_mag"), ("ammo", "hollow")):
        im = Image.open(OUT / f"part_{part}.png").convert("RGBA")
        px = im.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g, b, a = px[x, y]
                if a:
                    l = (r * 3 + g * 5 + b * 2) // 10
                    px[x, y] = (40 + l // 4, 46 + l // 4, 62 + l // 3, a)
        im.save(OUT / f"slot_{slot}.png")
    print(f"icons {len(made)}  survive {len(surv)}")
    if "--sheet" in sys.argv:
        sheet(made, "/tmp/claude-0/icons/pack.png", scale=3, cols=16)
        sheet(surv, "/tmp/claude-0/icons/surv.png", scale=3, cols=16)


if __name__ == "__main__":
    main()
