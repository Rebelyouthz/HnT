#!/usr/bin/env python3
"""Pixel-art kit for icons: draw flat shapes with a *material*, and the kit
does the rest the way a pixel artist would:

  * every material is a 5-step hue-shifted ramp (shadows lean blue/purple,
    lights lean yellow), so nothing is just "darker" or "lighter";
  * each shape is a *part*: its top/left rim catches the light, its
    bottom/right rim falls into shade, and round parts get a sphere ramp;
  * a selective outline: the outline takes the darkest colour of the part it
    hugs, so a gold coin gets a brown outline and steel a navy one;
  * a hard specular glint where the light hits first.

    from pixkit import Icon
    ic = Icon(32)
    ic.ellipse(4, 4, 27, 27, "gold", round_=True)
    ic.save("coin.png")
"""
from __future__ import annotations

import colorsys
import math

from PIL import Image, ImageDraw

BASE = {
    "steel": (126, 134, 150), "gun": (88, 94, 110), "black": (52, 50, 62),
    "gold": (232, 176, 52), "brass": (196, 146, 60), "copper": (196, 104, 58),
    "red": (204, 52, 52), "blood": (150, 24, 36), "orange": (238, 128, 40),
    "yellow": (246, 214, 70), "green": (72, 176, 84), "lime": (150, 220, 70),
    "teal": (44, 170, 160), "blue": (64, 120, 220), "sky": (110, 190, 240),
    "cyan": (90, 220, 240), "navy": (40, 52, 110), "purple": (140, 76, 196),
    "pink": (236, 110, 170), "white": (226, 228, 232), "paper": (232, 222, 196),
    "skin": (232, 170, 124), "brown": (134, 86, 50), "wood": (164, 108, 60),
    "leather": (110, 66, 40), "denim": (66, 96, 160), "grey": (128, 128, 136),
    "fire": (250, 150, 40), "glass": (160, 220, 240), "ghost": (200, 210, 230),
    "olive": (120, 130, 60), "cream": (240, 226, 170), "mint": (130, 230, 180),
    "violet": (180, 110, 240), "slate": (90, 100, 120), "rust": (160, 80, 40),
    "hivis": (210, 240, 40), "jade": (60, 190, 130), "ink": (30, 28, 40),
}


def _ramp(rgb):
    """Five steps: 0 deep shadow .. 2 base .. 4 highlight, hue-shifted."""
    r, g, b = (v / 255.0 for v in rgb)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    out = []
    for k in (-2, -1, 0, 1, 2):
        # Shadows rotate toward blue/purple, lights toward yellow.
        hs = h
        if k < 0:
            target = 0.7  # blue-violet
            hs = h + (_hue_toward(h, target)) * 0.06 * -k
            ll = l * (1.0 - 0.24 * -k)
            ss = min(1.0, s * (1.0 + 0.1 * -k))
        elif k > 0:
            target = 0.14  # warm yellow
            hs = h + (_hue_toward(h, target)) * 0.05 * k
            ll = l + (1.0 - l) * 0.24 * k
            ss = s * (1.0 - 0.08 * k)
        else:
            ll, ss = l, s
        rr, gg, bb = colorsys.hls_to_rgb(hs % 1.0, max(0.0, min(1.0, ll)), max(0.0, min(1.0, ss)))
        out.append((int(rr * 255), int(gg * 255), int(bb * 255), 255))
    return out


def _hue_toward(h, target):
    d = (target - h + 0.5) % 1.0 - 0.5
    return 1.0 if d > 0 else -1.0


RAMPS = {k: _ramp(v) for k, v in BASE.items()}


def mat(name_or_rgb):
    if isinstance(name_or_rgb, str):
        return RAMPS[name_or_rgb]
    return _ramp(name_or_rgb)


class Icon:
    def __init__(self, size=32):
        self.n = size
        self.mat = [[None] * size for _ in range(size)]   # ramp per pixel
        self.part = [[0] * size for _ in range(size)]
        self.style = {}                                  # part -> dict
        self.fixed = {}                                  # (x, y) -> rgba
        self._next = 1
        self.glints = []

    # --- shapes --------------------------------------------------------
    def _mask(self):
        m = Image.new("L", (self.n, self.n), 0)
        return m, ImageDraw.Draw(m)

    def _apply(self, m, material, round_=False, flat=False, light=(0.3, 0.25), tone=0):
        ramp = mat(material)
        pid = self._next
        self._next += 1
        self.style[pid] = {"round": round_, "flat": flat, "light": light, "tone": tone}
        px = m.load()
        hit = False
        for y in range(self.n):
            for x in range(self.n):
                if px[x, y] > 0:
                    self.mat[y][x] = ramp
                    self.part[y][x] = pid
                    self.fixed.pop((x, y), None)
                    hit = True
        return pid if hit else 0

    def rect(self, x0, y0, x1, y1, material, **kw):
        m, d = self._mask()
        x0, x1 = min(x0, x1), max(x0, x1)
        y0, y1 = min(y0, y1), max(y0, y1)
        d.rectangle([x0, y0, x1, y1], fill=255)
        return self._apply(m, material, **kw)

    def ellipse(self, x0, y0, x1, y1, material, **kw):
        m, d = self._mask()
        x0, x1 = min(x0, x1), max(x0, x1)
        y0, y1 = min(y0, y1), max(y0, y1)
        d.ellipse([x0, y0, x1, y1], fill=255)
        return self._apply(m, material, **kw)

    def poly(self, pts, material, **kw):
        m, d = self._mask()
        d.polygon([tuple(p) for p in pts], fill=255)
        return self._apply(m, material, **kw)

    def line(self, pts, material, width=1, **kw):
        m, d = self._mask()
        d.line([tuple(p) for p in pts], fill=255, width=width)
        if width > 2:
            for p in pts:
                r = width / 2.0 - 0.5
                d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=255)
        return self._apply(m, material, **kw)

    def arc(self, box, a0, a1, material, width=1, **kw):
        m, d = self._mask()
        d.arc(box, a0, a1, fill=255, width=width)
        return self._apply(m, material, **kw)

    def ring(self, x0, y0, x1, y1, width, material, **kw):
        m, d = self._mask()
        d.ellipse([x0, y0, x1, y1], fill=255)
        d.ellipse([x0 + width, y0 + width, x1 - width, y1 - width], fill=0)
        return self._apply(m, material, **kw)

    def pixels(self, pts, material, step=2):
        """Single pixels in one tone of a ramp (step 0..4); not shaded."""
        ramp = mat(material)
        for (x, y) in pts:
            if 0 <= x < self.n and 0 <= y < self.n:
                self.fixed[(x, y)] = ramp[step]

    def px(self, x, y, rgba):
        if 0 <= x < self.n and 0 <= y < self.n:
            self.fixed[(x, y)] = rgba if len(rgba) == 4 else tuple(rgba) + (255,)

    def erase(self, pts):
        for (x, y) in pts:
            if 0 <= x < self.n and 0 <= y < self.n:
                self.mat[y][x] = None
                self.part[y][x] = 0
                self.fixed.pop((x, y), None)

    def erase_rect(self, x0, y0, x1, y1):
        self.erase([(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)])

    def glint(self, x, y, big=False):
        self.glints.append((x, y, big))

    # --- render --------------------------------------------------------
    def render(self, outline=True):
        n = self.n
        im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
        o = im.load()
        # Part bounding boxes for round shading.
        boxes = {}
        for y in range(n):
            for x in range(n):
                p = self.part[y][x]
                if p:
                    b = boxes.get(p)
                    boxes[p] = (min(b[0], x), min(b[1], y), max(b[2], x), max(b[3], y)) if b else (x, y, x, y)

        def same(x, y, p):
            return 0 <= x < n and 0 <= y < n and self.part[y][x] == p

        for y in range(n):
            for x in range(n):
                ramp = self.mat[y][x]
                if ramp is None:
                    continue
                p = self.part[y][x]
                st = self.style[p]
                if st["flat"]:
                    k = 2 + st["tone"]
                elif st["round"]:
                    bx = boxes[p]
                    cx = bx[0] + (bx[2] - bx[0]) * st["light"][0]
                    cy = bx[1] + (bx[3] - bx[1]) * st["light"][1]
                    rad = max(2.0, max(bx[2] - bx[0], bx[3] - bx[1]) * 0.95)
                    dd = math.hypot(x - cx, y - cy) / rad
                    k = 4 if dd < 0.09 else 3 if dd < 0.3 else 2 if dd < 0.6 else 1
                    if not same(x + 1, y, p) or not same(x, y + 1, p):
                        k = min(k, 1)
                    if not same(x + 1, y + 1, p) and not same(x, y + 1, p):
                        k = 0 if dd > 0.6 else k
                else:
                    k = 2 + st["tone"]
                    up = not same(x, y - 1, p)
                    left = not same(x - 1, y, p)
                    down = not same(x, y + 1, p)
                    right = not same(x + 1, y, p)
                    if up or left:
                        k = 3 + (1 if up and left else 0)
                    if down or right:
                        k = 1 if not (down and right) else 0
                    if (up or left) and (down or right):
                        k = 2
                k = max(0, min(4, k))
                o[x, y] = ramp[k]
        for (x, y), c in self.fixed.items():
            o[x, y] = c
        for (x, y, big) in self.glints:
            if 0 <= x < n and 0 <= y < n and o[x, y][3]:
                o[x, y] = (255, 255, 246, 255)
                if big:
                    for dx, dy in ((1, 0), (0, 1)):
                        if 0 <= x + dx < n and 0 <= y + dy < n and o[x + dx, y + dy][3]:
                            r, g, b, _ = o[x + dx, y + dy]
                            o[x + dx, y + dy] = ((r + 255) // 2, (g + 255) // 2, (b + 246) // 2, 255)
        if outline:
            im = self._outline(im)
        return im

    def _outline(self, im):
        n = self.n
        a = im.load()
        out = im.copy()
        o = out.load()
        for y in range(n):
            for x in range(n):
                if a[x, y][3]:
                    continue
                best = None
                for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < n and 0 <= ny < n and a[nx, ny][3]:
                        ramp = self.mat[ny][nx]
                        c = ramp[0] if ramp else a[nx, ny]
                        best = c if best is None or sum(c[:3]) < sum(best[:3]) else best
                if best is not None:
                    # Selective outline: the part's own deepest tone, pushed
                    # toward ink so it always reads against any background.
                    o[x, y] = (int(best[0] * 0.42 + 8), int(best[1] * 0.38 + 6), int(best[2] * 0.45 + 14), 255)
        return out

    def save(self, path, outline=True):
        self.render(outline).save(path)
        return path


def sheet(paths, out, scale=4, cols=12, bg=(22, 24, 34)):
    """Contact sheet to eyeball a batch."""
    ims = [Image.open(p).convert("RGBA") for p in paths]
    if not ims:
        return
    s = ims[0].size[0]
    cell = s * scale + 8
    rows = (len(ims) + cols - 1) // cols
    sh = Image.new("RGBA", (cols * cell, rows * cell), bg + (255,))
    for i, im in enumerate(ims):
        big = im.resize((im.size[0] * scale, im.size[1] * scale), Image.NEAREST)
        sh.alpha_composite(big, ((i % cols) * cell + 4, (i // cols) * cell + 4))
    sh.save(out)
