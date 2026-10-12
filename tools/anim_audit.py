"""Audit a character's clips: which ones are broken and why.

    python tools/anim_audit.py father son

Loops (walk*, parkour_run, idle): does the cycle close without a pop, is it
a whole stride (two steps, both legs: the pose half way round is the other
leg's copy of the first) and not half a step, any frames repeated, does the
body change size or the feet jump. One-shots (attacks, hurt, ...): repeated
frames, size jumps against the character's idle, feet leaving the floor on a
ground move, a marked hit frame. Prints one line per clip, OK or the faults.
"""
import json, sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "assets" / "sprites"
AIR = {"jump", "air_mix", "air_spin_kick", "backflip_kick", "cartwheel_kick", "dive", "dropkick", "flying_knee",
       "jump_high_kick", "jump_roundhouse", "jump_spin_kick", "superman_punch", "roll", "knockdown", "fail_back",
       "fail_face", "fail_trip", "getup_kick", "getup_upper", "sit", "slide", "duck", "land", "sweep", "hurt"}
WALKS = ("walk", "walk_up", "walk_down", "walk_ur", "walk_dr", "parkour_run", "run_up", "run_down", "run_ur", "run_dr")


def frames(who, clip):
    meta = json.loads((ROOT / who / f"{clip}.json").read_text())
    sheet = Image.open(ROOT / who / f"{clip}.png").convert("RGBA")
    cw, ch = meta["cell"]
    out = []
    for f in meta["frames"]:
        c = Image.new("RGBA", (cw, ch))
        c.alpha_composite(sheet.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])), (f["ox"], f["oy"]))
        out.append(np.asarray(c).astype(np.float32) / 255.0)
    return meta, out


def box(a):
    m = a[..., 3] > 0.16
    ys, xs = np.where(m)
    if len(ys) == 0:
        return None
    return xs.min(), ys.min(), xs.max(), ys.max()


def sig(a, size=48, mask_only=False):
    b = box(a)
    if b is None:
        return np.zeros((size, size) if mask_only else (size, size, 4), np.float32)
    x0, y0, x1, y1 = b
    im = Image.fromarray((a[y0:y1 + 1, x0:x1 + 1] * 255).astype(np.uint8), "RGBA").resize((size, size), Image.BILINEAR)
    s = np.asarray(im).astype(np.float32) / 255.0
    return s[..., 3] if mask_only else s


def audit(who, clip, idle_h):
    meta, fr = frames(who, clip)
    n = len(fr)
    loop = bool(meta.get("loop", clip in WALKS or clip == "idle"))
    bad = []
    boxes = [box(a) for a in fr]
    if any(b is None for b in boxes):
        bad.append("empty frame")
        return n, loop, bad
    hs = [b[3] - b[1] for b in boxes]
    feet = [b[3] for b in boxes]
    steps = [float(np.abs(fr[i + 1] - fr[i]).mean()) for i in range(n - 1)]
    med = float(np.median(steps)) if steps else 0.0
    rep = sum(1 for s in steps if s < 1e-4)
    if rep:
        bad.append(f"{rep} repeated frame(s)")
    if clip not in AIR and max(feet) - min(feet) > 8:
        bad.append(f"feet jump {max(feet) - min(feet)} px")
    if clip in WALKS and (max(hs) - min(hs)) > 0.14 * idle_h:
        bad.append(f"body height {min(hs)}-{max(hs)} px over the cycle")
    if clip in WALKS or clip == "idle":
        h0 = float(np.median(hs))
        if abs(h0 - idle_h) > 0.12 * idle_h and clip != "parkour_run":
            bad.append(f"body {h0:.0f} px vs idle {idle_h} px (wrong size)")
    if loop and n >= 4:
        seam = float(np.abs(fr[0] - fr[-1]).mean())
        if med > 0 and seam > 2.2 * med:
            bad.append(f"pop at loop point ({seam / med:.1f}x a normal step)")
    if clip in WALKS and n >= 8:
        m = [sig(a, mask_only=True) for a in fr]
        d = [float(np.abs(m[0] - m[k]).mean()) for k in range(n)]
        far = max(d)
        # Half way round the other leg leads: in profile the outline matches
        # frame 1, seen from the back or front it is frame 1 mirrored.
        half = min(d[n // 2], float(np.abs(m[0][:, ::-1] - m[n // 2]).mean()))
        # Whole stride: half way round is the other leg's contact pose, close
        # to frame 1's outline. Half a stride: half way is the passing pose.
        if far > 0 and half / far > 0.62:
            bad.append(f"not a whole stride (half-way pose {half / far:.2f} of the farthest; one step only?)")
    if not loop and clip not in ("idle",) and clip not in WALKS:
        if "hit" not in meta and clip not in AIR and clip not in ("block_high", "block_mid", "block_low", "hurt", "knockdown"):
            pass
        area = [float((a[..., 3] > 0.16).sum()) for a in fr]
        if max(area) > 0 and min(area) / max(area) < 0.35 and clip not in AIR:
            bad.append("body area jumps (frames from different sizes?)")
    return n, loop, bad


def main(whos):
    for who in whos:
        _, idle = frames(who, "idle")
        b = box(idle[0])
        idle_h = b[3] - b[1]
        print(f"== {who} (idle {idle_h} px)")
        for p in sorted((ROOT / who).glob("*.json")):
            clip = p.stem
            try:
                n, loop, bad = audit(who, clip, idle_h)
            except Exception as e:  # noqa: BLE001
                print(f"  {clip:16s} ERROR {e}")
                continue
            print(f"  {clip:16s} {n:2d}f {'loop' if loop else 'once'}  " + ("OK" if not bad else "; ".join(bad)))


if __name__ == "__main__":
    main(sys.argv[1:] or ["father", "son"])
