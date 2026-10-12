#!/usr/bin/env python3
"""Turn a generated clip into a finished game sprite sheet that matches the
game exactly, and refuse it when it does not.

    python finish_clip.py clips/bailiff_walk_back.mp4 [more.mp4 ...]

For every clip it:
  1. works out the game clip it becomes (walk_back -> walk_up, walk_front ->
     walk_down, walk_ur, walk_dr, kick_front -> kick_low, punch_free ->
     punch_high, roll) and the reference in the game it must match
     (assets/sprites/<who>/<clip>.json if the game has it, else the
     character's walk.json);
  2. for walks: finds exactly ONE full stride -- two steps, both legs go all
     the way round and the last frame leads straight back into the first
     (not half a step, not one and a half);
  3. resamples it to EXACTLY the reference's frame count, at the reference's
     fps, the body scaled to EXACTLY the character's height in the game (in
     pixels), feet on the same row, in the same 288 px cell;
  4. checks all of that again on the result and writes
       finished/<who>/<clip>.png + .json   (the sheet, game format)
       finished/<who>/<clip>_preview.gif   (in-game speed, loops)
       finished/<who>/<clip>_compare.png   (game frame next to the new one)
     and prints PASS or FAIL with the reasons.

Only push clips that PASS. Needs: pillow numpy scipy imageio imageio-ffmpeg
"""
import json, os, subprocess, sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SPRITES = ROOT / "assets" / "sprites"
OUT = HERE / "finished"
V2S = ROOT / "tools" / "video2sprite.py"

# local clip move -> (game clip, kind)
MOVES = {
    "walk_back": ("walk_up", "walk"), "walk_front": ("walk_down", "walk"),
    "walk_ur": ("walk_ur", "walk"), "walk_dr": ("walk_dr", "walk"),
    "walk": ("walk", "walk"), "run": ("parkour_run", "walk"),
    "kick_front": ("kick_low", "strike"), "punch_free": ("punch_high", "strike"),
    "roll": ("roll", "action"),
}


def split(name):
    for move in sorted(MOVES, key=len, reverse=True):
        if name.endswith("_" + move):
            return name[: -len(move) - 1], move
    raise SystemExit(f"{name}: unknown move (expected one of {', '.join(MOVES)})")


def sheet_frames(meta_path):
    meta = json.loads(meta_path.read_text())
    sheet = Image.open(meta_path.with_suffix(".png")).convert("RGBA")
    cw, ch = meta["cell"]
    out = []
    for f in meta["frames"]:
        c = Image.new("RGBA", (cw, ch))
        c.alpha_composite(sheet.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])), (f["ox"], f["oy"]))
        out.append(c)
    return meta, out


def body_box(im):
    return im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()


def body_h(im):
    bb = body_box(im)
    return 0 if bb is None else bb[3] - bb[1]


def game_height(who):
    """The character's standing height in the game, in sheet pixels."""
    for ref in ("idle", "walk"):
        p = SPRITES / who / f"{ref}.json"
        if p.exists():
            return body_h(sheet_frames(p)[1][0])
    raise SystemExit(f"{who}: no idle/walk in assets/sprites/{who} to measure")


def reference(who, clip):
    for c in (clip, "walk"):
        p = SPRITES / who / f"{c}.json"
        if p.exists():
            return p
    raise SystemExit(f"{who}: no {clip}.json or walk.json in the game")


def smooth(path):
    """16 fps clip -> 48 fps with motion-compensated in-betweens (the same
    step the game's own clips went through), so a short stride still has a
    distinct pose for every game frame."""
    try:
        import imageio_ffmpeg
        ff = imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        ff = "ffmpeg"
    out = OUT / "_48fps" / path.name
    out.parent.mkdir(parents=True, exist_ok=True)
    if not out.exists() or out.stat().st_mtime < path.stat().st_mtime:
        subprocess.run([ff, "-y", "-loglevel", "error", "-i", str(path), "-vf",
                        "minterpolate=fps=48:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1",
                        "-c:v", "libx264", "-crf", "12", "-pix_fmt", "yuv420p", str(out)], check=True)
    return out


def finish(path):
    path = Path(path)
    who, move = split(path.stem)
    clip, kind = MOVES[move]
    ref_path = reference(who, clip)
    ref_meta, ref_frames = sheet_frames(ref_path)
    n = len(ref_meta["frames"])
    fps = float(ref_meta.get("fps") or 12.0)
    H = game_height(who)
    cell = ref_meta["cell"]
    main = n
    extra = []
    if kind == "walk":
        extra = ["--loop", "--stride"]
    elif kind == "strike":
        # The game's strikes: wind-up..peak, the peak held, then back to guard.
        hit = int(ref_meta.get("hit", n - 6))
        main = hit + 1
        back = max(0, n - main - 1)
        extra = ["--hold", "1", "--retract", str(back)]
    cmd = [sys.executable, str(V2S), str(smooth(path)), who, clip, "--frames", str(main), "--fps", "%.2f" % fps,
           "--stand", str(H), "--stand-frame", "0", "--out", str(OUT)] + extra
    r = subprocess.run(cmd, capture_output=True, text=True)
    log = (r.stdout + r.stderr).strip()
    bad = []
    if r.returncode != 0:
        print(f"FAIL {path.name}: slicer error\n{log[-800:]}")
        return False
    out_json = OUT / who / f"{clip}.json"
    meta, frames = sheet_frames(out_json)
    # --- the checks -----------------------------------------------------------
    if len(frames) != n:
        bad.append(f"{len(frames)} frames, the game's {clip} has {n}")
    h0 = body_h(frames[0])
    if abs(h0 - H) > 3:
        bad.append(f"body {h0} px tall in frame 1, the game draws {who} {H} px tall")
    feet = [body_box(f)[3] for f in frames if body_box(f)]
    if max(feet) - min(feet) > 6 and kind == "walk":
        bad.append(f"feet jump {max(feet) - min(feet)} px between frames (should stay on the floor row)")
    heights = [body_h(f) for f in frames]
    if kind == "walk" and (max(heights) - min(heights)) > 0.12 * H:
        bad.append(f"body height changes {min(heights)}-{max(heights)} px over the cycle (zoom or morph)")
    if kind == "walk":
        line = [l for l in log.splitlines() if l.startswith("stride")]
        if line:
            # "stride a..b (Ts = 2 steps of k frames), mismatch d"
            txt = line[0]
            mism = float(txt.rsplit("mismatch", 1)[1])
            if mism > 0.075:
                bad.append(f"the loop does not close (last pose vs first: {mism:.3f}, needs < 0.075) -- make the clip again")
        else:
            bad.append("no full stride found (needs two full steps in the clip)")
        # Loop seam: last frame -> first frame must look like any other step.
        a = [np.asarray(f).astype(np.float32) / 255.0 for f in frames]
        steps = [float(np.abs(a[i + 1] - a[i]).mean()) for i in range(len(a) - 1)]
        if min(steps) < 1e-5:
            bad.append("two frames in a row are identical (the stride is too short in the clip: make it slower or longer)")
        seam = float(np.abs(a[0] - a[-1]).mean())
        if seam > 2.2 * max(1e-6, float(np.median(steps))):
            bad.append(f"pop at the loop point (jump {seam:.4f} vs normal step {np.median(steps):.4f})")
    # --- compare picture: the game's frame 1 next to the new frame 1 ---------
    cmp_im = Image.new("RGBA", (cell[0] * 2 + 20, cell[1]), (40, 40, 50, 255))
    cmp_im.alpha_composite(ref_frames[0].resize((cell[0], cell[1])) if ref_frames[0].size != tuple(cell) else ref_frames[0], (0, 0))
    cmp_im.alpha_composite(frames[0], (cell[0] + 20, 0))
    cmp_im.save(OUT / who / f"{clip}_compare.png")
    if bad:
        print(f"FAIL {path.name} -> {who}/{clip}:")
        for b in bad:
            print("   - " + b)
        return False
    print(f"PASS {path.name} -> {who}/{clip}: {n} frames @ {fps:.2f} fps, body {h0} px (game {H}), "
          f"cell {meta['cell'][0]}x{meta['cell'][1]}  [{OUT / who}]")
    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    OUT.mkdir(exist_ok=True)
    ok = [finish(p) for p in sys.argv[1:]]
    sys.exit(0 if all(ok) else 2)
