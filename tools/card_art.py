#!/usr/bin/env python3
"""Level-up card frames as pixel-art sprites, one per rarity, on the
640x360 grid (a texel is 2 design px):

    python3 tools/card_art.py  ->  assets/sprites/cards/*.png

story_<rarity>.png   150x220  the story card: a bevelled metal frame in the
                     rarity's metal (steel, jade, cobalt, amethyst, gold),
                     corner studs, a gem socket on top for the type emblem,
                     a sunk art window with its glow baked in, a ribbon name
                     plate, the rarity gems and a recessed rule panel
back_<rarity>.png    150x220  the same frame face down (lattice + crest)
surv_<rarity>.png    160x163  the survivor card, a different object: a
                     riveted steel ID badge with an enamel header in the
                     rarity colour, a lanyard slot, punched holes down the
                     sides, a square icon window and a hazard-striped foot
glow_story.png / glow_surv.png   soft stepped glow around each card's
                     silhouette (white; tinted and pulsed in the game)
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

from pixkit import mat

OUT = Path(__file__).resolve().parent.parent / "assets/sprites/cards"
METAL = {"common": "steel", "uncommon": "jade", "rare": "blue", "epic": "purple", "legendary": "gold"}
GEM = {"common": "white", "uncommon": "lime", "rare": "sky", "epic": "violet", "legendary": "yellow"}
RANK = {"common": 1, "uncommon": 2, "rare": 3, "epic": 4, "legendary": 5}
INK = (12, 10, 20, 255)
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def blend(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def dither(x, y, t):
    """True when the ordered-dither threshold at (x, y) is under t (0..1)."""
    return (BAYER[y % 4][x % 4] + 0.5) / 16.0 < t


class Canvas:
    def __init__(self, w, h):
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)
        self.px = self.im.load()
        self.w, self.h = w, h

    def rect(self, x0, y0, x1, y1, c):
        self.d.rectangle([x0, y0, x1, y1], fill=c)

    def bevel(self, x0, y0, x1, y1, r, t=1, sunk=False, cut=0):
        """Filled block with lit top/left and shaded bottom/right edges."""
        hi, lo = (r[4], r[3]) if not sunk else (r[0], r[1])
        sh, sh2 = (r[0], r[1]) if not sunk else (r[4], r[3])
        self.rect(x0, y0, x1, y1, r[2])
        for k in range(t):
            self.d.line([x0 + k, y1 - k, x0 + k, y0 + k, x1 - k, y0 + k], fill=hi if k == 0 else lo)
            self.d.line([x0 + k + 1, y1 - k, x1 - k, y1 - k, x1 - k, y0 + k + 1], fill=sh if k == 0 else sh2)
        if cut:
            for k in range(cut):
                for (cx, cy, dx, dy) in ((x0, y0, 1, 1), (x1, y0, -1, 1), (x0, y1, 1, -1), (x1, y1, -1, -1)):
                    for j in range(cut - k):
                        self.px[cx + dx * j, cy + dy * k] = (0, 0, 0, 0)

    def gradient_face(self, x0, y0, x1, y1, top, bottom, tint=None, tint_k=0.0):
        for y in range(y0, y1 + 1):
            t = (y - y0) / max(1, y1 - y0)
            for x in range(x0, x1 + 1):
                c = blend(top, bottom, t)
                if tint is not None and dither(x, y, tint_k * (1 - t)):
                    c = blend(c, tint, 0.18)
                self.px[x, y] = c

    def glow(self, cx, cy, rx, ry, col, strength=0.6):
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                if not (0 <= x < self.w and 0 <= y < self.h):
                    continue
                d = math.hypot((x - cx) / rx, (y - cy) / ry)
                if d < 1.0:
                    k = (1 - d) ** 1.6 * strength
                    if dither(x, y, k * 1.6):
                        self.px[x, y] = blend(self.px[x, y], col, min(0.55, k))

    def stud(self, cx, cy, r, gem):
        self.d.polygon([(cx, cy - 3), (cx + 3, cy), (cx, cy + 3), (cx - 3, cy)], fill=INK)
        self.d.polygon([(cx, cy - 2), (cx + 2, cy), (cx, cy + 2), (cx - 2, cy)], fill=r[3])
        self.px[cx, cy] = gem[4]
        self.px[cx - 1, cy] = gem[2]

    def save(self, name):
        self.im.save(OUT / name)


def story(rar, back=False):
    r = mat(METAL[rar])
    g = mat(GEM[rar])
    c = Canvas(150, 220)
    # Outer frame: 6 texels of bevelled metal with cut corners.
    c.bevel(0, 0, 149, 219, r, t=2, cut=3)
    c.d.rectangle([4, 4, 145, 215], outline=r[1])
    c.d.rectangle([5, 5, 144, 214], outline=INK)
    deep = blend(r[0], (8, 8, 16), 0.82)
    deeper = blend(r[0], (4, 4, 10), 0.92)
    c.gradient_face(6, 6, 143, 213, deep, deeper, tint=g[2], tint_k=0.35)
    # Engraved dots running round the frame.
    for x in range(8, 142, 4):
        c.px[x, 2] = r[1]
        c.px[x, 217] = r[1]
    for y in range(8, 212, 4):
        c.px[2, y] = r[1]
        c.px[147, y] = r[1]
    # Filigree brackets in the inner corners.
    for (x, y, dx, dy) in ((7, 7, 1, 1), (142, 7, -1, 1), (7, 212, 1, -1), (142, 212, -1, -1)):
        for k in range(12):
            c.px[x + dx * k, y] = r[3] if k % 5 else r[4]
            c.px[x, y + dy * k] = r[3] if k % 5 else r[4]
            c.px[x + dx * k, y + dy] = r[0]
            c.px[x + dx, y + dy * k] = r[0]
        c.px[x + dx * 12, y] = g[3]
        c.px[x, y + dy * 12] = g[3]
    for (x, y) in ((11, 11), (138, 11), (11, 208), (138, 208)):
        c.stud(x, y, r, g)
    if back:
        # Diamond lattice and the family crest in a socket.
        for y in range(10, 210, 10):
            for x in range(10 + (5 if (y // 10) % 2 else 0), 140, 10):
                c.px[x, y] = r[1]
                c.px[x + 1, y] = r[0]
        c.d.ellipse([45, 80, 105, 140], fill=r[1])
        c.d.ellipse([47, 82, 103, 138], fill=r[3])
        c.d.ellipse([51, 86, 99, 134], fill=INK)
        c.d.ellipse([53, 88, 97, 132], fill=deep)
        c.glow(75, 110, 22, 22, g[3], 0.7)
        # A shield crest.
        c.d.polygon([(66, 98), (84, 98), (84, 110), (75, 122), (66, 110)], fill=r[3])
        c.d.polygon([(68, 100), (82, 100), (82, 110), (75, 119), (68, 110)], fill=r[1])
        c.d.line([75, 100, 75, 118], fill=g[4])
        c.d.line([69, 106, 81, 106], fill=g[4])
        return c
    # Emblem socket at the top.
    c.d.rectangle([58, 0, 92, 6], fill=r[2])
    c.d.line([58, 0, 92, 0], fill=r[4])
    c.d.ellipse([61, 2, 89, 30], fill=r[1])
    c.d.ellipse([62, 3, 88, 29], fill=r[3])
    c.d.ellipse([64, 5, 86, 27], fill=INK)
    c.d.ellipse([65, 6, 85, 26], fill=blend(deep, g[1], 0.25))
    # Art window: sunk, with an inner shadow top-left and a lit lip
    # bottom-right, the glow pooled in the middle.
    c.rect(17, 30, 133, 100, r[3])
    c.rect(17, 30, 132, 99, r[0])
    c.rect(19, 32, 131, 98, INK)
    c.gradient_face(20, 33, 130, 97, blend(deep, g[0], 0.25), deeper)
    c.glow(75, 66, 52, 30, g[2], 0.55)
    c.d.line([20, 33, 130, 33], fill=(0, 0, 0, 255))
    c.d.line([20, 33, 20, 97], fill=(0, 0, 0, 255))
    # Ribbon name plate with folded tails.
    for (x0, x1, s) in ((2, 13, 1), (137, 148, -1)):
        c.d.polygon([(x0, 106), (x1, 104), (x1, 122), (x0, 124), (x0 + 4 * s if s > 0 else x1 - 4, 115)], fill=r[0])
    c.bevel(11, 102, 139, 121, r, t=1)
    c.d.line([12, 120, 138, 120], fill=r[0])
    c.d.rectangle([13, 104, 137, 119], outline=r[1])
    # Rarity gems (as many as the rarity's rank) in sockets.
    n = RANK[rar]
    for i in range(5):
        x = 51 + i * 11
        c.d.rectangle([x, 129, x + 7, 134], fill=INK)
        if i < n:
            c.d.rectangle([x + 1, 130, x + 6, 133], fill=g[2])
            c.d.line([x + 1, 130, x + 6, 130], fill=g[4])
            c.px[x + 2, 131] = (255, 255, 250, 255)
        else:
            c.d.rectangle([x + 1, 130, x + 6, 133], fill=(32, 32, 40, 255))
    # Recessed rule panel.
    c.rect(13, 138, 137, 207, blend(deeper, (0, 0, 0), 0.3))
    c.d.line([13, 138, 137, 138], fill=(0, 0, 0, 255))
    c.d.line([13, 207, 137, 207], fill=r[1])
    c.d.line([20, 165, 130, 165], fill=r[0])
    # Foot plaque.
    c.d.rectangle([62, 209, 88, 216], fill=r[1])
    c.d.rectangle([63, 210, 87, 215], fill=r[3])
    c.px[75, 212] = g[4]
    c.px[74, 212] = g[2]
    c.px[76, 212] = g[2]
    return c


def surv(rar):
    s = mat("slate")
    e = mat(METAL[rar] if rar != "common" else "grey")
    g = mat(GEM[rar])
    c = Canvas(160, 163)
    # Steel badge plate.
    c.bevel(0, 0, 159, 162, s, t=2, cut=4)
    c.d.rectangle([3, 3, 156, 159], outline=INK)
    face = (16, 18, 26, 255)
    c.gradient_face(4, 4, 155, 158, (22, 25, 36, 255), (10, 11, 17, 255), tint=e[2], tint_k=0.2)
    # Enamel header band in the rarity colour with a diagonal shine.
    c.bevel(4, 4, 155, 22, e, t=1)
    for x in range(10, 150, 26):
        c.d.polygon([(x, 5), (x + 6, 5), (x - 2, 21), (x - 8, 21)], fill=e[3])
    c.d.line([4, 23, 155, 23], fill=INK)
    # Lanyard slot.
    c.d.rounded_rectangle([66, 8, 94, 13], radius=2, fill=INK)
    c.d.line([67, 13, 93, 13], fill=e[4])
    # Punched holes down both sides.
    for y in range(32, 140, 12):
        for x in (8, 150):
            c.rect(x, y, x + 1, y + 3, (0, 0, 0, 255))
            c.px[x, y + 4] = s[3]
            c.px[x + 1, y + 4] = s[3]
    # Rivets.
    for (x, y) in ((8, 28), (151, 28), (8, 146), (151, 146)):
        c.d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=INK)
        c.d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=s[3])
        c.px[x - 1, y - 1] = s[4]
    # Square icon window.
    c.rect(53, 26, 107, 80, s[4])
    c.rect(53, 26, 106, 79, s[0])
    c.rect(55, 28, 105, 78, INK)
    c.gradient_face(56, 29, 104, 77, blend(face, e[0], 0.3), face)
    c.glow(80, 53, 26, 26, e[2], 0.6)
    # Corner brackets on the window.
    for (x, y, dx, dy) in ((51, 24, 1, 1), (109, 24, -1, 1), (51, 82, 1, -1), (109, 82, -1, -1)):
        c.d.line([x, y, x + 6 * dx, y], fill=e[3])
        c.d.line([x, y, x, y + 6 * dy], fill=e[3])
    # Text bed.
    c.rect(12, 86, 147, 144, (8, 9, 14, 255))
    c.d.line([12, 86, 147, 86], fill=(0, 0, 0, 255))
    c.d.line([12, 144, 147, 144], fill=s[1])
    # Hazard-striped foot.
    for x in range(4, 156):
        for y in range(148, 158):
            c.px[x, y] = e[2] if ((x + y) // 4) % 2 == 0 else (20, 18, 24, 255)
    c.d.line([4, 147, 155, 147], fill=INK)
    return c


def glow_mask(w, h, cut, margin=8):
    im = Image.new("RGBA", (w + margin * 2, h + margin * 2), (0, 0, 0, 0))
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            # Distance to the card rectangle (cut corners rounded off).
            dx = max(margin - x, 0, x - (w + margin - 1))
            dy = max(margin - y, 0, y - (h + margin - 1))
            d = math.hypot(dx, dy)
            if 0 < d <= margin:
                k = 1 - d / margin
                a = 200 if k > 0.66 else (120 if k > 0.33 else 50)
                if dither(x, y, k * 1.4) or k > 0.5:
                    px[x, y] = (255, 255, 255, a)
    return im


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for rar in METAL:
        story(rar).save(f"story_{rar}.png")
        story(rar, back=True).save(f"back_{rar}.png")
        surv(rar).save(f"surv_{rar}.png")
    glow_mask(150, 220, 3).save(OUT / "glow_story.png")
    glow_mask(160, 163, 4).save(OUT / "glow_surv.png")
    print("cards ok")


if __name__ == "__main__":
    main()
