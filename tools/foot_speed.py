#!/usr/bin/env python3
"""Measure how fast the planted foot moves backward in each walk / run clip,
in texels per frame, and store it as "ground" in the clip json, so the game
plays the cycle at exactly the speed the body travels (no ice skating).

    python3 tools/foot_speed.py            # all actors
"""
import json, sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "assets/sprites"
CLIPS = ("walk", "parkour_run", "run")


def contact_x(im):
    """Mean x of the pixels touching the ground (within 2 rows of the lowest)."""
    a = im.split()[3].load()
    w, h = im.size
    for y in range(h - 1, -1, -1):
        xs = [x for x in range(w) if a[x, y] > 128]
        if len(xs) >= 2:
            pts = []
            for yy in range(y, max(0, y - 3), -1):
                pts += [x for x in range(w) if a[x, yy] > 128]
            # The contact foot: the cluster holding the lowest pixel.
            lo = min(xs)
            cl = [x for x in pts if abs(x - lo) < 26 or abs(x - max(xs)) < 0]
            return sum(cl) / len(cl), y
    return None, None


def measure(png, meta):
    sheet = Image.open(png).convert("RGBA")
    cw, ch = meta["cell"]
    pts = []
    for f in meta["frames"]:
        cell = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        cell.paste(sheet.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])), (f["ox"], f["oy"]))
        pts.append(contact_x(cell)[0])
    n = len(pts)
    d = []
    for i in range(n):
        a, b = pts[i], pts[(i + 1) % n]
        if a is None or b is None:
            continue
        dx = b - a
        # Planted foot slides back; a forward jump is the other foot landing.
        if -40 < dx < 0:
            d.append(-dx)
    if len(d) < 2:
        return None, pts
    d.sort()
    return round(d[len(d) // 2], 2), pts


def main():
    who_filter = set(a for a in sys.argv[1:] if not a.startswith('-'))
    for d in sorted(ROOT.iterdir()):
        if not d.is_dir() or (who_filter and d.name not in who_filter):
            continue
        for c in CLIPS:
            mj, mp = d / f"{c}.json", d / f"{c}.png"
            if not mj.exists() or not mp.exists():
                continue
            meta = json.loads(mj.read_text())
            if "frames" not in meta or "cell" not in meta:
                continue
            g, pts = measure(mp, meta)
            if "-v" in sys.argv:
                print(d.name, c, [round(p) if p else None for p in pts])
            if g is None:
                continue
            if "--write" in sys.argv:
                meta["ground"] = g
                mj.write_text(json.dumps(meta, indent=1) if mj.read_text().count("\n") > 3 else json.dumps(meta))
            print(f"{d.name}/{c}: {g} texels/frame  fps {meta.get('fps')}")


if __name__ == "__main__":
    main()
