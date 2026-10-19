"""Copy staged clips into the game: despill green, game timing, hit frame."""
import json, shutil, sys
import numpy as np
from PIL import Image
SP = "/home/user/hnt/assets/sprites"; ST = "/tmp/claude-0/pol/e2"
DUR = {"punch_high": 0.85, "punch_mid": 0.85, "kick_low": 0.85, "hurt": 0.45, "death": 1.1}
for spec in sys.argv[1:]:
    who, clip = spec.split("/")
    im = np.array(Image.open(f"{ST}/{who}/{clip}.png").convert("RGBA")).astype(int)
    r, g, b, a = im[..., 0], im[..., 1], im[..., 2], im[..., 3]
    m = (a > 0) & (g > r + 12) & (g > b + 12)
    im[..., 1] = np.where(m, np.maximum(r, b), g)
    Image.fromarray(im.astype(np.uint8)).save(f"{SP}/{who}/{clip}.png")
    meta = json.load(open(f"{ST}/{who}/{clip}.json"))
    n = len(meta["frames"])
    if clip.startswith("walk") or clip == "idle":
        meta["loop"] = True          # walk cycles keep their sliced speed
    else:
        meta["loop"] = False
        meta["fps"] = round(n / DUR.get(clip, 1.0), 2)
    if clip.startswith("punch") or clip.startswith("kick"):
        meta["hit"] = max(0, int(meta.get("hit", 9)) - 1)
    else:
        meta.pop("hit", None)
    json.dump(meta, open(f"{SP}/{who}/{clip}.json", "w"), separators=(",", ":"))
    print(spec, n, "frames fps", meta["fps"], "hit", meta.get("hit", "-"), "despill", int(m.sum()))
