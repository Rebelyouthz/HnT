#!/usr/bin/env python3
"""Crew stills in the hideout style (like assets/sprites/crew/benny.png):
a full-body pixel-art character standing three-quarter front, keyed off a
flat green screen, trimmed and brought to 240 px tall. FLUX.1-schnell on an
HF ZeroGPU space.  python3 tools/crew_still.py <who> [--keep DIR] [--seed N]"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/sprites/crew"
STYLE = ("detailed 16-bit pixel art game character sprite, full body from head to boots, standing in a relaxed three-quarter front view, "
         "isolated on a flat solid pure green background, no shadow, no floor, no text, crisp pixels, warm rim light")
WHO = {
	"ember": "a cool young woman blacksmith in her twenties, red and black undercut hair tied back, welding goggles pushed up on her head, "
	         "sleeveless black top, heavy brown leather apron with tools in the pockets, tattooed muscular arms, thick work gloves, cargo pants and steel-toe boots, "
	         "a big smithing hammer resting on her shoulder, confident grin",
	"vendor": "a friendly scruffy street vendor man in his fifties with a grey stubble, a flat cap, a padded green vest over a checkered shirt, "
	          "fingerless gloves, a money pouch on his belt and an apron, holding a small cash box",
}


def key(im: Image.Image) -> Image.Image:
	"""Flood the greenish backdrop (and its soft floor shadow) in from the
	borders; green inside the outline (a vest) is not connected, so stays."""
	from scipy import ndimage
	a = np.asarray(im.convert("RGB")).astype(np.int16)
	r, g, b = a[..., 0], a[..., 1], a[..., 2]
	greenish = (g > r + 12) & (g > b + 25)
	lab, n = ndimage.label(greenish)
	edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
	bg = np.isin(lab, list(edge))
	# Pockets of backdrop shut in between an arm and the body: anything
	# close to the backdrop colour goes too (a dark green vest does not).
	border = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
	ref = np.median(border, axis=0)
	bg |= np.abs(a - ref).sum(axis=2) < 70
	# One pixel of erosion eats the green fringe on the outline.
	bg = ndimage.binary_dilation(bg, iterations=1)
	alpha = np.where(bg, 0, 255).astype(np.uint8)
	out = Image.fromarray(np.dstack([a.astype(np.uint8), alpha]), "RGBA")
	ys, xs = np.where(alpha > 0)
	return out.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def main() -> None:
	who = sys.argv[1]
	keep = Path(sys.argv[sys.argv.index("--keep") + 1]) if "--keep" in sys.argv else Path("/tmp")
	seed = int(sys.argv[sys.argv.index("--seed") + 1]) if "--seed" in sys.argv else 7
	src = keep / f"crew_{who}_{seed}.webp"
	if not src.exists():
		from gradio_client import Client
		c = Client("black-forest-labs/FLUX.1-schnell")
		path, _ = c.predict(WHO[who] + ", " + STYLE, seed, False, 768, 1024, 4, api_name="/infer")
		shutil.copy(path, src)
	cut = key(Image.open(src))
	w = int(round(cut.width * 240 / cut.height))
	cut = cut.resize((w, 240), Image.LANCZOS)
	OUT.mkdir(parents=True, exist_ok=True)
	cut.save(OUT / f"{who}.png")
	print(who, cut.size)


if __name__ == "__main__":
	main()
