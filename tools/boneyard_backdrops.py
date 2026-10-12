"""Painted street sections for the three BONE YARD maps (FLUX.1-schnell on
an HF ZeroGPU space), in the house style of the other strips. Run, then
stitch each theme with tools/street_strip.py.
Usage: python3 tools/boneyard_backdrops.py <outdir> [theme ...]"""
import os, sys, shutil
from gradio_client import Client

STYLE = ("2D side-scrolling beat em up background, straight-on front view of a building facade at street level, "
         "flat orthographic, no people, gritty graphic novel ink and wash illustration, muted palette, night, "
         "wet reflective ground strip along the bottom fifth of the image, wide panorama, no text, no letters")
THEMES = {
	"butcher": [
		"a night butcher shop window full of hanging pig carcasses on hooks behind fogged glass, red neon glow",
		"a meat packing loading door with a rail of steel meat hooks and dripping carcasses, red light",
		"a butcher counter seen through a big window, cleavers on a magnetic strip, chalk price board, red tile walls",
		"a narrow alley between butcher shops with crates of bones, a blood drain, a flickering red lamp",
	],
	"cold": [
		"inside a frozen industrial cold storage warehouse, frost on corrugated walls, hanging plastic strip curtains, icy blue light",
		"a cold storage aisle with tall steel racks of frozen crates covered in frost, cold blue fluorescent tubes",
		"a freezer room wall with hanging frozen carcasses in rows, frost and icicles, pale blue light",
		"a giant steel freezer vault door half open with cold mist pouring out, warning stripes, blue light",
	],
	"chapel": [
		"an abandoned gothic chapel interior wall with tall stained glass windows, candles, piles of unpaid bills on pews, purple moonlight",
		"a gothic chapel altar turned into a debt collector desk with ledgers, candles and a big brass bell, purple light",
		"a chapel side wall with confession booths stuffed with paper invoices, iron candelabras, dim violet light",
		"a ruined chapel organ with pipes, cobwebs, scattered envelopes and candles, cold moonlight through broken windows",
	],
}


def main():
	out = sys.argv[1]
	want = sys.argv[2:] or list(THEMES)
	os.makedirs(out, exist_ok=True)
	c = Client("black-forest-labs/FLUX.1-schnell")
	for th in want:
		for i, p in enumerate(THEMES[th]):
			path, _ = c.predict(p + ", " + STYLE, 11 + i, False, 1456, 768, 4, api_name="/infer")
			dst = os.path.join(out, "%s_%d.webp" % (th, i))
			shutil.copy(path, dst)
			print("section", dst)


if __name__ == "__main__":
	main()
