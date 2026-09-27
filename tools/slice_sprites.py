#!/usr/bin/env python3
"""Cut generated sprite boards into pixel-perfect Godot sprite sheets.

Every source board is AI pixel art on a chroma board (hot pink, maroon or
magenta; sometimes black or plum cell rules, sometimes a dark vignette).

1. Find the figures: an even grid of rules when the board has one, else
   connected ink (loose papers, shadows and light bars glue to their owner,
   figures touching feet-to-head are split), else a stated GRID.
2. Key each figure: board estimated from its own border, border-connected
   flood plus enclosed board pockets, vignette rims, then the outer ring takes
   its colour from the figure's interior so no board tint survives.
3. Scale: one base factor per character from the idle height, corrected per
   board by body area (each board was drawn at its own zoom; a body's pixel
   area barely changes with pose).
4. Anchor: feet on one baseline, x registered by mask overlap against idle.
5. Resample premultiplied with Lanczos, hard alpha -> crisp at 1:1 on 1080p
   (4.5 texels per world unit under the 1.5x couch camera).
6. Pack every clip into one trimmed sheet + JSON (region + offset per frame)
   that SpriteBook turns into AtlasTextures.

Needs Pillow, numpy, scipy.   python3 tools/slice_sprites.py [all|father|...]
"""
from __future__ import annotations

import json
import os
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
ART = Path(os.environ.get("HNT_SPRITE_SRC", str(ROOT / "tools" / "sprite_src")))
OUT = ROOT / "assets" / "sprites"
SHEETS = ROOT / "tools" / "sprite_src"

# Texel budget: 4.5 texels per world unit (SpriteBook.DRAW_SCALE = 1/4.5).
# The couch camera zooms 1.5x, so a 1080p window (3x of 640x360) draws one
# texel per screen pixel.
STAND_H = 198       # standing actor, 44 world units (unchanged from the 96 px era)
MIN_WHO_CELL = 288  # actor cell floor, 64 world units
PROP_CELL = 216     # props / pickups / living props, 48 world units
TILE = 144          # 32 world units
ICON = 128          # hub icons, shrunk into UI boxes with trilinear
SHEET_MAX_W = 2048
PAD = 4             # transparent gutter between packed frames (mip bleed)

# Boards whose figures touch across rows or split into loose parts: the grid
# is stated instead of detected.
GRID = {
    "gant-hurt-recoil.png": (3, 4),
    "gate-gap-idle.png": (3, 4),
    "gate-rail-idle.png": (4, 4),
    "mohawk-hurt-recoil.png": (4, 4),
    "smash-dumpster-idle.png": (4, 4),
    "toy-flag-idle.png": (4, 3),
}


# --------------------------------------------------------------------------
# Board colour


def _border(a: np.ndarray, t: int = 3) -> np.ndarray:
    """Border pixels, minus near-black cell rules (they are not the board)."""
    px = np.concatenate([
        a[:t].reshape(-1, a.shape[-1]), a[-t:].reshape(-1, a.shape[-1]),
        a[:, :t].reshape(-1, a.shape[-1]), a[:, -t:].reshape(-1, a.shape[-1]),
    ])
    lit = px[px[:, :3].max(axis=1) >= 42]
    return lit if len(lit) >= max(16, len(px) // 5) else px


def _noise_floor(ring_d: np.ndarray, floor: float, cap: float) -> float:
    """Board noise threshold from border distances, robust to stray rules."""
    med = float(np.median(ring_d))
    mad = float(np.median(np.abs(ring_d - med))) * 1.4826
    return float(np.clip(med + 5.0 * mad, floor, cap))


def _pinkish(rgb: np.ndarray) -> np.ndarray:
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return (r > g + 40) & (b > g + 15) & (r > 70)


def _hue_sat(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    mx = rgb.max(axis=-1)
    mn = rgb.min(axis=-1)
    c = mx - mn
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    safe = np.maximum(c, 1e-6)
    h = np.where(mx == r, ((g - b) / safe) % 6.0,
                 np.where(mx == g, (b - r) / safe + 2.0, (r - g) / safe + 4.0)) * 60.0
    s = c / np.maximum(mx, 1e-6)
    return h, s


def _board_hue(f: np.ndarray, bg: np.ndarray) -> np.ndarray:
    """Pixels tinted toward the board's hue (magenta/maroon family)."""
    h, s = _hue_sat(f)
    bh, _ = _hue_sat(bg[None, :])
    dh = np.abs(((h - float(bh[0])) + 180.0) % 360.0 - 180.0)
    return (dh < 28.0) & (s > 0.32) & (f.max(axis=-1) > 28.0)


# --------------------------------------------------------------------------
# Rules and grids


def _dark_rows(a: np.ndarray, axis: int) -> list[tuple[int, int]]:
    """Thin near-black lines across 80%+ of the board (cell rules)."""
    dark = a[..., :3].max(axis=2) < 60
    frac = dark.mean(axis=1 - axis)
    n = frac.shape[0]
    hits = [int(i) for i in np.nonzero(frac > 0.8)[0]]
    groups: list[list[int]] = []
    for i in hits:
        if groups and i - groups[-1][-1] <= 4:
            groups[-1].append(i)
        else:
            groups.append([i])
    out = []
    for g in groups:
        a0, a1 = g[0], g[-1]
        if a1 - a0 > 12:
            continue
        # A rule is a spike: beside it the board is lit (a vignette is not).
        side = np.concatenate([frac[max(0, a0 - 16):max(0, a0 - 5)], frac[min(n, a1 + 6):min(n, a1 + 17)]])
        edge = a0 <= 2 or a1 >= n - 3
        if edge or side.size == 0 or float(side.mean()) < 0.45:
            out.append((a0, a1))
    return out


def _rule_runs(m: np.ndarray, axis: int) -> list[tuple[int, int]]:
    """Thin coloured lines (<= 8 px) that are ink across 80%+ of the board."""
    frac = m.mean(axis=1 - axis)
    full = frac > 0.8
    n = full.shape[0]
    out, run = [], 0
    for i in range(n + 1):
        if i < n and full[i]:
            run += 1
            continue
        if 0 < run <= 8:
            a0, a1 = i - run, i
            side = np.concatenate([frac[max(0, a0 - 18):max(0, a0 - 6)], frac[min(n, a1 + 6):min(n, a1 + 18)]])
            if side.size == 0 or float(side.mean()) < 0.5:
                out.append((a0, a1))
        run = 0
    return out


def _regular(lines: list[tuple[int, int]], extent: int) -> list[tuple[int, int]]:
    """Cell spans from rule candidates that sit on an even k-grid (k >= 3).

    Dark props (lamp posts, booth walls, car shadows) also make lines; only a
    set of lines at i*extent/k for every i counts as the board's rules."""
    if not lines:
        return []
    mids = [(a0 + a1) * 0.5 for a0, a1 in lines]
    for k in (6, 5, 4, 3):
        step = extent / k
        tol = step * 0.06
        picked = []
        for i in range(1, k):
            want = i * step
            best = min(range(len(mids)), key=lambda j: abs(mids[j] - want))
            if abs(mids[best] - want) > tol:
                break
            picked.append(lines[best])
        else:
            edges = [(-1, -1)] + picked + [(extent, extent)]
            return [(p1 + 1, q0) for (_, p1), (q0, _) in zip(edges, edges[1:])]
    return []


def _even(extent: int, n: int) -> list[tuple[int, int]]:
    step = extent / n
    return [(int(round(i * step)), int(round((i + 1) * step))) for i in range(n)]


def _grid_cells(ys: list[tuple[int, int]], xs: list[tuple[int, int]], shape: tuple[int, int]) -> list:
    out = []
    for y0, y1 in ys:
        for x0, x1 in xs:
            own = np.zeros(shape, bool)
            own[y0 + 3:y1 - 3, x0 + 3:x1 - 3] = True
            out.append(((x0 + 3, y0 + 3, x1 - 3, y1 - 3), own))
    return out


def cells(a: np.ndarray, cols: int = 0, rows: int = 0) -> list[tuple[int, int, int, int]]:
    """Cell boxes for single-frame boards (tiles, props, icons)."""
    h, w = a.shape[:2]
    if cols >= 1 and rows >= 1:
        ys, xs = _even(h, rows), _even(w, cols)
    else:
        ys, xs = _regular(_dark_rows(a, 0), h), _regular(_dark_rows(a, 1), w)
        if len(ys) < 2 or len(xs) < 2:
            ys, xs = _even(h, 3), _even(w, 4)
    return [(x0, y0, x1, y1) for y0, y1 in ys for x0, x1 in xs]


# --------------------------------------------------------------------------
# Figures


def _gap_overlap(a: list, b: list) -> tuple[float, float, float, float]:
    """(horizontal gap, vertical gap, x-overlap frac, y-overlap frac)."""
    gx = max(b[0] - a[2], a[0] - b[2], 0)
    gy = max(b[1] - a[3], a[1] - b[3], 0)
    ox = max(0, min(a[2], b[2]) - max(a[0], b[0])) / max(1, min(a[2] - a[0], b[2] - b[0]))
    oy = max(0, min(a[3], b[3]) - max(a[1], b[1])) / max(1, min(a[3] - a[1], b[3] - b[1]))
    return gx, gy, ox, oy


def _merge_parts(comps: list[dict]) -> list[dict]:
    """Glue a figure back together: its shadow, a light bar, a spark, a door.

    The smaller part joins when it is at most half the bigger one and sits
    close with overlap. Two whole frames never merge: similar size, a gutter
    apart."""
    hs = sorted(c["box"][3] - c["box"][1] for c in comps if c["area"] > 0)
    med_h = float(np.median(hs[len(hs) // 2:])) if hs else 1.0
    changed = True
    while changed:
        changed = False
        comps.sort(key=lambda c: -c["area"])
        for i in range(len(comps)):
            if comps[i]["area"] <= 0:
                continue
            for j in range(len(comps)):
                if i == j or comps[j]["area"] <= 0 or comps[j]["area"] > comps[i]["area"]:
                    continue
                A, B = comps[i], comps[j]
                gx, gy, ox, oy = _gap_overlap(A["box"], B["box"])
                small = B["area"] < 0.5 * A["area"]
                near = (gy <= med_h * 0.2 and ox > 0.3) or (gx <= med_h * 0.12 and oy > 0.3)
                if small and near:
                    A["own"] |= B["own"]
                    A["area"] += B["area"]
                    A["box"] = [min(A["box"][0], B["box"][0]), min(A["box"][1], B["box"][1]),
                                max(A["box"][2], B["box"][2]), max(A["box"][3], B["box"][3])]
                    B["area"] = 0
                    changed = True
    return [c for c in comps if c["area"] > 0]


def _split_merged(items: list, m: np.ndarray, depth: int = 0) -> list:
    """Split boxes that swallowed several figures (feet touching a head)."""
    if len(items) < 3 or depth > 2:
        return items
    hs = np.array([b[3] - b[1] for b, _ in items], np.float32)
    ws = np.array([b[2] - b[0] for b, _ in items], np.float32)
    # The smallest plausible figure is the unit (stacks are 2x, 3x of it).
    ref_h = float(hs[hs >= hs.max() * 0.3].min())
    ref_w = float(ws[ws >= ws.max() * 0.3].min())
    out = []
    split_any = False
    for box, own in items:
        x0, y0, x1, y1 = box
        h, w = y1 - y0, x1 - x0
        if h > ref_h * 1.6:
            axis, parts = 0, int(round(h / ref_h))
        elif w > ref_w * 1.7:
            axis, parts = 1, int(round(w / ref_w))
        else:
            out.append((box, own))
            continue
        parts = max(2, parts)
        ink = (own & m)[y0:y1, x0:x1]
        prof = ink.sum(axis=1 - axis).astype(np.float32)
        n = prof.shape[0]
        cuts = [0]
        for k in range(1, parts):
            c = n * k / parts
            lo, hi = int(c - n / parts * 0.25), int(c + n / parts * 0.25)
            cuts.append(lo + int(np.argmin(prof[lo:hi])))
        cuts.append(n)
        # Only cut through a real valley (a gutter or a toe-to-head touch).
        valley = 0.4 if axis == 0 else 0.15
        mean = float(prof.mean()) if prof.size else 0.0
        if any(prof[c] > mean * valley for c in cuts[1:-1]):
            out.append((box, own))
            continue
        pieces = []
        for lo, hi in zip(cuts, cuts[1:]):
            sub = np.zeros_like(own)
            if axis == 0:
                sub[y0 + lo:y0 + hi, x0:x1] = own[y0 + lo:y0 + hi, x0:x1]
            else:
                sub[y0:y1, x0 + lo:x0 + hi] = own[y0:y1, x0 + lo:x0 + hi]
            ys, xs = np.nonzero(sub & m)
            if len(ys):
                pieces.append(((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1), sub))
        if len(pieces) == parts:
            out.extend(pieces)
            split_any = True
        else:
            out.append((box, own))
    return _split_merged(out, m, depth + 1) if split_any else out


def figures(a: np.ndarray) -> tuple[list[tuple[tuple[int, int, int, int], np.ndarray]], bool]:
    """Every figure on a board in reading order, and whether it came from a grid."""
    f = a.astype(np.float32)
    h, w = a.shape[:2]
    ry, rx = _regular(_dark_rows(a, 0), h), _regular(_dark_rows(a, 1), w)
    if len(ry) >= 3 and len(rx) >= 3:
        return _grid_cells(ry, rx, (h, w)), True
    bg = np.median(_border(f, 6), axis=0)
    d = np.sqrt(((f - bg) ** 2).sum(axis=2))
    lo = _noise_floor(np.sqrt(((_border(f, 6) - bg) ** 2).sum(axis=1)), 40.0, 90.0)
    m = d > lo
    grid_rows, grid_cols = _rule_runs(m, 0), _rule_runs(m, 1)
    gy, gx = _regular(grid_rows, h), _regular(grid_cols, w)
    if len(gy) >= 3 and len(gx) >= 3:
        return _grid_cells(gy, gx, (h, w)), True
    for y0, y1 in grid_rows:
        m[max(0, y0 - 1):y1 + 1, :] = False
    for x0, x1 in grid_cols:
        m[:, max(0, x0 - 1):x1 + 1] = False
    # Specks go by area, not by opening: an opening erases lamp posts.
    lab0, n0 = ndimage.label(m)
    if n0:
        sz = ndimage.sum(m, lab0, index=np.arange(1, n0 + 1))
        m &= ~np.isin(lab0, np.nonzero(sz < 20)[0] + 1)
    r = max(3, int(round(min(h, w) * 0.006)))
    lab, n = ndimage.label(ndimage.binary_dilation(m, iterations=r))
    if n == 0:
        return [], False
    comps = []
    for i, sl in enumerate(ndimage.find_objects(lab)):
        own = lab == (i + 1)
        comps.append({"box": [sl[1].start, sl[0].start, sl[1].stop, sl[0].stop],
                      "area": float((own & m).sum()), "own": own})
    comps = _merge_parts(comps)
    top = sorted((c["area"] for c in comps), reverse=True)
    ref = float(np.median(top[:max(1, min(len(top), 12))]))
    comps = [c for c in comps if c["area"] >= ref * 0.12]
    out = [(tuple(int(v) for v in c["box"]), c["own"]) for c in comps]
    out = _split_merged(out, m)
    med_h = float(np.median([b[3] - b[1] for b, _ in out]))
    out.sort(key=lambda t: ((t[0][1] + t[0][3]) * 0.5, t[0][0]))
    rows: list[list] = []
    for item in out:
        cy = (item[0][1] + item[0][3]) * 0.5
        if rows and abs(cy - rows[-1][0]) < med_h * 0.5:
            rows[-1][1].append(item)
        else:
            rows.append([cy, [item]])
    ordered = []
    for _, items in rows:
        ordered.extend(sorted(items, key=lambda t: t[0][0]))
    return ordered, False


# --------------------------------------------------------------------------
# Chroma key


def key(rgb: np.ndarray, strict: bool = False) -> np.ndarray:
    """RGBA float [0..1] with the board removed and its tint gone from edges."""
    f = rgb.astype(np.float32)
    ring = _border(f, 4)
    bg = np.median(ring, axis=0)
    d = np.sqrt(((f - bg) ** 2).sum(axis=2))
    lo = _noise_floor(np.sqrt(((ring - bg) ** 2).sum(axis=1)), 26.0 if strict else 34.0, 80.0)
    pink_board = bool(_pinkish(bg[None, :])[0])
    cand = d < lo
    # Vignetted cells darken toward the rules; that dark rim is board too.
    rim = np.concatenate([f[:4].reshape(-1, 3), f[-4:].reshape(-1, 3), f[:, :4].reshape(-1, 3), f[:, -4:].reshape(-1, 3)])
    if float(np.median(rim.max(axis=1))) < 70.0 and float(bg.max()) > 110.0:
        cand |= f.max(axis=2) < 70.0
    # Board speckle keys too, never skin or blood (far in hue as well).
    if pink_board:
        cand |= (d < lo * 1.8) & _pinkish(f)
    # Rules at the crop edge are board as well.
    cand[:2, :] = True
    cand[-2:, :] = True
    cand[:, :2] = True
    cand[:, -2:] = True
    lab, n = ndimage.label(cand)
    bgmask = np.zeros(cand.shape, bool)
    if n:
        edge_ids = np.unique(np.concatenate([lab[:3].ravel(), lab[-3:].ravel(), lab[:, :3].ravel(), lab[:, -3:].ravel()]))
        bgmask |= np.isin(lab, edge_ids[edge_ids > 0])
        # Enclosed pockets (between an arm and the torso) key when they are
        # board-coloured through and through.
        idx = np.arange(1, n + 1)
        sizes = ndimage.sum(np.ones_like(d), lab, index=idx)
        tight = ndimage.mean((d < lo * 0.8).astype(np.float32), lab, index=idx)
        bgmask |= np.isin(lab, np.nonzero((sizes >= 6) & (tight > 0.6))[0] + 1)
    fg = ~bgmask
    if pink_board:
        # Board-hued blobs hanging on the outside (a painted magenta puddle,
        # a glow dot) peel off; board-hued details enclosed by the figure
        # (Gant's tie) stay because they never touch the outside.
        h_, s_ = _hue_sat(f)
        peel = fg & _board_hue(f, bg) & (s_ > 0.45)
        if peel.any():
            labp, npk = ndimage.label(peel, structure=np.ones((3, 3), bool))
            outside = ndimage.binary_dilation(~fg, iterations=1)
            touch = np.unique(labp[outside & peel])
            fg &= ~np.isin(labp, touch[touch > 0])
    lab2, n2 = ndimage.label(fg)
    if n2:
        sizes = ndimage.sum(fg, lab2, index=np.arange(1, n2 + 1))
        fg &= ~np.isin(lab2, np.nonzero(sizes < max(10.0, sizes.max() * 0.002))[0] + 1)
    # Edge ring: coverage from projecting onto board -> nearest interior
    # colour; the colour becomes that interior colour (no tint survives).
    inner = ndimage.binary_erosion(fg, iterations=2)
    if pink_board:
        near = ndimage.distance_transform_edt(fg) <= 6
        inner &= ~(near & _board_hue(f, bg))
    if not inner.any():
        inner = fg
    edge = fg & ~inner
    col = f.copy()
    alpha = fg.astype(np.float32)
    if edge.any():
        idx = ndimage.distance_transform_edt(~inner, return_distances=False, return_indices=True)
        c_in = f[idx[0], idx[1]]
        v = c_in - bg
        wproj = np.clip(((f - bg) * v).sum(axis=2) / np.maximum((v * v).sum(axis=2), 1.0), 0.0, 1.0)
        # Dark outline pixels are ink even when the projection is weak.
        ink = f.max(axis=2) < 70
        wproj = np.where(ink, np.maximum(wproj, 0.75), wproj)
        alpha[edge] = wproj[edge]
        tinted = _board_hue(f, bg) | ((f[..., 0] > f[..., 1] + 12) & (f[..., 2] > f[..., 1] + 4))
        ink_col = np.where(tinted[..., None], np.minimum(c_in * 0.55, f.max(axis=2, keepdims=True)), f)
        col[edge] = np.where(ink[edge][:, None], ink_col[edge], c_in[edge])
    col = np.clip(col, 0.0, 255.0) / 255.0
    return np.dstack([col, alpha]).astype(np.float32)


def bbox(rgba: np.ndarray, t: float = 0.5) -> tuple[int, int, int, int] | None:
    m = rgba[..., 3] >= t
    if not m.any():
        return None
    ys, xs = np.nonzero(m)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


# --------------------------------------------------------------------------
# Resampling


def resample(rgba: np.ndarray, scale: float, hard: bool = True) -> np.ndarray:
    """Premultiplied Lanczos resize; alpha thresholded for crisp pixel edges."""
    h, w = rgba.shape[:2]
    nw, nh = max(1, int(round(w * scale))), max(1, int(round(h * scale)))
    a = rgba[..., 3]
    chans = []
    for c in range(3):
        im = Image.fromarray((rgba[..., c] * a).astype(np.float32), mode="F")
        chans.append(np.asarray(im.resize((nw, nh), Image.Resampling.LANCZOS)))
    ai = np.asarray(Image.fromarray(a.astype(np.float32), mode="F").resize((nw, nh), Image.Resampling.LANCZOS))
    ai = np.clip(ai, 0.0, 1.0)
    rgb = np.clip(np.dstack(chans) / np.maximum(ai, 1e-4)[..., None], 0.0, 1.0)
    if hard:
        ai = (ai >= 0.5).astype(np.float32)
    return np.dstack([rgb, ai]).astype(np.float32)


def to_img(rgba: np.ndarray) -> Image.Image:
    out = np.clip(rgba * 255.0 + 0.5, 0, 255).astype(np.uint8)
    out[..., :3][out[..., 3] == 0] = 0
    return Image.fromarray(out, "RGBA")


def load(src: Path) -> np.ndarray:
    return np.asarray(Image.open(src).convert("RGB"))


def _mask(im: np.ndarray) -> np.ndarray:
    return im[..., 3] >= 0.5


def _trim(im: np.ndarray) -> np.ndarray:
    m = _mask(im)
    ys = np.nonzero(m.any(axis=1))[0]
    xs = np.nonzero(m.any(axis=0))[0]
    return im[int(ys.min()):int(ys.max()) + 1, int(xs.min()):int(xs.max()) + 1]


# --------------------------------------------------------------------------
# Frames of one character


@dataclass
class Raw:
    img: np.ndarray            # keyed RGBA, trimmed, source scale
    anchor: str                # feet | cell


def raw_frames(src: Path, anchor: str) -> list[Raw]:
    a = load(src)
    h, w = a.shape[:2]
    if src.name in GRID:
        gc, gr = GRID[src.name]
        found, grid = _grid_cells(_even(h, gr), _even(w, gc), (h, w)), True
    else:
        found, grid = figures(a)
    out: list[Raw] = []
    for (x0, y0, x1, y1), own in found:
        # Grid cells are keyed inside the rules; loose figures get a margin
        # of board so the flood has somewhere to start.
        pad = 0 if grid else 6
        X0, Y0 = max(0, x0 - pad), max(0, y0 - pad)
        X1, Y1 = min(w, x1 + pad), min(h, y1 + pad)
        k = key(a[Y0:Y1, X0:X1])
        if not grid:
            k[..., 3] *= own[Y0:Y1, X0:X1]
        bb = bbox(k)
        if bb is None or float(_mask(k).mean()) < 0.004:
            continue
        out.append(Raw(k[bb[1]:bb[3], bb[0]:bb[2]], anchor))
    return out


def _best_dx(ref: np.ndarray, mov: np.ndarray, start: int, span: int) -> int:
    """Left-edge shift of mov (feet aligned) maximising overlap with ref."""
    rh, rw = ref.shape
    mh, mw = mov.shape
    h = max(rh, mh)
    pad = span + max(rw, mw)
    base = np.zeros((h, rw + 2 * pad), np.float32)
    base[h - rh:, pad:pad + rw] = ref
    best, best_dx = -1.0, start
    mv = mov.astype(np.float32)
    for dx in range(start - span, start + span + 1):
        x = pad + dx
        if x < 0 or x + mw > base.shape[1]:
            continue
        score = float((base[h - mh:, x:x + mw] * mv).sum())
        if score > best:
            best, best_dx = score, dx
    return best_dx


def _loop_outliers(frames: list[np.ndarray]) -> list[np.ndarray]:
    """Drop stray poses from a loop (a baton swing inside a walk board)."""
    if len(frames) < 6:
        return frames
    med = float(np.median([f.shape[1] for f in frames]))
    keep = [f for f in frames if f.shape[1] <= med * 1.35]
    return keep if len(keep) >= 4 else frames


def pingpong(frames: list, minimum: int = 6) -> list:
    if len(frames) >= minimum or not frames:
        return frames
    extra = list(reversed(frames[1:-1])) if len(frames) > 2 else list(reversed(frames))
    out = list(frames) + extra
    i = 0
    while len(out) < minimum:
        out.append(frames[i % len(frames)])
        i += 1
    return out[:12]


LOOPS = ("idle", "walk", "parkour_run", "duck", "dog", "crawl")


def build_who(who: str, clips: dict[str, tuple[Path, str]], stand_h: int = STAND_H,
              min_cell: int = MIN_WHO_CELL, split: dict[str, tuple[int, int]] | None = None) -> None:
    """Slice every clip of one character with one body size and one anchor."""
    raws: dict[str, list[Raw]] = {}
    cache: dict[Path, list[Raw]] = {}
    for clip, (src, anchor) in clips.items():
        if src not in cache:
            cache[src] = raw_frames(src, anchor)
        fr = [Raw(r.img, anchor) for r in cache[src]]
        if split and clip in split:
            a0, a1 = split[clip]
            fr = fr[a0:a1]
        if len(fr) > 12:
            fr = fr[:12]
        if not fr:
            raise SystemExit("%s/%s: no frames in %s" % (who, clip, src.name))
        raws[clip] = fr
    ref_clip = "idle" if "idle" in raws else ("dog" if "dog" in raws else next(iter(raws)))
    base = stand_h / float(np.median([r.img.shape[0] for r in raws[ref_clip]]))

    def body_area(fr: list[Raw]) -> float:
        return float(np.median([float(_mask(r.img).sum()) for r in fr]))

    ref_area = body_area(raws[ref_clip])
    scaled: dict[str, list[np.ndarray]] = {}
    for clip, fr in raws.items():
        # Each board has its own zoom; body area is pose-invariant enough to
        # bring every clip to the idle body's size.
        k = base * float(np.sqrt(ref_area / max(body_area(fr), 1.0)))
        imgs = [resample(r.img, k) for r in fr]
        imgs = [_trim(im) for im in imgs if _mask(im).any()]
        if clip in LOOPS:
            imgs = _loop_outliers(imgs)
        scaled[clip] = imgs
    ref = _mask(scaled[ref_clip][0])
    stand_mid = ref.shape[0] * 0.5
    placed: dict[str, list[tuple[np.ndarray, int]]] = {}
    max_side = 0.0
    max_up = 0
    for clip, imgs in scaled.items():
        anchor = raws[clip][0].anchor
        rows_out = []
        prev = None
        for im in imgs:
            m = _mask(im)
            span = max(8, int(max(m.shape[1], ref.shape[1]) * 0.45))
            start = (ref.shape[1] - m.shape[1]) // 2
            dx = _best_dx(ref, m, start, span)
            if prev is not None and abs(dx - prev) > span * 0.8:
                dx = prev
            prev = dx
            rows_out.append((im, dx))
            max_side = max(max_side, -dx, dx + im.shape[1] - ref.shape[1])
            need = stand_mid + im.shape[0] * 0.5 if anchor == "cell" else float(im.shape[0])
            max_up = max(max_up, int(np.ceil(need)))
        placed[clip] = rows_out
    cw = int(np.ceil(max(ref.shape[1] * 0.5 + max_side, min_cell * 0.5))) * 2
    ch = max(min_cell, int(np.ceil((max_up + 4) / 2.0)) * 2)
    ref_left = cw // 2 - ref.shape[1] // 2
    baseline = ch - 2
    dest = OUT / who
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True)
    for clip, rows_out in placed.items():
        cell_anchor = raws[clip][0].anchor == "cell"
        frames = []
        for im, dx in rows_out:
            x = int(np.clip(ref_left + dx, 0, cw - im.shape[1]))
            if cell_anchor:
                y = int(round(baseline - stand_mid - im.shape[0] * 0.5))
            else:
                y = baseline - im.shape[0]
            frames.append((im, x, int(np.clip(y, 0, ch - im.shape[0]))))
        if clip in LOOPS or len(frames) < 6:
            frames = pingpong(frames, 6)
        write_sheet(dest / clip, frames, (cw, ch))
    print("%-16s base %.3f cell %dx%d clips %d" % (who, base, cw, ch, len(placed)))


# --------------------------------------------------------------------------
# Packing and single frames


def write_sheet(stem: Path, frames: list[tuple[np.ndarray, int, int]], cell: tuple[int, int]) -> None:
    """One PNG per clip (trimmed frames, shelf packed) + JSON regions."""
    x = y = shelf = 0
    places = []
    for im, _, _ in frames:
        h, w = im.shape[:2]
        if x + w + PAD > SHEET_MAX_W:
            x = 0
            y += shelf + PAD
            shelf = 0
        places.append((x, y))
        x += w + PAD
        shelf = max(shelf, h)
    W = max(p[0] + f[0].shape[1] for p, f in zip(places, frames))
    H = y + shelf
    sheet = np.zeros((H, W, 4), np.float32)
    meta = {"cell": list(cell), "frames": []}
    for (px, py), (im, ox, oy) in zip(places, frames):
        h, w = im.shape[:2]
        sheet[py:py + h, px:px + w] = im
        meta["frames"].append({"x": px, "y": py, "w": w, "h": h, "ox": ox, "oy": oy})
    to_img(sheet).save(stem.with_suffix(".png"), optimize=True)
    stem.with_suffix(".json").write_text(json.dumps(meta, separators=(",", ":")))


def build_live(who: str, src: Path, anchor: str = "prop") -> None:
    """Animated prop (idle only): the whole clip fits PROP_CELL at one scale."""
    fr = raw_frames(src, "feet")[:12]
    if not fr:
        raise SystemExit("%s: no frames" % who)
    mw = max(r.img.shape[1] for r in fr)
    mh = max(r.img.shape[0] for r in fr)
    scale = min((PROP_CELL - 8) / mw, (PROP_CELL - 6) / mh)
    frames = []
    for r in fr:
        im = resample(r.img, scale)
        if not _mask(im).any():
            continue
        im = _trim(im)
        x = (PROP_CELL - im.shape[1]) // 2
        y = PROP_CELL - 2 - im.shape[0] if anchor == "prop" else (PROP_CELL - im.shape[0]) // 2
        frames.append((im, x, y))
    frames = pingpong(frames, 6)
    dest = OUT / who
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True)
    write_sheet(dest / "idle", frames, (PROP_CELL, PROP_CELL))
    print("%-16s live %d frames" % (who, len(frames)))


def tile_cut(cell: np.ndarray) -> np.ndarray:
    """Opaque square tile: the solid face, pink rim trimmed, no chroma left."""
    k = key(cell, strict=True)
    m = k[..., 3] >= 0.5
    lab, n = ndimage.label(m)
    if n:
        sizes = ndimage.sum(m, lab, index=np.arange(1, n + 1))
        m = lab == (int(np.argmax(sizes)) + 1)
    if not m.any():
        block = cell
    else:
        rows_ok = np.nonzero(m.mean(axis=1) > 0.92 * m.mean(axis=1).max())[0]
        cols_ok = np.nonzero(m.mean(axis=0) > 0.92 * m.mean(axis=0).max())[0]
        y0, y1 = int(rows_ok.min()) + 2, int(rows_ok.max()) - 1
        x0, x1 = int(cols_ok.min()) + 2, int(cols_ok.max()) - 1
        block = cell[y0:y1, x0:x1]
    f = block.astype(np.float32)
    # Pinkish survivors take their nearest non-pink neighbour's colour.
    bad = _pinkish(f)
    if bad.any() and not bad.all():
        idx = ndimage.distance_transform_edt(bad, return_distances=False, return_indices=True)
        f = f[idx[0], idx[1]]
    chans = [np.asarray(Image.fromarray(f[..., c] / 255.0, mode="F").resize((TILE, TILE), Image.Resampling.LANCZOS))
             for c in range(3)]
    return np.clip(np.dstack(chans + [np.ones((TILE, TILE), np.float32)]), 0.0, 1.0)


def build_named(src: Path, dest_dir: Path, names: list[str], mode: str, cols: int = 0, rows: int = 0) -> None:
    """Single-frame props, tiles and icons."""
    a = load(src)
    dest_dir.mkdir(parents=True, exist_ok=True)
    n = 0
    for (x0, y0, x1, y1), name in zip(cells(a, cols, rows), names):
        inset = 4
        cell = a[y0 + inset:y1 - inset, x0 + inset:x1 - inset]
        if mode == "icon":
            im = np.dstack([cell.astype(np.float32) / 255.0, np.ones(cell.shape[:2], np.float32)])
            out = resample(im, ICON / max(im.shape[:2]))
            canvas = np.zeros((ICON, ICON, 4), np.float32)
            oy, ox = (ICON - out.shape[0]) // 2, (ICON - out.shape[1]) // 2
            canvas[oy:oy + out.shape[0], ox:ox + out.shape[1]] = out
        elif mode == "tile":
            canvas = tile_cut(cell)
        else:
            k = key(cell)
            bb = bbox(k)
            if bb is None:
                continue
            k = k[bb[1]:bb[3], bb[0]:bb[2]]
            im = _trim(resample(k, min((PROP_CELL - 8) / k.shape[1], (PROP_CELL - 6) / k.shape[0])))
            canvas = np.zeros((PROP_CELL, PROP_CELL, 4), np.float32)
            x = (PROP_CELL - im.shape[1]) // 2
            y = PROP_CELL - 2 - im.shape[0]
            canvas[y:y + im.shape[0], x:x + im.shape[1]] = im
        to_img(canvas).save(dest_dir / ("%s.png" % name))
        n += 1
    print("%s -> %s (%d/%d)" % (src.name, dest_dir.relative_to(ROOT), n, len(names)))


# --------------------------------------------------------------------------
# What goes where

FATHER = {
    "idle": ("father-idle-stand.png", "feet"),
    "walk": ("father-walk.png", "feet"),
    "parkour_run": ("father-parkour-cycle.png", "feet"),
    "jump": ("father-jump.png", "cell"),
    "duck": ("father-duck.png", "feet"),
    "hurt": ("father-hurt.png", "feet"),
    "jab": ("father-jab.png", "feet"),
    "cross": ("father-cross.png", "feet"),
    "gut": ("father-gut-casual.png", "feet"),
    "heavy": ("father-heavy-casual.png", "feet"),
    "front_kick": ("father-front-kick-casual.png", "feet"),
    "side_kick": ("father-side-kick-casual.png", "feet"),
    "roundhouse": ("father-roundhouse-casual.png", "feet"),
    "uppercut": ("father-uppercut-casual.png", "cell"),
    "air_mix": ("father-air-mix-casual.png", "cell"),
    "snap": ("father-snap-casual.png", "feet"),
    "slide": ("father-slide-casual.png", "feet"),
    "dive": ("father-dive-casual.png", "cell"),
}

PUNK = {
    "idle": "punk-idle.png",
    "walk": "punk-walk-casual.png",
    "attack": "punk-attack.png",
    "hurt": "punk-hurt.png",
}

COP = {
    "idle": "cop-idle-stand.png",
    "walk": "cop-walk-patrol.png",
    "attack": "cop-attack-stick.png",
    "hurt": "cop-hurt-recoil.png",
}

TILE_NAMES = [
    "cobble",
    "cobble_wet",
    "plank",
    "water",
    "brick",
    "brick_window",
    "roof",
    "curb",
    "lamp_tile",
    "awning_tile",
    "crates_tile",
    "barrel_tile",
]

PROP_NAMES = [
    "booth",
    "barrel",
    "hydrant",
    "manhole",
    "kiosk",
    "news",
    "cop_car",
    "dumpster",
    "mail",
    "crate",
    "awning",
    "lamp",
]

TOY_NAMES = [
    "bench",
    "cart",
    "hood",
    "pole",
    "billboard",
    "scaffold",
    "grind",
    "flag",
    "crate_stack",
    "plank_chunk",
    "facade",
    "crane",
]

SON = {
    "idle": ("son-idle-stand.png", "feet"),
    "walk": ("son-walk-jog.png", "feet"),
    "parkour_run": ("son-parkour-cycle.png", "feet"),
    "jump": ("son-jump-arc.png", "cell"),
    "duck": ("son-duck-crouch.png", "feet"),
    "hurt": ("son-hurt-recoil.png", "feet"),
    "jab": ("son-jab-punch.png", "feet"),
    "cross": ("son-cross-punch.png", "feet"),
    "gut": ("son-gut-punch.png", "feet"),
    "heavy": ("son-heavy-haymaker.png", "feet"),
    "front_kick": ("son-front-kick.png", "feet"),
    "side_kick": ("son-side-kick.png", "feet"),
    "roundhouse": ("son-roundhouse.png", "feet"),
    "uppercut": ("son-uppercut.png", "cell"),
    "air_mix": ("son-air-mix.png", "cell"),
    "snap": ("son-snap-flash.png", "feet"),
    "slide": ("son-slide-crouch.png", "feet"),
    "dive": ("son-dive-drop.png", "cell"),
}

LOT_TILE_NAMES = [
    "asphalt",
    "asphalt_wet",
    "stall",
    "lot_curb",
    "chain",
    "puddle",
    "oil",
    "hatch",
    "cone_tile",
    "bumper",
    "sodium_tile",
    "lot_roof",
]

LOT_PROP_NAMES = [
    "sedan",
    "hatchback",
    "van",
    "cone",
    "sodium_lamp",
    "ticket_booth",
    "barrier",
    "lot_cart",
    "lot_dumpster",
    "lot_crate",
    "fence",
    "drum",
]

HUB_NAMES = [
    "pawn_shop",
    "radio_tower",
    "blood_fridge",
    "dojo",
    "workshop",
    "streak_locker",
    "trophy_cabinet",
]

HUB2_NAMES = [
    "street_map",
    "therapy_couch",
    "wardrobe_cage",
    "research_lab",
    "front_desk",
    "mail_slot",
    "bounty_board",
    "punching_bag",
]

HUB3_NAMES = [
    "bulletin_board",
    "compare_mirrors",
    "patrol_desk",
    "album_wall",
    "invoice_wheel",
    "warrant_fax",
    "tip_jar",
    "lost_found",
    "payphone",
    "water_cooler",
    "coat_check",
    "time_clock",
    "bleach_closet",
]

LIVE_IDLE = {
    "booth": "smash-booth-idle.png",
    "barrel": "smash-barrel-idle.png",
    "hydrant": "smash-hydrant-idle.png",
    "manhole": "smash-manhole-idle.png",
    "kiosk": "smash-kiosk-idle.png",
    "news": "smash-news-idle.png",
    "cop_car": "smash-copcar-idle.png",
    "dumpster": "smash-dumpster-idle.png",
    "mail": "smash-mail-idle.png",
    "bench": "toy-bench-idle.png",
    "awning": "toy-awning-idle.png",
    "cart": "toy-cart-idle.png",
    "hood": "toy-hood-idle.png",
    "pole": "toy-pole-idle.png",
    "billboard": "toy-billboard-idle.png",
    "scaffold": "toy-scaffold-idle.png",
    "grind": "toy-grind-idle.png",
    "flag": "toy-flag-idle.png",
    "crate": "toy-crate-idle.png",
    "gap": "gate-gap-idle.png",
    "rail": "gate-rail-idle.png",
    "power_gate": "power-gate-idle.png",
    "chain": "pickup-chain-idle.png",
}

REMAIN_IDLE = {
    "vault": "smash-vault-idle.png",
    "geyser": "toy-geyser-idle.png",
    "pistol": "pickup-pistol-idle.png",
    "board": "pickup-board-idle.png",
    "knife": "pickup-knife-idle.png",
    "pipe": "pickup-pipe-idle.png",
    "envelope": "pickup-envelope-idle.png",
    "web_anchor": "web-anchor-idle.png",
    "blood_mart": "blood-mart-idle.png",
    "secret": "secret-stash-idle.png",
    "fire_escape": "fire-escape-idle.png",
    "tower": "viewpoint-tower-idle.png",
}

GANT = {
    "idle": "gant-idle-stand.png",
    "walk": "gant-walk-cycle.png",
    "attack": "gant-attack-knuckles.png",
    "hurt": "gant-hurt-recoil.png",
}

SHIFT = {
    "idle": "shift-idle-stand.png",
    "walk": "shift-walk-cycle.png",
    "attack": "shift-attack-clip.png",
    "hurt": "shift-hurt-recoil.png",
}

MOHAWK = {
    "idle": "mohawk-idle-stand.png",
    "walk": "mohawk-walk-cycle.png",
    "attack": "mohawk-attack-bat.png",
    "hurt": "mohawk-hurt-recoil.png",
}

LOT_LIVE = {
    "fridge": "smash-fridge-idle.png",
    "crowbar": "pickup-crowbar-idle.png",
    "sedan": "lot-sedan-idle.png",
    "hatchback": "lot-hatchback-idle.png",
    "van": "lot-van-idle.png",
    "sodium_lamp": "lot-sodium-idle.png",
    "ticket_booth": "lot-ticket-booth-idle.png",
    "cone": "lot-cone-idle.png",
    "barrier": "lot-barrier-idle.png",
    "drum": "lot-drum-idle.png",
    "fence": "lot-fence-idle.png",
}

COPING = {
    "idle": "coping-imp-idle-stand.png",
    "walk": "coping-imp-walk-cycle.png",
    "attack": "coping-imp-attack-jab.png",
    "hurt": "coping-imp-hurt-recoil.png",
}

VALET = {
    "idle": "valet-idle-stand.png",
    "walk": "valet-walk-cycle.png",
    "attack": "valet-attack-clamp.png",
    "hurt": "valet-hurt-recoil.png",
}

CLAMP = {
    "idle": "clamp-king-idle-stand.png",
    "walk": "clamp-king-walk-cycle.png",
    "attack": "clamp-king-attack-slam.png",
    "hurt": "clamp-king-hurt-recoil.png",
}

HYDRA = {
    "idle": "lot-hydra-idle-stand.png",
    "walk": "lot-hydra-walk-cycle.png",
    "attack": "lot-hydra-attack-boots.png",
    "hurt": "lot-hydra-hurt-recoil.png",
}

CLIPBOARD = {
    "idle": "clipboard-idle-hover.png",
    "walk": "clipboard-walk-fly.png",
    "attack": "clipboard-attack-paper.png",
    "hurt": "clipboard-hurt-recoil.png",
}




def sheet(name: str) -> Path:
    src = ART / name
    if not src.exists():
        src = SHEETS / name
    if not src.exists():
        raise SystemExit("missing sheet %s" % name)
    return src


def slice_hero(who: str, table: dict[str, tuple[str, str]]) -> None:
    build_who(who, {clip: (sheet(n), a) for clip, (n, a) in table.items()})


def slice_enemy(who: str, table: dict[str, str], anchor: str = "feet") -> None:
    build_who(who, {clip: (sheet(n), anchor) for clip, n in table.items()})


def slice_skinwalker() -> None:
    src = sheet("skinwalker-sheet.png")
    clips = {"dog": (src, "feet"), "crawl": (src, "feet"), "walk": (src, "feet"), "gape": (src, "feet")}
    split = {"dog": (0, 4), "crawl": (4, 8), "walk": (8, 12), "gape": (12, 16)}
    build_who("skinwalker", clips, split=split)


def slice_dock() -> None:
    build_named(sheet("dock-tiles.png"), OUT / "dock" / "tiles", TILE_NAMES, "tile")
    build_named(sheet("dock-props.png"), OUT / "dock" / "props", PROP_NAMES, "prop")
    build_named(sheet("dock-toys.png"), OUT / "dock" / "toys", TOY_NAMES, "prop")


def slice_lot() -> None:
    build_named(sheet("lot-tiles.png"), OUT / "lot" / "tiles", LOT_TILE_NAMES, "tile", 4, 3)
    build_named(sheet("lot-props.png"), OUT / "lot" / "props", LOT_PROP_NAMES, "prop", 4, 3)


def slice_hub() -> None:
    build_named(sheet("clinic-hub-icons.png"), OUT / "hub", HUB_NAMES, "icon", 4, 2)
    build_named(sheet("clinic-hub-gate-icons.png"), OUT / "hub", HUB2_NAMES, "icon", 4, 2)
    build_named(sheet("clinic-hub-camp-icons.png"), OUT / "hub", HUB3_NAMES, "icon", 4, 4)


def slice_live() -> None:
    for table in (LIVE_IDLE, REMAIN_IDLE, LOT_LIVE):
        for who, name in table.items():
            build_live(who, sheet(name))
    build_live("lamp", sheet("lamp-flicker-sheet.png"), "cell")


JOBS = {
    "father": lambda: slice_hero("father", FATHER),
    "son": lambda: slice_hero("son", SON),
    "punk": lambda: slice_enemy("punk", PUNK),
    "cop": lambda: slice_enemy("cop", COP),
    "gant": lambda: slice_enemy("gant", GANT),
    "shift": lambda: slice_enemy("shift_lead", SHIFT),
    "mohawk": lambda: slice_enemy("mohawk", MOHAWK),
    "coping": lambda: slice_enemy("coping_imp", COPING),
    "valet": lambda: slice_enemy("valet", VALET),
    "clamp": lambda: slice_enemy("clamp_king", CLAMP),
    "hydra": lambda: slice_enemy("lot_hydra", HYDRA),
    "clipboard": lambda: slice_enemy("clipboard_flier", CLIPBOARD, "cell"),
    "bystander": lambda: slice_enemy("bystander", {"idle": "bystander-idle-sheet.png"}),
    "skinwalker": slice_skinwalker,
    "dock": slice_dock,
    "lot": slice_lot,
    "hub": slice_hub,
    "live": slice_live,
}


def main() -> None:
    args = [a.lower() for a in sys.argv[1:]] or ["all"]
    unknown = [a for a in args if a != "all" and a not in JOBS]
    if unknown:
        raise SystemExit("unknown: %s (know: all %s)" % (" ".join(unknown), " ".join(JOBS)))
    todo = list(JOBS) if "all" in args else args
    for job in todo:
        JOBS[job]()
    print("done")


if __name__ == "__main__":
    main()
