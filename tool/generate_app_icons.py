"""Generate launcher PNGs from the approved Lembretes artwork.

Requires Pillow. XML, HTML, and manifest declarations are maintained as source files.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets/branding"
RESAMPLE = Image.Resampling.LANCZOS
ANDROID_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}
BACKGROUND_TOP = "#33A0F5"
BACKGROUND_BOTTOM = "#0754CA"


def load_artwork() -> tuple[Image.Image, Image.Image]:
    master = Image.open(BRANDING / "lembretes-icon-master.png").convert("RGBA")
    foreground = Image.open(BRANDING / "lembretes-icon-foreground.png").convert("RGBA")
    if master.size != foreground.size:
        raise ValueError("Master and foreground must have the same dimensions.")
    if master.getchannel("A").getextrema() != (255, 255):
        raise ValueError("The full-bleed master artwork must be opaque.")

    # Remove stray pixels with negligible alpha from the generated cutout.
    alpha = foreground.getchannel("A").point(lambda value: 0 if value < 16 else value)
    foreground.putalpha(alpha)

    visible = alpha.point(lambda value: 255 if value >= 128 else 0).getbbox()
    if visible is None:
        raise ValueError("The foreground has no visible symbol.")
    safe_start = master.width * 21 / 108
    safe_end = master.width * 87 / 108
    left, top, right, bottom = visible
    if not (
        safe_start <= left < right <= safe_end
        and safe_start <= top < bottom <= safe_end
    ):
        raise ValueError(f"Bell extends beyond the Android safe zone: {visible}")
    return master, foreground


def shape_mask(size: int, shape: str) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    bounds = (0, 0, size - 1, size - 1)
    if shape == "circle":
        draw.ellipse(bounds, fill=255)
    elif shape == "rounded":
        draw.rounded_rectangle(bounds, radius=round(size * 0.22), fill=255)
    else:
        raise ValueError(f"Unknown icon shape: {shape}")
    return mask


def save_png(
    artwork: Image.Image,
    path: Path,
    size: int,
    *,
    shape: str | None = None,
    opaque: bool = False,
) -> None:
    icon = artwork.resize((size, size), RESAMPLE)
    if shape is not None:
        icon.putalpha(ImageChops.multiply(icon.getchannel("A"), shape_mask(size, shape)))
    path.parent.mkdir(parents=True, exist_ok=True)
    icon.convert("RGB" if opaque else "RGBA").save(path, optimize=True)


def export_android(master: Image.Image, foreground: Image.Image) -> None:
    res = ROOT / "android/app/src/main/res"
    for density, size in ANDROID_SIZES.items():
        mipmap = res / f"mipmap-{density}"
        save_png(master, mipmap / "ic_launcher.png", size, opaque=True)
        save_png(master, mipmap / "ic_launcher_round.png", size, shape="circle")

    drawable = res / "drawable-nodpi"
    save_png(foreground, drawable / "ic_launcher_foreground.png", 432)
    monochrome = Image.new("RGBA", foreground.size, "white")
    monochrome.putalpha(foreground.getchannel("A"))
    save_png(monochrome, drawable / "ic_launcher_monochrome.png", 432)


def export_ios(master: Image.Image) -> None:
    iconset = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((iconset / "Contents.json").read_text(encoding="utf-8"))
    for entry in contents["images"]:
        filename = entry.get("filename")
        if filename is None:
            continue
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].removesuffix("x"))
        save_png(master, iconset / filename, round(points * scale), opaque=True)


def export_web(master: Image.Image) -> None:
    web = ROOT / "web"
    save_png(master, web / "favicon.png", 64, shape="rounded")
    save_png(master, web / "apple-touch-icon.png", 180, opaque=True)
    for size in (192, 512):
        save_png(master, web / "icons" / f"icon-{size}.png", size, shape="rounded")
        save_png(master, web / "icons" / f"icon-maskable-{size}.png", size, opaque=True)


def export_shape_preview(foreground: Image.Image) -> None:
    # Android masks the inner 72 dp of each 108 dp adaptive layer.
    layer_size = 330
    inset = layer_size // 6
    shade = Image.linear_gradient("L").resize((layer_size, layer_size))
    composed = ImageOps.colorize(shade, BACKGROUND_TOP, BACKGROUND_BOTTOM).convert("RGBA")
    composed.alpha_composite(foreground.resize((layer_size, layer_size), RESAMPLE))

    icon_size = 220
    tile = composed.crop(
        (inset, inset, layer_size - inset, layer_size - inset)
    ).resize((icon_size, icon_size), RESAMPLE)
    gap = 28
    sheet = Image.new("RGB", (icon_size * 3 + gap * 4, icon_size + gap * 2), "#F2F3F8")
    for index, shape in enumerate((None, "rounded", "circle")):
        preview = tile.copy()
        if shape is not None:
            preview.putalpha(shape_mask(icon_size, shape))
        x = gap + index * (icon_size + gap)
        sheet.paste(preview, (x, gap), preview.getchannel("A"))
    sheet.save(BRANDING / "lembretes-shapes-preview.png", optimize=True)


def main() -> None:
    master, foreground = load_artwork()
    export_android(master, foreground)
    export_ios(master)
    export_web(master)
    export_shape_preview(foreground)


if __name__ == "__main__":
    main()
