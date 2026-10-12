"""Image quilting (Efros & Freeman 2001): a large non-repeating texture
sewn from patches of a small sample along minimum-error boundary cuts,
so there is no tile grid and no straight seam anywhere."""
import numpy as np


def _cut_v(err):
    # err: (B, O) -> mask (B, O) True where the NEW patch wins.
    B, O = err.shape
    cost = err.copy()
    for i in range(1, B):
        prev = cost[i - 1]
        left = np.r_[np.inf, prev[:-1]]
        right = np.r_[prev[1:], np.inf]
        cost[i] += np.minimum(np.minimum(left, prev), right)
    path = np.zeros(B, int)
    path[-1] = int(np.argmin(cost[-1]))
    for i in range(B - 2, -1, -1):
        j = path[i + 1]
        lo, hi = max(0, j - 1), min(O, j + 2)
        path[i] = lo + int(np.argmin(cost[i, lo:hi]))
    m = np.zeros((B, O), bool)
    for i in range(B):
        m[i, path[i]:] = True
    return m


def quilt(sample, out_h, out_w, B=64, O=16, cand=500, tol=0.12, seed=0):
    rng = np.random.default_rng(seed)
    S = sample.astype(np.float32)
    sh, sw = S.shape[:2]
    step = B - O
    ny = int(np.ceil((out_h - O) / step))
    nx = int(np.ceil((out_w - O) / step))
    H, W = ny * step + O, nx * step + O
    out = np.zeros((H, W, 3), np.float32)
    for iy in range(ny):
        for ix in range(nx):
            y, x = iy * step, ix * step
            ys = rng.integers(0, sh - B, cand)
            xs = rng.integers(0, sw - B, cand)
            if iy == 0 and ix == 0:
                k = 0
            else:
                e = np.zeros(cand, np.float32)
                idx_y = ys[:, None, None] + np.arange(B)[None, :, None]
                idx_x = xs[:, None, None] + np.arange(B)[None, None, :]
                P = S[idx_y, idx_x]  # cand,B,B,3
                if ix > 0:
                    d = P[:, :, :O] - out[y:y + B, x:x + O][None]
                    e += (d * d).sum(axis=(1, 2, 3))
                if iy > 0:
                    d = P[:, :O, :] - out[y:y + O, x:x + B][None]
                    e += (d * d).sum(axis=(1, 2, 3))
                best = e.min()
                ok = np.where(e <= best * (1.0 + tol) + 1e-3)[0]
                k = int(rng.choice(ok))
            patch = S[ys[k]:ys[k] + B, xs[k]:xs[k] + B]
            mask = np.ones((B, B), bool)
            if ix > 0:
                d = patch[:, :O] - out[y:y + B, x:x + O]
                mask[:, :O] &= _cut_v((d * d).sum(-1))
            if iy > 0:
                d = patch[:O, :] - out[y:y + O, x:x + B]
                mask[:O, :] &= _cut_v((d * d).sum(-1).T).T
            region = out[y:y + B, x:x + B]
            region[mask] = patch[mask]
    return out[:out_h, :out_w]


def smooth_noise(h, w, scale, seed, octaves=3):
    """Cheap value noise in [0, 1] (bilinear upsampled random grids)."""
    from PIL import Image
    rng = np.random.default_rng(seed)
    acc = np.zeros((h, w), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        gh = max(2, int(h / scale) + 2)
        gw = max(2, int(w / scale) + 2)
        g = (rng.random((gh, gw)) * 255).astype(np.uint8)
        up = np.asarray(Image.fromarray(g).resize((w, h), Image.BICUBIC)).astype(np.float32) / 255.0
        acc += up * amp
        tot += amp
        amp *= 0.5
        scale /= 2.0
    return acc / tot
