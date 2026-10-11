"""Find clips whose character turns round mid-clip (some frames drawn
facing the other way), and optionally mirror those frames back.

    python tools/flip_audit.py                 # report every who/clip
    python tools/flip_audit.py --fix who clip  # mirror the odd-facing frames
    python tools/flip_audit.py --fix who clip all  # mirror the whole clip

A frame faces the other way when its mirror image matches its neighbours
far better than the frame itself does.
"""
import json, sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "assets" / "sprites"


def cells(meta, sheet):
    cw, ch = meta["cell"]
    out = []
    for f in meta["frames"]:
        c = Image.new("RGBA", (cw, ch))
        c.alpha_composite(sheet.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])), (f["ox"], f["oy"]))
        out.append(c)
    return out


def sig(im, size=24):
    """Head and shoulders only (the top quarter of the body), centred on
    the head: arms and legs swing, the face keeps pointing one way."""
    a = np.asarray(im).astype(np.float32) / 255.0
    m = a[..., 3] > 0.2
    ys, xs = np.where(m)
    if len(xs) == 0:
        return np.zeros((size, size, 4), np.float32)
    y0, y1 = ys.min(), ys.max()
    top = y0 + max(4, int((y1 - y0) * 0.22))
    band = m[y0:top]
    cols = np.where(band.any(axis=0))[0]
    cx = int(np.median(np.where(band)[1]))
    half = max(6, (cols.max() - cols.min()) // 2 + 2)
    crop = im.crop((cx - half, y0, cx + half, top)).resize((size, size), Image.BILINEAR)
    return np.asarray(crop).astype(np.float32) / 255.0


def facing(frames):
    """+1 / -1 per frame, relative to the clip's majority facing."""
    s = [sig(f) for f in frames]
    m = [x[:, ::-1] for x in s]
    n = len(s)
    # Start from frame 0's facing, then settle each frame against the mean
    # head of the frames that agree, a few rounds.
    side = [1] * n
    for _ in range(4):
        ref = np.mean([s[i] if side[i] > 0 else m[i] for i in range(n)], axis=0)
        side = [1 if np.abs(s[i] - ref).mean() <= np.abs(m[i] - ref).mean() else -1 for i in range(n)]
    if side.count(-1) > side.count(1):
        side = [-v for v in side]
    return side


def audit():
    for d in sorted(p for p in ROOT.iterdir() if p.is_dir()):
        for j in sorted(d.glob("*.json")):
            try:
                meta = json.loads(j.read_text())
                if "frames" not in meta or len(meta["frames"]) < 4 or j.stem in ("death", "knockdown", "roll", "backflip_kick", "cartwheel_kick"):
                    continue
                if j.stem in ("walk_up", "walk_down"):
                    continue
                fr = cells(meta, Image.open(j.with_suffix(".png")).convert("RGBA"))
            except Exception:
                continue
            side = facing(fr)
            odd = [i for i, v in enumerate(side) if v < 0]
            # A turn: a run of 2+ frames the other way (one odd frame is
            # usually a pose that just reads mirrored).
            runs, cur = [], []
            for i in odd:
                if cur and i != cur[-1] + 1:
                    runs.append(cur)
                    cur = []
                cur.append(i)
            if cur:
                runs.append(cur)
            if any(len(r) >= 3 for r in runs):
                print(f"{d.name}/{j.stem}: frames {odd} face the other way ({len(fr)} frames)")


def clip_audit():
    """Whole clips drawn facing left: the clip's mean head against the mean
    head of the character's other side-view clips."""
    skip = ("walk_up", "walk_down", "death", "knockdown", "roll", "sit", "hurt", "fail_back", "fail_face", "fail_trip")
    for d in sorted(p for p in ROOT.iterdir() if p.is_dir()):
        heads = {}
        for j in sorted(d.glob("*.json")):
            try:
                meta = json.loads(j.read_text())
                if "frames" not in meta or j.stem in skip or "cell" not in meta:
                    continue
                fr = cells(meta, Image.open(j.with_suffix(".png")).convert("RGBA"))
            except Exception:
                continue
            heads[j.stem] = np.mean([sig(f) for f in fr], axis=0)
        if len(heads) < 3:
            continue
        for k, h in heads.items():
            rest = np.mean([v for kk, v in heads.items() if kk != k], axis=0)
            same = np.abs(h - rest).mean()
            mirr = np.abs(h[:, ::-1] - rest).mean()
            if mirr < same * 0.85:
                print(f"{d.name}/{k}: whole clip faces the other way ({mirr:.3f} mirrored vs {same:.3f})")


def fix(who, clip, idx):
    p = ROOT / who / f"{clip}.json"
    meta = json.loads(p.read_text())
    sheet = Image.open(p.with_suffix(".png")).convert("RGBA")
    cw = meta["cell"][0]
    for i in idx:
        f = meta["frames"][i]
        box = (f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])
        sheet.paste(sheet.crop(box).transpose(Image.FLIP_LEFT_RIGHT), box[:2])
        # Mirror about the cell's centre line, where the feet are anchored.
        f["ox"] = cw - f["ox"] - f["w"]
    sheet.save(p.with_suffix(".png"))
    p.write_text(json.dumps(meta, indent=1))
    print("mirrored", who, clip, idx)


if __name__ == "__main__":
    if len(sys.argv) >= 4 and sys.argv[1] == "--fix":
        who, clip = sys.argv[2], sys.argv[3]
        meta = json.loads((ROOT / who / f"{clip}.json").read_text())
        fr = cells(meta, Image.open(ROOT / who / f"{clip}.png").convert("RGBA"))
        side = facing(fr)
        idx = [i for i, v in enumerate(side) if v < 0]
        if len(sys.argv) > 4 and sys.argv[4] == "all":
            idx = list(range(len(fr)))
        fix(who, clip, idx)
    else:
        audit()
        clip_audit()
