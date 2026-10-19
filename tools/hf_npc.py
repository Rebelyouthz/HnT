#!/usr/bin/env python3
"""Hideout / street NPC clips: Wan 2.2 image-to-video (HF ZeroGPU) from the
NPC's crew still on a green screen, sliced with video2sprite at the still's
own height so the clip matches the still.
    python3 tools/hf_npc.py <workdir> [who ...]
Writes assets/sprites/<who>/<clip>.png/.json."""
import json, os, re, shutil, subprocess, sys
from gradio_client import Client, handle_file
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAIL = (" Locked static camera that never moves or zooms, full body always in frame, she or he stays on the same spot, "
        "flat solid green background that never changes, no other people, realistic human motion with weight, "
        "keep the exact same pixel art style, face, hair and outfit for the whole clip.")
NEG = "camera movement, zoom, pan, cut, scene change, background change, extra people, text, watermark, blurry, morphing, deformed limbs, extra limbs, cropped body, walking away"
CLIPS = {
	"ember": {
		"idle": (3.0, "The woman blacksmith stands relaxed with the big hammer resting on her shoulder, breathing slowly, shifting her weight a little from one foot to the other, a small confident smile, she rolls her free shoulder once."),
		"hammer": (3.0, "The woman blacksmith swings the big hammer down in front of her three times as if striking hot metal on an anvil at waist height, strong and rhythmic, then rests it back on her shoulder."),
	},
	"vendor": {
		"idle": (3.0, "The old street vendor stands relaxed, counts a few coins from his money pouch, nods and gives a friendly little wave, then rests his hands on his hips."),
	},
}


def start_image(who, out):
	im = Image.open(os.path.join(ROOT, "assets", "sprites", "crew", who + ".png")).convert("RGBA")
	k = 600.0 / im.height
	im = im.resize((int(im.width * k), 600), Image.LANCZOS)
	bg = Image.new("RGBA", (576, 768), (0, 184, 50, 255))
	bg.alpha_composite(im, ((576 - im.width) // 2, 768 - 80 - im.height))
	bg.convert("RGB").save(out)


def main():
	work = sys.argv[1]
	whos = sys.argv[2:] or list(CLIPS)
	os.makedirs(work, exist_ok=True)
	wan = Client("zerogpu-aoti/wan2-2-fp8da-aoti-faster")
	for who in whos:
		st = os.path.join(work, "start_%s.png" % who)
		if not os.path.exists(st):
			start_image(who, st)
		for clip, (dur, p) in CLIPS[who].items():
			mp4 = os.path.join(work, "%s_%s.mp4" % (who, clip))
			if not os.path.exists(mp4):
				try:
					v, _ = wan.predict(input_image=handle_file(st), prompt=p + TAIL, steps=6, negative_prompt=NEG,
						duration_seconds=dur, guidance_scale=1, guidance_scale_2=1, seed=11, randomize_seed=False,
						api_name="/generate_video")
				except Exception as e:
					if "quota" in str(e).lower():
						m = re.search(r"Try again in ([0-9:]+)", str(e))
						print("QUOTA", m.group(1) if m else "?", flush=True)
						sys.exit(3)
					print("ERR", who, clip, str(e)[:200], flush=True)
					continue
				shutil.copy(v["video"] if isinstance(v, dict) else v, mp4)
			subprocess.run([sys.executable, os.path.join(ROOT, "tools", "video2sprite.py"), mp4, who, clip, "--frames", "16"], check=False)
			print("OK", who, clip, flush=True)


if __name__ == "__main__":
	main()
