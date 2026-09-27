# Builds the App Store screenshots from plain simulator captures.
#
# Put the plain captures in Tools/screenshot-sources and run this; the framed
# versions land in fastlane/screenshots/en-US, where deliver expects them.
# Capture on a 6.9" device (iPhone 17 Pro Max, 1320x2868) -- Apple scales that
# down for every smaller size, so one set covers them all.
#
#   xcrun simctl io <udid> screenshot Tools/screenshot-sources/01-browse.png
#
# Usage: python3 Tools/frame-screenshots.py

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Sources live outside fastlane/screenshots so deliver does not upload them
# alongside the finished ones.
S = os.path.join(ROOT, "Tools", "screenshot-sources")
OUT = os.path.join(ROOT, "fastlane", "screenshots", "en-US")
os.makedirs(OUT, exist_ok=True)

W, H = 1320, 2868

def font(size, weight):
    f = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)
    try: f.set_variation_by_name(weight)
    except Exception: pass
    return f

def background():
    # Near-black with a green cast, warming slightly toward the bottom where
    # the glow sits. Dark so the app's white UI reads as a lit panel.
    bg = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(bg)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=(int(6 + 10 * t), int(12 + 18 * t), int(9 + 13 * t)))
    # A soft green bloom behind the device, so the frame is not floating on flat black.
    glow = Image.new("RGB", (W, H), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-260, 620, W + 260, 2400], fill=(0, 92, 44))
    glow = glow.filter(ImageFilter.GaussianBlur(260))
    return Image.blend(bg, Image.blend(bg, glow, 0.55), 0.85)

def rounded(im, radius):
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, im.size[0] - 1, im.size[1] - 1], radius, fill=255)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out

def compose(src, head, sub, dest):
    canvas = background().convert("RGBA")
    d = ImageDraw.Draw(canvas)

    hf, sf = font(92, "Bold"), font(44, "Regular")
    x, y = 96, 150
    for line in head.split("\n"):
        d.text((x, y), line, font=hf, fill=(255, 255, 255))
        y += 104
    y += 14
    for line in sub.split("\n"):
        d.text((x, y), line, font=sf, fill=(150, 165, 157))
        y += 56

    shot = Image.open(os.path.join(S, src)).convert("RGB")
    tw = 1032
    shot = shot.resize((tw, int(shot.height * tw / shot.width)), Image.LANCZOS)
    card = rounded(shot, 66)

    px, py = (W - tw) // 2, 560
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [px + 14, py + 26, px + tw - 14, py + card.height + 10], 66, fill=(0, 0, 0, 165))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(38)))

    canvas.alpha_composite(card, (px, py))
    # A hairline edge so the white screenshot does not bleed into the glow.
    ImageDraw.Draw(canvas).rounded_rectangle(
        [px, py, px + tw - 1, py + card.height - 1], 66, outline=(255, 255, 255, 38), width=3)

    canvas.convert("RGB").save(os.path.join(OUT, dest), quality=95)
    print("wrote", dest, Image.open(os.path.join(OUT, dest)).size)


def compose_watch(src, head, sub, dest):
    """The watch is close to square, so it sits centred rather than bleeding
    off the bottom the way a phone screenshot does."""
    canvas = background().convert("RGBA")
    d = ImageDraw.Draw(canvas)

    hf, sf = font(92, "Bold"), font(44, "Regular")
    x, y = 96, 150
    for line in head.split("\n"):
        d.text((x, y), line, font=hf, fill=(255, 255, 255))
        y += 104
    y += 14
    d.text((x, y), sub, font=sf, fill=(150, 165, 157))

    shot = Image.open(os.path.join(S, src)).convert("RGB")
    # Not larger: the source is a crop of a simulator window, so pushing it
    # much past this starts to look soft.
    tw = 880
    shot = shot.resize((tw, int(shot.height * tw / shot.width)), Image.LANCZOS)
    # The radius matches the watch's own corner, so the mask clips away the
    # pale simulator-window background outside the bezel instead of leaving it
    # showing in the corners.
    card = rounded(shot, int(tw * 0.205))

    # Centred in whatever is left under the text, rather than a fixed offset.
    px = (W - tw) // 2
    py = y + 70 + (H - (y + 70) - card.height) // 2
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [px + 20, py + 34, px + tw - 20, py + card.height + 14],
        int(tw * 0.205), fill=(0, 0, 0, 180))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(46)))
    canvas.alpha_composite(card, (px, py))

    canvas.convert("RGB").save(os.path.join(OUT, dest), quality=95)
    print("wrote", dest, Image.open(os.path.join(OUT, dest)).size)


compose_watch("watch-face.png", "A piece of home,\nall day",
              "On your watch face, in full colour", "01-watch.png")
compose("lock-screen.png", "Right under\nthe clock",
        "On your Lock Screen, at a glance", "02-lock.png")
compose("home-screen.png", "Fills the\nwhole slot",
        "On your Home Screen, any size", "03-home.png")
compose("01-browse.png", "Every flag,\none tap away",
        "Around 250 countries, searchable", "04-browse.png")
compose("02-detail.png", "Put it where\nyou'll see it",
        "Watch face, Lock Screen, Home Screen", "05-put-it-somewhere.png")
compose("03-favourites.png", "Star the ones\nthat matter",
        "They follow you to your Apple Watch", "06-favourites.png")
