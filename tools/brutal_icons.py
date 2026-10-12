"""BONE YARD tree icons: one glyph per move from FLUX.1-schnell (HF ZeroGPU
space), cut to an iPhone-style rounded square with rim and gloss.
Usage: HF_TOKEN=... python3 tools/brutal_icons.py [id ...]
Writes assets/ui/brutal/<id>.png (128 px, 192 px for the big supers)."""
import json, os, sys
from gradio_client import Client
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui", "brutal")
STYLE = ("full-bleed square game ability icon, bold flat vector glyph, thick white silhouette "
         "with one red accent, %s gradient background filling the whole frame, high contrast, "
         "centered, simple, no border, no frame, no text, no letters")
GLYPH = {
	"arm_breaker": "a human forearm bent backwards at the elbow with a jagged crack line",
	"knee_snap": "a human leg with the knee bent the wrong way and a crack at the knee",
	"neck_crack": "two hands twisting a head sideways, a crack line at the neck",
	"death_touch": "an open palm with five glowing dots on the fingertips",
	"eye_gouge": "two fingers in a V jabbing toward a staring eye",
	"pipe_javelin": "a steel pipe flying like a spear through a torso silhouette",
	"heart_punch": "a fist holding up an anatomical heart, drops falling",
	"spine_rip": "a skull attached to a long spine being pulled upward by a fist",
	"back_breaker": "a body folded over a raised knee, cracked spine",
	"two_way": "a leg bent backwards and a head flying off, two curved arrows",
	"skull_crusher": "a hammer fist smashing a cracked skull, shards bursting",
	"flamingo_reaper": "a single raised leg doing three kicks with motion lines and a scythe-like arc",
}


def bg(r):
	if r.get("big"):
		return "black and molten gold"
	if r["id"] == "pipe_javelin":
		return "dark bronze and rust"
	return "deep crimson and black" if r["hero"] == "father" else "deep violet and teal"


def finish(src, size, big):
	im = Image.open(src).convert("RGB").resize((size, size), Image.LANCZOS)
	rad = int(size * 0.225)
	mask = Image.new("L", (size, size), 0)
	ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), rad, fill=255)
	gloss = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	gd = ImageDraw.Draw(gloss)
	for y in range(size // 2):
		gd.line((0, y, size, y), fill=(255, 255, 255, int(46 * (1 - y / (size / 2)))))
	out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	out.paste(im, (0, 0), mask)
	out = Image.alpha_composite(out, Image.composite(gloss, Image.new("RGBA", (size, size)), mask))
	rim = Image.new("RGBA", (size, size), (0, 0, 0, 0))
	col = (255, 205, 90, 255) if big else (255, 255, 255, 120)
	ImageDraw.Draw(rim).rounded_rectangle((1, 1, size - 2, size - 2), rad, outline=col, width=3 if big else 2)
	return Image.alpha_composite(out, rim)


def main():
	rows = json.load(open(os.path.join(ROOT, "data", "brutal.json")))
	want = set(sys.argv[1:])
	c = Client("black-forest-labs/FLUX.1-schnell")
	for r in rows:
		if want and r["id"] not in want:
			continue
		prompt = GLYPH[r["id"]] + ", " + STYLE % bg(r)
		path, _seed = c.predict(prompt, 7, False, 512, 512, 4, api_name="/infer")
		size = 192 if r.get("big") else 128
		finish(path, size, bool(r.get("big"))).save(os.path.join(OUT, r["id"] + ".png"))
		print("icon", r["id"])


if __name__ == "__main__":
	main()
