"""Key images for Wan first/last-frame clips, cut from the game's own sprites."""
import json, sys
from PIL import Image
SP = "/home/user/hnt/assets/sprites"
W, H, BODY, FEET = 832, 640, 430, 600
GREEN = (0, 184, 50)

def frame(who, clip, i):
    d = json.load(open(f"{SP}/{who}/{clip}.json")); im = Image.open(f"{SP}/{who}/{clip}.png").convert("RGBA")
    fr = d["frames"]; f = fr[i if i >= 0 else len(fr) + i]
    cw, ch = d["cell"]
    cell = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    cell.paste(im.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])), (f.get("ox", 0), f.get("oy", 0)))
    return cell, len(fr), d

def scale_of(who):
    cell, _, _ = frame(who, "idle", 0)
    bb = cell.getbbox()
    return BODY / (bb[3] - bb[1])

def key(who, clip, i, out):
    """The cell keeps its bottom-centre anchor, so poses line up with the idle."""
    s = scale_of(who)
    idle, _, _ = frame(who, "idle", 0)
    lift = (idle.height - idle.getbbox()[3]) * s
    cell, _, _ = frame(who, clip, i)
    big = cell.resize((int(cell.width * s), int(cell.height * s)), Image.LANCZOS)
    can = Image.new("RGB", (W, H), GREEN)
    x = int(W * 0.5 - big.width * 0.5); y = int(FEET + lift - big.height)
    bb = big.getbbox()
    if x + bb[0] < 30:
        x = 30 - bb[0]
    if x + bb[2] > W - 30:
        x = W - 30 - bb[2]
    can.paste(big, (x, y), big)
    can.save(out)

def hit_of(who, clip):
    _, n, d = frame(who, clip, 0)
    if "hit" in d: return int(d["hit"])
    best, at = -1, 0
    for k, f in enumerate(d["frames"]):
        r = f.get("ox", 0) + f["w"]
        if r > best: best, at = r, k
    return at

if __name__ == "__main__":
    key(*sys.argv[1:3], int(sys.argv[3]), sys.argv[4])
