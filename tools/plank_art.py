"""Pixel-art lumber for Benny's builds in the hideout: four planks (two
boards, a beam, a short offcut) with grain, knots, nail heads, a lit top
edge and one dark outline. One row, each plank in its own 56x10 cell.

    python tools/plank_art.py   ->  assets/sprites/camp/planks.png
"""
import os, random
import numpy as np
from PIL import Image

CW, CH = 56, 10
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "camp")
INK = (22, 14, 10)
WOOD = [(70, 44, 26), (104, 68, 38), (140, 96, 56), (176, 126, 76), (206, 160, 104)]
NAIL = (150, 150, 158)


def plank(length, thick, seed, light=1.0):
    rnd = random.Random(seed)
    img = np.zeros((CH, CW, 4), np.uint8)
    x0 = (CW - length) // 2
    y0 = (CH - thick) // 2
    knots = [(rnd.randint(x0 + 6, x0 + length - 7), rnd.randint(y0 + 1, y0 + thick - 2)) for _ in range(rnd.randint(1, 2))]
    phase = rnd.random() * 6.0
    for y in range(y0, y0 + thick):
        for x in range(x0, x0 + length):
            t = (y - y0) / max(1, thick - 1)
            v = 2.6 - t * 1.6                      # lit top, shaded underside
            # Grain: long wavy streaks along the board.
            g = np.sin((x - x0) * 0.21 + y * 1.7 + phase + np.sin(x * 0.07) * 1.3)
            if g > 0.75:
                v -= 0.8
            for kx, ky in knots:
                d = ((x - kx) / 2.2) ** 2 + ((y - ky) / 1.2) ** 2
                if d < 1.0:
                    v -= 1.4 if d < 0.4 else 0.8
            if y == y0:
                v += 0.9                           # top edge catches the bulb
            v = max(0, min(len(WOOD) - 1, int(round(v * light))))
            img[y, x, :3] = WOOD[v]
            img[y, x, 3] = 255
    # Saw-cut ends a shade darker, nail heads near each end.
    for y in range(y0, y0 + thick):
        img[y, x0, :3] = WOOD[1]
        img[y, x0 + length - 1, :3] = WOOD[1]
    ny = y0 + thick // 2
    for nx in (x0 + 3, x0 + length - 4):
        img[ny, nx, :3] = NAIL
    # One dark outline around the board.
    a = img[..., 3] > 0
    edge = np.zeros_like(a)
    edge[1:, :] |= a[:-1, :]
    edge[:-1, :] |= a[1:, :]
    edge[:, 1:] |= a[:, :-1]
    edge[:, :-1] |= a[:, 1:]
    edge &= ~a
    img[edge, :3] = INK
    img[edge, 3] = 255
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    cells = [plank(44, 5, 1), plank(52, 5, 2, 0.95), plank(40, 6, 3, 1.05), plank(28, 5, 4)]
    sheet = np.concatenate(cells, axis=1)
    Image.fromarray(sheet, "RGBA").save(os.path.join(OUT, "planks.png"))
    print("OK", len(cells), CW, CH)


if __name__ == "__main__":
    main()
