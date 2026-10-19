#!/usr/bin/env python3
"""Cut a real sitting pose out of a fighter's idle frame: the torso (head to
hips) as drawn, one leg split at the knee into a thigh (laid forward over
the edge) and a shin (hanging down), plus a darker copy for the far leg.
Saved as parts so the game can swing the shins:

    python3 tools/sit_pose.py son father
  -> assets/sprites/<who>/sit_torso.png, sit_thigh.png, sit_shin.png, sit.json
"""
import json, sys
from pathlib import Path
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parent.parent / "assets/sprites"


def frame(who, clip="idle", i=0):
    m = json.loads((ROOT / who / f"{clip}.json").read_text())
    sh = Image.open(ROOT / who / f"{clip}.png").convert("RGBA")
    f = m["frames"][i]
    return sh.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))


def bbox_rows(im):
    a = im.split()[3]
    return a.getbbox()


def clusters(im, y, thr=128):
    a = im.split()[3].load()
    w = im.width
    out, x = [], 0
    while x < w:
        if a[x, y] > thr:
            s = x
            while x < w and a[x, y] > thr:
                x += 1
            out.append((s, x - 1))
        x += 1
    return [c for c in out if c[1] - c[0] >= 3]


def main(whos):
    for who in whos:
        im = frame(who)
        x0, y0, x1, y1 = bbox_rows(im)
        im = im.crop((x0, y0, x1, y1))
        W, H = im.size
        hip = int(H * 0.53)
        knee = int(H * 0.76)
        torso = im.crop((0, 0, W, hip + 2))
        # Front leg (facing right): the rightmost cluster at mid thigh / mid shin.
        ct = clusters(im, (hip + knee) // 2) or [(0, W - 1)]
        cs = clusters(im, (knee + H) // 2) or ct
        fx0, fx1 = ct[-1]
        sx0, sx1 = cs[-1]
        pad = 2
        thigh = im.crop((max(0, fx0 - pad), hip - 2, min(W, fx1 + pad + 1), knee + 2))
        shin = im.crop((max(0, sx0 - pad), knee - 2, min(W, sx1 + pad + 1), H))
        # Laid forward: rotate the thigh so the hip end is left, knee right.
        thigh_r = thigh.rotate(90, expand=True)
        out = ROOT / who
        torso.save(out / "sit_torso.png")
        thigh_r.save(out / "sit_thigh.png")
        shin.save(out / "sit_shin.png")
        meta = {
            "torso": [torso.width, torso.height],
            # Hip joint inside the torso image (where the thigh starts).
            "hip": [int((fx0 + fx1) / 2), hip],
            "thigh": [thigh_r.width, thigh_r.height],
            "shin": [shin.width, shin.height],
            "shin_top": [int((sx0 + sx1) / 2) - max(0, sx0 - pad), 2],
        }
        (out / "sit.json").write_text(json.dumps(meta))
        # Preview: assemble.
        can = Image.new("RGBA", (W + thigh_r.width + 40, H + 20), (40, 44, 60, 255))
        hx, hy = meta["hip"]
        can.alpha_composite(torso, (10, 10))
        far = ImageEnhance.Brightness(thigh_r).enhance(0.6)
        far_s = ImageEnhance.Brightness(shin).enhance(0.6)
        tx, ty = 10 + hx - 6, 10 + hy - thigh_r.height // 2
        can.alpha_composite(far, (tx - 4, ty - 2))
        can.alpha_composite(far_s, (tx - 4 + thigh_r.width - meta["shin_top"][0] - 4, ty - 2 + thigh_r.height // 2))
        can.alpha_composite(thigh_r, (tx, ty))
        can.alpha_composite(shin, (tx + thigh_r.width - meta["shin_top"][0] - 4, ty + thigh_r.height // 2))
        can.save(f"/tmp/claude-0/sit_{who}.png")
        print(who, meta)


if __name__ == "__main__":
    main(sys.argv[1:] or ["son", "father"])
