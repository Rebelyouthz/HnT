"""Painted crew sprite (FLUX Krea on HF ZeroGPU), keyed off the green, cropped
to the 240 px height the Vale brothers use: python tools/crew_art.py dot"""
import os, sys
from gradio_client import Client
from PIL import Image
import numpy as np

DESIGN = {
    "dot": "a tough young woman mechanic in her twenties, short messy bleached hair with dark roots, grease-stained dark blue work overalls with the top tied around the waist, white tank top, tool belt with a big wrench, fingerless gloves, scuffed work boots, confident half smile",
}
STY = ("detailed 16-bit pixel art video game character sprite in the style of Streets of Rage 4, crisp dark outlines, "
       "full body from head to shoes, three-quarter front view, standing relaxed, one hand on the hip, one single character centred, "
       "flat solid bright green background #00b832, no shadow, no text, no other objects")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "crew")


def key(src, dst, h=240):
    im = np.asarray(Image.open(src).convert("RGB")).astype(np.int16)
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    green = (g > 90) & (g - np.maximum(r, b) > 40)
    a = np.where(green, 0, 255).astype(np.uint8)
    rgba = np.dstack([im.clip(0, 255).astype(np.uint8), a])
    # Green spill on the edge pixels: pull g down to the max of r and b.
    sp = (~green) & (g > np.maximum(r, b))
    rgba[..., 1] = np.where(sp, np.maximum(r, b), rgba[..., 1]).clip(0, 255)
    out = Image.fromarray(rgba, "RGBA")
    out = out.crop(out.getbbox())
    w = round(out.width * h / out.height)
    out.resize((w, h), Image.LANCZOS).save(dst)


if __name__ == "__main__":
    who = sys.argv[1]
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 7
    tok = open(os.path.expanduser("~/.cache/huggingface/token")).read().strip()
    flux = Client("black-forest-labs/FLUX.1-Krea-dev", token=tok)
    img, s = flux.predict(prompt=DESIGN[who] + ", " + STY, seed=seed, randomize_seed=False, width=768, height=1152,
                          guidance_scale=4.5, num_inference_steps=28, api_name="/infer")
    raw = f"/tmp/claude-0/dot/{who}_{seed}_raw.png"
    Image.open(img).save(raw)
    key(raw, f"/tmp/claude-0/dot/{who}_{seed}.png")
    print("OK", raw)
