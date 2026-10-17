#!/usr/bin/env python3
"""FORGE icons as 32x32 pixel art with the same kit as every other icon
(tools/pixkit.py): the four smelted materials (part_<id>), the forged gear
(gear_<id>) and the forge itself (forge_anvil, forge_smelt, forge_hammer).
    python3 tools/forge_icons.py [--sheet]"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pixkit import Icon, sheet  # noqa: E402

OUT = Path(__file__).resolve().parent.parent / "assets/sprites/icons"
ICONS = {}


def icon(name):
	def deco(fn):
		ICONS[name] = fn
		return fn
	return deco


@icon("part_iron_scrap")
def iron_scrap():
	ic = Icon()
	ic.poly([(4, 22), (14, 14), (22, 18), (12, 27)], "steel")
	ic.poly([(14, 10), (26, 6), (28, 14), (18, 17)], "gun")
	ic.rect(8, 6, 13, 13, "rust")
	ic.ring(20, 20, 28, 28, 2, "steel")
	ic.glint(23, 8)
	return ic


@icon("part_leather_strip")
def leather_strip():
	ic = Icon()
	ic.poly([(3, 24), (24, 4), (29, 9), (8, 29)], "leather")
	for i in range(4):
		ic.pixels([(9 + i * 5, 21 - i * 5)], "cream", 1)
	ic.rect(22, 3, 28, 9, "brass")
	return ic


@icon("part_cloth_roll")
def cloth_roll():
	ic = Icon()
	ic.ellipse(4, 8, 14, 26, "denim", round_=True)
	ic.rect(9, 8, 26, 26, "denim")
	ic.ellipse(21, 8, 29, 26, "navy", round_=True)
	ic.ellipse(23, 13, 27, 21, "denim")
	ic.line([(12, 11), (24, 11)], "sky", flat=True)
	ic.line([(12, 22), (24, 22)], "sky", flat=True)
	return ic


@icon("part_ember_core")
def ember_core():
	ic = Icon()
	ic.ellipse(6, 6, 26, 26, "fire", round_=True)
	ic.ellipse(10, 10, 22, 22, "yellow", round_=True)
	ic.ellipse(13, 13, 19, 19, "white", flat=True)
	for x, y in ((4, 16), (16, 3), (28, 16), (16, 29)):
		ic.pixels([(x, y)], "orange", 4)
	return ic


@icon("gear_forged_plate")
def forged_plate():
	ic = Icon()
	ic.poly([(6, 6), (13, 4), (16, 8), (19, 4), (26, 6), (26, 27), (6, 27)], "steel")
	ic.line([(16, 8), (16, 26)], "gun", flat=True)
	for y in (12, 18, 24):
		ic.pixels([(9, y), (23, y)], "brass", 1)
	ic.glint(10, 9)
	return ic


@icon("gear_riveted_jacket")
def riveted_jacket():
	ic = Icon()
	ic.poly([(5, 8), (12, 4), (16, 9), (20, 4), (27, 8), (29, 20), (24, 20), (24, 28), (8, 28), (8, 20), (3, 20)], "leather")
	ic.line([(16, 9), (16, 28)], "black", flat=True)
	for y in (12, 17, 22, 26):
		ic.pixels([(12, y), (20, y)], "steel", 1)
	return ic


@icon("gear_steel_cap")
def steel_cap():
	ic = Icon()
	ic.ellipse(5, 6, 27, 26, "steel", round_=True)
	ic.rect(5, 16, 27, 26, "steel")
	ic.rect(3, 22, 29, 25, "gun")
	ic.line([(16, 6), (16, 22)], "gun", flat=True)
	ic.glint(11, 10)
	return ic


@icon("gear_ember_goggles")
def ember_goggles():
	ic = Icon()
	ic.rect(3, 14, 29, 18, "leather")
	ic.ring(4, 9, 15, 22, 2, "brass")
	ic.ring(17, 9, 28, 22, 2, "brass")
	ic.ellipse(6, 11, 13, 20, "fire", round_=True)
	ic.ellipse(19, 11, 26, 20, "fire", round_=True)
	ic.glint(8, 13)
	ic.glint(21, 13)
	return ic


@icon("gear_iron_toe_boots")
def iron_toe_boots():
	ic = Icon()
	ic.rect(8, 4, 17, 22, "leather")
	ic.poly([(8, 20), (17, 20), (28, 23), (28, 28), (6, 28)], "leather")
	ic.ellipse(20, 21, 29, 28, "steel", round_=True)
	ic.rect(5, 27, 29, 29, "black")
	for y in (8, 12, 16):
		ic.pixels([(12, y)], "cream", 1)
	return ic


@icon("gear_spark_runners")
def spark_runners():
	ic = Icon()
	ic.poly([(6, 14), (16, 12), (28, 20), (28, 26), (4, 26)], "red")
	ic.rect(4, 25, 29, 28, "white")
	ic.line([(10, 17), (20, 17)], "yellow", flat=True)
	for x, y in ((3, 10), (8, 6), (2, 18)):
		ic.pixels([(x, y)], "fire", 4)
	return ic


@icon("forge_anvil")
def anvil():
	ic = Icon()
	ic.poly([(3, 9), (24, 9), (29, 12), (24, 15), (20, 15), (20, 20), (24, 24), (8, 24), (12, 20), (12, 15), (6, 15)], "gun")
	ic.rect(7, 24, 25, 28, "black")
	ic.line([(5, 9), (23, 9)], "steel", flat=True)
	ic.ellipse(14, 4, 20, 8, "fire", round_=True)
	return ic


@icon("forge_smelt")
def smelt():
	ic = Icon()
	ic.poly([(5, 10), (27, 10), (23, 26), (9, 26)], "gun")
	ic.ellipse(7, 7, 25, 13, "fire", round_=True)
	ic.ellipse(10, 8, 22, 11, "yellow", flat=True)
	ic.line([(23, 25), (28, 29)], "steel", width=2)
	return ic


@icon("forge_hammer")
def hammer():
	ic = Icon()
	ic.line([(6, 27), (19, 12)], "wood", width=3)
	ic.rect(14, 3, 28, 12, "steel")
	ic.rect(14, 3, 17, 12, "gun")
	ic.glint(24, 5)
	for x, y in ((6, 8), (9, 4), (4, 13)):
		ic.pixels([(x, y)], "yellow", 4)
	return ic


def main():
	OUT.mkdir(parents=True, exist_ok=True)
	made = []
	for name, fn in ICONS.items():
		p = OUT / f"{name}.png"
		fn().save(p)
		made.append(p)
	print("forge icons", len(made))
	if "--sheet" in sys.argv:
		sheet(made, "/tmp/claude-0/icons/forge.png", scale=6, cols=7)


if __name__ == "__main__":
	main()
