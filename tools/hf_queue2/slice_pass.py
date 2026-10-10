"""Slice pass-6 clips into staged sheets (/tmp/claude-0/pol/e2/<who>/<clip>)."""
import json, subprocess, sys, os
from PIL import Image
HN = "/home/user/hnt"; Q = HN + "/tools/hf_queue2"; ST = "/tmp/claude-0/pol/e2"
def idle_h(who):
    d = json.load(open(f"{HN}/assets/sprites/{who}/idle.json")); f = d["frames"][0]
    im = Image.open(f"{HN}/assets/sprites/{who}/idle.png").convert("RGBA").crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))
    bb = im.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
    return bb[3] - bb[1]
# name -> (who, clip, extra args)
STRIKE = ["--frames", "12", "--retract", "4", "--hold", "1", "PEAK"]
MAP = {
 "cop_walk_down": ("cop", "walk_down", ["--loop", "--frames", "16", "--fps", "15", "--start", "1.0"]),
 "son_walk_up": ("son", "walk_up", ["--loop", "--frames", "16", "--fps", "15", "--start", "2.0"]),
 "son_walk_up2": ("son", "walk_up", ["--loop", "--frames", "16", "--fps", "15", "--start", "0.6"]),
 "bailiff_walk_up2": ("bailiff", "walk_up", ["--loop", "--frames", "16", "--fps", "15", "--start", "1.2"]),
 "son_roll": ("son", "roll", ["--frames", "18", "--anchor", "ground", "--start", "0.4"]),
 "lot_hydra_walk_up": ("lot_hydra", "walk_down", ["--loop", "--frames", "16", "--fps", "15", "--start", "2.0"]),
 "shift_lead_hurt2": ("shift_lead", "hurt", ["--frames", "13"]),
 "bag_snatch_punch_high2": ("bag_snatch", "punch_high", STRIKE),
 "clamp_king_hurt2": ("clamp_king", "hurt", ["--frames", "13"]),
 "repo_goon_idle": ("repo_goon", "idle", ["--loop", "--frames", "16", "--min-cycle", "1.0", "--max-cycle", "1.8"]),
 "valet_hurt2": ("valet", "hurt", ["--frames", "13"]),
 "valet_walk": ("valet", "walk", ["--loop", "--frames", "16", "--fps", "15", "--start", "0.8"]),
 "son_walk_down": ("son", "walk_down", ["--loop", "--frames", "16", "--fps", "15", "--start", "1.0"]),
 "bailiff_walk_up": ("bailiff", "walk_up", ["--loop", "--frames", "16", "--fps", "15", "--start", "1.0"]),
 "clipboard_flier_walk_up": ("clipboard_flier", "walk_up", ["--loop", "--frames", "16", "--fps", "15", "--start", "2.0"]),
 "valet_walk_up": ("valet", "walk_up", ["--loop", "--frames", "16", "--fps", "15", "--start", "1.6"]),
 "lot_hydra_walk_down": ("lot_hydra", "walk_down", ["--loop", "--frames", "16", "--fps", "15", "--start", "1.0"]),
 "punk_punch_mid": ("punk", "punch_mid", STRIKE),
 "shift_lead_punch_mid": ("shift_lead", "punch_mid", STRIKE),
 "bag_snatch_punch_high": ("bag_snatch", "punch_high", STRIKE),
 "valet_hurt": ("valet", "hurt", ["--frames", "13"]),
 "shift_lead_hurt": ("shift_lead", "hurt", ["--frames", "13"]),
 "coping_imp_hurt": ("coping_imp", "hurt", ["--frames", "13"]),
 "clipboard_flier_hurt": ("clipboard_flier", "hurt", ["--frames", "13"]),
 "clamp_king_hurt": ("clamp_king", "hurt", ["--frames", "13"]),
 "clamp_king_death": ("clamp_king", "death", ["--frames", "20"]),
 "coping_imp_death": ("coping_imp", "death", ["--frames", "20"]),
 "lot_hydra_death": ("lot_hydra", "death", ["--frames", "20"]),
 "clipboard_flier_death": ("clipboard_flier", "death", ["--frames", "20"]),
}
FF = "/usr/local/lib/python3.11/dist-packages/imageio_ffmpeg/binaries/ffmpeg-linux-x86_64-v7.0.2"
def smooth(name):
    """16 fps HF clip -> 48 fps with motion-compensated in-betweens."""
    os.makedirs(f"{Q}/i48", exist_ok=True)
    out = f"{Q}/i48/{name}.mp4"
    if not os.path.exists(out):
        subprocess.run([FF, "-y", "-loglevel", "error", "-i", f"{Q}/{name}.mp4", "-vf",
            "minterpolate=fps=48:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1", "-c:v", "libx264", "-crf", "12", "-pix_fmt", "yuv420p", out], check=True)
    return out
def peak(video):
    import numpy as np
    sys.path.insert(0, HN + "/tools")
    import video2sprite as V
    keys, fps = V.keyed_cached(video)
    xs = [int(np.nonzero((k[..., 3] >= 0.5).any(0))[0].max()) if (k[..., 3] >= 0.5).any() else 0 for k in keys]
    return int(np.argmax(xs)) / fps
import re
def spec(name):
    if name in MAP:
        return MAP[name]
    base = re.sub(r"\d+$", "", name)
    for clip, extra in (("punch_high", STRIKE), ("kick_low", STRIKE), ("punch_mid", STRIKE), ("hurt", ["--frames", "13"]), ("death", ["--frames", "20"])):
        if base.endswith("_" + clip):
            return (base[: -len(clip) - 1], clip, extra)
    raise KeyError(name)
for name in sys.argv[1:]:
    who, clip, extra = spec(name)
    h = idle_h(who)
    vid = smooth(name)
    if "PEAK" in extra:
        pk = peak(vid)
        extra = [e for e in extra if e != "PEAK"] + ["--start", "%.3f" % max(0.0, pk - 0.42), "--end", "%.3f" % pk]
    cmd = ["python3", f"{HN}/tools/video2sprite.py", vid, who, clip, "--stand-frame", "0", "--stand", str(h), "--out", ST] + extra
    r = subprocess.run(cmd, capture_output=True, text=True)
    print(name, "->", who, clip, "H", h, (r.stdout.strip().splitlines() or [""])[-1], r.stderr.strip()[-300:])
    gif = f"{ST}/{who}/{clip}_preview.gif"
    if os.path.exists(gif): os.remove(gif)
