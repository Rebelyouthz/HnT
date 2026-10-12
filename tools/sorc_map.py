#!/usr/bin/env python3
"""Whole pixel maps from Sorceress (image_generate, gpt-image-2, 3:1): one
painted section per place along the map, a floor for each section and a
sheet of smashable props, all brought to one native pixel grid and drawn
with nearest filtering in the game. Every section after the first gets the
first one as a style reference, so the map reads as one place.

    python3 tools/sorc_map.py <theme> [bg] [floor] [props] [--keep DIR]
Writes assets/backdrops/<theme>_strip_*.png/.json, <theme>_floor_road*.png
/.json and assets/sprites/yard/props/<prop>.png. Images are cached in DIR
so a rerun never pays twice. The key stays in ~/.config/sorceress/key.
"""
from __future__ import annotations

import json
import sys
import time
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parent))
import sorceress as S  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
BD = ROOT / "assets/backdrops"
PROPS_OUT = ROOT / "assets/sprites/yard/props"
H = 240                       # native strip height in texels
TEXEL = round(0.26 * 792.0 / H, 4)
FLOOR_H = int(round(215.0 / TEXEL))
SEAM = 24
MODEL = "gpt-image-2"
BG_STYLE = ("Wide 16-bit pixel art background for a side-scrolling beat 'em up, straight-on flat side view at street level. "
            "The image ends exactly at floor level: the floor of the scene is only a thin sliver at the very bottom edge, no border strip below it. "
            "Night, dramatic lighting, glowing lights reflected on wet ground, rim light, deep shadows, lots of detail, crisp pixels, limited palette, "
            "no people, no characters, no text, no letters, no logos.")
FLOOR_STYLE = ("16-bit pixel art ground texture for a side-scrolling beat 'em up: a wide area of floor seen from high above at a steep angle, "
               "the floor fills the whole frame edge to edge with many small details, no walls, no horizon, no sky, no people, no text, "
               "night lighting, wet reflective patches, crisp pixels, limited palette.")
PROP_STYLE = ("16-bit pixel art game sprites: {n} separate objects laid out in one row, evenly spaced with wide gaps between them, each shown whole "
              "in side view standing on the same baseline, isolated on a flat solid pure green (#00FF00) background, no shadows on the background, "
              "no floor, no people, no text, night lighting with a cool rim light, crisp pixels.")
MAPS = {
	# BONE YARD map 1: the cave under the mansion, out through the waterfall,
	# past the landmarks of the gothic city, to the asylum on the island.
	"grimhollow": {
		"sections": [
			("a huge secret cave hideout under a mansion: a wall of glowing blue computer monitors, a sleek black armored car on a turntable, steel catwalks, stalactites, hanging bats, cold blue light, an underground river running to the right",
			 "dark wet cave rock floor with puddles, black cables and steel grating"),
			("the mouth of the cave seen from inside: a roaring curtain waterfall pouring down in front of the opening, moonlight and city glow shining through the falling water, wet rocks, mist, a narrow rock ledge path leading out",
			 "wet black river rocks and shallow running water with foam"),
			("a gothic city square at night: a huge gothic cathedral with gargoyles and a rose window, a stone bell tower, rain, a giant searchlight beam sweeping the clouds",
			 "dark wet gothic cobblestones with a round iron manhole cover and puddles"),
			("downtown of a gothic art deco city: a towering art deco skyscraper with a glowing crown, a police headquarters with a big searchlight on its roof pointing at the clouds, steam rising from manholes, yellow cabs",
			 "cracked wet asphalt with faded lane lines and a steaming grate"),
			("a grim alley beside an old abandoned theatre with a broken glowing marquee, fire escapes, a single street lamp, scattered pearls of light in puddles, red and amber glow",
			 "dirty wet alley bricks with puddles, litter and a rusty drain"),
			("an elevated train line over a gothic city street: iron girders, a train passing overhead with lit windows, gas lamps, old brick tenements, rain",
			 "wet cobblestones with old iron tram rails and puddles reflecting lamps"),
			("an old iron suspension bridge at night leading across a dark river to an island, the city skyline behind, fog on the water, bridge lamps",
			 "wet iron bridge deck plates with rivets and puddles"),
			("the iron gates of a grim victorian asylum on an island: stone walls, barbed wire, searchlight towers, a lightning storm over the gothic towers",
			 "muddy gravel path with broken stone flagstones and puddles"),
			("the great hall deep inside the asylum: a long corridor of padded cell doors, broken gurneys, flickering green fluorescent lights, chains, a raised stone stage at the end for a boss fight, eerie mist",
			 "cracked filthy hospital floor tiles in pale green and white with grime and a drain"),
		],
		"props": ["yard_barricade", "yard_gargoyle", "yard_gurney", "yard_newsstand", "yard_gas_lamp_crate", "yard_police_cone_set"],
		"props_prompt": "a black and yellow police sawhorse barricade with an amber lamp; a stone gargoyle statue on a pedestal; a rusty asylum hospital gurney with leather straps; a small gothic newspaper stand; a wooden crate of gas lamp parts; a stack of orange traffic cones with a sign",
	},
	# BONE YARD map 3: the megacity, street level up to the corporate tower.
	"neon_maze": {
		"sections": [
			("a cyberpunk megacity street: towering buildings covered in holographic billboards, pink and cyan neon, flying cars far away, rain",
			 "glossy black wet asphalt with glowing neon lane markings and puddles reflecting pink and cyan"),
			("an elevated maglev train station platform in a cyberpunk city: a sleek train with glowing windows, holographic timetables, chrome pillars, cyan light",
			 "polished metal platform tiles with a yellow safety strip and glowing floor lights"),
			("a cyberpunk night market: food stalls under neon canopies, steaming noodle pots, tangled cables, glowing paper lanterns, purple light",
			 "wet stone paving tiles with tangled cables, food stall litter and purple reflections"),
			("a cyberpunk back alley: vending machines, glowing pipes, a giant holographic koi fish floating, puddles reflecting neon, cyan and magenta",
			 "steel grates over wet concrete with glowing cyan puddles"),
			("a cyberpunk skybridge between two towers high above the city: glass walls, the endless neon city far below, drones, wind and rain",
			 "glass and steel walkway panels with glowing edge lights and reflections"),
			("a cyberpunk corporate tower lobby: glass doors, red laser security grid, chrome pillars, holographic guard drones, a raised platform for a boss fight, cold white light",
			 "polished black marble floor with chrome strips and red laser reflections"),
		],
		"props": ["yard_neon_vending", "yard_noodle_cart", "yard_holo_bin", "yard_drone_crate", "yard_neon_barrier", "yard_server_rack"],
		"props_prompt": "a cyberpunk vending machine glowing pink and cyan; a cyberpunk street noodle cart with a steaming pot and lanterns; a futuristic trash bin with a small cyan hologram; a cargo crate with a broken drone on it; a glowing neon road barrier; a sparking server rack cabinet",
	},
}


# World units tall (a fighter is ~115).
PROP_H = {"yard_barricade": 42, "yard_gargoyle": 78, "yard_gurney": 46, "yard_newsstand": 72, "yard_gas_lamp_crate": 40,
          "yard_police_cone_set": 60, "yard_neon_vending": 92, "yard_noodle_cart": 80, "yard_holo_bin": 50, "yard_drone_crate": 46,
          "yard_neon_barrier": 36, "yard_server_rack": 88}


def gen(prompt: str, out: Path, refs: list[str] | None = None, aspect: str = "3:1") -> str:
	"""One image (cached at out); returns its URL (or the cached URL)."""
	meta = out.with_suffix(".url")
	if out.exists() and meta.exists():
		return meta.read_text().strip()
	body = {"model": MODEL, "prompt": prompt, "aspectRatio": aspect}
	if refs:
		body["refImages"] = refs
	r = S.call("image_generate", body)
	jid = (r.get("data") or r).get("jobId")
	if not jid:
		raise SystemExit("image_generate failed: %s" % str(r.get("error", ""))[:300])
	j = S.job(jid, every=5)
	d = j.get("data") or j
	url = d.get("imageUrl") or (d.get("images") or [{}])[0].get("url")
	if not url:
		raise SystemExit("no image: %s" % json.dumps(d)[:300])
	for tries in range(5):
		try:
			with urllib.request.urlopen(url, timeout=300) as f:
				out.write_bytes(f.read())
			break
		except OSError as e:
			print("  download retry", tries + 1, str(e)[:80], flush=True)
			time.sleep(4 * (tries + 1))
	meta.write_text(url)
	print("  gen", out.name, "credits", d.get("creditsCharged", "?"), flush=True)
	return url


def to_native(path: Path, h: int) -> Image.Image:
	"""Area-average down to the native grid, then a small shared palette so
	every texel is a clean flat pixel."""
	im = Image.open(path).convert("RGB")
	w = int(round(im.width * h / im.height))
	im = im.resize((w, h), Image.BOX)
	return im.quantize(colors=96, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")


def dither_join(a: np.ndarray, b: np.ndarray) -> np.ndarray:
	bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], np.float32) / 16.0 + 1.0 / 32.0
	ramp = (np.arange(SEAM, dtype=np.float32) + 0.5) / SEAM
	th = bayer[np.arange(a.shape[0])[:, None] % 4, np.arange(SEAM)[None, :] % 4]
	return np.where((ramp[None, :] > th)[:, :, None], b[:, :SEAM], a[:, -SEAM:])


def join(parts: list[np.ndarray]) -> tuple[np.ndarray, list[int]]:
	strip = parts[0]
	starts = [0]
	for p in parts[1:]:
		starts.append(strip.shape[1] - SEAM)
		strip = np.concatenate([strip[:, :-SEAM], dither_join(strip, p), p[:, SEAM:]], axis=1)
	return strip, starts


def do_bg(theme: str, keep: Path) -> None:
	spec = MAPS[theme]["sections"]
	parts = []
	ref = None
	for i, (scene, _) in enumerate(spec):
		out = keep / f"{theme}_bg_{i}.png"
		url = gen(scene + ". " + BG_STYLE + (" Match the pixel art style, palette and lighting of the reference image exactly." if ref else ""), out, [ref] if ref else None)
		ref = ref or url
		parts.append(np.asarray(to_native(out, H)))
		print("section", i, parts[-1].shape[1], flush=True)
	strip, starts = join(parts)
	for old in BD.glob(f"{theme}_strip_*.png"):
		old.unlink()
	widths = []
	for k, x0 in enumerate(range(0, strip.shape[1], 4096)):
		piece = strip[:, x0:x0 + 4096]
		Image.fromarray(piece).save(BD / f"{theme}_strip_{k}.png")
		widths.append(piece.shape[1])
	meta = {"ground": H - 1, "texel": TEXEL, "parts": widths, "sections": [[s, f"{theme}_{i}"] for i, s in enumerate(starts)], "pixel": True}
	(BD / f"{theme}_strip.json").write_text(json.dumps(meta))
	print("strip", strip.shape[1], "x", H, "texel", TEXEL)


def wet_mask(rgb: np.ndarray) -> np.ndarray:
	g = Image.fromarray(rgb).convert("L")
	a = np.asarray(g).astype(np.float32)
	blur = np.asarray(g.filter(ImageFilter.BoxBlur(3))).astype(np.float32)
	var = np.asarray(Image.fromarray(np.abs(a - blur).astype(np.uint8)).filter(ImageFilter.BoxBlur(4))).astype(np.float32)
	flat = np.clip(1.0 - var / 14.0, 0.0, 1.0)
	return ((0.25 + 0.75 * (flat > 0.55)) * 255.0).astype(np.uint8)


def do_floor(theme: str, keep: Path) -> None:
	spec = MAPS[theme]["sections"]
	meta = json.loads((BD / f"{theme}_strip.json").read_text())
	starts = [int(s[0]) for s in meta["sections"]]
	ends = starts[1:] + [sum(int(w) for w in meta["parts"])]
	parts = []
	ref = None
	for i, (_, floor) in enumerate(spec):
		out = keep / f"{theme}_floor_{i}.png"
		url = gen(floor + ". " + FLOOR_STYLE + (" Match the pixel art style and palette of the reference image." if ref else ""), out, [ref] if ref else None)
		ref = ref or url
		w = int(round((ends[i] - starts[i]) / 0.9)) + SEAM
		nat = to_native(out, FLOOR_H)
		parts.append(np.asarray(nat.resize((w, FLOOR_H), Image.NEAREST)))
	strip, _ = join(parts)
	head = strip[:, :SEAM].copy()
	strip[:, :SEAM] = dither_join(strip, head)
	strip = strip[:, :-SEAM]
	Image.fromarray(strip).save(BD / f"{theme}_floor_road.png")
	Image.fromarray(wet_mask(strip), "L").save(BD / f"{theme}_floor_road_wet.png")
	(BD / f"{theme}_floor_road.json").write_text(json.dumps({"texel": TEXEL, "pixel": True}))
	print("floor", strip.shape[1], "x", FLOOR_H)


def do_props(theme: str, keep: Path) -> None:
	m = MAPS[theme]
	names = m["props"]
	out = keep / f"{theme}_props.png"
	gen(PROP_STYLE.format(n=len(names)) + " The objects, left to right: " + m["props_prompt"] + ".", out, aspect="3:1")
	rgb = np.asarray(Image.open(out).convert("RGB")).astype(np.int16)
	r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
	screen = (g > 140) & (g - r > 60) & (g - b > 60)
	alpha = ~screen
	cols = alpha.sum(axis=0) > 2
	# Runs of object columns, merged across small gaps, biggest N kept.
	runs, x = [], 0
	while x < cols.size:
		if cols[x]:
			x0 = x
			while x < cols.size and cols[x:x + 12].any():
				x += 1
			runs.append((x0, x))
		x += 1
	runs = sorted(sorted(runs, key=lambda t: t[1] - t[0], reverse=True)[:len(names)])
	PROPS_OUT.mkdir(parents=True, exist_ok=True)
	img = Image.open(out).convert("RGB")
	for name, (x0, x1) in zip(names, runs):
		a = alpha[:, x0:x1]
		ys = np.where(a.any(axis=1))[0]
		y0, y1 = int(ys.min()), int(ys.max()) + 1
		crop = np.asarray(img.crop((x0, y0, x1, y1)))
		rgba = np.dstack([crop, np.where(a[y0:y1], 255, 0).astype(np.uint8)])
		obj = Image.fromarray(rgba, "RGBA")
		# Its real height next to the fighters (~115 world units tall), in
		# texels of the backdrop grid.
		th = int(round(PROP_H.get(name, 50) / TEXEL))
		tw = max(4, int(round(obj.width * th / obj.height)))
		nat = obj.resize((tw, th), Image.BOX)
		al = (np.asarray(nat)[:, :, 3] > 140).astype(np.uint8) * 255
		nat = Image.fromarray(np.dstack([np.asarray(nat)[:, :, :3], al]), "RGBA")
		# Drawn at SpriteBook.DRAW_SCALE (1/4.5): blow up so one texel is
		# TEXEL world units.
		k = TEXEL * 4.5
		nat.resize((max(1, int(round(tw * k))), max(1, int(round(th * k)))), Image.NEAREST).save(PROPS_OUT / f"{name}.png")
		print("prop", name, (tw, th), flush=True)


def main() -> None:
	args = sys.argv[1:]
	keep = Path("/tmp/sorc_map")
	if "--keep" in args:
		i = args.index("--keep")
		keep = Path(args[i + 1])
		del args[i:i + 2]
	keep.mkdir(parents=True, exist_ok=True)
	theme = args[0]
	steps = args[1:] or ["bg", "floor", "props"]
	if "bg" in steps:
		do_bg(theme, keep)
	if "floor" in steps:
		do_floor(theme, keep)
	if "props" in steps:
		do_props(theme, keep)


if __name__ == "__main__":
	main()
