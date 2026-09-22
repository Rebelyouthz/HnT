#!/usr/bin/env python3
"""Write FnS ICO + PNG: two blocks (brick Father, lemon Son), readable at 32px."""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "icon"

BG = (12, 13, 18, 255)
GOLD = (201, 162, 39, 255)
BRICK = (181, 74, 58, 255)
LEMON = (230, 216, 74, 255)
CREAM = (242, 234, 216, 255)


def _chunk(tag: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)


def png_rgba(w: int, h: int, pixels: bytes) -> bytes:
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    raw = b""
    stride = w * 4
    for y in range(h):
        raw += b"\x00" + pixels[y * stride : (y + 1) * stride]
    return (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", ihdr)
        + _chunk(b"IDAT", zlib.compress(raw, 9))
        + _chunk(b"IEND", b"")
    )


def _fill(buf: bytearray, w: int, x0: int, y0: int, x1: int, y1: int, c: tuple[int, int, int, int]) -> None:
    x0, x1 = max(0, x0), min(w, x1)
    y0, y1 = max(0, y0), min(w, y1)
    r, g, b, a = c
    for y in range(y0, y1):
        row = y * w * 4
        for x in range(x0, x1):
            i = row + x * 4
            buf[i : i + 4] = bytes((r, g, b, a))


def draw(size: int) -> bytes:
    buf = bytearray(size * size * 4)
    _fill(buf, size, 0, 0, size, size, BG)
    border = max(1, size // 16)
    inset = max(1, size // 32)
    # Gold frame
    _fill(buf, size, inset, inset, size - inset, size - inset, GOLD)
    inner = inset + border
    _fill(buf, size, inner, inner, size - inner, size - inner, BG)
    pad = inner + max(1, size // 16)
    box = size - pad * 2
    gap = max(1, size // 16)
    # Father: taller brick left. Son: shorter lemon right. Bottom-aligned.
    left_w = (box - gap) * 5 // 9
    right_w = box - gap - left_w
    left_h = box * 7 // 8
    right_h = box * 5 // 8
    lx0, ly1 = pad, pad + box
    lx1, ly0 = lx0 + left_w, ly1 - left_h
    rx0, ry1 = lx1 + gap, pad + box
    rx1, ry0 = rx0 + right_w, ry1 - right_h
    _fill(buf, size, lx0, ly0, lx1, ly1, BRICK)
    _fill(buf, size, rx0, ry0, rx1, ry1, LEMON)
    # Tiny cream ticks so 32px still reads as two people, not a flag.
    tick = max(1, size // 32)
    _fill(buf, size, lx0 + tick * 2, ly0 + tick * 2, lx0 + tick * 5, ly0 + tick * 3, CREAM)
    _fill(buf, size, rx0 + tick * 2, ry0 + tick * 2, rx0 + tick * 4, ry0 + tick * 3, CREAM)
    return bytes(buf)


def ico(pngs: list[tuple[int, bytes]]) -> bytes:
    count = len(pngs)
    offset = 6 + 16 * count
    entries = b""
    blobs = b""
    for size, blob in pngs:
        w = 0 if size >= 256 else size
        entries += struct.pack("<BBBBHHII", w, w, 0, 0, 1, 32, len(blob), offset)
        blobs += blob
        offset += len(blob)
    return struct.pack("<HHH", 0, 1, count) + entries + blobs


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sizes = (16, 32, 48, 64, 128, 256)
    pngs: list[tuple[int, bytes]] = []
    for s in sizes:
        blob = png_rgba(s, s, draw(s))
        pngs.append((s, blob))
        if s == 256:
            (OUT_DIR / "fns.png").write_bytes(blob)
        if s == 32:
            (OUT_DIR / "fns-32.png").write_bytes(blob)
    (OUT_DIR / "fns.ico").write_bytes(ico(pngs))
    print("wrote", OUT_DIR / "fns.ico")


if __name__ == "__main__":
    main()
