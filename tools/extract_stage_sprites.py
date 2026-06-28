#!/usr/bin/env python3
"""Extract real SMB stage sprites used by DeskMario world-object UI.

All rectangles are source coordinates in assets/backgrounds/smb_world_minus1.png.
The output images are direct crops with the sheet sky color keyed to alpha 0.
No sprite pixels are redrawn or repainted.
"""

from pathlib import Path

from PIL import Image

SOURCE = Path("assets/backgrounds/smb_world_minus1.png")
OUT_DIR = Path("assets/sprites")

SPRITES = {
    "cloud_small.png": (56, 43, 42, 18),
    "pipe_tall.png": (398, 80, 96, 128),
    "flagpole.png": (2427, 30, 24, 178),
    "castle.png": (2520, 30, 86, 178),
}


def key_sky_to_alpha(crop: Image.Image, sky: tuple[int, int, int, int]) -> int:
    """Return a copy-like in-place crop with exact sky-color pixels transparent."""
    changed = 0
    pixels = crop.load()
    width, height = crop.size

    for y in range(height):
        for x in range(width):
            if pixels[x, y] == sky:
                pixels[x, y] = (sky[0], sky[1], sky[2], 0)
                changed += 1

    return changed


def main() -> None:
    image = Image.open(SOURCE).convert("RGBA")
    sky = image.getpixel((0, 0))
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for name, (x, y, w, h) in SPRITES.items():
        crop = image.crop((x, y, x + w, y + h))
        transparent = key_sky_to_alpha(crop, sky)
        out = OUT_DIR / name
        crop.save(out)
        print(
            f"{out}: source=({x},{y},{w},{h}) "
            f"size={crop.size[0]}x{crop.size[1]} "
            f"transparent_sky_pixels={transparent}"
        )


if __name__ == "__main__":
    main()
