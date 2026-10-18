"""Hand-built heavy bag + speed bag sprites (no generator): cylindrical
leather shading, seams, tape band, logo patch, steel rings, rubber base.
    python3 tools/paint_bag.py
Writes assets/sprites/yard/props/heavy_bag.png (140x512, pivot = bottom
centre) and speed_bag.png (a platform + 6-frame bag strip)."""
import numpy as np
from PIL import Image

rng = np.random.default_rng(7)
OUT = "assets/sprites/yard/props/"


def hexc(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float)


def ramp(cols, t):
    """Pick from a dark->light palette (pixel-art steps, no smooth blend)."""
    t = np.clip(t, 0, 0.999)
    i = (t * len(cols)).astype(int)
    return np.array(cols)[i]


LEATHER = [hexc(c) for c in ("2a0a10", "3f0e17", "5a121e", "761826", "93202f", "ad2d3a", "c84452", "e0707a")]
TAPE = [hexc(c) for c in ("1d1c22", "2b2a32", "3b3a45", "4e4d5a", "62616f")]
STEEL = [hexc(c) for c in ("2c3138", "4a525c", "6f7a86", "a6b2bd", "dfe7ee")]
RUBBER = [hexc(c) for c in ("0b0b10", "14141c", "1d1e28", "282a36", "363948", "4a4e60")]
GOLD = [hexc(c) for c in ("6b4a12", "9a6c1c", "c99a2e", "efcd62")]


def outline(img):
    """Pixels just outside solid ones (no wrap-around at the borders)."""
    a = img[..., 3] > 200
    p = np.pad(a, 1)
    near = p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return near & (img[..., 3] == 0)


def heavy_bag():
    W, H = 140, 512
    img = np.zeros((H, W, 4), float)
    cx = W / 2
    # ---- rubber base (weighted disc, seen slightly from above) ----
    by0, by1 = 452, 506
    for y in range(by0, by1):
        k = (y - by0) / (by1 - by0)
        half = 64 if k > 0.28 else 46 + 18 * (k / 0.28) ** 0.5
        for x in range(W):
            dx = (x - cx) / half
            if abs(dx) > 1:
                continue
            top = k < 0.28
            # top face lit from upper left, side face darker with a rim
            if top:
                t = 0.55 + 0.35 * (1 - (dx + 1) / 2) - 0.25 * k
            else:
                t = 0.25 + 0.3 * (1 - abs(dx)) ** 0.7 - 0.2 * (k - 0.28)
                if abs(dx) > 0.93:
                    t += 0.2  # rim light catches the edge
            if top and abs(k - 0.27) < 0.02:
                t = 0.95  # lip highlight
            c = ramp(RUBBER, t + rng.normal(0, 0.03))
            img[y, x, :3] = c
            img[y, x, 3] = 255
    # contact shadow under the base
    for y in range(by1, min(H, by1 + 6)):
        for x in range(W):
            dx = (x - cx) / 70
            if abs(dx) < 1:
                img[y, x] = [5, 5, 8, 150 * (1 - abs(dx)) * (1 - (y - by1) / 6)]
    # ---- neck (sprung post) ----
    for y in range(420, 456):
        for x in range(int(cx - 13), int(cx + 13)):
            dx = (x - cx) / 13
            t = 0.35 + 0.45 * (1 - (dx + 1) / 2) ** 1.2
            if (y // 3) % 2 == 0:
                t -= 0.08  # spring coils
            img[y, x, :3] = ramp(STEEL, t)
            img[y, x, 3] = 255
    # ---- the bag body: tall leather cylinder with a domed top ----
    top, bot = 46, 424
    R = 52
    for y in range(top, bot):
        k = (y - top) / (bot - top)
        # dome at the top, slight belly, rounded bottom
        r = R
        if y < top + 26:
            r = R * np.sqrt(max(0.0, 1 - ((top + 26 - y) / 28) ** 2))
        if y > bot - 14:
            r = R * np.sqrt(max(0.0, 1 - ((y - (bot - 14)) / 15) ** 2))
        r *= 1 + 0.03 * np.sin(k * np.pi)
        for x in range(W):
            dx = (x - cx) / max(r, 1)
            if abs(dx) > 1:
                continue
            nz = np.sqrt(1 - dx * dx)
            # key light from upper left, warm bounce from the right edge
            light = 0.62 * max(0, (-0.55 * dx + 0.8 * nz)) + 0.12
            if dx > 0.82:
                light += 0.22 * (dx - 0.82) / 0.18  # rim
            light -= 0.18 * k  # floor is darker than the lamp side
            # leather grain + worn punch zone (lighter, scuffed) at chest height
            light += rng.normal(0, 0.025)
            if 0.28 < k < 0.55 and -0.5 < dx < 0.3:
                light += 0.05 * np.sin(x * 1.7 + y * 0.9)
            c = ramp(LEATHER, light)
            # vertical panel seams (stitched)
            for sx in (-0.62, 0.0, 0.62):
                if abs(dx - sx) < 0.035:
                    c = c * 0.62
                    if y % 4 == 0:
                        c = ramp(LEATHER, light + 0.25)
            img[y, x, :3] = c
            img[y, x, 3] = 255
    # tape bands (two wraps) and a logo patch
    for (y0, y1) in ((112, 128), (352, 366)):
        for y in range(y0, y1):
            for x in range(W):
                if img[y, x, 3] == 0:
                    continue
                dx = (x - cx) / R
                nz = np.sqrt(max(0, 1 - dx * dx))
                t = 0.15 + 0.7 * max(0, -0.5 * dx + 0.8 * nz)
                if y in (y0, y1 - 1):
                    t *= 0.55
                img[y, x, :3] = ramp(TAPE, t + rng.normal(0, 0.03))
    # logo: a gold fist roundel on the front
    ly, lx = 232, int(cx - 6)
    for y in range(ly - 15, ly + 16):
        for x in range(lx - 15, lx + 16):
            d = np.hypot(x - lx, y - ly)
            if d <= 15:
                t = 0.35 + 0.5 * (1 - (x - lx + y - ly + 30) / 60)
                c = ramp(GOLD, t) if d > 11.5 else ramp(LEATHER, 0.18)
                if d <= 11.5 and (abs(x - lx) < 6 and -6 < y - ly < 5):
                    c = ramp(GOLD, 0.6 + 0.3 * (y < ly - 2))  # fist block
                if d <= 11.5 and abs(x - lx) < 6 and y - ly in (-3, 1):
                    c = ramp(GOLD, 0.15)  # knuckle lines
                img[y, x, :3] = c
    # top cap: steel ring plate and four D-rings
    for y in range(40, 52):
        for x in range(W):
            dx = (x - cx) / 40
            if abs(dx) < 1:
                img[y, x, :3] = ramp(STEEL, 0.25 + 0.6 * (1 - (dx + 1) / 2) - 0.05 * (y - 40) / 12)
                img[y, x, 3] = 255
    for rx in (-30, -10, 10, 30):
        for y in range(30, 46):
            for x in range(int(cx + rx - 5), int(cx + rx + 6)):
                d = np.hypot((x - cx - rx) / 5, (y - 38) / 7)
                if 0.62 < d <= 1.0:
                    img[y, x, :3] = ramp(STEEL, 0.4 + 0.5 * (x < cx + rx))
                    img[y, x, 3] = 255
    # one-pixel dark outline (readable on any street)
    img[outline(img)] = [12, 6, 10, 255]
    Image.fromarray(img.astype(np.uint8)).save(OUT + "heavy_bag.png")


def speed_bag():
    """Board on a bracket and a teardrop bag; 6 frames of the rebound."""
    W, H, N = 132, 120, 6
    sheet = np.zeros((H, W * N, 4), float)
    WOOD = [hexc(c) for c in ("2b170c", "40220f", "5a3115", "77431c", "955a26", "b6773a")]
    for f in range(N):
        img = np.zeros((H, W, 4), float)
        # the rebound board
        for y in range(6, 20):
            for x in range(4, W - 4):
                t = 0.35 + 0.45 * (1 - (y - 6) / 14) + 0.06 * np.sin(x * 0.7)
                img[y, x, :3] = ramp(WOOD, t)
                img[y, x, 3] = 255
        for x in range(4, W - 4):
            img[20, x] = [18, 10, 6, 255]
        # swivel
        cx = W // 2
        for y in range(20, 27):
            for x in range(cx - 3, cx + 4):
                img[y, x, :3] = ramp(STEEL, 0.5 + 0.4 * (x < cx))
                img[y, x, 3] = 255
        # bag angle swings round the swivel: forward, rebound, back
        ang = [0.0, 0.85, 0.35, -0.7, -0.25, 0.45][f]
        L = 70
        for y in range(26, H):
            for x in range(W):
                px, py = x - cx, y - 26
                # rotate into the bag's own frame
                c, s = np.cos(-ang), np.sin(-ang)
                u, v = c * px - s * py, s * px + c * py
                if v < 0 or v > L:
                    continue
                k = v / L
                r = 4 + 14 * np.sin(np.pi / 2 * k / 0.6) if k < 0.6 else 18 * np.sqrt(max(0.0, 1 - ((k - 0.6) / 0.4) ** 2))
                if abs(u) > r:
                    continue
                dx = u / r
                nz = np.sqrt(max(0, 1 - dx * dx))
                t = 0.15 + 0.7 * max(0, -0.5 * dx + 0.8 * nz) - 0.12 * k + rng.normal(0, 0.02)
                if abs(dx) < 0.05:
                    t *= 0.7
                img[y, x, :3] = ramp(LEATHER, t)
                img[y, x, 3] = 255
        img[outline(img)] = [12, 6, 10, 255]
        sheet[:, f * W:(f + 1) * W] = img
    Image.fromarray(sheet.astype(np.uint8)).save(OUT + "speed_bag.png")


if __name__ == "__main__":
    heavy_bag()
    speed_bag()
    print("bags painted")
