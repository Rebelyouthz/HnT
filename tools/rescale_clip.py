"""Scale one clip of a character (every frame), keeping the feet on the same
floor row and the body on the same centre column, so the clip matches the
character's other clips.

    python tools/rescale_clip.py son walk 0.92

Writes assets/sprites/<who>/<clip>.png/.json in place (git keeps the old one).
"""
import json, sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent / "assets" / "sprites"


def main(who, clip, k):
    k = float(k)
    js = ROOT / who / f"{clip}.json"
    meta = json.loads(js.read_text())
    sheet = Image.open(js.with_suffix(".png")).convert("RGBA")
    cw, ch = meta["cell"]
    frames = []
    for f in meta["frames"]:
        im = sheet.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))
        w, h = max(1, round(f["w"] * k)), max(1, round(f["h"] * k))
        im = im.resize((w, h), Image.LANCZOS)
        # Feet (bottom of the cell box) stay put; x scales about the cell centre.
        bottom = f["oy"] + f["h"]
        cx = f["ox"] + f["w"] / 2.0
        ox = round(cw / 2.0 + (cx - cw / 2.0) * k - w / 2.0)
        oy = bottom - h
        frames.append((im, ox, oy))
    # Repack in one row per 8 frames.
    cols = min(8, len(frames))
    rows = (len(frames) + cols - 1) // cols
    cell_w = max(im.width for im, _, _ in frames) + 4
    cell_h = max(im.height for im, _, _ in frames) + 4
    out = Image.new("RGBA", (cols * cell_w, rows * cell_h))
    new = []
    for i, (im, ox, oy) in enumerate(frames):
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        out.paste(im, (x, y))
        new.append({"x": x, "y": y, "w": im.width, "h": im.height, "ox": ox, "oy": oy})
    meta["frames"] = new
    if "scale" in meta:
        meta["scale"] = round(float(meta["scale"]) * k, 5)
    out.save(js.with_suffix(".png"))
    js.write_text(json.dumps(meta, separators=(",", ":")))
    print(f"{who}/{clip}: {len(new)} frames scaled x{k}")


if __name__ == "__main__":
    main(*sys.argv[1:4])
