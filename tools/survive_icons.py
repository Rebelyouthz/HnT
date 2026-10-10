#!/usr/bin/env python3
"""Icons for the new coping-hour abilities, traits and ultimates, drawn in
the same 32 px house style as tools/gun_art.py, saved 2x (64 px) next to the
old ones in assets/sprites/survive/."""
from pathlib import Path
from PIL import Image
from gun_art import Pen, shade

OUT = Path(__file__).resolve().parent.parent / "assets/sprites/survive"
RED = (210, 50, 44, 255)
YEL = (240, 200, 60, 255)
BLU = (70, 140, 230, 255)
GRN = (70, 190, 90, 255)
WHT = (235, 232, 222, 255)
STEEL = (130, 136, 148, 255)
BRN = (120, 80, 46, 255)
PUR = (150, 80, 200, 255)


def cart():
    p = Pen(32, 32)
    p.box(5, 9, 25, 19, STEEL)
    for x in range(7, 25, 4):
        p.d.line([x, 10, x, 18], fill=shade(STEEL, 0.6))
    p.d.line([3, 6, 6, 9], fill=STEEL)
    p.d.line([6, 20, 24, 20], fill=shade(STEEL, 0.7))
    p.d.ellipse([7, 22, 11, 26], fill=(30, 30, 34, 255))
    p.d.ellipse([19, 22, 23, 26], fill=(30, 30, 34, 255))
    return p


def bag():
    p = Pen(32, 32)
    p.poly([(9, 12), (23, 12), (26, 26), (6, 26)], (40, 44, 50, 255))
    p.poly([(12, 8), (20, 8), (23, 12), (9, 12)], (60, 64, 72, 255))
    p.d.line([16, 2, 16, 8], fill=YEL)
    p.d.arc([2, 0, 30, 30], 200, 340, fill=YEL)
    p.px(13, 18, (90, 96, 106, 255))
    return p


def hydrant():
    p = Pen(32, 32)
    p.box(11, 10, 21, 27, RED)
    p.box(9, 14, 23, 17, shade(RED, 0.8))
    p.poly([(11, 10), (21, 10), (19, 6), (13, 6)], shade(RED, 1.2))
    p.box(14, 3, 18, 6, STEEL)
    for i in range(4):
        p.d.line([23, 15, 30, 9 + i * 3], fill=BLU)
    return p


def mail():
    p = Pen(32, 32)
    p.box(5, 11, 27, 25, (190, 150, 100, 255))
    p.d.line([5, 11, 16, 19], fill=shade((190, 150, 100, 255), 0.6))
    p.d.line([27, 11, 16, 19], fill=shade((190, 150, 100, 255), 0.6))
    p.d.line([22, 10, 26, 3], fill=WHT)
    p.px(26, 2, YEL)
    p.px(27, 3, RED)
    return p


def sprinkler():
    p = Pen(32, 32)
    p.d.ellipse([12, 12, 20, 20], fill=STEEL)
    for i in range(8):
        import math
        a = i * math.pi / 4
        x, y = 16 + math.cos(a) * 13, 16 + math.sin(a) * 13
        p.d.line([16 + math.cos(a) * 6, 16 + math.sin(a) * 6, x, y], fill=WHT)
    return p


def audit():
    p = Pen(32, 32)
    p.d.ellipse([5, 5, 21, 21], outline=STEEL, width=3)
    p.d.ellipse([8, 8, 18, 18], fill=(170, 210, 240, 255))
    p.d.line([19, 19, 27, 27], fill=BRN, width=4)
    p.d.line([10, 12, 16, 12], fill=RED)
    return p


def gravy():
    p = Pen(32, 32)
    p.poly([(5, 16), (24, 16), (20, 24), (9, 24)], WHT)
    p.poly([(24, 16), (29, 13), (28, 15), (24, 18)], WHT)
    p.d.ellipse([7, 13, 22, 18], fill=(130, 80, 40, 255))
    p.d.line([10, 9, 12, 5], fill=(200, 200, 200, 200))
    p.d.line([15, 9, 17, 5], fill=(200, 200, 200, 200))
    return p


def skull():
    p = Pen(32, 32)
    p.d.ellipse([7, 4, 25, 21], fill=WHT)
    p.box(11, 18, 21, 25, WHT, False)
    p.d.ellipse([10, 10, 14, 15], fill=(20, 10, 30, 255))
    p.d.ellipse([18, 10, 22, 15], fill=(20, 10, 30, 255))
    for x in (13, 16, 19):
        p.d.line([x, 21, x, 25], fill=(60, 50, 70, 255))
    return p


def thorns():
    p = Pen(32, 32)
    p.d.ellipse([9, 9, 23, 23], fill=GRN)
    for (a, b, c) in [((16, 1), (13, 10), (19, 10)), ((16, 31), (13, 22), (19, 22)), ((1, 16), (10, 13), (10, 19)), ((31, 16), (22, 13), (22, 19))]:
        p.poly([a, b, c], shade(GRN, 0.7))
    return p


def clover():
    p = Pen(32, 32)
    for (x, y) in [(10, 6), (17, 6), (10, 13), (17, 13)]:
        p.d.ellipse([x, y, x + 8, y + 8], fill=GRN)
    p.d.line([16, 20, 20, 29], fill=shade(GRN, 0.7), width=2)
    return p


def fang():
    p = Pen(32, 32)
    p.poly([(16, 3), (25, 17), (16, 28), (7, 17)], RED)
    p.poly([(16, 3), (16, 28), (7, 17)], shade(RED, 1.3))
    p.px(13, 12, WHT)
    return p


def evolve():
    p = Pen(32, 32)
    pts = []
    import math
    for i in range(10):
        r = 14 if i % 2 == 0 else 6
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((16 + math.cos(a) * r, 16 + math.sin(a) * r))
    p.poly(pts, YEL)
    p.d.line([16, 8, 16, 20], fill=WHT)
    return p


def crash():
    p = Pen(32, 32)
    import math
    pts = []
    for i in range(14):
        r = 14 if i % 2 == 0 else 7
        a = i * math.pi / 7
        pts.append((16 + math.cos(a) * r, 16 + math.sin(a) * r))
    p.poly(pts, (255, 140, 40, 255))
    p.d.ellipse([11, 11, 21, 21], fill=YEL)
    return p


def dome():
    p = Pen(32, 32)
    p.d.pieslice([3, 6, 29, 32], 180, 360, fill=(90, 170, 240, 160))
    p.d.arc([3, 6, 29, 32], 180, 360, fill=WHT, width=2)
    p.box(3, 19, 29, 21, STEEL)
    return p


def tag():
    p = Pen(32, 32)
    p.poly([(4, 14), (14, 4), (28, 4), (28, 18), (18, 28)], RED)
    p.d.ellipse([20, 8, 24, 12], fill=(20, 20, 24, 255))
    p.d.text((9, 13), "%", fill=WHT)
    return p


def main():
    for name, fn in [("cart", cart), ("bag", bag), ("hydrant", hydrant), ("mailbomb", mail), ("sprinkler", sprinkler), ("audit", audit), ("gravy", gravy), ("t_curse", skull), ("t_thorns", thorns), ("t_luck", clover), ("t_vamp", fang), ("evolve", evolve), ("u_crash", crash), ("u_dome", dome), ("u_friday", tag)]:
        pen = fn()
        pen.outline()
        pen.im.resize((64, 64), Image.NEAREST).save(OUT / f"{name}.png")
    print("ok")


if __name__ == "__main__":
    main()
