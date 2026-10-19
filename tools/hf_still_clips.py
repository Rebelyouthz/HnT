#!/usr/bin/env python3
"""Clips from a still or a hero frame via Wan 2.2 image-to-video (HF ZeroGPU):
idles for the painted crew (Benny, Rico) and the heroes sitting on a ledge
with their legs over the edge (the tower summit). Renders mp4s only.
    HF_TOKEN=... python3 tools/hf_still_clips.py <workdir> [label ...]"""
import os, re, shutil, sys
from gradio_client import Client, handle_file
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hf_hero_moves as hm

ROOT = hm.ROOT
TAIL = (" Strict side view, locked static camera that never moves or zooms, full body always in frame, "
        "flat solid green background that never changes, no other people, natural motion with weight, "
        "keep the exact same pixel art style, face, hair and outfit for the whole clip.")
GREEN = (0, 184, 50, 255)
# label -> (source, prompt). source "crew:<name>" is the painted still,
# "hero:<who>" the hero's idle frame.
JOBS = {
	"benny_idle": ("crew:benny", "The big bearded man in the red flannel shirt and tool belt stands in one place, relaxed, breathing slowly, his chest rising and falling, he shifts his weight from one foot to the other and scratches his beard once. He does not walk or step and does not turn around."),
	"rico_idle": ("crew:rico", "The young man in the green cap and jacket stands in one place holding the clipboard, breathing, he taps the clipboard with his pen, glances down at it and back up, shifting his weight a little. He does not walk or step and does not turn around."),
	"father_sit": ("hero:father", "The bearded man in the grey hoodie faces left and sits down on the edge of a low ledge the same flat green as the background, then stays sitting on the edge with his thighs flat and both lower legs hanging straight down over the edge, gently swinging his feet, hands resting on his knees, looking out into the distance."),
	"son_sit": ("hero:son", "The young man faces left and sits down on the edge of a low ledge the same flat green as the background, then stays sitting on the edge with his thighs flat and both lower legs hanging straight down over the edge, swinging his feet back and forth, hands on the ledge beside his hips, looking out into the distance."),
	"father_climb": ("hero:father", "The bearded man in the grey hoodie turns his back to the camera and climbs straight up a ladder that is the same flat green as the background, hand over hand and foot over foot, his arms reaching up one after the other and his knees lifting in turn, a steady climbing rhythm, his body rising a little with each step."),
	"son_climb": ("hero:son", "The young man turns his back to the camera and climbs straight up a ladder that is the same flat green as the background, hand over hand and foot over foot, his arms reaching up one after the other and his knees lifting in turn, a quick steady climbing rhythm, his body rising a little with each step."),
	"benny_walk": ("crew:benny", "The big bearded man in the red flannel shirt and tool belt walks to the right at an easy steady pace, a full natural walk cycle with both legs and arms swinging, heavy boots, seen from the side the whole time."),
	"rico_walk": ("crew:rico", "The young man in the green cap and jacket walks to the right at an easy steady pace holding the clipboard, a full natural walk cycle with both legs, seen from the side the whole time."),
	"benny_hammer": ("crew:benny", "The big bearded man in the red flannel shirt turns to his right and swings a claw hammer down hard three times at a nail in a plank at waist height in front of him, a full overhead swing each time, then looks at his work. He stays on the same spot."),
	"father_climb2": ("hero:father", "The bearded man in the grey hoodie turns his back to the camera and climbs upward on the spot, hand over hand and knee over knee, as if gripping rungs that cannot be seen: his hands close on empty air one above the other and his feet step up in turn, a steady climbing rhythm. There is nothing in front of him, only the flat green background."),
	"son_climb2": ("hero:son", "The young man turns his back to the camera and climbs upward on the spot, hand over hand and knee over knee, as if gripping rungs that cannot be seen: his hands close on empty air one above the other and his feet step up in turn, a quick climbing rhythm. There is nothing in front of him, only the flat green background."),
}
NEG_CLIMB = ", ladder, rungs, wood, wooden planks, rope, pole, wall, scaffold, any object"


def crew_start(out, name):
	im = Image.open(os.path.join(ROOT, "assets/sprites/crew/%s.png" % name)).convert("RGBA")
	k = 520.0 / im.height
	im = im.resize((int(im.width * k), 520), Image.NEAREST)
	bg = Image.new("RGBA", (768, 768), GREEN)
	bg.alpha_composite(im, ((768 - im.width) // 2, 768 - 110 - im.height))
	bg.convert("RGB").save(out)


def main():
	work = sys.argv[1]
	labels = sys.argv[2:] or list(JOBS)
	os.makedirs(work, exist_ok=True)
	wan = Client("zerogpu-aoti/wan2-2-fp8da-aoti-faster")
	for lab in labels:
		mp4 = os.path.join(work, lab + ".mp4")
		if os.path.exists(mp4):
			continue
		src, prompt = JOBS[lab]
		kind, name = src.split(":")
		st = os.path.join(work, "start_%s.png" % name)
		if not os.path.exists(st):
			crew_start(st, name) if kind == "crew" else hm.start_image(st, name, "idle")
		try:
			v, _ = wan.predict(input_image=handle_file(st), prompt=prompt + TAIL, steps=6, negative_prompt=hm.NEG + (NEG_CLIMB if "climb" in lab else ""),
				duration_seconds=3.0, guidance_scale=1, guidance_scale_2=1, seed=int(os.environ.get("SEED", "7")), randomize_seed=False,
				api_name="/generate_video")
		except Exception as e:
			if "quota" in str(e).lower():
				m = re.search(r"Try again in ([0-9:]+)", str(e))
				print("QUOTA", m.group(1) if m else "?", flush=True)
				sys.exit(3)
			print("ERR", lab, str(e)[:200], flush=True)
			continue
		shutil.copy(v["video"] if isinstance(v, dict) else v, mp4)
		print("OK", lab, flush=True)


if __name__ == "__main__":
	main()
