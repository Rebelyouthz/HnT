#!/usr/bin/env python3
"""Pixel-art backdrop strips for whole maps: each section is painted as
pixel art (FLUX.1-schnell on an HF ZeroGPU space), snapped to its true
pixel grid (tools/backdrop.py: period/phase from edge energy, median per
block), brought to one native height with nearest, and laid side by side.
The game draws it with nearest filtering ("pixel": true in the JSON), so
every art pixel stays a crisp square like the rest of the game.

    python3 tools/pixel_strip.py <theme> [--keep DIR]
Writes assets/backdrops/<theme>_strip_0.png (+ _1 ...) and <theme>_strip.json.
"""
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import backdrop as B  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/backdrops"
H = 200          # native strip height (texels)
CHUNK = 4096
SEAM = 24       # texels two sections share at a seam
STYLE = ("highly detailed 16-bit pixel art, side-scrolling beat em up background, straight-on flat front elevation "
         "at street level, night, moody dramatic lighting, glowing lamps and neon reflected in wet ground, rim light, "
         "deep shadows, rich color, crisp pixels, no people, no characters, no text, no letters, no logos, "
         "wet reflective ground strip along the bottom fifth")
THEMES = {
	# BONE YARD map 1: a gothic noir city, from the cave under the mansion to
	# the asylum on the island (original names: Grimhollow, Ashgate).
	"grimhollow": [
		"a secret cave hideout under a mansion: wall of glowing computer screens, a parked black armored car, stalactites, a waterfall, hanging bats, cold blue light",
		"a gothic city street: art deco skyscrapers, stone gargoyles on a cathedral, a huge searchlight beam in the cloudy sky, an elevated train bridge, rain",
		"a rain-soaked gothic downtown block: an old theatre with a glowing marquee, fire escapes, steam rising from manholes, gas lamps, red and amber light",
		"the iron gates of an old victorian asylum on an island at night: stone walls, barbed wire, searchlights, a lightning storm over the towers",
		"inside an old asylum: a long corridor of padded cell doors, flickering green fluorescent lights, broken gurneys, cracked tiles, eerie mist",
	],
	# BONE YARD map 2: the meat district where the debt men hang their bills.
	"butcher_row": [
		"a night meat market street: butcher shop windows glowing red with hanging carcasses on hooks, striped awnings, crates of ice, a refrigerated truck, wet cobbles",
		"a grim slaughterhouse loading dock at night: rows of meat hooks on rails, plastic strip curtains, steam, flickering red neon, stacked pallets, blood drains",
		"a narrow alley behind butcher shops: dumpsters, chained back doors, hanging chains, a bare bulb, rats, puddles reflecting red and teal light",
		"inside a huge cold slaughterhouse hall: hanging carcasses in long rows, chains, steel tables, cold blue fluorescent light, red emergency lamps, fog",
	],
	# BONE YARD map 3: a megacity night market.
	"neon_maze": [
		"a cyberpunk megacity street: towering buildings covered in holographic billboards, pink and cyan neon, flying cars far away, rain",
		"a cyberpunk night market: food stalls under neon canopies, steaming noodle pots, tangled cables, glowing lanterns, purple light",
		"a cyberpunk alley: vending machines, glowing pipes, a holographic koi fish floating, puddles reflecting neon, cyan and magenta",
		"a cyberpunk corporate tower lobby entrance: glass doors, red laser security grid, chrome pillars, holographic guard drones, cold white light",
	],
}


def snap_native(path: str) -> Image.Image:
	im = Image.open(path).convert("RGB")
	# Some paintings come with black letterbox bars: cut them off.
	a = np.asarray(im).astype(np.float32).max(axis=2)
	rows = np.where(a.mean(axis=1) > 6.0)[0]
	if rows.size:
		im = im.crop((0, int(rows[0]), im.width, int(rows[-1]) + 1))
	rgb = np.asarray(im).astype(np.float32)
	gray = rgb.mean(axis=2)
	px, ox = B.grid(gray, 1)
	py, oy = B.grid(gray, 0)
	if not (3.0 <= px <= 7.0):
		px, ox = 4.0, 0.0
	if not (3.0 <= py <= 7.0):
		py, oy = px, 0.0
	nat = B.snap(np.asarray(im), px, ox, py, oy)
	n = Image.fromarray(nat.astype(np.uint8))
	w = int(round(n.width * H / n.height))
	return n.resize((w, H), Image.NEAREST)


def main() -> None:
	theme = sys.argv[1]
	keep = Path(sys.argv[sys.argv.index("--keep") + 1]) if "--keep" in sys.argv else None
	from gradio_client import Client
	c = Client("black-forest-labs/FLUX.1-schnell")
	parts = []
	starts = []
	x = 0
	for i, prompt in enumerate(THEMES[theme]):
		src = keep / f"{theme}_{i}.webp" if keep else None
		if src is None or not src.exists():
			path, _ = c.predict(prompt + ", " + STYLE, 31 + i, False, 1456, 768, 4, api_name="/infer")
			if keep:
				keep.mkdir(parents=True, exist_ok=True)
				shutil.copy(path, src)
			else:
				src = Path(path)
		sec = snap_native(str(src))
		parts.append(sec)
		starts.append([x, f"{theme}_{i}"])
		x += sec.width
		print("section", i, sec.size, flush=True)
	# Sections overlap by SEAM texels and hand over through an ordered
	# (Bayer) dither, so the seams stay pure pixels instead of a hard cut.
	x -= SEAM * (len(parts) - 1)
	strip = np.zeros((H, x, 3), np.uint8)
	bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32) / 16.0 + 1.0 / 32.0
	cx = 0
	for k, p in enumerate(parts):
		arr = np.asarray(p)
		if k == 0:
			strip[:, :p.width] = arr
		else:
			ramp = (np.arange(SEAM, dtype=np.float32) + 0.5) / SEAM
			th = bayer[np.arange(H)[:, None] % 4, np.arange(SEAM)[None, :] % 4]
			take = ramp[None, :] > th
			strip[:, cx:cx + SEAM] = np.where(take[:, :, None], arr[:, :SEAM], strip[:, cx:cx + SEAM])
			strip[:, cx + SEAM:cx + p.width] = arr[:, SEAM:]
		starts[k][0] = cx
		cx += p.width - SEAM
	strip = Image.fromarray(strip)
	widths = []
	for k, x0 in enumerate(range(0, x, CHUNK)):
		piece = strip.crop((x0, 0, min(x, x0 + CHUNK), H))
		piece.save(OUT / f"{theme}_strip_{k}.png")
		widths.append(piece.width)
	meta = {"ground": H - 1, "texel": round(0.26 * 792.0 / H, 4), "parts": widths, "sections": starts, "pixel": True}
	(OUT / f"{theme}_strip.json").write_text(json.dumps(meta))
	print("strip", x, "x", H, "texel", meta["texel"])


if __name__ == "__main__":
	main()
