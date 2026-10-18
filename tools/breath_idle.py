"""A breathing idle from one standing frame: the feet stay planted, the body
above the hips rises and settles on a slow sine (chest swell, shoulders up,
the head riding along), with a hair of sway. Same cell, offsets and meta as
the clip it replaces, so the game's sizes do not change.

    python tools/breath_idle.py son walk 0          # who, source clip, frame
    python tools/breath_idle.py son idle 0 --frames 32 --fps 16
"""
import argparse, json, math
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "assets" / "sprites"


def cell(meta, sheet, i):
    cw, ch = meta["cell"]
    f = meta["frames"][i]
    c = Image.new("RGBA", (cw, ch))
    c.alpha_composite(sheet.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])), (f["ox"], f["oy"]))
    return c


def breathe(base, t, amp, sway):
    """Rows above the hip line rise by up to `amp` px (most at the shoulders),
    a smooth vertical warp so nothing tears; the legs never move."""
    a = np.asarray(base).astype(np.float32)
    h, w = a.shape[:2]
    m = a[..., 3] > 20
    ys = np.where(m.any(axis=1))[0]
    top, feet = int(ys.min()), int(ys.max())
    hip = top + int((feet - top) * 0.52)
    s = 0.5 - 0.5 * math.cos(t * math.tau)          # 0 -> 1 -> 0
    out = np.zeros_like(a)
    xs = np.arange(w, dtype=np.float32)
    for y in range(h):
        if y >= hip:
            out[y] = a[y]
            continue
        # How far up this row moves: 0 at the hips, full at the shoulders and
        # above (the head rides the shoulders).
        k = min(1.0, (hip - y) / max(1.0, (hip - top) * 0.55))
        dy = amp * s * k
        dx = sway * math.sin(t * math.tau) * k
        src_y = y + dy
        y0 = int(math.floor(src_y))
        fy = src_y - y0
        y0 = min(max(y0, 0), h - 1)
        y1 = min(y0 + 1, h - 1)
        row = a[y0] * (1 - fy) + a[y1] * fy
        sx = xs - dx
        x0 = np.clip(np.floor(sx).astype(int), 0, w - 1)
        x1 = np.clip(x0 + 1, 0, w - 1)
        fx = (sx - np.floor(sx))[:, None]
        out[y] = row[x0] * (1 - fx) + row[x1] * fx
    return Image.fromarray(out.clip(0, 255).astype(np.uint8), "RGBA")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("who")
    ap.add_argument("src")
    ap.add_argument("frame", type=int)
    ap.add_argument("--frames", type=int, default=32)
    ap.add_argument("--fps", type=float, default=16.0)
    ap.add_argument("--amp", type=float, default=2.6, help="shoulder rise in sheet px")
    ap.add_argument("--sway", type=float, default=0.6)
    ap.add_argument("--out", default="idle", help="clip name to write")
    a = ap.parse_args()
    src_meta = json.loads((ROOT / a.who / f"{a.src}.json").read_text())
    sheet = Image.open(ROOT / a.who / f"{a.src}.png").convert("RGBA")
    base = cell(src_meta, sheet, a.frame)
    cw, ch = src_meta["cell"]
    frames = [breathe(base, i / a.frames, a.amp, a.sway) for i in range(a.frames)]
    # Pack: trim each frame, one row of cells.
    boxes = [f.getbbox() for f in frames]
    W = sum(b[2] - b[0] for b in boxes) + 2 * len(boxes)
    H = max(b[3] - b[1] for b in boxes)
    out = Image.new("RGBA", (W, H))
    x = 0
    fr = []
    for f, b in zip(frames, boxes):
        crop = f.crop(b)
        out.paste(crop, (x, 0))
        fr.append({"x": x, "y": 0, "w": crop.width, "h": crop.height, "ox": b[0], "oy": b[1]})
        x += crop.width + 2
    dst_json = ROOT / a.who / f"{a.out}.json"
    dst = json.loads(dst_json.read_text()) if dst_json.exists() else {}
    dst.update({"cell": [cw, ch], "frames": fr, "fps": a.fps, "loop": True})
    for k in ("scale", "src_area"):
        if k in src_meta and k not in dst:
            dst[k] = src_meta[k]
    dst["breath_from"] = f"{a.src}:{a.frame}"
    dst["frames"] = fr
    out.save(ROOT / a.who / f"{a.out}.png")
    dst_json.write_text(json.dumps(dst, indent=1))
    print(a.out + ":", len(fr), "frames @", a.fps, "fps from", a.src, a.frame, "sheet", out.size)


if __name__ == "__main__":
    main()
