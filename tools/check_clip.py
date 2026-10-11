"""Check a new character clip against the clips already in the game before
pushing it. Compares resolution, how tall the character stands in frame,
where his feet are, whether he stays centred, the green background and the
length, against the existing clips of the same character (or any clip when
he has none yet).

    pip install pillow numpy imageio-ffmpeg
    python tools/check_clip.py path/to/bailiff_walk_up.mp4 [more.mp4 ...]

Prints PASS or FAIL per clip with the reasons, and writes a strip of 8
frames next to the clip (<name>_check.png) to look at by eye.
"""
import glob, json, os, subprocess, sys, tempfile
import numpy as np
from PIL import Image

try:
    import imageio_ffmpeg
    FF = imageio_ffmpeg.get_ffmpeg_exe()
except Exception:
    FF = "ffmpeg"

HERE = os.path.dirname(os.path.abspath(__file__))
REF_DIRS = [os.path.join(HERE, "hf_queue2"), os.path.join(HERE, "hf_queue")]


def frames(path, n=8):
    """n evenly spaced RGB frames plus (w, h, seconds)."""
    with tempfile.TemporaryDirectory() as d:
        subprocess.run([FF, "-v", "error", "-i", path, "-vf", "fps=8", os.path.join(d, "f%03d.png")], check=True)
        files = sorted(glob.glob(os.path.join(d, "*.png")))
        if not files:
            return [], (0, 0, 0.0)
        secs = len(files) / 8.0
        pick = [files[round(i * (len(files) - 1) / max(1, n - 1))] for i in range(n)]
        ims = [np.asarray(Image.open(f).convert("RGB")).astype(np.int16) for f in pick]
    h, w = ims[0].shape[:2]
    return ims, (w, h, secs)


def body(im):
    """Bounding box of the non-green pixels as fractions of the frame."""
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    green = (g > 90) & (g - np.maximum(r, b) > 40)
    fg = ~green
    # Ignore specks: a column/row counts with at least 3 body pixels.
    cols = np.where(fg.sum(axis=0) >= 3)[0]
    rows = np.where(fg.sum(axis=1) >= 3)[0]
    h, w = fg.shape
    if len(cols) == 0 or len(rows) == 0:
        return None
    return {
        "height": (rows[-1] - rows[0]) / h,
        "feet": rows[-1] / h,
        "cx": (cols[0] + cols[-1]) / 2.0 / w,
        "green": float(green[:, :max(4, w // 40)].mean() + green[:, -max(4, w // 40):].mean()) / 2.0,
        "edge": bool(cols[0] <= 1 or cols[-1] >= w - 2 or rows[0] <= 1),
    }


def stats(path):
    ims, (w, h, secs) = frames(path)
    bs = [body(i) for i in ims]
    bs = [b for b in bs if b]
    if not bs:
        return None
    med = lambda k: float(np.median([b[k] for b in bs]))
    return {
        "w": w, "h": h, "secs": secs,
        "height": med("height"), "feet": med("feet"), "cx": med("cx"),
        "green": min(b["green"] for b in bs),
        "height_spread": max(b["height"] for b in bs) - min(b["height"] for b in bs),
        "cx_spread": max(b["cx"] for b in bs) - min(b["cx"] for b in bs),
        "edge": any(b["edge"] for b in bs),
        "ims": ims,
    }


def refs(who):
    out = []
    for d in REF_DIRS:
        out += glob.glob(os.path.join(d, who + "_*.mp4"))
    if not out:
        for d in REF_DIRS:
            out += glob.glob(os.path.join(d, "*.mp4"))[:6]
    return out


def check(path):
    name = os.path.basename(path)
    who = name.rsplit(".", 1)[0]
    for move in ("_walk", "_kick", "_punch", "_hurt", "_death", "_idle", "_run", "_roll"):
        if move in who:
            who = who.split(move)[0]
            break
    me = stats(path)
    if me is None:
        print(f"FAIL {name}: no character found (is the background green?)")
        return False
    rs = [s for s in (stats(r) for r in refs(who) if os.path.abspath(r) != os.path.abspath(path)) if s]
    bad = []
    # Without the clips on this machine, the numbers measured from them
    # (tools/clip_refs.json, committed) stand in.
    table = {}
    tp = os.path.join(HERE, "clip_refs.json")
    if os.path.exists(tp):
        table = json.load(open(tp))
    rh = rf = rw = None
    if rs:
        rh = float(np.median([s["height"] for s in rs]))
        rf = float(np.median([s["feet"] for s in rs]))
        rw = max(set((s["w"], s["h"]) for s in rs), key=[(s["w"], s["h"]) for s in rs].count)
    elif table:
        t = table.get(who, table.get("_any"))
        rh, rf, rw = t["height"], t["feet"], (t["w"], t["h"])
    if rh is not None:
        if (me["w"], me["h"]) != rw:
            bad.append(f"size {me['w']}x{me['h']}, the others are {rw[0]}x{rw[1]}")
        if abs(me["height"] - rh) > 0.08:
            bad.append(f"he fills {me['height']:.0%} of the frame height, the others {rh:.0%} (zoomed {'in' if me['height'] > rh else 'out'})")
        if abs(me["feet"] - rf) > 0.06:
            bad.append(f"feet at {me['feet']:.0%} down the frame, the others at {rf:.0%}")
    if me["green"] < 0.9:
        bad.append("the background is not flat green at the edges")
    if me["edge"]:
        bad.append("he touches the edge of the frame (cut off)")
    if me["cx_spread"] > 0.18 and "walk" not in name:
        bad.append("he drifts sideways a lot (the camera or he moves)")
    if me["height_spread"] > 0.22 and not any(k in name for k in ("death", "hurt", "roll", "kick")):
        bad.append("his size jumps between frames")
    if me["secs"] < 1.0:
        bad.append(f"only {me['secs']:.1f}s long")
    strip = Image.fromarray(np.concatenate([i.clip(0, 255).astype(np.uint8) for i in me["ims"]], axis=1))
    strip.thumbnail((2400, 400))
    strip.save(os.path.splitext(path)[0] + "_check.png")
    if bad:
        print(f"FAIL {name}:")
        for b in bad:
            print("   - " + b)
        return False
    print(f"PASS {name}  ({me['w']}x{me['h']}, {me['secs']:.1f}s, fills {me['height']:.0%})")
    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    ok = all([check(p) for p in sys.argv[1:]])
    sys.exit(0 if ok else 2)
