"""One unique, non-repeating ground image per survivor map.

Covers the arena (2600 x 1700 world units) plus a margin, at U world units
per texel. Stochastic surfaces (asphalt grain, cobbles) are quilted from a
FLUX sample; regular surfaces (slabs, tiles, planks) are laid out piece by
piece with real texture cut from the sample into every piece, so nothing
tiles and no seam runs anywhere."""
import sys, math
import numpy as np
from PIL import Image, ImageFilter, ImageDraw
sys.path.insert(0, "/tmp/claude-0/ground")
from quilt import quilt, smooth_noise

W, H, M, U = 2600.0, 1700.0, 60.0, 0.75
PW, PH = int((W + 2 * M) / U), int((H + 2 * M) / U)
OUT = "/home/user/hnt/assets/sprites/field/"
FG = "/tmp/claude-0/fieldgen/"


def px(x, y):
    return (x + M) / U, (y + M) / U


def load(path, size=None):
    im = Image.open(path).convert("RGB")
    if size:
        im = im.resize(size, Image.LANCZOS)
    return np.asarray(im).astype(np.float32)


def flatten(a, r=40):
    """Strip lighting gradients / vignette: keep detail, even out the mean."""
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    lo = np.asarray(im.filter(ImageFilter.GaussianBlur(r))).astype(np.float32)
    return np.clip(a - lo + a.reshape(-1, 3).mean(0), 0, 255)


def macro(img, seed, lo=0.86, hi=1.1, scale=420):
    n = smooth_noise(img.shape[0], img.shape[1], scale, seed, 3)
    return img * (lo + (hi - lo) * n)[..., None]


def blob_mask(h, w, cx, cy, rx, ry, seed, rough=0.35):
    """Soft irregular blob (0..1) the size of the image."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
    n = smooth_noise(h, w, max(8, min(rx, ry) * 0.6), seed, 2)
    d = d + (n - 0.5) * rough * 2
    return np.clip(1.0 - d, 0, 1)


def stamp(img, cx, cy, r, fn, seed):
    """Apply fn(region, mask) to a square region round (cx, cy)."""
    h, w = img.shape[:2]
    x0, x1 = int(max(0, cx - r)), int(min(w, cx + r))
    y0, y1 = int(max(0, cy - r)), int(min(h, cy + r))
    if x1 <= x0 or y1 <= y0:
        return
    sub = img[y0:y1, x0:x1]
    img[y0:y1, x0:x1] = fn(sub, (x0, y0))


def crack(draw, rng, x, y, length, col, width=2):
    a = rng.uniform(0, math.tau)
    pts = [(x, y)]
    for i in range(int(length / 6)):
        a += rng.normal(0, 0.35)
        x += math.cos(a) * 6
        y += math.sin(a) * 6
        pts.append((x, y))
        if rng.random() < 0.04:
            crack(draw, rng, x, y, length * 0.4, col, max(1, width - 1))
    draw.line(pts, fill=col, width=width)


def stains(img, rng, n, col, rmin, rmax, alpha, seed):
    h, w = img.shape[:2]
    for i in range(n):
        cx, cy = rng.uniform(0, w), rng.uniform(0, h)
        rx, ry = rng.uniform(rmin, rmax), rng.uniform(rmin, rmax) * rng.uniform(0.5, 1.0)
        r = int(max(rx, ry) * 1.6)

        def fn(sub, o, cx=cx, cy=cy, rx=rx, ry=ry, s=seed + i):
            m = blob_mask(sub.shape[0], sub.shape[1], cx - o[0], cy - o[1], rx, ry, s)
            m = (m ** 0.6 * alpha)[..., None]
            return sub * (1 - m) + np.array(col, np.float32) * m
        stamp(img, cx, cy, r, fn, seed)


def finish(img, name, colors=72):
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    im = im.quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    im.save(OUT + name + ".webp", quality=90, method=6)
    small = im.resize((PW // 4, PH // 4), Image.LANCZOS)
    small.save("/tmp/claude-0/ground/prev_" + name + ".png")
    print("saved", name, im.size, flush=True)


def gapfree_crops(src, size, is_gap, n, rng, tries=4000):
    h, w = src.shape[:2]
    gap = is_gap(src)
    out = []
    for t in range(tries):
        y, x = rng.integers(0, h - size), rng.integers(0, w - size)
        if gap[y:y + size, x:x + size].mean() < 0.004:
            out.append(src[y:y + size, x:x + size])
            if len(out) >= n:
                break
    return out


def lum(a):
    return a[..., 0] * 0.3 + a[..., 1] * 0.59 + a[..., 2] * 0.11


# ---------------------------------------------------------------- lot
def lot():
    rng = np.random.default_rng(1)
    a = load("/tmp/claude-0/ground/asphalt.png")[:, :430]
    a = flatten(a, 30)
    s = np.asarray(Image.fromarray(a.astype(np.uint8)).resize((140, 333), Image.LANCZOS)).astype(np.float32)
    img = quilt(s, PH, PW, B=48, O=12, seed=3)
    img = macro(img, 11, 0.84, 1.08, 520)
    # Patched tar strips (resealed trenches) a shade darker and smoother.
    for i in range(9):
        x0, y0 = rng.uniform(0, PW), rng.uniform(0, PH)
        horiz = rng.random() < 0.5
        L, T = rng.uniform(300, 1100), rng.uniform(28, 70)
        x1, y1 = (x0 + L, y0 + T) if horiz else (x0 + T, y0 + L)
        sl = img[int(y0):int(y1), int(x0):int(x1)]
        img[int(y0):int(y1), int(x0):int(x1)] = sl * 0.78 + 4
    # Oil stains and wet dark patches.
    stains(img, rng, 70, (18, 18, 20), 10, 34, 0.55, 40)
    stains(img, rng, 14, (30, 34, 40), 60, 160, 0.35, 90)
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    for i in range(55):
        crack(d, rng, rng.uniform(0, PW), rng.uniform(0, PH), rng.uniform(80, 360), (14, 14, 16), 2)
    img = np.asarray(im).astype(np.float32)
    # Stall lines round the two parked rows (cars sit at y 380 / 1300,
    # every 190 from x 260): worn white paint.
    paint = np.zeros((PH, PW), np.float32)
    pim = Image.fromarray((paint * 255).astype(np.uint8))
    pd = ImageDraw.Draw(pim)
    for row in (380.0, 1300.0):
        x = 260.0 - 95.0
        while x < W - 150.0:
            a0, a1 = px(x, row - 95), px(x, row + 95)
            pd.line([a0, a1], fill=255, width=7)
            x += 190.0
        b0, b1 = px(165, row + 95 if row < 800 else row - 95), px(x - 190.0, row + 95 if row < 800 else row - 95)
        pd.line([b0, b1], fill=255, width=7)
    # Lane arrows down the middle.
    for x in (700.0, 1300.0, 1900.0):
        cx, cy = px(x, 840)
        pd.polygon([(cx - 40, cy - 9), (cx + 20, cy - 9), (cx + 20, cy - 22), (cx + 52, cy), (cx + 20, cy + 22), (cx + 20, cy + 9), (cx - 40, cy + 9)], fill=255)
    paint = np.asarray(pim).astype(np.float32) / 255.0
    wear = smooth_noise(PH, PW, 26, 5, 3)
    paint *= np.clip((wear - 0.28) * 3.0, 0, 1) * 0.85
    img = img * (1 - paint[..., None]) + np.array([205, 200, 182], np.float32) * paint[..., None]
    finish(img, "ground_lot")


# ---------------------------------------------------------------- circle
def circle():
    rng = np.random.default_rng(2)
    src = flatten(load(FG + "raw2/circle.png"), 60)
    gapf = lambda a: (lum(a) < 95) | ((a[..., 1] > a[..., 0] + 6) & (a[..., 1] > a[..., 2] + 10))
    crops = gapfree_crops(src, 130, gapf, 40, rng)
    print("slab crops", len(crops))
    soil = np.array([52, 47, 38], np.float32)
    img = np.zeros((PH, PW, 3), np.float32) + soil
    img += (smooth_noise(PH, PW, 6, 7, 2)[..., None] - 0.5) * 30
    slab = 96 / U  # px
    gap = 5
    ny, nx = int(PH / slab) + 2, int(PW / slab) + 2
    for j in range(ny):
        off = rng.uniform(0, slab) if j % 2 else 0  # loose running bond
        for i in range(-1, nx):
            x0 = int(i * slab + off + gap / 2 + rng.integers(-2, 3))
            y0 = int(j * slab + gap / 2 + rng.integers(-2, 3))
            sw, shh = int(slab - gap), int(slab - gap)
            c = crops[rng.integers(len(crops))]
            c = np.rot90(c, rng.integers(4))
            c = np.asarray(Image.fromarray(c.astype(np.uint8)).resize((sw, shh), Image.LANCZOS)).astype(np.float32)
            c = c * rng.uniform(0.86, 1.08) + rng.normal(0, 4, 3)
            # Bevel: lit top-left edge, dark bottom-right.
            c[:3] *= 1.12
            c[:, :3] *= 1.08
            c[-3:] *= 0.72
            c[:, -3:] *= 0.78
            if rng.random() < 0.08:  # a cracked slab
                im = Image.fromarray(np.clip(c, 0, 255).astype(np.uint8))
                crack(ImageDraw.Draw(im), rng, rng.uniform(0, sw), rng.uniform(0, shh), sw * 0.8, (40, 38, 34), 2)
                c = np.asarray(im).astype(np.float32)
            ya, yb = max(0, y0), min(PH, y0 + shh)
            xa, xb = max(0, x0), min(PW, x0 + sw)
            if yb > ya and xb > xa:
                img[ya:yb, xa:xb] = c[ya - y0:yb - y0, xa - x0:xb - x0]
    # Moss and grass creeping out of the joints.
    g = smooth_noise(PH, PW, 5, 21, 2)
    joint = (np.abs(img - soil).sum(-1) < 60).astype(np.float32)
    jm = np.asarray(Image.fromarray((joint * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))).astype(np.float32) / 255
    moss = jm * np.clip((g - 0.45) * 4, 0, 1) * np.clip((smooth_noise(PH, PW, 90, 22, 2) - 0.35) * 3, 0, 1)
    mcol = np.array([78, 98, 44], np.float32) + (g[..., None] - 0.5) * 60
    img = img * (1 - moss[..., None] * 0.85) + mcol * moss[..., None] * 0.85
    # A worn ring path of cobbles under the tree ring.
    cob = flatten(load(FG + "raw3/sleet_crop.png", (300, 300)), 30)
    cob = cob * np.array([1.0, 0.95, 0.86]) * 0.86
    ring = quilt(cob, PH, PW, B=72, O=18, seed=8)
    yy, xx = np.mgrid[0:PH, 0:PW].astype(np.float32)
    cx, cy = px(1300, 850)
    e = np.sqrt(((xx - cx) / (720 / U)) ** 2 + ((yy - cy) / (470 / U)) ** 2)
    band = np.clip(1 - np.abs(e - 1.0) / (0.12), 0, 1)
    band = np.clip(band * 2.5 + (smooth_noise(PH, PW, 30, 9, 2) - 0.5) * 1.2, 0, 1)
    img = img * (1 - band[..., None]) + ring * band[..., None]
    img = macro(img, 23, 0.8, 1.06, 480)
    stains(img, rng, 30, (40, 38, 34), 12, 40, 0.4, 300)
    finish(img, "ground_circle")


# ---------------------------------------------------------------- clinic
def clinic():
    rng = np.random.default_rng(3)
    src = flatten(load(FG + "raw2/clinic.png"), 50)
    gapf = lambda a: lum(a) < 150
    crops = gapfree_crops(src, 110, gapf, 40, rng)
    print("tile crops", len(crops))
    mint = np.array([118, 168, 140], np.float32)
    cream = np.array([214, 204, 176], np.float32)
    grout = np.array([92, 92, 84], np.float32)
    img = np.zeros((PH, PW, 3), np.float32) + grout
    t = 64 / U
    ny, nx = int(PH / t) + 1, int(PW / t) + 1
    for j in range(ny):
        for i in range(nx):
            x0, y0 = int(i * t) + 1, int(j * t) + 1
            sz = int(t) - 2
            base = mint if (i + j) % 2 else cream
            c = crops[rng.integers(len(crops))]
            c = np.rot90(c, rng.integers(4))
            c = np.asarray(Image.fromarray(c.astype(np.uint8)).resize((sz, sz), Image.LANCZOS)).astype(np.float32)
            det = lum(c)
            det = (det - det.mean()) / 255.0
            tile = base * rng.uniform(0.92, 1.04) + det[..., None] * 120
            tile[:2] *= 1.06
            tile[-2:] *= 0.86
            if rng.random() < 0.05:
                im = Image.fromarray(np.clip(tile, 0, 255).astype(np.uint8))
                crack(ImageDraw.Draw(im), rng, rng.uniform(0, sz), rng.uniform(0, sz), sz, (70, 70, 64), 1)
                tile = np.asarray(im).astype(np.float32)
            ya, yb, xa, xb = y0, min(PH, y0 + sz), x0, min(PW, x0 + sz)
            img[ya:yb, xa:xb] = tile[:yb - ya, :xb - xa]
    # Grime: darker along walls and in traffic lanes, scuffs, coffee rings.
    g = smooth_noise(PH, PW, 260, 31, 3)
    img *= (0.78 + 0.26 * g)[..., None]
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    for i in range(420):
        x, y = rng.uniform(0, PW), rng.uniform(0, PH)
        r = rng.uniform(6, 22)
        a0 = rng.uniform(0, 360)
        d.arc([x - r, y - r * 0.5, x + r, y + r * 0.5], a0, a0 + rng.uniform(40, 140), fill=(96, 94, 86), width=1)
    img = np.asarray(im).astype(np.float32)
    # Coffee rings: soft brown, not ink outlines.
    rl = Image.new("L", (PW, PH), 0)
    rd = ImageDraw.Draw(rl)
    for i in range(36):
        x, y, r = rng.uniform(0, PW), rng.uniform(0, PH), rng.uniform(7, 13)
        rd.ellipse([x - r, y - r, x + r, y + r], outline=255, width=3)
    rm = np.asarray(rl.filter(ImageFilter.GaussianBlur(1.2))).astype(np.float32)[..., None] / 255 * 0.4
    img = img * (1 - rm) + np.array([128, 92, 58], np.float32) * rm
    # Mop arcs: wide faint lighter swirls.
    for i in range(40):
        cx, cy, r = rng.uniform(0, PW), rng.uniform(0, PH), rng.uniform(60, 160)
        yy, xx = np.mgrid[int(max(0, cy - r - 20)):int(min(PH, cy + r + 20)), int(max(0, cx - r - 20)):int(min(PW, cx + r + 20))]
        if yy.size == 0:
            continue
        d2 = np.abs(np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) - r)
        ang = np.arctan2(yy - cy, xx - cx)
        m = np.clip(1 - d2 / 14, 0, 1) * (np.sin(ang + rng.uniform(0, 6)) > 0.2) * 0.12
        img[yy, xx] = img[yy, xx] * (1 - m[..., None]) + 255 * m[..., None]
    stains(img, rng, 26, (110, 84, 52), 14, 40, 0.35, 500)
    finish(img, "ground_clinic")


# ---------------------------------------------------------------- sleet
def sleet():
    rng = np.random.default_rng(4)
    cob = flatten(load(FG + "raw3/sleet_crop.png", (300, 300)), 30)
    img = quilt(cob, PH, PW, B=72, O=18, seed=12)
    img = macro(img, 41, 0.82, 1.06, 500)
    # Drifts: snow settles in broad soft fields, thin where people walk.
    n = smooth_noise(PH, PW, 220, 42, 4)
    fine = smooth_noise(PH, PW, 8, 43, 2)
    snow = np.clip((n - 0.42) * 3.0 + (fine - 0.5) * 0.6, 0, 1)
    scol = np.array([226, 232, 242], np.float32) + (fine[..., None] - 0.5) * 20
    img = img * (1 - snow[..., None] * 0.9) + scol * snow[..., None] * 0.9
    # Slush tracks: grey-brown ruts across the snow.
    tr = Image.new("L", (PW, PH), 0)
    td = ImageDraw.Draw(tr)
    for i in range(10):
        x, y = rng.uniform(0, PW), rng.uniform(0, PH)
        a = rng.uniform(0, math.tau)
        pts = []
        for k in range(60):
            a += rng.normal(0, 0.06)
            x += math.cos(a) * 30
            y += math.sin(a) * 30
            pts.append((x, y))
        td.line(pts, fill=200, width=int(rng.uniform(14, 26)))
    trk = np.asarray(tr.filter(ImageFilter.GaussianBlur(4))).astype(np.float32) / 255 * snow
    img = img * (1 - trk[..., None] * 0.7) + np.array([108, 104, 98], np.float32) * trk[..., None] * 0.7
    finish(img, "ground_sleet")


# ---------------------------------------------------------------- dock
def dock():
    rng = np.random.default_rng(5)
    src = load("/tmp/claude-0/ground/planks.png")
    L = lum(src).mean(1)
    # Gap rows are the dark minima between planks.
    sm = np.convolve(L, np.ones(5) / 5, "same")
    gaps = [i for i in range(6, len(sm) - 6) if sm[i] == sm[i - 6:i + 7].min() and sm[i] < np.median(sm) - 18]
    strips = []
    for a, b in zip(gaps[:-1], gaps[1:]):
        if 60 < b - a < 140:
            strips.append(src[a + 6:b - 5])
    print("plank strips", len(strips))
    ph = int(44 / U)
    gap = 4
    img = np.zeros((PH, PW, 3), np.float32) + np.array([16, 14, 12], np.float32)
    y = 0
    while y < PH:
        x = -int(rng.uniform(0, 400))
        while x < PW:
            ln = int(rng.uniform(380, 1100))
            s = strips[rng.integers(len(strips))]
            sx = rng.uniform(0.9, 1.15)
            s = np.asarray(Image.fromarray(s.astype(np.uint8)).resize((int(s.shape[1] * sx * ph / s.shape[0]), ph - gap), Image.LANCZOS)).astype(np.float32)
            if rng.random() < 0.5:
                s = s[:, ::-1]
            off = rng.integers(0, max(1, s.shape[1] - min(ln, s.shape[1])))
            seg = s[:, off:off + ln]
            seg = seg * rng.uniform(0.82, 1.08)
            xa, xb = max(0, x), min(PW, x + seg.shape[1])
            ya, yb = y, min(PH, y + seg.shape[0])
            if xb > xa and yb > ya:
                img[ya:yb, xa:xb] = seg[:yb - ya, xa - x:xb - x]
                # Butt joint and its nails.
                if x > 0:
                    img[ya:yb, x:x + 2] = (14, 12, 10)
                    for ny_ in (ya + 5, yb - 7):
                        for nx_ in (x - 6, x + 5):
                            if 0 <= nx_ < PW - 2 and ny_ + 2 < PH:
                                img[ny_:ny_ + 2, nx_:nx_ + 2] = (70, 66, 60)
            x += seg.shape[1]
        y += ph
    img = macro(img, 51, 0.78, 1.08, 420)
    # Wet planks and algae.
    wet = np.clip((smooth_noise(PH, PW, 160, 52, 3) - 0.55) * 3, 0, 1)
    img *= (1 - wet * 0.3)[..., None]
    alg = np.clip((smooth_noise(PH, PW, 70, 53, 3) - 0.62) * 4, 0, 1) * np.clip((smooth_noise(PH, PW, 6, 54, 2) - 0.35) * 3, 0, 1)
    img = img * (1 - alg[..., None] * 0.6) + np.array([70, 92, 40], np.float32) * alg[..., None] * 0.6
    finish(img, "ground_dock")


if __name__ == "__main__":
    for name in sys.argv[1:]:
        globals()[name]()
