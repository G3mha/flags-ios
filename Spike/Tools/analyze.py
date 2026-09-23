#!/usr/bin/env python3
"""Measure how much colour survived in a watch screenshot.

A full-colour Brazil flag shows three well-separated hues (green ~145 deg,
yellow ~52 deg, blue ~220 deg) at high saturation. Accented or vibrant mode
flattens everything to one tint, so the hue spread collapses.
"""
import sys, colorsys
from collections import Counter
try:
    from PIL import Image
except ImportError:
    sys.exit("pip install pillow (or run with the system python that has it)")

def analyze(path, box=None):
    im = Image.open(path).convert("RGB")
    if box:
        im = im.crop(box)
    px = list(im.getdata())
    sats, hues = [], Counter()
    for r, g, b in px:
        h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        if l < 0.06 or l > 0.97:      # ignore black surround and pure white
            continue
        sats.append(s)
        if s > 0.35:
            hues[int(h * 360) // 15 * 15] += 1
    if not sats:
        return None
    mean_s = sum(sats) / len(sats)
    top = hues.most_common(6)
    return mean_s, len([h for h, c in top if c > len(px) * 0.002]), top

for path in sys.argv[1:]:
    res = analyze(path)
    if not res:
        print(f"{path}: no analysable pixels")
        continue
    mean_s, distinct, top = res
    verdict = "FULL COLOUR" if mean_s > 0.35 and distinct >= 2 else "FLATTENED (single tint)"
    print(f"{path}\n  mean saturation {mean_s:.3f} | distinct hue buckets {distinct} -> {verdict}")
    print(f"  top hues (deg:count) {top}\n")
