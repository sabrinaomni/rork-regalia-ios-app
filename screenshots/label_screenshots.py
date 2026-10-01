"""Adds a "Requires subscription" label band to each final App Store screenshot.

Originals in screenshots/final/ stay untouched; labelled copies go to
screenshots/final-labelled/ at the same 1284 x 2778 size.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
SRC = ROOT / "final"
OUT = ROOT / "final-labelled"
FONT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/tmp/cormorant.ttf")

W, H = 1284, 2778
BAND = 190
BOTTOM = 44
GOLD = (212, 162, 76)
TOP_COLOR = (11, 21, 51)
BOTTOM_COLOR = (4, 7, 14)
LABEL = "REQUIRES SUBSCRIPTION"
TRACKING = 7


def gradient() -> Image.Image:
    canvas = Image.new("RGB", (W, H))
    draw = ImageDraw.Draw(canvas)
    for y in range(H):
        t = y / (H - 1)
        color = tuple(round(a + (b - a) * t) for a, b in zip(TOP_COLOR, BOTTOM_COLOR))
        draw.line([(0, y), (W, y)], fill=color)
    return canvas


def load_font(size: int) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONT), size)
    try:
        font.set_variation_by_name("SemiBold")
    except Exception:
        try:
            font.set_variation_by_axes([600])
        except Exception:
            pass
    return font


def tracked_width(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont) -> int:
    widths = [draw.textlength(ch, font=font) for ch in text]
    return round(sum(widths) + TRACKING * (len(text) - 1))


def draw_label(canvas: Image.Image) -> None:
    draw = ImageDraw.Draw(canvas)
    font = load_font(46)
    text_w = tracked_width(draw, LABEL, font)
    ascent, descent = font.getmetrics()
    pad_x, pill_h = 46, 88
    pill_w = text_w + pad_x * 2
    x0 = (W - pill_w) // 2
    y0 = (BAND - pill_h) // 2 + 14
    draw.rounded_rectangle(
        [x0, y0, x0 + pill_w, y0 + pill_h],
        radius=pill_h // 2,
        fill=(22, 26, 40),
        outline=GOLD,
        width=3,
    )
    x = x0 + pad_x
    text_y = y0 + (pill_h - (ascent + descent)) // 2 + 2
    for ch in LABEL:
        draw.text((x, text_y), ch, font=font, fill=GOLD)
        x += draw.textlength(ch, font=font) + TRACKING


def place_screen(canvas: Image.Image, screen: Image.Image) -> None:
    target_h = H - BAND - BOTTOM
    target_w = round(target_h * screen.width / screen.height)
    scaled = screen.resize((target_w, target_h), Image.LANCZOS)
    radius = 64
    mask = Image.new("L", scaled.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, target_w - 1, target_h - 1], radius=radius, fill=255)
    x = (W - target_w) // 2
    y = BAND
    canvas.paste(scaled, (x, y), mask)
    ImageDraw.Draw(canvas).rounded_rectangle(
        [x - 2, y - 2, x + target_w + 1, y + target_h + 1],
        radius=radius + 2,
        outline=(*GOLD, ),
        width=2,
    )


def main() -> None:
    OUT.mkdir(exist_ok=True)
    files = sorted(p for p in SRC.glob("*.png"))
    for path in files:
        screen = Image.open(path).convert("RGB")
        canvas = gradient()
        place_screen(canvas, screen)
        draw_label(canvas)
        out = OUT / path.name
        canvas.save(out, "PNG", optimize=True)
        print(out.name, canvas.size)


if __name__ == "__main__":
    main()
