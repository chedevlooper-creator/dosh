"""favicon.png (256×256) ve web ikonları üret."""
from PIL import Image, ImageDraw
import os

SRC = os.path.join(os.path.dirname(__file__), "icon_raw.png")
FAVICON = os.path.join(os.path.dirname(__file__), "..", "..", "web", "favicon.png")

img = Image.open(SRC).resize((256, 256), Image.LANCZOS)

# Beyaz zemin ekle (favicon genelde görünür zemin ister)
bg = Image.new("RGBA", (256, 256), (0xF5, 0xB6, 0x2B, 255))
bg.paste(img, (0, 0), img)
bg.save(FAVICON, "PNG")
print(f"Favicon saved: {FAVICON}")
