#!/usr/bin/env python3
"""Smoother clips: optical-flow in-between frames for a sprite clip.

Reads assets/sprites/<who>/<clip>.png + .json, puts every frame on its cell
canvas, and between each pair of neighbours renders a middle frame by
warping both halfway along the dense optical flow (DIS) and blending them.
The clip gets 2n frames (loops wrap last->first, one-shots n*2-1), its fps
doubles so the timing stays the same, and a strike's "hit" frame index is
remapped. Alpha is warped with the colour, then hardened, so the outline
stays crisp at game scale.

    python3 tools/tween_frames.py son jab [--out DIR] [--dry]
Needs: numpy pillow opencv-python-headless
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "sprites"


def load_clip(who: str, clip: str):
    meta = json.loads((SPRITES / who / f"{clip}.json").read_text())
    sheet = np.asarray(Image.open(SPRITES / who / f"{clip}.png").convert("RGBA")).astype(np.float32) / 255.0
    cw, ch = meta["cell"]
    frames = []
    for fr in meta["frames"]:
        cell = np.zeros((ch, cw, 4), np.float32)
        x, y, w, h, ox, oy = (int(fr[k]) for k in ("x", "y", "w", "h", "ox", "oy"))
        sub = sheet[y:y + h, x:x + w]
        h2 = min(h, ch - oy)
        w2 = min(w, cw - ox)
        cell[oy:oy + h2, ox:ox + w2] = sub[:h2, :w2]
        frames.append(cell)
    return meta, frames


def _gray(f: np.ndarray) -> np.ndarray:
    a = f[..., 3:4]
    rgb = f[..., :3] * a + (1.0 - a) * 0.5
    g = cv2.cvtColor((rgb * 255).astype(np.uint8), cv2.COLOR_RGB2GRAY)
    return g


def _warp(f: np.ndarray, flow: np.ndarray, t: float) -> np.ndarray:
    h, w = flow.shape[:2]
    gx, gy = np.meshgrid(np.arange(w, dtype=np.float32), np.arange(h, dtype=np.float32))
    mx = gx - flow[..., 0] * t
    my = gy - flow[..., 1] * t
    pre = f.copy()
    pre[..., :3] *= pre[..., 3:4]
    out = cv2.remap(pre, mx, my, interpolation=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=0)
    return out


def middle(a: np.ndarray, b: np.ndarray, dis) -> np.ndarray:
    ga, gb = _gray(a), _gray(b)
    f_ab = dis.calc(ga, gb, None)   # a -> b
    f_ba = dis.calc(gb, ga, None)   # b -> a
    wa = _warp(a, f_ab, 0.5)  # a pushed half way toward b
    wb = _warp(b, f_ba, 0.5)  # b pulled half way back toward a
    m = 0.5 * wa + 0.5 * wb
    alpha = m[..., 3:4]
    rgb = np.where(alpha > 1e-4, m[..., :3] / np.maximum(alpha, 1e-4), 0.0)
    # Harden the edge like the source art (binary-ish alpha).
    hard = np.clip((alpha - 0.35) / 0.3, 0.0, 1.0)
    out = np.concatenate([np.clip(rgb, 0.0, 1.0), hard], axis=2)
    return out


def write(who: str, clip: str, meta: dict, frames: list, out_dir: Path) -> None:
    boxes = []
    for f in frames:
        ys, xs = np.nonzero(f[..., 3] > 0.02)
        if len(xs) == 0:
            boxes.append((0, 0, 1, 1))
        else:
            boxes.append((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    pad = 4
    W = sum(b[2] - b[0] + pad for b in boxes)
    H = max(b[3] - b[1] for b in boxes)
    sheet = np.zeros((H, W, 4), np.float32)
    x = 0
    out_frames = []
    for f, (x0, y0, x1, y1) in zip(frames, boxes):
        w, h = x1 - x0, y1 - y0
        sheet[0:h, x:x + w] = f[y0:y1, x0:x1]
        out_frames.append({"x": int(x), "y": 0, "w": int(w), "h": int(h), "ox": int(x0), "oy": int(y0)})
        x += int(w) + pad
    out_dir.mkdir(parents=True, exist_ok=True)
    Image.fromarray((sheet * 255).round().astype(np.uint8), "RGBA").save(out_dir / f"{clip}.png")
    m2 = dict(meta)
    m2["frames"] = out_frames
    (out_dir / f"{clip}.json").write_text(json.dumps(m2, separators=(",", ":")))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("who")
    ap.add_argument("clip")
    ap.add_argument("--out", default="")
    ap.add_argument("--fps", type=float, default=0.0, help="source fps if the JSON has none")
    ap.add_argument("--loop", type=int, default=-1, help="1 loop / 0 one-shot (default from JSON)")
    args = ap.parse_args()
    meta, frames = load_clip(args.who, args.clip)
    loop = bool(meta.get("loop", False)) if args.loop < 0 else bool(args.loop)
    dis = cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_MEDIUM)
    out = []
    n = len(frames)
    for i in range(n):
        out.append(frames[i])
        if i + 1 < n:
            out.append(middle(frames[i], frames[i + 1], dis))
        elif loop:
            out.append(middle(frames[i], frames[0], dis))
    src_fps = float(meta.get("fps", args.fps if args.fps > 0 else 10.0))
    meta["fps"] = round(src_fps * 2.0, 2)
    meta["loop"] = loop
    if "hit" in meta:
        meta["hit"] = int(meta["hit"]) * 2
    meta["tweened"] = True
    out_dir = Path(args.out) if args.out else SPRITES / args.who
    write(args.who, args.clip, meta, out, out_dir)
    print(f"{args.who}/{args.clip}: {n} -> {len(out)} frames, fps {src_fps} -> {meta['fps']}, loop={loop} -> {out_dir}")


if __name__ == "__main__":
    main()
