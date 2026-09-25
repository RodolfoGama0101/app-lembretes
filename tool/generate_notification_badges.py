"""Generate Android large icons for the reminder notification palette.

Run with: python tool/generate_notification_badges.py
"""

from math import cos, pi, sin
from pathlib import Path

from PIL import Image, ImageDraw

COLORS = {
    "blue": "#0072DE",
    "green": "#16804A",
    "orange": "#B85D00",
    "purple": "#7752B4",
    "red": "#D92D3A",
    "yellow": "#F0B900",
}
SYMBOLS = ("bell", "star", "check")
OUTPUT = Path(__file__).resolve().parents[1] / "android/app/src/main/res/drawable-nodpi"
SCALE = 4


def draw_badge(color: str, symbol: str) -> Image.Image:
    image = Image.new("RGBA", (256 * SCALE, 256 * SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    def box(coords: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
        return tuple(value * SCALE for value in coords)

    draw.ellipse(box((16, 16, 240, 240)), fill=color)
    foreground = "#342900" if color == COLORS["yellow"] else "#FFFFFF"

    if symbol == "bell":
        draw.ellipse(box((91, 58, 165, 132)), fill=foreground)
        draw.rectangle(box((91, 95, 165, 156)), fill=foreground)
        draw.polygon([(x * SCALE, y * SCALE) for x, y in
                      ((91, 149), (165, 149), (183, 179), (73, 179))],
                     fill=foreground)
        draw.ellipse(box((117, 183, 139, 205)), fill=foreground)
    elif symbol == "star":
        vertices = []
        for point in range(10):
            angle = -pi / 2 + point * pi / 5
            radius = 77 if point % 2 == 0 else 34
            vertices.append(((128 + radius * cos(angle)) * SCALE,
                             (132 + radius * sin(angle)) * SCALE))
        draw.polygon(vertices, fill=foreground)
    else:
        points = [(78 * SCALE, 130 * SCALE),
                  (113 * SCALE, 165 * SCALE),
                  (183 * SCALE, 91 * SCALE)]
        draw.line(points, fill=foreground, width=22 * SCALE, joint="curve")
        for x, y in points:
            draw.ellipse((x - 11 * SCALE, y - 11 * SCALE,
                          x + 11 * SCALE, y + 11 * SCALE), fill=foreground)

    return image.resize((128, 128), Image.Resampling.LANCZOS)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, color in COLORS.items():
        for symbol in SYMBOLS:
            draw_badge(color, symbol).save(
                OUTPUT / f"notification_badge_{name}_{symbol}.png",
                optimize=True,
            )


if __name__ == "__main__":
    main()
