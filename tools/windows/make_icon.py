#!/usr/bin/env python3
"""Write the FnS icon (ICO + PNGs): the father's and the son's heads and
shoulders side by side, turned toward each other, cut from their own idle
sprites, under a warm lamp glow in a gold frame."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SPRITES = ROOT / "assets" / "sprites"
OUT_DIR = ROOT / "assets" / "icon"
GOLD = (201, 162, 39, 255)


def frame(who: str, clip: str, i: int) -> Image.Image:
    meta = json.loads((SPRITES / who / f"{clip}.json").read_text())
    sheet = Image.open(SPRITES / who / f"{clip}.png").convert("RGBA")
    f = meta["frames"][i]
    cell = Image.new("RGBA", tuple(meta["cell"]))
    cell.alpha_composite(sheet.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])), (f["ox"], f["oy"]))
    return cell.crop(cell.getbbox())


def bust(img: Image.Image, frac: float = 0.36) -> Image.Image:
    return img.crop((0, 0, img.width, int(img.height * frac)))


def draw(size: int = 512) -> Image.Image:
    dad = bust(frame("father", "idle_casual", 0))
    kid = bust(frame("son", "idle_casual", 0)).transpose(Image.FLIP_LEFT_RIGHT)
    bg = Image.new("RGBA", (size, size), (14, 14, 22, 255))
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((60, 40, 452, 420), fill=(201, 140, 60, 120))
    bg.alpha_composite(glow.filter(ImageFilter.GaussianBlur(70)))
    h = int(size * 0.86)
    k = h / dad.height
    d2 = dad.resize((int(dad.width * k), int(dad.height * k)), Image.NEAREST)
    k2 = k * 0.93
    s2 = kid.resize((int(kid.width * k2), int(kid.height * k2)), Image.NEAREST)
    bg.alpha_composite(d2, (size // 2 - d2.width + 40, size - d2.height))
    bg.alpha_composite(s2, (size // 2 - 40, size - s2.height))
    ImageDraw.Draw(bg).rounded_rectangle((6, 6, size - 7, size - 7), radius=48, outline=GOLD, width=14)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=54, fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(bg, (0, 0), mask)
    return out


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    big = draw(512)
    big.resize((256, 256), Image.LANCZOS).save(OUT_DIR / "fns.png")
    big.resize((32, 32), Image.LANCZOS).save(OUT_DIR / "fns-32.png")
    big.save(OUT_DIR / "fns.ico", sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print("icon:", OUT_DIR / "fns.ico")


if __name__ == "__main__":
    main()
