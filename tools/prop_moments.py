"""Sort each living prop's idle frames into a calm rest frame and the
"moments" that may pop now and then (steam, a spark, a lid lifting), and
drop frames that are a different object altogether (a silver manhole on a
dark one). Props whose every frame is the same body moving (a flag, moths
round a lamp) keep looping. Writes "rest", "moments" and "mode" into each
assets/sprites/<prop>/idle.json.

    python tools/prop_moments.py [--dry]
"""
import glob, json, os, sys
import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
# Characters and townsfolk animate for real; leave them alone.
SKIP = {"bystander", "npc_old_man", "npc_old_woman", "npc_sanitation", "crew", "father", "son"}
# The whole clip is one thing moving (cloth in the wind, moths round a
# lamp): keep it looping.
LOOP = {"flag", "sodium_lamp", "lamp", "barrel", "blood_mart", "hatchback"}


def canvas(sheet, f, cell):
    c = np.zeros((cell[1], cell[0], 4), dtype=np.uint8)
    fr = np.asarray(sheet.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])))
    c[f["oy"]:f["oy"] + f["h"], f["ox"]:f["ox"] + f["w"]] = fr
    return c


def sim(a, b):
    """How much b is the same object as a: overlap of the solid shapes and
    colour agreement where both are solid."""
    ma, mb = a[..., 3] > 128, b[..., 3] > 128
    inter = ma & mb
    union = ma | mb
    if union.sum() == 0:
        return 1.0, 1.0
    iou = inter.sum() / union.sum()
    # Of a's body, how much is still there in b (effects outside don't count).
    keep = inter.sum() / max(1, ma.sum())
    if inter.sum() == 0:
        return iou, 0.0
    d = np.abs(a[..., :3].astype(int) - b[..., :3].astype(int))[inter].mean() / 255.0
    return iou, keep * (1.0 - d * 2.5)


def main(dry):
    for meta_path in sorted(glob.glob(os.path.join(ROOT, "*", "idle.json"))):
        who = os.path.basename(os.path.dirname(meta_path))
        if who in SKIP:
            continue
        others = [p for p in glob.glob(os.path.join(os.path.dirname(meta_path), "*.json")) if not p.endswith("idle.json")]
        if any(os.path.basename(p).startswith(("walk", "hurt", "death", "punch")) for p in others):
            continue
        meta = json.load(open(meta_path))
        fr = meta.get("frames", [])
        if len(fr) < 3:
            continue
        sheet = Image.open(meta_path[:-5] + ".png").convert("RGBA")
        cvs = [canvas(sheet, f, meta["cell"]) for f in fr]
        n = len(cvs)
        S = np.zeros((n, n))
        for i in range(n):
            for j in range(n):
                S[i, j] = sim(cvs[i], cvs[j])[1]
        rest = int(np.argmax(S.sum(axis=1)))          # the most typical frame
        score = S[rest]
        same = [j for j in range(n) if score[j] > 0.80]
        moments = [j for j in range(n) if j != rest and 0.55 < score[j]]
        mode = "loop" if (len(same) >= n - 1 or who in LOOP) else "moments"
        dropped = [j for j in range(n) if j != rest and j not in moments]
        print(f"{who:14s} mode={mode:7s} rest={rest:2d} moments={moments} dropped={dropped}")
        if not dry:
            meta["rest"] = rest
            meta["moments"] = moments
            meta["mode"] = mode
            json.dump(meta, open(meta_path, "w"), separators=(",", ":"))


if __name__ == "__main__":
    main("--dry" in sys.argv)
