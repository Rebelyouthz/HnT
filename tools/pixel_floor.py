#!/usr/bin/env python3
"""Pixel-art floors for the pixel maps: one painted floor per backdrop
section (FLUX.1-schnell on an HF ZeroGPU space), snapped to its pixel grid,
laid side by side with dithered seams and a wrap seam, so the ground under
the fighters changes with the place behind them (cave rock, cobbles, tram
rails, asylum tiles ...). Writes for WetStreet:

    assets/backdrops/<theme>_floor_road.png      the floor (nearest, texel 1.0296)
    assets/backdrops/<theme>_floor_road_wet.png  where it is wet (puddles reflect)
    assets/backdrops/<theme>_floor_road.json     {"texel": .., "pixel": true}

    python3 tools/pixel_floor.py <theme> [--keep DIR]
Each section is as wide as its backdrop section / 0.9 (the backdrop layer
scrolls at 0.9), so the floors change roughly under the matching place.
"""
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pixel_strip as P  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/backdrops"
H = 210          # texels from the kerb down (215 world units at texel 1.0296)
TEXEL = 1.0296
STYLE = ("highly detailed 16-bit pixel art ground texture for a side-scrolling beat em up, the floor seen from above at a steep angle, "
         "the floor fills the entire frame edge to edge, no walls, no horizon, no sky, no people, no characters, no text, no letters, "
         "night, moody lighting, wet reflective patches, crisp pixels, rich detail")
FLOORS = {
	"grimhollow": [
		"dark wet cave rock floor with shallow puddles, thick black cables and a steel grating walkway, cold blue light",
		"a wide area of many small dark wet gothic cobblestones seen from high above with a round iron manhole cover and puddles reflecting lamps",
		"a wide area of cracked old asphalt seen from high above with two thin rusty tram rails, a steaming grate and amber reflections in puddles",
		"a wide area of muddy gravel and many small broken stone flagstones seen from high above and puddles, cold storm light",
		"cracked filthy hospital floor tiles in pale green and white, grime in the grout, a drain, flickering green light",
	],
	"butcher_row": [
		"a wide area of many small wet cobblestones seen from high above, covered in sawdust and melting ice chips, red neon reflections",
		"stained concrete loading dock floor with a steel drain, dark blood streaks and pallet marks",
		"grimy alley asphalt with puddles, a rusty drain, cigarette butts and red and teal reflections",
		"white slaughterhouse floor tiles smeared with blood, steel floor drains, red stained grout, cold blue light",
	],
	"neon_maze": [
		"glossy black wet asphalt with glowing neon lane markings and puddles reflecting pink and cyan signs",
		"wet stone paving tiles with tangled cables, food stall litter and purple neon reflections",
		"steel grates over wet concrete with glowing cyan puddles and magenta reflections",
		"polished black marble floor with chrome strips and red laser light reflections",
	],
}
SEAM = 24


def section_widths(theme: str) -> list[int]:
	meta = json.loads((OUT / f"{theme}_strip.json").read_text())
	starts = [int(s[0]) for s in meta["sections"]]
	total = sum(int(w) for w in meta["parts"])
	ends = starts[1:] + [total]
	return [int(round((e - s) / 0.9)) for s, e in zip(starts, ends)]


def dither_join(a: np.ndarray, b: np.ndarray) -> np.ndarray:
	"""Last SEAM columns of a hand over to the first SEAM columns of b."""
	bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32) / 16.0 + 1.0 / 32.0
	ramp = (np.arange(SEAM, dtype=np.float32) + 0.5) / SEAM
	th = bayer[np.arange(a.shape[0])[:, None] % 4, np.arange(SEAM)[None, :] % 4]
	take = (ramp[None, :] > th)[:, :, None]
	return np.where(take, b[:, :SEAM], a[:, -SEAM:])


def wet_mask(rgb: np.ndarray) -> np.ndarray:
	"""Puddles: the smooth, flat patches of the painting (low local detail)
	read as standing water; everything else gets a faint damp sheen."""
	g = Image.fromarray(rgb).convert("L")
	a = np.asarray(g).astype(np.float32)
	blur = np.asarray(g.filter(ImageFilter.BoxBlur(3))).astype(np.float32)
	var = np.asarray(Image.fromarray(np.abs(a - blur).astype(np.uint8)).filter(ImageFilter.BoxBlur(4))).astype(np.float32)
	flat = np.clip(1.0 - var / 14.0, 0.0, 1.0)
	m = 0.25 + 0.75 * (flat > 0.55)
	return (m * 255.0).astype(np.uint8)


def main() -> None:
	theme = sys.argv[1]
	keep = Path(sys.argv[sys.argv.index("--keep") + 1]) if "--keep" in sys.argv else None
	widths = section_widths(theme)
	prompts = FLOORS[theme]
	assert len(widths) == len(prompts), (widths, len(prompts))
	from gradio_client import Client
	c = Client("black-forest-labs/FLUX.1-schnell")
	parts = []
	for i, (w, prompt) in enumerate(zip(widths, prompts)):
		src = keep / f"{theme}_floor_{i}.webp" if keep else None
		if src is None or not src.exists():
			path, _ = c.predict(prompt + ", " + STYLE, 51 + i, False, 1680, 832, 4, api_name="/infer")
			if keep:
				keep.mkdir(parents=True, exist_ok=True)
				shutil.copy(path, src)
			else:
				src = Path(path)
		nat = P.snap_native(str(src))   # H 200, aspect kept
		sec = nat.resize((w + SEAM, H), Image.NEAREST)
		parts.append(np.asarray(sec))
		print("floor", i, sec.size, flush=True)
	strip = parts[0]
	for p in parts[1:]:
		strip = np.concatenate([strip[:, :-SEAM], dither_join(strip, p), p[:, SEAM:]], axis=1)
	# Wrap: the end hands over to the start, so the floor repeats seamlessly.
	head = strip[:, :SEAM].copy()
	strip[:, :SEAM] = dither_join(strip, head)
	strip = strip[:, :-SEAM]
	Image.fromarray(strip).save(OUT / f"{theme}_floor_road.png")
	Image.fromarray(wet_mask(strip), "L").save(OUT / f"{theme}_floor_road_wet.png")
	(OUT / f"{theme}_floor_road.json").write_text(json.dumps({"texel": TEXEL, "pixel": True}))
	print("floor", strip.shape[1], "x", H)


if __name__ == "__main__":
	main()
