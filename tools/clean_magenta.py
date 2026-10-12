#!/usr/bin/env python3
"""Remove chroma-key magenta left inside world sprites (holes the keyer did
not reach: between chain links, under cars, between legs). Strict key pink
-> transparent, then one ring of pinkish fringe next to it. Cards, UI,
icons, gear and mission art keep their purples.

    python3 tools/clean_magenta.py [--dry]
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1] / "assets" / "sprites"
SKIP = {"cards", "ui", "icons", "missions", "gear", "survive", "vault", "guns", "held", "field", "hub"}


def clean(path: Path, dry: bool) -> int:
    im = np.array(Image.open(path).convert("RGBA")).astype(np.int32)
    r, g, b, a = im[..., 0], im[..., 1], im[..., 2], im[..., 3]
    strict = (a > 20) & (r > 130) & (b > 100) & (g < 0.55 * np.minimum(r, b)) & (np.abs(r - b) < 110)
    n = int(strict.sum())
    if n < 30:
        return 0
    soft = (a > 0) & (r > 100) & (b > 80) & (g < 0.72 * np.minimum(r, b)) & (np.abs(r - b) < 120)
    near = ndimage.binary_dilation(strict, iterations=1)
    kill = strict | (soft & near)
    if not dry:
        im[kill, 3] = 0
        Image.fromarray(im.astype(np.uint8), "RGBA").save(path)
    return int(kill.sum())


def main() -> None:
    dry = "--dry" in sys.argv
    for d in sorted(ROOT.iterdir()):
        if not d.is_dir() or d.name in SKIP:
            continue
        for p in sorted(d.glob("*.png")):
            k = clean(p, dry)
            if k:
                print(f"{d.name}/{p.name}: {k} px")


if __name__ == "__main__":
    main()


## Second pass, props only: darker key purple blended into wood / steel
## (hue 285-335 degrees, saturated). Figures are left alone.
PROPS = ["scaffold", "bench", "cart", "chain", "web_anchor", "hood", "geyser", "flag", "awning", "kiosk", "billboard", "hydrant", "cop_car"]


def clean_hue(path: Path) -> int:
    import colorsys  # noqa: F401
    im = np.array(Image.open(path).convert("RGBA")).astype(np.float32)
    rgb = im[..., :3] / 255.0
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    d = np.maximum(mx - mn, 1e-6)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60.0
    s = d / np.maximum(mx, 1e-6)
    kill = (im[..., 3] > 0) & (h >= 285) & (h <= 335) & (s > 0.42) & (mx > 0.16)
    n = int(kill.sum())
    if n:
        im[kill, 3] = 0
        Image.fromarray(im.astype(np.uint8), "RGBA").save(path)
    return n


if __name__ == "__main__" and "--props" in sys.argv and "--dry" not in sys.argv:
    for name in PROPS:
        for p in sorted((ROOT / name).glob("*.png")):
            k = clean_hue(p)
            if k:
                print(f"hue {name}/{p.name}: {k} px")
    q = ROOT / "props" / "shop_cart.png"
    if q.exists():
        print("hue props/shop_cart.png:", clean_hue(q))
