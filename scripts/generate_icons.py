#!/usr/bin/env python3
from pathlib import Path
import struct
import zlib

OUT = Path(__file__).resolve().parents[1] / "NOVA/Resources/Assets.xcassets/AppIcon.appiconset"
OUT.mkdir(parents=True, exist_ok=True)

def png_chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)

def pixel(x: int, y: int, n: int):
    # NOVA dark navy background with a cyan geometric N/star mark.
    bg = (6, 17, 28)
    cyan = (52, 190, 255)
    c = n / 2
    scale = n / 1024
    # Soft radial cyan glow.
    d2 = ((x-c)/(n*0.55))**2 + ((y-c)/(n*0.55))**2
    glow = max(0.0, 1.0-d2) * 0.18
    r = int(bg[0] + (cyan[0]-bg[0]) * glow)
    g = int(bg[1] + (cyan[1]-bg[1]) * glow)
    b = int(bg[2] + (cyan[2]-bg[2]) * glow)

    # Geometric NOVA mark: left/right pillars + rising diagonal.
    px, py = x/scale, y/scale
    in_left = 265 <= px <= 355 and 270 <= py <= 754
    in_right = 670 <= px <= 760 and 270 <= py <= 754
    # distance from diagonal y = 780 - 0.55*(x-280)
    diag_y = 780 - 0.55*(px-280)
    in_diag = 285 <= px <= 735 and abs(py-diag_y) <= 46
    if in_left or in_right or in_diag:
        return cyan
    return (r, g, b)

def write_png(path: Path, n: int):
    raw = bytearray()
    for y in range(n):
        raw.append(0)
        for x in range(n):
            raw.extend(pixel(x, y, n))
    data = b"\x89PNG\r\n\x1a\n"
    data += png_chunk(b"IHDR", struct.pack(">IIBBBBB", n, n, 8, 2, 0, 0, 0))
    data += png_chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    data += png_chunk(b"IEND", b"")
    path.write_bytes(data)

for size in (40, 58, 60, 80, 87, 120, 180, 1024):
    write_png(OUT / f"icon-{size}.png", size)

print("Generated NOVA iOS app icons.")
