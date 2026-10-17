#!/usr/bin/env python3
"""Smashable pixel-art props for the pixel BONE YARD maps: FLUX.1-schnell
(HF ZeroGPU) paints one object on a flat magenta screen, it is snapped to
its pixel grid, keyed, trimmed, brought to its height in texels and blown
up 4x with nearest, so at SpriteBook.DRAW_SCALE one art texel is ~0.9 world
units, close to the pixel backdrops (1.03).

    python3 tools/pixel_props.py [--keep DIR] [name ...]
Writes assets/sprites/yard/props/<name>.png (SpriteBook.prop finds them).
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import backdrop as B  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/sprites/yard/props"
STYLE = ("highly detailed 16-bit pixel art game sprite of a single object, side view, centered, the whole object in frame, "
         "isolated on a flat solid pure magenta background, no shadow on the background, no floor, no people, no text, "
         "night lighting with a cool rim light, crisp pixels")
# name: (texels tall, prompt)
PROPS = {
	"yard_barricade": (46, "a striped black and yellow police sawhorse barricade with a flashing amber lamp"),
	"yard_gargoyle": (66, "a grim stone gargoyle statue crouching on a cracked stone pedestal"),
	"yard_gurney": (48, "a rusty old asylum hospital gurney with leather straps and a stained sheet"),
	"yard_meat_crate": (44, "a wooden crate full of ice and raw meat cuts, dripping"),
	"yard_butcher_block": (50, "a heavy blood-stained wooden butcher block table with a cleaver stuck in it"),
	"yard_hook_cart": (74, "a steel rolling rack with two hanging meat carcasses on hooks"),
	"yard_neon_vending": (90, "a cyberpunk vending machine glowing pink and cyan with a cracked screen"),
	"yard_noodle_cart": (72, "a cyberpunk street noodle cart with a steaming pot, glowing lanterns and a small neon sign"),
	"heavy_bag": (128, "a worn red leather freestanding punching bag on a round black weighted base, duct tape patches, side view"),
	"yard_holo_bin": (54, "a futuristic metal trash bin with a small glowing cyan hologram above it and cables"),
}


SEEDS = {"yard_barricade": 171, "yard_hook_cart": 175, "yard_noodle_cart": 177}


def key_out(rgb: np.ndarray) -> np.ndarray:
	"""Magenta screen to alpha: anything close to the corner colour goes."""
	c = np.median(np.concatenate([rgb[:4, :4].reshape(-1, 3), rgb[-4:, -4:].reshape(-1, 3), rgb[:4, -4:].reshape(-1, 3), rgb[-4:, :4].reshape(-1, 3)]), axis=0)
	d = np.abs(rgb.astype(np.int16) - c.astype(np.int16)).sum(axis=2)
	r, g, b = (rgb[:, :, i].astype(np.int16) for i in range(3))
	# The screen and the magenta-tinted shadow it casts under the object.
	mag = (r - g > 45) & (b - g > 35)
	a = np.where((d < 90) | mag, 0, 255).astype(np.uint8)
	return np.dstack([rgb, a])


def main() -> None:
	args = sys.argv[1:]
	keep = None
	if "--keep" in args:
		i = args.index("--keep")
		keep = Path(args[i + 1])
		del args[i:i + 2]
	names = args or list(PROPS)
	OUT.mkdir(parents=True, exist_ok=True)
	from gradio_client import Client
	c = Client("black-forest-labs/FLUX.1-schnell")
	for k, name in enumerate(names):
		tall, prompt = PROPS[name]
		src = keep / f"{name}.webp" if keep else None
		if src is None or not src.exists():
			path, _ = c.predict(prompt + ", " + STYLE, SEEDS.get(name, 71 + k), False, 1024, 1024, 4, api_name="/infer")
			if keep:
				keep.mkdir(parents=True, exist_ok=True)
				shutil.copy(path, src)
			else:
				src = Path(path)
		im = Image.open(src).convert("RGB")
		gray = np.asarray(im).astype(np.float32).mean(axis=2)
		px, ox = B.grid(gray, 1)
		py, oy = B.grid(gray, 0)
		if not (3.0 <= px <= 8.0):
			px, ox = 4.0, 0.0
		if not (3.0 <= py <= 8.0):
			py, oy = px, 0.0
		nat = B.snap(np.asarray(im), px, ox, py, oy).astype(np.uint8)
		rgba = key_out(nat)
		ys, xs = np.where(rgba[:, :, 3] > 0)
		if ys.size == 0:
			print("EMPTY", name)
			continue
		rgba = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
		obj = Image.fromarray(rgba, "RGBA")
		w = max(1, int(round(obj.width * tall / obj.height)))
		obj = obj.resize((w, tall), Image.NEAREST).resize((w * 4, tall * 4), Image.NEAREST)
		obj.save(OUT / f"{name}.png")
		print("prop", name, obj.size, flush=True)


if __name__ == "__main__":
	main()
