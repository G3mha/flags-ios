# Builds the App Store screenshots from plain simulator captures.
#
# Put the plain captures in Tools/screenshot-sources and run this; the framed
# versions land in fastlane/screenshots/en-US, where deliver expects them.
# Capture iPhone on a 6.9" device (iPhone 17 Pro Max, 1320x2868), which Apple
# scales down for every smaller iPhone. iPad is a separate requirement and
# cannot be covered by the iPhone set: capture it on a 13" iPad (2064x2752).
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

IPHONE = (1320, 2868)
IPAD = (2064, 2752)

# The layout below was drawn for the iPhone canvas. Everything scales off its
# width, so the same numbers produce a proportionate iPad panel rather than
# iPhone-sized text stranded on a much bigger page.

def font(size, weight):
    f = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)
    try: f.set_variation_by_name(weight)
    except Exception: pass
    return f

def background(size):
    W, H = size
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

def compose(src, head, sub, dest, size=IPHONE):
    W, H = size
    k = W / IPHONE[0]
    canvas = background(size).convert("RGBA")
    d = ImageDraw.Draw(canvas)

    hf, sf = font(int(92 * k), "Bold"), font(int(44 * k), "Regular")
    x, y = int(96 * k), int(150 * k)
    for line in head.split("\n"):
        d.text((x, y), line, font=hf, fill=(255, 255, 255))
        y += int(104 * k)
    y += int(14 * k)
    for line in sub.split("\n"):
        d.text((x, y), line, font=sf, fill=(150, 165, 157))
        y += int(56 * k)

    shot = Image.open(os.path.join(S, src)).convert("RGB")
    tw = int(1032 * k)
    shot = shot.resize((tw, int(shot.height * tw / shot.width)), Image.LANCZOS)
    radius = int(66 * k)
    card = rounded(shot, radius)

    px, py = (W - tw) // 2, int(560 * k)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [px + int(14 * k), py + int(26 * k), px + tw - int(14 * k), py + card.height + int(10 * k)],
        radius, fill=(0, 0, 0, 165))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(int(38 * k))))

    canvas.alpha_composite(card, (px, py))
    # A hairline edge so the white screenshot does not bleed into the glow.
    ImageDraw.Draw(canvas).rounded_rectangle(
        [px, py, px + tw - 1, py + card.height - 1], radius,
        outline=(255, 255, 255, 38), width=max(2, int(3 * k)))

    canvas.convert("RGB").save(os.path.join(OUT, dest), quality=95)
    print("wrote", dest, Image.open(os.path.join(OUT, dest)).size)


def compose_watch(src, head, sub, dest):
    """The watch is close to square, so it sits centred rather than bleeding
    off the bottom the way a phone screenshot does."""
    W, H = IPHONE
    canvas = background(IPHONE).convert("RGBA")
    d = ImageDraw.Draw(canvas)

    hf, sf = font(92, "Bold"), font(44, "Regular")
    x, y = 96, 150
    for line in head.split("\n"):
        d.text((x, y), line, font=hf, fill=(255, 255, 255))
        y += 104
    y += 14
    d.text((x, y), sub, font=sf, fill=(150, 165, 157))

    # The source is a cut-out with a real alpha channel, so there is no mask
    # and no card here: the watch's own silhouette is the shape, and the
    # shadow is cast from that rather than from a rounded rectangle.
    shot = Image.open(os.path.join(S, src)).convert("RGBA")
    shot = shot.crop(shot.getchannel("A").getbbox())

    tw = 880
    shot = shot.resize((tw, int(shot.height * tw / shot.width)), Image.LANCZOS)

    px = (W - tw) // 2
    py = y + 70 + (H - (y + 70) - shot.height) // 2

    silhouette = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    silhouette.paste((0, 0, 0, 190), (px, py + 30), shot.getchannel("A"))
    canvas = Image.alpha_composite(canvas, silhouette.filter(ImageFilter.GaussianBlur(44)))
    canvas.alpha_composite(shot, (px, py))

    canvas.convert("RGB").save(os.path.join(OUT, dest), quality=95)
    print("wrote", dest, Image.open(os.path.join(OUT, dest)).size)



def watch_screenshot(src, dest, size=(422, 514)):
    """The Apple Watch slot wants the watch's own screen, not a framed panel.

    The source is a cut-out of the whole device, so this insets past the case
    and crops to the screen's aspect before resizing -- cropping rather than
    squashing, so the face stays round."""
    im = Image.open(os.path.join(S, src)).convert("RGBA")
    im = im.crop(im.getchannel("A").getbbox())
    w, h = im.size
    inner = im.crop((int(w * 0.075), int(h * 0.055),
                     w - int(w * 0.075), h - int(h * 0.055))).convert("RGB")

    tw, th = size
    iw, ih = inner.size
    want, have = tw / th, iw / ih
    if have > want:
        nw = int(ih * want)
        inner = inner.crop(((iw - nw) // 2, 0, (iw + nw) // 2, ih))
    else:
        nh = int(iw / want)
        inner = inner.crop((0, (ih - nh) // 2, iw, (ih + nh) // 2))

    inner.resize((tw, th), Image.LANCZOS).save(os.path.join(OUT, dest))
    print("wrote", dest, size)


watch_screenshot("watch-face.png", "watch-01-face.png")

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

# iPad is its own required size and the iPhone set does not satisfy it.
compose("ipad-browse.png", "Every flag,\none tap away",
        "Around 250 countries, searchable", "ipad-01-browse.png", size=IPAD)
compose("ipad-detail.png", "Put it where\nyou'll see it",
        "Watch face, Lock Screen, Home Screen", "ipad-02-detail.png", size=IPAD)
