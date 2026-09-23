#!/usr/bin/env python3
"""Slice generated sprite sheets into Godot PNG frames. Magenta/maroon chroma."""
from __future__ import annotations

import os
import shutil
import sys
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
    hot_magenta = r > 170 and g < 130 and b > 100 and r > g + 30
    if hot_magenta:
        return True
    if strict:
        return False
    magenta = r > 100 and b > 80 and g < 100 and (r > g + 25) and (b > g + 10)
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
    w, h = im.size
    if w / max(h, 1) > 1.45:
        rows_b, cols_b = _equal(w, h, 4, 3)
        cells = [(x0, y0, x1, y1) for y0, y1 in rows_b for x0, x1 in cols_b]
    else:
        cells = grid(im)
    frames: list[Image.Image] = []
    forced = w / max(h, 1) > 1.45
    for box in cells:
        raw = chroma_cell(im, box, bg, strict=anchor == "tile")
        if _bbox(raw) is None or _opaque_frac(raw) < (0.01 if forced else 0.06):
            if not forced:
                continue
            frames.append(Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0)))
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


def slice_named(
    src: Path,
    dest_dir: Path,
    names: list[str],
    mode: str,
    cols: int = 0,
    rows: int = 0,
) -> None:
    im = Image.open(src).convert("RGBA")
    bg = _bg(im)
    if cols >= 2 and rows >= 2:
        rows_b, cols_b = _equal(im.size[0], im.size[1], cols, rows)
        cells = [(x0, y0, x1, y1) for y0, y1 in rows_b for x0, x1 in cols_b]
    else:
        cells = grid(im)
    frames: list[Image.Image] = []
    forced = cols >= 2 and rows >= 2
    for box in cells:
        if mode == "icon":
            x0, y0, x1, y1 = box
            pad = 2
            raw = im.crop((x0 + pad, y0 + pad, max(x0 + pad + 1, x1 - pad), max(y0 + pad + 1, y1 - pad))).convert("RGBA")
        else:
            raw = chroma_cell(im, box, bg, strict=mode == "tile")
        empty = _bbox(raw) is None or _opaque_frac(raw) < (0.02 if forced else 0.06)
        if empty and not forced:
            continue
        if empty:
            size = 64 if mode in ("tile", "icon") else 96
            frames.append(Image.new("RGBA", (size, size), (0, 0, 0, 0)))
        elif mode in ("tile", "icon"):
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


def _wipe(name: str) -> None:
    p = OUT / name
    if p.exists():
        shutil.rmtree(p)


def slice_father() -> None:
    for clip, (name, anchor) in FATHER.items():
        src = copy_sheet(name)
        n = slice_who(src, OUT / "father" / clip, anchor)
        if n < 6:
            raise SystemExit("father/%s has %d frames" % (clip, n))


def slice_punk() -> None:
    for clip, name in PUNK.items():
        src = copy_sheet(name)
        n = slice_who(src, OUT / "punk" / clip, "feet")
        if n < 6:
            raise SystemExit("punk/%s has %d frames" % (clip, n))


def slice_dock() -> None:
    tiles = copy_sheet("dock-tiles.png")
    slice_named(tiles, OUT / "dock" / "tiles", TILE_NAMES, "tile")
    props = copy_sheet("dock-props.png")
    slice_named(props, OUT / "dock" / "props", PROP_NAMES, "prop")
    toys = copy_sheet("dock-toys.png")
    slice_named(toys, OUT / "dock" / "toys", TOY_NAMES, "prop")


def slice_son() -> None:
    for clip, (name, anchor) in SON.items():
        src = copy_sheet(name)
        n = slice_who(src, OUT / "son" / clip, anchor)
        if n < 6:
            raise SystemExit("son/%s has %d frames" % (clip, n))


def slice_lot() -> None:
    tiles = copy_sheet("lot-tiles.png")
    slice_named(tiles, OUT / "lot" / "tiles", LOT_TILE_NAMES, "tile", 4, 3)
    props = copy_sheet("lot-props.png")
    slice_named(props, OUT / "lot" / "props", LOT_PROP_NAMES, "prop", 4, 3)


def slice_hub() -> None:
    src = copy_sheet("clinic-hub-icons.png")
    slice_named(src, OUT / "hub", HUB_NAMES, "icon", 4, 2)


def slice_hub2() -> None:
    src = copy_sheet("clinic-hub-gate-icons.png")
    slice_named(src, OUT / "hub", HUB2_NAMES, "icon", 4, 2)


def slice_cop() -> None:
    for clip, name in COP.items():
        src = copy_sheet(name)
        n = slice_who(src, OUT / "cop" / clip, "feet")
        if n < 6:
            raise SystemExit("cop/%s has %d frames" % (clip, n))


def slice_lamp() -> None:
    src = copy_sheet("lamp-flicker-sheet.png")
    n = slice_who(src, OUT / "lamp" / "idle", "cell")
    if n < 6:
        raise SystemExit("lamp/idle has %d frames" % n)


def slice_bystander() -> None:
    src = copy_sheet("bystander-idle-sheet.png")
    n = slice_who(src, OUT / "bystander" / "idle", "feet")
    if n < 6:
        raise SystemExit("bystander/idle has %d frames" % n)


def main() -> None:
    if not ART.is_dir():
        raise SystemExit("missing art dir %s" % ART)
    args = [a.lower() for a in sys.argv[1:]] or ["all"]
    unknown = [a for a in args if a not in ("all", "father", "punk", "dock", "skinwalker", "son", "lot", "hub", "hub2", "cop", "lamp", "bystander", "slides")]
    if unknown:
        raise SystemExit("unknown who: %s" % " ".join(unknown))
    if "all" in args:
        args = ["father", "punk", "dock", "skinwalker", "son", "lot", "hub", "hub2", "cop", "lamp", "bystander"]
        for child in ["father", "punk", "dock", "skinwalker", "son", "lot", "hub", "cop", "lamp", "bystander"]:
            _wipe(child)
    else:
        for child in args:
            if child in ("hub2", "slides"):
                continue
            _wipe(child)
    SHEETS.mkdir(parents=True, exist_ok=True)
    if "father" in args:
        slice_father()
    if "punk" in args:
        slice_punk()
    if "dock" in args:
        slice_dock()
    if "skinwalker" in args:
        skin = copy_sheet("skinwalker-sheet.png")
        split_skinwalker(skin)
    if "son" in args:
        slice_son()
    if "lot" in args:
        slice_lot()
    if "hub" in args:
        slice_hub()
    if "hub2" in args:
        slice_hub2()
    if "cop" in args:
        slice_cop()
    if "lamp" in args:
        slice_lamp()
    if "bystander" in args:
        slice_bystander()
    if "slides" in args:
        for who, mapping in (("father", FATHER), ("son", SON)):
            for clip in ("slide", "dive"):
                name, anchor = mapping[clip]
                src = copy_sheet(name)
                n = slice_who(src, OUT / who / clip, anchor)
                if n < 6:
                    raise SystemExit("%s/%s has %d frames" % (who, clip, n))
    print("done")


if __name__ == "__main__":
    main()
