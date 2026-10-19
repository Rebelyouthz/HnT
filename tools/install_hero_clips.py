#!/usr/bin/env python3
"""Generated hero clips (Wan video) -> game clips, one call per move.

For each spec: video2sprite (same body height as the idle, feet on the
baseline), drop stray keyed blobs, then game timing:
  * strikes get a "hit" frame = the frame where the silhouette reaches
    furthest forward, and an fps that plays the clip in `dur` seconds;
  * holds (duck) stop on their last frame (loop false);
  * loops keep their real-time cycle.

    python3 tools/install_hero_clips.py <video_dir> <who> <spec> [<spec> ...]
spec = clip:video[:frames[:dur[:start[:end[:loop]]]]]
  e.g. jab:son_jab:12:0.42:0.3:1.3   run:son_run:12:0:0:0:loop
Needs: video2sprite.py deps + scipy
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"


def clean(base: Path) -> int:
    meta = json.loads(base.with_suffix(".json").read_text())
    im = np.array(Image.open(base.with_suffix(".png")).convert("RGBA"))
    removed = 0
    for fr in meta["frames"]:
        x, y, w, h = fr["x"], fr["y"], fr["w"], fr["h"]
        sub = im[y:y + h, x:x + w]
        lab, n = ndimage.label(sub[..., 3] > 20)
        if n <= 1:
            continue
        sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
        big = sizes.max()
        for i, s in enumerate(sizes):
            if s < big * 0.06:
                sub[lab == i + 1] = 0
                removed += 1
        im[y:y + h, x:x + w] = sub
    Image.fromarray(im).save(base.with_suffix(".png"))
    return removed


def reach_frame(meta: dict) -> int:
    """Index of the frame whose silhouette sticks out furthest forward."""
    best, at = -1e9, 0
    for i, fr in enumerate(meta["frames"]):
        right = fr["ox"] + fr["w"]
        if right > best:
            best, at = right, i
    return at


def main() -> None:
    vdir = Path(sys.argv[1])
    who = sys.argv[2]
    for spec in sys.argv[3:]:
        parts = spec.split(":")
        clip, video = parts[0], parts[1]
        frames = int(parts[2]) if len(parts) > 2 and parts[2] else 12
        dur = float(parts[3]) if len(parts) > 3 and parts[3] else 0.0
        start = parts[4] if len(parts) > 4 and parts[4] not in ("", "0") else ""
        end = parts[5] if len(parts) > 5 and parts[5] not in ("", "0") else ""
        mode = parts[6] if len(parts) > 6 else ""
        cmd = [sys.executable, str(ROOT / "tools" / "video2sprite.py"), str(vdir / f"{video}.mp4"), who, clip,
               "--frames", str(frames), "--stand-frame", "0", "--stand", "199"]
        if mode == "loop":
            cmd += ["--loop", "--min-cycle", "0.5", "--max-cycle", "1.6"]
        if start:
            cmd += ["--start", start]
        if end:
            cmd += ["--end", end]
        out = subprocess.run(cmd, capture_output=True, text=True)
        if out.returncode != 0:
            print("FAIL", clip, out.stderr[-400:])
            continue
        base = SPRITES / who / clip
        n_blobs = clean(base)
        meta = json.loads(base.with_suffix(".json").read_text())
        n = len(meta["frames"])
        if mode == "hold":
            meta["loop"] = False
        elif mode == "loop":
            meta["loop"] = True
        else:
            meta["loop"] = False
        if dur > 0:
            meta["fps"] = round(n / dur, 2)
        if mode == "strike":
            meta["hit"] = reach_frame(meta)
        base.with_suffix(".json").write_text(json.dumps(meta, separators=(",", ":")))
        print(f"{who}/{clip}: {n} frames, fps {meta.get('fps')}, loop {meta['loop']}, hit {meta.get('hit', '-')}, blobs {n_blobs}")


if __name__ == "__main__":
    main()
