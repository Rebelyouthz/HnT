"""BONE YARD victim reactions for the street thugs: Wan 2.2 image-to-video
(HF ZeroGPU) from a frame of the thug's own idle sheet, sliced at the same
body scale as his hurt clip.  python3 tools/hf_react.py <workdir> [who ...]
Writes assets/sprites/<who>/r_knee|r_blind|r_heart|block.png/.json
(HF_MOVES=block for just the guard)."""
import json, os, re, shutil, subprocess, sys, time
from gradio_client import Client, handle_file
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TAIL = (" Strict side view, locked static camera that never moves or zooms, facing right, full body always in frame, "
        "flat solid green background that never changes, no other people, realistic human motion with weight, "
        "keep the exact same pixel art style and outfit.")
NEG = "camera movement, zoom, pan, cut, scene change, background change, extra people, text, watermark, blurry, morphing, deformed limbs, extra limbs, cropped body, turning toward camera"
MOVES = {
	"r_knee": (3.0, "The man screams as his front knee suddenly buckles the wrong way; he collapses down onto his other knee, clutching his leg with both hands, rocking in pain."),
	"r_blind": (3.0, "The man clutches both hands over his eyes and staggers backward blindly, bent over, swinging one arm at nothing, stumbling."),
	"r_heart": (3.0, "The man suddenly stiffens, clutches his chest with both hands, takes two shaky steps, his knees give out and he collapses face down onto the ground and lies still."),
	"block": (2.0, "The man snaps both forearms up in front of his face in a tight boxing guard, flinches half a step backward as a hard punch lands on his arms, then holds the guard up, eyes over his fists."),
}
# HF_MOVES=block,r_knee picks which reactions to make (default: all).
if os.environ.get("HF_MOVES"):
	MOVES = {k: v for k, v in MOVES.items() if k in os.environ["HF_MOVES"].split(",")}
WHO = {"bag_snatch": "The thief in the red hoodie with the hood up, a white bandana mask over his nose and mouth, a brown satchel, baggy grey pants and red sneakers,",
       "repo_goon": "The bald heavyset thug in the grey vest and grey cargo pants with a gold chain and brown boots,",
       "mohawk": "The punk with the spiky black mohawk, black leather jacket, ripped blue jeans and black boots,",
       "punk": "The street punk in the yellow beanie, black leather jacket, ripped blue jeans and black boots, holding a clipboard,"}
KEEP = " He keeps exactly the same face, hair, headwear and outfit for the whole clip; nothing about his look changes."


def start_image(who, out):
	sheet = os.path.join(ROOT, "assets", "sprites", who, "idle")
	meta = json.load(open(sheet + ".json"))
	fr = meta["frames"][0]
	im = Image.open(sheet + ".png").convert("RGBA").crop((fr["x"], fr["y"], fr["x"] + fr["w"], fr["y"] + fr["h"]))
	k = 600.0 / im.height
	im = im.resize((int(im.width * k), 600), Image.LANCZOS)
	bg = Image.new("RGBA", (576, 768), (0, 184, 50, 255))
	bg.alpha_composite(im, ((576 - im.width) // 2, 768 - 80 - im.height))
	bg.convert("RGB").save(out)


def main():
	work = sys.argv[1]
	whos = sys.argv[2:] or list(WHO)
	os.makedirs(work, exist_ok=True)
	wan = Client("zerogpu-aoti/wan2-2-fp8da-aoti-faster")
	for who in whos:
		st = os.path.join(work, "start_%s.png" % who)
		if not os.path.exists(st):
			start_image(who, st)
		for clip, (dur, p) in MOVES.items():
			mp4 = os.path.join(work, "%s_%s.mp4" % (who, clip))
			if not os.path.exists(mp4):
				try:
					v, _ = wan.predict(input_image=handle_file(st), prompt=p.replace("The man", WHO[who]) + KEEP + TAIL, steps=6,
						negative_prompt=NEG, duration_seconds=dur, guidance_scale=1, guidance_scale_2=1, seed=23,
						randomize_seed=False, api_name="/generate_video")
				except Exception as e:
					if "quota" in str(e).lower():
						m = re.search(r"Try again in ([0-9:]+)", str(e))
						print("QUOTA", m.group(1) if m else "?", flush=True)
						sys.exit(3)
					print("ERR", who, clip, str(e)[:200], flush=True)
					continue
				shutil.copy(v["video"] if isinstance(v, dict) else v, mp4)
			ref = os.path.join(ROOT, "assets", "sprites", who, "hurt.json")
			subprocess.run([sys.executable, os.path.join(ROOT, "tools", "video2sprite.py"), mp4, who, clip, "--frames", "16",
				"--scale-ref", ref], check=False)
			print("OK", who, clip, flush=True)


if __name__ == "__main__":
	main()
