"""Renders the launcher icon (mascot head + ukulele headstock) for every platform.

Run from apps/app:  python tool/generate_icons.py [--preview DIR]
Needs Pillow. Colors are sampled from DesignImages/Splash Screen.png.
"""

import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

S = 1024
SS = 4  # supersampling factor, downscaled with LANCZOS for clean edges

BG = (255, 206, 143)
ORANGE = (255, 146, 1)
RUST = (214, 122, 1)
NECK = (169, 117, 94)
HEAD = (145, 101, 81)
INK = (20, 14, 10)

APP = Path(__file__).resolve().parent.parent


def s(v):
    return v * SS


def draw_uke(d, ox, oy, angle_deg):
    # Local axis: x runs along the neck toward the headstock, +y is the
    # underside of the neck. Rotated so the neck rises up-right like the splash.
    a = math.radians(angle_deg)
    ux, uy = math.cos(a), -math.sin(a)
    vx, vy = math.sin(a), math.cos(a)

    def pt(x, y):
        return (s(ox + x * ux + y * vx), s(oy + x * uy + y * vy))

    def poly(points, fill):
        d.polygon([pt(x, y) for x, y in points], fill=fill)

    def peg(x, y, r):
        cx, cy = pt(x, y)
        d.ellipse([cx - s(r), cy - s(r), cx + s(r), cy + s(r)], fill=HEAD)

    poly([(0, -30), (360, -30), (360, 30), (0, 30)], NECK)
    poly([(0, 16), (360, 16), (360, 30), (0, 30)], HEAD)
    # Pegs sit on short stems, two per side, staggered like the splash art.
    for x, side in ((382, -1), (432, -1), (462, 1), (512, 1)):
        poly([(x - 9, 0), (x + 9, 0), (x + 9, side * 66), (x - 9, side * 66)], HEAD)
        peg(x, side * 70, 22)
    poly([(350, -30), (405, -44), (405, 44), (350, 30)], NECK)
    poly([(400, -46), (480, -60), (532, -34), (538, 28), (490, 56), (400, 46)], HEAD)


def draw_head(img, cx, cy, r):
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse(
        [s(cx - r + 20), s(cy - r + 26), s(cx + r + 20), s(cy + r + 26)],
        fill=(150, 80, 20, 90),
    )
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(s(28))))
    d = ImageDraw.Draw(img)
    d.ellipse([s(cx - r + r * 0.09), s(cy - r), s(cx + r + r * 0.09), s(cy + r)], fill=RUST)
    d.ellipse([s(cx - r), s(cy - r), s(cx + r), s(cy + r)], fill=ORANGE)
    ew, eh, gap = r * 0.17, r * 0.36, r * 0.24
    ey = cy + r * 0.08
    for ex in (cx - gap, cx + gap):
        d.ellipse([s(ex - ew / 2), s(ey - eh / 2), s(ex + ew / 2), s(ey + eh / 2)], fill=INK)


def render_art():
    """The mascot on a transparent canvas, plus the bbox of its solid pixels."""
    img = Image.new("RGBA", (s(S), s(S)), (0, 0, 0, 0))
    cx, cy, r = 360, 620, 280
    draw_uke(ImageDraw.Draw(img), cx, cy, 30)
    draw_head(img, cx, cy, r)
    img = img.resize((S, S), Image.LANCZOS)
    # Threshold keeps the soft shadow out of the bbox; it still renders, just
    # doesn't count toward centering and sizing.
    return img, img.getchannel("A").point(lambda v: 255 if v > 200 else 0).getbbox()


def compose(art, fit, bg=BG):
    """Scales art so its bbox's longer side spans `fit` of the canvas, centered."""
    img, (x0, y0, x1, y1) = art
    canvas = Image.new("RGBA", (S, S), bg + (255,) if bg else (0, 0, 0, 0))
    k = S * fit / max(x1 - x0, y1 - y0)
    a = img.resize((round(S * k), round(S * k)), Image.LANCZOS)
    dx = round(S / 2 - (x0 + x1) / 2 * k)
    dy = round(S / 2 - (y0 + y1) / 2 * k)
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    layer.paste(a, (dx, dy))
    return Image.alpha_composite(canvas, layer)


def save(img, path, size, rgb=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    out = img.resize((size, size), Image.LANCZOS)
    (out.convert("RGB") if rgb else out).save(path)


def main():
    art = render_art()
    full = compose(art, 0.84)
    # Adaptive foreground: launchers crop to the inner 72/108 and mask further,
    # so the art must sit inside the ~66% safe zone.
    fg = compose(art, 0.56, bg=None)
    # Web maskable icons keep content inside an 80% safe circle.
    maskable = compose(art, 0.72)

    if "--preview" in sys.argv:
        out = Path(sys.argv[sys.argv.index("--preview") + 1])
        save(full, out / "icon_full.png", 1024)
        save(compose(art, 0.56), out / "icon_adaptive.png", 1024)
        return

    res = APP / "android/app/src/main/res"
    for density, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        save(full, res / f"mipmap-{density}/ic_launcher.png", px)
        save(fg, res / f"mipmap-{density}/ic_launcher_foreground.png", round(px * 108 / 48))

    iconset = APP / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for entry in json.loads((iconset / "Contents.json").read_text())["images"]:
        pts = float(entry["size"].split("x")[0])
        px = round(pts * int(entry["scale"][0]))
        # App Store rejects icons with an alpha channel.
        save(full, iconset / entry["filename"], px, rgb=True)

    web = APP / "web"
    save(full, web / "favicon.png", 32)
    save(full, web / "icons/Icon-192.png", 192)
    save(full, web / "icons/Icon-512.png", 512)
    save(maskable, web / "icons/Icon-maskable-192.png", 192)
    save(maskable, web / "icons/Icon-maskable-512.png", 512)


if __name__ == "__main__":
    main()
