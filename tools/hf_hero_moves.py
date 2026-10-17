#!/usr/bin/env python3
"""Hero move clips for the Kid via Wan 2.2 image-to-video (HF ZeroGPU), from
his own idle frame on a green screen. Only renders the mp4s; install them
with tools/install_hero_clips.py so they match his other clips.
    python3 tools/hf_hero_moves.py <workdir> [label ...]"""
import json, os, re, shutil, sys
from gradio_client import Client, handle_file
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAIL = (" Strict side view, locked static camera that never moves or zooms, full body always in frame, he stays on the same spot, "
        "flat solid green background that never changes, no other people, realistic martial arts motion with weight, "
        "keep the exact same pixel art style, face, hair and outfit for the whole clip.")
NEG = "camera movement, zoom, pan, cut, scene change, background change, extra people, text, watermark, blurry, morphing, deformed limbs, extra limbs, cropped body, walking away, turning to the camera"
CLIPS = {
	"son_mega_punch": "The young man faces right. He sinks into a low wide crouch and pulls both fists far back behind his hip, charging up and trembling with power, then explodes forward driving both fists together straight ahead in a huge two-handed punch, arms fully extended, then returns to his fighting stance.",
	"son_spin_high": "The young man faces right. He pivots on one foot and spins his whole body one full turn, his back to the camera for a moment, his straight leg whipping round in a high spinning hook kick at head height, then he lands back in his fighting stance facing right.",
	"son_spin_low": "The young man faces right. He drops low into a crouch with one hand on the floor and spins one full turn close to the ground, his straight leg sweeping a wide circle at ankle height like a leg sweep, then he rises back into his fighting stance facing right.",
}


def start_image(out):
	m = json.load(open(os.path.join(ROOT, "assets/sprites/son/idle.json")))
	fr = m["frames"][0]
	sheet = Image.open(os.path.join(ROOT, "assets/sprites/son/idle.png")).convert("RGBA")
	im = sheet.crop((fr["x"], fr["y"], fr["x"] + fr["w"], fr["y"] + fr["h"]))
	k = 520.0 / im.height
	im = im.resize((int(im.width * k), 520), Image.LANCZOS)
	bg = Image.new("RGBA", (768, 768), (0, 184, 50, 255))
	bg.alpha_composite(im, ((768 - im.width) // 2, 768 - 110 - im.height))
	bg.convert("RGB").save(out)


def main():
	work = sys.argv[1]
	labels = sys.argv[2:] or list(CLIPS)
	os.makedirs(work, exist_ok=True)
	st = os.path.join(work, "start_son.png")
	if not os.path.exists(st):
		start_image(st)
	wan = Client("zerogpu-aoti/wan2-2-fp8da-aoti-faster")
	for lab in labels:
		mp4 = os.path.join(work, lab + ".mp4")
		if os.path.exists(mp4):
			continue
		try:
			v, _ = wan.predict(input_image=handle_file(st), prompt=CLIPS[lab] + TAIL, steps=6, negative_prompt=NEG,
				duration_seconds=3.0, guidance_scale=1, guidance_scale_2=1, seed=7, randomize_seed=False,
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
