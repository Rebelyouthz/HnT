"""The hideout portal as a pixel-art sprite sheet: a ring Benny welded out of
scrap pipe (rivets, a cable, two little status lamps) standing on a pallet,
with a swirling rift inside. 12 looping frames side by side.

    python tools/portal_art.py   ->  assets/sprites/portal/portal_sheet.png
"""
import math, os
import numpy as np
from PIL import Image

W, H = 72, 100          # one frame at pixel-art resolution
UP = 2                  # nearest-neighbour upscale for the game
N = 12                  # frames in the loop
CX, CY = 36.0, 44.0     # rift centre
RX, RY = 22.0, 33.0     # rift radii (inside the pipe)
PIPE = 5.0              # pipe thickness

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "portal")

INK = np.array([14, 12, 18])
RIFT = [np.array(c) for c in ([8, 10, 30], [16, 30, 74], [26, 70, 140], [50, 130, 205], [120, 210, 245], [225, 250, 255])]
STEEL = [np.array(c) for c in ([40, 40, 48], [70, 68, 78], [104, 100, 108], [146, 140, 140], [196, 188, 176])]
RUST = np.array([120, 66, 38])
WOOD = [np.array(c) for c in ([58, 38, 24], [92, 62, 38], [128, 90, 56])]


def ramp(pal, v):
    v = min(0.999, max(0.0, v))
    f = v * (len(pal) - 1)
    i = int(f)
    return pal[i] + (pal[i + 1] - pal[i]) * (f - i)


def hash2(x, y, s=0):
    n = math.sin(x * 12.9898 + y * 78.233 + s * 37.719) * 43758.5453
    return n - math.floor(n)


def frame(t):
    img = np.zeros((H, W, 4), dtype=np.float64)
    ph = t / N * math.tau
    for y in range(H):
        for x in range(W):
            dx, dy = (x + 0.5 - CX) / RX, (y + 0.5 - CY) / RY
            d = math.hypot(dx, dy)
            if d < 1.0:
                # The rift: spiral bands pulled toward a bright core.
                a = math.atan2(dy, dx)
                sw = math.sin(a * 3.0 + d * 9.0 - ph * 2.0) * 0.5 + 0.5
                sw2 = math.sin(a * 5.0 - d * 14.0 + ph * 3.0) * 0.5 + 0.5
                v = (1.0 - d) ** 1.4 * 0.95 + sw * 0.28 * (1.0 - d * 0.5) + sw2 * 0.12
                v -= (d ** 6) * 0.35          # dark lip just inside the pipe
                v = round(v * 9.0) / 9.0      # hard pixel-art colour steps
                c = ramp(RIFT, v)
                # A thin bright rim where the rift meets the pipe.
                if d > 0.93 and math.sin(math.atan2(dy, dx) * 6.0 + ph * 4.0) > 0.2:
                    c = c * 0.3 + np.array([150, 230, 255]) * 0.7
                # Specks orbiting inward.
                if hash2(round(a * 7.0 + ph * 1.5), round(d * 18.0 - ph * 3.0), 3) > 0.94:
                    c = c * 0.4 + RIFT[-1] * 0.6
                img[y, x, :3] = c
                img[y, x, 3] = 1.0
            # The welded pipe ring around it.
            px, py = (x + 0.5 - CX) / (RX + PIPE), (y + 0.5 - CY) / (RY + PIPE)
            pd = math.hypot(px, py)
            if d >= 1.0 and pd < 1.0:
                # Round pipe: light from the top left, a highlight line, dark underside.
                across = min(1.0, max(0.0, (math.hypot(dx * RX, dy * RY) - RX) / PIPE))
                ang = math.atan2(py, px)
                light = 0.55 + 0.35 * math.cos(ang + 2.3) + 0.35 * (1.0 - abs(across - 0.35) * 2.2)
                c = ramp(STEEL, round(light * 6.0) / 6.0)
                # Rust blooms low on the ring.
                if py > 0.4 and hash2(x // 2, y // 2, 9) > 0.62:
                    c = c * 0.45 + RUST * 0.55
                # Weld seams every 45 degrees.
                seg = (ang / math.tau * 8.0) % 1.0
                if seg < 0.035 or seg > 0.965:
                    c = STEEL[1]
                img[y, x, :3] = c
                img[y, x, 3] = 1.0
    # Rivets on the pipe.
    for k in range(12):
        a = k / 12.0 * math.tau + 0.13
        rx, ry = CX + math.cos(a) * (RX + PIPE * 0.5), CY + math.sin(a) * (RY + PIPE * 0.5)
        x, y = int(rx), int(ry)
        if 0 <= x < W - 1 and 0 <= y < H - 1:
            img[y, x, :3] = STEEL[4]
            img[y + 1, x, :3] = STEEL[1]
    # The pallet it stands on.
    base_y = int(CY + RY + PIPE) - 1
    for y in range(base_y, min(H, base_y + 12)):
        for x in range(10, W - 10):
            row = y - base_y
            if row in (0, 1, 2) or row in (8, 9, 10, 11) and (x - 10) % 22 < 7:
                c = ramp(WOOD, 0.75 if row in (0, 8) else 0.4)
                if (x * 7 + row * 3) % 11 == 0:
                    c = WOOD[0]
                img[y, x, :3] = c
                img[y, x, 3] = 1.0
            elif 3 <= row <= 7 and (x - 10) % 22 < 7:
                img[y, x, :3] = ramp(WOOD, 0.3)
                img[y, x, 3] = 1.0
    # Two feet welded from the ring down to the pallet.
    for fx in (int(CX - RX * 0.62), int(CX + RX * 0.62) - 2):
        for y in range(int(CY + RY * 0.82), base_y):
            for x in range(fx, fx + 3):
                if img[y, x, 3] == 0:
                    img[y, x, :3] = ramp(STEEL, 0.35 + 0.2 * (x - fx))
                    img[y, x, 3] = 1.0
    # A cable from the ring over the top, down the right side to the floor.
    for i in range(40):
        s = i / 39.0
        x = int(CX + RX + PIPE + 1 + 3.0 * math.sin(s * 3.2))
        y = int(CY - RY * 0.3 + s * (base_y - (CY - RY * 0.3)))
        if 0 <= x < W and 0 <= y < H:
            img[y, x, :3] = np.array([30, 28, 34])
            img[y, x, 3] = 1.0
    # A junction box with two status lamps on the left of the pipe.
    bx, by = int(CX - RX - PIPE - 4), int(CY + 4)
    for y in range(by, by + 9):
        for x in range(bx, bx + 6):
            img[y, x, :3] = STEEL[2] if (x in (bx, bx + 5) or y in (by, by + 8)) else STEEL[1]
            img[y, x, 3] = 1.0
    amber = t % 6 < 3
    green_on = (t // 2) % 3 != 0
    img[by + 2, bx + 2, :3] = [255, 196, 60] if amber else [90, 60, 20]
    img[by + 2, bx + 3, :3] = [255, 196, 60] if amber else [90, 60, 20]
    img[by + 5, bx + 2, :3] = [110, 255, 140] if green_on else [20, 70, 30]
    img[by + 5, bx + 3, :3] = [110, 255, 140] if green_on else [20, 70, 30]
    # One dark outline around everything solid.
    a = img[..., 3] > 0
    edge = np.zeros_like(a)
    edge[1:, :] |= a[:-1, :]
    edge[:-1, :] |= a[1:, :]
    edge[:, 1:] |= a[:, :-1]
    edge[:, :-1] |= a[:, 1:]
    edge &= ~a
    img[edge, :3] = INK
    img[edge, 3] = 1.0
    return Image.fromarray(np.dstack([img[..., :3].clip(0, 255), img[..., 3:] * 255]).astype(np.uint8), "RGBA")


def main():
    os.makedirs(OUT, exist_ok=True)
    frames = [frame(t) for t in range(N)]
    sheet = Image.new("RGBA", (W * N, H))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * W, 0))
    sheet = sheet.resize((W * N * UP, H * UP), Image.NEAREST)
    sheet.save(os.path.join(OUT, "portal_sheet.png"))
    print("OK", W * UP, H * UP, N)


if __name__ == "__main__":
    main()
