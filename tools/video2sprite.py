#!/usr/bin/env python3
"""Video -> game sprite sheet (the "video to sprite" method).

A generated (or filmed) clip of one character on a flat background becomes a
clip in assets/sprites/<who>/<clip>.png + .json, same format as the slicer:

1. Decode every frame.
2. Key the background (flat colour estimated from the frame border; works for
   white, green screen or any plain wall) with the slicer's edge cleanup.
3. Loop: for loops (walk, run, idle) find the frame pair a..b whose poses
   match best (mask IoU + colour) with a minimum cycle length, and keep
   exactly one cycle so the animation repeats without a pop.
   For one-shots (attacks) trim the still head/tail where nothing moves.
4. Resample the kept range to the target frame count (even spacing).
5. One scale for the whole clip (body height -> STAND_H), feet on the
   baseline, x registered by overlap, premultiplied Lanczos + hard alpha.
6. Write the packed sheet + JSON and an in-game-speed preview GIF.

    python3 tools/video2sprite.py clip.mp4 father walk --loop --frames 12
    python3 tools/video2sprite.py jab.mp4 father jab --frames 10
Needs: pillow numpy scipy imageio imageio-ffmpeg
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import imageio
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import slice_sprites as S  # noqa: E402


def decode(path: str) -> tuple[list[np.ndarray], float]:
    r = imageio.get_reader(path)
    fps = float(r.get_meta_data().get("fps", 24.0))
    return [np.asarray(f)[..., :3] for f in r], fps


def keyed(frames: list[np.ndarray]) -> list[np.ndarray]:
    out = []
    for f in frames:
        k = S.key(f)
        # Keep the biggest body (drop stray specks the video model paints).
        m = k[..., 3] >= 0.5
        from scipy import ndimage
        lab, n = ndimage.label(m)
        if n > 1:
            sizes = ndimage.sum(m, lab, index=np.arange(1, n + 1))
            keep = np.isin(lab, np.nonzero(sizes >= sizes.max() * 0.08)[0] + 1)
            k[..., 3] *= keep
        out.append(k)
    return out


def _sig(k: np.ndarray, size: int = 64) -> np.ndarray:
    """Pose signature: alpha mask + colour, cropped to the body, fixed size."""
    bb = S.bbox(k)
    if bb is None:
        return np.zeros((size, size, 4), np.float32)
    x0, y0, x1, y1 = bb
    # Anchor to the feet and the body's horizontal centre so a character
    # drifting in the frame still compares pose to pose.
    crop = k[y0:y1, x0:x1]
    im = Image.fromarray((np.clip(crop, 0, 1) * 255).astype(np.uint8), "RGBA").resize((size, size), Image.BILINEAR)
    return np.asarray(im).astype(np.float32) / 255.0


def best_loop(keys: list[np.ndarray], min_len: int, max_len: int) -> tuple[int, int, float]:
    """Cycle a..b: end pose matches start pose, and the body really moves
    in between (a still stretch matches itself perfectly and is useless)."""
    sigs = [_sig(k) for k in keys]
    n = len(sigs)
    motion = np.array([float(np.abs(sigs[i + 1] - sigs[i]).mean()) for i in range(n - 1)] + [0.0])
    csum = np.concatenate([[0.0], np.cumsum(motion)])
    best_motion = max((csum[min(n, a + max_len)] - csum[a]) for a in range(n)) if n else 0.0
    need = best_motion * 0.55
    best = (0, min(n - 1, max_len), 1e9)
    for a in range(0, n - min_len):
        for b in range(a + min_len, min(n, a + max_len + 1)):
            moved = csum[b] - csum[a]
            if moved < need:
                continue
            d = float(np.abs(sigs[a] - sigs[b]).mean()) / (0.5 + moved / max(best_motion, 1e-6))
            if d < best[2]:
                best = (a, b, d)
    return best


def trim_still(keys: list[np.ndarray], thresh: float = 0.004) -> tuple[int, int]:
    sigs = [_sig(k) for k in keys]
    motion = [float(np.abs(sigs[i + 1] - sigs[i]).mean()) for i in range(len(sigs) - 1)]
    moving = [i for i, m in enumerate(motion) if m > thresh]
    if not moving:
        return 0, len(keys) - 1
    return max(0, moving[0] - 1), min(len(keys) - 1, moving[-1] + 2)


def resample_idx(a: int, b: int, count: int, loop: bool) -> list[int]:
    if loop:
        # b is the frame that matches a: play a..b-1 so b wraps onto a.
        return [int(round(a + (b - a) * i / count)) for i in range(count)]
    return [int(round(a + (b - a) * i / max(1, count - 1))) for i in range(count)]


def build(keys: list[np.ndarray], idx: list[int], stand_h: int) -> tuple[list, tuple[int, int]]:
    sel = [keys[i] for i in idx]
    heights = []
    for k in sel:
        bb = S.bbox(k)
        if bb:
            heights.append(bb[3] - bb[1])
    scale = stand_h / float(np.percentile(heights, 90))
    ims = []
    for k in sel:
        bb = S.bbox(k)
        im = S._trim(S.resample(k[bb[1]:bb[3], bb[0]:bb[2]], scale))
        ims.append(im)
    ref = S._mask(ims[0])
    placed = []
    max_side = 0.0
    max_h = 0
    prev = None
    for im in ims:
        m = S._mask(im)
        span = max(8, int(max(m.shape[1], ref.shape[1]) * 0.45))
        start = (ref.shape[1] - m.shape[1]) // 2
        dx = S._best_dx(ref, m, start, span)
        if prev is not None and abs(dx - prev) > span * 0.8:
            dx = prev
        prev = dx
        placed.append((im, dx))
        max_side = max(max_side, -dx, dx + im.shape[1] - ref.shape[1])
        max_h = max(max_h, im.shape[0])
    cw = int(np.ceil(max(ref.shape[1] * 0.5 + max_side, S.MIN_WHO_CELL * 0.5))) * 2
    ch = max(S.MIN_WHO_CELL, int(np.ceil((max_h + 4) / 2.0)) * 2)
    left = cw // 2 - ref.shape[1] // 2
    frames = [(im, int(np.clip(left + dx, 0, cw - im.shape[1])), ch - 2 - im.shape[0]) for im, dx in placed]
    return frames, (cw, ch)


def preview(frames: list, cell: tuple[int, int], fps: float, path: Path) -> None:
    cw, ch = cell
    pics = []
    for im, x, y in frames:
        c = Image.new("RGB", (cw, ch), (30, 34, 50))
        sprite = S.to_img(im)
        c.paste(sprite, (x, y), sprite)
        pics.append(c.convert("P", palette=Image.ADAPTIVE, colors=255))
    # Three passes so the loop is easy to judge.
    seq = pics * 3
    seq[0].save(path, save_all=True, append_images=seq[1:], duration=int(1000 / fps), loop=0, disposal=2)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("video")
    ap.add_argument("who")
    ap.add_argument("clip")
    ap.add_argument("--loop", action="store_true", help="cut one seamless cycle (walk/run/idle)")
    ap.add_argument("--frames", type=int, default=12)
    ap.add_argument("--fps", type=float, default=0.0, help="game playback fps (default: keeps real-time speed)")
    ap.add_argument("--stand", type=int, default=S.STAND_H)
    ap.add_argument("--min-cycle", type=float, default=0.5, help="shortest loop in seconds")
    ap.add_argument("--max-cycle", type=float, default=1.6, help="longest loop in seconds")
    ap.add_argument("--out", default=str(S.OUT))
    a = ap.parse_args()
    raw, vfps = decode(a.video)
    keys = keyed(raw)
    if a.loop:
        s, e, d = best_loop(keys, int(a.min_cycle * vfps), int(a.max_cycle * vfps))
        print("loop %d..%d (%.2fs), mismatch %.4f" % (s, e, (e - s) / vfps, d))
    else:
        s, e = trim_still(keys)
        print("action %d..%d (%.2fs)" % (s, e, (e - s) / vfps))
    idx = resample_idx(s, e, a.frames, a.loop)
    frames, cell = build(keys, idx, a.stand)
    fps = a.fps or a.frames / max(1e-3, (e - s) / vfps)
    dest = Path(a.out) / a.who
    dest.mkdir(parents=True, exist_ok=True)
    S.write_sheet(dest / a.clip, frames, cell)
    meta = json.loads((dest / (a.clip + ".json")).read_text())
    meta["fps"] = round(fps, 2)
    meta["loop"] = bool(a.loop)
    (dest / (a.clip + ".json")).write_text(json.dumps(meta, separators=(",", ":")))
    prev = dest / (a.clip + "_preview.gif")
    preview(frames, cell, fps, prev)
    print("wrote %s.png/.json (%d frames, cell %dx%d, %.1f fps) + %s" % (dest / a.clip, len(frames), cell[0], cell[1], fps, prev.name))


if __name__ == "__main__":
    main()
