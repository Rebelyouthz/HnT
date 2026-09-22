#!/usr/bin/env python3
"""Slice generated sprite sheets into Godot PNG frames. Magenta/maroon chroma."""
from __future__ import annotations

import os
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = Path(
    os.environ.get(
        "HNT_SPRITE_SRC",
        "/home/timmietooth/.local/state/cursor/agent-stores/"
        "cursor_agent_stores/bc-9f8f0f60-5113-55c8-8b20-0a70ba1c1d4f/"
        "files/artifacts/assets",
    )
)
OUT = ROOT / "assets" / "sprites"
SHEETS = ROOT / "tools" / "sprite_src"
CANVAS = 96


def _dark(p: tuple, t: int = 42) -> bool:
    return p[0] < t and p[1] < t and p[2] < t


def _cluster(xs: list[int], gap: int = 4) -> list[int]:
    if not xs:
        return []
    groups: list[list[int]] = [[xs[0]]]
    for x in xs[1:]:
        if x - groups[-1][-1] <= gap:
            groups[-1].append(x)
        else:
            groups.append([x])
    return [g[len(g) // 2] for g in groups]


def _lines(im: Image.Image, horizontal: bool) -> list[int]:
    w, h = im.size
    px = im.load()
    hits: list[int] = []
    n = h if horizontal else w
    m = w if horizontal else h
    step = 3
    for i in range(n):
        dark = 0
        tot = 0
        for j in range(0, m, step):
            p = px[j, i] if horizontal else px[i, j]
            tot += 1
            if _dark(p[:3]):
                dark += 1
        if tot and dark / tot > 0.62:
            hits.append(i)
    return _cluster(hits, 4)


def _pairs(lines: list[int], extent: int) -> list[tuple[int, int]]:
    pts = list(lines)
    if not pts or pts[0] > 8:
        pts = [0] + pts
    if pts[-1] < extent - 8:
        pts = pts + [extent - 1]
    out: list[tuple[int, int]] = []
    for a, b in zip(pts, pts[1:]):
        if b - a > 24:
            out.append((a + 2, b - 1))
    return out


def _equal(w: int, h: int, cols: int, rows: int) -> tuple[list[tuple[int, int]], list[tuple[int, int]]]:
    cw = w / cols
    ch = h / rows
    rows_b = [(int(i * ch) + 2, int((i + 1) * ch) - 2) for i in range(rows)]
    cols_b = [(int(j * cw) + 2, int((j + 1) * cw) - 2) for j in range(cols)]
    return rows_b, cols_b


def grid(im: Image.Image) -> list[tuple[int, int, int, int]]:
    w, h = im.size
    ys = _lines(im, True)
    xs = _lines(im, False)
    rows = _pairs(ys, h)
    cols = _pairs(xs, w)
    min_w = int(w * 0.16)
    min_h = int(h * 0.16)
    rows = [(a, b) for a, b in rows if b - a >= min_h]
    cols = [(a, b) for a, b in cols if b - a >= min_w]
    if len(rows) < 2 or len(cols) < 2:
        guess = (4, 4) if h > w * 0.9 and len(ys) >= 5 else (4, 3)
        if w / h > 1.6:
            guess = (4, 2)
        rows, cols = _equal(w, h, guess[0], guess[1])
    cells: list[tuple[int, int, int, int]] = []
    for y0, y1 in rows:
        for x0, x1 in cols:
            if (x1 - x0) >= min_w and (y1 - y0) >= min_h:
                cells.append((x0, y0, x1, y1))
    return cells


def _bg(im: Image.Image) -> tuple[int, int, int]:
    px = im.load()
    w, h = im.size
    samples = [
        px[4, 4],
        px[w - 5, 4],
        px[4, h - 5],
        px[w - 5, h - 5],
        px[w // 2, 4],
        px[4, h // 2],
    ]
    rs = [p[0] for p in samples]
    gs = [p[1] for p in samples]
    bs = [p[2] for p in samples]
    return (sum(rs) // len(rs), sum(gs) // len(gs), sum(bs) // len(bs))


def _is_chroma(p: tuple, bg: tuple[int, int, int], strict: bool = False) -> bool:
    r, g, b = p[0], p[1], p[2]
    br, bg_, bb = bg
    dist = abs(r - br) + abs(g - bg_) + abs(b - bb)
    limit = 48 if strict else 68
    if dist < limit:
        return True
    hot_magenta = r > 200 and b > 180 and g < 90
    if hot_magenta:
        return True
    if strict:
        return False
    magenta = r > 110 and b > 90 and g < 95 and (r > g + 30) and (b > g + 15)
    return bool(magenta)


def chroma_cell(
    im: Image.Image,
    box: tuple[int, int, int, int],
    bg: tuple[int, int, int],
    strict: bool = False,
) -> Image.Image:
    x0, y0, x1, y1 = box
    crop = im.crop((x0, y0, x1, y1)).convert("RGBA")
    pix = crop.load()
    w, h = crop.size
    for y in range(h):
        for x in range(w):
            p = pix[x, y]
            if _is_chroma(p, bg, strict):
                pix[x, y] = (0, 0, 0, 0)
    return crop


def _bbox(im: Image.Image) -> tuple[int, int, int, int] | None:
    a = im.split()[-1]
    return a.getbbox()


def _opaque_frac(im: Image.Image) -> float:
    a = im.split()[-1]
    hist = a.histogram()
    on = sum(hist[32:])
    return on / max(im.size[0] * im.size[1], 1)


def fit_feet(im: Image.Image, size: int = CANVAS) -> Image.Image:
    box = _bbox(im)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    if box is None:
        return out
    trimmed = im.crop(box)
    tw, th = trimmed.size
    scale = min((size - 8) / max(tw, 1), (size - 6) / max(th, 1))
    nw = max(1, int(tw * scale))
    nh = max(1, int(th * scale))
    trimmed = trimmed.resize((nw, nh), Image.Resampling.NEAREST)
    x = (size - nw) // 2
    y = size - nh - 2
    out.paste(trimmed, (x, y), trimmed)
    return out


def fit_cell(im: Image.Image, size: int = CANVAS) -> Image.Image:
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    box = _bbox(im)
    src = im.crop(box) if box else im
    tw, th = src.size
    if tw < 2 or th < 2:
        return out
    scale = min(size / tw, size / th)
    nw = max(1, int(tw * scale))
    nh = max(1, int(th * scale))
    src = src.resize((nw, nh), Image.Resampling.NEAREST)
    x = (size - nw) // 2
    y = (size - nh) // 2
    out.paste(src, (x, y), src)
    return out


def fit_tile(im: Image.Image, size: int = 64) -> Image.Image:
    box = _bbox(im)
    src = im.crop(box) if box else im
    return src.resize((size, size), Image.Resampling.NEAREST).convert("RGBA")


def pingpong(frames: list[Image.Image], minimum: int = 6) -> list[Image.Image]:
    if len(frames) >= minimum:
        return frames
    if not frames:
        return frames
    extra = list(reversed(frames[1:-1])) if len(frames) > 2 else list(reversed(frames))
    out = list(frames) + extra
    i = 0
    while len(out) < minimum:
        out.append(frames[i % len(frames)])
        i += 1
    return out[:12]


def save_clip(frames: list[Image.Image], dest: Path) -> None:
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True, exist_ok=True)
    for i, fr in enumerate(frames):
        fr.save(dest / ("%02d.png" % i))


def slice_who(src: Path, dest: Path, anchor: str) -> int:
    im = Image.open(src).convert("RGBA")
    bg = _bg(im)
    cells = grid(im)
    frames: list[Image.Image] = []
    for box in cells:
        raw = chroma_cell(im, box, bg, strict=anchor == "tile")
        if _bbox(raw) is None or _opaque_frac(raw) < 0.06:
            continue
        if anchor == "cell":
            frames.append(fit_cell(raw))
        elif anchor == "tile":
            frames.append(fit_tile(raw, 64))
        elif anchor == "prop":
            frames.append(fit_feet(raw, 96))
        else:
            frames.append(fit_feet(raw))
    if anchor in ("feet", "cell") and len(frames) > 12:
        frames = frames[:12]
    frames = pingpong(frames, 6 if anchor in ("feet", "cell") else 1)
    save_clip(frames, dest)
    print("%s -> %s (%d frames)" % (src.name, dest, len(frames)))
    return len(frames)


def copy_sheet(name: str) -> Path:
    src = ART / name
    if not src.exists():
        src = SHEETS / name
    SHEETS.mkdir(parents=True, exist_ok=True)
    dst = SHEETS / name
    if src.exists() and src.resolve() != dst.resolve():
        shutil.copy2(src, dst)
    return dst


def save_named(frames: list[Image.Image], dest_dir: Path, names: list[str]) -> None:
    dest_dir.mkdir(parents=True, exist_ok=True)
    n = min(len(frames), len(names))
    for i in range(n):
        frames[i].save(dest_dir / ("%s.png" % names[i]))
        print("  prop %s" % names[i])


def slice_named(src: Path, dest_dir: Path, names: list[str], mode: str) -> None:
    im = Image.open(src).convert("RGBA")
    bg = _bg(im)
    cells = grid(im)
    frames: list[Image.Image] = []
    for box in cells:
        raw = chroma_cell(im, box, bg, strict=mode == "tile")
        if _bbox(raw) is None or _opaque_frac(raw) < 0.06:
            continue
        if mode == "tile":
            frames.append(fit_tile(raw, 64))
        else:
            frames.append(fit_feet(raw, 96))
    print("%s named cells %d (want %d)" % (src.name, len(frames), len(names)))
    save_named(frames, dest_dir, names)


def split_skinwalker(src: Path) -> None:
    im = Image.open(src).convert("RGBA")
    bg = _bg(im)
    cells = grid(im)
    raws: list[Image.Image] = []
    for box in cells:
        raw = chroma_cell(im, box, bg)
        if _bbox(raw) is None or _opaque_frac(raw) < 0.06:
            continue
        raws.append(fit_feet(raw, 96))
    print("skinwalker cells", len(raws))
    clips = {
        "dog": raws[0:4] if len(raws) >= 4 else raws,
        "crawl": raws[4:8] if len(raws) >= 8 else raws,
        "walk": raws[8:12] if len(raws) >= 12 else raws,
        "gape": raws[12:16] if len(raws) >= 16 else raws[-4:],
    }
    for name, fr in clips.items():
        save_clip(pingpong(fr, 6), OUT / "skinwalker" / name)


FATHER = {
    "idle": ("father-idle-stand.png", "feet"),
    "walk": ("father-walk.png", "feet"),
    "parkour_run": ("father-parkour-run.png", "feet"),
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
}

PUNK = {
    "idle": "punk-idle.png",
    "walk": "punk-walk-casual.png",
    "attack": "punk-attack.png",
    "hurt": "punk-hurt.png",
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


def main() -> None:
    if not ART.is_dir():
        raise SystemExit("missing art dir %s" % ART)
    if OUT.exists():
        for child in ("father", "punk", "dock", "skinwalker"):
            p = OUT / child
            if p.exists():
                shutil.rmtree(p)
    SHEETS.mkdir(parents=True, exist_ok=True)
    for clip, (name, anchor) in FATHER.items():
        src = copy_sheet(name)
        n = slice_who(src, OUT / "father" / clip, anchor)
        if n < 6:
            raise SystemExit("father/%s has %d frames" % (clip, n))
    for clip, name in PUNK.items():
        src = copy_sheet(name)
        n = slice_who(src, OUT / "punk" / clip, "feet")
        if n < 6:
            raise SystemExit("punk/%s has %d frames" % (clip, n))
    tiles = copy_sheet("dock-tiles.png")
    slice_named(tiles, OUT / "dock" / "tiles", TILE_NAMES, "tile")
    props = copy_sheet("dock-props.png")
    slice_named(props, OUT / "dock" / "props", PROP_NAMES, "prop")
    toys = copy_sheet("dock-toys.png")
    slice_named(toys, OUT / "dock" / "toys", TOY_NAMES, "prop")
    skin = copy_sheet("skinwalker-sheet.png")
    split_skinwalker(skin)
    print("done")


if __name__ == "__main__":
    main()
